;*---------------------------------------------------------------------------
;  :Program.	deuteros.asm
;  :Contents.	Slave for "Deuteros"
;  :Author.	Wepl
;  :Version.	$Id: interphase.asm 1.5 1998/05/03 20:33:42 jah Exp jah $
;  :History.	14.05.98 started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V1.131
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	macros/ntypes.i

	IFD	BARFLY
	OUTPUT	"wart:deuteros/deuteros.slave"
	BOPT	O+ OG+				;enable optimizing
	BOPT	ODd- ODe-			;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	5			;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError	;ws_flags
_basememsize	dc.l	$80000			;ws_BaseMemSize
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

	INCLUDE	lvo/exec.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	lvo/graphics.i
	INCLUDE	graphics/gfx.i
	INCLUDE	graphics/view.i

	STRUCTURE	emu,$400
		STRUCT	exec_jmp,-_LVOCopyMemQuick
		STRUCT	exec,588
		STRUCT	gfx_jmp,-_LVOBltBitMapRastPort
		STRUCT	gfx,242
		ALIGNLONG
		STRUCT	coplc,200
		LABEL	emu_SIZEOF
		
		lea	(exec_jmp),a0
.ce		move.w	#$4afc,(a0)+
		cmp.l	#exec,a0
		bne	.ce
.ie		clr.w	(a0)+
		cmp.l	#gfx_jmp,a0
		bne	.ie
.cg		move.w	#$4afc,(a0)+
		cmp.l	#gfx,a0
		bne	.cg
.ig		clr.w	(a0)+
		cmp.l	#emu_SIZEOF,a0
		bne	.ig

		lea	(exec),a6
		move.l	a6,(4)
		ret	_LVOSuperState(a6)
		patch	_LVOUserState(a6),_UserState
		ret	_LVOFindTask(a6)
		ret	_LVOAddPort(a6)
		patch	_LVOOpenDevice(a6),_OpenDevice
		patch	_LVOOpenLibrary(a6),_OpenLibrary
		patch	_LVOAvailMem(a6),_AvailMem
		patch	_LVODoIO(a6),_DoIO
		bra	_exec_end

_UserState	move.l	(a7),a0
		move.l	d0,a7
		jmp	(a0)
_OpenDevice	move.l	d0,(IO_UNIT,a1)
		moveq	#0,d0
		rts
_OpenLibrary	move.l	#gfx,d0
		cmp.l	#"grap",(a1)
		beq	.ret
		illegal
.ret		rts
_AvailMem	btst	#2,d1
		bne	.retzero
		move.l	(_basememsize),d0
		sub.l	#$2000,d0
		rts
.retzero	moveq	#0,d0
		rts
_DoIO		cmp.w	#TD_MOTOR,(IO_COMMAND,a1)
		beq	.ret
		illegal
.ret
_exec_end

		lea	(gfx),a6
		patch	_LVOInitView(a6),_InitView
		patch	_LVOInitVPort(a6),_InitVPort
		patch	_LVOInitBitMap(a6),_InitBitMap
		patch	_LVOInitRastPort(a6),_InitRastPort
		patch	_LVOMakeVPort(a6),_MakeVPort
		patch	_LVOMrgCop(a6),_MrgCop
		patch	_LVOLoadView(a6),_LoadView
		bra	_gfx_end

_InitBitMap	move.b	d0,(bm_Depth,a0)
		lsr.w	#3,d1
		move.w	d1,(bm_BytesPerRow,a0)
		move.w	d2,(bm_Rows,a0)
_InitView
_InitVPort
_InitRastPort
_MakeVPort
_MrgCop		rts
_LoadView					;a1 = view
		move.l	(v_ViewPort,a1),a0
		move.l	(vp_RasInfo,a0),a0
		move.l	(ri_BitMap,a0),a0
		lea	(coplc),a1
		move.l	#diwstrt<<16+$2981,(a1)+
		move.l	#diwstop<<16+$f1c1,(a1)+	;320x200
		move.l	#ddfstrt<<16+$0038,(a1)+
		move.l	#ddfstop<<16+$00d0,(a1)+
		move.w	#bplcon0,(a1)+
		move.b	(bm_Depth,a0),d0
		ror.w	#4,d0
		or.w	#$200,d0
		move.w	d0,(a1)+
		move.l	#bplcon1<<16,(a1)+
		move.l	#bpl1mod<<16,(a1)+
		move.l	#bpl2mod<<16,(a1)+
		
		move.b	(bm_Depth,a0),d0
		lea	(bm_Planes,a0),a0
		move.w	#bplpt,d1
.lp		move.w	d1,(a1)+
		addq.w	#2,d1
		move.w	(a0)+,(a1)+
		move.w	d1,(a1)+
		addq.w	#2,d1
		move.w	(a0)+,(a1)+
		subq.b	#1,d0
		bne	.lp
		
		move.l	#-2,(a1)+
		move.l	#coplc,(_custom+cop1lc)
		waitvb
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER,(_custom+dmacon)
		rts
_gfx_end

		move.l	#$2c00,d0		;offset
		move.l	#$2c00,d1		;size
		moveq	#1,d2			;disk
		lea	$12800,a0		;destination
		move.l	(_resload),a1
		jsr	(resload_DiskLoad,a1)
		
		clr.l	$12fdc
		clr.l	$12ff4
		move.l	$300,$12ff8		;ioreq
		clr.l	$12ffc
		
		lea	$12800,a4
		ill	$1446(a4)
		
		jmp	(a4)
		
;--------------------------------

_exit		pea	TDREASON_OK
		move.l	(_resload),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;--------------------------------

_resload	dc.l	0			;address of resident loader

;============================================================================

	END

