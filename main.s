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
    
GLOBAL main_loop_inc1
GLOBAL main_loop_inc2
GLOBAL PREV_main_loop_inc1
GLOBAL PREV_main_loop_inc2
GLOBAL previous_click_state0
GLOBAL previous_click_state1
GLOBAL previous_click_state2    
GLOBAL previous_click_state3
GLOBAL previous_click_state4

GLOBAL bar_len
GLOBAL speed
GLOBAL paused
GLOBAL beat_num
GLOBAL lights_should_be_on
    
GLOBAL buff
GLOBAL PREV_buff

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

main_loop_inc1:
    DS 1
main_loop_inc2:
    DS 1
PREV_main_loop_inc1:
    DS 1
PREV_main_loop_inc2:
    DS 1
previous_click_state0:
    DS 1
previous_click_state1:
    DS 1
previous_click_state2:
    DS 1
previous_click_state3:
    DS 1
previous_click_state4:
    DS 1

bar_len:
    DS 1
speed:
    DS 1
paused:
    DS 1
beat_num:
    DS 1
lights_should_be_on:
    DS 1
    
buff:
    DS 1
PREV_buff:
    DS 1

PSECT resetVec,class=CODE,reloc=2
resetVec:
    goto       main

PSECT CODE

main:
    call init
    
    call initialise_main_loop
    call main_loop
    
    return
    
init:
    call clear
    movlw 00000111B ; lit up RA{0-1-2}
    movwf PORTA ; move WREG to LATA
    movlw 8
    movwf init_loop_container_inc

    ; wait for 1000ms
    call init_loop_container

    return

clear:
    clrf previous_click_state0
    clrf previous_click_state1
    clrf previous_click_state2
    clrf previous_click_state3
    clrf previous_click_state4
    call handle_click2 ; sets bar_len to 4
    call set_speed_1x
    clrf paused
    clrf beat_num
    clrf LATA
    clrf PORTA
    
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

initialise_main_loop:
    movlw 4
    movwf bar_len
    
    call reset_main_loop_inc1
    
    call reset_main_loop_inc2
    
    clrf beat_num
    incf beat_num
    incf beat_num
    incf beat_num
    incf beat_num
    
    clrf buff
    clrf PREV_buff
    
    clrf lights_should_be_on
    incf lights_should_be_on
    
    return

reset_main_loop_inc2:
    movlw 240
    movwf main_loop_inc2
    movlw 239
    movwf PREV_main_loop_inc2
    return
    
reset_main_loop_inc1:
    movlw 5
    movwf main_loop_inc1
    movlw 4
    movwf PREV_main_loop_inc1
    return
    
main_loop:
    call check_clicks
    
    btfsc paused, 0
    goto main_loop 
    
    movff main_loop_inc1, WREG
    cpfsgt PREV_main_loop_inc1
    goto post_inc
    
    call reset_main_loop_inc1
    
    movff main_loop_inc2, WREG
    cpfsgt PREV_main_loop_inc2
    goto post_toggle
    
    call toggle_lights_should_be_on
    
    call reset_main_loop_inc2

    post_toggle:
	movff main_loop_inc2, PREV_main_loop_inc2
	incf main_loop_inc2
	btfsc speed, 0
	incf main_loop_inc2
	
	post_inc: 
	    movff main_loop_inc1, WREG
	    movwf PREV_main_loop_inc1

	    btfsc lights_should_be_on, 0
	    call lights_on
	    btfss lights_should_be_on, 0
	    call lights_off

	    incf main_loop_inc1
	    ; btfsc speed, 0
	    ; incf main_loop_inc1

	    goto main_loop
	
    return
    
toggle_lights_should_be_on:
    btfss lights_should_be_on, 0
    goto turn_on
    
    btfsc lights_should_be_on, 0
    goto turn_off
    
    return
    
    turn_on:
	incf lights_should_be_on
	incf beat_num
	return
	
    turn_off:
	clrf lights_should_be_on
	return
    
lights_on:
    movff beat_num, WREG
    cpfseq bar_len  ; compare beat_num with bar_len
    goto mustard_not_on_da_beat
    goto mustard_on_da_beat ; if beat num == bar_len call on da beat
    return
    
    mustard_on_da_beat:
	call on_da_beat
	return
	
    mustard_not_on_da_beat:
	call not_on_da_beat
	return
    
lights_off:
    movlw 00000000B
    movwf buff
    movff buff, WREG
    cpfseq PREV_buff
    movff buff, PORTA
    movff buff, PREV_buff
    
    ; to increase stability
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    movlw 1
    
    return
    
check_clicks:
    btfss PORTB, 0
    call is_clicked0
    
    btfss PORTB, 0
    call set_previous_click_state0_0
    btfsc PORTB, 0
    call set_previous_click_state0_1
    
    btfss PORTB, 1
    call is_clicked1
    
    btfss PORTB, 1
    call set_previous_click_state1_0
    btfsc PORTB, 1
    call set_previous_click_state1_1
    
    btfss PORTB, 2
    call is_clicked2
    
    btfss PORTB, 2
    call set_previous_click_state2_0
    btfsc PORTB, 2
    call set_previous_click_state2_1
    
    btfss PORTB, 3
    call is_clicked3
    
    btfss PORTB, 3
    call set_previous_click_state3_0
    btfsc PORTB, 3
    call set_previous_click_state3_1
    
    btfss PORTB, 4
    call is_clicked4
    
    btfss PORTB, 4
    call set_previous_click_state4_0
    btfsc PORTB, 4
    call set_previous_click_state4_1
    
    return
    
is_clicked0:
    btfsc previous_click_state0, 0
    call handle_click0
    return
is_clicked1:
    btfsc previous_click_state1, 0
    call handle_click1
    return
is_clicked2:
    btfsc previous_click_state2, 0
    call handle_click2
    return
is_clicked3:
    btfsc previous_click_state3, 0
    call handle_click3
    return
is_clicked4:
    btfsc previous_click_state4, 0
    call handle_click4
    return

set_previous_click_state0_0:
    clrf previous_click_state0
    return
set_previous_click_state0_1:
    clrf previous_click_state0
    incf previous_click_state0
    return
set_previous_click_state1_0:
    clrf previous_click_state1
    return
set_previous_click_state1_1:
    clrf previous_click_state1
    incf previous_click_state1
    return
set_previous_click_state2_0:
    clrf previous_click_state2
    return
set_previous_click_state2_1:
    clrf previous_click_state2
    incf previous_click_state2
    return
set_previous_click_state3_0:
    clrf previous_click_state3
    return
set_previous_click_state3_1:
    clrf previous_click_state3
    incf previous_click_state3
    return
set_previous_click_state4_0:
    clrf previous_click_state4
    return
set_previous_click_state4_1:
    clrf previous_click_state4
    incf previous_click_state4
    return

handle_click0:
    ; Pause/Resume metronome
    btfsc paused, 0
    call continue_metronome
    btfss paused, 0
    call pause_metronome
    return
    
handle_click1:
    ; Switch between 2x and 1x speed.
    btfss speed, 0 ; if speed != 2x
    goto set_speed_2x
    
    btfsc speed, 0 ; else
    goto set_speed_1x
    return
    
    set_speed_1x:
	clrf speed
	return
    
    set_speed_2x:
	clrf speed
	incf speed
	return
    
handle_click2:
    ; Reset bar length to 4.
    clrf bar_len
    incf bar_len
    incf bar_len
    incf bar_len
    incf bar_len
    return
handle_click3:
    ; Decrease bar length by 1.
    decf bar_len
    return
handle_click4:    
    ; Increase bar length by 1.
    incf bar_len
    return
    
continue_metronome:
    clrf paused
    ; movlw 00000000B 
    ; movwf buff
    ; movff buff, WREG
    ; cpfseq PREV_buff
    ; movff buff, PORTA
    ; movff buff, PREV_buff
    return
    
pause_metronome:
    clrf paused
    incf paused
    movlw 00000100B
    movwf buff
    movff buff, WREG
    cpfseq PREV_buff
    movff buff, PORTA
    movff buff, PREV_buff
    return
    
on_da_beat:
    movlw 00000011B
    movwf buff
    movff buff, WREG
    cpfseq PREV_buff
    movff buff, PORTA
    movff buff, PREV_buff
    movlw 0
    movwf beat_num
    return
    
not_on_da_beat:
    movlw 00000001B
    movwf buff
    movff buff, WREG
    cpfseq PREV_buff
    movff buff, PORTA
    movff buff, PREV_buff
    return
    
end resetVec
    