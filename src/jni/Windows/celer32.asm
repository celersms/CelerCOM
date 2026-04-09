; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: September 2020
; ---------------------------
; Native COM driver for Windows 32-bit
; Compile using FASM: http://flatassembler.net/
format PE GUI 4.0 DLL at 0x01400000 on "nul"

section '.text' code readable executable

clos: ; Close comm device
   push 0Fh                    ; PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR
   push DWORD [esp + 16]       ; hFile
   call [PurgeComm]
   push DWORD [esp + 12]       ; hFile
   call [CloseHandle]
   retn 12

open: ; Open comm device and setup timeouts
   push ebp
   push esi
   mov esi, [esp + 12]         ; *JEnv
   push edi
   mov ebp, [esi]
   push 0                      ; *isCopy
   push DWORD [esp + 28]       ; string
   push esi                    ; *JEnv
   call DWORD [ebp + 169 * 4]  ; GetStringUTFChars
   test eax, eax
   jz ropen
   push eax                    ; *utf
   push 0                      ; hTemplateFile
   push 20000000h              ; dwFlagsAndAttributes  = FILE_FLAG_NO_BUFFERING
   push 3                      ; dwCreationDisposition = OPEN_EXISTING
   push 0                      ; lpSecurityAttributes
   push 0                      ; dwShareMode
   push 0C0000000h             ; dwDesiredAccess       = GENERIC_READ | GENERIC_WRITE
   push eax                    ; lpFileName
   call [CreateFileA]
   push DWORD [esp + 28]       ; string
   xchg eax, edi
   push esi                    ; *JEnv
   call DWORD [ebp + 170 * 4]  ; ReleaseStringUTFChars
   cmp edi, 0FFFFFFFFh
   mov eax, edi
   je ropen2
   push COMMTO                 ; lpCommTimeouts
   push eax                    ; hFile
   call [SetCommTimeouts]
   xchg eax, edi
   inc eax
ropen:
   dec eax
ropen2:
   pop edi
   pop esi
   pop ebp
   retn 12

read: ; Read from comm device
   push 0                      ; allocate Errors
   mov eax, esp
                               ; allocate COMSTAT:
   push eax                    ;    COMSTAT.cbOutQue
   push 0                      ;    COMSTAT.cbInQue
   push eax                    ;    COMSTAT.fReserved
   push esp                    ; lpStat
   push eax                    ; lpErrors
   push DWORD [esp + 36]       ; hFile
   call [ClearCommError]
   test eax, eax
   pop edx
   pop eax                     ; lpStat --> cbInQue
   pop edx
   pop ecx                     ; Errors
   jz unavail
   and cl, 14h                 ; CE_BREAK | CE_RXPARITY
   jnz unavail
   test eax, eax
   jnz avail
   retn 24                     ; no data available to read
unavail:
   xor eax, eax
   dec eax
   retn 24                     ; error detected (i.e. device disconnected)
avail:
   push ebp
   push esi
   push edi
   mov esi, [esp + 16]         ; *JEnv
   mov ebp, [esi]
   push 0                      ; *isCopy
   push DWORD [esp + 32]       ; array
   push esi                    ; *JEnv
   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
   test eax, eax
   mov edi, eax
   jz rread
   mov eax, [esp + 32]         ; off
   lea edx, [edi + eax]
   push 0                      ; allocate NumberOfBytesRead
   mov eax, esp
   push 0                      ; lpOverlapped
   push eax                    ; lpNumberOfBytesRead
   push DWORD [esp + 48]       ; nNumberOfBytesToRead
   push edx                    ; lpBuffer
   push DWORD [esp + 44]       ; hFile
   call [ReadFile]
   push 0                      ; mode = 0: copy back content and free elems buffer
   push edi                    ; *elems
   push DWORD [esp + 40]       ; array
   push esi                    ; *JEnv
   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
   pop eax                     ; deallocate NumberOfBytesRead
rread:
   pop edi
   pop esi
   pop ebp
   retn 24

writ: ; Write to comm device
   push ebp
   push edi
   push esi
   mov edi, [esp + 16]         ; *JEnv
   mov ebp, [edi]
   push 0                      ; *isCopy
   push DWORD [esp + 32]       ; array
   push edi                    ; *JEnv
   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
   test eax, eax
   mov esi, eax
   jz @f
   mov eax, [esp + 32]         ; off
   lea edx, [esi + eax]
   push 0                      ; allocate NumberOfBytesWritten
   mov eax, esp
   push 0                      ; lpOverlapped
   push eax                    ; lpNumberOfBytesWritten
   push DWORD [esp + 48]       ; nNumberOfBytesToWrite
   push edx                    ; lpBuffer
   push DWORD [esp + 44]       ; hFile
   call [WriteFile]
   push 2                      ; mode = JNI_ABORT: free buffer without copying back the possible changes
   push esi                    ; *elems
   push DWORD [esp + 40]       ; array
   push edi                    ; *JEnv
   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
   pop eax                     ; deallocate NumberOfBytesWritten
@@:
   pop esi
   pop edi
   pop ebp
   retn 24

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
   CreateFileA     dd RVA _CreateFileA
   SetCommTimeouts dd RVA _SetCommTimeouts
   WriteFile       dd RVA _WriteFile
   ReadFile        dd RVA _ReadFile
   ClearCommError  dd RVA _ClearCommError
   PurgeComm       dd RVA _PurgeComm
   CloseHandle     dd RVA _CloseHandle
                   dd 0
_clos              db '_Java_com_celer_N_c@12',0
_open              db '_Java_com_celer_N_o@12',0
_read              db '_Java_com_celer_N_r@24',0
_writ              db '_Java_com_celer_N_w@24',0
_ords              dw 0,1,2,3
_kernel32          db 'KERNEL32.DLL',0
_dllname           db 'celer32.dll',0
_CreateFileA       db 0,0,'CreateFileA',0
_SetCommTimeouts   db 0,0,'SetCommTimeouts',0
_WriteFile         db 0,0,'WriteFile',0
_CloseHandle       db 0,0,'CloseHandle',0
_PurgeComm         db 0,0,'PurgeComm',0
_ReadFile          db 0,0,'ReadFile',0,0
_ClearCommError    db 0,0,'ClearCommError',0
