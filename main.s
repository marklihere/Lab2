; main.s
; Runs on any Cortex M processor
; A very simple first project implementing a random number generator
; Daniel Valvano
; May 4, 2012

;  This example accompanies the book
;  "Embedded Systems: Introduction to Arm Cortex M Microcontrollers",
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2012
;  Section 3.3.10, Program 3.12
;
;Copyright 2012 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or diSTRibute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/

       THUMB
       AREA    DATA, ALIGN=2
       ALIGN          
       AREA    |.text|, CODE, READONLY, ALIGN=2
       EXPORT  Start

; Masked addr for each switch on GPIO_F
RESETB	EQU	0x40025004  ; PF0
GO	    EQU	0x40025020  ; PF3
STOP	EQU	0x40025040  ; PF4

; Base Addresses and Unlock codes/address
RCGCGPIO EQU 0x400FE108 ; Clocks for GPIOs
UNLOCK	EQU 0x4C4F434B  ; Unlock code for GPIO Port F
PORTF	EQU 0x40025000  ; GPIO Port F
PORTC	EQU	0x40006000	; GPIO Port C
PORTE	EQU	0x40024000	; GPIO Port E

BIT0	EQU 0x40006040  ; PC4
BIT1	EQU 0x40006080  ; PC5
BIT2	EQU 0x40006100  ; PC6
BIT3	EQU 0x40006200  ; PC7
BIT4	EQU 0x40024004  ; PE0
BIT5	EQU 0x40024008  ; PE1
BIT6	EQU 0x40024010  ; PE2
BIT7	EQU 0x40024020  ; PE3
BIT8	EQU 0x40024040  ; PE4
BIT9	EQU 0x40024080  ; PE5
	
Start  
;------------------------------------------------------
; Initialize GPIO Ports
	;MOV32 R0, #0x400FE108 ; Enable GPIO Clock RCGCGPIO
	LDR R0, =RCGCGPIO ; Enable GPIO Clock RCGCGPIO
	MOV R1, #0x34    ; Enables GPIO Port C, E, and F
	STR R1, [R0]     ;

;-----------------------
; Unlock Port F
	LDR R0, =PORTF	
	LDR R1, =UNLOCK
	STR R1, [R0,#0x520];

; Enable port F for switches
	MOV R1, #0x19      ; enable bits 0,3,4 for switches
	STR R1, [R0,#0x524]; GPIOCR enable [0,3,4]
	STR R1, [R0,#0x510]; GPIOPUR on [0,3,4]
	MOV R1, #0xE6      ; [0,3,4] are inputs
	STR R1, [R0,#0x400]; GPIODIR set as above
	MOV R1, #0x19
	STR R1, [R0,#0x51C] ;GPIODEN [0,3,4]

; Enable port C for lower 4 bits of LED
	LDR R0, =PORTC
	LDR R1, =UNLOCK
	STR R1, [R0,#0x520];

	MOV R1, #0xF0;   
	STR R1, [R0,#0x524]; GPIOCR enable [7:4]
	MOV R1, #0xF0;      ; [7:4] are outputs
	STR R1, [R0,#0x510] ; GPIOPUR [7:4]
	STR R1, [R0,#0x400] ; GPIODIR set as above
	STR R1, [R0,#0x51C] ; GPIODEN [7:4]

; Enable port E for higher 6 bits of LED
	LDR R0, =PORTE
	MOV R1, #0x3F;
	STR R1, [R0,#0x524] ; GPIOCR enable [5:0]
	MOV R1, #0x3F;      ; [5:0] are outputs
	STR R1, [R0,#0x400] ; GPIODIR set as above
	STR R1, [R0,#0x510] ; GPIOPUR [5:0]
	STR R1, [R0,#0x51C] ; digital enable bits[5:0]

;------------------------------------------------------
; ACTUAL PROGRAM!!
;------------------------------------------------------

Reset	
	MOV R4, #0            ; global counter = 0, sorry
	BL print

; Is Start Pushed?  if Y start Running, if N, Reset
	LDR R0, =GO          ; Read input of Start switch
	LDR R1, [R0]         ; GPIOF pin 3, the external button
	CMP R1, #0x0         ; Check if button pushed
	BEQ Running;
	B Reset;

;----------------------
; Runstate
Running
		ADD R4, #1          ; counter++
		BL print

; Check if reset
		LDR R0, =RESETB     ; Read input of Reset switch
		LDR R1, [R0]        ; GPIOF pin0 for Reset switch
		CMP R1, #0x0        ; reset button pushed?
		BEQ Reset

; Check if stop
		LDR R0, =STOP       ; Addr of Stop switch
		LDR R1, [R0]        ; Read switch
		CMP R1, #0x0        ; stop button pushed?
		BEQ Stopstate       ; Yep

; enter delay b/c no reset and no stop, so keep counting 
; Delay loop for remainder of 0.25s
		MOV32 R0, #0x145855 ; delay counter 1,333,333 cycles 
delay	SUBS R0, #1    	    ; decrement delay counter
		BNE delay

; Finished 0.5s delay, keep on running
		B Running

;----------------------
Stopstate
; Check if reset
		LDR R0, =RESETB     ; Read input of Reset switch
		LDR R1, [R0]        ; GPIOF pin0 for Reset switch
		CMP R1, #0x0        ; reset button pushed?
		BEQ Reset

; Check if start
		LDR R0, =GO        ; Read input of Reset switch
		LDR R1, [R0]       ; GPIOF pin0 for Reset switch
		CMP R1, #0x0       ; Check if button pushed
		BEQ Running
		B Stopstate

;----------------------
; Print Subroutine
print
	PUSH {LR}              ; Store Return
	MVN R5, R4;            ; Invert counter due to active low LEDs
	LDR R0, =PORTC         ; GPIOC base address
	LSL R10, R5, #4        ; get lower bits [3:0] of counter into bit position [7:4] of R10
	STR R10, [R0,#0x3C0]   ; write counter[3:0]  into Port C[7:4]
	LDR R0, =PORTE         ; GPIOE base address
	LSR R10, R5, #4        ; rotate counter upper 6 bits for LED display into position [5:0]
	STR R10, [R0,#0x0FC]   ; write upper six bits into LED disply
	POP {LR}
	BX LR

	ALIGN      
    END  
           