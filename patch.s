; Thunder Dragon 2 Enhancement Hacks
; 2018 Mike J Moffitt
;
; Features:
;  * P1 autofire on button 1; button 3 acts as a non-auto fire
;  * P2 can now start a game without P1
;
; Apply this patch over a byteswapped "6.rom".
; -----------------------------------------------------------------------------

	CPU 68000
	PADDING OFF
	ORG		$000000
	BINCLUDE	"prg.sw"

	ORG	$000000

PORT_IN0 = $100000
PORT_IN1 = $100002
PORT_DSW1 = $100008
PORT_DSW2 = $10000A


GameStatus = $1F9000
CreditCount = $1F900C

ROM_FREE = $048000

wait_for_vblank = $00AECA
push_start_fix_draw = $00CA9E
start_show_credits = $00CBC0
start_check_start = $00BF4A
game_begin = $00CA4C

; Skip checksum
	ORG	$0062EA
	nop
	nop
	nop

; 1P autofire on button 1
	ORG	$00B026
	jmp	autofire_proc

; Don't autojoin P1 if P2 starts
	ORG	$00CA72
	jmp	p1_no_autojoin

; =============================================================================

	ORG	ROM_FREE

autofire_proc:
	move.w	(PORT_IN1).l, d7
	not.w	d7
	andi.w	#$FFEF, d7
	; Mask out P1 button 1

	; If button 3 is pressed, clear the toggle bit, set button, and exit
	move.w	d7, d6
	andi.w	#$0040, d6
	beq	.no_button3
	
	clr.w	($1F000E).l
	ori.w	#$0010, d7
	bra	.finish

.no_button3:
	; Check button 1
	move.w	(PORT_IN1).l, d6
	not	d6
	andi.w	#$0010, d6
	bne	.yes_button1

	clr.w	($1F000E).l
	bra	.finish
.yes_button1:
	; Button is pressed: toggle firing bit
	eor.w	#$0001, ($1F000E).l
	beq	.finish
	ori.w	#$0010, d7
	bra	.finish

.finish
	jmp	($00B02E).l

p1_no_autojoin:
	tst.w	(CreditCount).l
	beq	.skip_p1
	btst	#3, d7
	beq	.skip_p1
	jmp	($00CA7A).l
.skip_p1:
	jmp	($00CA9A).l
