;nasm -f elf64 -o counter.o counter.asm
;ld -o counter_execute counter.o
;./counter_execute


%include "linux64.inc"

section .data
    filename db "my_list.txt",0
section .bss    
    text resb 124            ; buffer para leer archivo
    l_text equ 124
    num_buffer resb 20   ; buffer para imprimir número de palabras

section .text   
    global _start

_start:
;------Abrir archivo-------
    mov rax, SYS_OPEN
    mov rdi, filename
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    push rax                ; guardar descriptor de archivo

    xor r8, r8              ; acumulador total de palabras

read_loop:
;-----Lectura archivo txt------------------------------
    pop rdi                 ; recuperar descriptor de archivo
    push rdi                ; guardar de nuevo
    mov rax, SYS_READ
    mov rsi, text
    mov rdx, l_text
    syscall

    cmp rax, 0
    je done_file            ; fin del archivo

    mov rdx, rax            ; cantidad de bytes leídos se almacen de rax a rdx

;------Contar palabras en este bloque-------
    xor rcx, rcx            ; contador de palabras en bloque
    xor rbx, rbx            ; flag inside-word
    mov rsi, text           ; puntero en lectura del texto
    mov r9, rdx             ; límite del buffer leído

count_loop:

    mov r10, text
    add r10, r9
    cmp rsi, r10
    jge count_done

    mov al, [rsi]
    cmp al, ' '
    je sep
    cmp al, 10
    je sep

    cmp rbx, 1              ;Is it inside for the word 
    je next_char            
    add rcx, 1              ; nueva palabra
    mov rbx, 1
    jmp next_char

sep:
    mov rbx, 0

next_char:
    inc rsi                 ; increse the read
    jmp count_loop

count_done:
    add r8, rcx             ; acumular total de palabras

;---------Imprime valores del bloque leido (opcional)---------------------
    mov rdx, rdx            ; cantidad de bytes leídos
    ;print text                                                                 ; we dont want to write on the screen

    jmp read_loop

done_file:
;--------Cerrar archivo-------------
    mov rax, SYS_CLOSE
    pop rdi
    syscall

;------Convertir r8 (total palabras) a ASCII-------
    mov rax, r8
    mov rdi, num_buffer + 19
    xor rcx, rcx

    cmp rax, 0
    jne conv_loop
    mov byte [rdi], '0'
    inc rcx
    jmp print_number

conv_loop:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    inc rcx
    cmp rax, 0
    jne conv_loop

print_number:
    inc rdi
    mov rsi, rdi
    mov rdx, rcx
    mov rax, SYS_WRITE
    mov rdi, 1          ; stdout
    syscall

;------Imprimir salto de línea-------
    mov rax, SYS_WRITE
    mov rdi, 1
    lea rsi, [num_buffer+20]
    mov byte [rsi-1], 10
    mov rdx, 1
    syscall

;--------Salir-------------
    exit