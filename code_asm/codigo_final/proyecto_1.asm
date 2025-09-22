;nasm -f elf64 -o  proyecto_1.o proyecto_1.asm
;ld -o   proyecto_1_execute   proyecto_1.o
;./proyecto_1_execute


section .data
;------------------------------Archivos de lectura----------------------------
    listatxt  db "inventario.txt", 0
    configtxt    db "config.ini", 0

;------------------------------Errores al abrir el archivo----------------------
    error_config db 'No se encontro el archivo de configuracion',0xa                ;Impresion error de configuracion en pantalla
    l_error_config equ $-error_config

    error_inventario db 'No se encontro el archivo de inventario',0xa            ;Impresion error de configuracion en pantalla
    l_error_inventario equ $-error_inventario
;-----------------Valores para el histograma--------------------------------------
    dos_puntos_msg      db ":", 0        ; ':' para imprimir
    espacio_msg         db " ", 0        ; espacio para separar
    nueva_linea_msg     db 10, 0         ; salto de línea

    ansi_esc            db 0x1B           ; ESC para secuencias ANSI
    ansi_open           db "[", 0         ; inicio secuencia ANSI
    ansi_m              db "m", 0         ; fin secuencia ANSI
    ansi_reset_completo db 0x1B, "[0m", 0 ; reset de formato ANSI 
    ansi_reset_len      equ $ - ansi_reset_completo ; longitud de reset

    

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
    Buf_cantidadfruta resq 100                                                      ;Buffer para denotar el numero de frutas que hay
;/////////////////////////////////// guardar dato en Ascii ///////////////////////////////////////////////////////////////////////////////
    buf_num_ascii     resb 64                                                       ;Para almacenar los valores ascci en numeros
;/////////////////////////////////// estructura del histograma ///////////////////////////////////////////////////////////////////////////
    caracter_barra     resb 1                                                       ; almacena el carácter que forma cada barra del histograma
    color_barra        resb 1                                                       ; color asignado a las barras
    color_fondo        resb 1                                                       ; color del fondo del histograma
    char_buffer        resb 1                                                       ; buffer temporal para un solo carácter
    num_buffer         resb 20                                                      ; buffer para almacenar números (ej. texto de entrada)
    byte_buffer        resb 4                                                       ; buffer de 4 bytes para datos temporales
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
    call datos_configuracion                                                                      ; Procesar datos de configuración
    

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
    call GuardarNombresFrutas
    call Cantidad_fruta
    call Ordenamiento_bubble_sort
    call GenerarHistograma    

    jmp funcional                                                                     ;Se lee con exito ambos archivos




; Cerrar archivos

    mov rdi, [fd]           ; Descriptor de configuración
    mov rax, 3              ; syscall: close()
    syscall 

    mov rdi, [fd1]          ; Descriptor de notas
    mov rax, 3              ; syscall: close()
    syscall 

;///////////////////////////////////////// Manejo de errores ///////////////////////////////////////
;/////////////////////////////////////// Son mensajes para detectar errores de flujo////////////////////////
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
;//////////////////////////////////La utilidad radica en ver los valores que se estan guardando en memoria///////////////
;//////////////////////////////////
funcional:
; imprimir los datos de configuracion
    ;mov rax, 1                         ; código de la llamada al sistema (sys_write)         
    ;mov rdi, 1                         ; descriptor de archivo: 1 = salida estándar (stdout)
    ;mov rsi, buffer_confg              ; dirección del buffer a imprimir
    ;mov rdx, 512                       ; cantidad de bytes a escribir
    ;syscall                            ; ejecuta la llamada al sistema (escribe en pantalla)

;///////////////////todos los demas hacen lo mismo pero en diferentes espaciones de memoria/////////////////

; im;primir los datos de inventario
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, buffer_lista                 ;lectura de la lista completa
    ;mov rdx, 1024
    ;syscall

; im;primir los datos de ascii
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, datos_config                ;guarda los valores de la lectura de config
    ;mov rdx, 1024
    ;syscall

; im;primir de la Nombre de frutas
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, Buf_Nombrefruta              ;Guarda los nombres de las fruta
    ;mov rdx, 1024
    ;syscall

; im;primir de la cantidad de frutas
    ;mov rax, 1
    ;mov rdi, 1
    ;mov rsi, Buf_cantidadfruta           ;Guarda las cntidades de las frutas      
    ;mov rdx, 1024
    ;syscall


    jmp salida                            ;Salida inmediata del sistema

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
datos_configuracion:
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

; //////////////////////////////////////////////////////
; Función: ascii_decimal
; Descripción: Convierte un número ASCII a decimal
;              y lo deja en AL (1 byte)
; /////////////////////////////////////////////////////

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


;/////////////////////////////////////////////////// Nombres de las frutas del inventario /////////////////////////////////////////////

; ///////////////////////////////////////////////////////////
; Función: GuardarNombresFrutas
; Descripción: Extrae los nombres de frutas del inventario
; ///////////////////////////////////////////////////////////
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
    ;call ascii_decimal_cantidad 
    mov byte [rdi], al           ; Guardar el carácter en el buffer de nombres
    inc rsi                      ; Avanzar al siguiente carácter en la entrada
    inc rdi                      ; Avanzar al siguiente espacio en el buffer de salida
    jmp GuardarNombreFruta       ; Repetir el proceso hasta encontrar ':' o salto de línea

; ---------------------------
; Cerrar nombre y saltar los números hasta '\n'
FinNombre:
    mov byte [rdi], 0            ; Terminar el nombre con NULL para que sea un string válido
    inc r11                      ; Incrementar el contador de frutas leídas

    ; --- Alinear nombres (16 bytes por fruta) --- ; CORRECCIÓN: cambiar de 32 a 16 bytes
    mov rax, rdi                 ; Copiar la posición actual de salida en RAX
    xor rdx, rdx                 ; Limpiar RDX (residuo de división)
    mov rcx, 16                  ; Tamaño de bloque por fruta (16 bytes)
    div rcx                      ; Dividir RAX entre 16
    add rdi, 16                  ; Avanzar RDI al siguiente bloque de 16 bytes
    sub rdi, rdx                 ; Ajustar según residuo para mantener alineación

SkipToNextLine:
    mov al, [rsi]                ; Leer el siguiente carácter de la entrada
    cmp al, 0                    ; Comprobar si es fin de buffer
    je GFListo                   ; Si fin de buffer, terminar rutina
    cmp al, 10                   ; Comprobar si es salto de línea
    je AvanzarLinea              ; Si es salto de línea, avanzar y procesar siguiente fruta
    inc rsi                      ; Si no es salto de línea, avanzar al siguiente carácter
    jmp SkipToNextLine           ; Repetir hasta encontrar salto de línea o fin de buffer

AvanzarLinea:
    inc rsi                      ; Saltar el carácter de salto de línea
    jmp GuardarNombreFruta       ; Volver al bucle principal para procesar la siguiente fruta

; ---------------------------
; Fin de la rutina
GFListo:
    mov [Buf_numfrutas], r11     ; Guardar el total de frutas leídas en memoria
    ret  

;/////////////////////////////////////////////////// valores para la lectura del inventario //////////////////////////////////////////

; /////////////////////////////////////////////////
; Función: Cantidad_fruta
; Descripción: Extrae las cantidades numéricas del inventario
; /////////////////////////////////////////////////
Cantidad_fruta:
    mov rsi, buffer_lista                   ; Apuntar al inicio del buffer
    mov rdi, Buf_cantidadfruta              ; Buffer para cantidades NUMÉRICAS
    xor rcx, rcx                            ; Contador de frutas
    
buscar_dato_cantidad:   
    mov al, [rsi]
    cmp al, 0                               ; Fin del buffer
    je done_ascii_cantidad  
    cmp al, ':'                             ; Buscar ':'
    jne siguiente_caracter_cantidad 
    
    inc rsi                                 ; Saltar ':' 
    ; ¡IMPORTANTE! Ahora procesar el número
    
leer_valor_cantidad:
    call ascii_decimal_cantidad             ; Convertir ASCII a número
    mov [rdi], rax                          ; Guardar el VALOR NUMÉRICO (8 bytes)
    add rdi, 8                              ; Avanzar 8 bytes (tamaño de qword)
    inc rcx                                 ; Incrementar contador de frutas
    
    ; Buscar siguiente línea
buscar_siguiente_linea:
    mov al, [rsi]
    cmp al, 0
    je done_ascii_cantidad
    cmp al, 10                              ; Salto de línea
    je encontro_salto
    inc rsi
    jmp buscar_siguiente_linea

encontro_salto:
    inc rsi                                 ; Saltar el salto de línea
    jmp buscar_dato_cantidad

siguiente_caracter_cantidad:
    inc rsi
    jmp buscar_dato_cantidad

done_ascii_cantidad:
    mov [Buf_numfrutas], rcx                ; Guardar número de frutas
    ret

; //////////////////////////////////////////
; Función: ascii_decimal_cantidad
; //////////////////////////////////////////
ascii_decimal_cantidad:
    xor rax, rax                            ; Limpiar RAX
    xor rbx, rbx
    
convertir_cantidad:
    mov bl, [rsi]
    cmp bl, '0'                             ; ¿Es dígito?
    jb fin_convert_cantidad
    cmp bl, '9'
    ja fin_convert_cantidad
    cmp bl, 10                              ; Salto de línea
    je fin_convert_cantidad
    cmp bl, 0                               ; Fin de buffer
    je fin_convert_cantidad
    
    sub bl, '0'                             ; Convertir ASCII a número
    imul rax, 10                            ; rax = rax * 10
    add rax, rbx                            ; rax = rax + dígito
    inc rsi
    jmp convertir_cantidad

fin_convert_cantidad:
    ret

;/////////////////////////////////////////////////// Ordenar lista alfabeticamente  //////////////////////////////////////////////////

; ////////////////////////////////////////////////////////////////////////////////
; Función: OrdenarxNombre
; Descripción: Ordena la lista de frutas alfabéticamente usando Bubble Sort
; ////////////////////////////////////////////////////////////////////////////////

Ordenamiento_bubble_sort:
    push r12                    ; Guardar registro r12
    push r13                    ; Guardar registro r13
    push r14                    ; Guardar registro r14
    push r15                    ; Guardar registro r15
    push rbx                    ; Guardar registro rbx
    push rsi                    ; Guardar registro rsi
    push rdi                    ; Guardar registro rdi
    
    mov r12, Buf_Nombrefruta      ; Cargar dirección base de nombres
    mov r13, Buf_cantidadfruta    ; Cargar dirección base de cantidades
    mov r14, [Buf_numfrutas]      ; Cargar número total de elementos
    cmp r14, 1                   ; Comparar si hay 0 o 1 elemento
    jle finish_sort               ; Saltar al final si ya está ordenado
    
    dec r14                       ; n-1 (para bubble sort)
    mov r15, r14                  ; i = n-1 (contador externo)

outer_loop:
    xor r11, r11                  ; Inicializar bandera de intercambios a 0
    xor r10, r10                  ; j = 0 (contador interno)

inner_loop:
    cmp r10, r15                  ; Comparar j con i
    jge check_swap_done           ; Saltar si j >= i
    
    ; Comparar nombre[j] con nombre[j+1]
    mov rax, r10                  ; Cargar índice j
    imul rax, 16                  ; Multiplicar por 16 (tamaño de cada nombre)
    lea rsi, [r12 + rax]          ; Calcular dirección de nombre[j]
    
    mov rbx, r10                  ; Cargar índice j
    inc rbx                       ; j+1
    imul rbx, 16                  ; Multiplicar por 16
    lea rdi, [r12 + rbx]          ; Calcular dirección de nombre[j+1]
    
    call comparar_strings         ; Llamar función para comparar strings
    cmp rax, 0                    ; Comparar resultado
    jle next_j                    ; Saltar si nombre[j] <= nombre[j+1]
    
    ; INTERCAMBIAR elemento[j] con elemento[j+1]
    ; Intercambiar nombres
    mov rax, r10                  ; Cargar índice j
    imul rax, 16                  ; Multiplicar por 16
    lea rsi, [r12 + rax]          ; Calcular dirección de nombre[j]
    
    mov rbx, r10                  ; Cargar índice j
    inc rbx                       ; j+1
    imul rbx, 16                  ; Multiplicar por 16
    lea rdi, [r12 + rbx]          ; Calcular dirección de nombre[j+1]
    
    call intercambiar_nombres     ; Llamar función para intercambiar nombres
    
    ; Intercambiar cantidades
    mov rax, r10                  ; Cargar índice j
    imul rax, 8                   ; Multiplicar por 8 (tamaño de cada cantidad)
    lea rsi, [r13 + rax]          ; Calcular dirección de cantidad[j]
    
    mov rbx, r10                  ; Cargar índice j
    inc rbx                       ; j+1
    imul rbx, 8                   ; Multiplicar por 8
    lea rdi, [r13 + rbx]          ; Calcular dirección de cantidad[j+1]
    
    call intercambiar_cantidades  ; Llamar función para intercambiar cantidades
    
    mov r11, 1                    ; Establecer bandera de intercambio a 1

next_j:
    inc r10                       ; Incrementar j
    jmp inner_loop                ; Volver al inicio del loop interno

check_swap_done:
    ; Verificar si hubo intercambios en esta pasada
    cmp r11, 0                    ; Comparar bandera de intercambios
    je finish_sort                ; Saltar al final si no hubo intercambios
    
    dec r15                       ; Decrementar i
    jnz outer_loop                ; Continuar mientras i > 0

finish_sort:
    pop rdi                       ; Restaurar registro rdi
    pop rsi                       ; Restaurar registro rsi
    pop rbx                       ; Restaurar registro rbx
    pop r15                       ; Restaurar registro r15
    pop r14                       ; Restaurar registro r14
    pop r13                       ; Restaurar registro r13
    pop r12                       ; Restaurar registro r12
    ret                           ; Retornar de la función

; ///////////////////////////////////////////////////////////////////////
comparar_strings:
    push rcx                      ; Guardar registro rcx
    xor rcx, rcx                  ; Inicializar contador a 0
    
compare_loop:
    mov al, [rsi + rcx]          ; Cargar carácter del primer string
    mov bl, [rdi + rcx]          ; Cargar carácter del segundo string
    
    ; Si llegamos al final de ambos strings, son iguales
    cmp al, 0                    ; Verificar fin del primer string
    je check_second_end          ; Saltar si es fin de string
    cmp bl, 0                    ; Verificar fin del segundo string
    je check_first_end           ; Saltar si es fin de string
    
    ; Comparación alfabética
    cmp al, bl                   ; Comparar caracteres
    jl less_than                 ; Saltar si primer string es menor
    jg greater_than              ; Saltar si primer string es mayor
    
    inc rcx                      ; Incrementar contador
    jmp compare_loop             ; Continuar comparación

check_second_end:
    cmp bl, 0                    ; Verificar si segundo string también terminó
    je equal                     ; Saltar si son iguales
    jmp less_than                ; Saltar si primer string es menor

check_first_end:
    jmp greater_than             ; Saltar si primer string es mayor

less_than:
    mov rax, -1                  ; Devolver -1 (primer string es menor)
    jmp done_compare             ; Saltar al final
    
greater_than:
    mov rax, 1                   ; Devolver 1 (primer string es mayor)
    jmp done_compare             ; Saltar al final
    
equal:
    xor rax, rax                 ; Devolver 0 (strings iguales)
    
done_compare:
    pop rcx                      ; Restaurar registro rcx
    ret                          ; Retornar de la función

; //////////////////////////////////////////////////////////
intercambiar_nombres:
    push rcx                     ; Guardar registro rcx
    push rax                     ; Guardar registro rax
    push rbx                     ; Guardar registro rbx
    
    mov rcx, 16                  ; 16 bytes por nombre (contador)
swap_names:
    mov al, [rsi]               ; Cargar byte del primer nombre
    mov bl, [rdi]               ; Cargar byte del segundo nombre
    mov [rsi], bl               ; Intercambiar: poner segundo en primero
    mov [rdi], al               ; Intercambiar: poner primero en segundo
    inc rsi                     ; Avanzar al siguiente byte del primer nombre
    inc rdi                     ; Avanzar al siguiente byte del segundo nombre
    dec rcx                     ; Decrementar contador
    jnz swap_names              ; Continuar mientras contador > 0
    
    pop rbx                     ; Restaurar registro rbx
    pop rax                     ; Restaurar registro rax
    pop rcx                     ; Restaurar registro rcx
    ret                         ; Retornar de la función

; /////////////////////////////////////////////////////////////////
intercambiar_cantidades:
    push rax                     ; Guardar registro rax
    push rbx                     ; Guardar registro rbx
    
    mov rax, [rsi]              ; Cargar cantidad del primer elemento
    mov rbx, [rdi]              ; Cargar cantidad del segundo elemento
    mov [rsi], rbx              ; Intercambiar: poner segundo en primero
    mov [rdi], rax              ; Intercambiar: poner primero en segundo
    
    pop rbx                     ; Restaurar registro rbx
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

;////////////////////////////////////////////////////////  Histograma ///////////////////////////////////////////////

; ========================================
; 
;    CONFIGURACION; Paso 4
;              
; ========================================
GenerarHistograma:
    push r12        ; Guardar registro r12 en la pila
    push r13        ; Guardar registro r13 en la pila
    push r14        ; Guardar registro r14 en la pila
    push r15        ; Guardar registro r15 en la pila
    push rbx        ; Guardar registro rbx en la pila
    
    ; Obtener configuración de colores y caracteres
    mov r12, datos_config       ; Cargar dirección de configuración en r12
    mov al, [r12]               ; Cargar carácter de barra desde memoria
    mov [caracter_barra], al    ; Guardar carácter en variable
    
    mov al, [r12 + 1]           ; Cargar color de barra desde memoria
    mov [color_barra], al       ; Guardar color en variable
    
    mov al, [r12 + 2]           ; Cargar color de fondo desde memoria
    mov [color_fondo], al       ; Guardar color en variable
    
    ; Preparar datos para procesar
    mov r13, Buf_Nombrefruta    ; Cargar dirección de nombres de frutas
    mov r14, Buf_cantidadfruta  ; Cargar dirección de cantidades
    mov r15, [Buf_numfrutas]    ; Cargar número total de frutas
    
    xor rbx, rbx                ; Inicializar contador de frutas a 0

imprimir_fila:
    cmp rbx, r15                ; Comparar contador con total de frutas
    jge fin_histograma          ; Saltar al final si ya se procesaron todas
    
    ; Imprimir nombre de la fruta
    mov rax, rbx                ; Copiar índice actual
    imul rax, 16                ; Multiplicar por 16 (tamaño de cada nombre)
    lea rsi, [r13 + rax]        ; Calcular dirección del nombre actual
    
    call imprimir_string        ; Llamar función para imprimir string
    call imprimir_dos_puntos    ; Llamar función para imprimir ":"
    call imprimir_espacio       ; Llamar función para imprimir espacio
    
    ; Aplicar colores ANSI
    call imprimir_codigos_ansi_corregido ; Llamar función para colores
    
    ; Preparar para imprimir barras
    mov rax, rbx                ; Copiar índice actual
    imul rax, 8                 ; Multiplicar por 8 (tamaño de cada cantidad)
    mov rcx, [r14 + rax]        ; Cargar cantidad de frutas actual
    
    ; Verificar si hay cero frutas
    cmp rcx, 0                  ; Comparar cantidad con cero
    je saltar_barras            ; Saltar impresión de barras si es cero

imprimir_barras:
    push rcx                    ; Guardar contador de barras en pila
    mov al, [caracter_barra]    ; Cargar carácter de barra
    call imprimir_caracter      ; Llamar función para imprimir carácter
    pop rcx                     ; Recuperar contador de barras
    loop imprimir_barras        ; Repetir loop según cantidad en rcx

saltar_barras:
    ; Restaurar colores terminal
    call imprimir_reset_ansi    ; Llamar función para resetear colores
    
    ; Imprimir cantidad numérica
    call imprimir_espacio       ; Llamar función para imprimir espacio
    mov rax, rbx                ; Copiar índice actual
    imul rax, 8                 ; Multiplicar por 8
    mov rax, [r14 + rax]        ; Cargar cantidad de frutas actual
    call imprimir_numero        ; Llamar función para imprimir número
    
    ; Nueva línea para siguiente fruta
    call imprimir_nueva_linea   ; Llamar función para nueva línea
    
    inc rbx                     ; Incrementar contador de frutas
    jmp imprimir_fila           ; Saltar al inicio del loop

fin_histograma:
    pop rbx                     ; Restaurar registro rbx
    pop r15                     ; Restaurar registro r15
    pop r14                     ; Restaurar registro r14
    pop r13                     ; Restaurar registro r13
    pop r12                     ; Restaurar registro r12
    ret                         ; Retornar de la función

; ========================================
; Rutina para imprimir códigos ANSI de color
imprimir_codigos_ansi_corregido:
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    push rbx                    ; Guardar registro rbx
    push rcx                    ; Guardar registro rcx
    
    ; Imprimir código de escape para fondo
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, ansi_esc           ; carácter de escape ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    mov rax, 1                  ; syscall: sys_write
    mov rsi, ansi_open          ; carácter "[" de ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    ; Imprimir código numérico de fondo
    movzx rax, byte [color_fondo] ; Cargar color de fondo (zero-extend)
    call imprimir_numero_directo ; Llamar función para imprimir número
    
    mov rax, 1                  ; syscall: sys_write
    mov rsi, ansi_m             ; carácter "m" de ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    ; Imprimir código de escape para color de barra
    mov rax, 1                  ; syscall: sys_write
    mov rsi, ansi_esc           ; carácter de escape ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    mov rax, 1                  ; syscall: sys_write
    mov rsi, ansi_open          ; carácter "[" de ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    ; Imprimir código numérico de barra
    movzx rax, byte [color_barra] ; Cargar color de barra (zero-extend)
    call imprimir_numero_directo ; Llamar función para imprimir número
    
    mov rax, 1                  ; syscall: sys_write
    mov rsi, ansi_m             ; carácter "m" de ANSI
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    pop rcx                     ; Restaurar registro rcx
    pop rbx                     ; Restaurar registro rbx
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

; ========================================
; Rutina para imprimir números sin espacios
imprimir_numero_directo:
    push rbx                    ; Guardar registro rbx
    push rcx                    ; Guardar registro rcx
    push rdx                    ; Guardar registro rdx
    push rsi                    ; Guardar registro rsi
    push rdi                    ; Guardar registro rdi
    
    ; Convertir número a string
    mov rdi, num_buffer + 10    ; Apuntar a buffer temporal
    mov byte [rdi], 0           ; Agregar terminador nulo
    
    mov rbx, 10                 ; Base decimal para conversión
    xor rcx, rcx                ; Inicializar contador de dígitos
    
    ; Manejar caso especial de cero
    test rax, rax               ; Verificar si número es cero
    jnz convert_directo         ; Saltar si no es cero
    mov byte [rdi - 1], '0'     ; Poner carácter '0'
    dec rdi                     ; Ajustar puntero
    inc rcx                     ; Incrementar contador de dígitos
    jmp print_directo           ; Saltar a impresión
    
convert_directo:
    xor rdx, rdx                ; Limpiar registro para división
    div rbx                     ; Dividir rax por 10
    add dl, '0'                 ; Convertir resto a ASCII
    dec rdi                     ; Mover puntero hacia atrás
    mov [rdi], dl               ; Guardar dígito
    inc rcx                     ; Incrementar contador de dígitos
    test rax, rax               ; Verificar si cociente es cero
    jnz convert_directo         ; Continuar si no es cero
    
print_directo:
    ; Imprimir el número convertido
    mov rsi, rdi                ; Puntero al string convertido
    mov rdx, rcx                ; Longitud del string
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    syscall                     ; llamar al sistema
    
    pop rdi                     ; Restaurar registro rdi
    pop rsi                     ; Restaurar registro rsi
    pop rdx                     ; Restaurar registro rdx
    pop rcx                     ; Restaurar registro rcx
    pop rbx                     ; Restaurar registro rbx
    ret                         ; Retornar de la función

; ========================================
; Restablecer colores terminal a defaults
imprimir_reset_ansi:
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, ansi_reset_completo ; código ANSI para reset
    mov rdx, ansi_reset_len     ; longitud del código
    syscall                     ; llamar al sistema
    
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

; ========================================
; Rutinas auxiliares de impresión
imprimir_string:
    push rcx                    ; Guardar registro rcx
    push rdx                    ; Guardar registro rdx
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    
    ; Calcular longitud del string
    mov rdi, rsi                ; Copiar puntero al string
    call strlen                 ; Llamar función para calcular longitud
    mov rdx, rax                ; Mover longitud a rdx
    
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    syscall                     ; llamar al sistema
    
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    pop rdx                     ; Restaurar registro rdx
    pop rcx                     ; Restaurar registro rcx
    ret                         ; Retornar de la función

imprimir_dos_puntos:
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, dos_puntos_msg     ; mensaje de dos puntos
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

imprimir_espacio:
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, espacio_msg        ; mensaje de espacio
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

imprimir_caracter:
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    
    mov [char_buffer], al       ; Guardar carácter en buffer
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, char_buffer        ; buffer con el carácter
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    ret                         ; Retornar de la función

imprimir_numero:                 ; función: imprime el número en RAX
    push rbx                     ; guardar RBX
    push rcx                     ; guardar RCX
    push rdx                     ; guardar RDX
    push rsi                     ; guardar RSI
    push rdi                     ; guardar RDI
    
    mov rdi, num_buffer + 19     ; RDI = puntero al final del buffer
    mov byte [rdi], 0            ; escribir terminador nulo
    dec rdi                      ; retroceder un byte
    mov rbx, 10                  ; RBX = 10 (base decimal)
    
    test rax, rax                ; ¿RAX == 0?
    jnz .convert                 ; si no es 0, convertir
    mov byte [rdi], '0'          ; si es 0, escribir '0'
    dec rdi                      ; retroceder puntero
    jmp .print                   ; ir a imprimir
    
.convert:                        ; etiqueta conversión
    xor rdx, rdx                 ; RDX = 0 (para DIV)
    div rbx                      ; dividir RDX:RAX / RBX → RAX=cociente, RDX=resto
    add dl, '0'                  ; convertir resto a ASCII
    mov [rdi], dl                ; almacenar dígito en buffer
    dec rdi                      ; mover a la izquierda en el buffer
    test rax, rax                ; ¿cociente == 0?
    jnz .convert                 ; si no, repetir
    
.print:                          ; etiqueta impresión
    inc rdi                      ; ajustar al primer carácter válido
    mov rsi, rdi                 ; RSI = inicio del string
    mov rcx, num_buffer + 20     ; RCX = fin del buffer + 1
    sub rcx, rdi                 ; RCX = longitud del string
    mov rdx, rcx                 ; RDX = longitud (arg para write)
    mov rax, 1                   ; syscall number: sys_write
    mov rdi, 1                   ; fd = stdout
    syscall                      ; llamar a write
    
    pop rdi                      ; restaurar RDI
    pop rsi                      ; restaurar RSI
    pop rdx                      ; restaurar RDX
    pop rcx                      ; restaurar RCX
    pop rbx                      ; restaurar RBX
    ret                          ; retornar

imprimir_nueva_linea:
    push rax                    ; Guardar registro rax
    push rdi                    ; Guardar registro rdi
    push rsi                    ; Guardar registro rsi
    push rdx                    ; Guardar registro rdx
    
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; file descriptor: stdout
    mov rsi, nueva_linea_msg    ; mensaje de nueva línea
    mov rdx, 1                  ; longitud: 1 byte
    syscall                     ; llamar al sistema
    
    pop rdx                     ; Restaurar registro rdx
    pop rsi                     ; Restaurar registro rsi
    pop rdi                     ; Restaurar registro rdi
    pop rax                     ; Restaurar registro rax
    ret                         ; Retornar de la función

; ========================================
; Utilidades
strlen:
    push rcx                    ; Guardar registro rcx
    push rdi                    ; Guardar registro rdi
    
    mov rdi, rsi                ; Copiar puntero al string
    xor rcx, rcx                ; Limpiar contador
    not rcx                     ; Invertir bits (rcx = -1)
    xor al, al                  ; Buscar byte cero (terminador)
    cld                         ; Dirección forward (incremento)
    repne scasb                 ; Buscar terminador del string
    not rcx                     ; Complementar para obtener longitud
    dec rcx                     ; Ajustar longitud
    mov rax, rcx                ; Devolver longitud en rax
    
    pop rdi                     ; Restaurar registro rdi
    pop rcx                     ; Restaurar registro rcx
    ret                         ; Retornar de la función

int_to_string:
    push rbx                    ; Guardar registro rbx
    push rcx                    ; Guardar registro rcx
    push rdx                    ; Guardar registro rdx
    push rdi                    ; Guardar registro rdi
    
    mov rbx, 10                 ; Base decimal para conversión
    xor rcx, rcx                ; Inicializar contador de dígitos
    
    test rax, rax               ; Verificar si número es cero
    jnz convert_loop            ; Saltar si no es cero
    mov byte [rdi - 1], '0'     ; Poner carácter '0'
    dec rdi                     ; Ajustar puntero
    inc rcx                     ; Incrementar contador de dígitos
    jmp done_convert            ; Saltar al final
    
convert_loop:
    xor rdx, rdx                ; Limpiar registro para división
    div rbx                     ; Dividir rax por 10
    add dl, '0'                 ; Convertir resto a ASCII
    dec rdi                     ; Mover puntero hacia atrás
    mov [rdi], dl               ; Guardar dígito
    inc rcx                     ; Incrementar contador de dígitos
    test rax, rax               ; Verificar si cociente es cero
    jnz convert_loop            ; Continuar si no es cero
    
done_convert:
    pop rdi                     ; Restaurar registro rdi
    pop rdx                     ; Restaurar registro rdx
    pop rcx                     ; Restaurar registro rcx
    pop rbx                     ; Restaurar registro rbx
    ret                         ; Retornar de la función
    



