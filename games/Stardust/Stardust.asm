;*---------------------------------------------------------------------------
;  :Program.	Stardust.asm
;  :Contents.	Slave for "Stardust" from Blood House
;  :Author.	Mr.Larmer of Wanted Team
;  :History.	27.03.2000
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	OUTPUT	dh2:Stardust/Stardust.slave
	OPT	O+ OG+			;enable optimizing

Trainer		=	0	; 1 - on ; 0 -off

;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd	;ws_flags
		dc.l	$100000		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$59		;ws_keyexit = F10
_expmem		dc.l	0		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info

_name	dc.b	'Stardust',0
_copy	dc.b	'1993 Bloodhouse',0
_info	dc.b	'Installed and fixed by Mr.Larmer',10
	dc.b	'Version 1.1 (27.03.2000)',-1
	dc.b	'Greetings to Chris Vella',0
	CNOP 0,2

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		lea	Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)

		lea	$7000.w,A0
		moveq	#0,D0
		move.l	#$1600,D1
		moveq	#1,D2
		bsr.w	_LoadDisk

		move.w	#$4EF9,$29C(a0)
		pea	Patch(pc)
		move.l	(a7)+,$29E(a0)

		move.w	#$4EF9,$686(a0)
		pea	Load(pc)
		move.l	(a7)+,$688(a0)

		moveq	#0,d1			; attn flag
		move.l	a0,d6			; loader address
		move.l	#$80000-$400,d7		; ext mem

		jmp	$C4(A0)

Tags
		dc.l	WHDLTAG_Private3
_keyenabled
		dc.l	0
		dc.l	0

;--------------------------------

Patch
		move.l	$782E4,a5

	ifne	0
; many access fault to remove :(
		move.l	#$DFF080,$3E(a5)
		move.l	#$DFF080,$88(a5)
		move.l	#$DFF080,$E8CAC
		move.l	#$DFF080,$EC984
		move.l	#$DFF080,$EC99A
		add.w	#$1200,$16A(a5)		; access fault fixed
		add.w	#$1200,$170(a5)
		add.w	#$1C00,$EB5A8
		add.w	#$1C00,$EB5AE
		add.w	#$1C00,$EB5EA
		add.w	#$1C00,$EB5F0
		add.w	#$1C00,$EB5F4
		add.w	#$1C00,$EB5F8
		add.w	#$1C00,$EB5FC
		add.w	#$1C00,$EB602
	endc
		move.w	#$4EB9,$340(a5)
		pea	Decrunch(pc)
		move.l	(a7)+,$342(a5)

		move.w	#$4EF9,$57C(a5)
		pea	Load(pc)
		move.l	(a7)+,$57E(a5)

		move.w	#$4E75,$4016(a5)	; skip check some cardridges?

		move.w	#$4EF9,$ED41A
		pea	LoadSaveHighs(pc)
		move.l	(a7)+,$ED41C

		jmp	(a5)

;--------------------------------

Decrunch
		move.l	a2,-(a7)

		lea	Size(pc),a2
		move.l	a1,(a2)+
		move.l	6(a0),(a2)

		moveq	#12,d1
		subq.l	#4,a7
		lea	(a7),a2
.loop
		move.l	4(a2),(a2)+
		dbf	d1,.loop

		move.l	(a7)+,a2

		addq.l	#6,a0
		move.l	(a0)+,d1
		move.l	(a0)+,d2

		pea	Back(pc)
		move.l	(a7)+,$30(a7)

		rts
Back
		movem.l	a0-a1,-(a7)

		lea	Size(pc),a1
		move.l	(a1)+,a0
		move.l	(a1),a1
		add.l	a0,a1
.loop
		cmp.l	#$48E7E040,(a0)
		bne.b	.next

		cmp.l	#$34197000,4(a0)
		bne.b	.next

		move.w	#$4EF9,(a0)
		pea	Load(pc)
		move.l	(a7)+,2(a0)
.next
		cmp.l	#$5C882218,(a0)
		bne.b	.next2

		cmp.w	#$2418,4(a0)
		bne.b	.next2

		move.w	#$4EB9,(a0)
		pea	Decrunch(pc)
		move.l	(a7)+,2(a0)
.next2
		addq.l	#2,a0
		cmp.l	a0,a1
		bne.b	.loop

		movem.l	(a7)+,a0-a1
		tst.l	d0
		rts

Size		dc.l	0,0

;--------------------------------

Load
		movem.l	d0/d2-a6,-(a7)

		moveq	#0,d2
		move.w	(a1)+,d2
		addq.b	#1,d2
		move.l	(a1),d0
		lsr.l	#8,d0
		sub.l	#$230,d0
		move.l	2(a1),d1
		and.l	#$FFFFF,d1

		bsr.b	_LoadDisk

		movem.l	(A7)+,d0/d2-a6
		rts

;--------------------------------

LoadSaveHighs
		movem.l	d0-a6,-(a7)

		tst.w	$ED414
		bne.b	.save

		moveq	#0,d0
		moveq	#$4A,d1
		moveq	#2,d2
		bsr.b	_LoadDisk
		bra.b	.skip
.save
		move.l	_keyenabled(pc),D0
		beq.b	.skip

		moveq	#$4A,d0			;len
		moveq	#0,d1			;offset
		lea	(a0),a1			;address
		lea	_savename(pc),a0	;filename
		move.l	_resload(pc),a2
		jsr	resload_SaveFileOffset(a2)
.skip
		movem.l	(a7)+,d0-a6
		moveq	#0,d0
		rts
_savename
		dc.b	'Disk.2',0

;--------------------------------

_resload	dc.l	0		;address of resident loader

;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

_LoadDisk	movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DiskLoad(a2)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

;======================================================================
