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

    datos_config      resb 64                                                       ;Buffer para guardar los datos de interes de "config.ini"
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
    call datos_cofig             ; Procesar datos de configuración
    

; Abrir archivo de inventario
    mov rax, 2                                                                        ;Sys_open
    mov rdi, listatxt                                                                 ;Archivo a abrir
    mov rsi, 0                                                                        ;O_RDONLY
    syscall 

    cmp rax, 0                                                                       ;Por si hay un fallo que el archivo no se pudo abrir 
    jl Fin_programa_dos                                                              ;Finaliza el programa
    mov [fd1], rax                                                                   ;El descriptor de archivo guarda etiqueta para abrir "config.ini"

; Leer archivo de inventario
    mov rdi, [fd1]                                                                    ;rdi apunta en direccion en donde esta el archivo de configuracion
    mov rax, 0                                                                        ;SYS_read
    mov rsi, buffer_lista                                                             ;Buffer en donde se encuentra toda la configuracion
    mov rdx, 1024                                                                     ;Longitud del buffer
    syscall

    jmp funcional                                                                     ;Se lee con exito ambos archivos

; Cerrar archivos

    mov rdi, [fd]           ; Descriptor de configuración
    mov rax, 3              ; syscall: close()
    syscall 

    mov rdi, [fd1]          ; Descriptor de notas
    mov rax, 3              ; syscall: close()
    syscall 

;///////////////////////////////////////// Manejo de errores ///////////////////////////////////////

Fin_programa:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_config
    mov rdx, l_error_config
    syscall 
    jmp salida

Fin_programa_dos:
    mov rax, 1
    mov rdi, 1
    mov rsi, error_inventario
    mov rdx, l_error_inventario
    syscall 
    jmp salida

;/////////////////////////////////// imprimir valores en pantall ////////////////////////////////////
funcional:
; imprimir los datos de configuracion
    mov rax, 1                 
    mov rdi, 1
    mov rsi, buffer_confg
    mov rdx, 512
    syscall

; imprimir los datos de inventario
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_lista
    mov rdx, 1024
    syscall
    jmp salida

; imprimir los datos de ascii
    mov rax, 1
    mov rdi, 1
    mov rsi, buf_num_ascii
    mov rdx, 1024
    syscall
    jmp salida

;////////////////////////////////////////   salida del sistema  ///////////////////////////////////////
salida:
    mov rax, 60             ; syscall: exit()
    xor rdi, rdi            ; Código de salida: 0
    syscall 
    
;////////////////////////////////////// Recoleccion de datos de la configuracion///////////////////////
datos_cofig:
    mov rsi, buffer_confg
    mov rdi, datos_config
    mov r8b, 4                                                   ;Bandera de cuantos valores de interes hay en configuracion

buscar_dato:
    xor r9, r9                                                   ;contador de caracteres
    mov al, [rsi]                                                ;se encarga de lectura archivo de 1 byte cada caracter es de un byte
    cmp al, 0                                                    ;Ya no hay mas bit para leer
    je done_ascii                                        ;finaliza lectura
    cmp al,':'                                                   ;Determina el comienzo de un caracter de interes.                                               
    je leer_valor                                                ;Cuando se determina el comienzo del caracter de interes se guarda el dato
    inc rsi                                                      ;En caso de no encontrar sigue aumentando el puntureo hasta llegar al bit de interes
    jmp buscar_dato                                              ;Repite todo el ciclo

leer_valor:
    dec r8b                                                     ;decrece en un el valor del dato que se quiere encontrar
    jz done_ascii                                       ;Bandera que finaliza la busqueda cundon r8b haya llegado a 0, sin datos de interes
    inc rsi                                                     ;Incrementa el rsi par continuar con la lectura, saltando el simbolo :
    jmp acceso_dato                                             ;El sistema salta a acceder el dato de interes en configuraciones        

acceso_dato:
    mov al, [rsi]                                               ;al es un puntero de 1 byte que nos permite leer caracter por caracter en el achivo config el cual esta siendo apuntado por rsi
    
    cmp al, ' '
    je main_convertidor_ascii
    cmp al, 0Ah
    je main_convertidor_ascii
    cmp al, 0
    je main_convertidor_ascii
    
    inc rsi                                                     ;incrementamos el valor rsi para seguir leyendo
    inc r9                                                      ;Incrementamos el numero de caracteres
    jmp acceso_dato                                             ;En caso de que no se encuentre el valor final se repite el bucle
    
main_convertidor_ascii:
    sub rsi, r9                                                 ; Retroceder al inicio del número
    mov al, [rsi]                                               ; Verificar si el valor es un caracter
    cmp al, '0'
    jb guardar_caracter                                         ; si < '0', es caracter
    cmp al, '9'
    ja guardar_caracter                                         ; si > '9', es caracter
    call ascii_decimal
    mov [rdi], rax                                              ; Guardar número completo en qword
    mov [buf_num_ascii], rax
    inc rdi                                                     ; Avanzar al siguiente espacio de datos
    add rsi, r9                                                 ; Avanzar puntero después del número
    jmp buscar_dato                                             ;Simpre salta al loop principal

guardar_caracter:
    mov al, [rsi]               ; guardar el carácter
    movzx rax, al

guardar_dato:
    mov [rdi], rax              ; guardar en buffer de datos
    mov [buf_num_ascii], rax    ; opcional: guardar también en buffer temporal
    inc rsi
    add rsi, r9                 ; avanzar al siguiente dato
    inc rdi                      ; apuntar a la siguiente posición de salida
    jmp buscar_dato

ascii_decimal:
    xor rax,rax                                                 ;Inicializar rax en 0
convertir:
    mov bl, [rsi]                                               ;Utilizamos un registro de un byte para almacenar el archivo
    cmp bl, ' '                                                 ;Si el valor final es un espacio
    je done_ascii                                               ;Termina la ejecucion
    cmp bl, 0
    je done_ascii
    cmp bl, 0Ah                                                 ;considerar salto de línea
    je done_ascii

    sub bl, '0'                                                 ;Convertir de ASCII a decimal
    movzx rbx, bl                                               ;se tranforma la informacion en bl a 64 bits
    imul rax, 10                                                ;multiplicador del resultado actual por diez
    add rax, rbx                                                ;Sumar el nuevo dígito

    inc rsi
    inc r9
    jmp convertir    

done_ascii:
    ret