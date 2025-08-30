; Filename: colorful_hello_64.asm
; To assemble and run:
; nasm -f elf64 -o data_visualizer.o data_visualizer.asm
; ld -o data_visualizer_execute data_visualizer.o
; ./data_visualizer_execute

;----------includes----------

section .data
;----------Read----------
    filename db "My_list",0xa

    ; --- ANSI Escape Codes for Colors ---
    ; Format: \x1b[<text_color>;<background_color>m
    ; \x1b is the ESC character (decimal 27)

    ; Color 1: Red text (31) on a Blue background (44)
    color1 db 0x1b, "[31;44m"
    color1_len equ $ - color1

    ; Color 2: Green text (32) on a Yellow background (43)
    color2 db 0x1b, "[32;43m"
    color2_len equ $ - color2

    ; Color 3: Magenta text (35) on a Cyan background (46)
    color3 db 0x1b, "[35;46m"
    color3_len equ $ - color3

    ; Reset Code: Resets terminal colors to default
    reset_color db 0x1b, "[0m"
    reset_color_len equ $ - reset_color

                                                    ;Un
section .bss                                       
    ; --- The message to be printed ---
    msg resb 128
    msg_len equ $ - msg                             ; Calculate the length of the string

    msg1 resb 128                                   ; The string, 0xa is the newline character
    msg1_len equ $ - msg1                           ; Calculate the length of the string

    msg2 resb 124                                   ;The string, 0xa is the newline character
    msg2_len equ $ - msg2                           ; Calculate the length of the string




section .text
    global _start

_start:
    ; --- First Print: Red on Blue ---
    ; Set the color

    mov rax, 1              ; syscall number for sys_write
    mov rdi, 1              ; file descriptor 1 is stdout
    mov rsi, color1         ; pointer to the color1 string
    mov rdx, color1_len     ; length of the color1 string
    syscall                 ; call the kernel

    ; read the message
    mov rax, 0
    mov rdi, 0
    mov rsi, msg
    mov rdx, msg_len
    syscall

    ; write the message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, msg_len
    syscall


    ; --- Second Print: Green on Yellow ---
    ; Set the color
    mov rax, 1
    mov rdi, 1
    mov rsi, color2
    mov rdx, color2_len
    syscall

    ; read the message
    mov rax, 0
    mov rdi, 0
    mov rsi, msg1
    mov rdx, msg1_len
    syscall

    ; write the message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg1
    mov rdx, msg1_len
    syscall


    ; --- Third Print: Magenta on Cyan ---
    ; Set the color
    mov rax, 1
    mov rdi, 1
    mov rsi, color3
    mov rdx, color3_len
    syscall

    ; read the message
    mov rax, 0
    mov rdi, 0
    mov rsi, msg2
    mov rdx, msg2_len
    syscall

    ; Write the message
    mov rax, 1
    mov rdi, 1
    mov rsi, msg2
    mov rdx, msg2_len
    syscall


    ; --- Reset the terminal color to default ---
    mov rax, 1
    mov rdi, 1
    mov rsi, reset_color
    mov rdx, reset_color_len
    syscall

    ; --- Exit the program gracefully ---
    mov rax, 60             ; syscall number for sys_exit
    mov rdi, 0              ; exit code 0 (success)
    syscall                 ; call the kernel

