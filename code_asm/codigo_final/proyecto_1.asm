;nasm -f elf64 -o  proyecto_1.o proyecto_1.asm
;ld -o   proyecto_1_execute   proyecto_1.o
;./proyecto_1_execute

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

    datos_config      resb 100*100                                                       ;Buffer para guardar los datos de interes de "config.ini"
    l_datos_config    resb 64                                                       ;longitud de los datos de interes "config.ini"

    buffer_lista      resb 1024                                                     ;Buffer para lectura total del archivo "inventario.txt"
    fd1               resq 1                                                        ;Descriptor de archivo para "inventario.txt"

    datos_lista       resb 64                                                       ;Buffer para guardar los datos de interes "inventario.txt"
    l_datos_lista     resb 64                                                       ;longitud de los datos de interes "inventario.txt"
; //////////////////////////////////// buffer de estructura de los datos //////////////////////////////////////////////////////////////////

    Buf_Nombrefruita  resb 512                                                      ;Buffer para denotar los nombres de las frutas                                            

    Buf_cantidadfruta resb 512                                                      ;Buffer para denotar el numero de frutas que hay
;/////////////////////////////////// guardar dato en Ascii ///////////////////////////////////////////////////////////////////////////////
    buf_num_ascii     resb 64
;/////////////////////////////////// estructura del histograma ///////////////////////////////////////////////////////////////////////////

    GNHistograma      resb 100*100                                                   ;Generar el histograma

    VecX              resb 1024                                                      ;Posicion de referencia a donde va el histograma

    Cantidad_fila     resb 8                                                         ;Cantidad de elementos en el histograma

    restHistograma    resb 32                                                        ;Reset del histograma

;////////////////////////////////////////////////////// Codificacion  ///////////////////////////////////////////////////////////////////

section .text
    global _start                                                                    ;Comienzo del codigo
    global _segunda
    global _tercera


_start:

; Abrir archivo de configuracion
    mov rax, 2                                                                        ;Sys_open
    mov rdi, configtxt                                                                ;Archivo a abrir
    mov rsi, 0                                                                        ;O_RDONLY
    syscall 
    cmp rax, 0                                                                        ;Por si hay un fallo que el archivo no se pudo abrir 
    jl Fin_programa                                                                  ;Finaliza el programa
    mov [fd], rax                                                                     ;El descriptor de archivo guarda etiqueta para abrir "config.ini"

; Leer archivo de configuracion 
    mov rdi, [fd]                                                                     ;rdi apunta en direccion en donde esta el archivo de configuracion
    mov rax, 0                                                                        ;SYS_read
    mov rsi, buffer_confg                                                             ;Buffer en donde se encuentra toda la configuracion
    mov rdx, 512                                                                      ;Longitud del buffer
    syscall
    cmp rax, 0                                                                        ;Por si hay un fallo que el archivo no se pudo abrir 
    jl Fin_programa 
    call datos_C                                                                      ; Procesar datos de configuración
    

; Abrir archivo de inventario
    ;mov rax, 2                                                                        ;Sys_open
    ;mov rdi, listatxt                                                                 ;Archivo a abrir
    ;mov rsi, 0                                                                        ;O_RDONLY
    ;syscall 

    ;cmp rax, 0                                                                       ;Por si hay un fallo que el archivo no se pudo abrir 
    ;jl Fin_programa_dos                                                              ;Finaliza el programa
    ;mov [fd1], rax                                                                   ;El descriptor de archivo guarda etiqueta para abrir "config.ini"

; Leer archivo de inventario
    ;mov rdi, [fd1]                                                                    ;rdi apunta en direccion en donde esta el archivo de configuracion
    ;mov rax, 0                                                                        ;SYS_read
    ;mov rsi, buffer_lista                                                             ;Buffer en donde se encuentra toda la configuracion
    ;mov rdx, 1024                                                                     ;Longitud del buffer
    ;syscall

    jmp funcional                                                                     ;Se lee con exito ambos archivos
    ;Jmp salida   ; borrar esto es solo para probar algo unos momentos, no es util para nada.
; Cerrar archivos

   ;mov rdi, [fd]           ; Descriptor de configuración
   ;mov rax, 3              ; syscall: close()
   ;syscall 

   ;mov rdi, [fd1]          ; Descriptor de notas
   ;mov rax, 3              ; syscall: close()
   ;syscall 

;///////////////////////////////////////// Manejo de errores ///////////////////////////////////////

Fin_programa:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_config
    mov rdx, l_error_config
    syscall 
    jmp salida

;Fin_programa_dos:
   ;mov rax, 1
   ;mov rdi, 1
   ;mov rsi, error_inventario
   ;mov rdx, l_error_inventario
   ;syscall 
   ;jmp salida

;/////////////////////////////////// imprimir valores en pantall ////////////////////////////////////
funcional:
; imprimir los datos de configuracion
    ;mov rax, 1                 
    ;mov rdi, 1
    ;mov rsi, buffer_confg
    ;mov rdx, 512
    ;syscall

; imprimir los datos de inventario
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, buffer_lista
    ;mov rdx, 1024
    ;syscall
    ;jmp salida

; imprimir los datos de ascii
    mov rax, 1
    mov rdi, 1
    mov rsi, datos_config 
    mov rdx, 1024
    syscall
    jmp salida

;////////////////////////////////////////   salida del sistema  ///////////////////////////////////////
salida:
_tercera:
    syscall

    mov rax, 60             ; syscall: exit()
    xor rdi, rdi            ; Código de salida: 0
    syscall 

;////////////////////////////////////// Recoleccion de datos de la configuracion///////////////////////
_segunda:
    syscall
datos_C:
    mov rsi, buffer_confg       ; Apuntar al inicio del buffer de configuración
    mov rdi, datos_config       ; Apuntar al buffer donde guardaremos los datos                      
buscar_dato:
    mov al, [rsi]               ; Leer el siguiente byte del buffer
    cmp al, 0                   ; Si llegamos al fin del buffer (NULL), terminar
    je done_ascii
    cmp al, ':'                 ; Buscar el caracter ':' que indica inicio de valor
    jne siguiente_caracter
    inc rsi                     ; Saltar ':' y pasar al primer caracter del valor
    jmp leer_valor              ; Ir a leer el valor

siguiente_caracter:
    inc rsi                     ; Si no es ':', pasar al siguiente byte
    jmp buscar_dato             ; Repetir búsqueda

leer_valor:
    mov al, [rsi]               ; Leer el siguiente byte (primer caracter del valor)
    cmp al, 0Ah                 ; Si es salto de linea, terminar dato
    je guardar_valor
    cmp al, 0                   ; Si es NULL, terminar dato
    je guardar_valor
    cmp al, '0'
    jb guardar_valor_char       ; Si < '0', es carácter
    cmp al, '9'
    ja guardar_valor_char       ; Si > '9', es carácter
    cmp al, '*'
    ja guardar_valor_char 
    call ascii_decimal          ; Si es número, convertir ASCII -> decimal
    mov [rdi], al               ; Guardar 1 byte del número en datos_config
    inc rdi                     ; Avanzar al siguiente byte del buffer de salida
    add rsi, r9                 ; Saltar al siguiente dato en el buffer de entrada
    jmp buscar_dato             ; Volver a buscar próximo dato

guardar_valor_char:
    mov [rdi], al               ; Guardar el carácter en datos_config
    inc rdi                     ; Avanzar al siguiente byte del buffer de salida
    inc rsi                     ; Avanzar al siguiente byte del buffer de entrada
    inc r9
    jmp buscar_dato             ; Volver a buscar próximo dato

guardar_valor:
    inc rsi                     ; Avanzar al siguiente byte del buffer
    jmp buscar_dato             ; Continuar búsqueda

; ========================================
; Función: ascii_decimal
; Descripción: Convierte un número ASCII a decimal
;              y lo deja en AL (1 byte)
; ========================================

ascii_decimal:
    xor rax, rax                ; Limpiar RAX para acumular el número
    ;xor r9, r9                  ; Contador de caracteres leídos
convertir:
    mov bl, [rsi]               ; Leer un byte del buffer
    cmp bl, ' '                 ; Si es espacio, fin de número
    je fin_convert
    cmp bl, 0Ah                 ; Si es salto de línea, fin de número
    je fin_convert
    cmp bl, 0                   ; Si es NULL, fin de número
    je fin_convert
    sub bl, '0'                 ; Convertir ASCII -> decimal
    movzx rbx, bl               ; Pasar a 64 bits
    imul rax, 10                ; Multiplicar acumulador por 10
    add rax, rbx                ; Sumar el nuevo dígito
    inc rsi                     ; Avanzar al siguiente byte del buffer
    ;inc r9                      ; Incrementar contador de caracteres
    jmp convertir               ; Repetir hasta fin de número
fin_convert:
    mov al, al                  ; Guardar solo el byte menos significativo en AL
    ret

done_ascii:
    ret
