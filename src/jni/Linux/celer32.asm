; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: September 2020
; ---------------------------
; Native COM driver for Linux 32-bit
; Compile using FASM: http://flatassembler.net/
; Linker / strip commands:
;    ld -m elf_i386 -shared -o libceler32.so -z noexecstack -soname libceler32.so celer32.o
;    strip --strip-all libceler32.so
format ELF

section '.text' executable

PUBLIC Java_com_celer_N_c ; Close comm device
Java_com_celer_N_c:
   push ebx
   mov ebx, [esp + 12]         ; fd
   push 3                      ; FREAD | FWRITE
   mov edx, esp
   mov ecx, 80047410h          ; request = TIOCFLUSH
   mov eax, 54                 ; sys_ioctl
   int 80h
   mov eax, 6                  ; sys_close
   int 80h
   pop edx
   pop ebx
   retn

PUBLIC Java_com_celer_N_o ; Open comm device and setup timeouts
Java_com_celer_N_o:
   push ebp
   push esi
   mov esi, [esp + 12]         ; *JEnv
   push ebx
   mov ebp, [esi]
   push 0                      ; *isCopy
   push DWORD [esp + 28]       ; string
   push esi                    ; *JEnv
   call DWORD [ebp + 169 * 4]  ; GetStringUTFChars
   add esp, 12
   test eax, eax
   jz ropen
   push eax                    ; *utf
   mov ecx, 902h               ; O_NOCTTY | O_NONBLOCK | O_RDWR
   mov ebx, eax                ; filename
   mov eax, 5                  ; sys_open
   cdq                         ; mode
   int 80h
   push DWORD [esp + 28]       ; string
   xchg eax, ebx
   push esi                    ; *JEnv
   call DWORD [ebp + 170 * 4]  ; ReleaseStringUTFChars
   add esp, 12
   test ebx, ebx               ; fd
   js ropen2
   call @f
@@:
   pop edx
   add edx, TERMIOS - @b
   mov ecx, 80487414h          ; request = TIOCSETA
   mov eax, 54                 ; sys_ioctl
   int 80h
   xchg eax, ebx
   inc eax
ropen:
   dec eax
   pop ebx
   pop esi
   pop ebp
   retn
ropen2:
   xor eax, eax
   jmp ropen

PUBLIC Java_com_celer_N_r ; Read from comm device
Java_com_celer_N_r:
   push ebp
   push esi
   push edi
   mov esi, [esp + 16]         ; *JEnv
   mov ebp, [esi]
   push 0                      ; *isCopy
   push DWORD [esp + 32]       ; array
   push esi                    ; *JEnv
   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
   add esp, 12
   test eax, eax
   mov edi, eax
   jz rread
   push ebx
   mov eax, [esp + 36]         ; off
   mov edx, [esp + 40]         ; count
   lea ecx, [edi + eax]        ; *buf
   mov ebx, [esp + 28]         ; fd
   mov eax, 3                  ; sys_read
   int 80h
   pop ebx
   push 0                      ; mode = 0: copy back content and free elems buffer
   push edi                    ; *elems
   push DWORD [esp + 36]       ; array
   mov edi, eax
   push esi                    ; *JEnv
   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
   mov eax, edi
   add esp, 16
   cmp eax, -4                 ; transparently skip EINTR
   je aread
   cmp eax, -11                ; transparently skip EAGAIN
   je aread
   test eax, eax
   jnz rread
   lea edx, [esp + 16]         ; *argp
   mov ecx, 4004746ah          ; request = TIOCMGET
   mov eax, 54                 ; sys_ioctl
   int 80h
rread:
   pop edi
   pop esi
   pop ebp
   retn
aread:
   xor eax, eax
   jmp rread

PUBLIC Java_com_celer_N_w ; Write to comm device
Java_com_celer_N_w:
   push ebp
   push edi
   push esi
   mov edi, [esp + 16]         ; *JEnv
   mov ebp, [edi]
   push 0                      ; *isCopy
   push DWORD [esp + 32]       ; array
   push edi                    ; *JEnv
   call DWORD [ebp + 184 * 4]  ; GetByteArrayElements
   add esp, 12
   test eax, eax
   mov esi, eax
   jz @f
   push ebx
   mov eax, [esp + 36]         ; off
   mov edx, [esp + 40]         ; count
   lea ecx, [esi + eax]        ; *buf
   mov ebx, [esp + 28]         ; fd
   mov eax, 4                  ; sys_write
   int 80h
   pop ebx
   push 2                      ; mode = JNI_ABORT: free buffer without copying back the possible changes
   push esi                    ; *elems
   push DWORD [esp + 36]       ; array
   mov esi, eax
   push edi                    ; *JEnv
   call DWORD [ebp + 192 * 4]  ; ReleaseByteArrayElements
   mov eax, esi
   add esp, 16
@@:
   pop esi
   pop edi
   pop ebp
   retn

align 4
TERMIOS dd 401h     ; c_iflag = IGNBRK | IXON
        dd 0        ; c_oflag
        dd 4B0h     ; c_cflag = HUPCL | CREAD | CS8
        dd 0        ; c_lflag
        db 0        ; c_line
        db 0        ; c_cc.VINTR
        db 0        ; c_cc.VQUIT
        db 0        ; c_cc.VERASE
        db 0        ; c_cc.VKILL
        db 0        ; c_cc.VEOF
        db 2        ; c_cc.VTIME = 200 ms
        db 0        ; c_cc.VMIN  = 0
        db 0        ; c_cc.VSWTC
        db 0        ; c_cc.VSTART
        db 0        ; c_cc.VSTOP
        db 0        ; c_cc.VSUSP
        db 0        ; c_cc.VEOL
        db 0        ; c_cc.VREPRINT
        db 0        ; c_cc.VDISCARD
        db 0        ; c_cc.VWERASE
        db 0        ; c_cc.VLNEXT
        db 0        ; c_cc.VEOL2
        db 0, 0     ; c_cc reserved
        dd 0        ; c_ispeed
        dd 0        ; c_ospeed
