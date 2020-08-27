#Jai Chawla
#jdc153

.include "macros.asm"

.eqv VOL 100

.data
# maps from ASCII to MIDI note numbers, or -1 if invalid.
key_to_note_table: .byte
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 60 -1 -1 -1
	75 -1 61 63 -1 66 68 70 -1 73 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
	-1 -1 55 52 51 64 -1 54 56 72 58 -1 -1 59 57 74
	76 60 65 49 67 71 53 62 50 69 48 -1 -1 -1 -1 -1

demo_notes: .byte
	67 67 64 67 69 67 64 64 62 64 62
	67 67 64 67 69 67 64 62 62 64 62 60
	60 60 64 67 72 69 69 72 69 67
	67 67 64 67 69 67 64 62 64 65 64 62 60
	-1

demo_times: .word
	250 250 250 250 250 250 500 250 750 250 750
	250 250 250 250 250 250 500 375 125 250 250 1000
	375 125 250 250 1000 375 125 250 250 1000
	250 250 250 250 250 250 500 250 125 125 250 250 1000
	0

recorded_notes: .byte  -1:1024
recorded_times: .word 250:1024

curr_inst: .word 0

.text

# -----------------------------------------------

.globl main
main:
println_str "Welcome to the online keyboard!"
_main_loop:
	print_str "[k]eyboard, [d]emo, [r]ecord, [p]lay, [q]uit: "

	li v0, 12
	syscall
	move t0, v0
	println_str ""
	beq t0, 'q', _quit
	beq t0, 'k', _case_keyboard
	beq t0, 'd', _case_demo
	beq t0, 'r', _case_record
	beq t0, 'p', _case_play
	println_str "Not a valid command!"
	
	j _main_loop
# -----------------------------------------------
_quit:
	li v0, 10
	syscall
_case_keyboard:
	jal keyboard
	j _main_loop
_case_demo:
	jal demo
	j _main_loop
_case_record:
	jal record
	j _main_loop
_case_play:
	jal play
	j _main_loop
	
keyboard:
	push ra
	println_str "Play notes with letters and numbers, ` to change instrument, enter to stop." 
	_play_loop:
		li v0, 12
		syscall
		move a0, v0
		beq v0, '\n', _end_keyboard
		beq v0, '`', _change_instrument
		jal translate_note
		move a0, v0
		bne a0, -1, _play_note
		j _play_loop
	_end_keyboard:
		pop ra
		jr ra
	_play_note:
		jal play_note
		j _play_loop
	_change_instrument:
		println_str ""
		_change_loop:
			print_str "Enter instrument number (1..128): "
			li v0, 5
			syscall
			subi v0, v0, 1
			slti t1, v0, 0
			beq t1, 1, _change_loop #if note is less than 0
			slti t1, v0, 128
			beq t1, 0, _change_loop #if note is greater than 127
			sw v0, curr_inst
			j _play_loop
			
translate_note:
	push ra
	#a0 has ascii value of note
	slti t1, a0, 0 
	beq t1, 1, _return_invalid #if note is less than 0
	slti t1, a0, 128
	beq t1, 0, _return_invalid #if note is greater than 127
	la t1, key_to_note_table
	add t1, t1, a0
	lb t2, (t1) #puts number into t2
	move v0, t2
	_end_translate:
		pop ra
		jr ra
	_return_invalid:
		li a0, -1
		j _end_translate
		
demo:
	push ra
	
	la s0, demo_notes
	la s1, demo_times
	
	jal play_song
	
	pop ra
	jr ra
	
record:
	push ra
	println_str "Play when ready, hit enter to finish."
	push s0
	push s1
	la s0, recorded_notes
	la s1, recorded_times
	_record_loop:
		li v0, 12
		syscall
		move a0, v0
		li v0, 30
		syscall
		move a1, v0
		beq a0, '\n', _end_record
		jal translate_note
		move a0, v0
		bne a0, -1, _record_note
		j _record_loop
	_record_note:
		sb a0, (s0)
		addi s0, s0, 1
		sw a1, (s1)
		addi s1, s1, 4
		jal play_note
		j _record_loop		
	_end_record:
#		li t1, -1
#		sb t1, (s0)
		li v0, 30
		syscall
		sw v0, (s1)
		jal fix_times
		println_str "Recorded!"
		pop s0
		pop s1
		pop ra
		jr ra
	
fix_times:
	push ra
	push s0
	push s1
	la s0, recorded_notes
	la s1, recorded_times
	_fix_loop:
		lb t0, (s0)
		beq t0, -1, _end_fix_times
		lw t1, (s1)
		addi s1, s1, 4
		lw t2, (s1)
		sub t1, t2, t1
		subi s1, s1, 4
		sw t1, (s1)
		addi s0, s0, 1
		addi s1, s1, 4
		j _fix_loop
	_end_fix_times:
		pop s0
		pop s1
		pop ra
		jr ra
play:
	push ra
	push s0
	push s1
	
	println_str "Playing recorded song"
	la s0, recorded_notes
	la s1, recorded_times
	jal play_song
	println_str "Sounds good!"
		
	pop s0
	pop s1
	pop ra
	jr ra
	
play_note:
	push ra
	
	li a1, 750
	lw a2, curr_inst
	li a3, VOL 
	li v0, 31
	syscall
	pop ra
	jr ra
	
play_song:
	push ra
	push s0
	push s1
	li t2, 0 #notes counter
	_song_loop:
		move a0, s0
		add a0, a0, t2
		lb a0, (a0)
		beq a0, -1, _end_song
		jal play_note
		move a0, s1
		mul t1, t2, 4
		add a0, a0, t1
		lw a0, (a0)
		li v0, 32
		syscall
		addi t2, t2, 1
		j _song_loop
	_end_song:
		pop s0
		pop s1
		pop ra
		jr ra
