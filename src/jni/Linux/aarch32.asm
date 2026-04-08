; Copyright CelerSMS - All Rights Reserved
; Unauthorized copying of this file, via any medium is strictly prohibited
; Proprietary and confidential
; Author: Victor Celer <admin@celersms.com>
; Last Update: December 2020
; ---------------------------
; Native COM driver for Linux ARM 32-bit
; Compile using FASMARM: http://arm.flatassembler.net/
; Linker / strip commands:
;    ld -m armelf_linux_eabi -shared -o libaarch32.so -z noexecstack -soname libaarch32.so aarch32.o
;    strip --strip-all libaarch32.so
format ELF

section '.text' executable

PUBLIC Java_com_celer_N_c ; Close comm device
Java_com_celer_N_c:
   stmfd sp!,{r4,lr}
   mov r4,r2
   mov r1,3                    ; FREAD | FWRITE
   str r1,[sp,-4]
   sub sp,sp,4
   mov r2,sp
   ldr r1,[TIOCF]              ; request = TIOCFLUSH
   mov r0,r2                   ; fd
   swi 0x900036                ; sys_ioctl
   add sp,sp,4
   mov r0,r4                   ; fd
   swi 0x900006                ; sys_close
   ldmfd sp!,{r4,pc}

PUBLIC Java_com_celer_N_o ; Open comm device and setup timeouts
Java_com_celer_N_o:
   stmfd sp!,{r4-r7,lr}
   mov r4,r0                   ; *JEnv
   mov r6,r2
   ldr r5,[r4]
   mov r1,r2                   ; string
   mov r2,0                    ; *isCopy
   ldr r7,[r5 + 169 * 4]       ; GetStringUTFChars
   blx r7
   tst r0,r0
   beq ropen
   mov r7,r0                   ; filename

   ; Debug
;   mov r2,r0
;@@:
;   ldrb r3,[r2],1
;   tst r3,r3
;   bne @b
;   sub r2,r2,r0
;   sub r2,r2,1                 ; len
;   mov r1,r0                   ; str
;   mov r0,0                    ; stdout
;   swi 0x900004                ; sys_write
;   mov r0,r7

   mov r2,0                    ; mode
   mov r1,900h                 ; O_NOCTTY | O_NONBLOCK | O_RDWR
   add r1,r1,2
   swi 0x900005                ; sys_open
   mov r2,r7                   ; *utf
   mov r1,r6                   ; string
   mov r7,r0
   mov r0,r4                   ; *JEnv
   ldr r5,[r5 + 170 * 4]       ; ReleaseStringUTFChars
   blx r5
   mov r0,r7                   ; fd
   tst r7,r7
   bmi ropen
   adr r2,TERMIOS
   ldr r1,[TIOCS]              ; request = TIOCSETA
   swi 0x900036                ; sys_ioctl
   mov r0,r7
   b ropen2
ropen:
   mov r0,-1
ropen2:
   ldmfd sp!,{r4-r7,pc}

PUBLIC Java_com_celer_N_r ; Read from comm device
Java_com_celer_N_r:
   stmfd sp!,{r4-r7,lr}
   mov r0,0
   ldmfd sp!,{r4-r7,pc}

;   push rbx
;   push rbp
;   mov rbx, rdi                ; *JEnv
;   push rdx
;   mov rbp, [rdi]
;   push rcx
;   xor rdx, rdx                ; *isCopy
;   push r8
;   mov rsi, rcx                ; array
;   push r9
;   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
;   test rax, rax
;   jz rread
;   mov edx, [rsp + 8]          ; off
;   lea rsi, [rax + rdx]        ; *buf
;   mov rdx, [rsp]              ; count
;   mov rdi, [rsp + 24]         ; fd
;   push rax
;   xor eax, eax                ; sys_read
;   syscall
;   pop rdx                     ; *elems
;   xor rcx, rcx                ; mode = 0: copy back content and free elems buffer
;   mov rsi, [rsp + 16]         ; array
;   mov rdi, rbx                ; *JEnv
;   push rax
;   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
;   pop rax
;   cmp eax, -4                 ; transparently skip EINTR
;   jne @f
;   xor rax, rax
;   jmp rread
;@@:
;   cmp eax, -11                ; transparently skip EAGAIN
;   jne @f
;   xor rax, rax
;   jmp rread
;@@:
;   test eax, eax
;   jnz rread
;   mov rdx, rsp                ; *argp
;   mov esi, 4004746ah          ; request = TIOCMGET
;   mov rdi, [rsp + 24]         ; fd
;   mov eax, 16                 ; sys_ioctl
;   syscall
;rread:
;   add rsp, 32
;   pop rbp
;   pop rbx
;   retn

PUBLIC Java_com_celer_N_w ; Write to comm device
Java_com_celer_N_w:
   stmfd sp!,{r4-r7,lr}
   mov r0,0
   ldmfd sp!,{r4-r7,pc}

;   push rbx
;   push rbp
;   mov rbx, rdi                ; *JEnv
;   push rdx
;   mov rbp, [rdi]
;   push rcx
;   xor rdx, rdx                ; *isCopy
;   push r8
;   mov rsi, rcx                ; array
;   push r9
;   call QWORD [rbp + 184 * 8]  ; GetByteArrayElements
;   test rax, rax
;   jz @f
;   mov edx, [rsp + 8]          ; off
;   lea rsi, [rax + rdx]        ; *buf
;   mov rdx, [rsp]              ; count
;   mov rdi, [rsp + 24]         ; fd
;   push rax
;   mov eax, 1                  ; sys_write
;   syscall
;   pop rdx                     ; *elems
;   mov ecx, 2                  ; mode = JNI_ABORT: free buffer without copying back the possible changes
;   mov rsi, [rsp + 16]         ; array
;   mov rdi, rbx                ; *JEnv
;   push rax
;   call QWORD [rbp + 192 * 8]  ; ReleaseByteArrayElements
;   pop rax
;@@:
;   add rsp, 32
;   pop rbp
;   pop rbx
;   retn

align 4
TIOCF   dw 80047410h
TIOCS   dw 80487414h
TERMIOS dw 401h     ; c_iflag = IGNBRK | IXON
        dw 0        ; c_oflag
        dw 4B0h     ; c_cflag = HUPCL | CREAD | CS8
        dw 0        ; c_lflag
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
        dw 0        ; c_ispeed
        dw 0        ; c_ospeed
