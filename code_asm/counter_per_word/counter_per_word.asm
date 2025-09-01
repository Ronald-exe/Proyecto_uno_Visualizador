;nasm -f elf64 -o  counter_per_word.o counter_per_word.asm
;ld -o  counter_per_word_execute  counter_per_word.o
;./counter_per_word_execute

%include "linux64.inc"

section .data
    filename   db "my_list.txt",0
    sep_colon  db ": ",0
    nl         db 10

section .bss
    text      resb 256
    len_count resb 64      ; contador de palabras por longitud (1..64)
    max_len   resb 1       ; longitud máxima vista (en bytes)

section .text
    global _start

_start:
    ; --- abrir archivo ---
    mov     rax, 2                 ; SYS_open
    mov     rdi, filename
    xor     rsi, rsi               ; O_RDONLY
    xor     rdx, rdx
    syscall
    cmp     rax, 0
    js      open_fail
    mov     r12, rax               ; fd (guardado en r12)

    xor     r9, r9                 ; longitud actual de la palabra (contador)
    xor     r10, r10               ; índice en buffer
    xor     r11, r11               ; bytes leídos en buffer
    xor     rbx, rbx               ; limpiar rbx por seguridad

read_loop:
    mov     rax, 0                 ; SYS_read
    mov     rdi, r12
    mov     rsi, text
    mov     rdx, 256
    syscall
    cmp     rax, 0
    js      read_fail
    je      eof_flush              ; si EOF, flusheamos última palabra (si hay)
    mov     r10, 0                 ; índice buffer = 0
    mov     r11, rax               ; bytes leídos

next_char:
    cmp     r10, r11
    je      read_loop

    mov     al, [text + r10]
    cmp     al, ' '
    je      end_word
    cmp     al, 10
    je      end_word

    ; dentro de palabra
    inc     r9
    cmp     r9, 64                 ; límite razonable (1..64)
    ja      too_long
    inc     r10
    jmp     next_char

end_word:
    cmp     r9, 0
    je      skip_sep               ; separadores seguidos
    ; palabra terminada: actualizar contador por longitud
    xor     rbx, rbx               ; limpiar rbx antes de usar bl
    mov     bl, r9b                ; longitud (1..64)
    dec     bl                     ; índice 0 = palabras de 1 char
    cmp     rbx, 63
    ja      skip_sep               ; protección extra
    mov     al, [len_count + rbx]
    inc     al
    mov     [len_count + rbx], al
    ; actualizar max_len (byte)
    mov     al, [max_len]
    cmp     r9b, al
    jbe     .no_upd
    mov     [max_len], r9b
.no_upd:
    xor     r9, r9
skip_sep:
    inc     r10
    jmp     next_char

too_long:
    ; si se pasa del límite, descartar esta palabra
    xor     r9, r9
    inc     r10
    jmp     next_char

eof_flush:
    ; si el archivo no acaba en separador, la última palabra queda en r9
    cmp     r9, 0
    je      close_file
    xor     rbx, rbx
    mov     bl, r9b
    dec     bl
    cmp     rbx, 63
    ja      close_file
    mov     al, [len_count + rbx]
    inc     al
    mov     [len_count + rbx], al
    mov     al, [max_len]
    cmp     r9b, al
    jbe     close_file
    mov     [max_len], r9b

close_file:
    mov     rax, 3                 ; SYS_close
    mov     rdi, r12
    syscall
    jmp     print_results

open_fail:
    mov     rax, 60
    mov     rdi, 1
    syscall

read_fail:
    cmp     r12, 0
    jl      short_exit
    mov     rax, 3
    mov     rdi, r12
    syscall
short_exit:
    mov     rax, 60
    mov     rdi, 2
    syscall

; --- imprimir resultados ---
; Usamos r12 como índice del bucle de impresión (registro callee-saved)
print_results:
    xor     r12, r12               ; índice 0..(max_len-1)
    movzx   rdx, byte [max_len]    ; rdx = max_len (1..64)
    test    rdx, rdx
    jz      done_program

print_loop:
    cmp     r12, rdx
    jae     done_program

    mov     al, [len_count + r12]
    test    al, al
    jz      next_len

    ; imprimir longitud = (r12 + 1)
    mov     al, r12b
    inc     al
    call    print_number

    ; imprimir ": "
    mov     rax, 1                 ; SYS_write
    mov     rdi, 1                 ; stdout
    mov     rsi, sep_colon
    mov     rdx, 2
    syscall

    ; imprimir cantidad = len_count[r12]
    mov     al, [len_count + r12]
    call    print_number

    ; imprimir "\n"
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, nl
    mov     rdx, 1
    syscall

next_len:
    inc     r12
    jmp     print_loop

done_program:
    mov     rax, 60
    xor     rdi, rdi
    syscall

; ------------------------------------------------------------
; print_number
; Imprime en decimal el valor de AL (0..255)
; Clobbers: RAX, RBX, RDX, RSI
; NO modifica R12 (por eso usamos r12 en el bucle)
; ------------------------------------------------------------
print_number:
    movzx   rax, al                ; valor a convertir (0..255)
    mov     rcx, 10
    sub     rsp, 16                ; reservar pequeño buffer (mantener alineación)
    lea     rsi, [rsp+16]          ; rsi = fin del buffer
.convert:
    xor     rdx, rdx
    div     rcx                    ; rax = rax/10, rdx = rax%10
    add     dl, '0'
    dec     rsi
    mov     [rsi], dl
    test    rax, rax
    jnz     .convert

    ; write(1, rsi, (rsp+16 - rsi))
    mov     rax, 1
    mov     rdi, 1
    mov     rdx, rsp
    add     rdx, 16
    sub     rdx, rsi
    syscall

    add     rsp, 16
    ret