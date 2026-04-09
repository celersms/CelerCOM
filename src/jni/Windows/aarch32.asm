; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: December 2020
; ---------------------------
; Native COM driver for Windows CE (ARM 32-bit)
; Compile using FASMARM: http://arm.flatassembler.net/
format PE GUI 4.0 DLL

section '.text' data code readable writeable executable

clos: ; Close comm device
   stmfd sp!,{r4,lr}
   mov r4,r2
   mov r1,0                    ; PURGE_RXABORT | PURGE_RXCLEAR | PURGE_TXABORT | PURGE_TXCLEAR
   mov r0,r2                   ; hFile
   bl _dll.PurgeComm
   mov r0,r4                   ; hFile
   bl _dll.CloseHandle
   ldmfd sp!,{r4,pc}

open: ; Open comm device and setup timeouts
   stmfd sp!,{r4-r7,lr}
   mov r4,r0                   ; *JEnv
   mov r6,r2
   ldr r5,[r4]
   mov r1,r2                   ; string
   mov r2,0                    ; *isCopy
   ldr r7,[r5 + 165 * 4]       ; GetStringChars
   bx r7
   cmp r0,0
   beq ropen
   mov r7,r0                   ; lpFileName
   mov r1,0                    ; hTemplateFile
   str r1,[sp,-4]
   mov r1,80000000h            ; dwFlagsAndAttributes  = FILE_FLAG_WRITE_THROUGH
   str r1,[sp,-8]
   mov r1,3                    ; dwCreationDisposition = OPEN_EXISTING
   str r1,[sp,-12]
   mov r3,0                    ; lpSecurityAttributes
   mov r2,0                    ; dwShareMode
   mov r1,0C0000000h           ; dwDesiredAccess       = GENERIC_READ | GENERIC_WRITE
   sub sp,sp,12
   bl _dll.CreateFileW
   mov r2,r7                   ; *utf
   mov r1,r6                   ; string
   mov r7,r0
   mov r0,r4                   ; *JEnv
   ldr r5,[r5 + 166 * 4]       ; ReleaseStringChars
   bx r5
   cmp r7,0FFFFFFFFh
   mov r0,r7                   ; hFile
   beq ropen2
   adr r1,COMMTO               ; lpCommTimeouts
   bl _dll.SetCommTimeouts
   mov r0,1
ropen:
   sub r0,r0,1
ropen2:
   ldmfd sp!,{r4-r7,pc}

read: ; Read from comm device
   stmfd sp!,{r4-r7,lr}
   mov r0,0
   ldmfd sp!,{r4-r7,pc}

;   push 0                      ; allocate Errors
;   mov eax, esp
                               ; allocate COMSTAT:
;   push eax                    ;    COMSTAT.cbOutQue
;   push 0                      ;    COMSTAT.cbInQue
;   push eax                    ;    COMSTAT.fReserved
;   push esp                    ; lpStat
;   push eax                    ; lpErrors
;   push DWORD [esp + 36]       ; hFile
;   call [ClearCommError]
;   test eax, eax
;   pop edx
;   pop eax                     ; lpStat --> cbInQue
;   pop edx
;   pop ecx                     ; Errors
;   jz unavail
;   and cl, 14h                 ; CE_BREAK | CE_RXPARITY
;   jnz unavail
;   test eax, eax
;   jnz avail
;   retn 24                     ; no data available to read
;unavail:
;   xor eax, eax
;   dec eax
;   retn 24                     ; error detected (i.e. device disconnected)
;avail:
;   push ebp
;   push esi
;   push edi
;   mov esi, [esp + 16]         ; *JEnv
;   mov ebp, [esi]
;   push 0                      ; *isCopy
;   push DWORD [esp + 32]       ; array
;   push esi                    ; *JEnv
;   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
;   test eax, eax
;   mov edi, eax
;   jz rread
;   mov eax, [esp + 32]         ; off
;   lea edx, [edi + eax]
;   push 0                      ; allocate NumberOfBytesRead
;   mov eax, esp
;   push 0                      ; lpOverlapped
;   push eax                    ; lpNumberOfBytesRead
;   push DWORD [esp + 48]       ; nNumberOfBytesToRead
;   push edx                    ; lpBuffer
;   push DWORD [esp + 44]       ; hFile
;   call [ReadFile]
;   push 0                      ; mode = 0: copy back content and free elems buffer
;   push edi                    ; *elems
;   push DWORD [esp + 40]       ; array
;   push esi                    ; *JEnv
;   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
;   pop eax                     ; deallocate NumberOfBytesRead
;rread:
;   pop edi
;   pop esi
;   pop ebp
;   retn 24

writ: ; Write to comm device
   stmfd sp!,{r4-r7,lr}
   mov r0,0
   ldmfd sp!,{r4-r7,pc}

;   push ebp
;   push edi
;   push esi
;   mov edi, [esp + 16]         ; *JEnv
;   mov ebp, [edi]
;   push 0                      ; *isCopy
;   push DWORD [esp + 32]       ; array
;   push edi                    ; *JEnv
;   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
;   test eax, eax
;   mov esi, eax
;   jz @f
;   mov eax, [esp + 32]         ; off
;   lea edx, [esi + eax]
;   push 0                      ; allocate NumberOfBytesWritten
;   mov eax, esp
;   push 0                      ; lpOverlapped
;   push eax                    ; lpNumberOfBytesWritten
;   push DWORD [esp + 48]       ; nNumberOfBytesToWrite
;   push edx                    ; lpBuffer
;   push DWORD [esp + 44]       ; hFile
;   call [WriteFile]
;   push 2                      ; mode = JNI_ABORT: free buffer without copying back the possible changes
;   push esi                    ; *elems
;   push DWORD [esp + 40]       ; array
;   push edi                    ; *JEnv
;   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
;   pop eax                     ; deallocate NumberOfBytesWritten
;@@:
;   pop esi
;   pop edi
;   pop ebp
;   retn 24

_dll:
   .CreateFileW:     ldr pc,[CreateFileW]
   .SetCommTimeouts: ldr pc,[SetCommTimeouts]
   .WriteFile:       ldr pc,[WriteFile]
   .ReadFile:        ldr pc,[ReadFile]
   .ClearCommError:  ldr pc,[ClearCommError]
   .CloseHandle:     ldr pc,[CloseHandle]
   .PurgeComm:       ldr pc,[PurgeComm]

align 4
COMMTO dw 0FFFFFFFFh, 0FFFFFFFFh, 200 ; ReadTotalTimeoutConstant = 200ms

data import
   dw 0,0,0,RVA coredll_name,RVA coredll_tbl
   dw 0,0,0,RVA serdev_name,RVA serdev_tbl
   dw 0,0
end data
data export
   dw 0,0,0,RVA _dllname,1
   dw 4,4,RVA _procaddrs,RVA _procnames,RVA _ords ; 4 = number of exported procs
end data
data fixups
end data

coredll_tbl:
   CreateFileW     dw RVA _CreateFileW
   WriteFile       dw RVA _WriteFile
   ReadFile        dw RVA _ReadFile
   CloseHandle     dw RVA _CloseHandle
                   dw 0
serdev_tbl:
   PurgeComm       dw RVA _PurgeComm
   SetCommTimeouts dw RVA _SetCommTimeouts
   ClearCommError  dw RVA _ClearCommError
                   dw 0
_dllname           db 'aarch32.dll',0
coredll_name       db 'coredll.dll',0
serdev_name        db 'serdev.dll',0
_CreateFileW       db 0,0,'CreateFileW',0
_SetCommTimeouts   db 0,0,'SetCommTimeouts',0
_WriteFile         db 0,0,'WriteFile',0
_CloseHandle       db 0,0,'CloseHandle',0
_ReadFile          db 0,0,'ReadFile',0,0
_ClearCommError    db 0,0,'ClearCommError',0
_PurgeComm         db 0,0,'PurgeComm',0

; Sort alphabetically the proc names
align 2
_procaddrs         dw RVA clos,RVA open,RVA read,RVA writ
_procnames         dw RVA _clos,RVA _open,RVA _read,RVA _writ
_clos              db '_Java_com_celer_N_c@12',0
_open              db '_Java_com_celer_N_o@12',0
_read              db '_Java_com_celer_N_r@24',0
_writ              db '_Java_com_celer_N_w@24',0
_ords              dh 0,1,2,3
