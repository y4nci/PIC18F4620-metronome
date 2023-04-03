PROCESSOR    18F4620

#include <xc.inc>

; CONFIGURATION (DO NOT EDIT)
CONFIG OSC = HSPLL      ; Oscillator Selection bits (HS oscillator, PLL enabled (Clock Frequency = 4 x FOSC1))
CONFIG FCMEN = OFF      ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
CONFIG IESO = OFF       ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)
; CONFIG2L
CONFIG PWRT = ON        ; Power-up Timer Enable bit (PWRT enabled)
CONFIG BOREN = OFF      ; Brown-out Reset Enable bits (Brown-out Reset disabled in hardware and software)
CONFIG BORV = 3         ; Brown Out Reset Voltage bits (Minimum setting)
; CONFIG2H
CONFIG WDT = OFF        ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
; CONFIG3H
CONFIG PBADEN = OFF     ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
CONFIG LPT1OSC = OFF    ; Low-Power Timer1 Oscillator Enable bit (Timer1 configured for higher power operation)
CONFIG MCLRE = ON       ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)
; CONFIG4L
CONFIG LVP = OFF        ; Single-Supply ICSP Enable bit (Single-Supply ICSP disabled)
CONFIG XINST = OFF      ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; GLOBAL SYMBOLS
; You need to add your variables here if you want to debug them.
GLOBAL init_loop_inc1
GLOBAL init_loop_inc2
GLOBAL init_loop_inc3
GLOBAL init_loop_inc4
GLOBAL init_loop_container_inc

; Define space for the variables in RAM
PSECT udata_acs
init_loop_inc1:
    DS 1
init_loop_inc2:
    DS 1
init_loop_inc3:
    DS 1
init_loop_inc4:
    DS 1
init_loop_container_inc:
    DS 1

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE

main:
    call init
    movlw 31
    
init:
    movlw 11100000B ; lit up RA{0-1-2}
    movwf LATA ; move WREG to LATA
    movlw 8
    movwf init_loop_container_inc

    ; wait for 1000ms
    call init_loop_container

    return

init_loop_container:
    movlw 5 ; for setting inc{1-2-3-4} values
    movwf init_loop_inc1
    movwf init_loop_inc2
    movwf init_loop_inc3
    movwf init_loop_inc4
    call init_loop1
    call init_loop2
    call init_loop3
    call init_loop4
    
    infsnz init_loop_container_inc
    return
    goto init_loop_container
    
init_loop1:
    infsnz init_loop_inc1
    return
    goto init_loop1

init_loop2:
    infsnz init_loop_inc2
    return
    goto init_loop2
    
init_loop3:
    infsnz init_loop_inc3
    return
    goto init_loop3
    
init_loop4:
    infsnz init_loop_inc4
    return
    goto init_loop4

post_init_loop:

end resetVec
