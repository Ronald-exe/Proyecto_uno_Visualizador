; nasm -f elf64 -o read_text.o read_text.asm
; ld -o read_text_execute read_text.o
; ./read_text_execute

%include "linux64.inc"
section .data
    filename db "my_list.txt",0
section .bss    
    text resb 124
    l_text equ 124
section .text   
    global _start

_start:
;------Open file-------
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, O_RDONLY
    mov rdx, SYS_READ
    syscall

    ; Guardar el file descriptor en un apila aparte
    push rax                ; se pone en la sys_read

read_loop:
;-----lectura archivo txt------------------------------
    ; Recuperar el file descriptor para usarlo en SYS_READ
    pop rdi                 ; recupera el file descriptor de la pila en que se guardo 
    push rdi                ; lo volvemos a guardar para futuras lecturas
    mov rax, SYS_READ       ;se encarga de leer byte por byte el archivo hasta terminarlo, en otras palabtas quedan 0 bytes.
    mov rsi, text
    mov rdx, l_text
    
    syscall
;-------- comparacion para determinar salida ----------

    cmp rax, 0
    je done_file

;---------imprime valores de lista---------------------
    mov rdx, rax            ; rax tiene la cantidad de bytes leídos
    print text

;---------regresa al ciclo cuando aun hay datos ------

    jmp read_loop

done_file:
;-------- Fin del programa ------------
    mov rax, SYS_CLOSE
    pop rdi                 ; recuperar el descriptor de archivo
    syscall

    exit