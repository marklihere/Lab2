; Mark Li and Aaron Yardley
; Sep 20, 2016
; ECE 3710 Lab 3
; 10-bit binary LED counter

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
	
Start  
;------------------------------------------------------
; Initialize GPIO Ports
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
	CMP R1, #0         ; Check if button pushed
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
		CMP R1, #0        ; reset button pushed?
		BEQ Reset

; Check if stop
		LDR R0, =STOP       ; Addr of Stop switch
		LDR R1, [R0]        ; Read switch
		CMP R1, #0        ; stop button pushed?
		BEQ Stopstate       ; Yep

; enter delay b/c no reset and no stop, so keep counting 
; 2 Hz means period = 0.5 s period, 0.25 per off/on cycle
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
		CMP R1, #0        ; reset button pushed?
		BEQ Reset

; Check if start
		LDR R0, =GO        ; Read input of Reset switch
		LDR R1, [R0]       ; GPIOF pin0 for Reset switch
		CMP R1, #0       ; Check if button pushed
		BEQ Running
		B Stopstate

;----------------------
; Print Subroutine
; Displays R4[9:0] on LED bar
;  Uses ugly global variables, doesn't store
print
	PUSH {LR}              ; Store Return
	MVN R5, R4;            ; Invert counter due to active low LEDs
	LDR R0, =PORTC
	LSL R10, R5, #4        ; get lower bits [3:0] of counter into bit position [7:4] of R10
	STR R10, [R0,#0x3C0]   ; write counter[3:0]  into Port C[7:4]
	LDR R0, =PORTE
	LSR R10, R5, #4        ; rotate counter upper 6 bits for LED display into position [5:0]
	STR R10, [R0,#0x0FC]   ; write upper six bits into LED disply
	POP {LR}
	BX LR

	ALIGN      
    END  
           