;*---------------------------------------------------------------------------
;  :Program.	deuteros.asm
;  :Contents.	Slave for "Deuteros"
;  :Author.	Wepl
;  :Version.	$Id: deuteros.asm 1.10 2001/08/28 20:38:55 wepl Exp wepl $
;  :History.	14.05.98 started
;		10.08.98 reading from second disk fixed
;		02.09.98 sound play fixed
;		05.09.98 icache enabled
;		23.09.98 access fault late in the game fixed (olivier schott)
;		30.09.98 first patch for random routine changed
;		08.10.98 patch for "reaching stars" sequence added (Björn Hagström)
;			 new patch routine
;		16.12.98 on second version also bad version requester appears
;			 cache disabled by default
;		07.07.99 reworked for whdload v10
;		03.08.01 adapted for kickemu
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:d/deuteros/Deuteros.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

	STRUCTURE	globals,$100
		LONG	ACTDISK
		LONG	DOIO_OS
		LONG	SIZE3

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= 0
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HRTMON
;MEMFREE	= $100
SETPATCH

;============================================================================

KICKSIZE	= $40000			;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	14			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC

_name		dc.b	"Deuteros",0
_copy		dc.b	"1991 Ian Bird",0
_info		dc.b	"installed & fixed by Wepl",10
		dc.b	"Version 1.9 "
		INCBIN	"T:date"
		dc.b	0
	EVEN

;============================================================================

_bootearly

	;init vars
		move.l	#1,ACTDISK

	;get savedisksize
		lea	(_savename),a0
		move.l	(_resload),a1
		jsr	(resload_GetFileSize,a1)
		move.l	d0,(SIZE3)
		
	;bootblock stuff
		move.l	#$2c00,d0		;offset
		move.l	#$2c00,d1		;size
		moveq	#1,d2			;disk
		lea	$12800,a0		;destination
		move.l	a0,a4
		move.l	(_resload),a3
		jsr	(resload_DiskLoad,a3)
		move.l	#$2c00,d0
		move.l	a4,a0
		jsr	(resload_CRC16,a3)
		cmp.w	#$d84b,d0
		beq	.v1
		pea	TDREASON_WRONGVER
		jmp	(resload_Abort,a3)

.v1	;some fixes
		ret	$9ae(a4)		;rn-copylock
	;delay
		patch	$12b1a,.delay

	;variables
		clr.l	$12fdc
		clr.l	$12ff4
		move.l	#0,$12ff8		;ioreq
		clr.l	$12ffc
	;hook for doio
		move.l	(4),a0
		move.l	(_LVODoIO+2,a0),(DOIO_OS)
		lea	(_doio),a1
		move.l	a1,(_LVODoIO+2,a0)
	;start
		jmp	(a4)


.delay		move.w	#200,d0
.1		btst	#6,$bfe001
		beq	.2
		btst	#7,$bfe001
		beq	.2
		waitvb
		dbf	d0,.1
.2		move.w	$12a34,d0		;original
		rts

;--------------------------------

_doio		movem.l	d0-d1/a0-a1,-(a7)
		moveq	#0,d0			;unit
		move.l	(ACTDISK),d1		;image
		bsr	_trd_changedisk
		movem.l	(a7)+,_MOVEMREGS

		cmp.l	#3,(ACTDISK)
		bne	.go

	;savedisk
		cmp.w	#ETD_WRITE,(IO_COMMAND,a1)
		beq	.go
		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		bne	.fail
	;check read size
		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(SIZE3),d0
		bhi	.clr
	;enter os function
.go		move.l	(DOIO_OS),a0
		jsr	(a0)
	;check command
		cmp.w	#ETD_WRITE,(IO_COMMAND,a1)
		bne	.read
	;write operation
		tst.b	(IO_ERROR,a1)		;success ?
		bne	.q
		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(SIZE3),d0		;enlarged ?
		blo	.q
		move.l	d0,(SIZE3)		;new disk 3 size
		bra	.q
	;read operation
.read		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		bne	.q
		
		movem.l	d0-d4/a2,-(a7)
		lea	(.base),a0
		move.l	a0,a2
.next		movem.l	(a0)+,d0-d4
		tst.l	d0
		beq	.end
		cmp.l	(ACTDISK),d0
		bne	.next
		cmp.l	(IO_LENGTH,a1),d1
		bne	.next
		cmp.l	(IO_DATA,a1),d2
		bne	.next
		cmp.l	(IO_OFFSET,a1),d3
		bne	.next
		jsr	(a2,d4.l)
.end		movem.l	(a7)+,d0-d4/a2

.q		rts

.fail		st	(IO_ERROR,a1)
		rts

.clr		move.l	(IO_DATA,a1),a0
		move.l	(IO_LENGTH,a1),d0
.c		clr.l	(a0)+
		subq.l	#4,d0
		bhi	.c
		sf	(IO_ERROR,a1)
		rts

;--------------------------------

.base		dc.l	1,$6ca00,$13000,$6e000,.main-.base	;loaded first time
		dc.l	1,$55400,$1e000,$79000,.main-.base	;loaded after "reaching stars" sequence
		dc.l	1,$4200,$20000,$5800,.intro-.base
		dc.l	2,$4200,$20000,$5800,.stars-.base	;"reaching stars"
		dc.l	2,$1600,$256ce,$25200,.late-.base	;after loding game
		dc.l	0

	;main exe
.main		patch	$38818,_disk2		;insert data disk
		move.l	#$20000,$3f766		;bad random generator reading from $ff0000
	;	skip	$130-$116,$38116	;check for savedisk
		patchs	$38116,_disk3
		ret	$3867c			;format savedisk
		move.w	#$4e71,$3fc0e		;sound play fix
		rts

	;intro
.intro		ret	$2080c			;access fault (intro)
		rts

	;"reaching stars"
.stars		patchs	$2085c,.af1
		rts
.af1		clr.w	$2174c			;access fault (extro)
		clr.w	$21750			;access fault (extro)
		move.l	#1,ACTDISK
		move.l	$2174c,a0		;original
		rts

	;after late loading (oliver schott)
.late	;	lea	($7bb7a),a0
	;	cmp.l	#$ff0000,(a0)		;tries to read from ROM area
	;	bne	.q
	;	move.l	#$20000,(a0)		;set to uncritical mem area
		move.l	#$20000,$7bb7a
		rts

;--------------------------------

_disk2		move.l	#2,ACTDISK
		rts
_disk3		move.l	#3,ACTDISK
		add.l	#$130-$116-6,(a7)
		rts

;--------------------------------

_savename	dc.b	"Disk.3",0
	EVEN

;============================================================================

	INCLUDE	Sources:whdload/kick13.s

;============================================================================

	END

