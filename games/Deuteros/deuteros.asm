;*---------------------------------------------------------------------------
;  :Program.	deuteros.asm
;  :Contents.	Slave for "Deuteros"
;  :Author.	Wepl
;  :Version.	$Id: deuteros.asm 1.6 1998/10/15 23:42:19 jah Exp jah $
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
	OUTPUT	"wart:d-f/deuteros/Deuteros.Slave"
	BOPT	O+ OG+				;enable optimizing
	BOPT	ODd- ODe-			;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

	STRUCTURE	globals,$100
		LONG	ACTDISK
		LONG	DOIO_OS
		LONG	RESLOAD
		LONG	SIZE3

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	7			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		dc.l	$100000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$59			;ws_keyexit = F10

;============================================================================

	IFD	BARFLY
		dc.b	"$VER: Deuteros.Slave 1.7 by Wepl "
	DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	0
	ENDC
	EVEN

;============================================================================
_Start	;	A0 = resident loader
;============================================================================

		move.l	a0,(RESLOAD)			;save for later using

	;enable cache
	;	move.l	#CACRF_EnableI,d0		;enable instruction cache
	;	move.l	d0,d1    			;mask
	;	jsr	(resload_SetCACR,a0)

	;init vars
		move.l	#0,ACTDISK

	;get savedisksize
		lea	(_disk3),a0
		move.l	(RESLOAD),a1
		jsr	(resload_GetFileSize,a1)
		move.l	d0,(SIZE3)
		
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
		move.l	(RESLOAD),a2		;the resload base
		jsr	(resload_LoadFileDecrunch,a2)	;this allows to
						;compress the osemu
	;init the osemu module
		move.l	a2,a0			;the resload base
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
		move.l	(RESLOAD),a3
		jsr	(resload_DiskLoad,a3)
		move.l	#$2c00,d0
		move.l	a4,a0
		jsr	(resload_CRC16,a3)
		cmp.w	#$d84b,d0
	bne	_badver
	;	beq	.v1
	;	cmp.w	#$8ab8,d0
	;	beq	.v2
	;	bra	_badver

.v1	;some fixes
		ret	$9ae(a4)		;rn-copylock
	;delay
		patch	$12b1a,.delay
	IFEQ 1
		bra	.vall

.v2		lea	$12800,a0
		lea	$12500,a1
		move.l	a1,a4
		move.l	#$2c00,d0
.v2_1		move.l	(a0)+,(a1)+
		subq.l	#4,d0
		bne	.v2_1
	ENDC
.vall
	;variables
		clr.l	$12fdc
		clr.l	$12ff4
	;	move.l	$300,$12ff8		;ioreq
		clr.l	$12ffc
	;reset colors
		lea	(_custom+color),a0
		moveq	#32/2-1,d0
.cl2		clr.l	(a0)+
		dbf	d0,.cl2
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

_doio		move.l	ACTDISK,(IO_UNIT,a1)
		cmp.l	#$2063e,a1		;savedisk ?
		bne	.go
	;savedisk
		move.l	#2,(IO_UNIT,a1)		;saving to disk #3
		cmp.w	#ETD_WRITE,(IO_COMMAND,a1)
		beq	.go
		cmp.w	#ETD_READ,(IO_COMMAND,a1)
		bne	.fail
	;check read size
		move.l	(IO_OFFSET,a1),d0
		add.l	(IO_LENGTH,a1),d0
		cmp.l	(SIZE3),d0
		bhi	.clr
	;enter osemu function
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
		subq.l	#1,d0
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
		skip	$130-$116,$38116	;check for savedisk
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
		clr.l	ACTDISK
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

_disk2		move.l	#1,ACTDISK
		rts

;--------------------------------

_badver		pea	TDREASON_WRONGVER.w
		bra	_end
_end		move.l	(RESLOAD),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------

_version	dc.w	1
_disk3		dc.b	"Disk.3",0
_osemu		dc.b	"OSEmu.400",0

;============================================================================

	END

