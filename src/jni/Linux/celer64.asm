; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: September 2020
; ---------------------------
; Native COM driver for Linux 64-bit
; Compile using FASM: http://flatassembler.net/
; Linker / strip commands:
;    ld -m elf_x86_64 -shared -o libceler64.so -z noexecstack -soname libceler64.so celer64.o
;    strip --strip-all libceler64.so
format ELF64

section '.text' executable

PUBLIC Java_com_celer_N_c ; Close comm device
Java_com_celer_N_c:
   push rdx
   mov edi, edx                ; fd
   push 3                      ; FREAD | FWRITE
   mov rdx, rsp
   mov esi, 80047410h          ; request = TIOCFLUSH
   mov eax, 16                 ; sys_ioctl
   syscall
   pop rax
   pop rdi                     ; fd
   mov eax, 3                  ; sys_close
   syscall
   retn

PUBLIC Java_com_celer_N_o ; Open comm device and setup timeouts
Java_com_celer_N_o:
   push rbx
   push rbp
   mov rbx, rdi                ; *JEnv
   push rdx
   mov rbp, [rdi]
   mov rsi, rdx                ; string
   xor rdx, rdx                ; *isCopy
   call QWORD [rbp + 169 * 8]  ; GetStringUTFChars
   test rax, rax
   jz ropen
   push rax
   mov esi, 902h               ; O_NOCTTY | O_NONBLOCK | O_RDWR
   mov rdi, rax                ; filename
   mov eax, 2                  ; sys_open
   cdq                         ; mode
   syscall
   pop rdx                     ; *utf
   pop rsi                     ; string
   mov rdi, rbx                ; *JEnv
   push rax
   call QWORD [rbp + 170 * 8]  ; ReleaseStringUTFChars
   mov rdi, [rsp]              ; fd
   test edi, edi
   js ropen2
   lea rdx, [TERMIOS]
   mov esi, 80487414h          ; request = TIOCSETA
   mov eax, 16                 ; sys_ioctl
   syscall
   mov rax, [rsp]
   inc rax
ropen:
   dec rax
   pop rdx
   pop rbp
   pop rbx
   retn
ropen2:
   xor rax, rax
   jmp ropen

PUBLIC Java_com_celer_N_r ; Read from comm device
Java_com_celer_N_r:
   push rbx
   push rbp
   mov rbx, rdi                ; *JEnv
   push rdx
   mov rbp, [rdi]
   push rcx
   xor rdx, rdx                ; *isCopy
   push r8
   mov rsi, rcx                ; array
   push r9
   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
   test rax, rax
   jz rread
   mov edx, [rsp + 8]          ; off
   lea rsi, [rax + rdx]        ; *buf
   mov rdx, [rsp]              ; count
   mov rdi, [rsp + 24]         ; fd
   push rax
   xor eax, eax                ; sys_read
   syscall
   pop rdx                     ; *elems
   xor rcx, rcx                ; mode = 0: copy back content and free elems buffer
   mov rsi, [rsp + 16]         ; array
   mov rdi, rbx                ; *JEnv
   push rax
   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
   pop rax
   cmp eax, -4                 ; transparently skip EINTR
   je aread
   cmp eax, -11                ; transparently skip EAGAIN
   je aread
   test eax, eax
   jnz rread
   mov rdx, rsp                ; *argp
   mov esi, 4004746ah          ; request = TIOCMGET
   mov rdi, [rsp + 24]         ; fd
   mov eax, 16                 ; sys_ioctl
   syscall
rread:
   add rsp, 32
   pop rbp
   pop rbx
   retn
aread:
   xor rax, rax
   jmp rread

PUBLIC Java_com_celer_N_w ; Write to comm device
Java_com_celer_N_w:
   push rbx
   push rbp
   mov rbx, rdi                ; *JEnv
   push rdx
   mov rbp, [rdi]
   push rcx
   xor rdx, rdx                ; *isCopy
   push r8
   mov rsi, rcx                ; array
   push r9
   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
   test rax, rax
   jz @f
   mov edx, [rsp + 8]          ; off
   lea rsi, [rax + rdx]        ; *buf
   mov rdx, [rsp]              ; count
   mov rdi, [rsp + 24]         ; fd
   push rax
   mov eax, 1                  ; sys_write
   syscall
   pop rdx                     ; *elems
   mov ecx, 2                  ; mode = JNI_ABORT: free buffer without copying back the possible changes
   mov rsi, [rsp + 16]         ; array
   mov rdi, rbx                ; *JEnv
   push rax
   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
   pop rax
@@:
   add rsp, 32
   pop rbp
   pop rbx
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
