; Thunder Dragon 2 Enhancement Hacks
; 2018 Mike J Moffitt
;
; Features:
;  * Free Play with attract (Set SW1.4 on to enable)
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

; Check for if credits are nonzero, which then goes to the Press Start screen.
; Replace this with a jump to our new routine that checks if credits are
; non-zero, and then jumps to the Press Start screen.
	ORG	$00C1BA
	jmp	attract_coin_redir_optional

; Replace the "push start" screen
	ORG	$00CA2E
	jmp	start_screen_loop_augment

; Make Push Start screen show Press Start in free play
	ORG	$00CAA4
	jmp	push_start_screen_conditional_text

; Don't print credit count on press start screen if in free play
	ORG	$00CBC0
	jmp	credit_count_hide

; Right before entering the main game loop, clear the credits for free play
	ORG	$00643C
	jmp	start_credit_clear

; Make continue process not check credit count
	ORG	$00CB50
	jmp	continue_skip_cred_1
	ORG	$00CB90
	jmp	continue_skip_cred_2

; Make continue process not subtract a coin
	ORG	$00CB78
	jmp	continue_free
	ORG	$00CBB8
	jmp	continue_free

; Only show game over in attract
	ORG	$00B8BC
	jmp	attract_message

; Show "Press Start" with zero credits in HUD when in free play
	ORG	$00BAA4
	jmp	hud_p1_show_press_start
	ORG	$00BAD0
	jmp	hud_p2_show_press_start

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

hud_p1_show_press_start:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.show_mapping
	tst.w	(CreditCount).l
	bne	.show_mapping
.show_mapping:
	movea.l	#$01262E, a6
	jmp	($00BAB2).l

hud_p2_show_press_start:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.show_mapping
	tst.w	(CreditCount).l
	bne	.show_mapping
.show_mapping:
	movea.l	#$012666, a6
	jmp	($00BADE).l

attract_message:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay
	movea.l	#$0118DE, a6
	jmp	($00B8C2).l

.freeplay:
	movea.l	#$011912, a6
	jmp	($00B8C2).l

continue_skip_cred_1:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	tst.w	(CreditCount).l
	beq	.locret
.freeplay_skip_credcheck:
	jmp	($00CB5A).l
.locret:
	rts

continue_free:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	subq.w	#1, (CreditCount).l
.freeplay_skip_credcheck:
	rts

continue_skip_cred_2:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	tst.w	(CreditCount).l
	beq	.locret
.freeplay_skip_credcheck:
	jmp	($00CB9A).l
.locret:
	rts

start_credit_clear:
	bset	#7, (GameStatus).l
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	bne	.no_freeplay_credit_reset
	move.w	#0000, (CreditCount).l

.no_freeplay_credit_reset:
	jmp	($006444).l

credit_count_hide:
	; If free play is on, don't draw the credits
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.locret
	btst	#6, (GameStatus).l
	bne.s	.locret
	jmp	($00CBCA).l
.locret:
	rts

push_start_screen_conditional_text:
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	tst.w	(CreditCount).l
	bne	.no_change
	jmp	($00CAAC).l
.no_change:
.freeplay_skip_credcheck:
	jmp	($00CAB2).l

start_screen_loop_augment:
.push_start_top:
	jsr	wait_for_vblank
	jsr	push_start_fix_draw
	jsr	start_show_credits

	; If free play is enabled, do not check credit count and instead set
	; the credit count to two
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	tst.w	(CreditCount).l
	beq	.push_start_top
	bra	.post_freeplay_hack
.freeplay_skip_credcheck:
	move.w	#$0002, (CreditCount).l
.post_freeplay_hack:

	jsr	start_check_start
	andi.w	#$18, d7 ; Was a start button pressed?
	beq	.push_start_top
	jmp	game_begin

; Redirect to the start screen only if a start button is pressed
attract_coin_redir_optional:
	; If free play is enabled, start button proceeds
	move.w	(PORT_DSW1).l, d0
	andi.w	#$0008, d0
	beq	.freeplay_skip_credcheck
	; Otherwise, check credit count like normal
	tst.w	(CreditCount).l
	beq	.no_start
	jmp	($00C996).l ; go_to_start_screen

.freeplay_skip_credcheck:
	move.w	(PORT_IN0).l, d0
	not.w	d0
	andi.w	#$0018, d0
	beq	.no_start
	jmp	($00C996).l ; go_to_start_screen

.no_start:
	jmp	($00C1C4).l
