section .data                                                           ; practice example
    cons_hi: db 'Hola',0xa
    hi_tamano: equ $-cons_hi

section .text                                                           ;Section so that my breakpoints
    global _start               

_start:
    mov rax,1
    mov rdi,1
    mov rsi,cons_hi
    mov rdx,hi_tamano
    syscall

    mov rax,60
    mov rdi,0
    syscall
