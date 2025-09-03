; ============================================
; Visualizador de Inventario - NASM x86_64 Linux
; ============================================
; Compilación:
; nasm -f elf64 -o inventory.o inventory.asm
; ld -o inventory inventory.o
; ./inventory
%include "linux64.inc"

section .data
    file_inventory db "my_list.txt",0
    file_config    db "config.ini",0
    nl             db 10
    sep_colon      db ": ",0
    default_char   db '#',0
    default_fg     db 92      ; verde brillante
    default_bg     db 40      ; fondo negro

section .bss
    buffer      resb 256           ; lectura de archivos
    temp_word   resb 16            ; palabra temporal
    word_table  resb 4096          ; hasta 256 palabras de 16 bytes
    word_count  resd 256
    num_words   resd 1

    config_char resb 1
    config_fg   resb 1
    config_bg   resb 1

section .text
global _start
_start:

; -----------------------------
; 1️⃣ Leer config.ini
; -----------------------------
    mov rdi, file_config
    call read_config

; -----------------------------
; 2️⃣ Leer archivo de inventario
; -----------------------------
    mov rdi, file_inventory
    call read_inventory

; -----------------------------
; 3️⃣ Ordenar alfabéticamente
; -----------------------------
    call bubble_sort

; -----------------------------
; 4️⃣ Imprimir gráfico de barras
; -----------------------------
    call print_graph

; -----------------------------
; 5️⃣ Salir
; -----------------------------
    mov rax, 60
    xor rdi, rdi
    syscall

; ====================================================
; Funciones
; ====================================================

; -----------------------------
; read_config
; -----------------------------
; rdi = puntero a archivo config.ini
read_config:
    ; por simplicidad, usamos valores por defecto
    mov al, [default_char]
    mov [config_char], al
    mov al, [default_fg]
    mov [config_fg], al
    mov al, [default_bg]
    mov [config_bg], al
    ret

; -----------------------------
; read_inventory
; -----------------------------
; rdi = puntero a archivo inventory.txt
read_inventory:
    ; abrir archivo
    mov rax, 2
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r12, rax      ; fd
    xor r9, r9        ; len palabra
read_loop_inv:
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 256
    syscall
    cmp rax, 0
    je eof_flush_inv
    mov r11, rax
    xor r10, r10
next_char_inv:
    cmp r10, r11
    je read_loop_inv
    mov al,[buffer + r10]
    cmp al,' '
    je end_word_inv
    cmp al,10
    je end_word_inv
    cmp r9,15
    ja too_long_inv
    mov [temp_word + r9], al
    inc r9
    inc r10
    jmp next_char_inv
end_word_inv:
    cmp r9,0
    je skip_sep_inv
    mov byte [temp_word + r9],0
    mov rdi, temp_word
    call find_or_add_word
skip_sep_inv:
    xor r9,r9
    inc r10
    jmp next_char_inv
too_long_inv:
    xor r9,r9
    inc r10
    jmp next_char_inv
eof_flush_inv:
    cmp r9,0
    je close_file_inv
    mov byte [temp_word + r9],0
    mov rdi, temp_word
    call find_or_add_word
close_file_inv:
    mov rax,3
    mov rdi,r12
    syscall
    ret

; -----------------------------
; find_or_add_word
; -----------------------------
; rdi = puntero a palabra
find_or_add_word:
    mov rax,[num_words]
    test rax,rax
    jz .add_new
    xor rcx,rcx
.next_word:
    mov rdx, rcx
    imul rdx,16
    lea rsi,[word_table+rdx]
    xor r8, r8
.compare_loop:
    mov al,[rsi + r8]
    mov bl,[rdi + r8]
    cmp al,bl
    jne .next
    cmp al,0
    je .found
    inc r8
    jmp .compare_loop
.next:
    inc rcx
    mov rax,[num_words]
    cmp rcx,rax
    jl .next_word
.add_new:
    mov rax,[num_words]
    imul rax,16
    lea rsi,[word_table+rax]
    xor rdx, rdx
.copy_loop:
    mov al,[rdi+rdx]
    mov [rsi+rdx],al
    cmp al,0
    je .done_copy
    inc rdx
    jmp .copy_loop
.done_copy:
    mov eax,[num_words]
    mov dword [word_count + rax*4],1
    inc dword [num_words]
    ret
.found:
    mov rax,rcx
    inc dword [word_count + rax*4]
    ret

; -----------------------------
; bubble_sort
; -----------------------------
bubble_sort:
    mov rax,[num_words]
    dec rax
    mov r8,rax
.outer:
    xor rbx,rbx
.inner:
    mov rdx,rbx
    mov rsi,word_table
    imul rdx,16
    add rsi,rdx
    mov rdi,rsi
    add rdi,16
    call cmp_words
    cmp al,1
    jne .no_swap
    call swap_words
.no_swap:
    inc rbx
    cmp rbx,r8
    jl .inner
    dec r8
    cmp r8,0
    jg .outer
    ret

; -----------------------------
; cmp_words
; -----------------------------
; compara palabras en rsi y rdi
; devuelve AL=1 si se deben intercambiar
cmp_words:
    xor rcx,rcx
.loop:
    mov al,[rsi+rcx]
    mov bl,[rdi+rcx]
    cmp al,bl
    ja .swap_needed
    jb .no_swap_needed
    cmp al,0
    je .no_swap_needed
    inc rcx
    jmp .loop
.swap_needed:
    mov al,1
    ret
.no_swap_needed:
    xor al,al
    ret

; -----------------------------
; swap_words
; -----------------------------
swap_words:
    push rsi
    push rdi
    xor rcx,rcx
.swap_loop:
    mov al,[rsi+rcx]
    mov bl,[rdi+rcx]
    mov [rsi+rcx],bl
    mov [rdi+rcx],al
    cmp al,0
    je .done_swap
    inc rcx
    jmp .swap_loop
.done_swap:
    pop rdi
    pop rsi
    ; intercambiar contadores
    mov rax,rsi
    sub rax,word_table
    shr rax,4           ; índice palabra1
    mov rbx,rdi
    sub rbx,word_table
    shr rbx,4           ; índice palabra2
    mov ecx,[word_count + rax*4]
    mov edx,[word_count + rbx*4]
    mov [word_count + rax*4],edx
    mov [word_count + rbx*4],ecx
    ret

; -----------------------------
; print_graph
; -----------------------------
print_graph:
    xor rcx,rcx
    mov rax,[num_words]
    test rax,rax
    jz .done_print
.print_loop:
    cmp rcx,rax
    jae .done_print
    ; imprimir palabra
    mov rsi, word_table
    mov rdx, rcx
    imul rdx,16
    add rsi,rdx
    ; longitud palabra
.len_loop_print:
    mov al,[rsi]
    cmp al,0
    je .print_sep
    mov rax,1
    mov rdi,1
    mov rdx,1
    mov rsi,rsi
    syscall
    inc rsi
    jmp .len_loop_print
.print_sep:
    ; imprimir ": "
    mov rax,1
    mov rdi,1
    mov rsi,sep_colon
    mov rdx,2
    syscall
    ; imprimir barras
    mov rax,[word_count+rcx*4]
    mov rbx,rax
    mov al,[config_char]
.print_bars:
    cmp rbx,0
    je .print_number_count
    mov rax,1
    mov rdi,1
    mov rsi,config_char
    mov rdx,1
    syscall
    dec rbx
    jmp .print_bars
.print_number_count:
    mov eax,[word_count+rcx*4]
    call print_number
    ; salto de línea
    mov rax,1
    mov rdi,1
    mov rsi,nl
    mov rdx,1
    syscall
    inc rcx
    jmp .print_loop
.done_print:
    ret

; -----------------------------
; print_number
; -----------------------------
print_number:
    xor rdx, rdx
    mov rcx, 10
    mov rcx,10
    sub rsp,16
    lea rsi,[rsp+16]
.convert:
    xor rdx,rdx
    div rcx
    add dl,'0'
    dec rsi
    mov [rsi],dl
    test rax,rax
    jnz .convert
    mov rax,1
    mov rdi,1
    lea rdx,[rsp+16]
    sub rdx,rsi
    mov rsi,rsi
    syscall
    add rsp,16
    ret