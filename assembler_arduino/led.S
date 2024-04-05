;Estas líneas están incluyendo las librerías necesarias para el desarrollo en lenguaje 
;ensamblador para el microcontrolador AVR que Arduino Uno utiliza.
#define __SFR_OFFSET 0x00
#include "avr/io.h"


;Estas líneas están declarando las etiquetas start y led como globales, lo que significa 
;que pueden ser utilizadas por otros archivos o módulos.
.global start
.global led

;Zona de codigo
;Columna 1		Columna 2		Columna 3		Columna 4
;Etiquetas		Operacion		Operandos		Comentarios	

;En la función start, se establece el pin digital 12 (PB4) como salida (output) mediante la 
;instrucción SBI (Set Bit in I/O Register) en el registro DDRB, que controla la dirección de 
;los pines. Luego, se retorna de la función start usando RET.
start:
    SBI       DDRB,       4           ; establece PB4 (D12) como salida
    RET                               ; retorna a la función setup()

;---------------------------------------------------------------------------
;En la función led, se compara el valor en el registro R24 (que es pasado por el llamador de la 
;función) con cero usando la instrucción CPI (Compare Immediate with Register). Si es igual a 
;cero (BREQ), salta a la etiqueta ledOFF que apaga el LED. Si no es igual a cero, establece el 
;pin digital 12 (PB4) en alto (encendido), llama a la función myDelay para un retardo y luego retorna.
led:
    CPI       R24,        0x00        ; compara el valor en R24 pasado por el llamador con 0
    BREQ      ledOFF                  ; salta (branch) si es igual a la subrutina ledOFF
    SBI       PORTB,      4           ; establece D12 a alto
    RCALL     myDelay
    RET                               ; retorna a la función loop()

;---------------------------------------------------------------------------
;La función ledOFF simplemente apaga el LED, estableciendo el pin digital 12 (PB4) en bajo (apagado), 
;luego llama a la función myDelay para un retardo y finalmente retorna.
ledOFF:
    CBI       PORTB,      4           ; establece D12 a bajo
    RCALL     myDelay
    RET                               ; retorna a la función loop()
    
;---------------------------------------------------------------------------
;Esta línea define una constante delayVal con un valor de 10000, que será utilizado como el valor 
;inicial del retardo en la función myDelay.
.equ          delayVal,   10000       ; valor inicial de conteo para el bucle interno

;---------------------------------------------------------------------------
;La función myDelay realiza un retardo utilizando dos bucles anidados. El valor de delayVal se carga 
;en los registros R30 y R31. Luego, se decrementa este valor con SBIW (Subtract Immediate from Word) 
;hasta que llega a cero. Esto se hace dentro de un bucle interno (innerLoop). Después, el bucle externo 
;(outerLoop) decrementa el valor de R20 y continúa hasta que este valor también llega a cero. Luego, la 
;función retorna.
myDelay:
    LDI       R20,        100         ; valor inicial de conteo para el bucle externo
outerLoop:
    LDI       R30,        lo8(delayVal)  ; byte bajo de delayVal en R30
    LDI       R31,        hi8(delayVal)  ; byte bajo de delayVal en R31
innerLoop:
    SBIW      R30,        1           ; resta 1 del valor de 16 bits en R31, R30
    BRNE      innerLoop               ; salta si countVal no es igual a 0
    ;--------------
    SUBI      R20,        1           ; resta 1 de R20
    BRNE      outerLoop               ; salta si R20 no es igual a 0
    RET
;---------------------------------------------------------------------------