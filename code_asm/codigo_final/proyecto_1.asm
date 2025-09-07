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

    Buf_Nombrefruta   resb 512                                                      ;Buffer para denotar los nombres de las frutas
    Buf_frutas_O      resb 512                                           
    Buf_numfrutas     resb 512                                                      ;Buffer para denotar los nombres de las frutas   
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
    call Cantidad_fruta
    call GuardarNombresFrutas
    call OrdenarxNombre
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

; imprimir los datos de ascii
    mov rax, 1
    mov rdi, 1
    mov rsi, datos_config 
    mov rdx, 1024
    syscall

; imprimir de la cantidad de frutas
    mov rax, 1
    mov rdi, 1
    mov rsi, Buf_cantidadfruta 
    mov rdx, 1024
    syscall

; imprimir de la Nombre de frutas
    mov rax, 1
    mov rdi, 1
    mov rsi, Buf_Nombrefruta 
    mov rdx, 1024
    syscall



    jmp salida

;////////////////////////////////////////   salida del sistema  ///////////////////////////////////////
salida:
_tercera:
    syscall

    mov rax, 60                             ; syscall: exit()
    xor rdi, rdi                            ; Código de salida: 0
    syscall 

; ========================================
; 
;    CONFIGURACION; Paso 1
;              
; ========================================

;////////////////////////////////////// Recoleccion de datos de la configuracion///////////////////////
_segunda:
    syscall
datos_C:
    mov rsi, buffer_confg                   ; Apuntar al inicio del buffer de configuración
    mov rdi, datos_config                   ; Apuntar al buffer donde guardaremos los datos                                
buscar_dato:            
    mov al, [rsi]                           ; Leer el siguiente byte del buffer
    cmp al, 0                               ; Si llegamos al fin del buffer (NULL), terminar
    je done_ascii           
    cmp al, ':'                             ; Buscar el caracter ':' que indica inicio de valor
    jne siguiente_caracter          
    inc rsi                                 ; Saltar ':' y pasar al primer caracter del valor
    jmp leer_valor                          ; Ir a leer el valor

siguiente_caracter:
    inc rsi                                 ; Si no es ':', pasar al siguiente byte
    jmp buscar_dato                         ; Repetir búsqueda

leer_valor:         
    mov al, [rsi]                           ; Leer el siguiente byte (primer caracter del valor)
    cmp al, 0Ah                             ; Si es salto de linea, terminar dato
    je guardar_valor            
    cmp al, 0                               ; Si es NULL, terminar dato
    je guardar_valor            
    cmp al, '0'         
    jb guardar_valor_char                   ; Si < '0', es carácter
    cmp al, '9'         
    ja guardar_valor_char                   ; Si > '9', es carácter
    cmp al, '*'         
    je guardar_valor_char           
    call ascii_decimal                      ; Si es número, convertir ASCII -> decimal
    mov [rdi], al                           ; Guardar 1 byte del número en datos_config
    inc rdi                                 ; Avanzar al siguiente byte del buffer de salida
    add rsi, r9                             ; Saltar al siguiente dato en el buffer de entrada
    jmp buscar_dato                         ; Volver a buscar próximo dato

guardar_valor_char:         
    mov [rdi], al                           ; Guardar el carácter en datos_config
    inc rdi                                 ; Avanzar al siguiente byte del buffer de salida
    inc rsi                                 ; Avanzar al siguiente byte del buffer de entrada
    inc r9          
    jmp buscar_dato                         ; Volver a buscar próximo dato

guardar_valor:          
    inc rsi                                 ; Avanzar al siguiente byte del buffer
    jmp buscar_dato                         ; Continuar búsqueda

; ========================================
; Función: ascii_decimal
; Descripción: Convierte un número ASCII a decimal
;              y lo deja en AL (1 byte)
; ========================================

ascii_decimal:
    xor rax, rax                            ; Limpiar RAX para acumular el número
    ;xor r9, r9                             ; Contador de caracteres leídos
convertir:          
    mov bl, [rsi]                           ; Leer un byte del buffer
    cmp bl, ' '                             ; Si es espacio, fin de número
    je fin_convert          
    cmp bl, 0Ah                             ; Si es salto de línea, fin de número
    je fin_convert          
    cmp bl, 0                               ; Si es NULL, fin de número
    je fin_convert          
    sub bl, '0'                             ; Convertir ASCII -> decimal
    movzx rbx, bl                           ; Pasar a 64 bits
    imul rax, 10                            ; Multiplicar acumulador por 10
    add rax, rbx                            ; Sumar el nuevo dígito
    inc rsi                                 ; Avanzar al siguiente byte del buffer
    ;inc r9                                 ; Incrementar contador de caracteres
    jmp convertir                           ; Repetir hasta fin de número
fin_convert:            
    mov al, al                              ; Guardar solo el byte menos significativo en AL
    ret

done_ascii:
    ret

; ========================================
; 
;    INVENTARIO; PASO 2
;              
; ========================================

;/////////////////////////////////////////////////// valores para la lectura del inventario //////////////////////////////////////////

Cantidad_fruta:
    mov rsi, buffer_lista                   ; Apuntar al inicio del buffer de configuración
    mov rdi, Buf_cantidadfruta              ; Apuntar al buffer donde guardaremos los datos                 
buscar_dato_cantidad:   
    mov al, [rsi]                           ; Leer el siguiente byte del buffer
    cmp al, 0                               ; Si llegamos al fin del buffer (NULL), terminar
    je done_ascii_cantidad  
    cmp al, ':'                             ; Buscar el caracter ':' que indica inicio de valor
    jne siguiente_caracter_cantidad 
    inc rsi                                 ; Saltar ':' y pasar al primer caracter del valor
    jmp leer_valor_cantidad                 ; Ir a leer el valor

siguiente_caracter_cantidad:
    inc rsi                                 ; Si no es ':', pasar al siguiente byte
    jmp buscar_dato_cantidad                ; Repetir búsqueda

leer_valor_cantidad:
    mov al, [rsi]                           ; Leer el siguiente byte (primer caracter del valor)
    cmp al, 0Ah                             ; Si es salto de linea, terminar dato
    je guardar_valor_cantidad
    cmp al, 0                               ; Si es NULL, terminar dato
    call ascii_decimal_cantidad             ; Si es número, convertir ASCII -> decimal
    mov [rdi], al                           ; Guardar 1 byte del número en datos_config
    inc rdi                                 ; Avanzar al siguiente byte del buffer de salida
    add rsi, r9                             ; Saltar al siguiente dato en el buffer de entrada
    jmp buscar_dato_cantidad                ; Volver a buscar próximo dato

guardar_valor_cantidad:
    inc rsi                                 ; Avanzar al siguiente byte del buffer
    jmp buscar_dato_cantidad                ; Continuar búsqueda

; ========================================
; Función: ascii_decimal
; Descripción: Convierte un número ASCII a decimal
;              y lo deja en AL (1 byte)
; ========================================

ascii_decimal_cantidad:
    xor rax, rax                            ; Limpiar RAX para acumular el número
    ;xor r9, r9                             ; Contador de caracteres leídos
convertir_cantidad:
    mov bl, [rsi]                           ; Leer un byte del buffer
    cmp bl, ' '                             ; Si es espacio, fin de número
    je fin_convert_cantidad
    cmp bl, 0Ah                             ; Si es salto de línea, fin de número
    je fin_convert_cantidad
    cmp bl, 0                               ; Si es NULL, fin de número
    je fin_convert_cantidad
    sub bl, '0'                             ; Convertir ASCII -> decimal
    movzx rbx, bl                           ; Pasar a 64 bits
    imul rax, 10                            ; Multiplicar acumulador por 10
    add rax, rbx                            ; Sumar el nuevo dígito
    inc rsi                                 ; Avanzar al siguiente byte del buffer
    ;inc r9                                 ; Incrementar contador de caracteres
    jmp convertir_cantidad                  ; Repetir hasta fin de número
fin_convert_cantidad:
    mov al, al                              ; Guardar solo el byte menos significativo en AL
    ret

done_ascii_cantidad:
    ret

;/////////////////////////////////////////////////// Nombres de las frutas del inventario /////////////////////////////////////////////
    
GuardarNombresFrutas:
    mov rsi, buffer_lista        ; RSI -> apuntar al inicio del buffer de entrada (contenido de inventario.txt)
    mov rdi, Buf_Nombrefruta     ; RDI -> apuntar al buffer donde se guardarán los nombres de las frutas
    xor r11, r11                 ; Inicializar contador de frutas a 0

    jmp GuardarNombreFruta       ; Saltar directamente al bucle que guarda los nombres

; ---------------------------
; Bucle para guardar un nombre de fruta
GuardarNombreFruta:
    mov al, [rsi]                ; Leer el siguiente carácter del buffer de entrada
    cmp al, 0                    ; Comprobar si llegamos al fin del buffer (NULL)
    je GFListo                   ; Si es fin del buffer, saltar a la etiqueta de finalización

    cmp al, ':'                  ; Comprobar si es el separador ':' (indica fin del nombre)
    je FinNombre                 ; Si es ':', cerrar nombre y pasar a ignorar la cantidad

    cmp al, 10                   ; Comprobar si es salto de línea (fin de línea)
    je FinNombre                 ; Si es salto de línea, cerrar nombre y pasar a siguiente fruta

    mov byte [rdi], al           ; Guardar el carácter en el buffer de nombres
    inc rsi                      ; Avanzar al siguiente carácter en la entrada
    inc rdi                      ; Avanzar al siguiente espacio en el buffer de salida
    jmp GuardarNombreFruta       ; Repetir el proceso hasta encontrar ':' o salto de línea

; ---------------------------
; Cerrar nombre y saltar los números hasta '\n'
FinNombre:
    mov byte [rdi], 0            ; Terminar el nombre con NULL para que sea un string válido
    inc r11                      ; Incrementar el contador de frutas leídas

    ; --- Alinear nombres (32 bytes por fruta) ---
    mov rax, rdi                 ; Copiar la posición actual de salida en RAX
    xor rdx, rdx                 ; Limpiar RDX (residuo de división)
    mov rcx, 32                   ; Tamaño de bloque por fruta
    div rcx                       ; Dividir RAX entre 32
    add rdi, 32                   ; Avanzar RDI al siguiente bloque de 32 bytes
    sub rdi, rdx                   ; Ajustar según residuo para mantener alineación

SkipToNextLine:
    mov al, [rsi]                ; Leer el siguiente carácter de la entrada
    cmp al, 0                    ; Comprobar si es fin de buffer
    je GFListo                   ; Si fin de buffer, terminar rutina
    cmp al, 10                   ; Comprobar si es salto de línea
    je AvanzarLinea              ; Si es salto de línea, avanzar y procesar siguiente fruta
    inc rsi                       ; Si no es salto de línea, avanzar al siguiente carácter
    jmp SkipToNextLine           ; Repetir hasta encontrar salto de línea o fin de buffer

AvanzarLinea:
    inc rsi                      ; Saltar el carácter de salto de línea
    jmp GuardarNombreFruta       ; Volver al bucle principal para procesar la siguiente fruta

; ---------------------------
; Fin de la rutina
GFListo:
    mov [Buf_numfrutas], r11     ; Guardar el total de frutas leídas en memoria
    ret  

;/////////////////////////////////////////////////// Ordenar lista alfabeticamente  //////////////////////////////////////////////////

OrdenarxNombre:
    mov rdx, Buf_Nombrefruta
    mov rcx, Buf_cantidadfruta
    mov r9, [Buf_numfrutas]
    dec r9

OrdenarLoop:
    mov r10, r9
    xor r11, r11

LoopCompararNombre:
    mov r12, r10
    imul r12, 16
    lea r13, [rdx + r12 - 16] ; nombre[i]
    lea r14, [rdx + r12]      ; nombre[i+1]

CompararNombres:
    mov al, [r13]
    mov bl, [r14]
    cmp al, bl
    jne DecidirIntercambio
    cmp al, 0
    je NoIntercambiar
    inc r13
    inc r14
    jmp CompararNombres

DecidirIntercambio:
    ja NoIntercambiar

    ; Intercambiar cantidades
    mov rax, [rcx + r10*8 - 8]
    mov rbx, [rcx + r10*8]
    mov [rcx + r10*8 - 8], rbx
    mov [rcx + r10*8], rax

    ; Intercambiar nombres (16 bytes = 2 bloques de 8)
    mov r15, 2
CambiarNombres:
    mov rax, [r13]
    mov rbx, [r14]
    mov [r14], rax
    mov [r13], rbx
    add r13, 8
    add r14, 8
    dec r15
    jnz CambiarNombres

    mov r11, 1

NoIntercambiar:
    dec r10
    jnz LoopCompararNombre

    cmp r11, 0
    jne OrdenarLoop
    ret
