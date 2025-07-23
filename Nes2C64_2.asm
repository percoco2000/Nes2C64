;----------------------------------------------;
; Program : Nes_toC64.asm                      ;
;----------------------------------------------;
; An interface to connect a NES Controller     ;
; to a Commodore64 Joystick port.              ;
; The NES controller use a serial interface    ;
; while the C64 Use a 5 bit parallel interface.;
; The NES is connected to PORTA and is so      ;  
; configured  								   ;
;                                              ;
; LATCH -> RA3                                 ;
; CLOCK -> RA2                                 ;
; DATA  -> RA4                                 ;
; The C64 Joystick is so configured            ;
;                                              ;
; UP    -> RB7                                 ;
; DOWN  -> RB6                                 ;
; LEFT  -> RB5                                 ;
; RIGHT -> RB4                                 ;
; START -> RB0                                 ;
; SELECT-> RB1                                 ;
; B     -> RB2                                 ;
; A     -> RB3                                 ;
;----------------------------------------------;

	processor p16f84
	;       _CP_OFF    _PWRTE_ON   _WDT_OFF   _RC_OSC 
	__CONFIG H'3FFF' &  H'3FF7' &   H'3FFB' &  H'3FFF'  
	
; ------- Aliases Set Up -------------
STATUS	equ		03h 	; status register
TRISA	equ		85h     ; Config register for PORT A
TRISB   equ     	86h     ; Config register for PORT B
PORTA	equ		05h 	; PORT A address
PORTB   equ     	06h     ; PORT B address
COUNT1	equ		08h		; First counter
COUNT2 	equ		09h		; Second counter
BYTE	equ		0x0C	; Byte storing the NES button status
N_BIT   equ     	9Fh     ; Used to count the bit readed

; -------- PORTA Bits Config -----------
LTC 	equ		0x03
CLK	equ		0x02
DAT	equ		0x04

; ------- Port Setup ------------------

	bsf 	STATUS,5	;Switch to BANK 1
	movlw	00h		;Load 0 in W register
	movwf   TRISA		;W -> TRISA (All PORTA pins output)
	movwf   TRISB   	;W -> TRISA (All PORTB pins output)
	bsf	TRISA,DAT	;RA2 -> Input
	bcf	STATUS,5	;Switch to BANK 0
	movwf   PORTA   	;
	movwf   PORTB       	; Clear ports
		
		
; ---- Main Program -----
		
Start:
        clrf	BYTE		; Clear BYTE
        bsf	PORTA,LTC	; Pulse LATCH 
	call 	delay
	bcf	PORTA,LTC
	movlw	0x08
	movwf	N_BIT		; Number of bits to read

;Read The bits from the NES gamepad, and store them 
;in BYTE
;The first Bit will be the LSB
;At the end, swap the Nibbles, so the direction will
;be stored in the first Nibble
;This will be the final bitS configurations:
; ----------------------------------------------
;NES : | UP | DN | LF | RG | A | B | SL | ST |
;BYTE: | 7  |  6 |  5 |  4 | 3 | 2 |  1 |  0 |   
; ----------------------------------------------
MainLoop:			
	nop 
	nop
	bsf	STATUS,0    	; Set CARRY -> 1
	btfss	PORTA,DAT	; BIT = 1 ?
	bcf	STATUS,0 	; NO, Clear CARRY
	rlf	BYTE,1		; BYTE << CARRY
	bcf	PORTA,CLK	; Clock OFF
	nop
	nop
	bsf	PORTA,CLK	; Clock ON
		
	decfsz  N_BIT,1
	goto	MainLoop
		
	swapf	BYTE,1		; Swap Nibbles so RB4-RB7 are alligned to C64 PORT
	movf	BYTE,0
	movwf	PORTB
	goto 	Start

		
delay:
        movlw 	0xA0
	movwf 	COUNT1
		
Loop1:
	decfsz	COUNT1,1	;COUNT1--; if COUNT1=0 Skip next instruction
	goto 	Loop1
	movwf 	COUNT1 		
Loop2:
	decfsz	COUNT1,1    	;COUNT1--; if COUNT2=0 Skip next instruction
	goto 	Loop2

        return

        end
