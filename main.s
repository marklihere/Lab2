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
;   You may use, edit, run or distribute this file
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
	   ;unlock 0x4C4F434B


	   ;PF4 is SW1
	   ;PF0 is SW2
	   ;PF1 is RGB Red
	   ;Enable Clock RCGCGPIO p338
	   ;Set direction 1 is out 0 is in. GPIODIR
	   ;DEN 
	   ; 0x3FC
RESET	EQU	0x40025004  ; PF0
START	EQU	0x40025020  ; PF3
STOP	EQU	0x40025040  ; PF4

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
;----------------------------
; Initialize GPIO Ports
	mov32 R0, #0x400FE108 ; Enable GPIO Clock RCGCGPIO
	mov R1, #0x34    ; Enables GPIO Port C, E, and F
	str R1, [R0]     ;

;---------------------------
; Unlock Port F
	mov32 R0, #0x40025000 ;GPIOF address
	
	;unlock GPIOF
	mov32 R1, #0x4C4F434B; GPIO Unlock code. 
	str R1, [R0,#0x520];

;; Enable port F for switches
	mov R1, #0x19   ; enable bits 0, 3, 4 for switches
	str R1, [R0,#0x524]; set GPIOCR with above value
	mov R1, #0x00;   
	str R1, [R0,#0x420];   disable alternative function
	mov R1, #0x19 ; enable weak pullup on pins for bits 0, 3, 4
	str R1, [R0,#0x510]; set GPIOPUR with above value
	mov R1, #0xE6      ; pins 0, 3, 4 as inputs
	str R1, [R0,#0x400] ;set GPIODIR with above value
	mov R1, #0x19 ; enable mask for positive logic with bits 0, 3, 4
	str R1, [R0,#0x51C] ;digital enable bit 0, 3, 4

; Enable port C
	mov32 R0, #0x40006000 ;GPIOC base address
	;unlock GPIOF
	mov32 R1, #0x4C4F434B; GPIO Unlock code. 
	str R1, [R0,#0x520];

	mov R1, #0xF0;   
	str R1, [R0,#0x524]; set GPIOCR with above value
	mov R1, #0x00;   
	str R1, [R0,#0x420];   disable alternative function
	mov R1, #0xF0;      ; bit [7:4] of PC are outputs
	str R1, [R0,#0x400] ;set GPIODIR with above value
	str R1, [R0,#0x510]; set GPIOPUR with above value  enables pullup on bits [7:4]
	str R1, [R0,#0x51C] ;digital enable bits[7:4]

; Enable port E
	mov32 R0, #0x40024000 ;GPIOE base address
	mov R1, #0x3F;
	str R1, [R0,#0x524]; set GPIOCR with above value
	mov R1, #0x00;   
	str R1, [R0,#0x420];   disable alternative function
	mov R1, #0x3F;      ; bit [5:0] of PC are outputs
	str R1, [R0,#0x400] ;set GPIODIR with above value
	str R1, [R0,#0x510]; set GPIOPUR with above value  enables pullup on bits [5:0]
	str R1, [R0,#0x51C] ;digital enable bits[5:0]

Reset
;; Turn off bits [3:0] of LED bar
	mov32 R0, #0x40006000 ;GPIOC base address
	MOV32 R1, #0xF0;
	STR R1, [R0,#0x3C0]	;write the above value to GPIOF ODR register.

;; Turn off bits [7:4] of LED bar  PE[0:5]
	mov32 R0, #0x40024000 ;GPIOE base address
	MOV32 R1, #0x3F	;  
	STR R1, [R0,#0x0FC]	;write the above value to GPIOF ODR register.

;; Count = 0
	MOV R4, #0x0    ; We suck and use global variables

;----------------------
; ACTUAL PROGRAM!!
;

;; Checked if reset if pushed
		LDR R0, =RESET          ; Read input of Reset switch
		LDR R1, [R0]            ; GPIOF pin0 for Reset switch
		CMP R1, #0x0            ; Check if button pushed
		BEQ pushed;
;; If stop is pushed during initial state, it has no effect because LEDs are already off
; and counter is already zero, so skip to reading START button
;; Check if Start is pushed		
		LDR R0, =START          ; Read input of Start switch
		LDR R1, [R0]            ; GPIOF pin 3, the external button
		CMP R1, #0x0            ; Check if button pushed
		BEQ start;    
		B   Reset
start
		ADD R4, #0x1        ; Nice global counter is increment

;; Delay loop 
		MOV R0, #0xf        ; delay counter  0x28B0AA 2,666,666 cycles 
delay	SUBS R0, #1    	;  decrement counter
		BNE delay

;; Real check for inputs while running
;; Checked if reset if pushed
		LDR R0, =RESET          ; Read input of Reset switch
		LDR R1, [R0]            ; GPIOF pin0 for Reset switch
		CMP R1, #0x0            ; Check if button pushed
		BEQ pushed;
;; If stop is pushed during initial state, it has no effect because LEDs are already off
; and counter is already zero, so skip to reading START button
;; Check if Start is pushed		
		LDR R0, =START          ; Read input of Start switch
		LDR R1, [R0]            ; GPIOF pin 3, the external button
		CMP R1, #0x0            ; Check if button pushed


pushed
	LDR R1, =0x40024040   ; BIT 7
	MOV R0, #0x8          ;
	STR R0, [R1];
       B   Reset

       ALIGN      
       END  
           
