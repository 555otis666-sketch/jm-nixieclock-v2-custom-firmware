stm8/

; Minimal IN-14 clock firmware test.
; DS3231 on PB4=SCL, PB5=SDA.
; 74HC595 measured pins: DATA=PC7, LATCH=PC5, CLOCK=PD3, OE=PD2.
; Displays HHMMSS on lamps 1..6.
; Stage 1 UI:
; SET short enters/advances time setup.
; SET long toggles night blanking ON/OFF.
; UP/DOWN change the selected HHMM digit.
; During setup lamps 5-6 are blank.

PA_ODR     EQU $5000
PA_IDR     EQU $5001
PA_DDR     EQU $5002
PA_CR1     EQU $5003
PB_ODR     EQU $5005
PB_IDR     EQU $5006
PB_DDR     EQU $5007
PB_CR1     EQU $5008
PC_ODR     EQU $500a
PC_DDR     EQU $500c
PC_CR1     EQU $500d
PD_ODR     EQU $500f
PD_DDR     EQU $5011
PD_CR1     EQU $5012
CLK_CKDIVR EQU $50c6
FLASH_DUKR EQU $5064
FLASH_IAPSR EQU $505f
EEP_MAGIC  EQU $4000
EEP_NIGHT_EN EQU $4001
EEP_START_H EQU $4002
EEP_START_M EQU $4003
EEP_END_H   EQU $4004
EEP_END_M   EQU $4005
EEP_POISON_MIN EQU $4006
EEP_RGB_MODE EQU $4007
EEP_HOUR_MODE EQU $4008

	segment byte at 0000-00ff 'ram0'
shift_temp.b    DS.B 1
bit_count.b     DS.B 1
byte_count.b    DS.B 1
i2c_temp.b      DS.B 1
i2c_read.b      DS.B 1
sec_bcd.b       DS.B 1
min_bcd.b       DS.B 1
hour_bcd.b      DS.B 1
dig1.b          DS.B 1
dig2.b          DS.B 1
dig3.b          DS.B 1
dig4.b          DS.B 1
dig5.b          DS.B 1
dig6.b          DS.B 1
f9.b            DS.B 1
f10.b           DS.B 1
f11.b           DS.B 1
f12.b           DS.B 1
f13.b           DS.B 1
f14.b           DS.B 1
f15.b           DS.B 1
f16.b           DS.B 1
mode.b          DS.B 1
edit_pos.b      DS.B 1
set_prev.b      DS.B 1
up_prev.b       DS.B 1
down_prev.b     DS.B 1
blink_count.b   DS.B 1
blink_state.b   DS.B 1
set_hold.b      DS.B 1
set_long_done.b DS.B 1
up_hold.b       DS.B 1
up_long_done.b  DS.B 1
down_hold.b     DS.B 1
down_long_done.b DS.B 1
night_en.b      DS.B 1
confirm_mode.b  DS.B 1
confirm_count.b DS.B 1
blank_active.b  DS.B 1
night_start_h.b DS.B 1
night_start_m.b DS.B 1
night_end_h.b   DS.B 1
night_end_m.b   DS.B 1
poison_min.b    DS.B 1
last_min_bcd.b  DS.B 1
last_sec_bcd.b  DS.B 1
minute_count.b  DS.B 1
second_count.b  DS.B 1
poison_digit.b  DS.B 1
poison_repeat.b DS.B 1
poison_l1_blank.b DS.B 1
rgb_mode.b      DS.B 1
hour_mode.b     DS.B 1

	segment byte at 0100-03ff 'stack'
	segment byte at 8000-807f 'vectit'
	segment byte at 8080-9fff 'rom'

	segment 'rom'

main.l
	ldw X,#$03ff
	ldw SP,X
	clr CLK_CKDIVR

	; RGB off.
	bset PC_DDR,#3
	bset PC_DDR,#4
	bset PC_DDR,#6
	bset PC_CR1,#3
	bset PC_CR1,#4
	bset PC_CR1,#6
	bres PC_ODR,#3
	bres PC_ODR,#4
	bres PC_ODR,#6

	; Buttons: UP=PA1, DOWN=PA2, SET=PA3, active low.
	bres PA_DDR,#1
	bres PA_DDR,#2
	bres PA_DDR,#3
	bset PA_CR1,#1
	bset PA_CR1,#2
	bset PA_CR1,#3
	bset PA_ODR,#1
	bset PA_ODR,#2
	bset PA_ODR,#3

	; I2C bit-bang, open-drain with external pull-ups.
	bset PB_DDR,#4
	bset PB_DDR,#5
	bres PB_CR1,#4
	bres PB_CR1,#5
	bset PB_ODR,#4
	bset PB_ODR,#5

	; 74HC595 pins.
	bset PC_DDR,#5
	bset PC_DDR,#7
	bset PC_CR1,#5
	bset PC_CR1,#7
	bset PD_DDR,#2
	bset PD_DDR,#3
	bset PD_DDR,#4      ; colon HH:MM
	bset PD_DDR,#5      ; colon MM:SS
	bset PD_DDR,#6
	bset PD_CR1,#2
	bset PD_CR1,#3
	bset PD_CR1,#4
	bset PD_CR1,#5
	bset PD_CR1,#6
	bres PC_ODR,#7
	bres PC_ODR,#5
	bres PD_ODR,#3
	bres PD_ODR,#2
	bres PD_ODR,#4
	bres PD_ODR,#5
	bres PD_ODR,#6
	clr mode
	clr edit_pos
	clr set_prev
	clr up_prev
	clr down_prev
	clr blink_count
	ld A,#1
	ld blink_state,A
	clr set_hold
	clr set_long_done
	clr up_hold
	clr up_long_done
	clr down_hold
	clr down_long_done
	clr confirm_mode
	clr confirm_count
	clr blank_active
	call load_settings

main_after_settings.l
	jra main_loop

set_default_settings.l
	clr night_en
	ld A,#$22
	ld night_start_h,A
	clr night_start_m
	ld A,#$07
	ld night_end_h,A
	clr night_end_m
	ld A,#1
	ld poison_min,A
	clr last_min_bcd
	clr last_sec_bcd
	clr minute_count
	clr second_count
	clr rgb_mode
	clr hour_mode
	ret

main_loop.l
	call scan_buttons
	ld A,confirm_mode
	jreq mode_check
	bres PD_ODR,#4
	bres PD_ODR,#5
	call handle_confirm_display
	call send_frame
	call delay_refresh
	jra main_loop
mode_check.l
	ld A,mode
	jreq normal_display
	bres PD_ODR,#4
	bres PD_ODR,#5
	call update_blink
	call build_frame
	call send_frame
	call delay_refresh
	jra main_loop

normal_display.l
	call update_rgb
	call ds3231_read_time
	call bcd_to_digits
	call update_night_blank
	ld A,blank_active
	jreq normal_not_blank
	bres PD_ODR,#4
	bres PD_ODR,#5
	call blank_display_frame
	call send_frame
	call delay_refresh
	jra main_loop
normal_not_blank.l
	bset PD_ODR,#4
	bset PD_ODR,#5
	call maybe_poison
	call ds3231_read_time
	call bcd_to_digits
	call build_frame
	call send_frame
	call delay_refresh
	jra main_loop

update_night_blank.l
	clr blank_active
	ld A,night_en
	jreq night_blank_done
	ld A,hour_bcd
	and A,#$3f
	ld hour_bcd,A
	; If start <= end: blank when current >= start AND current < end.
	; If start > end: blank when current >= start OR current < end.
	ld A,night_start_h
	cp A,night_end_h
	jrult night_same_day
	jrugt night_overnight
	ld A,night_start_m
	cp A,night_end_m
	jrule night_same_day
night_overnight.l
	call current_ge_start
	cp A,#1
	jreq night_blank_on
	call current_lt_end
	cp A,#1
	jreq night_blank_on
	jra night_blank_done
night_same_day.l
	call current_ge_start
	cp A,#1
	jrne night_blank_done
	call current_lt_end
	cp A,#1
	jreq night_blank_on
night_blank_done.l
	ret
night_blank_on.l
	ld A,#1
	ld blank_active,A
	ret

current_ge_start.l
	ld A,hour_bcd
	cp A,night_start_h
	jrugt cgs_yes
	jrult cgs_no
	ld A,min_bcd
	cp A,night_start_m
	jruge cgs_yes
cgs_no.l
	clr A
	ret
cgs_yes.l
	ld A,#1
	ret

current_lt_end.l
	ld A,hour_bcd
	cp A,night_end_h
	jrult cle_yes
	jrugt cle_no
	ld A,min_bcd
	cp A,night_end_m
	jrult cle_yes
cle_no.l
	clr A
	ret
cle_yes.l
	ld A,#1
	ret

maybe_poison.l
	ld A,sec_bcd
	cp A,last_sec_bcd
	jreq poison_done
	ld last_sec_bcd,A
	inc second_count
	ld A,second_count
	cp A,#60
	jrult poison_done
	clr second_count
	inc minute_count
	ld A,minute_count
	cp A,poison_min
	jrult poison_done
	clr minute_count
	clr second_count
	call run_poison
	call ds3231_read_time
	ld A,sec_bcd
	ld last_sec_bcd,A
	clr minute_count
	clr second_count
poison_done.l
	ret

update_rgb.l
	bres PC_ODR,#3
	bres PC_ODR,#4
	bres PC_ODR,#6
	ld A,rgb_mode
	cp A,#0
	jreq rgb_auto
	cp A,#1
	jreq rgb_done
	cp A,#2
	jreq rgb_red
	cp A,#3
	jreq rgb_purple
	cp A,#4
	jreq rgb_yellow
	cp A,#5
	jreq rgb_pink
	cp A,#6
	jreq rgb_green
	jra rgb_blue
rgb_auto.l
	ld A,hour_bcd
	and A,#$03
	cp A,#0
	jreq rgb_red
	cp A,#1
	jreq rgb_green
	cp A,#2
	jreq rgb_blue
	jra rgb_purple
rgb_red.l
	bset PC_ODR,#3
	jra rgb_done
rgb_green.l
	bset PC_ODR,#6
	jra rgb_done
rgb_blue.l
	bset PC_ODR,#4
	jra rgb_done
rgb_purple.l
	bset PC_ODR,#3
	bset PC_ODR,#4
	jra rgb_done
rgb_yellow.l
	bset PC_ODR,#3
	bset PC_ODR,#6
	jra rgb_done
rgb_pink.l
	bset PC_ODR,#3
	bset PC_ODR,#4
rgb_done.l
	ret

run_poison.l
	clr poison_l1_blank
	ld A,dig1
	cp A,#$ff
	jrne poison_l1_visible
	ld A,#1
	ld poison_l1_blank,A
poison_l1_visible.l
	clr poison_digit
poison_digit_loop.l
	ld A,poison_digit
	ld dig1,A
	ld dig2,A
	ld dig3,A
	ld dig4,A
	ld dig5,A
	ld dig6,A
	ld A,poison_l1_blank
	jreq poison_l1_keep_visible
	ld A,#$ff
	ld dig1,A
poison_l1_keep_visible.l
	call build_frame
	call send_frame
	ld A,#8
	ld poison_repeat,A
poison_delay_loop.l
	call delay_refresh
	dec poison_repeat
	jrne poison_delay_loop
	inc poison_digit
	ld A,poison_digit
	cp A,#10
	jrne poison_digit_loop
	ret

update_blink.l
	inc blink_count
	ld A,blink_count
	cp A,#20
	jrne blink_done
	clr blink_count
	ld A,blink_state
	xor A,#1
	ld blink_state,A
blink_done.l
	ret

scan_buttons.l
	ld A,PA_IDR
	and A,#$08
	jrne set_released
	inc set_hold
	ld A,set_hold
	cp A,#60
	jrne set_pressed_edge
	ld A,set_long_done
	jrne set_pressed_edge
	ld A,#1
	ld set_long_done,A
	call handle_set_long
set_pressed_edge.l
	ld A,set_prev
	jrne check_up
	ld A,#1
	ld set_prev,A
	jra check_up
set_released.l
	ld A,set_prev
	jreq set_release_cleanup
	ld A,set_long_done
	jrne set_release_cleanup
	call handle_set
set_release_cleanup.l
	clr set_prev
	clr set_hold
	clr set_long_done

check_up.l
	ld A,PA_IDR
	and A,#$02
	jrne up_released
	inc up_hold
	ld A,up_hold
	cp A,#60
	jrne up_pressed_edge
	ld A,up_long_done
	jrne up_pressed_edge
	ld A,#1
	ld up_long_done,A
	call handle_up_long
up_pressed_edge.l
	ld A,up_prev
	jrne check_down
	ld A,#1
	ld up_prev,A
	jra check_down
up_released.l
	ld A,up_prev
	jreq up_release_cleanup
	ld A,up_long_done
	jrne up_release_cleanup
	call handle_up
up_release_cleanup.l
	clr up_prev
	clr up_hold
	clr up_long_done

check_down.l
	ld A,PA_IDR
	and A,#$04
	jrne down_released
	inc down_hold
	ld A,down_hold
	cp A,#60
	jrne down_pressed_edge
	ld A,down_long_done
	jrne down_pressed_edge
	ld A,#1
	ld down_long_done,A
	call handle_down_long
down_pressed_edge.l
	ld A,down_prev
	jrne buttons_done
	ld A,#1
	ld down_prev,A
	jra buttons_done
down_released.l
	ld A,down_prev
	jreq down_release_cleanup
	ld A,down_long_done
	jrne down_release_cleanup
	call handle_down
down_release_cleanup.l
	clr down_prev
	clr down_hold
	clr down_long_done
buttons_done.l
	ret

handle_set.l
	ld A,mode
	cp A,#1
	jreq advance_edit
	cp A,#2
	jreq advance_edit
	cp A,#3
	jreq advance_edit
	cp A,#4
	jreq save_poison_stage
	jra enter_time_setup
advance_edit.l
	inc edit_pos
	ld A,edit_pos
	cp A,#4
	jrne set_done
	ld A,mode
	cp A,#1
	jrne save_night_stage
	call save_time_setup
	clr mode
	jra set_done
save_night_stage.l
	cp A,#2
	jrne save_night_end_stage
	call save_night_start
	call load_night_end_digits
	clr edit_pos
	ld A,#3
	ld mode,A
	jra set_done
save_night_end_stage.l
	call save_night_end
	call save_settings
	clr mode
	jra set_done
save_poison_stage.l
	call save_settings
	clr mode
	jra set_done
enter_time_setup.l
	call ds3231_read_time
	call bcd_hm_to_digits
	call clamp_hour_digits
	ld A,#$ff
	ld dig5,A
	ld dig6,A
	clr edit_pos
	ld A,#1
	ld mode,A
set_done.l
	ret

handle_set_long.l
	clr mode
	ld A,night_en
	xor A,#1
	ld night_en,A
	jreq night_off_confirm
	ld A,#1          ; ON: blank display briefly.
	ld confirm_mode,A
	jra confirm_init
night_off_confirm.l
	ld A,#2          ; OFF: show 000000 briefly.
	ld confirm_mode,A
confirm_init.l
	clr confirm_count
	call save_settings
	ret

handle_down_long.l
	ld A,mode
	jrne down_long_done_ret
	call load_night_start_digits
	clr edit_pos
	ld A,#2
	ld mode,A
down_long_done_ret.l
	ret

handle_up_long.l
	ld A,mode
	jrne up_long_done_ret
	ld A,poison_min
	ld dig1,A
	ld A,#$ff
	ld dig2,A
	ld dig3,A
	ld dig4,A
	ld dig5,A
	ld dig6,A
	clr edit_pos
	ld A,#4
	ld mode,A
up_long_done_ret.l
	ret

handle_confirm_display.l
	inc confirm_count
	ld A,confirm_count
	cp A,#80
	jrne confirm_still
	clr confirm_mode
confirm_still.l
	clr f9
	clr f10
	clr f11
	clr f12
	clr f13
	clr f14
	clr f15
	clr f16
	ld A,confirm_mode
	cp A,#2
	jrne confirm_blank
	clr A
	call set_l1
	clr A
	call set_l2
	clr A
	call set_l3
	clr A
	call set_l4
	clr A
	call set_l5
	clr A
	call set_l6
confirm_blank.l
	ret

blank_display_frame.l
	clr f9
	clr f10
	clr f11
	clr f12
	clr f13
	clr f14
	clr f15
	clr f16
	ret

handle_up.l
	ld A,mode
	jrne up_mode_active
	ld A,hour_mode
	xor A,#1
	ld hour_mode,A
	call save_settings
	jra up_done
up_mode_active.l
	cp A,#4
	jrne up_edit_digit
	inc poison_min
	ld A,poison_min
	cp A,#10
	jrult up_load_poison
	ld A,#1
	ld poison_min,A
up_load_poison.l
	ld A,poison_min
	ld dig1,A
	jra up_done
up_edit_digit.l
	call inc_selected_digit
up_done.l
	ret

handle_down.l
	ld A,mode
	jrne down_mode_active
	inc rgb_mode
	ld A,rgb_mode
	cp A,#8
	jrult down_rgb_ok
	clr rgb_mode
	ld A,#3
	ld poison_repeat,A
down_rgb_auto_loop.l
	bset PC_ODR,#3
	bres PC_ODR,#4
	bres PC_ODR,#6
	call delay_refresh
	call delay_refresh
	call delay_refresh
	bres PC_ODR,#3
	bres PC_ODR,#4
	bset PC_ODR,#6
	call delay_refresh
	call delay_refresh
	call delay_refresh
	bres PC_ODR,#3
	bset PC_ODR,#4
	bres PC_ODR,#6
	call delay_refresh
	call delay_refresh
	call delay_refresh
	bset PC_ODR,#3
	bset PC_ODR,#4
	bres PC_ODR,#6
	call delay_refresh
	call delay_refresh
	call delay_refresh
	dec poison_repeat
	jrne down_rgb_auto_loop
down_rgb_ok.l
	call save_settings
	jra down_done
down_mode_active.l
	cp A,#4
	jrne down_edit_digit
	ld A,poison_min
	cp A,#1
	jrne down_poison_dec
	ld A,#9
	ld poison_min,A
	jra down_load_poison
down_poison_dec.l
	dec poison_min
down_load_poison.l
	ld A,poison_min
	ld dig1,A
	jra down_done
down_edit_digit.l
	call dec_selected_digit
down_done.l
	ret

inc_selected_digit.l
	ld A,edit_pos
	cp A,#0
	jrne inc_pos1
	inc dig1
	ld A,dig1
	cp A,#3
	jrne inc_done
	clr dig1
	call clamp_hour_digits
	jra inc_done
inc_pos1.l
	cp A,#1
	jrne inc_pos2
	inc dig2
	ld A,dig1
	cp A,#2
	jrne inc_hour_ones_09
	ld A,dig2
	cp A,#4
	jrult inc_done
	clr dig2
	jra inc_done
inc_hour_ones_09.l
	ld A,dig2
	cp A,#10
	jrult inc_done
	clr dig2
	jra inc_done
inc_pos2.l
	cp A,#2
	jrne inc_pos3
	inc dig3
	ld A,dig3
	cp A,#6
	jrne inc_done
	clr dig3
	jra inc_done
inc_pos3.l
	inc dig4
	ld A,dig4
	cp A,#10
	jrne inc_done
	clr dig4
inc_done.l
	ret

dec_selected_digit.l
	ld A,edit_pos
	cp A,#0
	jrne dec_pos1
	ld A,dig1
	jrne dec_d1
	ld A,#2
	ld dig1,A
	call clamp_hour_digits
	jra dec_done
dec_d1.l
	dec dig1
	call clamp_hour_digits
	jra dec_done
dec_pos1.l
	cp A,#1
	jrne dec_pos2
	ld A,dig2
	jrne dec_d2
	ld A,dig1
	cp A,#2
	jrne dec_d2_9
	ld A,#3
	ld dig2,A
	jra dec_done
dec_d2_9.l
	ld A,#9
	ld dig2,A
	jra dec_done
dec_d2.l
	dec dig2
	jra dec_done
dec_pos2.l
	cp A,#2
	jrne dec_pos3
	ld A,dig3
	jrne dec_d3
	ld A,#5
	ld dig3,A
	jra dec_done
dec_d3.l
	dec dig3
	jra dec_done
dec_pos3.l
	ld A,dig4
	jrne dec_d4
	ld A,#9
	ld dig4,A
	jra dec_done
dec_d4.l
	dec dig4
dec_done.l
	ret

clamp_hour_digits.l
	ld A,dig1
	cp A,#2
	jrne clamp_done
	ld A,dig2
	cp A,#4
	jrult clamp_done
	ld A,#3
	ld dig2,A
clamp_done.l
	ret

save_time_setup.l
	ld A,dig1
	sll A
	sll A
	sll A
	sll A
	add A,dig2
	ld hour_bcd,A
	ld A,dig3
	sll A
	sll A
	sll A
	sll A
	add A,dig4
	ld min_bcd,A
	clr sec_bcd
	call ds3231_write_time
	ret

load_night_start_digits.l
	ld A,night_start_h
	ld hour_bcd,A
	ld A,night_start_m
	ld min_bcd,A
	call bcd_hm_to_digits
	ld A,#$ff
	ld dig5,A
	ld dig6,A
	ret

load_night_end_digits.l
	ld A,night_end_h
	ld hour_bcd,A
	ld A,night_end_m
	ld min_bcd,A
	call bcd_hm_to_digits
	ld A,#$ff
	ld dig5,A
	ld dig6,A
	ret

save_night_start.l
	call digits_to_bcd_hm
	ld A,hour_bcd
	ld night_start_h,A
	ld A,min_bcd
	ld night_start_m,A
	ret

save_night_end.l
	call digits_to_bcd_hm
	ld A,hour_bcd
	ld night_end_h,A
	ld A,min_bcd
	ld night_end_m,A
	ret

digits_to_bcd_hm.l
	ld A,dig1
	sll A
	sll A
	sll A
	sll A
	add A,dig2
	ld hour_bcd,A
	ld A,dig3
	sll A
	sll A
	sll A
	sll A
	add A,dig4
	ld min_bcd,A
	ret

load_settings.l
	ld A,EEP_MAGIC
	cp A,#$5b
	jreq load_settings_ok
	clr night_en
	ld A,#$22
	ld night_start_h,A
	clr night_start_m
	ld A,#$07
	ld night_end_h,A
	clr night_end_m
	ld A,#1
	ld poison_min,A
	clr rgb_mode
	clr hour_mode
	call save_settings
	ret
load_settings_ok.l
	ld A,EEP_NIGHT_EN
	and A,#1
	ld night_en,A
	ld A,EEP_START_H
	ld night_start_h,A
	ld A,EEP_START_M
	ld night_start_m,A
	ld A,EEP_END_H
	ld night_end_h,A
	ld A,EEP_END_M
	ld night_end_m,A
	ld A,EEP_POISON_MIN
	cp A,#1
	jrult load_poison_default
	cp A,#10
	jrult load_poison_ok
load_poison_default.l
	ld A,#1
load_poison_ok.l
	ld poison_min,A
	ld A,EEP_RGB_MODE
	cp A,#8
	jrult load_rgb_ok
	clr A
load_rgb_ok.l
	ld rgb_mode,A
	ld A,EEP_HOUR_MODE
	and A,#1
	ld hour_mode,A
	ret

save_settings.l
	call eeprom_unlock
	ld A,#$5b
	ld EEP_MAGIC,A
	ld A,night_en
	ld EEP_NIGHT_EN,A
	ld A,night_start_h
	ld EEP_START_H,A
	ld A,night_start_m
	ld EEP_START_M,A
	ld A,night_end_h
	ld EEP_END_H,A
	ld A,night_end_m
	ld EEP_END_M,A
	ld A,poison_min
	ld EEP_POISON_MIN,A
	ld A,rgb_mode
	ld EEP_RGB_MODE,A
	ld A,hour_mode
	ld EEP_HOUR_MODE,A
	ret

eeprom_unlock.l
	ld A,#$ae
	ld FLASH_DUKR,A
	ld A,#$56
	ld FLASH_DUKR,A
	ret

ds3231_read_time.l
	call i2c_start
	ld A,#$d0
	call i2c_write
	clr A
	call i2c_write
	call i2c_start
	ld A,#$d1
	call i2c_write
	call i2c_read_ack
	ld sec_bcd,A
	call i2c_read_ack
	ld min_bcd,A
	call i2c_read_nak
	ld hour_bcd,A
	call i2c_stop
	ret

ds3231_write_time.l
	call i2c_start
	ld A,#$d0
	call i2c_write
	clr A
	call i2c_write
	ld A,sec_bcd
	call i2c_write
	ld A,min_bcd
	call i2c_write
	ld A,hour_bcd
	call i2c_write
	call i2c_stop
	ret

bcd_to_digits.l
	ld A,hour_bcd
	and A,#$3f
	ld hour_bcd,A
	ld A,hour_mode
	jreq bcd_digits_24h
	call convert_hour_12
bcd_digits_24h.l
	ld A,hour_bcd
	and A,#$0f
	ld dig2,A
	ld A,hour_bcd
	and A,#$30
	call nibble_high
	ld dig1,A
	ld A,dig1
	jrne bcd_no_leading_blank
	ld A,#$ff
	ld dig1,A
bcd_no_leading_blank.l

	ld A,min_bcd
	and A,#$0f
	ld dig4,A
	ld A,min_bcd
	and A,#$70
	call nibble_high
	ld dig3,A

	ld A,sec_bcd
	and A,#$0f
	ld dig6,A
	ld A,sec_bcd
	and A,#$70
	call nibble_high
	ld dig5,A
	ret

convert_hour_12.l
	ld A,hour_bcd
	jrne ch12_not_midnight
	ld A,#$12
	ld hour_bcd,A
	ret
ch12_not_midnight.l
	cp A,#$13
	jrult ch12_done
	cp A,#$13
	jrne ch12_14
	ld A,#$01
	ld hour_bcd,A
	ret
ch12_14.l
	cp A,#$14
	jrne ch12_15
	ld A,#$02
	ld hour_bcd,A
	ret
ch12_15.l
	cp A,#$15
	jrne ch12_16
	ld A,#$03
	ld hour_bcd,A
	ret
ch12_16.l
	cp A,#$16
	jrne ch12_17
	ld A,#$04
	ld hour_bcd,A
	ret
ch12_17.l
	cp A,#$17
	jrne ch12_18
	ld A,#$05
	ld hour_bcd,A
	ret
ch12_18.l
	cp A,#$18
	jrne ch12_19
	ld A,#$06
	ld hour_bcd,A
	ret
ch12_19.l
	cp A,#$19
	jrne ch12_20
	ld A,#$07
	ld hour_bcd,A
	ret
ch12_20.l
	cp A,#$20
	jrne ch12_21
	ld A,#$08
	ld hour_bcd,A
	ret
ch12_21.l
	cp A,#$21
	jrne ch12_22
	ld A,#$09
	ld hour_bcd,A
	ret
ch12_22.l
	cp A,#$22
	jrne ch12_23
	ld A,#$10
	ld hour_bcd,A
	ret
ch12_23.l
	cp A,#$23
	jrne ch12_done
	ld A,#$11
	ld hour_bcd,A
ch12_done.l
	ret

bcd_hm_to_digits.l
	ld A,hour_bcd
	and A,#$3f
	ld hour_bcd,A
	and A,#$0f
	ld dig2,A
	ld A,hour_bcd
	and A,#$30
	call nibble_high
	ld dig1,A

	ld A,min_bcd
	and A,#$0f
	ld dig4,A
	ld A,min_bcd
	and A,#$70
	call nibble_high
	ld dig3,A
	ret

nibble_high.l
	srl A
	srl A
	srl A
	srl A
	ret

build_frame.l
	clr f9
	clr f10
	clr f11
	clr f12
	clr f13
	clr f14
	clr f15
	clr f16
	ld A,dig1
	cp A,#$ff
	jreq skip_l1
	call should_blank_l1
	cp A,#1
	jreq skip_l1
	ld A,dig1
	call set_l1
skip_l1.l
	ld A,dig2
	cp A,#$ff
	jreq skip_l2
	call should_blank_l2
	cp A,#1
	jreq skip_l2
	ld A,dig2
	call set_l2
skip_l2.l
	ld A,dig3
	cp A,#$ff
	jreq skip_l3
	call should_blank_l3
	cp A,#1
	jreq skip_l3
	ld A,dig3
	call set_l3
skip_l3.l
	ld A,dig4
	cp A,#$ff
	jreq skip_l4
	call should_blank_l4
	cp A,#1
	jreq skip_l4
	ld A,dig4
	call set_l4
skip_l4.l
	ld A,dig5
	cp A,#$ff
	jreq skip_l5
	call set_l5
skip_l5.l
	ld A,dig6
	cp A,#$ff
	jreq skip_l6
	call set_l6
skip_l6.l
	ret

should_blank_l1.l
	ld A,mode
	jreq no_blank_l1
	ld A,blink_state
	jrne no_blank_l1
	ld A,edit_pos
	cp A,#0
	jrne no_blank_l1
	ld A,#1
	ret
no_blank_l1.l
	clr A
	ret

should_blank_l2.l
	ld A,mode
	jreq no_blank_l2
	ld A,blink_state
	jrne no_blank_l2
	ld A,edit_pos
	cp A,#1
	jrne no_blank_l2
	ld A,#1
	ret
no_blank_l2.l
	clr A
	ret

should_blank_l3.l
	ld A,mode
	jreq no_blank_l3
	ld A,blink_state
	jrne no_blank_l3
	ld A,edit_pos
	cp A,#2
	jrne no_blank_l3
	ld A,#1
	ret
no_blank_l3.l
	clr A
	ret

should_blank_l4.l
	ld A,mode
	jreq no_blank_l4
	ld A,blink_state
	jrne no_blank_l4
	ld A,edit_pos
	cp A,#3
	jrne no_blank_l4
	ld A,#1
	ret
no_blank_l4.l
	clr A
	ret

set_l1.l
	cp A,#0
	jrne l1_1
	bset f10,#2
	ret
l1_1.l
	cp A,#1
	jrne l1_2
	bset f10,#3
	ret
l1_2.l
	cp A,#2
	jrne l1_3
	bset f10,#4
	ret
l1_3.l
	cp A,#3
	jrne l1_4
	bset f10,#5
	ret
l1_4.l
	cp A,#4
	jrne l1_5
	bset f10,#6
	ret
l1_5.l
	cp A,#5
	jrne l1_6
	bset f10,#7
	ret
l1_6.l
	cp A,#6
	jrne l1_7
	bset f9,#0
	ret
l1_7.l
	cp A,#7
	jrne l1_8
	bset f9,#1
	ret
l1_8.l
	cp A,#8
	jrne l1_9
	bset f9,#2
	ret
l1_9.l
	bset f9,#3
	ret

set_l2.l
	cp A,#0
	jrne l2_1
	bset f11,#0
	ret
l2_1.l
	cp A,#1
	jrne l2_2
	bset f11,#1
	ret
l2_2.l
	cp A,#2
	jrne l2_3
	bset f11,#2
	ret
l2_3.l
	cp A,#3
	jrne l2_4
	bset f11,#3
	ret
l2_4.l
	cp A,#4
	jrne l2_5
	bset f11,#4
	ret
l2_5.l
	cp A,#5
	jrne l2_6
	bset f11,#5
	ret
l2_6.l
	cp A,#6
	jrne l2_7
	bset f11,#6
	ret
l2_7.l
	cp A,#7
	jrne l2_8
	bset f11,#7
	ret
l2_8.l
	cp A,#8
	jrne l2_9
	bset f10,#0
	ret
l2_9.l
	bset f10,#1
	ret

set_l3.l
	cp A,#0
	jrne l3_1
	bset f13,#6
	ret
l3_1.l
	cp A,#1
	jrne l3_2
	bset f13,#7
	ret
l3_2.l
	cp A,#2
	jrne l3_3
	bset f12,#0
	ret
l3_3.l
	cp A,#3
	jrne l3_4
	bset f12,#1
	ret
l3_4.l
	cp A,#4
	jrne l3_5
	bset f12,#2
	ret
l3_5.l
	cp A,#5
	jrne l3_6
	bset f12,#3
	ret
l3_6.l
	cp A,#6
	jrne l3_7
	bset f12,#4
	ret
l3_7.l
	cp A,#7
	jrne l3_8
	bset f12,#5
	ret
l3_8.l
	cp A,#8
	jrne l3_9
	bset f12,#6
	ret
l3_9.l
	bset f12,#7
	ret

set_l4.l
	cp A,#0
	jrne l4_1
	bset f14,#4
	ret
l4_1.l
	cp A,#1
	jrne l4_2
	bset f14,#5
	ret
l4_2.l
	cp A,#2
	jrne l4_3
	bset f14,#6
	ret
l4_3.l
	cp A,#3
	jrne l4_4
	bset f14,#7
	ret
l4_4.l
	cp A,#4
	jrne l4_5
	bset f13,#0
	ret
l4_5.l
	cp A,#5
	jrne l4_6
	bset f13,#1
	ret
l4_6.l
	cp A,#6
	jrne l4_7
	bset f13,#2
	ret
l4_7.l
	cp A,#7
	jrne l4_8
	bset f13,#3
	ret
l4_8.l
	cp A,#8
	jrne l4_9
	bset f13,#4
	ret
l4_9.l
	bset f13,#5
	ret

set_l5.l
	cp A,#0
	jrne l5_1
	bset f15,#2
	ret
l5_1.l
	cp A,#1
	jrne l5_2
	bset f15,#3
	ret
l5_2.l
	cp A,#2
	jrne l5_3
	bset f15,#4
	ret
l5_3.l
	cp A,#3
	jrne l5_4
	bset f15,#5
	ret
l5_4.l
	cp A,#4
	jrne l5_5
	bset f15,#6
	ret
l5_5.l
	cp A,#5
	jrne l5_6
	bset f15,#7
	ret
l5_6.l
	cp A,#6
	jrne l5_7
	bset f14,#0
	ret
l5_7.l
	cp A,#7
	jrne l5_8
	bset f14,#1
	ret
l5_8.l
	cp A,#8
	jrne l5_9
	bset f14,#2
	ret
l5_9.l
	bset f14,#3
	ret

set_l6.l
	cp A,#0
	jrne l6_1
	bset f16,#0
	ret
l6_1.l
	cp A,#1
	jrne l6_2
	bset f16,#1
	ret
l6_2.l
	cp A,#2
	jrne l6_3
	bset f16,#2
	ret
l6_3.l
	cp A,#3
	jrne l6_4
	bset f16,#3
	ret
l6_4.l
	cp A,#4
	jrne l6_5
	bset f16,#4
	ret
l6_5.l
	cp A,#5
	jrne l6_6
	bset f16,#5
	ret
l6_6.l
	cp A,#6
	jrne l6_7
	bset f16,#6
	ret
l6_7.l
	cp A,#7
	jrne l6_8
	bset f16,#7
	ret
l6_8.l
	cp A,#8
	jrne l6_9
	bset f15,#0
	ret
l6_9.l
	bset f15,#1
	ret

send_frame.l
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	clr A
	call shift_byte
	ld A,f9
	call shift_byte
	ld A,f10
	call shift_byte
	ld A,f11
	call shift_byte
	ld A,f12
	call shift_byte
	ld A,f13
	call shift_byte
	ld A,f14
	call shift_byte
	ld A,f15
	call shift_byte
	ld A,f16
	call shift_byte
	call latch
	ret

latch.l
	bset PC_ODR,#5
	nop
	nop
	bres PC_ODR,#5
	ret

shift_byte.l
	ld shift_temp,A
	ld A,#8
	ld bit_count,A
shift_loop.l
	bres PC_ODR,#7
	ld A,shift_temp
	and A,#$80
	jreq data_done
	bset PC_ODR,#7
data_done.l
	bset PD_ODR,#3
	nop
	bres PD_ODR,#3
	ld A,shift_temp
	sll A
	ld shift_temp,A
	dec bit_count
	jrne shift_loop
	ret

i2c_start.l
	bset PB_ODR,#5
	bset PB_ODR,#4
	call i2c_delay
	bres PB_ODR,#5
	call i2c_delay
	bres PB_ODR,#4
	call i2c_delay
	ret

i2c_stop.l
	bres PB_ODR,#5
	bset PB_ODR,#4
	call i2c_delay
	bset PB_ODR,#5
	call i2c_delay
	ret

i2c_write.l
	ld i2c_temp,A
	ld A,#8
	ld bit_count,A
i2c_write_loop.l
	bres PB_ODR,#5
	ld A,i2c_temp
	and A,#$80
	jreq i2c_write_zero
	bset PB_ODR,#5
i2c_write_zero.l
	call i2c_delay
	bset PB_ODR,#4
	call i2c_delay
	bres PB_ODR,#4
	ld A,i2c_temp
	sll A
	ld i2c_temp,A
	dec bit_count
	jrne i2c_write_loop
	; ACK clock, ignored.
	bset PB_ODR,#5
	call i2c_delay
	bset PB_ODR,#4
	call i2c_delay
	bres PB_ODR,#4
	call i2c_delay
	ret

i2c_read_ack.l
	call i2c_read_byte
	push A
	bres PB_ODR,#5
	call i2c_ack_clock
	pop A
	ret

i2c_read_nak.l
	call i2c_read_byte
	push A
	bset PB_ODR,#5
	call i2c_ack_clock
	pop A
	ret

i2c_read_byte.l
	clr i2c_read
	bset PB_ODR,#5
	ld A,#8
	ld bit_count,A
i2c_read_loop.l
	ld A,i2c_read
	sll A
	ld i2c_read,A
	bset PB_ODR,#4
	call i2c_delay
	ld A,PB_IDR
	and A,#$20
	jreq i2c_read_zero
	bset i2c_read,#0
i2c_read_zero.l
	bres PB_ODR,#4
	call i2c_delay
	dec bit_count
	jrne i2c_read_loop
	ld A,i2c_read
	ret

i2c_ack_clock.l
	call i2c_delay
	bset PB_ODR,#4
	call i2c_delay
	bres PB_ODR,#4
	bset PB_ODR,#5
	call i2c_delay
	ret

i2c_delay.l
	ld A,#$30
i2c_d1.l
	dec A
	jrne i2c_d1
	ret

delay_refresh.l
	ldw X,#$07ff
dr1.l
	ld A,#$40
dr2.l
	dec A
	jrne dr2
	decw X
	jrne dr1
	ret

NonHandledInterrupt.l
	iret

	segment 'vectit'
	dc.l {$82000000+main}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}
	dc.l {$82000000+NonHandledInterrupt}

	end
