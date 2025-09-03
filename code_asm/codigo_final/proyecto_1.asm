;nasm -f elf64 -o  proyecto_1.o proyecto_1.asm
;ld -o   proyecto_1_execute   proyecto_1.o
;./proyecto_1_execute

%include "linux64.inc"

section .data
;------------------------------Archivos de lectura----------------------------
    listatxt  db "inventario.txt", 0
    configtxt    db "config.txt", 0

;------------------------------Errores al abrir el archivo----------------------
    error_config db 'No se encontro el archivo de configuracion',0xa                ;Impresion error de configuracion en pantalla
    l_error_config equ $-error_config

    error_inventario db 'No se encontro el archivo de inventario',0xa            ;Impresion error de configuracion en pantalla
    l_error_inventario equ $-error_inventario

section .bss
; /////////////////////////////////////// buffer para lectura general ////////////////////////////////////////////////////////////////////
    buffer_confg      resb 512                                                      ;Buffer para lectura total del archivo de "config.ini"
    fd                resq 1                                                        ;Descriptor de archivo para "config.ini"

    datos_config      resb 64                                                       ;Buffer para guardar los datos de interes de "config.ini"
    l_datos_config    resb 64                                                       ;longitud de los datos de interes "config.ini"

    buffer_lista      resb 1024                                                     ;Buffer para lectura total del archivo "inventario.txt"
    fd1               resq 1                                                        ;Descriptor de archivo para "inventario.txt"

    datos_lista       resb 64                                                       ;Buffer para guardar los datos de interes "inventario.txt"
    l_datos_lista     resb 64                                                       ;longitud de los datos de interes "inventario.txt"
; //////////////////////////////////// buffer de estructura de los datos //////////////////////////////////////////////////////////////////

    Buf_Nombrefruita  resb 512                                                      ;Buffer para denotar los nombres de las frutas                                            

    Buf_cantidadfruta resb 512                                                      ;Buffer para denotar el numero de frutas que hay

;/////////////////////////////////// estructura del histograma ///////////////////////////////////////////////////////////////////////////

    GNHistograma      resb 100*100                                                   ;Generar el histograma

    VecX              resb 1024                                                      ;Posicion de referencia a donde va el histograma

    Cantidad_fila     resb 8                                                         ;Cantidad de elementos en el histograma

    restHistograma    resb 32                                                        ;Reset del histograma

;////////////////////////////////////////////////////// Codificacion  ///////////////////////////////////////////////////////////////////

section .text
    global _start                                                                    ;Comienzo del codigo


_start:

; Abrir archivo de configuracion
    mov rax, 2                                                                        ;Sys_open
    mov rdi, configtxt                                                                   ;Archivo a abrir
    mov rsi, 0                                                                        ;O_RDONLY
    syscall 
    ;cmp rax, 0                                                                        ;Por si hay un fallo que el archivo no se pudo abrir 
    ;jl Fin_programa                                                                  ;Finaliza el programa
    mov [fd], rax                                                                     ;El descriptor de archivo guarda etiqueta para abrir "config.ini"

; Leer archivo de configuracion 
    mov rdi, [fd]                                                                     ;rdi apunta en direccion en donde esta el archivo de configuracion
    mov rax, 0                                                                        ;SYS_read
    mov rsi, buffer_confg                                                             ;Buffer en donde se encuentra toda la configuracion
    mov rdx, 512                                                                      ;Longitud del buffer
    syscall


; Abrir archivo de inventario
    mov rax, 2                                                                        ;Sys_open
    mov rdi, listatxt                                                                 ;Archivo a abrir
    mov rsi, 0                                                                        ;O_RDONLY
    syscall 

    ;cmp rax, 0                                                                        ;Por si hay un fallo que el archivo no se pudo abrir 
    ;jl Fin_programa_dos                                                               ;Finaliza el programa
    mov [fd1], rax                                                                    ;El descriptor de archivo guarda etiqueta para abrir "config.ini"

; Leer archivo de inventario
    mov rdi, [fd1]                                                                    ;rdi apunta en direccion en donde esta el archivo de configuracion
    mov rax, 0                                                                        ;SYS_read
    mov rsi, buffer_lista                                                             ;Buffer en donde se encuentra toda la configuracion
    mov rdx, 1024                                                                     ;Longitud del buffer
    syscall 

; Cerrar archivos

    mov rdi, [fd]           ; Descriptor de configuración
    mov rax, 3              ; syscall: close()
    syscall 

    mov rdi, [fd1]          ; Descriptor de notas
    mov rax, 3              ; syscall: close()
    syscall 

;///////////////////////////////////////// Imprimir valores en pantalla ////////////////////////////////
    print buffer_lista 
    syscall

;////////////////////////////////////////salida del sistema            ////////////////////////////////
salida:
    mov rax, 60             ; syscall: exit()
    xor rdi, rdi            ; Código de salida: 0
    syscall 