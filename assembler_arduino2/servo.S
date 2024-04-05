;Estas líneas están definiendo el desplazamiento base para los registros de E/S específicos de AVR y 
;están incluyendo las librerías necesarias para trabajar con los registros de E/S en un microcontrolador AVR.
#define __SFR_OFFSET 0x00
#include "avr/io.h"

;------------------------
;Esta línea declara la etiqueta servo_motor como global, lo que significa que puede ser referenciada desde 
;otros archivos o módulos.
.global servo_motor
;===============================================================

;Zona de codigo
;Columna 1		Columna 2		Columna 3		Columna 4
;Etiquetas		Operacion		Operandos		Comentarios	

;Estas instrucciones configuran los pines del puerto B (PB4, PB0, PB1 y PB2) como salidas para controlar el 
;servo y los LEDs en diferentes posiciones.
servo_motor:
;-----------
    SBI       DDRB,       4           ; Configura PB4 como salida para el control del servo
    SBI       DDRB,       0           ; Configura PB0 como salida para el LED rojo en la posición 0 grados
    SBI       DDRB,       1           ; Configura PB1 como salida para el LED verde en la posición 90 grados
    SBI       DDRB,       2           ; Configura PB2 como salida para el LED azul en la posición 180 grados
;---------------------------------------------------------------

;Estas instrucciones inicializan los contadores y cargan la dirección de memoria de las 
;posiciones de rotación en los registros Z.
again:     
    LDI       R25,        1          ; Contador para el control del LED
    LDI       R26,        8          ; Contador para el número de posiciones de rotación
    LDI       ZL,         lo8(rotate_pos) ; Carga la dirección de memoria de las posiciones de rotación
    LDI       ZH,         hi8(rotate_pos)
    ;-----------------------------------------------------------
    
;Este bucle lee cada posición de rotación desde la memoria de programa, llama a la función 
;rotate_servo para mover el servo a esa posición y decrementa el contador de posiciones de rotación.    
l1: LPM       R24,        Z+        ; Carga la posición de rotación
    RCALL     rotate_servo          ; y rota el servo
    DEC       R26
    BRNE      l1                    ; Vuelve a obtener otra posición de rotación
    ;-----------------------------------------------------------

;Después de recorrer todas las posiciones de rotación, el programa salta de nuevo al inicio del 
;bucle again para repetir el proceso.
    RJMP      again                 ; Vuelve a repetir el proceso
;---------------------------------------------------------------

;Estas son las posiciones de rotación del servo en grados, almacenadas en la memoria de programa.
rotate_pos:
.byte 40,70,90,110,180,110,90,70    ; Posiciones de rotación en grados
;===============================================================

;Esta instrucción inicializa el contador para generar suficientes ciclos de señal PWM para controlar el servo.
rotate_servo:
;------------
    LDI         R20,      10         ; Contador para generar suficientes ciclos de PWM

;Este bucle genera la señal PWM para controlar el servo. Se establece el pin del servo en alto, 
;se espera el tiempo necesario para el pulso PWM, se establece el pin en bajo y luego se espera 
;un tiempo antes de generar otro pulso PWM. Este proceso se repite el número de veces necesario 
;para generar suficientes ciclos PWM.
l2: SBI         PORTB,    4         ; Establece el pin del servo en alto
    RCALL       delay_timer0        ; Espera el tiempo necesario para el pulso PWM
    CBI         PORTB,    4         ; Establece el pin del servo en bajo
    RCALL       delay_20ms          ; Espera 20ms antes de enviar otro pulso
    DEC         R20
    BRNE        l2                  ; Repite la señal PWM
    ;-----------------------------------------------------------

;Estas instrucciones comparan la posición actual del servo (R25) con valores específicos y, si coincide, 
;saltan a diferentes subrutinas para encender los LEDs correspondientes.
    CPI       R25,        1
    BREQ      red_LED               ; Si la posición es 0 grados, enciende el LED rojo
    CPI       R25,        3
    BREQ      green_LED             ; Si la posición es 90 grados, enciende el LED verde
    CPI       R25,        5
    BREQ      blue_LED              ; Si la posición es 180 grados, enciende el LED azul
    CPI       R25,        7
    BREQ      green_LED             ; Si la posición es 90 grados, enciende el LED verde

;Esta parte del código espera medio segundo y luego apaga todos los LEDs. Luego, incrementa el contador 
;de posición (R25) y retorna a la subrutina principal.
bak:RCALL     delay_ms            ; Espera 0.5 segundos
    CBI       PORTB, 0
    CBI       PORTB, 1
    CBI       PORTB, 2            ; Apaga todos los LEDs
    INC       R25
    RET                           ; Retorna a la subrutina principal
;-------------------

;Esta subrutina enciende el LED rojo (PORTB, 0), apaga los otros LEDs y luego salta al punto bak.
red_LED:                          ; Subrutina para encender el LED rojo
    SBI       PORTB,      0
    CBI       PORTB,      1
    CBI       PORTB,      2
    RJMP      bak
;------------------

;Esta subrutina enciende el LED verde (PORTB, 1), apaga los otros LEDs y luego salta al punto bak.
green_LED:                        ; Subrutina para encender el LED verde
    CBI       PORTB,      0
    SBI       PORTB,      1
    CBI       PORTB,      2
    RJMP      bak
;------------------

;Esta subrutina enciende el LED azul (PORTB, 2), apaga los otros LEDs y luego salta al punto bak.
blue_LED:                         ; Subrutina para encender el LED azul
    CBI       PORTB,      0
    CBI       PORTB,      1
    SBI       PORTB,      2
    RJMP      bak


;===============================================================
; Subrutinas de retardo
;===============================================================
;Esta subrutina delay_timer0 realiza un retardo utilizando el Timer0. Primero inicializa el Timer0 
;con un contador igual a cero y configura el valor de comparación para generar la interrupción. 
;Luego espera hasta que la bandera de interrupción sea activada, indicando que el Timer0 ha alcanzado 
;el valor de comparación. Después de eso, detiene el Timer0 y borra la bandera de interrupción antes 
;de retornar.
delay_timer0:                     ; Retardo mediante Timer0
    ;-----------------------------------------------------------
    CLR       R21
    OUT       TCNT0,      R21     ; Inicializa el Timer0 con un contador = 0
    MOV       R21,        R24
    OUT       OCR0A,      R21
    LDI       R21,        0b00001100
    OUT       TCCR0B,     R21     ; Timer0: Modo CTC, preescalador 256
    ;-----------------------------------------------------------
l3: IN        R21,        TIFR0   ; Obtiene el byte de TIFR0 y lo verifica
    SBRS      R21,        OCF0A   ; Si OCF0=1, salta la siguiente instrucción
    RJMP      l3                  ; De lo contrario, vuelve y verifica la bandera OCF0
    ;-----------------------------------------------------------
    CLR       R21
    OUT       TCCR0B,     R21     ; Detiene el Timer0
    ;-----------------------------------------------------------
    LDI       R21, (1<<OCF0A)
    OUT       TIFR0,      R21     ; Borra la bandera OCF0
    RET
;===============================================================

;La subrutina delay_20ms realiza un retardo de aproximadamente 20ms utilizando un bucle 
;de decremento anidado. Esto genera un retardo aproximado ya que depende de la velocidad del 
;procesador y de otras consideraciones del sistema.
delay_20ms:                       ; Retardo de 20ms
    LDI       R21,        255
l4: LDI       R22,        210
l5: LDI       R23,        2
l6: DEC       R23
    BRNE      l6
    DEC       R22
    BRNE      l5
    DEC       R21
    BRNE      l4
    RET
;===============================================================

;La subrutina delay_ms realiza un retardo de aproximadamente 0.5 segundos utilizando un 
;bucle de decremento anidado similar al de delay_20ms, pero con valores diferentes para 
;alcanzar el tiempo deseado.
delay_ms:                           ; Retardo de 0.5 segundos
    LDI       R21,        255
l7 :LDI       R22,        255
l8 :LDI       R23,        41
l9 :DEC       R23
    BRNE      l9
    DEC       R22
    BRNE      l8
    DEC       R21
    BRNE      l7
    RET