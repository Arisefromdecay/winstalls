;*---------------------------------------------------------------------------
;  :Program.	deuteros.asm
;  :Contents.	Slave for "Deuteros"
;  :Author.	Wepl
;  :Version.	$Id: deuteros.asm 1.1 1998/05/25 15:45:29 jah Exp $
;  :History.	14.05.98 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	exec/io.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	lvo/exec.i

	IFD	BARFLY
	OUTPUT	"wart:deuteros/deuteros.slave"
	BOPT	O+ OG+				;enable optimizing
	BOPT	ODd- ODe-			;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	7			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
_basememsize	dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	$58			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10

;============================================================================

	IFD	BARFLY
		dc.b	"$VER: Deuteros.Slave by Wepl "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	0
	ENDC
	EVEN

;============================================================================
_Start	;	A0 = resident loader
;============================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using

	;get savedisksize
		lea	(_disk3),a0
		move.l	(_resload),a1
		jsr	(resload_GetFileSize,a1)
		lea	(_size3),a0
		move.l	d0,(a0)
		
	;clear mem for title picture
		lea	$8ab00,a0
		lea	$92800,a1
.cl		clr.l	(a0)+
		cmp.l	a0,a1
		bne	.cl

	;load the osemu module
		lea	(_osemu,pc),a0		;filename of the osemu module
		lea	$400,a1			;the address on which you have
						;assembled the osemu module
		move.l	(_resload,pc),a2	;the resload base
		jsr	(resload_LoadFileDecrunch,a2)	;this allows to
						;compress the osemu
	;init the osemu module
		move.l	(_resload,pc),a0	;the resload base
		lea	(_base,pc),a1		;the slave structure
		jsr	$400

	;start the program
		move	#0,sr			;if the program uses the os it
						;should executed in user mode

	;bootblock stuff
		move.l	#$2c00,d0		;offset
		move.l	#$2c00,d1		;size
		moveq	#1,d2			;disk
		lea	$12800,a0		;destination
		move.l	a0,a4
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		clr.l	$12fdc
		clr.l	$12ff4
	;	move.l	$300,$12ff8		;ioreq
		clr.l	$12ffc
	;some fixes
		ret	$9ae(a4)		;rn-copylock
	;reset colors
		lea	(_custom+color),a0
		moveq	#32/2-1,d0
.cl2		clr.l	(a0)+
		dbf	d0,.cl2
	;hook for doio
		move.l	(4),a0
		lea	(_doios),a1
		move.l	(_LVODoIO+2,a0),(a1)
		lea	(_doio),a1
		move.l	a1,(_LVODoIO+2,a0)
	;start
		jmp	(a4)

;--------------------------------

_doio		cmp.l	#$2063e,a1		;savedisk ?
		bne	.go
		move.l	#2,(IO_UNIT,a1)		;saving to disk #3
		lea	(_size3),a0
		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		beq	.read
		cmp.w	#ETD_WRITE,(IO_COMMAND,a1)
		bne	.fail

.write		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(a0),d0
		blo	.go
		move.l	d0,(a0)
		bra	.go

.read		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(a0),d0
		bhi	.clr

.go		move.l	(_doios),a0
		jsr	(a0)
		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		bne	.q
		cmp.l	#$4200,(IO_LENGTH,a1)
		beq	.2
		cmp.l	#$13000,(IO_DATA,a1)
		bne	.q
	;main exe
.1		patch	$38818,_disk2		;insert data disk
		patch	$3f764,_random
		skip	$130-$116,$38116	;check for savedisk
		bra	.q
	;intro
.2		ret	$2080c			;access fault
	;return
.q		rts

.fail		st	(IO_ERROR,a1)
		rts

.clr	blitz
		move.l	(IO_DATA,a1),a0
		move.l	(IO_LENGTH,a1),d0
.c		clr.l	(a0)+
		subq.l	#4,d0
		bhi	.c
		sf	(IO_ERROR,a1)
		rts

;--------------------------------

_disk2		addq.l	#1,($206a0+IO_UNIT)
		rts

_random		lea	($3f760),a0
		move.w	(vhposr+_custom),d0
		add.w	(a0),d0
		ror.w	#1,d0
		move.w	d0,(a0)
		and.w	#$ff,d0
		rts

;--------------------------------

_resload	dc.l	0			;address of resident loader
_doios		dc.l	0
_size3		dc.l	0
_disk3		dc.b	"Disk.3",0
_osemu		dc.b	"OSEmu.400",0

;============================================================================

	END

