/*
  Copyright CelerSMS - All Rights Reserved
  Unauthorized copying of this file, via any medium is strictly prohibited
  Proprietary and confidential
  Author: Victor Celer <admin@celersms.com>
  Last Update: December 2020
  ---------------------------
  Native COM driver for Linux ARM 32-bit
  Compile using GNU as:
     as -o aarch32.o aarch32.s
  Linker / strip commands:
     gcc -static -shared -o libaarch32.so -z noexecstack aarch32.o
     strip --strip-all libaarch32.so
  Remove unnecessary sections:
     objcopy -R .eh_frame -R .jcr libaarch32.so
*/
.data
.balign 4

TERMIOS: .word 0x401    /* c_iflag = IGNBRK | IXON */
         .word 0        /* c_oflag */
         .word 0x4B0    /* c_cflag = HUPCL | CREAD | CS8 */
         .word 0        /* c_lflag */
         .byte 0        /* c_line */
         .byte 0        /* c_cc.VINTR */
         .byte 0        /* c_cc.VQUIT */
         .byte 0        /* c_cc.VERASE */
         .byte 0        /* c_cc.VKILL */
         .byte 0        /* c_cc.VEOF */
         .byte 2        /* c_cc.VTIME = 200 ms */
         .byte 0        /* c_cc.VMIN  = 0 */
         .byte 0        /* c_cc.VSWTC */
         .byte 0        /* c_cc.VSTART */
         .byte 0        /* c_cc.VSTOP */
         .byte 0        /* c_cc.VSUSP */
         .byte 0        /* c_cc.VEOL */
         .byte 0        /* c_cc.VREPRINT */
         .byte 0        /* c_cc.VDISCARD */
         .byte 0        /* c_cc.VWERASE */
         .byte 0        /* c_cc.VLNEXT */
         .byte 0        /* c_cc.VEOL2 */
         .byte 0, 0     /* c_cc reserved */
         .word 0        /* c_ispeed */
         .word 0        /* c_ospeed */

.text
.balign 4

.globl Java_com_celer_N_c /* Close comm device */
Java_com_celer_N_c:
   stmfd sp!,{r4,r7,lr}
   mov r4,r2
   mov r1,#3                    /* FREAD | FWRITE */
   sub sp,sp,#4
   str r1,[sp]
   mov r2,sp
   ldr r1,=#0x80047410         /* request = TIOCFLUSH */
   mov r0,r2                   /* fd */
   mov r7,#0x36                /* sys_ioctl */
   swi #0
   add sp,sp,#4
   mov r0,r4                   /* fd */
   mov r7,#0x6                 /* sys_close */
   swi #0
   ldmfd sp!,{r4,r7,pc}

.globl Java_com_celer_N_o /* Open comm device and setup timeouts */
Java_com_celer_N_o:
   stmfd sp!,{r4-r8,lr}
   mov r4,r0                   /* *JEnv */
   mov r6,r2
   ldr r5,[r0]
   mov r1,r2                   /* string */
   mov r2,#0                   /* *isCopy */
   ldr r8,[r5,#169 * 4]        /* GetStringUTFChars */
   blx r8
   tst r0,r0
   beq ropen
   mov r8,r0                   /* filename */
   mov r2,#0                   /* mode */
   mov r1,#0x900               /* O_NOCTTY | O_NONBLOCK | O_RDWR */
   add r1,r1,#2
   mov r7,#0x5                 /* sys_open */
   swi #0
   mov r2,r8                   /* *utf */
   mov r1,r6                   /* string */
   mov r8,r0
   mov r0,r4                   /* *JEnv */
   ldr r5,[r5,#170 * 4]        /* ReleaseStringUTFChars */
   blx r5
   mov r0,r8                   /* fd */
   tst r8,r8
   bmi ropen
   ldr r2,addr_TERMIOS
   ldr r1,=#0x80487414         /* request = TIOCSETA */
   mov r7,#0x36                /* sys_ioctl */
   swi #0
   mov r0,r8
   b ropen2
ropen:
   mov r0,#-1
ropen2:
   ldmfd sp!,{r4-r8,pc}
addr_TERMIOS: .word TERMIOS

.globl Java_com_celer_N_r /* Read from comm device */
Java_com_celer_N_r:
   stmfd sp!,{r4-r10,lr}
   mov r4,r0                   /* *JEnv */
   mov r6,r2
   ldr r8,[sp,#32]             /* off */
   ldr r9,[sp,#36]             /* count */
   mov r10,r3
   ldr r5,[r0]
   mov r1,r3                   /* array */
   mov r2,#0                   /* *isCopy */
   ldr r7,[r5,#184 * 4]        /* GetByteArrayElements */
   blx r7
   tst r0,r0
   beq rread
   add r1,r0,r8                /* *buf */
   mov r8,r0
   mov r2,r9                   /* count */
   mov r0,r6                   /* fd */
   mov r7,#0x3                 /* sys_read */
   swi #0
   mov r9,r0
   mov r3,#0                   /* mode = 0: copy back content and free elems buffer */
   mov r2,r8                   /* *elem */
   mov r1,r10                  /* array */
   mov r0,r4                   /* *JEnv */
   ldr r5,[r5,#192 * 4]        /* ReleaseByteArrayElements */
   blx r5
   mov r0,r9
   cmp r0,#-4                  /* transparently skip EINTR */
   beq aread
   cmp r0,#-11                 /* transparently skip EAGAIN */
   beq aread
   tst r0,r0
   bne rread
   add r2,sp,#32               /* *argp */
   ldr r1,=#0x4004746a         /* request = TIOCMGET */
   mov r0,r6                   /* fd */
   mov r7,#0x36                /* sys_ioctl */
   swi #0
rread:
   ldmfd sp!,{r4-r10,pc}
aread:
   mov r0,#0
   b rread

.globl Java_com_celer_N_w /* Write to comm device */
Java_com_celer_N_w:
   stmfd sp!,{r4-r10,lr}
   mov r4,r0                   /* *JEnv */
   mov r6,r2
   ldr r8,[sp,#32]             /* off */
   ldr r9,[sp,#36]             /* count */
   mov r10,r3
   ldr r5,[r0]
   mov r1,r3                   /* array */
   mov r2,#0                   /* *isCopy */
   ldr r7,[r5,#184 * 4]        /* GetByteArrayElements */
   blx r7
   tst r0,r0
   beq rwrit
   mov r2,r9                   /* count */
   mov r9,r0
   add r1,r0,r8                /* *buf */
   mov r0,r6                   /* fd */
   mov r7,#0x4                 /* sys_write */
   swi #0
   mov r3,#2                   /* mode = JNI_ABORT: free buffer without copying back the possible changes */
   mov r2,r9                   /* *elem */
   mov r9,r0
   mov r1,r10                  /* array */
   mov r0,r4                   /* *JEnv */
   ldr r5,[r5,#192 * 4]        /* ReleaseByteArrayElements */
   blx r5
   mov r0,r9
rwrit:
   ldmfd sp!,{r4-r10,pc}
