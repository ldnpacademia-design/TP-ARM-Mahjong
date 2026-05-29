.data
    @  Secuencia ANSI para limpiar pantalla 
    cls:          .asciz "\x1b[H\x1b[2J"
    lencls:       .word .-cls

    @  Mensajes de Interfaz y Formato (Punto 1) 
    msg_fichas:   .asciz "\n TABLERO DE FICHAS \n  0 1 2 3 4 5 6 7\n +----------------\n"
    msg_niveles:  .asciz "\n\n TABLERO DE NIVELES \n   0 1 2 3 4 5 6 7\n +----------------\n"
    barra:         .asciz "| "
    espacio:      .asciz " "
    linea:        .asciz "\n"

    @  Prompts y Mensajes de Flujo (Punto 2 y 3) 
    prompt1:    .asciz "\n[Ficha 1] Ingrese Fila y Columna (ej. 32): "
    prompt2:    .asciz "[Ficha 2] Ingrese Fila y Columna (ej. 57): "
    msg_err:    .asciz "¡Error! Ficha bloqueada o posicion vacia. Intente de nuevo.\n"
    msg_match:  .asciz "¡MATCH! Las fichas coinciden y fueron eliminadas.\n"
    msg_fail:   .asciz "¡NO MATCH! Las fichas no coinciden. Reiniciando turno...\n"

    @  Buffer de Entrada para Syscalls de Teclado 
    input_buf:  .space 4

    @  Matrices Estáticas de 8x8 (64 celdas / bytes cada una) 
    fichas:
        .ascii "A", "B", "C", "C", "D", "E", "E", "F"
        .ascii "A", "B", "B", "C", "D", "E", "F", "F"
        .ascii "H", "A", "A", "G", "F", "C", "G", "C"
        .ascii "B", "B", "C", "A", "B", "C", "D", "E"
        .ascii "C", "D", "B", "D", "G", "A", "A", "H"
        .ascii "B", "C", "E", "H", "A", "B", "B", "K"
        .ascii "K", "D", "F", "F", "A", "B", "H", "I"
        .ascii "A", "B", "C", "C", "G", "G", "C", "G"

    niveles:
        .byte 1, 1, 1, 1, 2, 2, 1, 1
        .byte 1, 2, 2, 1, 3, 2, 1, 2
        .byte 1, 3, 1, 1, 1, 1, 2, 1
        .byte 2, 2, 2, 3, 3, 1, 1, 3
        .byte 1, 1, 1, 1, 1, 1, 2, 2
        .byte 2, 1, 1, 1, 2, 1, 2, 1
        .byte 1, 1, 1, 3, 3, 3, 1, 1
        .byte 1, 1, 2, 2, 2, 1, 1, 3

    @  Variables para Coordenadas del Turno actual 
    f1_row:     .word 0
    f1_col:     .word 0
    f2_row:     .word 0
    f2_col:     .word 0

.text
.global main
.align 2

main:

loop_juego:  @ El inicio del bucle infinito de juego
    
    @ IMPRIMIR EL TABLERO
    
    BL limpiar_pantalla
    
    LDR r0, =msg_fichas
    BL imprimir_string

    MOV r4, #0                  @ r4 = Fila (0 a 7)
loop_f_fichas:
    ADD r0, r4, #48             @ Convertir fila entera a carácter ASCII
    LDR r1, =input_buf
    STRB r0, [r1]
    MOV r0, r1
    BL imprimir_caracter
    LDR r0, =barra
    BL imprimir_string

    MOV r5, #0                  @ r5 = Columna (0 a 7)
loop_c_fichas:
    LSL r6, r4, #3              @ fila * 8
    ADD r6, r6, r5              @ r6 = índice lineal en memoria

    LDR r0, =niveles
    LDRB r1, [r0, r6]
    CMP r1, #0
    BEQ print_punto_f           @ Si el nivel es 0, dibujamos un punto

    LDR r0, =fichas
    LDRB r0, [r0, r6]
    LDR r1, =input_buf
    STRB r0, [r1]
    MOV r0, r1
    BL imprimir_caracter
    B print_espacio_f

print_punto_f:
    MOV r0, #46                 @ ASCII de '.'
    LDR r1, =input_buf
    STRB r0, [r1]
    MOV r0, r1
    BL imprimir_caracter        

print_espacio_f:
    LDR r0, =espacio
    BL imprimir_string

    ADD r5, r5, #1
    CMP r5, #8
    BNE loop_c_fichas

    LDR r0, =linea
    BL imprimir_string

    ADD r4, r4, #1
    CMP r4, #8
    BNE loop_f_fichas

    @  DIBUJAR MATRIZ DE NIVELES 
    LDR r0, =msg_niveles
    BL imprimir_string

    MOV r4, #0                  @ Fila (0 a 7)
loop_f_niveles:
    ADD r0, r4, #48             @ Fila a ASCII
    LDR r1, =input_buf
    STRB r0, [r1]
    MOV r0, r1
    BL imprimir_caracter
    LDR r0, =barra
    BL imprimir_string

    MOV r5, #0                  @ Columna (0 a 7)
loop_c_niveles:
    LSL r6, r4, #3              @ fila * 8
    ADD r6, r6, r5              @ índice lineal

    LDR r0, =niveles
    LDRB r0, [r0, r6]
    ADD r0, r0, #48             @ Convertir entero (0-3) a carácter ASCII
    LDR r1, =input_buf
    STRB r0, [r1]
    MOV r0, r1
    BL imprimir_caracter

    LDR r0, =espacio
    BL imprimir_string

    ADD r5, r5, #1
    CMP r5, #8
    BNE loop_c_niveles

    LDR r0, =linea
    BL imprimir_string

    ADD r4, r4, #1
    CMP r4, #8
    BNE loop_f_niveles

    
    @ LEER Y VALIDAR FICHA 1
    
pedir_f1:
    LDR r0, =prompt1
    BL imprimir_string
    BL leer_coordenadas         @ Retorna r1 = fila, r2 = columna
    
    BL validar_ficha_libre      
    CMP r0, #1
    BEQ f1_ok
    LDR r0, =msg_err
    BL imprimir_string
    B pedir_f1                  
f1_ok:
    LDR r0, =f1_row
    STR r1, [r0]
    LDR r0, =f1_col
    STR r2, [r0]

    
    @ LEER Y VALIDAR FICHA 2
    
pedir_f2:
    LDR r0, =prompt2
    BL imprimir_string
    BL leer_coordenadas         @ Retorna r1 = fila, r2 = columna
    
    BL validar_ficha_libre      
    CMP r0, #1
    BEQ f2_ok
    LDR r0, =msg_err
    BL imprimir_string
    B pedir_f2                  
f2_ok:
    LDR r0, =f2_row
    STR r1, [r0]
    LDR r0, =f2_col
    STR r2, [r0]

    
    @ COMPARAR, RESOLVER MATCH Y ACTUALIZAR
    
    BL comparar_pareja          @ Llama a la nueva rutina solicitada
    CMP r0, #1                  @ Si r0 == 1 significa que hubo MATCH
    BEQ turno_match             @ Salta a procesar el acierto

    @   NO MATCH 
    LDR r0, =msg_fail
    BL imprimir_string
    
    LDR r8, =0x50000000        @ Delay manual de error
delay_f:
    SUBS r8, r8, #1
    BNE delay_f

    B loop_juego                @  Vuelve al inicio del turno

turno_match:
    LDR r0, =msg_match
    BL imprimir_string

    @ Rutinas solicitadas por la consigna para procesar el MATCH:
    BL eliminar_ficha           @ Modifica visualmente o prepara la eliminación
    BL actualizar_niveles       @ Decrementa la matriz niveles[][] en ambas posiciones

    LDR r8, =0x50000000         @ Delay manual de éxito
delay_m:
    SUBS r8, r8, #1
    BNE delay_m

    B loop_juego                @ Vuelve al inicio del turno



@ RUTINAS DE LÓGICA Y REGLAS DE JUEGO

comparar_pareja:
    PUSH {r4, r5, r6, lr}       @ Protege los registros en la pila
    
    LDR r0, =f1_row
    LDR r1, [r0]
    LDR r0, =f1_col
    LDR r2, [r0]

    LDR r0, =f2_row
    LDR r3, [r0]
    LDR r0, =f2_col
    LDR r4, [r0]

    @ Control de Duplicados: Misma posición exacta no es válido
    CMP r1, r3
    BNE comp_letras
    CMP r2, r4
    BEQ fallo_pareja            @ Si coinciden fila y col, va a fallo

comp_letras:
    LSL r5, r1, #3
    ADD r5, r5, r2              @ Índice lineal Ficha 1
    LDR r0, =fichas
    LDRB r5, [r0, r5]           @ Carga letra de Ficha 1

    LSL r6, r3, #3
    ADD r6, r6, r4              @ Índice lineal Ficha 2
    LDRB r6, [r0, r6]           @ Carga letra de Ficha 2

    CMP r5, r6                  @ ¿Tienen la misma letra activa?
    BNE fallo_pareja            @ Si no coinciden, salta

    MOV r0, #1                  @ Retorna r0 = 1 (MATCH exitoso)
    POP {r4, r5, r6, pc}
fallo_pareja:
    MOV r0, #0                  @ Retorna r0 = 0 (No coinciden)
    POP {r4, r5, r6, pc}

eliminar_ficha:
    PUSH {lr}                   
    @  Esta rutina intermedia representa la acción lógica de 
    @ remover las fichas.
    POP {pc}

actualizar_niveles:
    PUSH {r4, r5, r6, lr}       @ Protege registros de trabajo
    LDR r0, =niveles            @ r0 = Dirección base de niveles[][]

    @ Decrementar nivel Ficha 1
    LDR r4, =f1_row
    LDR r1, [r4]
    LDR r4, =f1_col
    LDR r2, [r4]
    LSL r5, r1, #3
    ADD r5, r5, r2              @ Índice lineal Ficha 1
    LDRB r6, [r0, r5]           @ Lee nivel actual
    SUB r6, r6, #1              @ Decrementa en 1
    STRB r6, [r0, r5]           @ Guarda en memoria RAM

    @ Decrementar nivel Ficha 2
    LDR r4, =f2_row
    LDR r1, [r4]
    LDR r4, =f2_col
    LDR r2, [r4]
    LSL r5, r1, #3
    ADD r5, r5, r2              @ Índice lineal Ficha 2
    LDRB r6, [r0, r5]           @ Lee nivel actual
    SUB r6, r6, #1              @ Decrementa en 1
    STRB r6, [r0, r5]           @ Guarda en memoria RAM

    POP {r4, r5, r6, pc}        @ Restaura y regresa al código principal



@ RUTINAS DE ENTRADA DE TECLADO Y VALIDACIÓN


/* limpiar_pantalla:
    PUSH {r7, lr}
    MOV r0, #1                  @ stdout
    LDR r1, =cls
    LDR r2, =lencls
    LDR r2, [r2]
    MOV r7, #4                  @ Syscall write
    SWI 0
    POP {r7, pc} */

leer_coordenadas:
    PUSH {r7, lr}
    MOV r0, #0                  @ stdin
    LDR r1, =input_buf          
    MOV r2, #3                  @ Leer Fila, Columna y Enter
    MOV r7, #3                  @ Syscall read
    SWI 0

    LDR r0, =input_buf
    LDRB r1, [r0]               
    LDRB r2, [r0, #1]           

    SUB r1, r1, #48             @ De ASCII a número entero
    SUB r2, r2, #48             @ De ASCII a número entero
    POP {r7, pc}

validar_ficha_libre:
    PUSH {r1, r2, r3, lr}       
    LSL r3, r1, #3
    ADD r3, r3, r2              

    LDR r0, =niveles
    LDRB r0, [r0, r3]
    CMP r0, #0               
    BEQ bloqueada               

    CMP r2, #0
    BEQ aprobada                
    CMP r2, #7
    BEQ aprobada                

    LDR r0, =niveles
    SUB r1, r3, #1
    LDRB r1, [r0, r1]
    CMP r1, #0               
    BEQ aprobada                

    ADD r1, r3, #1
    LDRB r1, [r0, r1]
    CMP r1, #0                  
    BEQ aprobada                

bloqueada:
    MOV r0, #0                  
    POP {r1, r2, r3, pc}        
aprobada:
    MOV r0, #1                  
    POP {r1, r2, r3, pc}  


@ RUTINAS DE SALIDA Y PANTALLA    

limpiar_pantalla:
    PUSH {r7, lr}
    MOV r0, #1                  @ stdout
    LDR r1, =cls
    LDR r2, =lencls
    LDR r2, [r2]
    MOV r7, #4                  @ Syscall write
    SWI 0
    POP {r7, pc}  

imprimir_string:
    PUSH {r1, r2, r3, r4, r7, lr} 
    MOV r4, r0
    MOV r2, #0
contar_bytes:
    LDRB r3, [r4, r2]
    CMP r3, #0
    BEQ ejecutar_write
    ADD r2, r2, #1
    B contar_bytes
ejecutar_write:
    MOV r1, r4
    MOV r0, #1                  
    MOV r7, #4                  
    SWI 0
    POP {r1, r2, r3, r4, r7, pc}

imprimir_caracter:
    PUSH {r7, lr}
    MOV r1, r0
    MOV r2, #1                  
    MOV r0, #1                  
    MOV r7, #4                  
    SWI 0
    POP {r7, pc}

.global imprimir_string
.global imprimir_caracter
.global leer_coordenadas
.global validar_ficha_libre
.global comparar_pareja
.global eliminar_ficha
.global actualizar_niveles