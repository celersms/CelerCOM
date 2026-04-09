; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: September 2020
; ---------------------------
; Native COM driver for Windows 64-bit
; Compile using FASM: http://flatassembler.net/
format PE64 GUI 4.0 DLL at 0x10000000 on "nul"

section '.text' code readable executable

clos: ; Close comm device
   push r8
   sub rsp, 32                 ; allocate shadow area
   mov rdx, 0Fh                ; PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR
   mov rcx, r8                 ; hFile
   call [PurgeComm]
   mov rcx, [rsp + 32]         ; hFile
   call [CloseHandle]
   add rsp, 40                 ; fix stack
   retn

open: ; Open comm device and setup timeouts
   push rbp
   push rsi
   mov rsi, rcx                ; *JEnv
   push rdi
   mov rbp, [rcx]
   push r8
   push 0                      ; hTemplateFile
   push 20000000h              ; dwFlagsAndAttributes  = FILE_FLAG_NO_BUFFERING
   push 3                      ; dwCreationDisposition = OPEN_EXISTING
   sub rsp, 32                 ; allocate shadow area
   mov rdx, r8                 ; string
   xor r8, r8                  ; *isCopy
   call QWORD [rbp + 169 * 8]  ; GetStringUTFChars
   test rax, rax
   jz ropen
   mov rdi, rax
   xor r9, r9                  ; lpSecurityAttributes
   xor r8, r8                  ; dwShareMode
   mov rdx, 0C0000000h         ; dwDesiredAccess       = GENERIC_READ | GENERIC_WRITE
   mov rcx, rax                ; lpFileName
   call [CreateFileA]
   mov r8, rdi                 ; *utf
   mov rdx, [rsp + 56]         ; string
   mov rdi, rax
   mov rcx, rsi                ; *JEnv
   call QWORD [rbp + 170 * 8]  ; ReleaseStringUTFChars
   cmp edi, 0FFFFFFFFh
   mov rax, rdi
   je ropen2
   lea rdx, [COMMTO]           ; lpCommTimeouts
   mov rcx, rax                ; hFile
   call [SetCommTimeouts]
   mov rax, rdi
   inc rax
ropen:
   dec rax
ropen2:
   add rsp, 64                 ; fix stack
   pop rdi
   pop rsi
   pop rbp
   retn

read: ; Read from comm device
   push rbp
   push rsi
   push rdi
   mov rsi, rcx                ; *JEnv
   push r8
   push r9
   push 0                      ; allocate Errors
                               ;          COMSTAT.cbOutQue
   push 0                      ;          COMSTAT.cbInQue
                               ;          COMSTAT.fReserved
   lea rdx, [rsp + 12]         ; lpErrors
   mov rcx, r8                 ; hFile
   mov r8, rsp                 ; lpStat
   sub rsp, 32                 ; allocate shadow area
   call [ClearCommError]
   test eax, eax
   mov rax, [rsp + 32]         ; lpStat --> cbInQue
   mov rcx, [rsp + 40]         ; Errors
   mov QWORD [rsp + 40], -1    ; NumberOfBytesRead
   jz unavail
   shr rcx, 32
   shr rax, 32
   and cl, 14h                 ; CE_BREAK | CE_RXPARITY
   jnz unavail
   test eax, eax
   jz rread
   mov rbp, [rsi]
   xor r8, r8                  ; *isCopy
   mov [rsp + 32], r8          ; lpOverlapped
   mov rdx, [rsp + 48]         ; array
   mov rcx, rsi                ; *JEnv
   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
   test rax, rax
   mov rdi, rax
   jz rread
   mov eax, [rsp + 128]        ; off
   lea rdx, [rdi + rax]        ; lpBuffer
   lea r9, [rsp + 40]          ; lpNumberOfBytesRead
   mov r8, [rsp + 136]         ; nNumberOfBytesToRead
   mov rcx, [rsp + 56]         ; hFile
   call [ReadFile]
   xor r9, r9                  ; mode = 0: copy back content and free elems buffer
   mov r8, rdi                 ; *elems
   mov rdx, [rsp + 48]         ; array
   mov rcx, rsi                ; *JEnv
   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
unavail:
   mov rax, [rsp + 40]
rread:
   add rsp, 64                 ; fix stack
   pop rdi
   pop rsi
   pop rbp
   retn

writ: ; Write to comm device
   push rbp
   push rdi
   push rsi
   mov rdi, rcx                ; *JEnv
   mov rbp, [rcx]
   push r8
   push r9
   push 0                      ; allocate NumberOfBytesWritten
   push 0                      ; lpOverlapped
   sub rsp, 32                 ; allocate shadow area
   xor r8, r8                  ; *isCopy
   mov rdx, r9                 ; array
   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
   test rax, rax
   mov rsi, rax
   jz @f
   mov eax, [rsp + 128]        ; off
   lea rdx, [rsi + rax]        ; lpBuffer
   lea r9, [rsp + 40]          ; lpNumberOfBytesWritten
   mov r8, [rsp + 136]         ; nNumberOfBytesToWrite
   mov rcx, [rsp + 56]         ; hFile
   call [WriteFile]
   mov r9, 2                   ; mode = JNI_ABORT: free buffer without copying back the possible changes
   mov r8, rsi                 ; *elems
   mov rdx, [rsp + 48]         ; array
   mov rcx, rdi                ; *JEnv
   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
   mov rax, [rsp + 40]
@@:
   add rsp, 64                 ; fix stack
   pop rsi
   pop rdi
   pop rbp
   retn

align 4
COMMTO dd 0FFFFFFFFh, 0FFFFFFFFh, 200 ; ReadTotalTimeoutConstant = 200ms

data import
   dd 0,0,0,RVA _kernel32,RVA kernel32_tbl,0,0
end data
data export
   dd 0,0,0,RVA _dllname,1
   dd 4,4,RVA _procaddrs,RVA _procnames,RVA _ords ; 4 = number of exported procs
end data
data fixups
end data

; Sort alphabetically the proc names
_procaddrs         dd RVA clos,RVA open,RVA read,RVA writ
_procnames         dd RVA _clos,RVA _open,RVA _read,RVA _writ
kernel32_tbl:
   CreateFileA     dq RVA _CreateFileA
   SetCommTimeouts dq RVA _SetCommTimeouts
   WriteFile       dq RVA _WriteFile
   ReadFile        dq RVA _ReadFile
   ClearCommError  dq RVA _ClearCommError
   PurgeComm       dq RVA _PurgeComm
   CloseHandle     dq RVA _CloseHandle
                   dq 0
_clos              db 'Java_com_celer_N_c',0
_open              db 'Java_com_celer_N_o',0
_read              db 'Java_com_celer_N_r',0
_writ              db 'Java_com_celer_N_w',0
_ords              dw 0,1,2,3
_kernel32          db 'KERNEL32.DLL',0
_dllname           db 'celer64.dll',0
_CreateFileA       db 0,0,'CreateFileA',0
_SetCommTimeouts   db 0,0,'SetCommTimeouts',0
_WriteFile         db 0,0,'WriteFile',0
_CloseHandle       db 0,0,'CloseHandle',0
_PurgeComm         db 0,0,'PurgeComm',0
_ReadFile          db 0,0,'ReadFile',0,0
_ClearCommError    db 0,0,'ClearCommError',0
