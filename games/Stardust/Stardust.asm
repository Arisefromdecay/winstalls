;*---------------------------------------------------------------------------
;  :Program.	Stardust.asm
;  :Contents.	Slave for "Stardust" from Bloodhouse
;  :Author.	Mr.Larmer of Wanted Team, Bored Seal, Wepl
;  :Id.		$Id: Stardust.asm 1.6 2006/06/25 10:35:52 wepl Exp wepl $
;  :History.	27.03.2000 - first release (Mr Larmer)
; (Bored Seal)  29.11.2000 - asteroids and menu access faults removed
;                          - highscore is saved to file now
;               02.12.2000 - disk access removed
;                          - password feature
;               10.12.2000 - tunnel 1 faults removed
;                          - tunnel 2 faults removed
;                          - tunnel 3 faults removed
;               11.12.2000 - tunnel 4 faults removed
;                          - special missions fixed
;               13.12.2000 - access fault in outro fixed
;                          - quit routine for outro added
;               19.12.2000 - intro - blitter waits added
;                          - boot - cacr+vbr access removed
;                          - skip intro option added (custom1)
;               09.01.2001 - my bug in loader removed (intro sound works now)
;                          - outro quit routine removed - useless
;			   - game - 4x blitter waits added
;		25.06.2006 Wepl
;			termination of taglist for resload_Control fixed to
;			work with WHDLoad v16.6
;			uses 'data' subdir
;		03.05.2009 Wepl
;			version checks for intro and main added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

		INCDIR	Include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"wart:st/stardust/Stardust.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd
		dc.l	$100000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	_dir-base	;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit
_expmem		dc.l	$1000		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_dir		dc.b	"data",0
_name		dc.b	"Stardust",0
_copy		dc.b	"1993 Bloodhouse",0
_info		dc.b	"installed & fixed by Mr.Larmer/Bored Seal/Wepl",10
		dc.b	"V1.5 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
_savename	dc.b	'Highs',0
_password	dc.b	'Password',0
	EVEN

Start		lea	_resload,a1
		move.l	a0,(a1)
		move.l	a0,a2

	;	move.l	#CACRF_EnableI,d0
	;	move.l	d0,d1
	;	jsr	(resload_SetCACR,a2)

		lea     (_tags,pc),a0
		jsr     (resload_Control,a2)

		lea	$78000-$136,a3

		move.l	a3,a0
		moveq	#0,d0
		move.l	#$1600,d1
		moveq	#1,d2
		jsr	resload_DiskLoad(a2)

		move.l	a3,a0
		move.l	#$1600,d0
		jsr	(resload_CRC16,a2)
		cmp.w	#$20ea,d0		;v1
		beq	.ok
		cmp.w	#$2d5,d0		;v2
		bne	_wrongver
.ok
		move.l	_c1,d0
		beq	.1
		move.b	#$60,$18e(a3)		;skip intro
.1
		lea	_pl_boot,a0
		move.l	a3,a1
		jsr	(resload_Patch,a2)

		move.l	_expmem,a6
		lea	($400,a6),a7
		add.w	#$800,a6
		move.l	a6,usp
		move	#0,sr

	;copy decruncher to fast memory
		lea	($442,a3),a0
		move.l	a6,a1
		move.w	#($67e-$442+3)/4-1,d0
.cp		move.l	(a0)+,(a1)+
		dbf	d0,.cp
		move.w	#$4ef9,($442,a3)
		move.l	a6,($444,a3)

		jsr	(resload_FlushCache,a2)

		move.l	a3,d6			; loader address
		move.l	#$80000,d7		; ext mem
		jmp	($136,a3)

_pl_boot	PL_START
		PL_S	$158,$2e		;disk access (to $186)
		PL_PS	$22a,PatchIntro
		PL_P	$29c,PatchGame
		PL_P	$686,Load
		PL_END

_wrongver	pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a2)

		;a2/a3 must be preserved!
_getcrc		move.l	$782E4,a5		(_41a)
		move.l	#$1000,d0
		move.l	a5,a0
		move.l	_resload,a6
		jmp	(resload_CRC16,a6)

PatchGame	move.l	a1,-(a7)
		bsr	_getcrc
		cmp.w	#$e3f1,d0		;v1
		bne	_wrongver
		move.l	(a7)+,a1

		move.w	#$F080,$4404(a5)	;remove access faults
		move.w	#$F084,$1778(a5)
		move.w	#$F084,$2e74(a5)

		move.w	#$f088,d0
		move.w	d0,$e816c
		move.w	d0,$e824a
		move.w	d0,$e82d2
		move.w	d0,$e835a
		move.w	d0,$e8446
		move.w	d0,$e8522
		move.w	d0,$e85aa
		move.w	d0,$e8632
		move.w	d0,$e86b4
		move.w	d0,$e86ea
		move.w	d0,$e87c6
		move.w	d0,$e88ba
		move.w	d0,$e893c
		move.w	d0,$e8972
		move.w	d0,$e8a4e
		move.w	d0,$e8b42
		move.w	d0,$e8bc4
		move.w	d0,$e8c1e
		move.w	d0,$e8cc0
		move.w	d0,$e8d08
		move.w	d0,$e8d9a
		move.w	d0,$e8dc6

		move.w	#$96,$19a0(a5)

		move.w	#$f09a,d0
		move.w	d0,$1224(a5)
		move.w	d0,$11b0(a5)
		move.w	d0,$11e8(a5)

		move.w	#$4EB9,$340(a5)
		pea	Decrunch
		move.l	(sp)+,$342(a5)

		move.w	#$4ef9,d0
		move.w	d0,$57C(a5)
		pea	Load
		move.l	(sp)+,$57E(a5)

		move.w	d0,$ED41A
		pea	LoadSaveHighs
		move.l	(sp)+,$ED41C

		move.w	d0,$6668(a5)
		move.w	d0,$ec7d0
		pea	GetAdr
		move.l	(sp),$ec7d2
		move.l	(sp)+,$666a(a5)

		move.w	#$4e75,$4016(a5)	;no cartridge check

		move.l	a5,a0			;80000
		lea	$f0000,a2
		move.w	#$4a2e,d1
		move.w	#$be02,d2
		moveq	#2,d3
		bsr	Replace

		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$6522(a5)

		move.w	#$ac40,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$be42,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$e648,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$d44c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$c250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$f854,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$60ae(a5)
		move.w	d3,$68b4(a5)
		move.w	d3,$7b48(a5)

		move.w	#$f458,d1
		moveq	#$58,d3
		bsr	Repl2cod
		move.w	d3,$60b4(a5)
		move.w	d3,$68b8(a5)
		move.w	d3,$87b4c

		move.w	#$ae60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$bc62,d1
		moveq	#$62,d3
		bsr	Repl2cod

		move.w	#$9a64,d1
		moveq	#$64,d3
		bsr	Repl2cod

		move.w	#$b266,d1
		moveq	#$66,d3
		bsr	Repl2cod
		move.w	d3,$87b44
		move.w	d3,$60a8(a5)
		move.w	d3,$68b0(a5)

		move.w	#$f458,d1
		move.w	#$9a64,d2
		move.w	#$ae60,d3
		move.w	#$bc62,d4
		move.w	#$b266,d5
		move.w	#$ac40,d6
		move.w	#$be42,d7
		bsr	Replace2

		move.w	#$2d7c,d1
		move.w	#$ea44,d2
		moveq	#$44,d3
		bsr	Replace3

		move.w	#$c250,d2
		moveq	#$50,d3
		bsr	Replace3

		move.w	#$f854,d2
		moveq	#$54,d3
		bsr	Replace3

		move.w	#$2d79,d1
		move.w	#$e648,d2
		moveq	#$48,d3
		bsr	Replace3

		move.w	#$f854,d2
		moveq	#$54,d3
		bsr	Replace3
		move.w	d3,$e908a

		move.w	#$750,d1
		move.w	#$00df,d2
		move.w	#$f080,d3
		bsr	Replace4

		move.w	#$88c,d1
		move.w	#$00df,d2
		move.w	#$f080,d3
		bsr	Replace4

		move.w	#$6006,$8ac2c		;disk access
		bsr	LoadPass

		move.l	#$4e714eb9,d0
		move.l	d0,$e8224
		pea	PatchTun1
		move.l	(sp)+,$e8228

		move.l	d0,$e84fc
		pea	PatchTun2
		move.l	(sp)+,$e8500

		move.l	d0,$e87a0
		pea	PatchTun3
		move.l	(sp)+,$e87a4

		move.l	d0,$e8a28
		pea	PatchTun4
		move.l	(sp)+,$e8a2c

		move.w	d0,$e8ca0
		pea	PatchSM
		move.l	(sp)+,$e8ca2

		move.l	d0,$90bec
		move.l	d0,$88264
		pea	BlitFix3
		move.l	(sp),$90bf0
		move.l	(sp)+,$88268

		move.l	d0,$83ccc
		move.l	d0,$842cc
		pea	BlitFix4
		move.l	(sp),$83cd0
		move.l	(sp)+,$842d0

		move.w	#$4ef9,$12e(a5)
		pea	PatchOutro
		move.l	(sp)+,$130(a5)

;		move.w	#$4ef9,$9e(a5)		;enable outro
;		move.l	#$8011a,$a0(a5)
		jmp	(a5)

PatchSM		movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$96,$8f4
		move.w	#$f050,$30b0
		move.w	#$f058,$30b6

		move.w	#$40,$3094
		move.w	#$42,$309a
		move.w	#$64,$30a0
		move.w	#$66,$30a6
		move.w	#$54,$30e2

		lea	$178e,a1			;access fault fixes
		lea	$5000,a2
		moveq	#$e,d1
		move.w	#$802,d2
		moveq	#2,d3
		bsr	Replace

		move.w	#$2d7c,d1
		move.w	#$e44,d2
		moveq	#$44,d3
		bsr	Replace3

		movem.l	(sp)+,a0-a4/d0-d5
		move.w	$e8bf2,d3
		jmp	(a5)

PatchOutro	move.w	#2,$1358		;fix access fault
		jmp	$7d4

PatchTun4	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$1dde
		lea	$db0,a1			;access fault fixes
		lea	$6460,a2

		move.w	#$4a6d,d1
		move.w	#$602,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3de8
		move.w	d3,$45da

		move.w	#$440,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$642,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$848,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$84c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$650,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$a54,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$63e4

		move.w	#$e58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$c60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$e66,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$e58,d1
		move.w	#$a64,d2
		move.w	#$c60,d3
		move.w	#$c62,d4
		move.w	#$e66,d5
		move.w	#$642,d6
		move.w	#$440,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5e36
		move.w	d3,$63de
		bra	RunIt

PatchTun3	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$181a
		lea	$d40,a1			;access fault fixes
		lea	$6470,a2
		move.w	#$4a6d,d1
		move.w	#$202,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3d48
		move.w	d3,$460c

		move.w	#$c40,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$442,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$e48,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$64c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$c54,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$641e

		move.w	#$a58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$260,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$866,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$a58,d1
		move.w	#$664,d2
		move.w	#$260,d3
		move.w	#$462,d4
		move.w	#$866,d5
		move.w	#$442,d6
		move.w	#$c40,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$244,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5e70
		move.w	d3,$6418
		bra	RunIt

PatchTun2	movem.l	a0-a4/d0-d5,-(sp)
		move.w	#$6006,$11e4		;disk access
		lea	$d30,a1			;access fault fixes
		lea	$6390,a2
		move.w	#$4a6d,d1
		move.w	#$202,d2
		moveq	#2,d3
		bsr	Replace
		moveq	#$e,d1
		bsr	Replace
		move.w	d3,$3d30
		move.w	d3,$454a

		move.w	#$840,d1
		moveq	#$40,d3
		bsr	Repl2cod

		move.w	#$e42,d1
		moveq	#$42,d3
		bsr	Repl2cod

		move.w	#$648,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$44c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$250,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$854,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$6358

		move.w	#$258,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$e60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$866,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$258,d1
		move.w	#$a64,d2
		move.w	#$e60,d3
		move.w	#$e62,d4
		move.w	#$866,d5
		move.w	#$e42,d6
		move.w	#$840,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5dac
		move.w	d3,$6352

		bra	RunIt

PatchTun1	move.w	#$6006,$5832		;disk access
		movem.l	a0-a4/d0-d5,-(sp)
		lea	$7d0,a1			;access fault fixes
		lea	$bd28,a2
		move.w	#$4a6d,d1
		move.w	#$602,d2
		moveq	#2,d3
		bsr	Replace
		move.w	d3,$35f8
		move.w	d3,$3db4

		moveq	#$e,d1
		bsr	Replace

		move.w	#$0440,d1
		moveq	#$0040,d3
		bsr	Repl2cod
		move.w	#$0c40,d1
		bsr	Repl2cod

		move.w	#$be42,d1
		moveq	#$42,d3
		bsr	Repl2cod
		move.w	#$0242,d1
		bsr	Repl2cod

		move.w	#$848,d1
		moveq	#$48,d3
		bsr	Repl2cod

		move.w	#$84c,d1
		moveq	#$4c,d3
		bsr	Repl2cod

		move.w	#$650,d1
		moveq	#$50,d3
		bsr	Repl2cod

		move.w	#$654,d1
		moveq	#$54,d3
		bsr	Repl2cod
		move.w	d3,$5cf2

		move.w	#$e58,d1
		moveq	#$58,d3
		bsr	Repl2cod

		move.w	#$c60,d1
		moveq	#$60,d3
		bsr	Repl2cod

		move.w	#$a62,d1
		moveq	#$62,d3
		bsr	Repl2cod

		move.w	#$264,d1
		moveq	#$64,d3
		bsr	Repl2cod

		move.w	#$e66,d1
		moveq	#$66,d3
		bsr	Repl2cod

		move.w	#$e58,d1
		move.w	#$264,d2
		move.w	#$c60,d3
		move.w	#$a62,d4
		move.w	#$e66,d5
		move.w	#$440,d6
		move.w	#$242,d7
		bsr	Replace2

		move.w	#$2b7c,d1
		move.w	#$444,d2
		moveq	#$44,d3
		bsr	Replace3
		move.w	d3,$5426
		move.w	d3,$5cec
RunIt		movem.l	(sp)+,a0-a4/d0-d5
		movea.w	$ed406,a4
		jmp	(a5)

GetAdr		lea	$dff000,a6
		rts

Repl2cod	move.l	a1,a0		;opravuje $xxxxd1d1 => $xxxxd3d3
Hunt0		move.w	(a0),d5
		cmp.w	d1,d5
		bne	skip0
		move.w	-2(a0),d5
		cmp.w	#$2b40,d5
		blt	skip0
		cmp.w	#$3d50,d5
		bgt	skip0
		cmp.w	#$3001,d5
		beq	skip0
		cmp.w	#$303a,d5
		beq	skip0
		cmp.w	#$3404,d5
		beq	skip0
		move.w	d3,(a0)
skip0		lea	2(a0),a0
		cmp.l	a2,a0
		ble	Hunt0
		rts

Replace		move.l	a1,a0		;opravuje $D1D1D2D2 -> $D1D1D3D3
Hunt		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne	skip
		move.w	(a0),d5
		cmp.w	d2,d5
		bne	skip
		move.w	d3,(a0)
skip		cmp.l	a2,a0
		ble	Hunt
		rts

Replace2	move.l	a1,a0		;opravuje $3bxxXXXX0558
Hunt1		cmp.w	#$3b7c,(a0)
		beq	ast
		cmp.w	#$3b7a,(a0)
		beq	ast
		cmp.w	#$3d7c,(a0)
		bne	skip1
ast		move.w	4(a0),d0
		cmp.w	d1,d0
		beq	and4
		cmp.w	d2,d0
		beq	and4
		cmp.w	d3,d0
		beq	and4
		cmp.w	d4,d0
		beq	and4
		cmp.w	d5,d0
		beq	and4
		cmp.w	d6,d0
		beq	and4
		cmp.w	d7,d0
		bne	skip1
and4		and.w	#$00FF,d0
		move.w	d0,4(a0)
skip1		lea	2(a0),a0
		cmp.l	a2,a0
		ble	Hunt1
		rts

Replace3	move.l	a1,a0		;D1D1xxxxXXXXD2D2 => D1D1xxxxXXXXD3D3
Hunt2		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne	skip2
		move.w	4(a0),d5
		cmp.w	d2,d5
		bne	skip2
		move.w	d3,4(a0)
skip2		cmp.l	a2,a0
		ble	Hunt2
		rts

Replace4	move.l	a1,a0		;$D1D1D2D2xxxx => D1D1D2D2D3D3
Hunt4		move.w	(a0)+,d5
		cmp.w	d1,d5
		bne	skip4
		move.w	(a0),d5
		cmp.w	d2,d5
		bne	skip4
		move.w	d3,2(a0)
skip4		cmp.l	a2,a0
		ble	Hunt4
		rts

Decrunch	move.l	a2,-(sp)
		lea	Size,a2
		move.l	a1,(a2)+
		move.l	6(a0),(a2)
		moveq	#12,d1
		subq.l	#4,sp
		lea	(sp),a2
.loop		move.l	4(a2),(a2)+
		dbf	d1,.loop
		move.l	(sp)+,a2
		addq.l	#6,a0
		move.l	(a0)+,d1
		move.l	(a0)+,d2
		pea	Back
		move.l	(sp)+,$30(sp)
		rts

Back		movem.l	a0-a1,-(sp)
		lea	Size,a1
		move.l	(a1)+,a0
		move.l	(a1),a1
		add.l	a0,a1

.loop		cmp.l	#$48E7E040,(a0)
		bne.b	.next
		cmp.l	#$34197000,4(a0)
		bne.b	.next
		move.w	#$4EF9,(a0)
		pea	Load
		move.l	(sp)+,2(a0)

.next		cmp.l	#$5C882218,(a0)
		bne.b	.next2
		cmp.w	#$2418,4(a0)
		bne.b	.next2
		move.w	#$4EB9,(a0)
		pea	Decrunch
		move.l	(sp)+,2(a0)

.next2		addq.l	#2,a0
		cmp.l	a0,a1
		bne.b	.loop
		movem.l	(sp)+,a0-a1
		tst.l	d0
		rts

Size		dc.l	0,0

; .w disk number (0..2)
; .3 offset (custom track is $1830, therefore +$230)
; .3 length

Load		movem.l	d0/d2-a6,-(sp)
		moveq	#0,d2
		move.w	(a1)+,d2
		addq.b	#1,d2
		move.l	(a1),d0
		lsr.l	#8,d0
		sub.l	#$230,d0
		move.l	2(a1),d1
		and.l	#$FFFFF,d1
		move.l	d1,-(sp)
		move.l	_resload,a2
		jsr	resload_DiskLoad(a2)
		move.l	(sp)+,d1
		movem.l	(sp)+,d0/d2-a6
		rts

LoadPass	movem.l	d0-a6,-(sp)
		bsr	Params
		lea	_password,a0
		move.l	a0,a5
		jsr     (resload_GetFileSize,a2)
		tst.l	d0
		beq	NoPass
		move.l	a5,a0
		lea	$ece6c,a1
		jsr	(resload_LoadFile,a2)
NoPass		movem.l	(sp)+,d0-a6
		rts

LoadSaveHighs	movem.l	d0-a6,-(sp)
		tst.w	$ED414
		bne	.save

		move.l	a0,a5
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     end
		bsr	Params
		move.l	a5,a1
		jsr	(resload_LoadFile,a2)
		bra	end

.save		moveq	#$4a,d0			;len
		lea	(a0),a1			;address
		bsr	Params
		jsr	(resload_SaveFile,a2)
		lea	_password,a0
		lea	$ece6c,a1
		moveq	#12,d0
		jsr	(resload_SaveFile,a2)
end		movem.l	(sp)+,d0-a6
		moveq	#0,d0
		rts

Params		lea	_savename,a0
		move.l	_resload,a2
		rts

PatchIntro	move.l	a1,-(a7)

		bsr	_getcrc
		cmp.w	#$ac57,d0
		bne	_wrongver

		lea	_pl_intro,a0
		move.l	a5,a1
		jsr	(resload_Patch,a6)

		clr.l	-(a7)
		move.l	a5,-(a7)
		pea	WHDLTAG_DBGADR_SET
		move.l	a7,a0
		jsr	(resload_Control,a6)
		add.w	#12,a7

		move.l	(a7)+,a1
		jmp	(a5)

_pl_intro	PL_START
		PL_PS	$2752,.p1
		PL_END

.p1		move.w	#INTF_BLIT|INTF_INTEN|INTF_SETCLR,_custom+intena
		addq.l	#2,(a7)
		bra	BlitWait

BlitFix		bsr	BlitWait
		move.l	$86ef0,$dff054
		rts

BlitFix2	move.w	#$202c,$dff058
BlitWait	btst	#6,$dff002
		bne	BlitWait
		rts

BlitFix3	bsr	BlitWait
		move.l	#$ffff0000,$44(a6)
		rts

BlitFix4	bsr	BlitWait
		move.w	d1,$42(a6)
		ori.w	#$fca,d1
		rts

_tags		dc.l	WHDLTAG_CUSTOM1_GET
_c1		dc.l    0
		dc.l	0
_resload	dc.l	0

