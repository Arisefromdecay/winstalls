;*---------------------------------------------------------------------------
;  :Modul.	emeraldmines.asm
;  :Contents.	Slave for "Emerald Mines"
;  :Author.	Harry, Wepl
;  :Original.
;  :History.	25.11.2012 V1.0
;  :Requires.	kick31.s kickfs.s segtracker.s
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	BASM 2.16, ASM-One 1.44, Asm-Pro 1.17, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;============================================================================

CHIPMEMSIZE	= $19d000	;size of chip memory
FASTMEMSIZE	= $1b000	;size of fast memory
NUMDRIVES	= 1		;amount of floppy drives to be configured
WPDRIVES	= %1111		;write protection of floppy drives

;BLACKSCREEN			;set all initial colors to black
;BOOTBLOCK			;enable _bootblock routine
;BOOTDOS			;enable _bootdos routine
;BOOTEARLY			;enable _bootearly routine
CBDOSLOADSEG			;enable _cb_dosLoadSeg routine
;CBDOSREAD			;enable _cb_dosRead routine
;CBKEYBOARD			;enable _cb_keyboard routine
;CACHE				;enable inst/data cache for fast memory with MMU
CACHECHIP			;enable inst cache for chip/fast memory
;CACHECHIPDATA			;enable inst/data cache for chip/fast memory
;DEBUG				;add more internal checks
;DISKSONBOOT			;insert disks in floppy drives
;DOSASSIGN			;enable _dos_assign routine
;FONTHEIGHT	= 8		;enable 80 chars per line
HDINIT				;initialize filesystem handler
;HRTMON				;add support for HrtMON
;INITAGA			;enable AGA features
;INIT_AUDIO			;enable audio.device
;INIT_GADTOOLS			;enable gadtools.library
;INIT_LOWLEVEL			;init lowlevel.library
;INIT_MATHFFP			;enable mathffp.library
;INIT_NONVOLATILE		;init nonvolatile.library
;INIT_RESOURCE			;init whdload.resource
IOCACHE		= 4096		;cache for the filesystem handler (per fh)
;JOYPADEMU			;use keyboard for joypad buttons
;MEMFREE	= $100		;location to store free memory counter
;NEEDFPU			;set requirement for a fpu
NO68020				;remain 68000 compatible
;POINTERTICKS	= 1		;set mouse speed
;PROMOTE_DISPLAY		;allow DblPAL/NTSC promotion
SEGTRACKER			;add segment tracker
;SETKEYBOARD			;activate host keymap
;SNOOPFS			;trace filesystem handler
;STACKSIZE	= 6000		;increase default stack
;TRDCHANGEDISK			;enable _trd_changedisk routine
;WHDCTRL			;add WHDCtrl resident command

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError
slv_keyexit	= $59		;F10

;============================================================================

	INCLUDE	whdload/kick31.s

;============================================================================

slv_CurrentDir	dc.b	"data",0
slv_name	dc.b	"Emerald Mines",0
slv_copy	dc.b	"1994 Almathera",0
slv_info	dc.b	"adapted by Harry, Wepl",10
		dc.b	"Version 2.0 "
		INCBIN	".date"
		dc.b	0
slv_config	dc.b	"C1:B:Skip Dedication",0
	EVEN
slv_MemConfig	= slv_base				; disabled

;============================================================================
; callback/hook which gets executed after each successful call to dos.LoadSeg
; can also be used instead of _bootdos, requires the presence of
; "startup-sequence"
; if you use diskimages that is the way to patch the executables

; the following example uses a parameter table to patch different executables
; after they get loaded

; D0 = BSTR name of the loaded program as BCPL string
; D1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg	lsl.l	#2,d0		;-> APTR
		beq	.end		;ignore if name is unset
		move.l	d0,a0
		moveq	#0,d0
		move.b	(a0)+,d0	;D0 = name length
	;remove leading path
		move.l	a0,a1
		move.l	d0,d2
.path		move.b	(a1)+,d3
		subq.l	#1,d2
		cmp.b	#":",d3
		beq	.skip
		cmp.b	#"/",d3
		bne	.chk
.skip		move.l	a1,a0		;A0 = name
		move.l	d2,d0		;D0 = name length
.chk		tst.l	d2
		bne	.path
	;get hunk length sum
		move.l	d1,a1		;D1 = segment
		moveq	#0,d2
.add		add.l	a1,a1
		add.l	a1,a1
		add.l	(-4,a1),d2	;D2 = hunks length
		subq.l	#8,d2		;hunk header
		move.l	(a1),a1
		move.l	a1,d7
		bne	.add
	;search patch
		lea	(_cbls_patch,pc),a1
.next		move.l	(a1)+,d3
		movem.w	(a1)+,d4-d5
		beq	.end
		cmp.l	d2,d3		;length match?
		bne	.next
	;compare name
		lea	(_cbls_patch,pc,d4.w),a2
		move.l	a0,a3
		move.l	d0,d6
.cmp		move.b	(a3)+,d7
		cmp.b	#"a",d7
		blo	.l
		cmp.b	#"z",d7
		bhi	.l
		sub.b	#$20,d7
.l		cmp.b	(a2)+,d7
		bne	.next
		subq.l	#1,d6
		bne	.cmp
		tst.b	(a2)
		bne	.next
	;set debug
	IFD DEBUG
		clr.l	-(a7)
		move.l	d1,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		move.l	(_resload,pc),a2
		jsr	(resload_Control,a2)
		move.l	(4,a7),d1
		add.w	#12,a7
	ENDC
	;patch
		lea	(_cbls_patch,pc,d5.w),a0
		move.l	d1,a1
		move.l	(_resload,pc),a2
		jsr	(resload_PatchSeg,a2)
	;end
.end		rts

LSPATCH	MACRO
		dc.l	\1		;cumulated size of hunks (not filesize!)
		dc.w	\2-_cbls_patch	;name
		dc.w	\3-_cbls_patch	;patch list
	ENDM

_cbls_patch	LSPATCH	$24ac+$2b210,.n_dedication,_p_dedication
	;	LSPATCH	$39cc+$81610,.n_intro,_p_intro
	;	LSPATCH	$79dc+$7a8,.n_em,_p_em
		dc.l	0

	;all upper case!
.n_dedication	dc.b	"DEDICATION",0
.n_intro	dc.b	"INTRO",0
.n_em		dc.b	"EM",0
	EVEN

_p_dedication	PL_START
		PL_IFC1
		PL_R	0			;skip it completely
		PL_ENDIF
		PL_END

	IFEQ 1
_p_intro	PL_START
		PL_PA	$1736+2,.script
		PL_END

; original script is:
;		db	'assign DAT: em:_base',$A
;		db	'cd SFX:',$A
;		db	'copy DAT:NAM RAM:NAM',$A
;		db	'DAT:EM "                    %s%s%s                    "',$A,0

.script		db	'assign DAT: :_base',$A
		db	'cd SFX:',$A
		db	"if not exists lev:nam",10
		db	'copy DAT:NAM lev:NAM',$A
		db	"endif",10
		db	'DAT:EM "                    %s%s%s                    "',$A,0
	EVEN

_p_em		PL_START
		PL_STR	$123c,<LEV>		;RAM:nam
		PL_STR	$128c,<LEV>		;RAM:nam
		PL_END
	ENDC

;============================================================================

	END

