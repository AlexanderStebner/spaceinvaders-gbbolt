; Disassembly of "spaceinvaders.gb"
; This file was created with:
; mgbdis v3.0 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $000", ROM0[$0]

;@ def RST_00(index: a)
;@ path: system/vectors
;@ Restart vector $00: `rst $00` is the game's jump-table call. The table of addresses follows the
;@ `rst` instruction; JumpTableDispatch jumps to entry `index`.
;@ test: skip rewrites the return address on the stack
;@ sig: fc99fbdb
RST_00::
;> JumpTableDispatch(index)              # a jump: the table's routine returns to the caller of the rst
	jp JumpTableDispatch


	db $ff, $ff, $ff, $ff, $ff

;@ def RST_08()
;@ path: system/vectors
;@ Restart vectors $08-$20: unused filler bytes ($FF). Nothing executes them.
;@ test: skip filler bytes, not code
;@ sig: ff6cab0b
RST_08::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ def RST_28()
;@ path: system/vectors
;@ Restart vectors $28-$30: unused filler bytes ($FF). Nothing executes them.
;@ test: skip filler bytes, not code
;@ sig: 3fb3c61a
RST_28::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ def RST_38()
;@ path: system/vectors
;@ Restart vector $38: unused filler bytes ($FF). Nothing executes them.
;@ test: skip filler bytes, not code
;@ sig: 2144df1c
RST_38::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ def VBlankInterrupt()
;@ path: system/vectors
;@ Interrupt vector $40: the VBlank interrupt.
;@ test: skip interrupt vector
;@ sig: d2072b5d
VBlankInterrupt::
;> VBlankHandler()                       # a jump; the handler ends with reti
	jp VBlankHandler


	db $ff, $ff, $ff, $ff, $ff

;@ def LCDCInterrupt()
;@ path: system/vectors
;@ Interrupt vector $48: the LCD STAT interrupt (raised at HBlank while a VRAM access is pending).
;@ test: skip interrupt vector
;@ sig: a8153f83
LCDCInterrupt::
;> LcdStatHandler()                      # a jump; the handler ends with reti
	jp LcdStatHandler


	db $ff, $ff, $ff, $ff, $ff

;@ def TimerOverflowInterrupt()
;@ path: system/vectors
;@ Interrupt vector $50: the timer interrupt, which drives the sound engine.
;@ test: skip interrupt vector
;@ sig: 75bed57e
TimerOverflowInterrupt::
;> TimerHandler()                        # a jump; the handler ends with reti
	jp TimerHandler


	db $ff, $ff, $ff, $ff, $ff

;@ def SerialTransferCompleteInterrupt()
;@ path: system/vectors
;@ Interrupt vector $58: the serial interrupt, raised when a byte has gone over the link cable.
;@ The last padding byte ($D9) is a stray `reti` that nothing reaches.
;@ test: skip interrupt vector
;@ sig: b5c12418
SerialTransferCompleteInterrupt::
;> SerialHandler()                       # a jump; the handler ends with reti
	jp SerialHandler


	db $ff, $ff, $ff, $ff, $ff, $d9

;@ def LcdStatHandler()
;@ path: system/interrupts
;@ LCD STAT interrupt. The game switches it on (HBlank mode) only while it needs one VRAM access
;@ outside VBlank: it puts the low byte of one of the LcdHandler routines at $0071-$0095 into
;@ hLcdHook, and at the next HBlank (when VRAM is free) that routine runs once. The handlers end by
;@ jumping back to LcdHookDone, which restores the registers.
;@ writes: hLcdHook
;@ reads: hLcdHook
;@ test: skip interrupt handler (ends in reti)
;@ sig: 8b45e038
LcdStatHandler::
;> if hLcdHook != 0:
	push af
	ldh a, [hLcdHook]
	and a
	jr z, LcdStatReturn

;>     handler = 0x0000 + hLcdHook
	push hl
	ld l, a
;>     hLcdHook = 0                       # tells the waiting main code that the access is done
	xor a
	ld h, a
	ldh [hLcdHook], a
;>     handler()                          # a jump: the handler returns through LcdHookDone
	jp hl


LcdHookDone:
;> return                                # registers restored, reti
	pop hl

LcdStatReturn:
	pop af
	reti


;@ def LcdWriteTilePair()
;@ path: system/interrupts
;@ LCD hook $71: writes the tile pair hVramData0, hVramData0 + 1 to the background map at hVramAddr
;@ (two neighbouring tiles of a two-tile wide picture).
;@ reads: hVramAddrHi, hVramAddrLo, hVramData0
;@ test: skip LCD hook, ends in the interrupt handler's epilogue
;@ sig: a77421bd
LcdWriteTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = hVramData0
	ldh a, [hVramData0]
	ld [hli], a
;> mem[addr + 1] = hVramData0 + 1
	inc a
	ld [hl], a
;> LcdHookDone()
	jr LcdHookDone

;@ def LcdClearTilePair()
;@ path: system/interrupts
;@ LCD hook $7E: clears two neighbouring background tiles at hVramAddr (tile $A4 is blank).
;@ reads: hVramAddrHi, hVramAddrLo
;@ test: skip LCD hook, ends in the interrupt handler's epilogue
;@ sig: 3e5f57df
LcdClearTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = 0xA4                      # blank tile
	ld a, $a4
	ld [hli], a
;> mem[addr + 1] = 0xA4
	ld [hl], a
;> LcdHookDone()
	jr LcdHookDone

;@ def LcdWriteTile()
;@ path: system/interrupts
;@ LCD hook $8A: writes the single tile hVramData0 to the background map at hVramAddr.
;@ reads: hVramAddrHi, hVramAddrLo, hVramData0
;@ test: skip LCD hook, ends in the interrupt handler's epilogue
;@ sig: a456a37d
LcdWriteTile::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = hVramData0
	ldh a, [hVramData0]
	ld [hl], a
;> LcdHookDone()
	jr LcdHookDone

;@ def LcdReadTilePair()
;@ path: system/interrupts
;@ LCD hook $95: reads the two background tiles at hVramAddr into hVramData0 and hVramData1
;@ (the game looks at what lies under a shot or bomb).
;@ writes: hVramData0, hVramData1
;@ reads: hVramAddrHi, hVramAddrLo
;@ test: skip LCD hook, ends in the interrupt handler's epilogue
;@ sig: 5d8bfb91
LcdReadTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> hVramData0 = mem[addr]
	ld a, [hli]
	ldh [hVramData0], a
;> hVramData1 = mem[addr + 1]
	ld a, [hl]
	ldh [hVramData1], a
;> LcdHookDone()
	jr LcdHookDone

;@ def VBlankWriteTilePair()
;@ path: system/interrupts
;@ VBlank hook $A3: writes the tile pair hVramData0, hVramData0 + 1 to the background map at
;@ hVramAddr. Used instead of the LCD hook when the STAT interrupt is not available.
;@ reads: hVramAddrHi, hVramAddrLo, hVramData0
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: ad1e3c71
VBlankWriteTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = hVramData0
	ldh a, [hVramData0]
	ld [hli], a
;> mem[addr + 1] = hVramData0 + 1
	inc a
	ld [hl], a
;> VBlankDone()
	jp VBlankDone


;@ def VBlankClearTilePair()
;@ path: system/interrupts
;@ VBlank hook $B1: clears two neighbouring background tiles at hVramAddr (tile $A4 is blank).
;@ reads: hVramAddrHi, hVramAddrLo
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: 2095c026
VBlankClearTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = 0xA4                      # blank tile
	ld a, $a4
	ld [hli], a
;> mem[addr + 1] = 0xA4
	ld [hl], a
;> VBlankDone()
	jp VBlankDone


;@ def VBlankWriteTile()
;@ path: system/interrupts
;@ VBlank hook $BE: writes the single tile hVramData0 to the background map at hVramAddr.
;@ reads: hVramAddrHi, hVramAddrLo, hVramData0
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: 723f43a8
VBlankWriteTile::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = hVramData0
	ldh a, [hVramData0]
	ld [hl], a
;> VBlankDone()
	jp VBlankDone


;@ def VBlankMoveTilePairDownLeft()
;@ path: system/interrupts
;@ VBlank hook $CA: draws the tile pair hVramData0, hVramData0 + 1 at hVramAddr and clears the two
;@ tiles one row up and one column right of it, where the pair was before: a two-tile picture moves
;@ one tile down and one tile left in a single VBlank.
;@ reads: hVramAddrHi, hVramAddrLo, hVramData0
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: 62bad67e
VBlankMoveTilePairDownLeft::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> mem[addr] = hVramData0
	ldh a, [hVramData0]
	ld [hli], a
;> mem[addr + 1] = hVramData0 + 1
	inc a
	ld [hl], a
;> old = addr + 2 - 33                   # the previous spot: one row up, one column right
	ld de, $ffdf
	add hl, de
;> mem[old] = 0xA4
	ld a, $a4
	ld [hli], a
;> mem[old + 1] = 0xA4
	ld [hl], a
;> VBlankDone()
	jp VBlankDone


;@ def VBlankReadTilePair()
;@ path: unused/hooks
;@ VBlank hook $E0: reads the two background tiles at hVramAddr into hVramData0 and hVramData1.
;@ Nothing ever selects this hook (the game reads tiles through the LCD hook instead).
;@ writes: hVramData0, hVramData1
;@ reads: hVramAddrHi, hVramAddrLo
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: a38e4070
VBlankReadTilePair::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> hVramData0 = mem[addr]
	ld a, [hli]
	ldh [hVramData0], a
;> hVramData1 = mem[addr + 1]
	ld a, [hl]
	ldh [hVramData1], a
;> VBlankDone()
	jp VBlankDone


;@ def VBlankClearTileRow()
;@ path: unused/hooks
;@ VBlank hook $EF: clears 16 background tiles in a row from hVramAddr. Nothing ever selects it.
;@ reads: hVramAddrHi, hVramAddrLo
;@ test: skip VBlank hook, ends in the VBlank handler's epilogue
;@ sig: a8d3efca
VBlankClearTileRow::
;> addr = (hVramAddrHi << 8) | hVramAddrLo
	ldh a, [hVramAddrHi]
	ld h, a
	ldh a, [hVramAddrLo]
	ld l, a
;> fill(addr, 0xA4, 16)                  # 16 blank tiles
	ld a, $a4
	ld b, $10

.loop
	ld [hli], a
	dec b
	jr nz, .loop

;> VBlankDone()
	jp VBlankDone


;@ def Boot()
;@ path: system/boot
;@ Cartridge entry point at $0100, where the boot ROM hands over: jumps past the header to Start.
;@ test: skip never returns
;@ sig: 7f119ac7
Boot::
;> Start()                               # a jump
	nop
	jp Start


;@ path: system/header
;@ The Nintendo logo. The boot ROM scrolls it down the screen and only starts the cartridge if these
;@ 48 bytes match its own copy.
;@ asset: logo
HeaderLogo::
	db $ce, $ed, $66, $66, $cc, $0d, $00, $0b, $03, $73, $00, $83, $00, $0c, $00, $0d
	db $00, $08, $11, $1f, $88, $89, $00, $0e, $dc, $cc, $6e, $e6, $dd, $dd, $d9, $99
	db $bb, $bb, $67, $63, $6e, $0e, $ec, $cc, $dd, $dc, $99, $9f, $bb, $b9, $33, $3e

;@ path: system/header
;@ Game title, padded with zeros to 16 bytes.
HeaderTitle::
	db "SPACE INVADERS", $00, $00

;@ path: system/header
;@ New licensee code: unused (the old code at $014B is not $33).
HeaderNewLicenseeCode::
	db $00, $00

;@ path: system/header
;@ Super Game Boy flag: 0, no SGB features.
HeaderSGBFlag::
	db $00

;@ path: system/header
;@ Cartridge type: 0, plain ROM with no mapper.
HeaderCartridgeType::
	db $00

;@ path: system/header
;@ ROM size: 0, 32 KiB (two banks, no banking).
HeaderROMSize::
	db $00

;@ path: system/header
;@ RAM size: 0, no cartridge RAM.
HeaderRAMSize::
	db $00

;@ path: system/header
;@ Destination code: 0, Japan.
HeaderDestinationCode::
	db $00

;@ path: system/header
;@ Old licensee code: $C0, Taito.
HeaderOldLicenseeCode::
	db $c0

;@ path: system/header
;@ Mask ROM version: 0.
HeaderMaskROMVersion::
	db $00

;@ path: system/header
;@ Header checksum over $0134-$014C; the boot ROM checks it.
HeaderComplementCheck::
	db $3f

;@ path: system/header
;@ Checksum of the whole ROM (big endian); nothing checks it.
HeaderGlobalChecksum::
	db $2d, $e2

;@ def Start()
;@ path: system/boot
;@ Power-on start (and the restart after a game): switches the screen off, sets up the stack and
;@ the OAM DMA routine, silences the sound, clears the game's flags, loads all tile graphics into
;@ VRAM and shows the developer credit; then falls into the title sequence.
;@ writes: hIEMask, hLcdHook, hMainHook, hMarchNote, hMarchSfxRequest, hSfxRequest, hSfxRequest2, hShieldUpload, hShieldUploadDstHi, hShieldUploadDstLo, hShieldUploadSrcHi, hShieldUploadSrcLo, hSoundOff, hSyncFlags, hUnusedFFB5, hVramAddrHi, hVramAddrLo, wAttractCount, wCheatFlags, wHomingBombs, wHomingLevel, wKillCodeFlags, wSoundQueue, wSoundQueueEnd, wSoundQueuePos
;@ test: skip never returns
;@ sig: ceb59b65
Start::
;> LcdOff()                              # with interrupts off
	di
	call LcdOff
;> sp = 0xCFFF                           # the stack grows down from the end of WRAM bank 0
	ld sp, $cfff
;> CopyOamDmaRoutine()
	call CopyOamDmaRoutine
;> hShieldUploadDstHi = 0
	and $00
	ldh [hShieldUploadDstHi], a
;> hShieldUploadDstLo = 0
	ldh [hShieldUploadDstLo], a
;> hVramAddrHi = 0
	ldh [hVramAddrHi], a
;> hVramAddrLo = 0
	ldh [hVramAddrLo], a
;> hShieldUploadDstHi = 0                # (cleared twice)
	ldh [hShieldUploadDstHi], a
;> hShieldUploadDstLo = 0
	ldh [hShieldUploadDstLo], a
;> hShieldUploadSrcHi = 0
	ldh [hShieldUploadSrcHi], a
;> hShieldUploadSrcLo = 0
	ldh [hShieldUploadSrcLo], a
;> InitSound()
	call InitSound
;> wSoundQueueEnd = 1
	ld a, $01
	ld [wSoundQueueEnd], a
;> wSoundQueuePos = 0
	xor a
	ld [wSoundQueuePos], a
;> wSoundQueue[0] = 0
	ld [wSoundQueue], a
;> wSoundQueue[1] = 0
	ld [wSoundQueue + 1], a
;> hMarchNote = 0
	ldh [hMarchNote], a
;> hSfxRequest = 0
	ldh [hSfxRequest], a
;> hMarchSfxRequest = 0
	ldh [hMarchSfxRequest], a
;> hSfxRequest2 = 0
	ldh [hSfxRequest2], a
;> hUnusedFFB5 = 1
	ld a, $01
	ldh [hUnusedFFB5], a
;> hSoundOff = 1                         # VBlank silences the sound channels
	ldh [hSoundOff], a
;> hShieldUpload = 0
	xor a
	ldh [hShieldUpload], a
;> wCheatFlags = 0
	ld [wCheatFlags], a
;> wHomingBombs = 0
	ld [wHomingBombs], a
;> wKillCodeFlags = 0
	ld [wKillCodeFlags], a
;> wHomingLevel = 0
	ld [wHomingLevel], a
;> mem[0xD11F] = 0
	ld [$d11f], a
;> hSyncFlags = 0
	ldh [hSyncFlags], a
;> hLcdHook = 0
	ldh [hLcdHook], a
;> hMainHook = 0
	ldh [hMainHook], a
;> rSCY = 0
	ldh [rSCY], a
;> rSCX = 0
	ldh [rSCX], a
;> hIEMask = 0x0F                        # VBlank, LCD STAT, timer and serial interrupts
	ld a, $0f
	ldh [hIEMask], a
;> copy(0x8000, SpriteTiles, 0x1800)          # all 384 tiles of the game into VRAM
	ld hl, SpriteTiles
	ld de, $8000
	ld bc, $1800
	call CopyBytes
;> ClearBgMap()
	call ClearBgMap
;> LcdOn()
	call LcdOn
;> ResetLinkAndHiScore()
	call ResetLinkAndHiScore
;> ShowDeveloperCredit()
	call ShowDeveloperCredit
;> TitleAndMenu()                        # falls through

;@ def TitleAndMenu()
;@ path: game/main
;@ Start of a new game: resets score, lives and round, then runs the title sequence and the menu
;@ until a game is chosen. A one-player game goes on into StartRound; anything else is sorted out
;@ by HandlePlayEnd.
;@ writes: hGameMode, hLinkFlags
;@ reads: hGameMode, hLinkFlags
;@ test: skip never returns
;@ sig: b8ad091f
TitleAndMenu::
;> InitNewGame()
	call InitNewGame
;> if hGameMode != 0x55:
	ldh a, [hGameMode]
	cp $55
	jr z, .menu

;>     hGameMode = 0                     # title sequence
	and $00
	ldh [hGameMode], a
;>     hLinkFlags &= ~0x04               # no round on screen
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a

;>@menu while True:
.menu
;>     TitleIntro()
	call TitleIntro
;>     ShowScoreTableDemo()
	call ShowScoreTableDemo
;>     if hGameMode != 0:                # a game was chosen
;>         break
	ldh a, [hGameMode]
	and a
;=@menu
	jr z, .menu

;> SelectGameMode()
	call SelectGameMode
;> SelectWeaponStock()
	call SelectWeaponStock
;> if hGameMode != 0x55:
;>     return HandlePlayEnd()            # a jump
	ldh a, [hGameMode]
	cp $55
	jp nz, HandlePlayEnd

;> StartRound()                          # falls through

;@ def StartRound()
;@ path: game/main
;@ Starts a round: shows READY and the round number, draws the playfield, sets up the sprites
;@ and the invader formation, and (in a link game) waits for the other Game Boy. Falls into the
;@ game loop.
;@ writes: hGameMode, hMarchFlags, hMarchNote, hShieldUpload, hSyncFlags
;@ reads: hSyncFlags
;@ test: skip never returns
;@ sig: 4f2f60ac
StartRound::
;> hGameMode = 0x55                      # playing
	ld a, $55
	ldh [hGameMode], a
;> ShowReadyRound()
	call ShowReadyRound
;> DrawPlayfield()
	call DrawPlayfield
;> InitRoundSprites()
	call InitRoundSprites
;> hSyncFlags |= 0x02                    # no link bytes from VBlank while the formation is drawn
	ldh a, [hSyncFlags]
	set 1, a
	ldh [hSyncFlags], a
;> DrawFormation()
	call DrawFormation
;> hSyncFlags &= ~0x02
	ldh a, [hSyncFlags]
	res 1, a
	ldh [hSyncFlags], a
;> InitUfoTimer()
	call InitUfoTimer
;> hMarchFlags = 0
	xor a
	ldh [hMarchFlags], a
;> hMarchNote = 4                        # the first beat plays note 1
	ld a, $04
	ldh [hMarchNote], a
;> hShieldUpload = 1
	ld a, $01
	ldh [hShieldUpload], a
;> LinkSync()
	call LinkSync
;> GameLoop()                            # falls through

;@ def GameLoop()
;@ path: game/main
;@ One frame of play, forever: input, pause, score, cannon, UFO, invaders, shields, shots and
;@ bombs, hits, the end-of-round checks and the march beat. When hGameMode stops being $55
;@ (round cleared, game over, reset) it leaves through HandlePlayEnd.
;@ writes: hShieldUpload
;@ reads: hGameMode, hLinkFlags
;@ test: skip never returns
;@ sig: 755b4ffd
GameLoop::
;>@loop while True:
;>     ReadJoypad()
	call ReadJoypad
;>     CheckSoftReset()
	call CheckSoftReset
;>     if hGameMode != 0x55:
;>         return HandlePlayEnd()
	ldh a, [hGameMode]
	cp $55
	jp nz, HandlePlayEnd

;>     CheckPause()
	call CheckPause
;>     AddScore()
	call AddScore
;>     MoveCannonAndFire()
	call MoveCannonAndFire
;>     SpawnUfo()
	call SpawnUfo
;>     UpdateUfo()
	call UpdateUfo
;>     MarchInvaders()
	call MarchInvaders
;>     hShieldUpload = 0                 # don't upload shield tiles while they are being changed
	ld a, $00
	ldh [hShieldUpload], a
;>     CheckBombsVsShields()
	call CheckBombsVsShields
;>     hShieldUpload = 1
	ld a, $01
	ldh [hShieldUpload], a
;>     MoveShotsAndBombs()
	call MoveShotsAndBombs
;>     CheckShotHitsInvader()
	call CheckShotHitsInvader
;>     CheckRoundClear()
	call CheckRoundClear
;>     if hGameMode != 0x55:
;>         return HandlePlayEnd()
	ldh a, [hGameMode]
	cp $55
	jp nz, HandlePlayEnd

;>     CheckCannonHits()
	call CheckCannonHits
;>     if hGameMode != 0x55:
;>         return HandlePlayEnd()
	ldh a, [hGameMode]
	cp $55
	jp nz, HandlePlayEnd

;>     CheckShotHitsBomb()
	call CheckShotHitsBomb
;>     CheckInvaded()
	call CheckInvaded
;>     if hGameMode != 0x55:
;>         return HandlePlayEnd()
	ldh a, [hGameMode]
	cp $55
	jp nz, HandlePlayEnd

;>     TickExplosions()
	call TickExplosions
;>     if not hLinkFlags & 0x01:         # secret codes only in a one-player game
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>         CheckGameCheatCodes()
	call CheckGameCheatCodes
;>         CheckKillOrder()
	call CheckKillOrder

.link
;>     PlayMarchStep()
	call PlayMarchStep
;>     FrameDelay()
	call FrameDelay
;=@loop
	jp GameLoop


;@ def ResetLinkAndHiScore()
;@ path: game/main
;@ Resets the link-cable state. After power-on (not on a restart, hGameMode $BB) it also sets the
;@ hi-score to 1000.
;@ writes: hHiScoreHi, hHiScoreLo, hLinkFlags, hSerialIn, hSerialOut
;@ reads: hGameMode
;@ test: hGameMode = rng.choice([0xBB, 0x00, 0x44])
;@ sig: 846b9dc8
ResetLinkAndHiScore::
;> if hGameMode != 0xBB:
	ldh a, [hGameMode]
	cp $bb
	jr z, .keepHiScore

;>     hHiScoreLo = 0x00
	and $00
	ldh [hHiScoreLo], a
;>     hHiScoreHi = 0x01                 # 0100 in tens: 1000 points
	ld a, $01
	ldh [hHiScoreHi], a

.keepHiScore
;> hLinkFlags = 0
	and $00
	ldh [hLinkFlags], a
;> rSB = 0
	ldh [rSB], a
;> rSC = 0
	ldh [rSC], a
;> hSerialOut = 0
	ldh [hSerialOut], a
;> hSerialIn = 0
	ldh [hSerialIn], a
	ret


;@ def InitNewGame()
;@ path: game/main
;@ New game: score 0, round 1, two cannons in reserve (for the other player too), the first extra
;@ cannon at 1500 points.
;@ writes: hExtraLivesGiven, hLives, hNextLifeHi, hNextLifeLo, hOpponentLives, hRound, hScoreHi, hScoreLo
;@ sig: c0ad1a2a
InitNewGame::
;> hScoreLo = 0
	and $00
	ldh [hScoreLo], a
;> hScoreHi = 0
	ldh [hScoreHi], a
;> hExtraLivesGiven = 0
	ldh [hExtraLivesGiven], a
;> hRound = 0x01
	ld a, $01
	ldh [hRound], a
;> hLives = 2
	ld a, $02
	ldh [hLives], a
;> hOpponentLives = 2
	ldh [hOpponentLives], a
;> hNextLifeHi = 0x01                    # 0150 in tens: 1500 points
	ld a, $01
	ldh [hNextLifeHi], a
;> hNextLifeLo = 0x50
	ld a, $50
	ldh [hNextLifeLo], a
	ret


;@ def ShowReadyRound()
;@ path: game/round
;@ Shows "READY!" (and in a one-player game "ROUND nn" above it) in sprites for a moment before
;@ play starts, then clears the text and sets the palettes. In a link game it is skipped while
;@ invaders are left (after losing a cannon the round just goes on).
;@ writes: hLinkFlags, hSerialOut, hSoundOff, hTemp, wBombHoldoff
;@ reads: hInvadersLeft, hLinkFlags, hRound, hTemp, wCheatFlags
;@ test: skip runs a busy-wait delay of almost a second
;@ sig: 89a6de0f
ShowReadyRound::
;> hSoundOff = 1
	ld a, $01
	ldh [hSoundOff], a
;> if hLinkFlags & 0x01 and hInvadersLeft != 0:
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .show

	ldh a, [hInvadersLeft]
	and a
	jp nz, .done

.show
;> rBGP = 0
	and $00
	ldh [rBGP], a
;> rOBP0 = 0
	ldh [rOBP0], a
;> palette = 0xE4                        # normal shades
	ld a, [wCheatFlags]
	ld c, a
	ld a, $e4
;> if not wCheatFlags & 0x80 and wCheatFlags & 0x01:
	bit 7, c
	jr nz, .setObp1

	bit 0, c
	jr z, .setObp1

;>     palette = 0x1B                    # inverted shades (secret code)
	cpl
	ld c, a
;>     rBGP = palette
	and $ff
	ldh [rBGP], a
;>     rOBP0 = palette
	ldh [rOBP0], a
	ld a, c

.setObp1
;> rOBP1 = palette                       # the text sprites use OBP1
	ldh [rOBP1], a
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> text = TextReady                         # "READY!" then "ROUND"
	ld de, TextReady
;> oam = 0xC084                          # sprites 33-38
	ld h, $c0
	ld l, $84
;> x = 0x40
	ld b, $06
	ld c, $40
;> hTemp = 0x60                          # Y of READY!
	ld a, $60
	ldh [hTemp], a
;> if hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .ready

;>     hTemp = 0x50                      # a little higher in a link game
	ld a, $50
	ldh [hTemp], a

.ready
;>@ready for i in range(6):
;>     mem[oam] = hTemp
	ldh a, [hTemp]
	ld [hli], a
;>     mem[oam + 1] = x
	ld a, c
	ld [hli], a
;>     mem[oam + 2] = mem[text]
	ld a, [de]
	ld [hli], a
;>     mem[oam + 3] = 0x10               # palette OBP1
	ld a, $10
	ld [hli], a
;>     oam += 4
;>     text += 1
	inc de
;>     x += 8
	ld a, $08
	add c
	ld c, a
;=@ready
	dec b
	jr nz, .ready

;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .wait

;>     oam = 0xC068                      # sprites 26-32: "ROUND" and two digits
	ld h, $c0
	ld l, $68
;>     x = 0x40
	ld b, $05
	ld c, $40

.round
;>@round     for i in range(5):
;>         mem[oam] = 0x48
	ld a, $48
	ld [hli], a
;>         mem[oam + 1] = x
	ld a, c
	ld [hli], a
;>         mem[oam + 2] = mem[text]
	ld a, [de]
	ld [hli], a
;>         mem[oam + 3] = 0x10
	ld a, $10
	ld [hli], a
;>         oam += 4
;>         text += 1
	inc de
;>         x += 8
	ld a, $08
	add c
	ld c, a
;=@round
	dec b
	jr nz, .round

;>     x = 0x4C
	ld a, $4c
	ld c, a
;>     mem[oam] = 0x50                   # tens digit of the round
	ld a, $50
	ld [hli], a
;>     mem[oam + 1] = x
	ld a, c
	ld [hli], a
;>     WriteDigitTile(oam + 2, hRound >> 4)
	ldh a, [hRound]
	swap a
	call WriteDigitTile
;>     mem[oam + 3] = 0x10
	inc hl
	ld a, $10
	ld [hli], a
;>     x += 8
	ld a, $08
	add c
	ld c, a
;>     mem[oam + 4] = 0x50               # ones digit
	ld a, $50
	ld [hli], a
;>     mem[oam + 5] = x
	ld a, c
	ld [hli], a
;>     WriteDigitTile(oam + 6, hRound)
	ldh a, [hRound]
	call WriteDigitTile
;>     mem[oam + 7] = 0x10
	inc hl
	ld a, $10
	ld [hl], a

.wait
;> Delay(0xC0)                           # about 0.7 seconds
	ld d, $c0
	call Delay
;> oam = 0xC068                          # remove the 14 text sprites
	ld h, $c0
	ld l, $68
;>@clr for i in range(14):
	and $00
	ld c, $0e

.clear
;>     fill(oam, 0, 4)
;>     oam += 4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
;=@clr
	inc de
	dec c
	jr nz, .clear

;> palette = 0xE4
	ld a, [wCheatFlags]
	ld c, a
	ld a, $e4
;> if not wCheatFlags & 0x80 and wCheatFlags & 0x01:
	bit 7, c
	jr nz, .setPalettes

	bit 0, c
	jr z, .setPalettes

;>     palette = 0x1B
	cpl

.setPalettes
;> rBGP = palette
	ldh [rBGP], a
;> rOBP0 = palette
	ldh [rOBP0], a
;> rOBP1 = palette
	ldh [rOBP1], a
;> wBombHoldoff = 4
	ld a, $04
	ld [wBombHoldoff], a
;> hSerialOut = 0xBD
	ld a, $bd
	ldh [hSerialOut], a
;> hLinkFlags |= 0x04                    # a round is on screen
	ldh a, [hLinkFlags]
	set 2, a
	ldh [hLinkFlags], a

.done
	ret


;@ def InitRoundSprites()
;@ path: game/round
;@ Loads the starting sprite table of a round (cannon, score, lives ...; a different one in a
;@ link game), resets the round's state and sets up the formation. A one-player round also
;@ draws the score, resets the shields and restarts the sound engine.
;@ writes: hMarchNote, hMarchSfxRequest, hSfxRequest, hSfxRequest2, hShotCount, hSoundOff, hUnusedFFB5, wSoundQueue, wSoundQueueEnd, wSoundQueuePos
;@ reads: hLinkFlags
;@ test: skip calls into the formation and sound setup
;@ sig: 87ed4208
InitRoundSprites::
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .linkTable

;>     src = SoloStartOam                      # one-player sprite table
	ld de, SoloStartOam
;=@else
	jr .copy

;>@else else:
.linkTable
;>     src = LinkStartOam                      # link-game sprite table
	ld de, LinkStartOam

.copy
;> dst = wShadowOam
	ld hl, wShadowOam

;>@copy while mem[src] != 0xFF:          # the table ends with $FF
.copyLoop
	ld a, [de]
	cp $ff
	jr z, .copied

;>     mem[dst] = mem[src]
;>     dst += 1
	ld [hli], a
;>     src += 1
	inc de
;=@copy
	jr .copyLoop

.copied
;> InitRoundState()
	call InitRoundState
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>     DrawLives()
	call DrawLives
;>     AddScore()                        # draws the score
	call AddScore
;>     hShotCount = 0xFF
	ld a, $ff
	ldh [hShotCount], a
;>     SetupFormation()
	call SetupFormation
;>     ResetShields()
	call ResetShields
;>     InitSound()
	call InitSound
;>     wSoundQueueEnd = 1
	ld a, $01
	ld [wSoundQueueEnd], a
;>     wSoundQueuePos = 0
	xor a
	ld [wSoundQueuePos], a
;>     wSoundQueue[0] = 0
	ld [wSoundQueue], a
;>     wSoundQueue[1] = 0
	ld [wSoundQueue + 1], a
;>     hMarchNote = 0
	ldh [hMarchNote], a
;>     hSfxRequest = 0
	ldh [hSfxRequest], a
;>     hMarchSfxRequest = 0
	ldh [hMarchSfxRequest], a
;>     hSfxRequest2 = 0
	ldh [hSfxRequest2], a
;>     hUnusedFFB5 = 1
	ld a, $01
	ldh [hUnusedFFB5], a
;>     hSoundOff = 1
	ldh [hSoundOff], a
;=@lelse
	jr .done

;>@lelse else:
.link
;>     DrawLives()
	call DrawLives
;>     ShowOpponentLives()
	call ShowOpponentLives
;>     DrawRoundsLeft()
	call DrawRoundsLeft
;>     SetupFormation()
	call SetupFormation

.done
	ret


;@ def DrawPlayfield()
;@ path: game/round
;@ Draws the background of a round; just a jump to DrawRoundScreen, past the older version that
;@ follows it.
;@ test: skip draws the screen with the LCD off
;@ sig: d0ae12f0
DrawPlayfield::
;> DrawRoundScreen()                     # a jump
	jr DrawRoundScreen

;@ def DrawPlayfieldOld()
;@ path: unused
;@ Older version of DrawRoundScreen that nothing calls (DrawPlayfield jumps over it): with the
;@ screen off it draws the one-player playfield, or in a link game the link playfield.
;@ reads: hLinkFlags
;@ test: skip draws the screen with the LCD off
;@ sig: 8e2e0b63
DrawPlayfieldOld::
;> LcdOffClear()
	call LcdOffClear
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>     screen = PlayfieldMap                   # one-player playfield
	ld de, PlayfieldMap
;=@else
	jr .draw

;>@else else:
.link
;>     screen = LinkHeaderMap                   # link-game playfield
	ld de, LinkHeaderMap

.draw
;> DrawTilemapList(screen)
	call DrawTilemapList
;> LcdOn()
	call LcdOn
	ret


;@ def DrawRoundScreen()
;@ path: game/round
;@ Background of a round. One player: switches the screen off, draws the playfield and switches
;@ it on again. Link game: the playfield stays; the screen is blanked and wiped row by row by the
;@ VBlank hook ($FF), and this waits until the wipe is done.
;@ writes: hMainHook, hShieldUploadDstHi, hShieldUploadDstLo, hWipeRow
;@ reads: hLinkFlags, hMainHook
;@ test: skip draws the screen with the LCD off or waits for VBlank
;@ sig: a439f7da
DrawRoundScreen::
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>     LcdOffClear()
	call LcdOffClear
;>     DrawTilemapList(PlayfieldMap)           # the playfield
	ld de, PlayfieldMap
	call DrawTilemapList
;>     LcdOn()
	call LcdOn
;>     return
	ret


.link
;> rBGP = 0                              # all white while the wipe runs
	and $00
	ldh [rBGP], a
;> rOBP0 = 0
	ldh [rOBP0], a
;> rOBP1 = 0
	ldh [rOBP1], a
;> ClearShadowOam()
	call ClearShadowOam
;> hWipeRow = 0
	xor a
	ldh [hWipeRow], a
;> hShieldUploadDstHi = 0x98             # the wipe starts at the top of the map, $9800
	ld a, $98
	ldh [hShieldUploadDstHi], a
;> hShieldUploadDstLo = 0x00
	xor a
	ldh [hShieldUploadDstLo], a
;> hMainHook = 0xFF                      # VBlank: the screen wipe
	ld a, $ff
	ldh [hMainHook], a

;> while hMainHook != 0:                 # the wipe clears it when it is done
;>     wait_vblank_flag()
.wait
	ldh a, [hMainHook]
	and a
	jr nz, .wait

	ret


;@ def LinkSync()
;@ path: link/sync
;@ Link game only: brings both Game Boys to the same point before play goes on. Sends $DD until the
;@ other side answers with $DD, then lets five more bytes go through and waits a little. After
;@ about three seconds without an answer it restarts the transfer and gives up.
;@ reads: hLinkFlags, hSerialIn, hTimerHi
;@ test: skip waits for serial transfers
;@ sig: 01a1c10e
LinkSync::
;> if not hLinkFlags & 0x01:
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .done

;> LinkSyncStart()
	call LinkSyncStart

;>@wait while True:
.wait
;>     if hTimerHi >= 3:                 # about 3 seconds without an answer
;>         return LinkRestartTransfer()  # a jump
	ldh a, [hTimerHi]
	sub $03
	jp nc, LinkRestartTransfer

;>     if hSerialIn == 0xDD:             # the other side is here too
;>         break
	ldh a, [hSerialIn]
	cp $dd
;=@wait
	jr nz, .wait

;> for i in range(5):
;>     LinkWaitTransfer()
	call LinkWaitTransfer
	call LinkWaitTransfer
	call LinkWaitTransfer
	call LinkWaitTransfer
	call LinkWaitTransfer
;> Delay(0x20)
	ld d, $20
	call Delay

.done
	ret


;@ def LinkSyncStart()
;@ path: link/sync
;@ Restarts the timeout counter, lets three transfers go by, then sends $DD ("I am here") for
;@ three transfers.
;@ writes: hSerialOut, hTimerHi, hTimerLo
;@ reads: hSerialOut
;@ test: skip waits for serial transfers
;@ sig: 9ba66ca8
LinkSyncStart::
;> hTimerHi = 0
	and $00
	ldh [hTimerHi], a
;> hTimerLo = 0
	ldh [hTimerLo], a
;> for i in range(3):
;>     LinkWaitTransfer()
	and $00
	ldh a, [hSerialOut]
	call LinkWaitTransfer
	call LinkWaitTransfer
	call LinkWaitTransfer
;> hSerialOut = 0xDD
	ld a, $dd
	ldh [hSerialOut], a
;> for i in range(3):
;>     LinkWaitTransfer()
	call LinkWaitTransfer
	call LinkWaitTransfer
	call LinkWaitTransfer
	ret


;@ def LinkTimeoutRetry()
;@ path: unused
;@ Restarts the serial transfer and runs LinkSync again. Nothing calls it.
;@ test: skip waits for serial transfers
;@ sig: a4442d22
LinkTimeoutRetry::
;> LinkRestartTransfer()
	call LinkRestartTransfer
;> return LinkSync()                     # a jump
	jp LinkSync


;@ def LinkRestartTransfer()
;@ path: link/sync
;@ After a link timeout: the master (internal clock) stops its transfer, so that VBlank starts a
;@ fresh one; the slave arms a new transfer on the external clock. Then a short wait.
;@ test: skip busy-wait delay
;@ sig: e5565c83
LinkRestartTransfer::
;> if rSC & 0x01:                        # we are the master
	ldh a, [rSC]
	bit 0, a
	jr z, .slave

;>     rSC = 0x01                        # internal clock, no transfer running
	and $00
	set 0, a
	ldh [rSC], a
;=@else
	jr .wait

;>@else else:
.slave
;>     rSC = 0x80                        # wait for the master's clock
	and $00
	set 7, a
	ldh [rSC], a

.wait
;> Delay(0x08)
	ld d, $08
	call Delay
	ret


;@ def LinkWaitTransfer()
;@ path: link/sync
;@ Waits until the serial interrupt reports the next finished transfer (it clears bit 6 of
;@ hSyncFlags). While the timeout has run out it keeps restarting the transfer.
;@ writes: hSyncFlags
;@ reads: hSyncFlags, hTimerHi
;@ test: skip waits for serial transfers
;@ sig: 3bbc2524
LinkWaitTransfer::
;> hSyncFlags |= 0x40
	ldh a, [hSyncFlags]
	set 6, a
	ldh [hSyncFlags], a

;>@wait while True:
.wait
;>     if hTimerHi >= 3:
;>         LinkRestartTransfer()
	ldh a, [hTimerHi]
	sub $03
	call nc, LinkRestartTransfer
;>     if not hSyncFlags & 0x40:         # the serial interrupt cleared it
;>         break
	ldh a, [hSyncFlags]
	bit 6, a
;=@wait
	jr nz, .wait

	ret


;@ def CheckSoftReset()
;@ path: game/main
;@ Select and Start held together end the game and go back to the title (hGameMode $44).
;@ writes: hGameMode
;@ reads: hJoyHeld
;@ test: hJoyHeld = rand(0, 255)
;@ sig: 3e0709b8
CheckSoftReset::
;> if hJoyHeld & 0x04 and hJoyHeld & 0x08:
	ldh a, [hJoyHeld]
	bit 2, a
	jr z, .done

	bit 3, a
	jr z, .done

;>     hGameMode = 0x44
	ld a, $44
	ldh [hGameMode], a

.done
	ret


;@ def CheckPause()
;@ path: game/pause
;@ Start pauses the game. In a link game only the master reads Start (and not while the UFO
;@ explodes); the slave pauses when the master sends $DA. Both sides must be sending ordinary
;@ cannon positions ($10-$90), not a link command, for the pause to begin.
;@ reads: hJoyPressed, hLinkFlags, hSerialIn, hSerialOut, hSyncFlags, hUfoHitTimer
;@ test: skip the pause waits for buttons and serial transfers
;@ sig: 090c8112
CheckPause::
;>@slave if hLinkFlags & 0x01 and hSyncFlags & 0x08:   # we are the slave of a link game
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .start

	ldh a, [hSyncFlags]
	bit 3, a
	jr nz, .slave

;>@sl     if hSerialIn != 0xDA:          # the master has not paused
;>@slr         return
;> else:
;>     if hLinkFlags & 0x01 and hUfoHitTimer != 0:
;>         return
	ldh a, [hUfoHitTimer]
	and a
	jr nz, CheckPauseDone

.start
;>     if not hJoyPressed & 0x08:        # Start
;>         return
	ldh a, [hJoyPressed]
	bit 3, a
	jr z, CheckPauseDone

;>     if hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .pause

;>         if not 0x10 <= hSerialOut <= 0x90:
;>             return
	ldh a, [hSerialOut]
	sub $91
	jp nc, CheckPauseDone

	ldh a, [hSerialOut]
	sub $10
	jp c, CheckPauseDone

;>         if not 0x10 <= hSerialIn <= 0x90:
;>             return
	ldh a, [hSerialIn]
	sub $91
	jp nc, CheckPauseDone

	ldh a, [hSerialIn]
	sub $10
	jp c, CheckPauseDone

.pause
;>@pause return PauseGame()             # a jump
	jr PauseGame

.slave
;=@sl
	ldh a, [hSerialIn]
	cp $da
;=@pause
	jr z, PauseGame

CheckPauseDone:
;=@slr
	ret


;@ def EndPause()
;@ path: game/pause
;@ Leaves the pause: tells the other side ($DD), waits for it in a link game, removes the PAUSE
;@ text and goes on with the game.
;@ writes: hGameMode, hSerialOut
;@ test: skip waits for serial transfers
;@ sig: 38b00f2f
EndPause::
;> hSerialOut = 0xDD
	ld a, $dd
	ldh [hSerialOut], a
;> hGameMode = 0x55
	ld a, $55
	ldh [hGameMode], a
;> LinkSync()
	call LinkSync
;> HidePauseAndResume()                  # falls through

;@ def HidePauseAndResume()
;@ path: game/pause
;@ Removes the PAUSE text, restores the palettes and the timer, and goes on with the game.
;@ test: skip part of the pause flow
;@ sig: 30d6abb1
HidePauseAndResume::
;> HidePause()
	call HidePause
;> ResumePlay()                          # falls through

;@ def ResumePlay()
;@ path: game/pause
;@ Back to play: sends $DD and sets hGameMode to $55 again.
;@ writes: hGameMode, hLinkFlags, hSerialOut
;@ reads: hLinkFlags
;@ test: hLinkFlags = rand(0, 255)
;@ sig: d89d7a1e
ResumePlay::
;> hSerialOut = 0xDD
	ld a, $dd
	ldh [hSerialOut], a
;> hGameMode = 0x55
	ld a, $55
	ldh [hGameMode], a
;> hLinkFlags |= 0x04
	ldh a, [hLinkFlags]
	set 2, a
	ldh [hLinkFlags], a
;> return                                # through the ret of CheckPause
	jr CheckPauseDone

;@ def PauseLoop()
;@ path: game/pause
;@ The pause itself: waits for Start (the slave of a link game waits for the master's $DD
;@ instead), then ends the pause.
;@ reads: hJoyPressed, hLinkFlags, hSerialIn, hSyncFlags
;@ test: skip waits for buttons or serial transfers
;@ sig: 4e620c87
PauseLoop::
;> if hLinkFlags & 0x01 and hSyncFlags & 0x08:   # the slave
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .waitStart

	ldh a, [hSyncFlags]
	bit 3, a
	jr nz, .waitMaster

;>@sl     while hSerialIn != 0xDD:
;>@sw         wait_serial()             # the serial interrupt updates hSerialIn
;>@ret     return EndPause()             # a jump
;> else:
.waitStart
;>@st     while True:
;>         ReadJoypad()
	call ReadJoypad
;>         if hJoyPressed & 0x08:        # Start
;>             return EndPause()         # a jump
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, EndPause

;>         Delay(0x10)
	ld d, $10
	call Delay
;=@st
	jr .waitStart

.waitMaster
;=@sl
	ldh a, [hSerialIn]
	cp $dd
;=@ret
	jr z, EndPause

;=@sw
	jr .waitMaster

;@ def PauseGame()
;@ path: game/pause
;@ Starts the pause. In a link game it sends $DA ("pause") first; if the other side answers with
;@ a link command instead of a cannon position or $DA, the pause is called off. Then the PAUSE
;@ text appears and PauseLoop waits.
;@ writes: hGameMode, hLinkFlags, hSerialOut
;@ reads: hLinkFlags, hSerialIn
;@ test: skip waits for buttons or serial transfers
;@ sig: f646a323
PauseGame::
;> if hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .show

;>     hSerialOut = 0xDA
	ld a, $da
	ldh [hSerialOut], a
;>     hGameMode = 0xAA                  # paused
	ld a, $aa
	ldh [hGameMode], a
;>     if hSerialIn != 0xDA:
	ldh a, [hSerialIn]
	cp $da
	jp z, .show

;>         if not 0x10 <= hSerialIn <= 0x90:
;>             return ResumePlay()       # a jump: no pause after all
	ldh a, [hSerialIn]
	sub $91
	jp nc, ResumePlay

	ldh a, [hSerialIn]
	sub $10
	jp c, ResumePlay

.show
;> ShowPause()
	call ShowPause
;> if hLinkFlags & 0x01 and hSerialIn != 0xDA:
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .wait

	ldh a, [hSerialIn]
	cp $da
	jr z, .wait

;>     if not 0x10 <= hSerialIn <= 0x90:
;>         return HidePauseAndResume()   # a jump
	ldh a, [hSerialIn]
	sub $91
	jp nc, HidePauseAndResume

	ldh a, [hSerialIn]
	sub $10
	jp c, HidePauseAndResume

.wait
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> return PauseLoop()                    # a jump
	jp PauseLoop


;@ def ShowPause()
;@ path: game/pause
;@ Silences the sound, dims the screen, saves the timer and shows "PAUSE" in five sprites.
;@ writes: hMarchNote, hMarchSfxRequest, hSfxRequest, hSfxRequest2, hSoundOff, hUnusedFFB5, wPauseTimerHi, wPauseTimerLo, wSoundQueue, wSoundQueueEnd, wSoundQueuePos
;@ reads: hTimerHi, hTimerLo
;@ test: hTimerHi = rand(0, 255)
;@ sig: c6cc2b16
ShowPause::
;> wSoundQueueEnd = 1
	ld a, $01
	ld [wSoundQueueEnd], a
;> wSoundQueuePos = 0
	xor a
	ld [wSoundQueuePos], a
;> wSoundQueue[0] = 0
	ld [wSoundQueue], a
;> wSoundQueue[1] = 0
	ld [wSoundQueue + 1], a
;> hMarchNote = 0
	ldh [hMarchNote], a
;> hSfxRequest = 0
	ldh [hSfxRequest], a
;> hMarchSfxRequest = 0
	ldh [hMarchSfxRequest], a
;> hSfxRequest2 = 0
	ldh [hSfxRequest2], a
;> hUnusedFFB5 = 1
	ld a, $01
	ldh [hUnusedFFB5], a
;> hSoundOff = 1
	ldh [hSoundOff], a
;> rBGP = 0x54                           # lighter shades
	ld a, $54
	ldh [rBGP], a
;> rOBP0 = 0x54
	ldh [rOBP0], a
;> wPauseTimerHi = hTimerHi
	ldh a, [hTimerLo]
	ld c, a
	ldh a, [hTimerHi]
	ld [wPauseTimerHi], a
;> wPauseTimerLo = hTimerLo
	ld a, c
	ld [wPauseTimerLo], a
;> text = TextPause                         # "PAUSE"
	ld de, TextPause
;> oam = 0xC08C                          # sprites 35-39
	ld hl, wShadowOam
	ld l, $8c
;> x = 0x48
	ld b, $05
	ld c, $48

.loop
;>@loop for i in range(5):
;>     mem[oam] = 0x50
	ld a, $50
	ld [hli], a
;>     mem[oam + 1] = x
	ld a, c
	ld [hli], a
;>     mem[oam + 2] = mem[text]
	ld a, [de]
	ld [hli], a
;>     mem[oam + 3] = 0x10               # palette OBP1
	ld a, $10
	ld [hli], a
;>     oam += 4
;>     text += 1
	inc de
;>     x += 8
	ld a, c
	add $08
	ld c, a
;=@loop
	dec b
	jr nz, .loop

	ret


;@ def HidePause()
;@ path: game/pause
;@ Removes the PAUSE sprites, restores the palettes (inverted with the secret code) and the
;@ timer saved by ShowPause.
;@ writes: hTimerHi, hTimerLo
;@ reads: wCheatFlags, wPauseTimerHi, wPauseTimerLo
;@ test: wCheatFlags = rand(0, 255)
;@ sig: 6f13e8e7
HidePause::
;> oam = 0xC08C
	ld hl, wShadowOam
	ld l, $8c
;>@clr for i in range(5):
	and $00
	ld c, $05

.clear
;>     fill(oam, 0, 4)
;>     oam += 4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
;=@clr
	inc de
	dec c
	jr nz, .clear

;> palette = 0xE4
	ld a, [wCheatFlags]
	ld c, a
	ld a, $e4
;> if not wCheatFlags & 0x80 and wCheatFlags & 0x01:
	bit 7, c
	jr nz, .setPalettes

	bit 0, c
	jr z, .setPalettes

;>     palette = 0x1B                    # inverted
	cpl

.setPalettes
;> rBGP = palette
	ldh [rBGP], a
;> rOBP0 = palette
	ldh [rOBP0], a
;> rOBP1 = palette
	ldh [rOBP1], a
;> hTimerHi = wPauseTimerHi
	ld a, [wPauseTimerLo]
	ld c, a
	ld a, [wPauseTimerHi]
	ldh [hTimerHi], a
;> hTimerLo = wPauseTimerLo
	ld a, c
	ldh [hTimerLo], a
	ret


;@ def AddScore()
;@ path: score/score
;@ One-player game: adds hPointsToAdd to the score, draws the four score digits (sprites 10-13;
;@ a fixed 0 sprite follows them) and gives an extra cannon when the score reaches the next
;@ threshold: 1500, 6500, 11500, 16500, 20000 and 68000 points. At 68000 the reserve jumps to 9.
;@ The threshold test compares the two BCD bytes separately, so e.g. 7000 does not pass 6500
;@ (70 >= 65 but 00 < 50) until the low byte catches up.
;@ writes: hExtraLivesGiven, hLives, hNextLifeHi, hNextLifeLo, hPointsToAdd, hScoreHi, hScoreLo, hSfxRequest2
;@ reads: hExtraLivesGiven, hLinkFlags, hLives, hPointsToAdd, hScoreHi, hScoreLo
;@ test: hLinkFlags = rng.choice([0, 0, 1])
;@ test: hPointsToAdd = rng.choice([0, 0x05, 0x10, 0x15, 0x30, 0x99])
;@ test: hScoreLo = rng.choice([0x00, 0x45, 0x95, 0x99])
;@ test: hScoreHi = rng.choice([0x00, 0x01, 0x06, 0x99])
;@ test: hExtraLivesGiven = rand(0, 7)
;@ test: hLives = rand(0, 9)
;@ sig: 3a313e3a
AddScore::
;> if hLinkFlags & 0x01:                 # the link game has no score
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, .done

;> if hPointsToAdd != 0:
	ldh a, [hPointsToAdd]
	and a
	jr z, .draw

;>     lo = bcd_to_int(hScoreLo) + bcd_to_int(hPointsToAdd)
	ld hl, hScoreLo
	add [hl]
	daa
;>     if lo >= 100:
	jr nc, .noCarry

;>         hScoreHi = to_bcd((bcd_to_int(hScoreHi) + 1) % 100)
	ld b, a
	ldh a, [hScoreHi]
	add $01
	daa
	ldh [hScoreHi], a
	ld a, b

.noCarry
;>     hScoreLo = to_bcd(lo % 100)
	ldh [hScoreLo], a

.draw
;> WriteDigitTile(0xC036, hScoreLo)      # tile of sprite 13: ones (of tens of points)
	ld h, $c0
	ld l, $36
	ldh a, [hScoreLo]
	call WriteDigitTile
;> WriteDigitTile(0xC032, hScoreLo >> 4)
	ldh a, [hScoreLo]
	swap a
	ld l, $32
	call WriteDigitTile
;> WriteDigitTile(0xC02E, hScoreHi)
	ldh a, [hScoreHi]
	ld l, $2e
	call WriteDigitTile
;> WriteDigitTile(0xC02A, hScoreHi >> 4)
	ldh a, [hScoreHi]
	swap a
	ld l, $2a
	call WriteDigitTile
;> hPointsToAdd = 0
	and $00
	ldh [hPointsToAdd], a
;> if hExtraLivesGiven >= 7:
;>     return
	ldh a, [hExtraLivesGiven]
	ld c, a
	sub $07
	jr nc, .done

;> if hScoreHi < hNextLifeHi:
;>     return
	ld hl, hNextLifeHi
	ldh a, [hScoreHi]
	sub [hl]
	jr c, .done

;> if hScoreLo < hNextLifeLo:
;>     return
	inc hl
	ldh a, [hScoreLo]
	sub [hl]
	jr c, .done

;> hSfxRequest2 = 0x13                   # extra-cannon jingle
	ld a, $13
	ldh [hSfxRequest2], a
;> entry = ExtraCannonScores + 2 * hExtraLivesGiven # next threshold, high byte first
	ld hl, ExtraCannonScores
	ld a, c
	sla a
	ld c, a
	ld b, $00
	add hl, bc
;> hNextLifeHi = mem[entry]
	ld a, [hl]
	ldh [hNextLifeHi], a
;> hNextLifeLo = mem[entry + 1]
	inc hl
	ld a, [hl]
	ldh [hNextLifeLo], a
;> if hNextLifeLo == 0xFF:               # end of the table ($FFFF can never be reached)
;>     hLives = 8
	cp $ff
	jr nz, .count

	ld a, $08
	ldh [hLives], a

.count
;> hExtraLivesGiven += 1
	ldh a, [hExtraLivesGiven]
	inc a
	ldh [hExtraLivesGiven], a
;> if hLives + 1 != 10:                  # at most 9 in reserve
	ldh a, [hLives]
	inc a
	cp $0a
	jr z, .done

;>     hLives += 1
	ldh [hLives], a
;>     DrawLives()
	call DrawLives

.done
	ret


;@ def CheckRoundClear()
;@ path: game/round
;@ Ends the round when the last invader is gone. One player: the round number goes up (BCD),
;@ hGameMode becomes $CC, and after rounds 10, 20 and 30 a cutscene or the ending follows. A secret
;@ mode switches itself off after an odd round and raises wHomingLevel.
;@ Link game: the round counts up to 10 (binary); clearing the 10th wins. The clearing side
;@ sends $CA until the other side answers $DD; a side that receives $CA shows "YOUR ENEMY
;@ CLEARED" and both wait for each other. $CE (a win) or $EA (a loss) from the other side are
;@ handled by LinkCheckResult.
;@ writes: hGameMode, hRound, hRoundFlags, hSerialOut, wCheatFlags, wHomingLevel, wKillCodeFlags
;@ reads: hInvadersLeft, hLinkFlags, hRound, hRoundFlags, hSerialIn, wCheatFlags, wHomingLevel, wKillCodeFlags
;@ test: skip waits for serial transfers and runs busy-wait delays
;@ sig: 718067c3
CheckRoundClear::
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>     if hInvadersLeft != 0:
;>         return
	ldh a, [hInvadersLeft]
	and a
	jp nz, CheckRoundClearDone

;>     hRound = to_bcd(bcd_to_int(hRound) + 1)
	ldh a, [hRound]
	inc a
	daa
	ldh [hRound], a
;>     hGameMode = 0xCC                  # round cleared
	ld a, $cc
	ldh [hGameMode], a
;>     if wCheatFlags & 0xFC:            # a secret mode is on
	ld a, [wCheatFlags]
	ld c, a
	and $fc
	and a
	jr z, .killCode

;>         if hRound & 0x01:             # and the new round is odd
	ldh a, [hRound]
	bit 0, a
	jr z, .killCode

;>             wHomingLevel += 1
	ld a, [wHomingLevel]
	inc a
	ld [wHomingLevel], a
;>             wCheatFlags &= 0x03
	ld a, c
	and $03
	ld [wCheatFlags], a

.killCode
;>     if wKillCodeFlags != 0:
	ld a, [wKillCodeFlags]
	and a
	jr z, .wait

;>         wKillCodeFlags = 0
	xor a
	ld [wKillCodeFlags], a

.wait
;>     Delay(0x40)
	ld d, $40
	call Delay
;>     if hRound == 0x11:
;>         return ShowCoffeeBreak1()     # a jump: after round 10
	ldh a, [hRound]
	cp $11
	jp z, ShowCoffeeBreak1

;>     if hRound == 0x21:
;>         return ShowCoffeeBreak2()     # after round 20
	cp $21
	jp z, ShowCoffeeBreak2

;>     if hRound == 0x31:
;>         return ShowEnding()           # after round 30
	cp $31
	jp z, ShowEnding

;>     return
	jp CheckRoundClearDone


.link
;> if hSerialIn == 0xCA:                 # the other side cleared its round
;>     return ShowEnemyCleared()         # a jump
	ldh a, [hSerialIn]
	cp $ca
	jr z, ShowEnemyCleared

;> if hSerialIn == 0xCE or hSerialIn == 0xEA:
;>     return LinkCheckResult()          # a jump
	cp $ce
	jp z, LinkCheckResult

	cp $ea
	jp z, LinkCheckResult

;> if hInvadersLeft != 0:
;>     return
	ldh a, [hInvadersLeft]
	and a
	jp nz, CheckRoundClearDone

;> if not hRoundFlags & 0x01:            # count the round only once
	ldh a, [hRoundFlags]
	bit 0, a
	jr nz, .announce

;>     if hRound + 1 == 11:              # ten rounds cleared: we win
;>@win         hSerialOut = 0xCE
;>@wj         return LinkWin()          # a jump
	ldh a, [hRound]
	inc a
	cp $0b
	jr z, .win

;>     hRound += 1
	ldh [hRound], a
;>     hRoundFlags |= 0x01
	ldh a, [hRoundFlags]
	set 0, a
	ldh [hRoundFlags], a

.announce
;>@ann while True:
;>     hSerialOut = 0xCA                 # "I cleared my round"
	ld a, $ca
	ldh [hSerialOut], a
;>     hGameMode = 0xCC
	ld a, $cc
	ldh [hGameMode], a
;>     if hSerialIn == 0xCA:             # both cleared at the same time
;>         return ShowEnemyCleared()
	ldh a, [hSerialIn]
	cp $ca
	jp z, ShowEnemyCleared

;>     if hSerialIn == 0xCE or hSerialIn == 0xEA:
;>         return LinkCheckResult()
	cp $ce
	jp z, LinkCheckResult

	cp $ea
	jp z, LinkCheckResult

;>     if hSerialIn == 0xDD:             # the other side has seen it
;>         return
	cp $dd
;=@ann
	jr nz, .announce

	jp CheckRoundClearDone


.win
;=@win
	ld a, $ce
	ldh [hSerialOut], a
;=@wj
	jp LinkWin


;@ def ShowEnemyCleared()
;@ path: link/round
;@ Link game: the other side has cleared its round. Shows "YOUR / ENEMY / CLEARED" in sprites,
;@ takes the other cannon off the screen, waits for the other Game Boy and removes the text;
;@ then play goes on.
;@ writes: hGameMode, hSerialOut, hTemp
;@ reads: hTemp
;@ test: skip waits for serial transfers
;@ sig: e5fbd66e
ShowEnemyCleared::
;> hSerialOut = 0xC4
	ld a, $c4
	ldh [hSerialOut], a
;> rBGP = 0x54                       # lighter shades
	and $54
	ldh [rBGP], a
;> rOBP0 = 0x54
	ldh [rOBP0], a
;> text = TextYourEnemyCleared                     # "YOUR" / "ENEMY" / "CLEARED", each line ends with $FF
	ld de, TextYourEnemyCleared
;> oam = 0xC050                      # sprites 20-36
	ld h, $c0
	ld l, $50
;> y = 0x40
	ld b, $40
;> x = 0x40
	ld c, $40
;>@line for line in range(3):
	ld a, $03

.line
	ldh [hTemp], a

;>@chr     while mem[text] != 0xFF:
.char
	ld a, [de]
	cp $ff
	jr z, .nextLine

;>         mem[oam] = y
	ld a, b
	ld [hli], a
;>         mem[oam + 1] = x
	ld a, c
	ld [hli], a
;>         mem[oam + 2] = mem[text]
	ld a, [de]
	ld [hli], a
;>         mem[oam + 3] = 0x10       # palette OBP1
	ld a, $10
	ld [hli], a
;>         oam += 4
;>         text += 1
	inc de
;>         x += 8
	ld a, $08
	add c
	ld c, a
;=@chr
	jr .char

.nextLine
;>     y += 0x10
	ld a, b
	add $10
	ld b, a
;>     x = 0x40
	ld c, $40
;>     text += 1                     # skip the $FF
	inc de
;=@line
	ldh a, [hTemp]
	dec a
	jr nz, .line

;> hUfoFlags &= ~0x02                # the other cannon leaves the screen
	ld hl, hUfoFlags
	res 1, [hl]
;> LinkSync()
	call LinkSync
;> oam = 0xC050
	ld h, $c0
	ld l, $50
;>@clr for i in range(17):           # remove the text
	ld c, $11
	and $00

.clear
;>     fill(oam, 0, 4)
;>     oam += 4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
;=@clr
	dec c
	jr nz, .clear

;> hGameMode = 0x55
	ld a, $55
	ldh [hGameMode], a
;> rBGP = 0xE4
	ld a, $e4
	ldh [rBGP], a
;> rOBP0 = 0xE4
	ldh [rOBP0], a

CheckRoundClearDone:
	ret


;@ def CheckInvaded()
;@ path: game/over
;@ Ends the game when the invaders have landed (bit 7 of hLinkFlags): the cannon blinks and
;@ GameOver follows. A link game checks the other side's result instead (LinkCheckResult).
;@ writes: hSfxRequest2
;@ reads: hLinkFlags
;@ test: skip runs the game-over sequence with busy-wait delays
;@ sig: 9a5ab082
CheckInvaded::
;> if hLinkFlags & 0x01:
;>     return LinkCheckResult()          # a jump
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, LinkCheckResult

;> if not hLinkFlags & 0x80:             # not landed
;>     return
	bit 7, a
	jr z, CheckInvadedDone

;> hSfxRequest2 = 0x0B
	ld a, $0b
	ldh [hSfxRequest2], a
;> BlinkCannon()
	call BlinkCannon
;> GameOver()                            # falls through

;@ def GameOver()
;@ path: game/over
;@ One-player game over: shows the GAME OVER screen, waits, fades the background out in three
;@ steps and sets hGameMode to $EE. In a link game a lost game is LinkLose instead.
;@ writes: hGameMode, hLinkFlags, hRoundFlags
;@ reads: hLinkFlags, hRoundFlags
;@ test: skip draws the screen with the LCD off and runs busy-wait delays
;@ sig: df9c6516
GameOver::
;> if hLinkFlags & 0x01:
;>     return LinkLose()                 # a jump
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, LinkLose

;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> LcdOffClear()
	call LcdOffClear
;> DrawTilemapList(GameOverMap)               # the GAME OVER screen
	ld de, GameOverMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> Delay(0x80)
	ld d, $80
	call Delay
;>@fade for i in range(3):               # $E4 -> $90 -> $40 -> $00: fade to white
	ld c, $03
	ld hl, rBGP

.fade
;>     rBGP = (rBGP << 2) & 0xFF
	sla [hl]
	sla [hl]
;>     Delay(0x20)
	ld d, $20
	call Delay
;=@fade
	dec c
	jr nz, .fade

;> hRoundFlags &= ~0x80
	ldh a, [hRoundFlags]
	res 7, a
	ldh [hRoundFlags], a
;> hLinkFlags &= ~0x80
	ldh a, [hLinkFlags]
	res 7, a
	ldh [hLinkFlags], a
;> hGameMode = 0xEE                      # game over
	ld a, $ee
	ldh [hGameMode], a

CheckInvadedDone:
	ret


;@ def LinkCheckResult()
;@ path: link/result
;@ Link game, every frame: $EA from the other side means it lost (we win), $CE means it won (we
;@ lose); our own invaders landing also loses.
;@ reads: hLinkFlags, hSerialIn
;@ test: skip runs the link result screens
;@ sig: 298370b3
LinkCheckResult::
;> if hSerialIn == 0xEA:
;>     return LinkWin()                  # a jump
	ldh a, [hSerialIn]
	cp $ea
	jr z, LinkWin

;> if hSerialIn == 0xCE:
;>     return LinkLose()                 # a jump
	cp $ce
	jr z, LinkLose

;> if not hLinkFlags & 0x80:
;>     return
	ldh a, [hLinkFlags]
	bit 7, a
	jr z, CheckInvadedDone

;> LinkLose()                            # falls through

;@ def LinkLose()
;@ path: link/result
;@ We lost the link game: sends $EA, blinks the cannon and shows the loser's screen; hGameMode
;@ $44 then goes back to the title. If the other side has just lost too, it counts as our win.
;@ writes: hGameMode, hLinkFlags, hSerialOut
;@ reads: hLinkFlags, hSerialIn
;@ test: skip runs the link result screens
;@ sig: 47fc68d5
LinkLose::
;> if hSerialIn == 0xEA:
;>     return LinkWin()                  # a jump
	ldh a, [hSerialIn]
	cp $ea
	jr z, LinkWin

;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> hSerialOut = 0xEA                     # "I lost"
	ld a, $ea
	ldh [hSerialOut], a
;> BlinkCannon()
	call BlinkCannon
;> ShowLinkLoss()
	call ShowLinkLoss
;> hGameMode = 0x44
	ld a, $44
	ldh [hGameMode], a
;> return
	jp CheckInvadedDone


;@ def LinkWin()
;@ path: link/result
;@ We won the link game: sends $CE, shows the other cannon exploding and the winner's screen;
;@ hGameMode $44 then goes back to the title. If the other side has won too, it counts as our
;@ loss.
;@ writes: hGameMode, hLinkFlags, hSerialOut
;@ reads: hLinkFlags, hSerialIn
;@ test: skip runs the link result screens
;@ sig: 4ed3e610
LinkWin::
;> if hSerialIn == 0xCE:
;>     return LinkLose()                 # a jump
	ldh a, [hSerialIn]
	cp $ce
	jr z, LinkLose

;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> hSerialOut = 0xCE                     # "I won"
	ld a, $ce
	ldh [hSerialOut], a
;> FlashOpponentExplosion()
	call FlashOpponentExplosion
;> ShowLinkWin()
	call ShowLinkWin
;> hGameMode = 0x44
	ld a, $44
	ldh [hGameMode], a
;> return
	jp CheckInvadedDone


;@ def UpdateHiScore()
;@ path: score/hiscore
;@ One-player game over: if the score reaches the hi-score it becomes the new hi-score, and the
;@ HI-SCORE screen fades in with a jingle, stays a moment and fades out (not when the game ended
;@ from the pause, hGameMode $AA).
;@ writes: hHiScoreHi, hHiScoreLo, hLinkFlags, hSfxRequest2
;@ reads: hGameMode, hHiScoreLo, hLinkFlags, hScoreHi, hScoreLo
;@ test: skip draws a screen with the LCD off and runs busy-wait delays
;@ sig: 164c7375
UpdateHiScore::
;> if hLinkFlags & 0x01:
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .done

;> if hScoreHi < hHiScoreHi:
;>     return
	ld hl, hHiScoreHi
	ldh a, [hScoreHi]
	sub [hl]
	jr c, .done

;> if hScoreHi == hHiScoreHi and hScoreLo < hHiScoreLo:
;>     return                            # (an equal score counts as a new hi-score)
	jr nz, .newHiScore

	ld hl, hScoreLo
	ldh a, [hHiScoreLo]
	sub [hl]
	jr z, .newHiScore

	jr nc, .done

.newHiScore
;> hHiScoreLo = hScoreLo
	ldh a, [hScoreLo]
	ldh [hHiScoreLo], a
;> hHiScoreHi = hScoreHi
	ldh a, [hScoreHi]
	ldh [hHiScoreHi], a
;> if hGameMode == 0xAA:
;>     return
	ldh a, [hGameMode]
	cp $aa
	jr z, .done

;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> LcdOffClear()
	call LcdOffClear
;> rSCX = 0
	and $00
	ldh [rSCX], a
;> DrawTilemapList(HiScoreMap)               # the HI-SCORE screen
	ld de, HiScoreMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> rBGP = 0
	and $00
	ldh [rBGP], a
;> rOBP0 = 0
	ldh [rOBP0], a
;> rOBP1 = 0
	ldh [rOBP1], a
;> rBGP = 0x40                           # fade in
	ld a, $40
	ldh [rBGP], a
;> Delay(0x10)
	ld d, $10
	call Delay
;> rBGP = 0x90
	ld a, $90
	ldh [rBGP], a
;> Delay(0x10)
	ld d, $10
	call Delay
;> rBGP = 0xE4
	ld a, $e4
	ldh [rBGP], a
;> hSfxRequest2 = 0x13                   # jingle
	ld a, $13
	ldh [hSfxRequest2], a
;> Delay(0x40)
	ld d, $40
	call Delay
;>@fade for i in range(3):               # fade out
	ld c, $03
	ld hl, rBGP

.fade
;>     rBGP = (rBGP << 2) & 0xFF
	sla [hl]
	sla [hl]
;>     Delay(0x10)
	ld d, $10
	call Delay
;=@fade
	dec c
	jr nz, .fade

.done
	ret


;@ def FrameDelay()
;@ path: game/main
;@ Paces the game loop with a busy wait: a short one in a link game (the serial exchange slows
;@ it down already), three times as long in a one-player game.
;@ reads: hLinkFlags
;@ test: skip busy-wait delay
;@ sig: 6628fd0f
FrameDelay::
;> Delay(0x01)
	ld d, $01
	call Delay
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .done

;>     Delay(0x02)
	ld d, $02
	call Delay

.done
	ret


;@ def HandlePlayEnd()
;@ path: game/main
;@ Where the game goes when a round stops: $CC (round cleared) starts the next round; $AA and
;@ $EE (game over) check the hi-score and restart; $44 restarts at once (Start, keeping the
;@ hi-score with hGameMode $BB); anything else goes back to the title.
;@ writes: hGameMode
;@ reads: hGameMode
;@ test: skip never returns
;@ sig: 5c9c9ba5
HandlePlayEnd::
;> if hGameMode == 0x44:
	ldh a, [hGameMode]
	cp $44
	jr z, .restart

;>     pass                              # straight to the restart
;>@ae elif hGameMode == 0xAA or hGameMode == 0xEE:
	cp $aa
	jr z, .hiScore

;>@hs     UpdateHiScore()
;> elif hGameMode == 0xCC:               # round cleared
	cp $cc
	jr z, .nextRound

;=@ae
	cp $ee
	jr z, .hiScore

;>@sr     return StartRound()             # a jump
;> else:
;>     return TitleAndMenu()             # a jump
	jp TitleAndMenu


.nextRound
;=@sr
	jp StartRound


.hiScore
;=@hs
	call UpdateHiScore

.restart
;> hGameMode = 0xBB                      # restart, keep the hi-score
	ld a, $bb
	ldh [hGameMode], a
;> return Start()                        # a jump
	jp Start


;@ def InitRoundState()
;@ path: game/round
;@ Resets the round's flags and points, puts the cannon at the left edge, sends $AA and removes
;@ all shots and bombs.
;@ writes: hPointsToAdd, hRoundFlags, hSerialOut, hSoundOff, hUfoFlags, hUfoHitTimer, wCannonLeftTile, wCannonRightTile, wCannonRightX, wCannonSpriteX
;@ test: skip calls RemoveAllShots
;@ sig: 75e0dd09
InitRoundState::
;> hRoundFlags = 0
	ld a, $00
	ldh [hRoundFlags], a
;> hUfoFlags = 0
	ldh [hUfoFlags], a
;> hUfoHitTimer = 0
	ldh [hUfoHitTimer], a
;> hPointsToAdd = 0
	ldh [hPointsToAdd], a
;> wCannonLeftTile = 0
	ld [wCannonLeftTile], a
;> wCannonRightTile = 0
	ld [wCannonRightTile], a
;> wCannonSpriteX = 0x10
	ld a, $10
	ld [wCannonSpriteX], a
;> wCannonRightX = 0x18
	add $08
	ld [wCannonRightX], a
;> hSerialOut = 0xAA
	ld a, $aa
	ldh [hSerialOut], a
;> RemoveAllShots()
	call RemoveAllShots
;> hSoundOff = 1
	ld a, $01
	ldh [hSoundOff], a
	ret


;@ def Delay(d: d)
;@ path: system/delay
;@ Busy wait: counts a 16-bit counter up until its high byte equals d, 256 * d passes of 15
;@ machine cycles, about 3.7 ms per unit of d (Delay(1) is about a fifth of a frame).
;@ Keeps all registers.
;@ test: d = rand(1, 3)
;@ sig: 00c57005
Delay::
;> count = 0
	push hl
	push de
	push af
	ld hl, $0000

;>@loop while True:
.loop
;>     count += 1
	inc hl
;>     # seven nops make one pass 15 machine cycles long
	nop
	nop
	nop
	nop
;>     if (count >> 8) == d:
;>         break
	nop
	nop
	nop
	ld a, h
	cp d
;=@loop
	jp nz, .loop

	pop af
	pop de
	pop hl
	ret


;@ def WaitTimerTicks(n: d)
;@ path: unused
;@ Would wait n times until hTimerHi reaches $80 (about 2 minutes each). Nothing calls it.
;@ writes: hTimerHi
;@ reads: hTimerHi
;@ test: skip waits for the VBlank counter
;@ sig: 09b9c33a
WaitTimerTicks::
;>@tick for i in range(n):
;>     hTimerHi = 0
	and $00
	ldh [hTimerHi], a

;>     while not hTimerHi & 0x80:        # VBlank counts it up
;>         wait_vblank_flag()
.wait
	ldh a, [hTimerHi]
	bit 7, a
	jr z, .wait

;=@tick
	dec d
	jr nz, WaitTimerTicks

	ret


;@ def DrawRoundsLeft()
;@ path: link/round
;@ Link game: shows how many of the ten rounds are left (10 - hRound) as one digit sprite, in the
;@ place of the last score digit.
;@ reads: hRound
;@ test: hRound = rand(1, 10)
;@ sig: eaa44c8d
DrawRoundsLeft::
;> hTemp = hRound
	ld hl, hTemp
	ldh a, [hRound]
	ld [hl], a
;> WriteDigitTile(0xC036, 10 - hRound)
	ld a, $0a
	sub [hl]
	ld hl, $c036
	call WriteDigitTile
	ret


;@ def WriteDigitTile(ptr: hl, value: a)
;@ path: score/digits
;@ Writes the digit tile of the low nibble of value ($80-$89 are the digits 0-9) to ptr,
;@ usually the tile byte of a sprite.
;@ test: ptr = rand(0xC000, 0xC09F)
;@ sig: c35af192
WriteDigitTile::
;> mem[ptr] = 0x80 + (value & 0x0F)
	and $0f
	add $80
	ld [hl], a
	ret


;@ def InitUfoTimer()
;@ path: ufo/timer
;@ Starts the VBlank counter at $EC00, so that hTimerHi reaches $14 (the UFO's first appearance)
;@ after about 43 seconds.
;@ writes: hTimerHi, hTimerLo
;@ sig: 17adb959
InitUfoTimer::
;> hTimerHi = 0xEC
	ld a, $ec
	ldh [hTimerHi], a
;> hTimerLo = 0x00
	xor a
	ldh [hTimerLo], a
	ret


;@ def LcdOffClear()
;@ path: system/lcd
;@ With interrupts off: switches the screen off, fills the background map with blank tiles and
;@ silences the sound. LcdOn switches everything on again.
;@ writes: hSoundOff
;@ test: skip switches the LCD off
;@ sig: e04ef62e
LcdOffClear::
;> disable_interrupts()
	di
;> LcdOff()
	call LcdOff
;> ClearBgMap()
	call ClearBgMap
;> hSoundOff = 1
	ld a, $01
	ldh [hSoundOff], a
	ret


;@ def LcdOn()
;@ path: system/lcd
;@ Clears the sprites, sets the palettes (inverted with the secret code), resets the VRAM hooks,
;@ enables the interrupts of hIEMask (LCD STAT at HBlank) and switches the screen on: background
;@ and sprites, map $9800, background tiles from $8800.
;@ writes: hLcdHook, hMainHook, hShieldUpload, hUnusedFF95
;@ reads: hIEMask, wCheatFlags
;@ test: wCheatFlags = rand(0, 255)
;@ test: hIEMask = rng.choice([0x0F, 0x0D])
;@ sig: 248c1ce0
LcdOn::
;> ClearShadowOam()
	call ClearShadowOam
;> palette = 0xE4
	ld a, [wCheatFlags]
	ld c, a
	ld a, $e4
;> if not wCheatFlags & 0x80 and wCheatFlags & 0x01:
	bit 7, c
	jr nz, .setPalettes

	bit 0, c
	jr z, .setPalettes

;>     palette = 0x1B                    # inverted
	cpl

.setPalettes
;> rBGP = palette
	ldh [rBGP], a
;> rOBP0 = palette
	ldh [rOBP0], a
;> rOBP1 = palette
	ldh [rOBP1], a
;> rSTAT = 0x08                          # the STAT interrupt fires at HBlank
	ld a, $08
	ldh [rSTAT], a
;> hLcdHook = 0
	xor a
	ldh [hLcdHook], a
;> hMainHook = 0
	ldh [hMainHook], a
;> hUnusedFF95 = 0
	ldh [hUnusedFF95], a
;> hShieldUpload = 0
	ldh [hShieldUpload], a
;> rIF = 0
	ldh [rIF], a
;> rIE = hIEMask
	ldh a, [hIEMask]
	ldh [rIE], a
;> rLCDC = 0x83                          # screen on
	ld a, $83
	ldh [rLCDC], a
;> enable_interrupts()
	ei
	ret


;@ def RunVBlankHook(hook: a)
;@ path: system/vblank
;@ Runs the VBlank hook in hMainHook (part of VBlankHandler, entered with a = hMainHook). Any
;@ value but $FF is the low byte of a routine at $00xx (VBlankWriteTilePair ...), run once.
;@ $FF is the screen wipe of a link game: with all palettes white it clears one background row
;@ per frame (18 rows), then draws the top-row labels "E-", "RD-" and "S-" (enemy cannons,
;@ rounds left, own cannons; the numbers are sprites), and finally restores the palettes and
;@ ends itself.
;@ writes: hMainHook, hShieldUploadDstHi, hShieldUploadDstLo, hWipeRow
;@ reads: hShieldUploadDstHi, hShieldUploadDstLo, hWipeRow
;@ test: skip part of the VBlank interrupt handler
;@ sig: 6c783adc
RunVBlankHook::
;> if hook != 0xFF:
	ld l, a
	cp $ff
	jr z, .wipe

;>     hMainHook = 0
	xor a
	ld h, a
	ldh [hMainHook], a
;>     return (0x0000 + hook)()          # a jump: the hook ends with a jump to VBlankDone
	jp hl


.wipe
;> rBGP = 0
	and $00
	ldh [rBGP], a
;> rOBP0 = 0
	ldh [rOBP0], a
;> rOBP1 = 0
	ldh [rOBP1], a
;> if hWipeRow < 18:
	ldh a, [hWipeRow]
	cp $12
	jr nc, .labels

;>     addr = (hShieldUploadDstHi << 8) | hShieldUploadDstLo
	ld b, a
	ldh a, [hShieldUploadDstHi]
	ld h, a
	ldh a, [hShieldUploadDstLo]
	ld l, a
;>     fill(addr, 0xA4, 20)              # one row of the screen, blank
	ld c, $14
	ld a, $a4

.clearRow
	ld [hli], a
	dec c
	jr nz, .clearRow

;>     addr += 0x20                      # the next row of the map
	ld a, l
	sub $14
	ld l, a
	ld de, $0020
	add hl, de
;>     hWipeRow += 1
	inc b
	ld a, b
	ldh [hWipeRow], a
;>     hShieldUploadDstHi = addr >> 8
	ld a, h
	ldh [hShieldUploadDstHi], a
;>     hShieldUploadDstLo = addr & 0xFF
	ld a, l
	ldh [hShieldUploadDstLo], a
;>     return VBlankDone()               # a jump
	jp VBlankDone


.labels
;> elif hWipeRow == 18:
	ldh a, [hWipeRow]
	cp $12
	jr nz, .finish

;>     hWipeRow = 19
	inc a
	ldh [hWipeRow], a
;>     mem[0x9802] = 0x8E                # "E"
	ld b, $b6
	ld hl, $9802
	ld a, $8e
	ld [hli], a
;>     mem[0x9803] = 0xB6                # "-"
	ld a, b
	ld [hli], a
;>     mem[0x9808] = 0x9B                # "R"
	inc l
	inc l
	inc l
	inc l
	ld a, $9b
	ld [hli], a
;>     mem[0x9809] = 0x8D                # "D"
	ld a, $8d
	ld [hli], a
;>     mem[0x980A] = 0xB6                # "-"
	ld a, b
	ld [hli], a
;>     mem[0x980F] = 0x9C                # "S"
	inc l
	inc l
	inc l
	inc l
	ld a, $9c
	ld [hli], a
;>     mem[0x9810] = 0xB6                # "-"
	ld a, b
	ld [hli], a
;>     return VBlankDone()
	jp VBlankDone


.finish
;> else:
;>     rBGP = 0xE4
	ld a, $e4
	ldh [rBGP], a
;>     rOBP0 = 0xE4
	ldh [rOBP0], a
;>     rOBP1 = 0xE4
	ldh [rOBP1], a
;>     hMainHook = 0                     # the wipe is over
	xor a
	ldh [hMainHook], a
;>     return VBlankDone()
	jp VBlankDone


;@ def VBlankHandler()
;@ path: system/vblank
;@ The VBlank interrupt. Every second frame it loads the next link byte and (as the master)
;@ starts the transfer; it hands the highest-priority sound request to the sound engine, copies
;@ the sprites to OAM, counts the frame and the 16-bit timer, runs the VBlank hook if one is set,
;@ and in a one-player game uploads one tile of the shields from RAM to VRAM.
;@ writes: hFrameCounter, hMarchSfxRequest, hSerialFrame, hSfxRequest, hSfxRequest2, hShieldUploadDstHi, hShieldUploadDstLo, hShieldUploadSrcHi, hShieldUploadSrcLo, hShieldUploadTile, hSoundOff, hTimerHi, hTimerLo, wSoundQueue, wSoundQueuePos
;@ reads: hFrameCounter, hLinkFlags, hMainHook, hMarchSfxRequest, hSerialFrame, hSerialOut, hSfxRequest, hSfxRequest2, hShieldUpload, hShieldUploadDstHi, hShieldUploadDstLo, hShieldUploadSrcHi, hShieldUploadSrcLo, hShieldUploadTile, hSoundOff, hSyncFlags, hTimerHi, hTimerLo
;@ test: skip interrupt handler (ends in reti)
;@ sig: b5c8c2ae
VBlankHandler::
;> # (all registers are saved)
	push af
	push hl
	push bc
	push de
;> if not rSC & 0x80 and not hSyncFlags & 0x02:   # no transfer running, sending allowed
	ldh a, [rSC]
	bit 7, a
	jr nz, .sound

	ldh a, [hSyncFlags]
	bit 1, a
	jr nz, .sound

;>     hSerialFrame += 1
	ldh a, [hSerialFrame]
	inc a
	ldh [hSerialFrame], a
;>     if hSerialFrame % 2 == 0:
	bit 0, a
	jr nz, .sound

;>         rSB = hSerialOut
	ldh a, [hSerialOut]
	ldh [rSB], a
;>         if hSyncFlags & 0x01:         # the master starts the transfer
	ldh a, [hSyncFlags]
	bit 0, a
	jr z, .sound

;>             hSyncFlags &= ~0x80
	ld hl, hSyncFlags
	res 7, [hl]
;>             rSC |= 0x80
	ld hl, rSC
	set 7, [hl]

.sound
;> if hSoundOff:
	ld b, $00
	ldh a, [hSoundOff]
	and a
	jr nz, .silence

;>@off     wSoundQueue[1] = 0; wSoundQueuePos = 0; hSoundOff = 0   # "sound 0" silences the channels
;>@offp     PlayQueuedSound()
;> elif hMarchSfxRequest != 0:
	ldh a, [hMarchSfxRequest]
	and a
	jr z, .sfx

;>     wSoundQueue[1] = hMarchSfxRequest
	ld [wSoundQueue + 1], a
;>     wSoundQueuePos = 0                # entry 1 now differs from wSoundQueueEnd: play it
	ld a, b
	ld [wSoundQueuePos], a
;>     hMarchSfxRequest = 0
	ldh [hMarchSfxRequest], a
;>     PlayQueuedSound()                 # (through the shared call below)
	jr .play

.sfx
;> elif hSfxRequest != 0:
	ldh a, [hSfxRequest]
	and a
	jr z, .sfx2

;>     wSoundQueue[1] = hSfxRequest
	ld [wSoundQueue + 1], a
;>     wSoundQueuePos = 0
	ld a, b
	ld [wSoundQueuePos], a
;>     hSfxRequest = 0
	ldh [hSfxRequest], a
;>     PlayQueuedSound()
	jr .play

.sfx2
;> elif hSfxRequest2 != 0:
	ldh a, [hSfxRequest2]
	and a
	jr z, .dma

;>     wSoundQueue[1] = hSfxRequest2
	ld [wSoundQueue + 1], a
;>     wSoundQueuePos = 0
	ld a, b
	ld [wSoundQueuePos], a
;>     hSfxRequest2 = 0
	ldh [hSfxRequest2], a
;>     PlayQueuedSound()
	jr .play

.silence
;=@off
	xor a
	ld [wSoundQueue + 1], a
	ld [wSoundQueuePos], a
	ldh [hSoundOff], a

.play
;=@offp
	call PlayQueuedSound

.dma
;> hOamDma()                             # copy wShadowOam to OAM
	call hOamDma
;> hFrameCounter += 1
	ldh a, [hFrameCounter]
	inc a
	ldh [hFrameCounter], a
;> timer = ((hTimerHi << 8) | hTimerLo) + 4
	ldh a, [hTimerHi]
	ld h, a
	ldh a, [hTimerLo]
	ld l, a
	ld de, $0004
	add hl, de
;> hTimerLo = timer & 0xFF
	ld a, l
	ldh [hTimerLo], a
;> hTimerHi = (timer >> 8) & 0xFF
	ld a, h
	ldh [hTimerHi], a
;> if hMainHook != 0:
;>     return RunVBlankHook(hMainHook)   # a jump
	ldh a, [hMainHook]
	and a
	jp nz, RunVBlankHook

;> if hLinkFlags & 0x01 or hShieldUpload == 0:
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, VBlankDone

	ldh a, [hShieldUpload]
	and a
	jr z, VBlankDone

;> dst = (hShieldUploadDstHi << 8) | hShieldUploadDstLo
	ldh a, [hShieldUploadDstHi]
	ld h, a
	ldh a, [hShieldUploadDstLo]
	ld l, a
;> src = (hShieldUploadSrcHi << 8) | hShieldUploadSrcLo
	ldh a, [hShieldUploadSrcHi]
	ld d, a
	ldh a, [hShieldUploadSrcLo]
	ld e, a
;> tile = hShieldUploadTile + 1
	ldh a, [hShieldUploadTile]
	inc a
;> if tile == 6:                         # all six tiles of this shield done
	cp $06
	jr nz, .sameShield

;>     src = (src & 0xFF00) + 0x100      # the next shield's RAM copy
	inc d
	ld e, $00
;>     if src == 0xD700:                 # after the fourth shield start again
	ld a, d
	cp $d7
	jr nz, .tileZero

;>         dst = 0x95A0                  # VRAM of tile $5A, the first shield tile
	ld h, $95
	ld l, $a0
;>         src = 0xD300
	ld d, $d3

.tileZero
;>     tile = 0
	xor a

.sameShield
;> hShieldUploadTile = tile
	ldh [hShieldUploadTile], a
;>@cp for i in range(16):             # one tile, 16 bytes (src only steps its low byte)
;>     mem[dst + i] = mem[src + i]
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;=@cp
	ld a, [de]
	inc e
	ld [hli], a
;> hShieldUploadDstHi = (dst + 16) >> 8  # both pointers have moved on by one tile
	ld a, h
	ldh [hShieldUploadDstHi], a
;> hShieldUploadDstLo = (dst + 16) & 0xFF
	ld a, l
	ldh [hShieldUploadDstLo], a
;> hShieldUploadSrcHi = src >> 8
	ld a, d
	ldh [hShieldUploadSrcHi], a
;> hShieldUploadSrcLo = (src + 16) & 0xFF
	ld a, e
	ldh [hShieldUploadSrcLo], a

VBlankDone:
;> return                                # registers restored, reti
	pop de
	pop bc
	pop hl
	pop af
	reti


;@ def MoveCannonAndFire()
;@ path: player/move
;@ Moves the cannon one pixel per frame with Left/Right between X $10 and $90 and sends its
;@ position to the link partner. A or B fires: sends $F5 and, if no shot is flying, launches
;@ one from the cannon with a sound that depends on where the cannon is, and counts the shot
;@ (hShotCount 1-15, which picks the UFO's score). Secret: B while holding Down+Select, with the
;@ UFO on screen in a one-player game, makes the shot home in on the UFO.
;@ writes: hActiveShots, hSerialOut, hSfxRequest2, hShotCount, wCannonRightX, wCannonSpriteX, wCheatFlags, wShotSpriteX, wShotSpriteY
;@ reads: hActiveShots, hJoyHeld, hJoyPressed, hLinkFlags, hShotCount, hUfoFlags, wCannonSpriteX, wCheatFlags
;@ test: hJoyHeld = rand(0, 255)
;@ test: hJoyPressed = rand(0, 255)
;@ test: wCannonSpriteX = rand(0x10, 0x90)
;@ test: hShotCount = rand(0, 15)
;@ sig: e91adae7
MoveCannonAndFire::
;> shots = hActiveShots                  # (read once, before the cannon moves)
	ldh a, [hJoyHeld]
	ld b, a
	ld a, [wCannonSpriteX]
	ld d, a
	ldh a, [hActiveShots]
	ld e, a
;> if hJoyHeld & 0x20:                   # Left
	bit 5, b
	jr z, .notLeft

;>     if wCannonSpriteX != 0x10:
	ld a, d
	cp $10
	jr z, .moved

;>         wCannonSpriteX -= 1
;>@lset         wCannonRightX = wCannonSpriteX + 8   # (through the code shared with Right)
	dec a
;=@lset
	jr .setX

.notLeft
;> elif hJoyHeld & 0x10:                 # Right
	bit 4, b
	jr z, .moved

;>     if wCannonSpriteX != 0x90:
	ld a, d
	cp $90
	jr z, .moved

;>         wCannonSpriteX += 1
	inc a

.setX
;>         wCannonRightX = wCannonSpriteX + 8
	ld [wCannonSpriteX], a
	add $08
	ld [wCannonRightX], a

.moved
;> hSerialOut = wCannonSpriteX           # our cannon's position for the other Game Boy
	ld a, [wCannonSpriteX]
	ldh [hSerialOut], a
;> if not hJoyPressed & 0x01:            # not A
	ldh a, [hJoyPressed]
	bit 0, a
	jr nz, .fire

;>     if not hJoyPressed & 0x02:        # not B either
;>         return
	bit 1, a
	jr z, .done

;>     if not hLinkFlags & 0x01 and hUfoFlags & 0x02:   # one player, UFO on screen
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .fire

	ldh a, [hUfoFlags]
	bit 1, a
	jr z, .fire

;>         if not wCheatFlags & 0x80:
	ld a, [wCheatFlags]
	bit 7, a
	jp nz, .fire

;>             if hJoyHeld & 0x86 == 0x86:   # Down + Select + B
	ldh a, [hJoyHeld]
	and $86
	cp $86
	jr nz, .fire

;>                 wCheatFlags |= 0x40   # the shot homes in on the UFO
	ld a, [wCheatFlags]
	set 6, a
	ld [wCheatFlags], a

.fire
;> hSerialOut = 0xF5                     # "I fired"
	ld a, $f5
	ldh [hSerialOut], a
;> if shots & 0x01:                      # a shot is already flying
;>     return
	bit 0, e
	jr nz, .done

;> hActiveShots |= 0x01
	ldh a, [hActiveShots]
	set 0, a
	ldh [hActiveShots], a
;> wShotSpriteY = 0x9B                   # just above the cannon
	ld a, $9b
	ld [wShotSpriteY], a
;> if wCannonSpriteX < 0x35:
	ld a, [wCannonSpriteX]
	cp $35
	jr c, .leftThird

;>@lefts     hSfxRequest2 = 0x05           # shot sound, left part of the screen
;> elif wCannonSpriteX < 0x64:
	cp $64
	jr c, .middle

;>@mids     hSfxRequest2 = 0x06
;> else:
;>     hSfxRequest2 = 0x07
	ld a, $07
	ldh [hSfxRequest2], a
	jr .shotX

.middle
;=@mids
	ld a, $06
	ldh [hSfxRequest2], a
	jr .shotX

.leftThird
;=@lefts
	ld a, $05
	ldh [hSfxRequest2], a

.shotX
;> wShotSpriteX = wCannonSpriteX + 4
	ld a, [wCannonSpriteX]
	add $04
	ld [wShotSpriteX], a
;> hShotCount = (hShotCount + 1) & 0x0F
	ldh a, [hShotCount]
	inc a
	and $0f
;> if hShotCount == 0:                   # counts 1-15
;>     hShotCount = 1
	jr nz, .count

	inc a

.count
	ldh [hShotCount], a

.done
	ret


;@ def CannonHit()
;@ path: player/hit
;@ The cannon has been hit: explosion sound, one cannon less (sent to the link partner as $B0 +
;@ cannons left), all shots removed and the explosion shown. With no cannon left it is game over;
;@ otherwise the round restarts with READY (one player: the UFO is reset and the score and lives
;@ digit sprites are put back in place).
;@ writes: hLinkFlags, hLives, hSerialOut, hSfxRequest2, hUfoFlags, wShadowOam
;@ reads: hLinkFlags, hLives, hUfoFlags
;@ test: skip calls the explosion and READY sequences with busy-wait delays
;@ sig: 10b38fe7
CannonHit::
;> hSfxRequest2 = 0x0B                   # explosion
	ld a, $0b
	ldh [hSfxRequest2], a
;> hUfoFlags &= 0xC3
	ldh a, [hUfoFlags]
	and $c3
	ldh [hUfoFlags], a
;> hLives -= 1
	ldh a, [hLives]
	sub $01
	ldh [hLives], a
;> hSerialOut = 0xB0 | (hLives & 0x0F)   # "cannons left"
	and $0f
	or $b0
	ldh [hSerialOut], a
;> RemoveAllShots()
	call RemoveAllShots
;> BlinkCannon()
	call BlinkCannon
;> if hLives & 0x80:                     # went below zero
;>     return GameOver()                 # a jump
	ldh a, [hLives]
	bit 7, a
	jp nz, GameOver

;> DrawLives()
	call DrawLives
;> if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .ready

;>     ResetUfo()
	call ResetUfo
;>     x = 0x48
	ld hl, $c029
	ld b, $04
	ld a, $48

.scoreX
;>@sx     for i in range(4):             # X of the four score digit sprites 10-13
;>         mem[0xC029 + 4 * i] = x
	ld [hli], a
;>         x += 8
	add $08
	inc l
	inc l
	inc l
;=@sx
	dec b
	jr nz, .scoreX

;>     mem[0xC039] = 0x90                # sprite 14: the lives digit
	ld a, $90
	ld [$c039], a
;>     mem[0xC03D] = 0xB8                # sprites 15 and 16 off the right edge
	ld a, $b8
	ld [$c03d], a
;>     mem[0xC041] = 0xC0
	ld a, $c0
	ld [$c041], a

.ready
;> ShowReadyRound()
	call ShowReadyRound
;> hLinkFlags &= 0x01
	ldh a, [hLinkFlags]
	and $01
	ldh [hLinkFlags], a
;> InitRoundState()
	call InitRoundState
	ret


;@ def BlinkCannon()
;@ path: player/hit
;@ The cannon's explosion: twice the two explosion pictures (tiles 6 and 8), each for 24 short
;@ delays (about a tenth of a second). Meanwhile it keeps the other player's cannon count up to
;@ date and stops early if the link partner reports $CE or $EE.
;@ writes: hLinkFlags, hSoundOff, hTemp
;@ reads: hLinkFlags, hSerialIn, hTemp
;@ test: skip busy-wait delays
;@ sig: 8688dc83
BlinkCannon::
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;>@blink for i in range(2):
	ld b, $02

.blink
;>@pic     for tile in (0x06, 0x08):
;>         SetCannonTiles(tile)
	ld a, $06
	call SetCannonTiles
;>@wait         for j in range(0x18):
	ld a, $18

.wait1
	ldh [hTemp], a
;>@c1             if hSerialIn == 0xCE or hSerialIn == 0xEE:
;>                 return
	ldh a, [hSerialIn]
	cp $ce
	jr z, .done

	ldh a, [hSerialIn]
	cp $ee
	jr z, .done

;>@c2             if hSerialIn & 0xF0 == 0xB0:  # the other side lost a cannon
;>                 ReadOpponentLives()
	ldh a, [hSerialIn]
	and $f0
	cp $b0
	call z, ReadOpponentLives
;>@c3             Delay(0x01)
	ld d, $01
	call Delay
;=@wait
	ldh a, [hTemp]
	dec a
	jr nz, .wait1

;=@pic
	ld a, $08
	call SetCannonTiles
	ld a, $18

.wait2
;=@wait
	ldh [hTemp], a
;=@c1
	ldh a, [hSerialIn]
	cp $ce
	jr z, .done

	ldh a, [hSerialIn]
	cp $ee
	jr z, .done

;=@c2
	ldh a, [hSerialIn]
	and $f0
	cp $b0
	call z, ReadOpponentLives
;=@c3
	ld d, $01
	call Delay
;=@wait
	ldh a, [hTemp]
	dec a
	jr nz, .wait2

;=@blink
	dec b
	jr nz, .blink

;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> hSoundOff = 1
	ld a, $01
	ldh [hSoundOff], a

.done
	ret


;@ def SetCannonTiles(tile: a)
;@ path: player/hit
;@ Shows tile on both halves of the cannon sprite.
;@ sig: 7db8f12e
SetCannonTiles::
;> wCannonLeftTile = tile
	ld hl, wCannonLeftTile
	ld [hl], a
;> wCannonRightTile = tile
	ld hl, wCannonRightTile
	ld [hl], a
	ret


;@ def ReadOpponentLives()
;@ path: link/lives
;@ Takes the other player's cannon count from a received $Bn byte.
;@ writes: hOpponentLives
;@ reads: hSerialIn
;@ test: hSerialIn = rand(0xB0, 0xBF)
;@ sig: f761334e
ReadOpponentLives::
;> hOpponentLives = hSerialIn & 0x0F
	ldh a, [hSerialIn]
	and $0f
	ldh [hOpponentLives], a
	ret


;@ def DrawLives()
;@ path: score/lives
;@ Shows the number of cannons left as a digit sprite.
;@ reads: hLives
;@ sig: 1a8a3116
DrawLives::
;> WriteDigitTile(0xC03A, hLives)          # wLivesDigitTile
	ldh a, [hLives]
	ld hl, wLivesDigitTile
	call WriteDigitTile
;> return
	ret


;@ def SpawnUfo()
;@ path: ufo/spawn
;@ Puts the UFO on screen when it is due. In a normal game it appears every $14 ticks of hTimerHi
;@ (about 21 seconds), at a random edge, flying toward the other one. In a link game the "UFO" is the
;@ opponent's cannon: it appears at the top, mirrored to the X the other Game Boy sends.
;@ writes: hTimerHi, hTimerLo, hUfoSubX, hUfoTargetX, wUfoRightSpriteAttr, wUfoRightSpriteTile, wUfoRightSpriteX, wUfoRightSpriteY, wUfoSpriteAttr, wUfoSpriteTile, wUfoSpriteX, wUfoSpriteY
;@ reads: hLinkFlags, hSerialIn, hTimerHi, hUfoFlags
;@ sig: 22ecea62
SpawnUfo::
;> flags = hUfoFlags
	ldh a, [hUfoFlags]
	ld b, a
;> if flags & 0x02:                      # already on screen
	bit 1, b
;>     return
	jr nz, .done

;> if hLinkFlags & 0x01 == 0:
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, .link

;>     if flags & 0x80 or hTimerHi != 0x14:  # still exploding, or not time yet
	ldh a, [hTimerHi]
	bit 7, b
	jr nz, .done

	cp $14
;>         return
	jr nz, .done

;>     hTimerHi = 0
	xor a
	ldh [hTimerHi], a
;>     hTimerLo = 0
	ldh [hTimerLo], a
;>     tile = 0x01
	ld c, $01
;>     SetUfoOnScreen(flags)
	call SetUfoOnScreen
;>     if rDIV & 0x01 == 0:                  # random side
	ldh a, [rDIV]
	bit 0, a
	jr nz, .fromLeft

;>         flags |= 0x40                     # start at the right, fly left
	set 6, b
;>         x = 0x90
	ld a, $90
;=@else
	jr .place

;>@else     else:
;>         flags &= ~0x40                    # start at the left, fly right
.fromLeft
	res 6, b
;>         x = 0x08
	ld a, $08

;>     wUfoSpriteX = x
.place
	ld [wUfoSpriteX], a
;>     wUfoRightSpriteX = x + 8
	add $08
	ld [wUfoRightSpriteX], a
;>     wUfoSpriteY = 0x18
	ld a, $18
	ld [wUfoSpriteY], a
;>     wUfoRightSpriteY = 0x18
	ld [wUfoRightSpriteY], a
;>     SetUfoOnScreen(flags)
	call SetUfoOnScreen
;>     wUfoRightSpriteTile = tile
	ld a, c
	ld [wUfoRightSpriteTile], a
;>     wUfoSpriteTile = tile
	ld [wUfoSpriteTile], a
;>     wUfoSpriteAttr = 0
	and $00
	ld [wUfoSpriteAttr], a
;>     hUfoSubX = 0
	ldh [hUfoSubX], a
;>     wUfoRightSpriteAttr = 0x20            # right half is the left half mirrored
	ld a, $20
	ld [wUfoRightSpriteAttr], a
;>     return
	jr .done

; link game: the opponent's cannon
;> if hSerialIn >= 0x91 or hSerialIn < 0x10:   # not a cannon position
.link
	ldh a, [hSerialIn]
	sub $91
	jp nc, .done

	ldh a, [hSerialIn]
	sub $10
;>     return
	jp c, .done

;> SetUfoOnScreen(flags)
	call SetUfoOnScreen
;> wUfoSpriteY = 0x18
	ld a, $18
	ld [wUfoSpriteY], a
;> wUfoRightSpriteY = 0x18
	ld [wUfoRightSpriteY], a
;> hUfoTargetX = hSerialIn
	ldh a, [hSerialIn]
	ldh [hUfoTargetX], a
;> wUfoSpriteX = 0xA0 - hUfoTargetX  # seen from the other side
	ld hl, hUfoTargetX
	ld a, $a0
	sub [hl]
	ld [wUfoSpriteX], a
;> wUfoRightSpriteX = wUfoSpriteX + 8
	add $08
	ld [wUfoRightSpriteX], a

;> return
.done
	ret


;@ def SetUfoOnScreen(flags: b)
;@ path: ufo/spawn
;@ Stores the UFO flags with bit 1 (on screen) set.
;@ writes: hUfoFlags
;@ sig: 8d8ee39c
SetUfoOnScreen::
;> hUfoFlags = flags | 0x02
	set 1, b
	ld a, b
	ldh [hUfoFlags], a
;> return
	ret


;@ def UpdateUfo()
;@ path: ufo/move
;@ Moves the UFO each frame: in a normal game it glides 2 pixels every 3 frames toward the far edge,
;@ where it leaves, and starts its sound again in each third of the screen. In a link game it is the
;@ opponent's cannon, which follows (mirrored, 1 pixel a frame) the X the other Game Boy sends, and
;@ drops the opponent's shot when the other side has fired. A UFO that was hit runs UpdateUfoHit.
;@ writes: hActiveShots, hSfxRequest2, hTemp, hUfoFlags, hUfoSubX, hUfoTargetX, wLinkShotSpriteX, wLinkShotSpriteY, wUfoRightSpriteX, wUfoRightSpriteY, wUfoSpriteX, wUfoSpriteY
;@ reads: hActiveShots, hLinkFlags, hSerialIn, hTemp, hUfoFlags, hUfoSubX, hUfoTargetX, wLinkShotSpriteX, wUfoSpriteX
;@ test: hLinkFlags = rand(0, 1)
;@ sig: 10d31981
UpdateUfo::
;> flags = hUfoFlags
	ldh a, [hUfoFlags]
	ld b, a
;> link = hLinkFlags & 0x01
	ldh a, [hLinkFlags]
	ld c, a
;> x = wUfoSpriteX
	ld a, [wUfoSpriteX]
	ld d, a
;> if flags & 0x80: return UpdateUfoHit(hLinkFlags)
	bit 7, b
	jp nz, UpdateUfoHit

;> if flags & 0x02 == 0: return          # nothing on screen
	bit 1, b
	jp z, UfoDone

;> if not link:
	bit 0, c
	jr nz, .link

;>     SetUfoTile(0x01)
	ld e, $01
	call SetUfoTile
;>     if flags & 0x40:                  # flying left
	bit 6, b
	jr z, .flyRight

;>         if x <= 0x08: return RemoveUfo()      # gone past the left edge
	ld a, d
	cp $08
	jp z, RemoveUfo

	jp c, RemoveUfo

;>         step = hUfoSubX + 0xAA
	ldh a, [hUfoSubX]
	add $aa
;>         hUfoSubX = u8(step)
	ldh [hUfoSubX], a
;>         x -= step >> 8                # one pixel whenever the fraction overflows
	ld a, d
	sbc $00
;>         wUfoSpriteX = x
	ld [wUfoSpriteX], a
;=@else
	jr .setPos

;>@else     else:
;>         if x >= 0x98: return RemoveUfo()      # gone past the right edge
.flyRight
	ld a, d
	cp $98
	jp z, RemoveUfo

	jp nc, RemoveUfo

;>         step = hUfoSubX + 0xAA
	ldh a, [hUfoSubX]
	add $aa
;>         hUfoSubX = u8(step)
	ldh [hUfoSubX], a
;>         x += step >> 8
	ld a, d
	adc $00
;>         wUfoSpriteX = x
	ld [wUfoSpriteX], a
;=@lelse
	jp .setPos


;>@lelse else:
;>     SetUfoTile(0x05)                  # the opponent's cannon
.link
	ld e, $05
	call SetUfoTile
;>     ShowOpponentLives()
	call ShowOpponentLives
;>     if hSerialIn < 0x91:              # the other side sent a cannon X
	ldh a, [hSerialIn]
	sub $91
	jp nc, .linkShot

;>         if hSerialIn < 0x10: return
	ldh a, [hSerialIn]
	sub $10
	jp c, UfoDone

;>         hUfoTargetX = 0xA0 - hSerialIn        # mirrored: the other player sits on the far side
	ldh a, [hSerialIn]
	ldh [hUfoTargetX], a
	ld hl, hUfoTargetX
	ld a, $a0
	sub [hl]
	ldh [hUfoTargetX], a
;>@cmp         if wUfoSpriteX < hUfoTargetX:
	ld a, [wUfoSpriteX]
	ld hl, hUfoTargetX
	sub [hl]
	jr z, .onTarget

	jr nc, .moveLeft

	jr c, .moveRight

;=@cmp
	jr .onTarget

;>             x = u8(wUfoSpriteX + 1)
.moveRight
	ld a, [wUfoSpriteX]
	inc a
;>             hTemp = x
	ldh [hTemp], a
;>             if x >= 0x91:
	sub $91
	jr nc, .clampRight

	ldh a, [hTemp]
	jr .setPos

;>@cr                 x = 0x90
;>         elif wUfoSpriteX > hUfoTargetX:
;>             x = u8(wUfoSpriteX - 1)
.moveLeft
	ld a, [wUfoSpriteX]
	dec a
;>             hTemp = x
	ldh [hTemp], a
;>             if x < 0x07:
	sub $07
	jr c, .clampLeft

	ldh a, [hTemp]
	jr .setPos

;>@cl                 x = 0x10
;=@cr
.clampRight
	ld a, $90
	jr .setPos

;=@cl
.clampLeft
	ld a, $10
	jr .setPos

;>         else:
;>             x = hUfoTargetX
.onTarget
	ldh a, [hUfoTargetX]

;> if not (link and hSerialIn >= 0x91):  # (that case jumped past the sprite update)
;>     wUfoSpriteX = x
.setPos
	ld [wUfoSpriteX], a
;>     wUfoRightSpriteX = x + 8
	add $08
	ld [wUfoRightSpriteX], a
;>     wUfoSpriteY = 0x18
	ld a, $18
	ld [wUfoSpriteY], a
;>     wUfoRightSpriteY = 0x18
	ld [wUfoRightSpriteY], a
;>     if not link:                      # restart the UFO sound once in each third of the screen
	bit 0, c
	jp nz, .linkShot

;>         if x < 0x35:
	ld a, [wUfoSpriteX]
	cp $35
	jr c, .zoneLeft

;>@l1             if hUfoFlags & 0x20 == 0:
;>@l2                 hUfoFlags |= 0x20
;>@l3                 hSfxRequest2 = 0x0C
;>         elif x < 0x64:
	cp $64
	jr c, .zoneMiddle

;>@m1             if hUfoFlags & 0x10 == 0:
;>@m2                 hUfoFlags |= 0x10
;>@m3                 hSfxRequest2 = 0x0D
;>         elif x < 0x90:
	cp $90
	jr c, .zoneRight

	jr .linkShot

;>             if hUfoFlags & 0x08 == 0:
.zoneRight
	ldh a, [hUfoFlags]
	bit 3, a
	jr nz, .linkShot

;>                 hUfoFlags |= 0x08
	set 3, a
	ldh [hUfoFlags], a
;>                 hSfxRequest2 = 0x0E
	ld a, $0e
	ldh [hSfxRequest2], a
	jr .linkShot

;=@m1
.zoneMiddle
	ldh a, [hUfoFlags]
	bit 4, a
	jr nz, .linkShot

;=@m2
	set 4, a
	ldh [hUfoFlags], a
;=@m3
	ld a, $0d
	ldh [hSfxRequest2], a
	jr .linkShot

;=@l1
.zoneLeft
	ldh a, [hUfoFlags]
	bit 5, a
	jr nz, .linkShot

;=@l2
	set 5, a
	ldh [hUfoFlags], a
;=@l3
	ld a, $0c
	ldh [hSfxRequest2], a

;> if not link: return
.linkShot
	bit 0, c
	jp z, UfoDone

;> if hUfoFlags & 0x01 == 0: return      # the other side has not fired
	ldh a, [hUfoFlags]
	bit 0, a
	jp z, UfoDone

;> if hActiveShots & 0x02: return        # the opponent's shot is still falling
	ldh a, [hActiveShots]
	bit 1, a
	jp nz, UfoDone

;> wLinkShotSpriteY = 0x18               # drop it from the opponent's cannon
	ld a, $18
	ld [wLinkShotSpriteY], a
;> wLinkShotSpriteX = wUfoSpriteX + 4
	ld a, [wUfoSpriteX]
	add $04
	ld [wLinkShotSpriteX], a
;> hActiveShots |= 0x02
	ldh a, [hActiveShots]
	set 1, a
	ldh [hActiveShots], a
;> hUfoFlags &= ~0x01
	ldh a, [hUfoFlags]
	res 0, a
	ldh [hUfoFlags], a
;> if wLinkShotSpriteX < 0x35:           # shot sound for the left, middle or right of the screen
	ld a, [wLinkShotSpriteX]
	cp $35
	jr c, .shotLeft

;>@s1     hSfxRequest2 = 0x0F
;> elif wLinkShotSpriteX < 0x64:
	cp $64
	jr c, .shotMiddle

;>@s2     hSfxRequest2 = 0x10
;> else:
;>     hSfxRequest2 = 0x11
	ld a, $11
	ldh [hSfxRequest2], a
	jr .done

;=@s2
.shotMiddle
	ld a, $10
	ldh [hSfxRequest2], a
	jr .done

;=@s1
.shotLeft
	ld a, $0f
	ldh [hSfxRequest2], a

;> return
.done
	jp UfoDone


;@ def UpdateUfoHit(link: c)
;@ path: ufo/hit
;@ The UFO after a hit: it explodes for 32 frames (two tiles swapping every 8 frames), then its points
;@ (picked by hShotCount from UfoPointsTable) are added to the score and shown in its place for 64
;@ frames, then it is removed. In a link game the opponent's cannon was hit instead: the other side
;@ reports its remaining cannons, and the sprite is reset right away.
;@ writes: hOpponentLives, hPointsToAdd, hSfxRequest, hUfoFlags, hUfoHitTimer, hUfoPoints, wUfoRightSpriteAttr, wUfoSpriteTile, wUfoZeroSpriteX, wUfoZeroSpriteY
;@ reads: hShotCount, hUfoFlags, hUfoHitCode, hUfoHitTimer, hUfoPoints, wUfoRightSpriteX, wUfoSpriteY
;@ test: link = rand(0, 1)
;@ test: hShotCount = rand(0, 15)
;@ sig: 8b51bf81
UpdateUfoHit::
;> if hUfoFlags & 0x04 == 0:              # first frame after the hit
	ldh a, [hUfoFlags]
	bit 2, a
	jr nz, .timer

;>     hUfoFlags |= 0x04
	set 2, a
	ldh [hUfoFlags], a
;>     hSfxRequest = 0x12                # explosion sound
	ld a, $12
	ldh [hSfxRequest], a

;> t = hUfoHitTimer
.timer
	ldh a, [hUfoHitTimer]
;> if t & 0x80: return RemoveUfo()       # points shown long enough
	bit 7, a
	jp nz, RemoveUfo

;> elif t & 0x40:                        # show the points: [first digit][second digit][0]
	bit 6, a
	jr nz, .showPoints

;>@p1     p = hUfoPoints
;>@p2     if p & 0xF0:
;>@p3         WriteDigitTile(0xC00E, swap(p))    # wUfoSpriteTile
;>@p4     else:
;>@p5         wUfoSpriteTile = 0xA4              # blank instead of a leading 0
;>@p6     wUfoRightSpriteAttr = 0                # not mirrored any more
;>@p7     WriteDigitTile(0xC006, p)              # wUfoRightSpriteTile
;>@p8     wUfoZeroSpriteY = wUfoSpriteY
;>@p9     wUfoZeroSpriteX = wUfoRightSpriteX + 8
;>@p10     WriteDigitTile(0xC04A, 0)             # wUfoZeroSpriteTile
;> elif t & 0x20:                        # explosion over: score the points
	bit 5, a
	jr nz, .award

;>@a1     if link & 0x01:
;>@a2         hOpponentLives = hUfoHitCode & 0x0F    # the other side reports its cannons left
;>@a3         ResetUfo()
;>@a4         ShowOpponentLives()
;>@a5         return
;>@a6     hPointsToAdd = mem[UfoPointsTable + hShotCount]
;>@a7     hUfoPoints = hPointsToAdd
;>@a8     hUfoHitTimer = t | 0x40
;>@a9     return
;> else:
;>     SetUfoTile(0x0C if t & 0x08 else 0x0B)        # explosion, two tiles taking turns
	bit 3, a
	jr nz, .tile2

	ld e, $0b
	jr .setTile

.tile2
	ld e, $0c

.setTile
	call SetUfoTile

;> hUfoHitTimer = t + 1
.tick
	ldh a, [hUfoHitTimer]
	inc a
	ldh [hUfoHitTimer], a
;> return
	jr UfoDone

;=@a1
.award
	bit 0, c
	jr nz, .linkHit

;=@a6
	ld hl, UfoPointsTable
	ldh a, [hShotCount]
	ld c, a
	ld b, $00
	add hl, bc
	ld a, [hl]
;=@a6
	ldh [hPointsToAdd], a
;=@a7
	ldh [hUfoPoints], a
;=@a8
	ldh a, [hUfoHitTimer]
	set 6, a
	ldh [hUfoHitTimer], a
;=@a9
	jp UfoDone


;=@p1
.showPoints
	ldh a, [hUfoPoints]
	ld b, a
;=@p2
	and $f0
	jr z, .blank

;=@p3
	ld a, b
	swap a
	ld hl, wUfoSpriteTile
	call WriteDigitTile
	jr .second

;=@p5
.blank
	ld a, $a4
	ld [wUfoSpriteTile], a

;=@p6
.second
	and $00
	ld [wUfoRightSpriteAttr], a
;=@p7
	ldh a, [hUfoPoints]
	ld hl, wUfoRightSpriteTile
	call WriteDigitTile
;=@p8
	ld a, [wUfoSpriteY]
	ld [wUfoZeroSpriteY], a
;=@p9
	ld a, [wUfoRightSpriteX]
	add $08
	ld [wUfoZeroSpriteX], a
;=@p10
	and $00
	ld hl, wUfoZeroSpriteTile
	call WriteDigitTile
	jr .tick

;=@a2
.linkHit
	ldh a, [hUfoHitCode]
	and $0f
	ldh [hOpponentLives], a
;=@a3
	call ResetUfo
;=@a4
	call ShowOpponentLives
;=@a5
	jp UfoDone


;@ def RemoveUfo()
;@ path: ufo/hit
;@ Hides the UFO and the "0" of its points and resets it for the next appearance.
;@ writes: wUfoZeroSpriteX, wUfoZeroSpriteY
;@ sig: 10342003
RemoveUfo::
;> wUfoZeroSpriteY = 0xF0
	ld a, $f0
	ld [wUfoZeroSpriteY], a
;> wUfoZeroSpriteX = 0xF0
	ld [wUfoZeroSpriteX], a
;> ResetUfo()
	call ResetUfo

;> return
UfoDone:
	ret


;@ def SetUfoTile(tile: e)
;@ path: ufo/draw
;@ Gives both halves of the UFO sprite the same tile (the right half is drawn mirrored).
;@ writes: wUfoRightSpriteTile, wUfoSpriteTile
;@ sig: 969a813c
SetUfoTile::
;> wUfoRightSpriteTile = tile
	ld a, e
	ld [wUfoRightSpriteTile], a
;> wUfoSpriteTile = tile
	ld [wUfoSpriteTile], a
;> return
	ret


;@ def ResetUfo()
;@ path: ufo/spawn
;@ Takes the UFO (or the opponent's cannon) off the screen and clears its state, ready for the next
;@ appearance; also requests sound 1.
;@ writes: hSfxRequest, hUfoHitTimer, hUfoSubX, wUfoRightSpriteAttr, wUfoRightSpriteTile, wUfoRightSpriteX, wUfoRightSpriteY, wUfoSpriteAttr, wUfoSpriteTile, wUfoSpriteX, wUfoSpriteY
;@ reads: hLinkFlags
;@ sig: d1b0efd4
ResetUfo::
;> wUfoSpriteAttr = 0
	ld hl, hUfoFlags
	and $00
	ld [wUfoSpriteAttr], a
;> wUfoSpriteY = 0xF0                    # $F0 = below the screen, hidden
	ld a, $f0
	ld [wUfoSpriteY], a
;> wUfoSpriteX = 0xF0
	ld [wUfoSpriteX], a
;> wUfoRightSpriteY = 0xF0
	ld [wUfoRightSpriteY], a
;> wUfoRightSpriteX = 0xF0
	ld [wUfoRightSpriteX], a
;> hUfoFlags &= ~0x02
	res 1, [hl]
;> if hLinkFlags & 0x01 == 0:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .link

;>     tile = 0x01                       # UFO
	ld a, $01
;=@else
	jr .setTile

;>@else else:
;>     tile = 0x05                       # opponent's cannon
.link
	ld a, $05

;> wUfoRightSpriteTile = tile
.setTile
	ld [wUfoRightSpriteTile], a
;> wUfoSpriteTile = tile
	ld [wUfoSpriteTile], a
;> wUfoRightSpriteAttr = 0x20
	ld a, $20
	ld [wUfoRightSpriteAttr], a
;> hUfoFlags &= ~0xBC                    # not hit, no explosion sound, sound zones cleared
	res 7, [hl]
	res 5, [hl]
	res 4, [hl]
	res 3, [hl]
	res 2, [hl]
;> hUfoHitTimer = 0
	and $00
	ldh [hUfoHitTimer], a
;> hUfoSubX = 0
	ldh [hUfoSubX], a
;> hSfxRequest = 0x01
	ld a, $01
	ldh [hSfxRequest], a
;> return
	ret


;@ def ShowOpponentLives()
;@ path: score/lives
;@ Shows the number of cannons the link opponent has left as a digit sprite.
;@ reads: hOpponentLives
;@ sig: 4e677105
ShowOpponentLives::
;> WriteDigitTile(0xC02E, hOpponentLives)  # wOpponentLivesDigitTile
	ldh a, [hOpponentLives]
	ld hl, wOpponentLivesDigitTile
	call WriteDigitTile
;> return
	ret


;@ def FlashOpponentExplosion()
;@ path: link/end
;@ Plays the explosion sound and blinks the opponent's cannon at the top between the two explosion
;@ tiles, twice (about half a second), when the link game is decided.
;@ writes: hSfxRequest
;@ test: skip delay loops only
;@ sig: 2353131b
FlashOpponentExplosion::
;> hSfxRequest = 0x12
	ld a, $12
	ldh [hSfxRequest], a
;>@loop for _ in range(2):
	ld b, $02

;>     SetUfoTile(0x0B)
.loop
	ld e, $0b
	call SetUfoTile
;>     Delay(0x10)
	ld d, $10
	call Delay
;>     SetUfoTile(0x0C)
	ld e, $0c
	call SetUfoTile
;>     Delay(0x10)
	ld d, $10
	call Delay
;=@loop
	dec b
	jr nz, .loop

;> return
	ret


;@ def CheckShotHitsInvader()
;@ path: shots/hit-invader
;@ Tests the flying cannon shot against every invader of the formation. On a hit the shot turns into
;@ an explosion at the invader's place, the invader's points (10, 20 or 30, by its row) are queued
;@ for the score, an explosion sound plays (by the screen third), and the invader's two background
;@ tiles become the explosion tiles $A8/$A9; its entry is marked $A8 so that MarchInvaders removes it.
;@ writes: hHitLoopCount, hLcdHook, hMainHook, hMarchDescend, hPointsToAdd, hSavedIE, hSfxRequest, hShotFlags, hUfoFlags, hVramAddrHi, hVramAddrLo, hVramData0, wShotSpriteTile, wShotSpriteX, wShotSpriteY
;@ reads: hActiveShots, hHitLoopCount, hInvadersLeft, hLcdHook, hMainHook, hMarchDescend, hPointsToAdd, hSavedIE, hShotFlags, hUfoFlags, wShotSpriteX, wShotSpriteY
;@ test: skip waits for the LCD / VBlank hook to draw the tiles
;@ sig: ec9d7af1
CheckShotHitsInvader::
;> if hActiveShots & 0x01 == 0: return   # no shot flying
	ldh a, [hActiveShots]
	bit 0, a
	jp z, .done

;> if hShotFlags & 0x10: return          # it already hit something
	ldh a, [hShotFlags]
	bit 4, a
	jp nz, .done

;> p = wInvaders
	ld hl, wInvaders
;> if hInvadersLeft == 0: return
	ldh a, [hInvadersLeft]
	and a
	jp z, .done

;> hHitLoopCount = hInvadersLeft
	ldh [hHitLoopCount], a

;>@loop while hHitLoopCount:
;>     tile = mem[p]
.loop
	ld a, [hl]
	ld b, a
;>     if tile & 0xF0 != 0xA0:           # $A8 = exploding already
	and $f0
	cp $a0
	jp z, .next

;>         vram_hi = mem[p + 1]
	ld a, b
	inc hl
	ld d, [hl]
;>         vram_lo = mem[p + 2]
	inc hl
	ld e, [hl]
;>         x = mem[p + 3]
	inc hl
	ld b, [hl]
;>         y = mem[p + 4]
	inc hl
	ld c, [hl]
	dec hl
	dec hl
	dec hl
	dec hl
;>         x += (tile & 0x0F) - 1        # plus the formation's fine step (0, 2, 4, 6)
	and $0f
	dec a
	add b
	ld b, a
;>         if x <= u8(wShotSpriteX - 4) \
	ld a, [wShotSpriteX]
	sub $04
	cp b
	jp c, .next

;>                 and x > u8(wShotSpriteX - 13) \
	sub $09
	cp b
	jp nc, .next

;>                 and wShotSpriteY >= y \
	ld a, [wShotSpriteY]
	cp c
	jp c, .next

;>                 and u8(wShotSpriteY - 6) < y:
	sub $06
	cp c
	jp nc, .next

;>             hShotFlags |= 0x10        # the shot explodes
	ldh a, [hShotFlags]
	set 4, a
	ldh [hShotFlags], a
;>             wShotSpriteTile = 0x15
	ld a, $15
	ld [wShotSpriteTile], a
;>             wShotSpriteX = x + 8
	ld a, [wShotSpriteX]
	ld a, b
	add $08
	ld [wShotSpriteX], a
;>             if wShotSpriteX < 0x35:   # explosion sound for the left, middle or right of the screen
	cp $35
	jr c, .soundLeft

;>@s1                 hSfxRequest = 0x08
;>             elif wShotSpriteX < 0x64:
	cp $64
	jr c, .soundMiddle

;>@s2                 hSfxRequest = 0x09
;>             else:
;>                 hSfxRequest = 0x0A
	ld a, $0a
	ldh [hSfxRequest], a
	jr .scored

;=@s2
.soundMiddle
	ld a, $09
	ldh [hSfxRequest], a
	jr .scored

;=@s1
.soundLeft
	ld a, $08
	ldh [hSfxRequest], a

;>             hUfoFlags &= 0xC3         # the UFO's sound zones start over
.scored
	ldh a, [hUfoFlags]
	and $c3
	ldh [hUfoFlags], a
;>             wShotSpriteY = y
	ld a, [wShotSpriteY]
	ld a, c
	ld [wShotSpriteY], a
;>@pts             hPointsToAdd += (tile >> 4) - 0x0C        # tiles $Dx/$Ex/$Fx: 1/2/3 tens of points
	ld a, [hl]
	and $f0
	swap a
	sub $0c
	ld c, a
;=@pts
	ldh a, [hPointsToAdd]
	add c
	ldh [hPointsToAdd], a
;>             mem[p] = 0xA8             # exploding: MarchInvaders takes it out of the formation
	ld a, $a8
	ld [hl], a
;>             hVramData0 = 0xA8         # draw the explosion tiles $A8, $A9 over it
	ldh [hVramData0], a
;>             hVramAddrHi = vram_hi
	ld a, d
	ldh [hVramAddrHi], a
;>             hVramAddrLo = vram_lo
	ld a, e
	ldh [hVramAddrLo], a
;>             saved = hMarchDescend     # (held at 0 while the tiles are drawn)
	ldh a, [hMarchDescend]
	ld c, a
;>             hMarchDescend = 0
	xor a
	ldh [hMarchDescend], a
;>             if rIE & 0x02:            # LCD interrupt on: it writes the tiles
	ldh a, [rIE]
	bit 1, a
	jr z, .viaVBlank

;>                 hSavedIE = rIE        # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>                 rIF = 0
	xor a
	ldh [rIF], a
;>                 rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>                 hLcdHook = lo(LcdWriteTilePair)
	ld a, LOW(LcdWriteTilePair)
	ldh [hLcdHook], a

.waitLcd
;>                 while hLcdHook: LcdWriteTilePair()        # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .waitLcd

;>                 rIF = 0
	xor a
	ldh [rIF], a
;>                 rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;=@else
	jr .drawn

;>@else             else:                     # otherwise the VBlank handler does
;>                 hMainHook = lo(VBlankWriteTilePair)
.viaVBlank
	ld a, LOW(VBlankWriteTilePair)
	ldh [hMainHook], a

.waitVBlank
;>                 while hMainHook: VBlankWriteTilePair()
	ldh a, [hMainHook]
	and a
	jr nz, .waitVBlank

;>             hMarchDescend = saved
.drawn
	ld a, c
	ldh [hMarchDescend], a
;>             return
	ret


;>     p += 7
.next
	ld de, $0007
	add hl, de
;>     hHitLoopCount -= 1
	ldh a, [hHitLoopCount]
	dec a
	ldh [hHitLoopCount], a
;=@loop
	jp nz, .loop

;> return
.done
	ret


;@ def SetupFormation()
;@ path: invaders/setup
;@ Builds the formation for a new round: copies the 40 entries of FormationLayout to wInvaders,
;@ moved down by the round's FormationDropTable rows (a row is 32 bytes of the tilemap and 8
;@ pixels). The secret options in wCheatFlags (bits 2-4) give every invader the same shape. Then it
;@ starts the march (phase 2, to the right), sets the bomb rate for the round and clears the record
;@ of shot invaders that the secret kill orders are checked against.
;@ writes: hInvadersLeft, hMarchDescend, hMarchEdgeHit, hMarchLeftward, hMarchPhase, hMarchPtrHi, hMarchPtrLo, hMarchRemoved, hMarchToGo, wBombHoldoff, wBombRateMask, wFormationDrop, wKillCount, wLastKill
;@ reads: hRound, wCheatFlags, wFormationDrop
;@ test: hRound = rng.choice([0x01, 0x02, 0x05, 0x09, 0x10, 0x16, 0x23, 0x30])
;@ sig: 09a790f9
SetupFormation::
;> src = FormationLayout
	ld hl, FormationLayout
;> dst = wInvaders
	ld de, wInvaders
;> n = 40
	ld b, $28
;>@drop wFormationDrop = mem[FormationDropTable + hRound - 1]    # hRound is BCD
	ldh a, [hRound]
	dec a
	push hl
	push de
	ld hl, FormationDropTable
	ld d, $00
;=@drop
	ld e, a
	add hl, de
	ld a, [hl]
	pop de
	pop hl
	ld [wFormationDrop], a

;>@loop while n:
;>     tile = mem[src]
.loop
	ld a, [hli]
	push hl
	ld h, a
;>     if wCheatFlags & 0x80:            # options switched off
	ld a, [wCheatFlags]
	bit 7, a
	jr nz, .storeTile

;>         pass
;>     elif wCheatFlags & 0x04:          # all invaders of the bottom kind
	bit 2, a
	jr nz, .allLow

;>@b3         tile = 0xD1
;>     elif wCheatFlags & 0x08:          # all of the middle kind
	bit 3, a
	jr nz, .allMiddle

;>@b4         tile = 0xE1
;>     elif wCheatFlags & 0x10:          # all of the top kind
	bit 4, a
	jr nz, .allTop

	jr z, .storeTile

;>@b5         tile = 0xF1
;=@b3
.allLow
	ld h, $d1
	jr .storeTile

;=@b4
.allMiddle
	ld h, $e1
	jr .storeTile

;=@b5
.allTop
	ld h, $f1

;>     mem[dst] = tile
.storeTile
	ld a, h
	pop hl
	ld [de], a
	inc de
;>     vram = mem[src + 1] << 8 | mem[src + 2]   # tilemap address, high byte first
	push bc
	ld b, [hl]
	inc hl
	ld c, [hl]
	inc hl
	push hl
;>@drop2     vram += 32 * wFormationDrop
	ld a, [wFormationDrop]
	and a
	jr z, .noDrop

	ld h, b
	ld l, c
	ld bc, $0020

.addRow
;=@drop2
	add hl, bc
	dec a
	jr nz, .addRow

	ld b, h
	ld c, l

;>     mem[dst + 1] = hi(vram)
.noDrop
	ld a, b
	ld [de], a
	inc de
;>     mem[dst + 2] = lo(vram)
	ld a, c
	ld [de], a
	inc de
;>     mem[dst + 3] = mem[src + 3]       # X
	pop hl
	pop bc
	ld a, [hli]
	ld [de], a
	inc de
;>@y     mem[dst + 4] = mem[src + 4] + 8 * wFormationDrop      # Y
	and a
	ld a, [wFormationDrop]
	sla a
	sla a
	sla a
	ld c, a
;=@y
	ld a, [hli]
	add c
	ld [de], a
	inc de
;>     mem[dst + 5] = mem[src + 5]       # bomb turn
	ld a, [hli]
	ld [de], a
	inc de
;>     mem[dst + 6] = mem[src + 6]       # number
	ld a, [hli]
	ld [de], a
	inc de
;>     src, dst, n = src + 7, dst + 7, n - 1
	dec b
;=@loop
	jr nz, .loop

;> hMarchPtrLo = 0x00                    # the march starts at wInvaders
	ld a, $00
	ldh [hMarchPtrLo], a
;> hMarchPtrHi = 0xD0
	ld a, $d0
	ldh [hMarchPtrHi], a
;> hMarchPhase = 2
	ld a, $02
	ldh [hMarchPhase], a
;> hMarchLeftward = 0
	xor a
	ldh [hMarchLeftward], a
;> hMarchEdgeHit = 0
	xor a
	ldh [hMarchEdgeHit], a
;> hMarchToGo = 0
	ldh [hMarchToGo], a
;> hMarchRemoved = 0
	ldh [hMarchRemoved], a
;> hMarchDescend = 0
	ldh [hMarchDescend], a
;> hMarchPtrLo = 0x00                    # (once more)
	ld a, $00
	ldh [hMarchPtrLo], a
;> hMarchPtrHi = 0xD0
	ld a, $d0
	ldh [hMarchPtrHi], a
;> r = hRound + 1                        # BCD round, compared as hex
	ldh a, [hRound]
	inc a
;> if r < 0x05:                          # rounds 1-3
	cp $05
	jr c, .rate1F

;>@r1     mask = 0x1F
;> elif r < 0x10:                        # rounds 4-9
	cp $10
	jr c, .rate0F

;>@r2     mask = 0x0F
;> elif r < 0x17:                        # rounds 10-15
	cp $17
	jr c, .rate07

;>@r3     mask = 0x07
;> elif r < 0x25:                        # rounds 16-23
	cp $25
	jr c, .rate03

;>@r4     mask = 0x03
;> else:
;>     mask = 0x01
	ld a, $01
	jr .setRate

;=@r4
.rate03
	ld a, $03
	jr .setRate

;=@r3
.rate07
	ld a, $07
	jr .setRate

;=@r2
.rate0F
	ld a, $0f
	jr .setRate

;=@r1
.rate1F
	ld a, $1f

;> wBombRateMask = mask
.setRate
	ld [wBombRateMask], a
;> wBombHoldoff = 4                      # no bombs during the first 4 sweeps
	ld a, $04
	ld [wBombHoldoff], a
;> hMarchToGo = 0
	ld a, $00
	ldh [hMarchToGo], a
;> hInvadersLeft = 40
	ld a, $28
	ldh [hInvadersLeft], a
;> wLastKill = 0
	xor a
	ld [wLastKill], a
;> wKillCount = 0
	ld [wKillCount], a
;>@fill fill(wKillOrder, 0, 40)
	ld hl, wKillOrder
	xor a
	ld b, $28

.clear
;=@fill
	ld [hli], a
	dec b
	jr nz, .clear

;> return
	ret


;@ def DrawFormation()
;@ path: invaders/draw
;@ Draws every invader of wInvaders as its tile pair (phase 2 of its shape) through the VBlank hook,
;@ one invader per frame. The loop runs 41 times, one entry past the end of the formation.
;@ writes: hMainHook, hRoundFlags, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hMainHook, hRoundFlags
;@ test: skip waits for the VBlank handler, one frame per invader
;@ sig: c1ec9cbf
DrawFormation::
;> hRoundFlags &= ~0x01
	ldh a, [hRoundFlags]
	res 0, a
	ldh [hRoundFlags], a
;> p = wInvaders
	ld d, $00
	ld hl, wInvaders

;>@loop for i in range(41):
;>     hVramData0 = mem[p] + 2
.loop
	ld a, [hli]
	inc a
	inc a
	ldh [hVramData0], a
;>     hVramAddrHi = mem[p + 1]
	ld a, [hli]
	ldh [hVramAddrHi], a
;>     hVramAddrLo = mem[p + 2]
	ld a, [hli]
	ldh [hVramAddrLo], a
;>     p += 7
	inc hl
	inc hl
	inc hl
	inc hl
;>     hMainHook = lo(VBlankWriteTilePair)
	ld a, LOW(VBlankWriteTilePair)
	ldh [hMainHook], a

.wait
;>     while hMainHook: VBlankWriteTilePair()
	ldh a, [hMainHook]
	and a
	jr nz, .wait

;=@loop
	inc d
	ld a, $29
	cp d
	jr nz, .loop

;> return
	ret


;@ def PlayMarchStep()
;@ path: sound/march
;@ The march beat: when hFrameCounter reaches the number of invaders left plus 4, it starts over
;@ and the next of the 4 march notes (sounds $14-$17) is requested. So the beat speeds up as the
;@ formation thins out.
;@ writes: hFrameCounter, hMarchNote, hMarchSfxRequest
;@ reads: hFrameCounter, hInvadersLeft, hMarchNote
;@ test: hMarchNote = rand(1, 4)
;@ sig: 07276967
PlayMarchStep::
;> if hFrameCounter < u8(hInvadersLeft + 4): return
	ldh a, [hInvadersLeft]
	add $04
	ld c, a
	ldh a, [hFrameCounter]
	cp c
	ret c

;> hFrameCounter = 0
	xor a
	ldh [hFrameCounter], a
;> hMarchNote += 1
	ldh a, [hMarchNote]
	inc a
	ldh [hMarchNote], a
;> if hMarchNote == 5:
	cp $05
	jr nz, .play

;>     hMarchNote = 1
	ld a, $01
	ldh [hMarchNote], a

;> hMarchSfxRequest = hMarchNote + 0x13
.play
	add $13
	ldh [hMarchSfxRequest], a
;> return
	ret


;@ def MarchInvaders()
;@ path: invaders/march
;@ Moves one invader per frame, like the arcade machine: takes the next entry of the current sweep
;@ (hMarchPtr) and lets MoveInvader step it; when the sweep is through, EndMarchSweep starts the next
;@ one. While an invader explodes the formation waits (in a link game for a short delay instead).
;@ writes: hMarchPtrHi, hMarchPtrLo, hMarchToGo
;@ reads: hLinkFlags, hMarchPtrHi, hMarchPtrLo, hMarchRemoved, hMarchToGo, wShotSpriteTile
;@ test: skip runs into the tile drawing of MoveInvader
;@ sig: d5304f49
MarchInvaders::
;> if wShotSpriteTile == 0x15:          # an invader is exploding: the formation waits
	ld a, [wShotSpriteTile]
	cp $15
	jr nz, .move

;>     if hLinkFlags & 0x01 == 0: return
	ldh a, [hLinkFlags]
	bit 0, a
	ret z

;>     Delay(4)
	ld d, $04
	call Delay
;>     return
	ret


;> if hMarchToGo == hMarchRemoved: return EndMarchSweep()     # the sweep is through
.move
	ldh a, [hMarchRemoved]
	ld b, a
	ldh a, [hMarchToGo]
	cp b
	jp z, EndMarchSweep

;> hMarchToGo -= 1
	dec a
	ldh [hMarchToGo], a
;> p = hMarchPtrHi << 8 | hMarchPtrLo
	ldh a, [hMarchPtrHi]
	ld h, a
	ld b, a
	ldh a, [hMarchPtrLo]
	ld l, a
	ld c, a
;> nxt = p + 7
	ld de, $0007
	add hl, de
;> hMarchPtrHi = hi(nxt)
	ld a, h
	ldh [hMarchPtrHi], a
;> hMarchPtrLo = lo(nxt)
	ld a, l
	ldh [hMarchPtrLo], a
;> return MoveInvader(p)                 # (runs on into it)
	ld h, b
	ld l, c

;@ def MoveInvader(p: hl)
;@ path: invaders/march
;@ Steps one invader of the formation (entry p of wInvaders) and redraws its two background tiles.
;@ Sideways the formation moves 2 pixels a sweep: each shape has 4 tile pairs pre-shifted by 0, 2, 4
;@ and 6 pixels (tile = kind | 1 + hMarchPhase); at phase 0 (going right) or 6 (going left) the
;@ invader moves on to the next tile column. An invader at the edge (X $90 or 0) makes the next sweep
;@ go down. Dead entries are removed, and during the wipe sweep of a secret code the invader is
;@ erased. After drawing, an invader with a bomb turn may drop a bomb.
;@ writes: hLcdHook, hMainHook, hMarchEdgeHit, hSavedIE, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hInvadersLeft, hLcdHook, hMainHook, hMarchDescend, hMarchFlags, hMarchLeftward, hMarchPhase, hSavedIE
;@ test: skip waits for the LCD / VBlank hook to draw the tiles
;@ sig: a2bfd3ce
MoveInvader::
;> old = mem[p]
	ld a, [hl]
	ld c, a
;> tile = (old & 0xF0) + 1 + hMarchPhase
	and $f0
	inc a
	ld b, a
	ldh a, [hMarchPhase]
	add b
;> mem[p] = tile
	ld [hl], a
	ld b, a
;> vram = mem[p + 1] << 8 | mem[p + 2]
	inc hl
	ld d, [hl]
	inc hl
	ld e, [hl]
	inc hl
;> if old == 0xA8: return RemoveDeadInvader(p + 3)     # it was shot
	ld a, c
	cp $a8
	jp z, RemoveDeadInvader

;> if hMarchFlags & 0x01: return WipeInvader(vram, p + 3)
	ldh a, [hMarchFlags]
	bit 0, a
	jp nz, WipeInvader

;> if hMarchDescend: return MoveInvaderDown(tile, vram, p + 3)
	ld a, c
	ldh a, [hMarchDescend]
	and a
	jp nz, MoveInvaderDown

;> if not hMarchLeftward:
	ldh a, [hMarchLeftward]
	and a
	jr nz, .left

;>     hVramAddrHi = hi(vram)
	ld a, d
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(vram)
	ld a, e
	ldh [hVramAddrLo], a
;>     if hMarchPhase == 0:              # stepped into the next tile column
	ldh a, [hMarchPhase]
	and a
	jr nz, .rightLast

;>         tile -= 1                     # this time: shifted 8 pixels, still at the old place
	dec b
;>         vram += 1                     # from now on one tile further right
	inc de
;>         mem[p + 3] += 8               # X
	ld a, $08
	add [hl]
	ld [hl], a
;>         if mem[p + 3] == 0x90:
	cp $90
	jr nz, .rightLast

;>             hMarchEdgeHit = 0x90      # right edge reached: down next sweep
	ldh [hMarchEdgeHit], a

;>     if hInvadersLeft == 1 and tile == 0xD0:
.rightLast
	ldh a, [hInvadersLeft]
	cp $01
	jr nz, .rightDraw

	ld a, $d0
	cp b
	jr nz, .rightDraw

;>         tile = 0xDB                   # the last invader uses its own pair here
	ld b, $db

;>     hVramData0 = tile
.rightDraw
	ld a, b
	ldh [hVramData0], a
;>     if rIE & 0x02:                 # the LCD interrupt draws the tiles
	ldh a, [rIE]
	bit 1, a
	jr z, .rightVBlank

;>         hSavedIE = rIE                 # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>         hLcdHook = lo(LcdWriteTilePair)
	ld a, LOW(LcdWriteTilePair)
	ldh [hLcdHook], a

.rightWaitLcd
;>         while hLcdHook: LcdWriteTilePair()          # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .rightWaitLcd

;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;=@e1
	jr .rightDrawn

;>@e1     else:                         # otherwise the VBlank handler does
;>         hMainHook = lo(VBlankWriteTilePair)
.rightVBlank
	ld a, LOW(VBlankWriteTilePair)
	ldh [hMainHook], a

.rightWaitVBlank
;>         while hMainHook: VBlankWriteTilePair()
	ldh a, [hMainHook]
	and a
	jr nz, .rightWaitVBlank

.rightDrawn
;>     if mem[p + 5]:                 # its bomb turn (only invaders with none below them have one)
	inc hl
	inc hl
	ld a, [hld]
	dec hl
	and a
;>         return InvaderBombTurn(mem[p + 5], tile, vram, p + 3)
	jp nz, InvaderBombTurn

;>     mem[p + 2] = lo(vram)
	dec hl
	ld [hl], e
;>     mem[p + 1] = hi(vram)
	dec hl
	ld [hl], d
;>     return
	ret


;> else:                                # marching left
;>     if hMarchPhase == 6:              # stepped into the next tile column
.left
	ldh a, [hMarchPhase]
	cp $06
	jr nz, .leftLast

;>         vram -= 1
	dec de
;>         mem[p + 3] -= 8               # X
	ld a, [hl]
	sub $08
	ld [hl], a
;>         if mem[p + 3] == 0:
	cp $00
	jr nz, .leftLast

;>             hMarchEdgeHit = tile      # left edge reached: down next sweep
	ld a, b
	ldh [hMarchEdgeHit], a

;>     if hInvadersLeft == 1 and tile == 0xD1:   # the last invader: clear the pair above it
.leftLast
	ldh a, [hInvadersLeft]
	cp $01
	jr nz, .leftDraw

	ld a, $d1
	cp b
	jr nz, .leftDraw

;>         above = vram - 32
	push hl
	ld hl, -$20
	add hl, de
;>         hVramAddrHi = hi(above)
	ld a, h
	ldh [hVramAddrHi], a
;>         hVramAddrLo = lo(above)
	ld a, l
	ldh [hVramAddrLo], a
	pop hl
;>         if rIE & 0x02:                 # the LCD interrupt clears the tiles
	ldh a, [rIE]
	bit 1, a
	jr z, .clearVBlank

;>             hSavedIE = rIE                 # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>             rIF = 0
	xor a
	ldh [rIF], a
;>             rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>             hLcdHook = lo(LcdClearTilePair)
	ld a, LOW(LcdClearTilePair)
	ldh [hLcdHook], a

.clearWaitLcd
;>             while hLcdHook: LcdClearTilePair()          # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .clearWaitLcd

;>             rIF = 0
	xor a
	ldh [rIF], a
;>             rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;=@e2
	jr .leftDraw

;>@e2         else:                         # otherwise the VBlank handler does
;>             hMainHook = lo(VBlankClearTilePair)
.clearVBlank
	ld a, LOW(VBlankClearTilePair)
	ldh [hMainHook], a

.clearWaitVBlank
;>             while hMainHook: VBlankClearTilePair()
	ldh a, [hMainHook]
	and a
	jr nz, .clearWaitVBlank

;>     hVramData0 = tile
.leftDraw
	ld a, b
	ldh [hVramData0], a
;>     hVramAddrHi = hi(vram)
	ld a, d
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(vram)
	ld a, e
	ldh [hVramAddrLo], a
;>     if rIE & 0x02:                 # the LCD interrupt draws the tiles
	ldh a, [rIE]
	bit 1, a
	jr z, .leftVBlank

;>         hSavedIE = rIE                 # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>         hLcdHook = lo(LcdWriteTilePair)
	ld a, LOW(LcdWriteTilePair)
	ldh [hLcdHook], a

.leftWaitLcd
;>         while hLcdHook: LcdWriteTilePair()          # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .leftWaitLcd

;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;=@e3
	jr .leftDrawn

;>@e3     else:                         # otherwise the VBlank handler does
;>         hMainHook = lo(VBlankWriteTilePair)
.leftVBlank
	ld a, LOW(VBlankWriteTilePair)
	ldh [hMainHook], a

.leftWaitVBlank
;>         while hMainHook: VBlankWriteTilePair()
	ldh a, [hMainHook]
	and a
	jr nz, .leftWaitVBlank

.leftDrawn
;>     if mem[p + 5]:                 # its bomb turn (only invaders with none below them have one)
	inc hl
	inc hl
	ld a, [hld]
	dec hl
	and a
;>         return InvaderBombTurn(mem[p + 5], tile, vram, p + 3)
	jp nz, InvaderBombTurn

;>     mem[p + 2] = lo(vram)
	dec hl
	ld [hl], e
;>     mem[p + 1] = hi(vram)
	dec hl
	ld [hl], d
;>     return
	ret


;@ def MoveInvaderDown(tile: b, vram: de, xp: hl)
;@ path: invaders/march
;@ The down step of a sweep for one invader (xp points at its X in wInvaders): one tilemap row lower,
;@ 8 pixels down; it draws the pair at the new place and clears the old one. An invader that gets to
;@ Y $98 has landed: bit 7 of hLinkFlags ends the game.
;@ writes: hLcdHook, hLinkFlags, hMainHook, hSavedIE, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hLcdHook, hLinkFlags, hMainHook, hSavedIE
;@ test: skip waits for the LCD / VBlank hook to draw the tiles
;@ sig: 290787c0
MoveInvaderDown::
;> vram += 32
	ld a, h
	ld c, l
	ld hl, $0020
	add hl, de
	ld d, h
	ld e, l
;> mem[xp + 1] += 8                      # Y
	ld h, a
	ld l, c
	inc hl
	ld a, $08
	add [hl]
	ld [hl], a
;> if mem[xp + 1] == 0x98:               # down on the cannon's row
	dec hl
	cp $98
	jr nz, .draw

;>     hLinkFlags |= 0x80                # the invaders have landed
	ldh a, [hLinkFlags]
	set 7, a
	ldh [hLinkFlags], a

;> hVramData0 = tile
.draw
	ld a, b
	ldh [hVramData0], a
;> hVramAddrHi = hi(vram)
	ld a, d
	ldh [hVramAddrHi], a
;> hVramAddrLo = lo(vram)
	ld a, e
	ldh [hVramAddrLo], a
;> if rIE & 0x02:                        # the LCD interrupt draws, then clears the old pair
	ldh a, [rIE]
	bit 1, a
	jr z, .viaVBlank

;>     hSavedIE = rIE                 # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>     hLcdHook = lo(LcdWriteTilePair)
	ld a, LOW(LcdWriteTilePair)
	ldh [hLcdHook], a

.waitDraw
;>     while hLcdHook: LcdWriteTilePair()          # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .waitDraw

;>     above = vram - 32
	push hl
	ld hl, -$20
	add hl, de
;>     hVramAddrHi = hi(above)
	ld a, h
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(above)
	ld a, l
	ldh [hVramAddrLo], a
	pop hl
;>     hLcdHook = lo(LcdClearTilePair)
	ld a, LOW(LcdClearTilePair)
	ldh [hLcdHook], a

.waitClear
;>     while hLcdHook: LcdClearTilePair()          # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .waitClear

;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;=@e1
	jr .store

;>@e1 else:                              # the VBlank handler does both in one go
;>     hMainHook = lo(VBlankMoveTilePairDownLeft)
.viaVBlank
	ld a, LOW(VBlankMoveTilePairDownLeft)
	ldh [hMainHook], a

.waitVBlank
;>     while hMainHook: VBlankMoveTilePairDownLeft()
	ldh a, [hMainHook]
	and a
	jr nz, .waitVBlank

;> mem[xp - 1] = lo(vram)
.store
	dec hl
	ld [hl], e
;> mem[xp - 2] = hi(vram)
	dec hl
	ld [hl], d
;> return
	ret


;@ def InvaderBombTurn(turn: a, tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ An invader with a bomb turn (one with no invader below it) has just moved: in a normal game it
;@ first tries an aimed bomb, in a link game it goes straight to its turn. xp points at the X byte of
;@ its wInvaders entry (X, Y, turn follow; the tilemap address `vram` sits just before).
;@ reads: hLinkFlags
;@ test: skip part of the march, needs a formation entry
;@ sig: 0ff4b97d
InvaderBombTurn::
;> if hLinkFlags & 0x01 == 0: return DropAimedBomb(turn, tile, vram, xp)
	ld c, a
	ldh a, [hLinkFlags]
	bit 0, a
	jp z, DropAimedBomb

;> return AdvanceBombTurn(turn, tile, vram, xp)
	jp AdvanceBombTurn


;@ def UnusedDropRandomBomb(tile: b, vram: de, xp: hl)
;@ path: unused
;@ Nothing calls this: a bomb chance from the timer (the sum with rDIV is thrown away) and a mask
;@ made from the bomb rate; on a hit it would try bomb 1.
;@ reads: hTimerHi, wBombRateMask
;@ test: skip unused, part of the march
;@ sig: 252ef632
UnusedDropRandomBomb::
;>@chance chance = hTimerHi & (wBombRateMask * 2 + 1)
	ldh a, [hTimerHi]
	ld c, a
	ldh a, [rDIV]
	add c
	ld a, [wBombRateMask]
	sla a
;=@chance
	inc a
	and c
;> if chance: return DropAimedBomb1(tile, vram, xp)
	jp nz, DropAimedBomb1

;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;@ def DropAimedBomb(turn: c, tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ Normal game: an invader right above the cannon drops bomb 0 at once (or, when bomb 0 is busy,
;@ goes on to bomb 1 or 2); any other invader goes on with its bomb turn. No bombs while
;@ wBombHoldoff runs or when wBombRateMask is 0; the last invader only uses its turn.
;@ writes: hActiveShots, wBomb0SpriteX, wBomb0SpriteY
;@ reads: hActiveShots, hBombFlags, hInvadersLeft, wBombHoldoff, wBombRateMask, wCannonSpriteX
;@ test: skip part of the march, needs a formation entry
;@ sig: aa02d886
DropAimedBomb::
;> if wBombRateMask == 0: return StoreInvaderAddr(vram, xp)         # bombs switched off
	ld a, [wBombRateMask]
	and a
	jp z, StoreInvaderAddr

;> if wBombHoldoff: return StoreInvaderAddr(vram, xp)               # the round has just begun
	ld a, [wBombHoldoff]
	and a
	jp nz, StoreInvaderAddr

;> if hInvadersLeft == 1: return AdvanceBombTurn(turn, tile, vram, xp)
	ldh a, [hInvadersLeft]
	cp $01
	jp z, AdvanceBombTurn

;> if not (u8(wCannonSpriteX - 8) < mem[xp] <= wCannonSpriteX):   # not above the cannon
	ld a, [wCannonSpriteX]
	cp [hl]
	jp c, AdvanceBombTurn

	sub $08
	cp [hl]
;>     return AdvanceBombTurn(turn, tile, vram, xp)
	jp nc, AdvanceBombTurn

;> if hBombFlags[0] & 0x20: return DropAimedBomb1(tile, vram, xp)  # bomb 0 still exploding
	ldh a, [hBombFlags]
	bit 5, a
	jp nz, DropAimedBomb1

;> if hActiveShots & 0x04: return DropBomb1(tile, vram, xp)         # bomb 0 is falling
	ldh a, [hActiveShots]
	bit 2, a
	jp nz, DropBomb1

;> hActiveShots |= 0x04                  # drop bomb 0 below the invader's middle
	set 2, a
	ldh [hActiveShots], a
;> wBomb0SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb0SpriteX], a
;> wBomb0SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hld]
	add $08
	ld [wBomb0SpriteY], a
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;@ def DropAimedBomb1(tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ Drops bomb 1 below the invader if it is free; otherwise the invader goes on to DropBomb2.
;@ writes: hActiveShots, wBomb1SpriteX, wBomb1SpriteY
;@ reads: hActiveShots, hBombFlags
;@ test: skip part of the march, needs a formation entry
;@ sig: 86ed5043
DropAimedBomb1::
;> if hBombFlags[1] & 0x20: return DropBomb2(tile, vram, xp)       # bomb 1 still exploding
	ldh a, [hBombFlags + 1]
	bit 5, a
	jp nz, DropBomb2

;> if hActiveShots & 0x08: return DropBomb2(tile, vram, xp)        # bomb 1 is falling
	ldh a, [hActiveShots]
	bit 3, a
	jp nz, DropBomb2

;> hActiveShots |= 0x08
	set 3, a
	ldh [hActiveShots], a
;> wBomb1SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb1SpriteX], a
;> wBomb1SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hld]
	add $08
	ld [wBomb1SpriteY], a
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;@ def UnusedDropAimedBomb2(tile: b, vram: de, xp: hl)
;@ path: unused
;@ Nothing calls this: drops bomb 2 below the invader if it is free, like DropAimedBomb1 does with
;@ bomb 1.
;@ writes: hActiveShots, wBomb2SpriteX, wBomb2SpriteY
;@ reads: hActiveShots, hBombFlags
;@ test: skip unused, part of the march
;@ sig: 99956e85
UnusedDropAimedBomb2::
;> if hBombFlags[2] & 0x20: return StoreInvaderAddr(vram, xp)
	ldh a, [hBombFlags + 2]
	bit 5, a
	jp nz, StoreInvaderAddr

;> if hActiveShots & 0x10: return StoreInvaderAddr(vram, xp)
	ldh a, [hActiveShots]
	bit 4, a
	jp nz, StoreInvaderAddr

;> hActiveShots |= 0x10
	set 4, a
	ldh [hActiveShots], a
;> wBomb2SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb2SpriteX], a
;> wBomb2SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hld]
	add $08
	ld [wBomb2SpriteY], a
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;@ def AdvanceBombTurn(turn: c, tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ The bomb turn of an invader (byte 5 of its entry) cycles through the three bombs: turns 1, 2, 3
;@ drop bomb 0, 1, 2 (when it is free and the bomb rate allows); after a drop the turn becomes 4, 5, 6,
;@ which waits until that bomb is gone and then moves on to the next bomb's turn (6 back to 1).
;@ reads: hActiveShots
;@ test: skip part of the march, needs a formation entry
;@ sig: fdd22652
AdvanceBombTurn::
;> if turn == 1: return DropBomb0(tile, vram, xp)
	ld a, c
	cp $01
	jp z, DropBomb0

;> if turn == 2: return DropBomb1(tile, vram, xp)
	cp $02
	jp z, DropBomb1

;> if turn == 3: return DropBomb2(tile, vram, xp)
	cp $03
	jp z, DropBomb2

;> if turn == 4:
	cp $04
	jp z, .wait0

;>@w0     if hActiveShots & 0x04 == 0:   # bomb 0 gone: bomb 1 next
;>@w0a         mem[xp + 2] = 2
;> elif turn == 5:
	cp $05
	jp z, .wait1

;>@w1     if hActiveShots & 0x08 == 0:   # bomb 1 gone: bomb 2 next
;>@w1a         mem[xp + 2] = 3
;> elif hActiveShots & 0x10 == 0:        # turn 6, bomb 2 gone: bomb 0 next
	ldh a, [hActiveShots]
	bit 4, a
	jp nz, StoreInvaderAddr

;>     mem[xp + 2] = 1
	inc hl
	inc hl
	ld a, $01
	ld [hld], a
	dec hl
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;=@w0
.wait0
	ldh a, [hActiveShots]
	bit 2, a
	jp nz, StoreInvaderAddr

;=@w0a
	inc hl
	inc hl
	ld a, $02
	ld [hld], a
	dec hl
	jp StoreInvaderAddr


;=@w1
.wait1
	ldh a, [hActiveShots]
	bit 3, a
	jp nz, StoreInvaderAddr

;=@w1a
	inc hl
	inc hl
	ld a, $03
	ld [hld], a
	dec hl
	jp StoreInvaderAddr


;@ def DropBomb0(tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ Turn 1: drops bomb 0 below the invader when the bomb rate allows it (hTimerHi AND wBombRateMask)
;@ and the bomb is free, and sets the turn to 4. From wHomingLevel 9 on (and with 2 or more invaders
;@ left) the bomb homes in on the cannon. In a link game no bomb 0 is dropped; the turn just moves on.
;@ writes: hActiveShots, wBomb0HomingTimer, wBomb0SpriteX, wBomb0SpriteY, wHomingBombs
;@ reads: hActiveShots, hBombFlags, hInvadersLeft, hLinkFlags, hTimerHi, wBombRateMask, wHomingBombs, wHomingLevel
;@ test: skip part of the march, needs a formation entry
;@ sig: a27e8b32
DropBomb0::
;> if hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, .link

;>@l1     if hTimerHi & wBombRateMask:
;>@l2         mem[xp + 2] = 4
;>@l3     return StoreInvaderAddr(vram, xp)
;> if hTimerHi & wBombRateMask == 0: return StoreInvaderAddr(vram, xp)
	ldh a, [hTimerHi]
	ld c, a
	ld a, [wBombRateMask]
	and c
	jp z, StoreInvaderAddr

;> if hBombFlags[0] & 0x20: return StoreInvaderAddr(vram, xp)      # still exploding
	ldh a, [hBombFlags]
	bit 5, a
	jp nz, StoreInvaderAddr

;> if hActiveShots & 0x04: return StoreInvaderAddr(vram, xp)       # still falling
	ldh a, [hActiveShots]
	bit 2, a
	jp nz, StoreInvaderAddr

;> hActiveShots |= 0x04
	set 2, a
	ldh [hActiveShots], a
;> wBomb0SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb0SpriteX], a
;> wBomb0SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hli]
	add $08
	ld [wBomb0SpriteY], a
;> mem[xp + 2] = 4
	ld a, $04
	ld [hld], a
	dec hl
;> if hLinkFlags & 0x01: return StoreInvaderAddr(vram, xp)
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, StoreInvaderAddr

;> if wHomingLevel < 0x09: return StoreInvaderAddr(vram, xp)
	ld a, [wHomingLevel]
	cp $09
	jp c, StoreInvaderAddr

;> if hInvadersLeft < 2: return StoreInvaderAddr(vram, xp)
	ldh a, [hInvadersLeft]
	cp $02
	jp c, StoreInvaderAddr

;> wHomingBombs |= 0x01                  # this bomb steers toward the cannon
	ld a, [wHomingBombs]
	set 0, a
	ld [wHomingBombs], a
;> wBomb0HomingTimer = 0
	xor a
	ld [wBomb0HomingTimer], a
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;=@l1
.link
	ldh a, [hTimerHi]
	ld c, a
	ld a, [wBombRateMask]
	and c
	jp z, StoreInvaderAddr

;=@l2
	inc hl
	inc hl
	ld a, $04
	ld [hld], a
	dec hl
;=@l3
	jp StoreInvaderAddr


;@ def DropBomb1(tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ Turn 2: drops bomb 1 below the invader when the bomb rate allows it and the bomb is free, and sets
;@ the turn to 5. It homes in on the cannon when wHomingBombs bit 1 says so, or in a normal game
;@ from wHomingLevel $31 on.
;@ writes: hActiveShots, wBomb1HomingTimer, wBomb1SpriteX, wBomb1SpriteY, wHomingBombs
;@ reads: hActiveShots, hBombFlags, hLinkFlags, hTimerHi, wBombRateMask, wHomingBombs, wHomingLevel
;@ test: skip part of the march, needs a formation entry
;@ sig: f9394fe0
DropBomb1::
;> if hTimerHi & wBombRateMask == 0: return StoreInvaderAddr(vram, xp)
	ldh a, [hTimerHi]
	ld c, a
	ld a, [wBombRateMask]
	and c
	jp z, StoreInvaderAddr

;> if hBombFlags[1] & 0x20: return StoreInvaderAddr(vram, xp)      # still exploding
	ldh a, [hBombFlags + 1]
	bit 5, a
	jp nz, StoreInvaderAddr

;> if hActiveShots & 0x08: return StoreInvaderAddr(vram, xp)       # still falling
	ldh a, [hActiveShots]
	bit 3, a
	jp nz, StoreInvaderAddr

;> hActiveShots |= 0x08
	set 3, a
	ldh [hActiveShots], a
;> wBomb1SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb1SpriteX], a
;> wBomb1SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hli]
	add $08
	ld [wBomb1SpriteY], a
;> mem[xp + 2] = 5
	ld a, $05
	ld [hld], a
	dec hl
;> if wHomingBombs & 0x02 == 0:
	ld a, [wHomingBombs]
	bit 1, a
	jr nz, .homing

;>     if hLinkFlags & 0x01: return StoreInvaderAddr(vram, xp)
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, StoreInvaderAddr

;>     if wHomingLevel < 0x31: return StoreInvaderAddr(vram, xp)
	ld a, [wHomingLevel]
	cp $31
	jp c, StoreInvaderAddr

;> wHomingBombs |= 0x04                  # this bomb steers toward the cannon
.homing
	ld a, [wHomingBombs]
	set 2, a
	ld [wHomingBombs], a
;> wBomb1HomingTimer = 0
	xor a
	ld [wBomb1HomingTimer], a
;> return StoreInvaderAddr(vram, xp)
	jp StoreInvaderAddr


;@ def DropBomb2(tile: b, vram: de, xp: hl)
;@ path: shots/bombs/drop
;@ Turn 3: drops bomb 2 below the invader when the bomb rate allows it and the bomb is free, and sets
;@ the turn to 6.
;@ writes: hActiveShots, wBomb2SpriteX, wBomb2SpriteY
;@ reads: hActiveShots, hBombFlags, hTimerHi, wBombRateMask
;@ test: skip part of the march, needs a formation entry
;@ sig: 47f82585
DropBomb2::
;> if hTimerHi & wBombRateMask == 0: return StoreInvaderAddr(vram, xp)
	ldh a, [hTimerHi]
	ld c, a
	ld a, [wBombRateMask]
	and c
	jp z, StoreInvaderAddr

;> if hBombFlags[2] & 0x20: return StoreInvaderAddr(vram, xp)      # still exploding
	ldh a, [hBombFlags + 2]
	bit 5, a
	jp nz, StoreInvaderAddr

;> if hActiveShots & 0x10: return StoreInvaderAddr(vram, xp)       # still falling
	ldh a, [hActiveShots]
	bit 4, a
	jp nz, StoreInvaderAddr

;> hActiveShots |= 0x10
	set 4, a
	ldh [hActiveShots], a
;> wBomb2SpriteX = mem[xp] + (tile & 0x0F) - 1 + 8
	ld a, b
	and $0f
	dec a
	add [hl]
	add $08
	ld [wBomb2SpriteX], a
;> wBomb2SpriteY = mem[xp + 1] + 8
	inc hl
	ld a, [hli]
	add $08
	ld [wBomb2SpriteY], a
;> mem[xp + 2] = 6
	ld a, $06
	ld [hld], a
	dec hl
;> return StoreInvaderAddr(vram, xp)    # (runs on into it)

;@ def StoreInvaderAddr(vram: de, xp: hl)
;@ path: invaders/march
;@ Ends an invader's step: writes its (possibly moved) tilemap address back into its entry.
;@ test: xp = rand(0xD003, 0xD100)
;@ sig: c2102e1b
StoreInvaderAddr::
;> mem[xp - 1] = lo(vram)
	dec hl
	ld [hl], e
;> mem[xp - 2] = hi(vram)
	dec hl
	ld [hl], d
;> return
	ret


;@ def EndMarchSweep()
;@ path: invaders/march
;@ Every invader has moved once. In a normal game a secret kill order found by CheckKillOrder now
;@ takes effect, once: the bottom row shot from right to left wipes the formation off the screen
;@ (one sweep) and builds it again, the order 8 then 1 repairs the shields, and the right column
;@ and every second column after it, bottom to top, stop the bombs. Then the next sweep starts.
;@ writes: hMarchFlags
;@ reads: hLinkFlags, hMarchFlags, wKillCodeFlags
;@ test: skip runs on into the march of the first invader
;@ sig: 741339ae
EndMarchSweep::
;> if hLinkFlags & 0x01: return StartMarchSweep()
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, StartMarchSweep

;> code = wKillCodeFlags
	ld a, [wKillCodeFlags]
;> if code == 0: return StartMarchSweep()
	and a
	jr z, StartMarchSweep

;> if code & 0x80: return StartMarchSweep()      # already used
	ld c, a
	ldh a, [hMarchFlags]
	bit 7, c
	jr nz, StartMarchSweep

;> if code & 0x01:                       # wipe and rebuild
	bit 0, c
	jr nz, .rebuild

;>@r1     hMarchFlags |= 0x08
;>@r2     if hMarchFlags & 0x01: return KillCodeRebuild()    # the wipe sweep is done
;>@r3     hMarchFlags |= 0x01            # the coming sweep wipes every invader off the screen
;>@r4     return StartMarchSweep()
;> if code & 0x08: return KillCodeShields()
	bit 3, c
	jr nz, KillCodeShields

;> if code & 0x10: return KillCodeNoBombs()
	bit 4, c
	jr nz, KillCodeNoBombs

;> return KillCodeDone()
	jr KillCodeDone

;=@r1
.rebuild
	ldh a, [hMarchFlags]
	set 3, a
	ldh [hMarchFlags], a
;=@r2
	bit 0, a
	jr nz, KillCodeRebuild

;=@r3
	set 0, a
	ldh [hMarchFlags], a
;=@r4
	jp StartMarchSweep


;@ def UnusedJump_155C()
;@ path: unused
;@ Nothing jumps here: a leftover jump to StartMarchSweep.
;@ test: skip unused
;@ sig: f22f07a3
UnusedJump_155C::
;> return StartMarchSweep()
	jp StartMarchSweep


;@ def UnusedJump_155F()
;@ path: unused
;@ Nothing jumps here: a leftover jump to StartMarchSweep.
;@ test: skip unused
;@ sig: f22f07a3
UnusedJump_155F::
;> return StartMarchSweep()
	jp StartMarchSweep


;@ def UnusedJump_1562()
;@ path: unused
;@ Nothing jumps here: a leftover jump to StartMarchSweep.
;@ test: skip unused
;@ sig: f22f07a3
UnusedJump_1562::
;> return StartMarchSweep()
	jp StartMarchSweep


;@ def KillCodeNoBombs()
;@ path: invaders/kill-codes
;@ Secret kill order effect: the invaders drop no more bombs this round.
;@ writes: wBombRateMask
;@ test: skip runs on into the march of the first invader
;@ sig: 318d8deb
KillCodeNoBombs::
;> wBombRateMask = 0
	xor a
	ld [wBombRateMask], a
;> return KillCodeDone()
	jp KillCodeDone


;@ def KillCodeShields()
;@ path: invaders/kill-codes
;@ Secret kill order effect: the shields are restored to new.
;@ writes: hMarchFlags
;@ reads: hMarchFlags
;@ test: skip runs on into the march of the first invader
;@ sig: 3e8623ad
KillCodeShields::
;> hMarchFlags |= 0x08
	ldh a, [hMarchFlags]
	set 3, a
	ldh [hMarchFlags], a
;> ResetShields()
	call ResetShields
;> return KillCodeDone()
	jp KillCodeDone


;@ def KillCodeRebuild()
;@ path: invaders/kill-codes
;@ Secret kill order effect, after the wipe sweep: a complete new formation of 40 invaders.
;@ test: skip runs on into the march of the first invader
;@ sig: 3251cf50
KillCodeRebuild::
;> SetupFormation()
	call SetupFormation
;> return KillCodeDone()
	jr KillCodeDone

;@ def KillCodeDone()
;@ path: invaders/kill-codes
;@ Marks the secret kill order as used (bit 7) and starts the next sweep.
;@ writes: hMarchFlags, wKillCodeFlags
;@ reads: wKillCodeFlags
;@ test: skip runs on into the march of the first invader
;@ sig: 51cfbb4c
KillCodeDone::
;> hMarchFlags = 0
	xor a
	ldh [hMarchFlags], a
;> wKillCodeFlags |= 0x80
	ld a, [wKillCodeFlags]
	set 7, a
	ld [wKillCodeFlags], a
;> return StartMarchSweep()              # (runs on into it)

;@ def StartMarchSweep()
;@ path: invaders/march
;@ Starts a new sweep of the formation: entry 0 moves right now, the others one per frame. A sweep
;@ after a down step turns the formation around; a sweep after an invader touched an edge goes down
;@ (with the secret option wCheatFlags bit 5 the formation turns at once instead). Then the fine
;@ step moves 2 pixels in the marching direction.
;@ writes: hMarchDescend, hMarchEdgeHit, hMarchLeftward, hMarchPhase, hMarchPtrHi, hMarchPtrLo, hMarchRemoved, hMarchToGo, wBombHoldoff
;@ reads: hInvadersLeft, hMarchDescend, hMarchEdgeHit, hMarchLeftward, hMarchPhase, wBombHoldoff, wCheatFlags
;@ test: skip runs on into the march of the first invader
;@ sig: 3e663b0c
StartMarchSweep::
;> if wBombHoldoff: wBombHoldoff -= 1
	ld a, [wBombHoldoff]
	and a
	jr z, .holdoffDone

	dec a
	ld [wBombHoldoff], a

;> hMarchToGo = hInvadersLeft - 1
.holdoffDone
	ldh a, [hInvadersLeft]
	dec a
	ldh [hMarchToGo], a
;> hMarchRemoved = 0
	xor a
	ldh [hMarchRemoved], a
;> hMarchPtrHi = hi(wInvaders)
	ld hl, wInvaders
	ld a, h
	ldh [hMarchPtrHi], a
;> hMarchPtrLo = 0x07                    # next comes entry 1
	ld a, $07
	ldh [hMarchPtrLo], a
;> turn = hMarchDescend                  # it just went down: now turn around
	ldh a, [hMarchDescend]
	and a
;> if not turn:
	jr z, .edge

;>@e1     if hMarchEdgeHit:
;>@e2         hMarchDescend = hMarchEdgeHit        # this sweep goes down
;>@e3         hMarchEdgeHit = 0
;>@e4         turn = wCheatFlags & 0x20            # secret option: no down steps
;> if turn:
;>     hMarchDescend = 0
.turn
	xor a
	ldh [hMarchDescend], a
;>     hMarchLeftward = 0 if hMarchLeftward == 1 else 1
	ldh a, [hMarchLeftward]
	dec a
	jr z, .setDirection

	ld a, $01

.setDirection
	ldh [hMarchLeftward], a
	jr .phase

;=@e1
.edge
	ldh a, [hMarchEdgeHit]
	and a
	jr z, .phase

;=@e2
	ldh [hMarchDescend], a
;=@e3
	xor a
	ldh [hMarchEdgeHit], a
;=@e4
	ld a, [wCheatFlags]
	bit 5, a
	jr nz, .turn

;> if not hMarchLeftward:
.phase
	ldh a, [hMarchLeftward]
	and a
	jr nz, .leftward

;>     hMarchPhase += 2
	ldh a, [hMarchPhase]
	inc a
	inc a
	ldh [hMarchPhase], a
;>     if hMarchPhase == 8:
	cp $08
	jp nz, MoveInvader

;>         hMarchPhase = 0
	xor a
	ldh [hMarchPhase], a
;>     return MoveInvader(wInvaders)
	jp MoveInvader


;> else:
;>     hMarchPhase = u8(hMarchPhase - 2)
.leftward
	ldh a, [hMarchPhase]
	dec a
	dec a
	ldh [hMarchPhase], a
;>     if hMarchPhase == 0xFE:
	cp $fe
	jp nz, MoveInvader

;>         hMarchPhase = 6
	ld a, $06
	ldh [hMarchPhase], a
;>     return MoveInvader(wInvaders)
	jp MoveInvader


;@ def RemoveDeadInvader(xp: hl)
;@ path: invaders/march
;@ Takes a shot invader out of wInvaders when its turn in the sweep comes (xp points at its X): the
;@ entries behind it move down one place, so the list stays packed. Its bomb turn goes to the next
;@ invader in the same column (the one above it), and its number goes to wLastKill.
;@ writes: hHitPixelX, hHitPixelY, hHitTile, hInvadersLeft, hMarchPtrHi, hMarchPtrLo, hMarchRemoved, hMarchToGo, wLastKill
;@ reads: hHitPixelX, hHitTile, hInvadersLeft, hMarchRemoved, hMarchToGo
;@ test: hMarchToGo = rand(0, 10)
;@ test: hMarchRemoved = rand(0, 3)
;@ test: hInvadersLeft = rand(12, 40)
;@ test: xp = rand(0xD003, 0xD010)
;@ sig: 3492d404
RemoveDeadInvader::
;> hHitPixelX = mem[xp]                  # (scratch) its X, i.e. its column
	ld a, [hli]
	ldh [hHitPixelX], a
;> hHitPixelY = mem[xp + 1] - 8          # (scratch, not used further)
	ld a, [hli]
	sub $08
	ldh [hHitPixelY], a
;> hHitTile = mem[xp + 2]                # (scratch) its bomb turn
	ld a, [hli]
	ldh [hHitTile], a
;> wLastKill = mem[xp + 3]               # its number, for the secret kill orders
	ld a, [hld]
	ld [wLastKill], a
;> dst = xp - 3                          # the entry itself
	dec hl
	dec hl
	dec hl
	dec hl
	dec hl
;> hMarchPtrHi = hi(dst)                 # the entry moving into this slot is the next to step
	ld d, h
	ld e, l
	ld a, h
	ldh [hMarchPtrHi], a
;> hMarchPtrLo = lo(dst)
	ld a, l
	ldh [hMarchPtrLo], a
;> src = dst + 7
	ld hl, $0007
	add hl, de
;> n = hMarchToGo
	ldh a, [hMarchToGo]
	ld b, a
;> hMarchToGo = n + 1
	inc a
	ldh [hMarchToGo], a

;>@loop while n != hMarchRemoved:        # the entries behind it, one place down
.loop
	ldh a, [hMarchRemoved]
	cp b
	jr z, .done

;>     n -= 1
	dec b
;>@c4     copy(dst, src, 4)              # tile, tilemap address, X
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
;=@c4
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
;>     if mem[src + 3] != hHitPixelX:
	ld c, a
	ldh a, [hHitPixelX]
	cp c
	jr z, .sameColumn

;>@c3         copy(dst + 4, src + 4, 3)  # Y, bomb turn, number
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
;=@c3
	ld a, [hli]
	ld [de], a
	inc de
;=@loop
	jr .loop

;>     else:                             # the next invader up the same column
;>         mem[dst + 4] = mem[src + 4]
.sameColumn
	ld a, [hli]
	ld [de], a
	inc de
;>         mem[dst + 5] = hHitTile       # takes over the bomb turn
	ld a, [hli]
	ldh a, [hHitTile]
	ld [de], a
	inc de
;>         hHitTile = 0                  # (only the first one)
	xor a
	ldh [hHitTile], a
;>         mem[dst + 6] = mem[src + 6]
	ld a, [hli]
	ld [de], a
	inc de
;>     src, dst = src + 7, dst + 7
;=@loop
	jr .loop

;> hMarchRemoved += 1                    # the sweep ends one entry earlier
.done
	inc a
	ldh [hMarchRemoved], a
;> hInvadersLeft -= 1
	ldh a, [hInvadersLeft]
	dec a
	ldh [hInvadersLeft], a
;> return
	ret


;@ def WipeInvader(vram: de, xp: hl)
;@ path: invaders/kill-codes
;@ During the wipe sweep of a secret kill order: clears the invader's two tiles (through the LCD
;@ interrupt) instead of moving it.
;@ writes: hLcdHook, hSavedIE, hVramAddrHi, hVramAddrLo
;@ reads: hLcdHook, hSavedIE
;@ test: skip waits for the LCD interrupt to clear the tiles
;@ sig: 6667e495
WipeInvader::
;> hVramAddrHi = hi(vram)
	ld a, d
	ldh [hVramAddrHi], a
;> hVramAddrLo = lo(vram)
	ld a, e
	ldh [hVramAddrLo], a
;> hSavedIE = rIE                        # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;> rIF = 0
	xor a
	ldh [rIF], a
;> rIE = 0x03
	ld a, $03
	ldh [rIE], a
;> hLcdHook = lo(LcdClearTilePair)
	ld a, LOW(LcdClearTilePair)
	ldh [hLcdHook], a

.wait
;> while hLcdHook: LcdClearTilePair()    # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .wait

;> rIF = 0
	xor a
	ldh [rIF], a
;> rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;> mem[xp - 1] = lo(vram)
	dec hl
	ld [hl], e
;> mem[xp - 2] = hi(vram)
	dec hl
	ld [hl], d
;> return
	ret


;@ def UnusedDrawInvaderTile(tile: b, vram: de, xp: hl)
;@ path: unused
;@ Nothing calls this: draws an invader as a single tile through the LCD interrupt (with
;@ hMarchFlags bit 2 one of the tiles $C8-$CA by its kind), then goes on like MoveInvader with the
;@ bomb turn.
;@ writes: hLcdHook, hSavedIE, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hLcdHook, hMarchFlags, hSavedIE
;@ test: skip unused, waits for the LCD interrupt
;@ sig: 7056b9aa
UnusedDrawInvaderTile::
;> if hMarchFlags & 0x04:
	ldh a, [hMarchFlags]
	bit 2, a
	jr z, .normal

;>     t = (tile >> 4) - 0x0D + 0xC8
	ld a, b
	and $f0
	swap a
	sub $0d
	add $c8
;=@else
	jr .draw

;>@else else:
;>     t = (tile & 0xF0) + 1
.normal
	ld a, b
	and $f0
	inc a

;> hVramData0 = t
.draw
	ldh [hVramData0], a
;> hVramAddrHi = hi(vram)
	ld a, d
	ldh [hVramAddrHi], a
;> hVramAddrLo = lo(vram)
	ld a, e
	ldh [hVramAddrLo], a
;> hSavedIE = rIE
	ldh a, [rIE]
	ldh [hSavedIE], a
;> rIF = 0
	xor a
	ldh [rIF], a
;> rIE = 0x03
	ld a, $03
	ldh [rIE], a
;> hLcdHook = lo(LcdWriteTile)
	ld a, LOW(LcdWriteTile)
	ldh [hLcdHook], a

.wait
;> while hLcdHook: LcdWriteTile()
	ldh a, [hLcdHook]
	and a
	jr nz, .wait

;> rIF = 0
	xor a
	ldh [rIF], a
;> rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;> if mem[xp + 2]: return InvaderBombTurn(mem[xp + 2], tile, vram, xp)
	inc hl
	inc hl
	ld a, [hld]
	dec hl
	and a
	jp nz, InvaderBombTurn

;> mem[xp - 1] = lo(vram)
	dec hl
	ld [hl], e
;> mem[xp - 2] = hi(vram)
	dec hl
	ld [hl], d
;> return
	ret


;@ def CheckKillOrder()
;@ path: invaders/kill-codes
;@ Normal game: records the number of each invader shot (wLastKill) in wKillOrder and compares the
;@ record with the three secret kill orders. The first one that matches sets its bit in
;@ wKillCodeFlags; EndMarchSweep then carries it out once.
;@ writes: wKillCodeFlags, wKillCount, wLastKill
;@ reads: hLinkFlags, wKillCodeFlags, wKillCount, wLastKill
;@ test: wKillCodeFlags = rng.choice([0, 0, 0, 0x01, 0x80])
;@ test: wKillCount = rand(0, 12)
;@ test: wLastKill = rand(0, 40)
;@ sig: 8f7fe296
CheckKillOrder::
;> if hLinkFlags & 0x01: return
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, .done

;> if wKillCodeFlags & 0x80: return      # used up
	ld a, [wKillCodeFlags]
	bit 7, a
	jp nz, .done

;> if wKillCodeFlags: return             # one is waiting to be carried out
	and a
	jp nz, .done

;> n = wLastKill
	ld a, [wLastKill]
	ld c, a
;> wLastKill = 0
	xor a
	ld [wLastKill], a
;> if n == 0: return                     # nobody shot since the last check
	ld a, c
	and a
	jp z, .done

;> if n == 0xFF:                         # (never stored: would stop the checks)
	cp $ff
	jr nz, .record

;>     wKillCodeFlags |= 0x80
	ld a, [wKillCodeFlags]
	set 7, a
	ld [wKillCodeFlags], a
;>     return
	jp .done


;>@rec wKillOrder[wKillCount] = n
.record
	ld a, [wKillCount]
	ld e, a
	ld d, $00
	ld hl, wKillOrder
	add hl, de
;=@rec
	ld a, c
	ld [hl], a
;> wKillCount += 1
	inc e
	ld a, e
	ld [wKillCount], a
;> if MatchKillOrder(KillOrderRebuild) == 0:
	ld de, KillOrderRebuild
	call MatchKillOrder
	and a
	jr nz, .tryShields

;>     wKillCodeFlags |= 0x01
	ld a, [wKillCodeFlags]
	set 0, a
	ld [wKillCodeFlags], a
	jr .done

;> elif MatchKillOrder(KillOrderShields) == 0:
.tryShields
	ld de, KillOrderShields
	call MatchKillOrder
	and a
	jr nz, .tryNoBombs

;>     wKillCodeFlags |= 0x08
	ld a, [wKillCodeFlags]
	set 3, a
	ld [wKillCodeFlags], a
	jr .done

;> elif MatchKillOrder(KillOrderNoBombs) == 0:
.tryNoBombs
	ld de, KillOrderNoBombs
	call MatchKillOrder
	and a
	jr nz, .done

;>     wKillCodeFlags |= 0x10
	ld a, [wKillCodeFlags]
	set 4, a
	ld [wKillCodeFlags], a
	jr .done

;> return
.done
	ret


;@ def MatchKillOrder(order: de) -> a
;@ path: invaders/kill-codes
;@ Compares the start of wKillOrder with a 0-terminated list of invader numbers: 0 if they match
;@ all the way, $FF if not.
;@ test: order = rng.choice([0x174B, 0x1754, 0x176C])
;@ sig: 5656a4d2
MatchKillOrder::
;> p = wKillOrder
	ld hl, wKillOrder

;>@loop while mem[order]:
.loop
	ld a, [de]
	and a
	jr z, .match

;>     n = mem[order]
	ld c, a
;>     order += 1
	inc de
;>     if mem[p] != n:
	ld a, [hli]
	cp c
;>@ne         return 0xFF
;>     p += 1
;=@loop
	jr z, .loop

;=@ne
	ld a, $ff
	jr .return

;> return 0
.match
	ld a, $00

.return
	ret


;@ path: invaders/kill-codes
;@ Secret kill order (0-terminated invader numbers, see FormationLayout): the bottom row from right to
;@ left, 8 down to 1. Found by CheckKillOrder, it wipes the formation and builds a full new one.
KillOrderRebuild::
	db $08, $07, $06, $05, $04, $03, $02, $01, $00

;@ path: invaders/kill-codes
;@ Secret kill order: first the bottom right invader (8), then the bottom left one (1). It restores
;@ the shields.
KillOrderShields::
	db $08, $01, $00

;@ path: invaders/kill-codes
;@ A kill order nothing checks: columns 2, 4, 6 and 8, each from the bottom up.
KillOrderUnused::
	db $02, $0a, $12, $1a, $22
	db $04, $0c, $14, $1c, $24
	db $06, $0e, $16, $1e, $26
	db $08, $10, $18, $20, $28
	db $00

;@ path: invaders/kill-codes
;@ Secret kill order: columns 8, 6, 4 and 2, each from the bottom up. It stops the bombs for the
;@ rest of the round.
KillOrderNoBombs::
	db $08, $10, $18, $20, $28
	db $06, $0e, $16, $1e, $26
	db $04, $0c, $14, $1c, $24
	db $02, $0a, $12, $1a, $22
	db $00

;@ path: invaders/kill-codes
;@ A second copy of the order 8, 1 that nothing checks.
KillOrderUnused2::
	db $08, $01, $00

;@ path: invaders/setup
;@ The formation at the start of a round: 40 entries of 7 bytes, copied to wInvaders by
;@ SetupFormation (moved down by FormationDropTable). Each entry: tile (kind | 1: $D1 the two bottom
;@ rows, 10 points; $E1 the two middle rows, 20; $F1 the top row, 30), tilemap address (high byte
;@ first; 2 tiles wide, starting at column 2 of row 6), X, Y, bomb turn (1 for the bottom row, which
;@ has nobody below it), number 1-40. Numbers go from left to right, bottom row first: number n is
;@ in column (n - 1) % 8 + 1 of row (n - 1) / 8 from the bottom.
FormationLayout::
	db $d1, $98, $c2, $10, $40, $01, $01
	db $d1, $98, $c4, $20, $40, $01, $02
	db $d1, $98, $c6, $30, $40, $01, $03
	db $d1, $98, $c8, $40, $40, $01, $04
	db $d1, $98, $ca, $50, $40, $01, $05
	db $d1, $98, $cc, $60, $40, $01, $06
	db $d1, $98, $ce, $70, $40, $01, $07
	db $d1, $98, $d0, $80, $40, $01, $08
	db $d1, $98, $a2, $10, $38, $00, $09
	db $d1, $98, $a4, $20, $38, $00, $0a
	db $d1, $98, $a6, $30, $38, $00, $0b
	db $d1, $98, $a8, $40, $38, $00, $0c
	db $d1, $98, $aa, $50, $38, $00, $0d
	db $d1, $98, $ac, $60, $38, $00, $0e
	db $d1, $98, $ae, $70, $38, $00, $0f
	db $d1, $98, $b0, $80, $38, $00, $10
	db $e1, $98, $82, $10, $30, $00, $11
	db $e1, $98, $84, $20, $30, $00, $12
	db $e1, $98, $86, $30, $30, $00, $13
	db $e1, $98, $88, $40, $30, $00, $14
	db $e1, $98, $8a, $50, $30, $00, $15
	db $e1, $98, $8c, $60, $30, $00, $16
	db $e1, $98, $8e, $70, $30, $00, $17
	db $e1, $98, $90, $80, $30, $00, $18
	db $e1, $98, $62, $10, $28, $00, $19
	db $e1, $98, $64, $20, $28, $00, $1a
	db $e1, $98, $66, $30, $28, $00, $1b
	db $e1, $98, $68, $40, $28, $00, $1c
	db $e1, $98, $6a, $50, $28, $00, $1d
	db $e1, $98, $6c, $60, $28, $00, $1e
	db $e1, $98, $6e, $70, $28, $00, $1f
	db $e1, $98, $70, $80, $28, $00, $20
	db $f1, $98, $42, $10, $20, $00, $21
	db $f1, $98, $44, $20, $20, $00, $22
	db $f1, $98, $46, $30, $20, $00, $23
	db $f1, $98, $48, $40, $20, $00, $24
	db $f1, $98, $4a, $50, $20, $00, $25
	db $f1, $98, $4c, $60, $20, $00, $26
	db $f1, $98, $4e, $70, $20, $00, $27
	db $f1, $98, $50, $80, $20, $00, $28

;@ def CheckShotHitsBomb()
;@ path: shots/hits
;@ Shots can hit each other: tests the flying cannon shot against the opponent's shot (link game)
;@ and the three invader bombs. An object that is falling, not exploding, and within 8 pixels up or
;@ down and at the shot's X or one pixel right of it is hit; the jump table at ShotHitBomb2 decides
;@ what happens.
;@ reads: hActiveShots, hShotFlags, wShotSpriteX, wShotSpriteY
;@ test: hActiveShots = rand(0, 0x1F)
;@ sig: 3246374a
CheckShotHitsBomb::
;> bits = hActiveShots >> 1
	ldh a, [hActiveShots]
	ld e, a
	srl e
;> if hActiveShots & 0x01 == 0: return   # no shot flying
	jp nc, ShotHitDone

;>@loop for k in range(4):               # the opponent's shot, then bombs 0, 1, 2
	ld d, $04
	ld bc, hLinkShotFlags
	ld hl, wLinkShotSpriteY

;>     active, bits = bits & 1, bits >> 1
.loop
	srl e
;>     if not active: continue
	jr nc, .skipY

;>     obj = 0xC014 + 4 * k              # its sprite: wLinkShotSpriteY, wBomb0SpriteY ...
;>     if k == 0:
	ld a, d
	cp $04
	jr nz, .bomb

;>         if hLinkShotFlags & 0x10: continue    # exploding
	ld a, [bc]
	bit 4, a
	jr nz, .skipY

;=@elif
	jr .test

;>@elif     elif hBombFlags[k - 1] & 0x20: continue  # exploding
.bomb
	ld a, [bc]
	bit 5, a
	jr nz, .skipY

;>     if u8(wShotSpriteY - 8) >= mem[obj]: continue
.test
	ld a, [wShotSpriteY]
	sub $08
	sub [hl]
	jr nc, .skipY

;>     if u8(wShotSpriteY + 8) < mem[obj]: continue
	ld a, [wShotSpriteY]
	add $08
	sub [hl]
	jr c, .skipY

;>     if u8(wShotSpriteX - 1) >= mem[obj + 1]: continue
	ld a, [wShotSpriteX]
	inc l
	dec a
	sub [hl]
	jr nc, .next

;>     if u8(wShotSpriteX + 1) >= mem[obj + 1]:
	ld a, [wShotSpriteX]
	inc a
	sub [hl]
	jr nc, .hit

;>@h1         if hShotFlags & 0x20: return
;>@h2         return (ShotHitLinkShot, ShotHitBomb0, ShotHitBomb1, ShotHitBomb2)[k]()
;=@loop
	jr .next

;=@loop
.skipY
	inc l

;=@loop
.next
	inc l
	inc l
	inc l
	inc bc
	dec d
	jr nz, .loop

;> return
	jr ShotHitReturn

;=@h1
.hit
	ldh a, [hShotFlags]
	bit 5, a
	jr nz, ShotHitReturn

;=@h2
	ld hl, ShotHitBomb2 - 1
	ld a, d
	sla a
	dec a
	ld c, a
	ld b, $00
;=@h2
	add hl, bc
	jp hl


;@ def ShotHitBomb2()
;@ path: shots/hits
;@ Entry 1 of the jump table used by CheckShotHitsBomb (one 2-byte `jr` per object): the cannon's shot met
;@ invader bomb 2. Both are gone: the bomb disappears and the shot bursts.
;@ sig: cd190294
ShotHitBomb2::
;> return RemoveBomb2AndBurstShot()
	jr RemoveBomb2AndBurstShot

;@ def ShotHitBomb1()
;@ path: shots/hits
;@ Entry 2 of the shot-hit jump table: the cannon's shot met invader bomb 1. Only the bomb bursts, the
;@ shot flies on.
;@ sig: 5410532e
ShotHitBomb1::
;> return BurstBomb1()
	jr BurstBomb1

;@ def ShotHitBomb0()
;@ path: shots/hits
;@ Entry 3 of the shot-hit jump table: the cannon's shot met invader bomb 0. Only the shot bursts, the bomb
;@ keeps falling.
;@ sig: 49a7434a
ShotHitBomb0::
;> return BurstShot()
	jr BurstShot

;@ def ShotHitLinkShot()
;@ path: shots/hits
;@ Entry 4 of the shot-hit jump table: in a link game the cannon's shot met the opponent's shot. The
;@ opponent's shot disappears and ours bursts.
;@ sig: 37163ff7
ShotHitLinkShot::
;> return RemoveLinkShotAndBurstShot()
	jr RemoveLinkShotAndBurstShot

;@ def ShotHitNothing()
;@ path: shots/hits
;@ Entry 5 of the shot-hit jump table, never selected (there are only four objects to hit): does nothing.
;@ sig: 16a2cb42
ShotHitNothing::
;> return
	jr ShotHitReturn

;@ def RemoveBomb2AndBurstShot()
;@ path: shots/hits
;@ The cannon's shot destroyed invader bomb 2: the bomb vanishes at once and the shot bursts.
;@ sig: e711ef51
RemoveBomb2AndBurstShot::
;> RemoveBomb2()
	call RemoveBomb2
;> return BurstShot()
	jr BurstShot

;@ def BurstBomb1()
;@ path: shots/hits
;@ Invader bomb 1 was hit by the cannon's shot: it turns into an explosion (TickExplosions removes it
;@ after 32 frames).
;@ writes: hBombFlags, wBomb1SpriteTile
;@ reads: hBombFlags
;@ sig: 17f85a3b
BurstBomb1::
;> hBombFlags[1] |= 0x20                  # bit 5: exploding
	ldh a, [hBombFlags + 1]
	set 5, a
	ldh [hBombFlags + 1], a
;> wBomb1SpriteTile = 0x0A                # explosion picture
	ld a, $0a
	ld [wBomb1SpriteTile], a
;> return
	jr ShotHitReturn

;> # (two unreachable bytes: a stray `jr BurstShot`)
	db $18, $03

;@ def RemoveLinkShotAndBurstShot()
;@ path: shots/hits
;@ The cannon's shot met the opponent's shot (link game): the opponent's shot vanishes and ours bursts.
;@ sig: 23bbe896
RemoveLinkShotAndBurstShot::
;> RemoveLinkShot()
	call RemoveLinkShot
;> BurstShot()                             # falls through

;@ def BurstShot()
;@ path: shots/hits
;@ The cannon's shot has hit something: it turns into an explosion (TickExplosions removes it after 16
;@ frames).
;@ writes: hShotFlags, wShotSpriteTile
;@ reads: hShotFlags
;@ sig: 516b3fb7
BurstShot::
;> hShotFlags |= 0x10                     # bit 4: exploding
	ldh a, [hShotFlags]
	set 4, a
	ldh [hShotFlags], a
;> wShotSpriteTile = 0x0A                 # explosion picture
	ld a, $0a
	ld [wShotSpriteTile], a

ShotHitDone:
ShotHitReturn:
;> return
	ret


;@ def CheckCannonHits()
;@ path: shots/hits
;@ Two collision checks per frame. The UFO: in a one-player game the cannon's shot hits it once the shot is up
;@ in the UFO's row and within its width; in a link game the opponent announces that our shot hit it by
;@ sending $B0 + the lives it has left. Either way bit 7 of hUfoFlags tells the score code. Then the cannon: a
;@ falling bomb (or the opponent's shot) that overlaps it destroys it - unless the object is already exploding,
;@ or the secret invincibility is on (one-player game only).
;@ writes: hUfoFlags, hUfoHitCode
;@ reads: hActiveShots, hLinkFlags, hLinkShotFlags, hSerialIn, hShotFlags, hUfoFlags, wCannonSpriteX, wCannonSpriteY, wCheatFlags, wShotSpriteX, wShotSpriteY, wUfoSpriteX
;@ sig: 31f2a584
CheckCannonHits::
;> if hLinkFlags & 1:
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .onePlayer

;>     hit = (hSerialIn & 0xF0) == 0xB0         # the opponent's "I was hit" message: $B0 + lives left
	ldh a, [hSerialIn]
	and $f0
	cp $b0
	jr nz, .checkCannon

;>     hit = hit and (hSerialIn & 0x0F) < 5
	ldh a, [hSerialIn]
	and $0f
	sub $05
	jr nc, .checkCannon

	jr .hit

;> else:
;>     hit = hActiveShots & 1 and not hShotFlags & 0x10    # the shot flies and is not bursting
.onePlayer
	ldh a, [hActiveShots]
	bit 0, a
	jr z, .checkCannon

	ldh a, [hShotFlags]
	bit 4, a
	jr nz, .checkCannon

;>     hit = hit and wShotSpriteY < 0x1C           # up in the UFO's row
	ld a, [wShotSpriteY]
	sub $1c
	jr nc, .checkCannon

;>     hit = hit and (wUfoSpriteX - 3) % 256 < wShotSpriteX
	ld hl, wShotSpriteX
	ld a, [wUfoSpriteX]
	sub $03
	sub [hl]
	jr nc, .checkCannon

;>     hit = hit and (wShotSpriteX - 8) % 256 < wUfoSpriteX
	ld hl, wUfoSpriteX
	ld a, [wShotSpriteX]
	sub $08
	sub [hl]
	jr nc, .checkCannon

;>     if hit:
;>         RemoveShot()
	call RemoveShot

;> if hit:
;>     hUfoHitCode = hSerialIn
.hit
	ldh a, [hSerialIn]
	ldh [hUfoHitCode], a
;>     hUfoFlags |= 0x80                        # bit 7: the UFO (or the opponent) was hit
	ldh a, [hUfoFlags]
	set 7, a
	ldh [hUfoFlags], a

;> if not hLinkFlags & 1 and wCheatFlags & 0x02:
;>     return                                   # secret: invincible cannon
.checkCannon
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .scan

	ld a, [wCheatFlags]
	bit 1, a
	jp nz, .done

;>@bits bits = hActiveShots >> 1   # bit i: object i flies (0 = the opponent's shot, 1-3 = bombs 0-2)
.scan
	ldh a, [hActiveShots]
	ld e, a
;=@for
	ld d, $04
;> cannon_y, cannon_x = wCannonSpriteY, wCannonSpriteX
	ld a, [wCannonSpriteY]
	ld b, a
	ld a, [wCannonSpriteX]
	ld c, a
;=@for
	ld hl, wLinkShotSpriteY
;=@bits
	srl e

;>@for for i in range(4):                       # their OAM entries follow each other, 4 bytes apart
;>     if not bits >> i & 1:
;>         continue
.loop
	srl e
	jr nc, .skipY

;>     if mem[wLinkShotSpriteY + 4 * i] <= (cannon_y - 4) % 256:
;>         continue                             # above the cannon
	ld a, b
	sub $04
	sub [hl]
	jr nc, .skipY

;>     if mem[wLinkShotSpriteY + 4 * i] > cannon_y:
;>         continue                             # below it
	ld a, b
	sub [hl]
	jr c, .skipY

;>     if mem[wLinkShotSpriteX + 4 * i] <= (cannon_x - 3) % 256:
;>         continue                             # left of it
	ld a, c
	inc l
	sub $03
	sub [hl]
	jr nc, .next

;>     if mem[wLinkShotSpriteX + 4 * i] > (cannon_x + 8) % 256:
;>         continue                             # right of it
	ld a, c
	add $08
	sub [hl]
	jr nc, .found

	jr .next

.skipY
;=@for
	inc l

.next
	inc l
	inc l
	inc l
	dec d
	jr nz, .loop

;=@ret
	jr .done

;>     if i == 0:                               # the opponent's shot
.found
	ld hl, hTemp
	ld a, d
	cp $04
	jr z, .linkShot

;>@ls         if hLinkShotFlags & 0x10:
;>@lr             return                       # a bursting shot does no harm
;>     else:
;>         hTemp = 4 - i
	ld [hl], a
;>         flags = hBombFlags[i - 1]            # (computed as hShotFlags + 5 - hTemp)
	ld a, $05
	sub [hl]
	ld hl, hShotFlags
	add l
	ld l, a
;>         if flags & 0x20:
;>             return                           # nor does an exploding bomb
	bit 5, [hl]
	jr nz, .done

;>@hit     return CannonHit()
	jr .cannonHit

.linkShot
;=@ls
	ldh a, [hLinkShotFlags]
	bit 4, a
;=@lr
	jr nz, .done

.cannonHit
;=@hit
	jp CannonHit


.done
;>@ret return
	ret


;@ def MoveShotsAndBombs()
;@ path: shots/move
;@ Moves everything that flies, once per frame. The cannon's shot climbs 3 pixels and bursts at the top of the
;@ screen (with the secret homing shot it also steers 1 pixel toward the UFO). In a link game the opponent's
;@ shot falls 3 pixels. The three invader bombs fall 1 pixel and burst at the ground; bombs 0 and 1 can be
;@ homing bombs: for 20 frames they note where the cannon is, then steer toward that spot, and so on.
;@ Objects that are already exploding stay where they are.
;@ writes: wBomb0HomingTimer, wBomb0SpriteTile, wBomb0SpriteX, wBomb0SpriteY, wBomb0TargetX, wBomb1HomingTimer, wBomb1SpriteTile, wBomb1SpriteX, wBomb1SpriteY, wBomb1TargetX, wBomb2SpriteTile, wBomb2SpriteY, wCheatFlags, wHomingBombs, wLinkShotSpriteTile, wLinkShotSpriteY, wShotSpriteTile, wShotSpriteX, wShotSpriteY
;@ reads: hActiveShots, hLinkFlags, hUfoFlags, wBomb0HomingTimer, wBomb0SpriteX, wBomb0SpriteY, wBomb0TargetX, wBomb1HomingTimer, wBomb1SpriteX, wBomb1SpriteY, wBomb1TargetX, wBomb2SpriteY, wCannonSpriteX, wCheatFlags, wHomingBombs, wLinkShotSpriteY, wShotSpriteX, wShotSpriteY, wUfoSpriteX
;@ sig: 0a745b0b
MoveShotsAndBombs::
;> active = hActiveShots
	ldh a, [hActiveShots]
	ld b, a
;=@shot
	ld hl, hShotFlags
;> y = wShotSpriteY
	ld a, [wShotSpriteY]
	ld c, a
;>@shot if active & 0x01 and not hShotFlags & 0x10:    # the cannon's shot flies and is not bursting
	bit 0, b
	jp z, .linkShot

	bit 4, [hl]
	jp nz, .linkShot

;>     if y < 0x18:                              # reached the top: burst
	ld a, c
	sub $18
	jp nc, .shotFlies

;>         hShotFlags |= 0x10
	set 4, [hl]
;>         wShotSpriteTile = 0x0A                # explosion picture
	ld a, $0a
	ld [wShotSpriteTile], a
;>         wCheatFlags &= ~0x40                  # the homing shot is used up
	ld a, [wCheatFlags]
	res 6, a
	ld [wCheatFlags], a
	jp .linkShot


;>     else:
;>         homing = not hLinkFlags & 1 and hUfoFlags & 0x02    # one-player game, UFO on screen
.shotFlies
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .shotUp

	ldh a, [hUfoFlags]
	bit 1, a
	jr z, .shotUp

;>         if homing and wCheatFlags & 0x40:
	ld a, [wCheatFlags]
	bit 6, a
	jr z, .shotUp

;>             # secret homing shot: steer toward the UFO
;>             if wShotSpriteX > wUfoSpriteX:
	ld a, [wUfoSpriteX]
	ld c, a
	ld a, [wShotSpriteX]
	cp c
	jr z, .steered

	jr c, .shotRight

;>                 wShotSpriteX -= 1
	dec a
	ld [wShotSpriteX], a
	jr .steered

;>             elif wShotSpriteX < wUfoSpriteX:
;>                 wShotSpriteX += 1
.shotRight
	inc a
	ld [wShotSpriteX], a

;>             y = wShotSpriteY
.steered
	ld a, [wShotSpriteY]
	ld c, a

;>         wShotSpriteY = y - 3
.shotUp
	ld a, c
	sub $03
	ld [wShotSpriteY], a

;> if hLinkFlags & 1:
.linkShot
	inc hl
	ldh a, [hLinkFlags]
	bit 0, a
	jr z, .bomb0

;>     y = wLinkShotSpriteY
	ld a, [wLinkShotSpriteY]
	ld c, a
;>     if active & 0x02 and not hLinkShotFlags & 0x10:   # the opponent's shot falls
	bit 1, b
	jr z, .bomb0

	bit 4, [hl]
	jr nz, .bomb0

;>         if y >= 0x9B:                         # reached the ground: burst
	ld a, c
	sub $9b
	jr c, .linkShotDown

;>             hLinkShotFlags |= 0x10
	set 4, [hl]
;>             wLinkShotSpriteTile = 0x0A
	ld a, $0a
	ld [wLinkShotSpriteTile], a
	jr .bomb0

;>         else:
;>             wLinkShotSpriteY = y + 3
.linkShotDown
	ld a, c
	add $03
	ld [wLinkShotSpriteY], a

;> y = wBomb0SpriteY
.bomb0
	inc hl
	ld a, [wBomb0SpriteY]
	ld c, a
;> if active & 0x04 and not hBombFlags[0] & 0x20:      # bomb 0 falls
	bit 2, b
	jr z, .bomb1

	bit 5, [hl]
	jr nz, .bomb1

;>     if y >= 0x9B:                             # reached the ground: burst
	sub $9b
	jr c, .bomb0Falls

;>         hBombFlags[0] |= 0x20
	set 5, [hl]
;>         wBomb0SpriteTile = 0x0A
	ld a, $0a
	ld [wBomb0SpriteTile], a
;>         wHomingBombs &= ~0x01
	ld a, [wHomingBombs]
	res 0, a
	ld [wHomingBombs], a
	jr .bomb1

;>     else:
;>         if wHomingBombs & 0x01:
.bomb0Falls
	ld a, [wHomingBombs]
	bit 0, a
	jr z, .bomb0Down

;>             wBomb0HomingTimer = (wBomb0HomingTimer - 1) % 256
	ld a, [wBomb0HomingTimer]
	dec a
	ld [wBomb0HomingTimer], a
;>             if wBomb0HomingTimer >= 0xEC:     # first 20 frames of every 256: note the cannon's X
	cp $ec
	jr c, .bomb0Steer

;>                 wBomb0TargetX = (wCannonSpriteX + 3) % 256
	ld a, [wCannonSpriteX]
	add $03
	ld [wBomb0TargetX], a
	jr .bomb0Down

;>             else:                             # the rest of the time steer toward it
;>                 if wBomb0SpriteX > wBomb0TargetX:
.bomb0Steer
	ld a, [wBomb0TargetX]
	ld c, a
	ld a, [wBomb0SpriteX]
	cp c
	jr z, .bomb0Steered

	jr c, .bomb0Right

;>                     wBomb0SpriteX -= 1
	dec a
	ld [wBomb0SpriteX], a
	jr .bomb0Steered

;>                 elif wBomb0SpriteX < wBomb0TargetX:
;>                     wBomb0SpriteX += 1
.bomb0Right
	inc a
	ld [wBomb0SpriteX], a

;>                 y = wBomb0SpriteY
.bomb0Steered
	ld a, [wBomb0SpriteY]
	ld c, a

;>         wBomb0SpriteY = y + 1
.bomb0Down
	ld a, c
	inc a
	ld [wBomb0SpriteY], a

;> y = wBomb1SpriteY
.bomb1
	inc hl
	ld a, [wBomb1SpriteY]
	ld c, a
;> if active & 0x08 and not hBombFlags[1] & 0x20:      # bomb 1 falls (homing works the same as bomb 0's)
	bit 3, b
	jr z, .bomb2

	bit 5, [hl]
	jr nz, .bomb2

;>     if y >= 0x9B:
	sub $9b
	jr c, .bomb1Falls

;>         hBombFlags[1] |= 0x20
	set 5, [hl]
;>         wBomb1SpriteTile = 0x0A
	ld a, $0a
	ld [wBomb1SpriteTile], a
;>         wHomingBombs &= ~0x04
	ld a, [wHomingBombs]
	res 2, a
	ld [wHomingBombs], a
	jr .bomb2

;>     else:
;>         if wHomingBombs & 0x04:
.bomb1Falls
	ld a, [wHomingBombs]
	bit 2, a
	jr z, .bomb1Down

;>             wBomb1HomingTimer = (wBomb1HomingTimer - 1) % 256
	ld a, [wBomb1HomingTimer]
	dec a
	ld [wBomb1HomingTimer], a
;>             if wBomb1HomingTimer >= 0xE5:     # first 27 frames of every 256
	cp $e5
	jr c, .bomb1Steer

;>                 wBomb1TargetX = (wCannonSpriteX + 3) % 256
	ld a, [wCannonSpriteX]
	add $03
	ld [wBomb1TargetX], a
	jr .bomb1Down

;>             else:
;>                 if wBomb1SpriteX > wBomb1TargetX:
.bomb1Steer
	ld a, [wBomb1TargetX]
	ld c, a
	ld a, [wBomb1SpriteX]
	cp c
	jr z, .bomb1Steered

	jr c, .bomb1Right

;>                     wBomb1SpriteX -= 1
	dec a
	ld [wBomb1SpriteX], a
	jr .bomb1Steered

;>                 elif wBomb1SpriteX < wBomb1TargetX:
;>                     wBomb1SpriteX += 1
.bomb1Right
	inc a
	ld [wBomb1SpriteX], a

;>                 y = wBomb1SpriteY
.bomb1Steered
	ld a, [wBomb1SpriteY]
	ld c, a

;>         wBomb1SpriteY = y + 1
.bomb1Down
	ld a, c
	inc a
	ld [wBomb1SpriteY], a

;> y = wBomb2SpriteY
.bomb2
	inc hl
	ld a, [wBomb2SpriteY]
	ld c, a
;> if active & 0x10 and not hBombFlags[2] & 0x20:      # bomb 2 falls (never homing)
	bit 4, b
	jr z, .done

	bit 5, [hl]
	jr nz, .done

;>     if y >= 0x9B:
	sub $9b
	jr c, .bomb2Down

;>         hBombFlags[2] |= 0x20
	set 5, [hl]
;>         wBomb2SpriteTile = 0x0A
	ld a, $0a
	ld [wBomb2SpriteTile], a
	jr .done

;>     else:
;>         wBomb2SpriteY = y + 1
.bomb2Down
	ld a, c
	inc a
	ld [wBomb2SpriteY], a

.done
;> return
	ret


;@ def TickExplosions()
;@ path: shots/hits
;@ Runs the explosion timers, once per frame. An exploding object counts up in the low bits of its state byte
;@ until the exploding bit runs over (16 frames for a shot, 32 for a bomb); then the object is removed.
;@ The opponent's-shot timer also switches off bomb 0's homing on every frame it runs.
;@ writes: wHomingBombs
;@ reads: hActiveShots, wHomingBombs
;@ sig: a749692e
TickExplosions::
;> if hShotFlags & 0x10:                       # the cannon's shot is exploding
	ldh a, [hActiveShots]
	ld b, a
	ld hl, hShotFlags
	bit 4, [hl]
	jr z, .linkShot

;>     hShotFlags += 1
	inc [hl]
;>     if not hShotFlags & 0x10:               # timer ran over
;>         RemoveShot()
	bit 4, [hl]
	call z, RemoveShot

;> if hLinkShotFlags & 0x10:                   # the opponent's shot is exploding
.linkShot
	inc hl
	bit 4, [hl]
	jr z, .bomb0

;>     hLinkShotFlags += 1
	inc [hl]
;>     over = not hLinkShotFlags & 0x10
	bit 4, [hl]
;>     wHomingBombs &= ~0x01
	ld a, [wHomingBombs]
	res 0, a
	ld [wHomingBombs], a
;>     if over:
;>         RemoveLinkShot()
	ldh a, [hActiveShots]
	call z, RemoveLinkShot

;> if hBombFlags[0] & 0x20:                    # bomb 0 is exploding
.bomb0
	inc hl
	bit 5, [hl]
	jr z, .bomb1

;>     hBombFlags[0] += 1
	inc [hl]
;>     if not hBombFlags[0] & 0x20:
;>         RemoveBomb0()
	bit 5, [hl]
	call z, RemoveBomb0

;> if hBombFlags[1] & 0x20:
.bomb1
	inc hl
	bit 5, [hl]
	jr z, .bomb2

;>     hBombFlags[1] += 1
	inc [hl]
;>     if not hBombFlags[1] & 0x20:
;>         RemoveBomb1()
	bit 5, [hl]
	call z, RemoveBomb1

;> if hBombFlags[2] & 0x20:
.bomb2
	inc hl
	bit 5, [hl]
	jr z, .done

;>     hBombFlags[2] += 1
	inc [hl]
;>     if not hBombFlags[2] & 0x20:
;>         RemoveBomb2()
	bit 5, [hl]
	call z, RemoveBomb2

.done
;> return
	ret


;@ def RemoveAllShots()
;@ path: shots/hits
;@ Clears the screen of the cannon's shot, the opponent's shot and all bombs (when the cannon is hit or a
;@ stage starts).
;@ writes: hActiveShots
;@ sig: 7b0e5364
RemoveAllShots::
;> hActiveShots = 0
	and $00
	ldh [hActiveShots], a
;> RemoveShot()
	call RemoveShot
;> RemoveLinkShot()
	call RemoveLinkShot
;> RemoveBomb0()
	call RemoveBomb0
;> RemoveBomb1()
	call RemoveBomb1
;> RemoveBomb2()
	call RemoveBomb2
;> return
	ret


;@ def RemoveShot()
;@ path: shots/hits
;@ Takes the cannon's shot off the screen: not flying, state cleared, sprite parked at (240, 240) with the
;@ shot picture back in place.
;@ writes: hActiveShots, hShotFlags, wShotSpriteTile, wShotSpriteX, wShotSpriteY
;@ reads: hActiveShots
;@ sig: d6394317
RemoveShot::
;> hActiveShots &= ~0x01
	ldh a, [hActiveShots]
	res 0, a
	ldh [hActiveShots], a
;> hShotFlags = 0
	and $00
	ldh [hShotFlags], a
;> wShotSpriteX = 0xF0          # off screen
	ld a, $f0
	ld [wShotSpriteX], a
;> wShotSpriteY = 0xF0
	ld [wShotSpriteY], a
;> wShotSpriteTile = 0x02
	ld a, $02
	ld [wShotSpriteTile], a
;> return
	ret


;@ def RemoveLinkShot()
;@ path: shots/hits
;@ Takes the opponent's shot (link game) off the screen, like RemoveShot.
;@ writes: hActiveShots, hLinkShotFlags, wLinkShotSpriteTile, wLinkShotSpriteX, wLinkShotSpriteY
;@ reads: hActiveShots
;@ sig: 99fd8306
RemoveLinkShot::
;> hActiveShots &= ~0x02
	ldh a, [hActiveShots]
	res 1, a
	ldh [hActiveShots], a
;> hLinkShotFlags = 0
	and $00
	ldh [hLinkShotFlags], a
;> wLinkShotSpriteY = 0xF0
	ld a, $f0
	ld [wLinkShotSpriteY], a
;> wLinkShotSpriteX = 0xF0
	ld [wLinkShotSpriteX], a
;> wLinkShotSpriteTile = 0x02
	ld a, $02
	ld [wLinkShotSpriteTile], a
;> return
	ret


;@ def RemoveBomb0()
;@ path: shots/hits
;@ Takes invader bomb 0 off the screen and gives its sprite back its bomb picture (tile 3).
;@ writes: hActiveShots, hBombFlags, wBomb0SpriteTile, wBomb0SpriteX, wBomb0SpriteY
;@ reads: hActiveShots
;@ sig: 27df1428
RemoveBomb0::
;> hActiveShots &= ~0x04
	ldh a, [hActiveShots]
	res 2, a
	ldh [hActiveShots], a
;> hBombFlags[0] = 0
	and $00
	ldh [hBombFlags], a
;> wBomb0SpriteY = 0xF0
	ld a, $f0
	ld [wBomb0SpriteY], a
;> wBomb0SpriteX = 0xF0
	ld [wBomb0SpriteX], a
;> wBomb0SpriteTile = 0x03
	ld a, $03
	ld [wBomb0SpriteTile], a
;> return
	ret


;@ def RemoveBomb1()
;@ path: shots/hits
;@ Takes invader bomb 1 off the screen and gives its sprite back its bomb picture (tile 4).
;@ writes: hActiveShots, hBombFlags, wBomb1SpriteTile, wBomb1SpriteX, wBomb1SpriteY
;@ reads: hActiveShots
;@ sig: 92ea7e93
RemoveBomb1::
;> hActiveShots &= ~0x08
	ldh a, [hActiveShots]
	res 3, a
	ldh [hActiveShots], a
;> hBombFlags[1] = 0
	and $00
	ldh [hBombFlags + 1], a
;> wBomb1SpriteY = 0xF0
	ld a, $f0
	ld [wBomb1SpriteY], a
;> wBomb1SpriteX = 0xF0
	ld [wBomb1SpriteX], a
;> wBomb1SpriteTile = 0x04
	ld a, $04
	ld [wBomb1SpriteTile], a
;> return
	ret


;@ def RemoveBomb2()
;@ path: shots/hits
;@ Takes invader bomb 2 off the screen and gives its sprite back its bomb picture (tile 2).
;@ writes: hActiveShots, hBombFlags, wBomb2SpriteTile, wBomb2SpriteX, wBomb2SpriteY
;@ reads: hActiveShots
;@ sig: 80eced84
RemoveBomb2::
;> hActiveShots &= ~0x10
	ldh a, [hActiveShots]
	res 4, a
	ldh [hActiveShots], a
;> hBombFlags[2] = 0
	and $00
	ldh [hBombFlags + 2], a
;> wBomb2SpriteY = 0xF0
	ld a, $f0
	ld [wBomb2SpriteY], a
;> wBomb2SpriteX = 0xF0
	ld [wBomb2SpriteX], a
;> wBomb2SpriteTile = 0x02
	ld a, $02
	ld [wBomb2SpriteTile], a
;> return
	ret


;@ def ResetShields()
;@ path: shields/init
;@ Builds four fresh shields for a new stage: the RAM copies wShield0Tiles-wShield3Tiles get the intact
;@ shield picture, so do the 24 shield tiles in VRAM ($5A-$71, written one byte per LCD interrupt), the crater
;@ scratch area is set to "no hole" ($FF) and the two crater masks are loaded. A link game (or a screen with
;@ the LCD interrupt off) has no shields: then all of it is cleared to empty instead.
;@ writes: hShieldUploadDstHi, hShieldUploadDstLo, hShieldUploadSrcHi, hShieldUploadSrcLo, hShieldUploadTile, hUnusedA7
;@ reads: hLinkFlags
;@ test: skip waits for the LCD and VBlank interrupts
;@ sig: 07443fdd
ResetShields::
;> if not hLinkFlags & 1 and rIE & 0x02:            # one-player game with the LCD interrupt on
	ldh a, [hLinkFlags]
	bit 0, a
	jp nz, .noShields

	ldh a, [rIE]
	bit 1, a
	jr z, .noShields

;>     fill(wCraterScratch, 0xFF, 0x60)            # $FF: keep every pixel
	ld b, $60
	ld a, $ff
	ld hl, wCraterScratch
.fillScratch
	ld [hli], a
	dec b
	jr nz, .fillScratch

;>     fill(hUnusedED, 0, 6)
	xor a
	ld hl, hUnusedED
	ld b, $06
.clearUnused
	ld [hli], a
	dec b
	jr nz, .clearUnused

;>     CopyShieldGfx(wShield0Tiles)
	ld de, wShield0Tiles
	call CopyShieldGfx
;>     CopyShieldGfx(wShield1Tiles)
	ld de, wShield1Tiles
	call CopyShieldGfx
;>     CopyShieldGfx(wShield2Tiles)
	ld de, wShield2Tiles
	call CopyShieldGfx
;>     CopyShieldGfx(wShield3Tiles)
	ld de, wShield3Tiles
	call CopyShieldGfx
;>     UploadShieldGfx(0x95A0)                     # tiles $5A-$5F: shield 0
	ld de, $95a0
	call UploadShieldGfx
;>     UploadShieldGfx(0x9600)                     # tiles $60-$65: shield 1
	ld de, $9600
	call UploadShieldGfx
;>     UploadShieldGfx(0x9660)                     # tiles $66-$6B: shield 2
	ld de, $9660
	call UploadShieldGfx
;>     UploadShieldGfx(0x96C0)                     # tiles $6C-$71: shield 3
	ld de, $96c0
	call UploadShieldGfx
;>@cShot     for i in range(0x10):
	ld b, $10
	ld hl, ShotCraterMaskData
	ld de, wShotCraterMask
;>         mem[wShotCraterMask + i] = mem[ShotCraterMaskData + i]
.copyShotMask
	ld a, [hli]
	ld [de], a
	inc e
;=@cShot
	dec b
	jr nz, .copyShotMask

;>@cBomb     for i in range(0x10):
	ld b, $10
	ld hl, BombCraterMaskData
	ld de, wBombCraterMask
;>         mem[wBombCraterMask + i] = mem[BombCraterMaskData + i]
.copyBombMask
	ld a, [hli]
	ld [de], a
	inc e
;=@cBomb
	dec b
	jr nz, .copyBombMask

;>     hUnusedA7 = 0
	xor a
	ldh [hUnusedA7], a
;>     # the frame handler's shield refresh restarts with shield 0, tile 0
;>     hShieldUploadTile = 5
	ld a, $05
	ldh [hShieldUploadTile], a
;>     hShieldUploadSrcHi = 0xD6
	ld a, $d6
	ldh [hShieldUploadSrcHi], a
;>     hShieldUploadSrcLo = 0x00
	ld a, $00
	ldh [hShieldUploadSrcLo], a
;>     hShieldUploadDstHi = 0x95
	ld a, $95
	ldh [hShieldUploadDstHi], a
;>     hShieldUploadDstLo = 0xA0
	ld a, $a0
	ldh [hShieldUploadDstLo], a
;>     return
	ret


;> fill(wCraterScratch, 0, 0x60)
.noShields
	ld b, $60
	xor a
	ld hl, wCraterScratch
.clearScratch
	ld [hli], a
	dec b
	jr nz, .clearScratch

;> fill(hUnusedED, 0, 6)
	ld hl, hUnusedED
	ld b, $06
.clearUnused2
	ld [hli], a
	dec b
	jr nz, .clearUnused2

;> ClearShieldBuffer(wShield0Tiles)
	ld hl, wShield0Tiles
	call ClearShieldBuffer
;> ClearShieldBuffer(wShield1Tiles)
	ld hl, wShield1Tiles
	call ClearShieldBuffer
;> ClearShieldBuffer(wShield2Tiles)
	ld hl, wShield2Tiles
	call ClearShieldBuffer
;> ClearShieldBuffer(wShield3Tiles)
	ld hl, wShield3Tiles
	call ClearShieldBuffer
;> ClearShieldGfx(0x95A0)
	ld hl, $95a0
	call ClearShieldGfx
;> ClearShieldGfx(0x9600)
	ld hl, $9600
	call ClearShieldGfx
;> ClearShieldGfx(0x9660)
	ld hl, $9660
	call ClearShieldGfx
;> ClearShieldGfx(0x96C0)
	ld hl, $96c0
	call ClearShieldGfx
;> hUnusedA7 = 0
	xor a
	ldh [hUnusedA7], a
;> fill(wShotCraterMask, 0, 0x10)
	ld b, $10
	ld hl, wShotCraterMask
.clearShotMask
	ld [hli], a
	dec b
	jr nz, .clearShotMask

;> fill(wBombCraterMask, 0, 0x10)
	ld b, $10
	ld hl, wBombCraterMask
.clearBombMask
	ld [hli], a
	dec b
	jr nz, .clearBombMask

;> return
	ret


;@ def UploadShieldGfx(vram: de)
;@ path: shields/init
;@ Writes the intact shield picture (ShieldTiles, 6 tiles) to VRAM at `vram`, one byte at a time: each byte
;@ is handed to the LCD interrupt (LcdWriteTile), which stores it when the screen allows VRAM access.
;@ writes: hLcdHook, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hLcdHook
;@ test: skip waits for the LCD interrupt
;@ sig: 3382dc60
UploadShieldGfx::
;> src = ShieldTiles
	ld hl, ShieldTiles
;>@loop for i in range(0x60):
	ld b, $60
;>     hVramData0 = mem[src + i]
.loop
	ld a, [hli]
	ldh [hVramData0], a
;>     hVramAddrHi = hi(vram + i)
	ld a, d
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(vram + i)
	ld a, e
	ldh [hVramAddrLo], a
;>     hLcdHook = lo(LcdWriteTile)
	ld a, LOW(LcdWriteTile)
	ldh [hLcdHook], a
;>     while hLcdHook: LcdWriteTile()             # the interrupt clears the hook when done
.wait
	ldh a, [hLcdHook]
	and a
	jr nz, .wait

;=@loop
	inc de
	dec b
	jr nz, .loop

;> return
	ret


;@ def ClearShieldGfx(vram: hl)
;@ path: shields/init
;@ Clears the 6 tiles of one shield in VRAM at `vram` to empty, one byte per frame through the VBlank hook
;@ (VBlankWriteTile).
;@ writes: hMainHook, hVramAddrHi, hVramAddrLo, hVramData0
;@ reads: hMainHook
;@ test: skip waits for the VBlank interrupt
;@ sig: 3bd42afb
ClearShieldGfx::
;>@loop for i in range(0x60):
	ld b, $60
;>     hVramData0 = 0
.loop
	xor a
	ldh [hVramData0], a
;>     hVramAddrHi = hi(vram + i)
	ld a, h
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(vram + i)
	ld a, l
	ldh [hVramAddrLo], a
;>     hMainHook = lo(VBlankWriteTile)
	ld a, LOW(VBlankWriteTile)
	ldh [hMainHook], a
;>     while hMainHook: VBlankWriteTile()          # the VBlank handler clears the hook when done
.wait
	ldh a, [hMainHook]
	and a
	jr nz, .wait

;=@loop
	inc hl
	dec b
	jr nz, .loop

;> return
	ret


;@ def CopyShieldGfx(dest: de)
;@ path: shields/init
;@ Copies the intact shield picture (ShieldTiles, 6 tiles = $60 bytes) to a shield's RAM copy at `dest`.
;@ test: dest = 0xD300 + 0x100 * rand(0, 3)
;@ sig: 3d6bdec7
CopyShieldGfx::
;>@loop for i in range(0x60):
	ld hl, ShieldTiles
	ld b, $60
;>     mem[dest + i] = mem[ShieldTiles + i]
.loop
	ld a, [hli]
	ld [de], a
	inc e
;=@loop
	dec b
	jr nz, .loop

;> return
	ret


;@ def ClearShieldBuffer(dest: hl)
;@ path: shields/init
;@ Clears a shield's RAM copy ($60 bytes at `dest`) to empty.
;@ test: dest = 0xD300 + 0x100 * rand(0, 3)
;@ sig: 93480e3a
ClearShieldBuffer::
;> fill(dest, 0, 0x60)
	xor a
	ld b, $60
.loop
	ld [hli], a
	dec b
	jr nz, .loop

;> return
	ret


;@ path: shields/data
;@ The crater the cannon's shot cuts into a shield: an 8x8 tile mask that is ANDed into the shield's pixels
;@ (both bit planes alike, so 0 bits become holes). Rows, # = kept, . = hole:
;@ `########`, `###...##`, `##...#.#`, `#.#...#.`, `.......#`, `#.....#.`, `.#...#.#`, `########`
;@ asset: tiles bpp=2 length=$10
ShotCraterMaskData::
	db $ff, $ff, $e3, $e3, $c5, $c5, $a2, $a2, $01, $01, $82, $82, $45, $45, $ff, $ff
;@ path: shields/data
;@ The crater an invader bomb cuts into a shield, same format as ShotCraterMaskData:
;@ `########`, `##....##`, `.#...#..`, `#.#....#`, `.#...#..`, `#.....##`, `##...###`, `########`
;@ asset: tiles bpp=2 length=$10
BombCraterMaskData::
	db $ff, $ff, $c3, $c3, $44, $44, $a1, $a1, $44, $44, $83, $83, $c7, $c7, $ff, $ff

;@ def CheckBombsVsShields()
;@ path: shields/hits
;@ Once per frame: checks the three invader bombs, then the cannon's shot, against the shields and cuts a
;@ crater where one touches a shield pixel. Not in a link game (no shields there), nor while the LCD
;@ interrupt is off - the VRAM reads go through it.
;@ writes: hBombActiveBits, hShieldCheckIndex
;@ reads: hActiveShots, hLinkFlags
;@ test: skip reads VRAM through the LCD interrupt
;@ sig: 7ed55c9b
CheckBombsVsShields::
;> if hLinkFlags & 1:
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	ret nz

;> if not rIE & 0x02:
;>     return
	ldh a, [rIE]
	bit 1, a
	ret z

;> hShieldCheckIndex = 0                     # bomb 0 first
	ld a, $00
	ldh [hShieldCheckIndex], a
;> sprite = wBomb0SpriteY
	ld hl, wBomb0SpriteY
;> # rotated so that each further rotation brings the next bomb's bit (2, 3, 4) into bit 7
;> hBombActiveBits = (hActiveShots >> 2 | hActiveShots << 6) & 0xFF
	ldh a, [hActiveShots]
	rrca
	rrca
	ldh [hBombActiveBits], a

;> return BombShieldCheck(sprite)            # runs on into it

;@ def BombShieldCheck(sprite: hl)
;@ path: shields/hits
;@ Starts the shield check of one invader bomb (number hShieldCheckIndex, OAM-buffer entry `sprite`): a bomb
;@ that is falling and not yet exploding gets two probe points, tested by BombShieldProbe; otherwise the
;@ check moves on to the next bomb.
;@ writes: hBombActiveBits, hBombOamLow, hProbeCount
;@ reads: hBombActiveBits, hShieldCheckIndex
;@ test: hShieldCheckIndex = rand(0, 2); sprite = 0xC018 + 4 * hShieldCheckIndex
;@ sig: 5e33b0fb
BombShieldCheck::
;> hBombActiveBits = (hBombActiveBits >> 1 | hBombActiveBits << 7) & 0xFF
	ldh a, [hBombActiveBits]
	rrca
	ldh [hBombActiveBits], a
;> if not hBombActiveBits & 0x80:             # this bomb is not falling
;>     return BombShieldNext(sprite)
	bit 7, a
	jp z, BombShieldNext

;> if hBombFlags[hShieldCheckIndex] & 0x20:  # already exploding
	ld c, LOW(hBombFlags)
	ldh a, [hShieldCheckIndex]
	add c
	ld c, a
	ldh a, [c]
;>     return BombShieldNext(sprite)
	bit 5, a
	jp nz, BombShieldNext

;> hBombOamLow = lo(sprite)
	ld a, l
	ldh [hBombOamLow], a
;> hProbeCount = 2                           # two probe points, at the bomb's tip
	ld a, $02
	ldh [hProbeCount], a

;> return BombShieldProbe()                  # runs on into it

;@ def BombShieldProbe()
;@ path: shields/hits
;@ Tests the probe points of the current bomb, one after the other: a point 4 pixels below the sprite's top
;@ and 3 or 4 pixels right of its left edge. Only the two tile rows of the shields (screen y $71-$80) count.
;@ The background tile under the point is read from VRAM through the LCD hook; if it is a shield tile
;@ ($5A-$71) the pixel row is read too, and if the point's pixel is set the bomb has hit: the jump table
;@ BombCraterTable then cuts the crater into that tile and makes the bomb explode. With no hit the check
;@ moves on to the next bomb (BombShieldDone).
;@ writes: hHitPixelX, hHitPixelY, hHitTile, hLcdHook, hProbeCount, hSavedIE, hVramAddrHi, hVramAddrLo
;@ reads: hBombOamLow, hHitPixelX, hHitPixelY, hHitTile, hLcdHook, hProbeCount, hSavedIE, hVramData0, hVramData1
;@ test: skip reads VRAM through the LCD interrupt
;@ sig: 27167335
BombShieldProbe::
;> while True:
;>     sprite = wShadowOam + hBombOamLow
	ld h, HIGH(wShadowOam)
	ldh a, [hBombOamLow]
	ld l, a
;>     if hProbeCount == 0:
;>         return BombShieldDone()           # no hit
	ldh a, [hProbeCount]
	and a
	jp z, BombShieldDone

;>     hProbeCount -= 1
	dec a
	ldh [hProbeCount], a
;>     x = u8(mem[sprite + 1] + hProbeCount - 5)          # sprite X - 8 = screen x
	ld c, a
	inc l
	ld a, [hld]
	add c
	sub $05
	ld e, a
;>     hHitPixelX = x & 7
	and $07
	ldh [hHitPixelX], a
;>     y = u8(mem[sprite] + 4 - 0x10)                     # sprite Y - 16 = screen y
	ld a, [hl]
	add $04
	sub $10
	ld l, a
;>     hHitPixelY = y & 7
	and $07
	ldh [hHitPixelY], a
;>     if not 0x70 < y <= 0x80:                           # outside the shields' tile rows
;>         continue
	ld a, $70
	cp l
	jp nc, BombShieldProbe

	add $10
	cp l
	jp c, BombShieldProbe

;>     column = x >> 3
	srl e
	srl e
	srl e
	ld d, $98
;>     row = y >> 3
	srl l
	srl l
	srl l
	ld h, $00
;>     map = 0x9800 + row * 32 + column                   # its entry in the background map
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, de
;>     hVramAddrHi = hi(map)
	ld a, h
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(map)
	ld a, l
	ldh [hVramAddrLo], a
;>     hSavedIE = rIE
	ldh a, [rIE]
	ldh [hSavedIE], a
;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = 0x03                                         # only VBlank and LCD interrupts meanwhile
	ld a, $03
	ldh [rIE], a
;>     hLcdHook = lo(LcdReadTilePair)
	ld a, LOW(LcdReadTilePair)
	ldh [hLcdHook], a
;>     while hLcdHook: LcdReadTilePair()                  # the LCD interrupt reads VRAM when it is safe
.waitMap
	ldh a, [hLcdHook]
	and a
	jr nz, .waitMap

;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;>     tile = hVramData0
	ldh a, [hVramData0]
;>     if not 0x5A <= tile < 0x72:                        # not a shield tile
;>         continue
	cp $5a
	jp c, BombShieldProbe

	cp $72
	jp nc, BombShieldProbe

;>     hHitTile = tile
	ldh [hHitTile], a
;>     addr = (0x90 + (tile >> 4)) << 8                   # tiles $00-$7F of the background are at $9000
	ld l, a
	and $f0
	add $09
	swap a
	ld h, a
;>     addr += (tile & 0x0F) << 4
	ld a, l
	and $0f
	swap a
	ld l, a
;>     addr += 2 * hHitPixelY                             # the pixel row: 2 bytes
	ldh a, [hHitPixelY]
	sla a
	ld e, a
	ld d, $00
	add hl, de
;>     hVramAddrHi = hi(addr)
	ld a, h
	ldh [hVramAddrHi], a
;>     hVramAddrLo = lo(addr)
	ld a, l
	ldh [hVramAddrLo], a
;>     hSavedIE = rIE
	ldh a, [rIE]
	ldh [hSavedIE], a
;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>     hLcdHook = lo(LcdReadTilePair)
	ld a, LOW(LcdReadTilePair)
	ldh [hLcdHook], a
;>     while hLcdHook: LcdReadTilePair()
.waitRow
	ldh a, [hLcdHook]
	and a
	jr nz, .waitRow

;>     rIF = 0
	xor a
	ldh [rIF], a
;>     rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;>     shift = hHitPixelX
	ldh a, [hHitPixelX]
	ld b, a
	inc b
;>     pixels = hVramData0 | hVramData1                   # both bit planes: a pixel of any colour
	ldh a, [hVramData0]
	ld d, a
	ldh a, [hVramData1]
	or d

;>     if not (pixels << shift) & 0x80:                   # the probed pixel is empty
;>         continue
.rotate
	dec b
	jr z, .rotated

	rlca
	jr .rotate

.rotated
	and $80
	jp z, BombShieldProbe

;>@crater     return BombCraterTable[hHitTile - 0x5A](wBombCraterMask)   # hit: cut the crater into that tile
	ldh a, [hHitTile]
	sub $5a
	sla a
	sla a
	ld d, $00
	ld e, a
;=@crater
	ld hl, BombCraterTable
	add hl, de
	ld de, wBombCraterMask
	jp hl


;@ def BombCraterTable(mask: de)
;@ path: shields/craters/bomb
;@ Jump table of 24 entries of 4 bytes (`jp` and a padding byte), one per shield tile $5A-$71:
;@ entry n = tile $5A + n = tile n % 6 of shield n / 6. BombShieldProbe jumps to entry
;@ hHitTile - $5A with de = wBombCraterMask. This first entry is tile 0 of shield 0.
;@ test: mask = 0xD700
;@ sig: 3b9ba5e5
BombCraterTable::
;> return BombCraterShield0Tile0(mask)
	jp BombCraterShield0Tile0
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry1(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 1: shield tile $5B = tile 1 of shield 0.
;@ test: mask = 0xD700
;@ sig: 9b110895
BombCraterEntry1::
;> return BombCraterShield0Tile1(mask)
	jp BombCraterShield0Tile1
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry2(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 2: shield tile $5C = tile 2 of shield 0.
;@ test: mask = 0xD700
;@ sig: e45abeda
BombCraterEntry2::
;> return BombCraterShield0Tile2(mask)
	jp BombCraterShield0Tile2
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry3(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 3: shield tile $5D = tile 3 of shield 0.
;@ test: mask = 0xD700
;@ sig: 519ecd0a
BombCraterEntry3::
;> return BombCraterShield0Tile3(mask)
	jp BombCraterShield0Tile3
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry4(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 4: shield tile $5E = tile 4 of shield 0.
;@ test: mask = 0xD700
;@ sig: 3d22e3ba
BombCraterEntry4::
;> return BombCraterShield0Tile4(mask)
	jp BombCraterShield0Tile4
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry5(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 5: shield tile $5F = tile 5 of shield 0.
;@ test: mask = 0xD700
;@ sig: ed3aea33
BombCraterEntry5::
;> return BombCraterShield0Tile5(mask)
	jp BombCraterShield0Tile5
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry6(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 6: shield tile $60 = tile 0 of shield 1.
;@ test: mask = 0xD700
;@ sig: b61ab9ec
BombCraterEntry6::
;> return BombCraterShield1Tile0(mask)
	jp BombCraterShield1Tile0
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry7(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 7: shield tile $61 = tile 1 of shield 1.
;@ test: mask = 0xD700
;@ sig: 2be0c04d
BombCraterEntry7::
;> return BombCraterShield1Tile1(mask)
	jp BombCraterShield1Tile1
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry8(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 8: shield tile $62 = tile 2 of shield 1.
;@ test: mask = 0xD700
;@ sig: 488dd572
BombCraterEntry8::
;> return BombCraterShield1Tile2(mask)
	jp BombCraterShield1Tile2
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry9(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 9: shield tile $63 = tile 3 of shield 1.
;@ test: mask = 0xD700
;@ sig: dc1fd103
BombCraterEntry9::
;> return BombCraterShield1Tile3(mask)
	jp BombCraterShield1Tile3
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry10(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 10: shield tile $64 = tile 4 of shield 1.
;@ test: mask = 0xD700
;@ sig: 88eeb953
BombCraterEntry10::
;> return BombCraterShield1Tile4(mask)
	jp BombCraterShield1Tile4
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry11(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 11: shield tile $65 = tile 5 of shield 1.
;@ test: mask = 0xD700
;@ sig: 121d682e
BombCraterEntry11::
;> return BombCraterShield1Tile5(mask)
	jp BombCraterShield1Tile5
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry12(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 12: shield tile $66 = tile 0 of shield 2.
;@ test: mask = 0xD700
;@ sig: 493d3bf1
BombCraterEntry12::
;> return BombCraterShield2Tile0(mask)
	jp BombCraterShield2Tile0
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry13(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 13: shield tile $67 = tile 1 of shield 2.
;@ test: mask = 0xD700
;@ sig: ffea1193
BombCraterEntry13::
;> return BombCraterShield2Tile1(mask)
	jp BombCraterShield2Tile1
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry14(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 14: shield tile $68 = tile 2 of shield 2.
;@ test: mask = 0xD700
;@ sig: 9c8704ac
BombCraterEntry14::
;> return BombCraterShield2Tile2(mask)
	jp BombCraterShield2Tile2
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry15(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 15: shield tile $69 = tile 3 of shield 2.
;@ test: mask = 0xD700
;@ sig: 110e319c
BombCraterEntry15::
;> return BombCraterShield2Tile3(mask)
	jp BombCraterShield2Tile3
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry16(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 16: shield tile $6A = tile 4 of shield 2.
;@ test: mask = 0xD700
;@ sig: 45ff59cc
BombCraterEntry16::
;> return BombCraterShield2Tile4(mask)
	jp BombCraterShield2Tile4
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry17(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 17: shield tile $6B = tile 5 of shield 2.
;@ test: mask = 0xD700
;@ sig: ec6f0dd8
BombCraterEntry17::
;> return BombCraterShield2Tile5(mask)
	jp BombCraterShield2Tile5
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry18(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 18: shield tile $6C = tile 0 of shield 3.
;@ test: mask = 0xD700
;@ sig: 9324bb97
BombCraterEntry18::
;> return BombCraterShield3Tile0(mask)
	jp BombCraterShield3Tile0
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry19(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 19: shield tile $6D = tile 1 of shield 3.
;@ test: mask = 0xD700
;@ sig: 12f86146
BombCraterEntry19::
;> return BombCraterShield3Tile1(mask)
	jp BombCraterShield3Tile1
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry20(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 20: shield tile $6E = tile 2 of shield 3.
;@ test: mask = 0xD700
;@ sig: 6db3d709
BombCraterEntry20::
;> return BombCraterShield3Tile2(mask)
	jp BombCraterShield3Tile2
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry21(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 21: shield tile $6F = tile 3 of shield 3.
;@ test: mask = 0xD700
;@ sig: af7b74fe
BombCraterEntry21::
;> return BombCraterShield3Tile3(mask)
	jp BombCraterShield3Tile3
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry22(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 22: shield tile $70 = tile 4 of shield 3.
;@ test: mask = 0xD700
;@ sig: fb8a1cae
BombCraterEntry22::
;> return BombCraterShield3Tile4(mask)
	jp BombCraterShield3Tile4
	db $00                                    ; padding to 4 bytes

;@ def BombCraterEntry23(mask: de)
;@ path: shields/craters/bomb
;@ BombCraterTable entry 23: shield tile $71 = tile 5 of shield 3.
;@ test: mask = 0xD700
;@ sig: 45122843
BombCraterEntry23::
;> return BombCraterShield3Tile5(mask)
	jp BombCraterShield3Tile5
	db $00                                    ; padding to 4 bytes

;@ path: unused
;@ Two 8x8 tiles (2 bits per pixel) that nothing reads, left between BombCraterTable and its routines:
;@ ragged patterns of the same kind as the crater masks.
;@ asset: tiles bpp=2 length=$20
UnusedTiles1EC2::
	db $ff, $ff, $a2, $c3, $45, $a5, $a2, $c3, $45, $c3, $a2, $a5, $45, $48, $ff, $ff
	db $ff, $ff, $42, $66, $82, $c3, $41, $81, $a2, $81, $45, $c3, $a2, $e7, $ff, $ff

;@ def BombCraterShield0Tile0(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 0 (top left) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 0, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: bbbe41ed
BombCraterShield0Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield0Tile1(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 1 (bottom left) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 1, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: f3d375f5
BombCraterShield0Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield0Tile2(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 2 (top middle) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 2, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 3935c3c1
BombCraterShield0Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield0Tile3(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 3 (bottom middle) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 3, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: skip the loop over the bombs goes on through BombShieldCheck, so a random state can run it without end
;@ sig: 7d63f007
BombCraterShield0Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield0Tile4(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 4 (top right) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 4, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: f83931ff
BombCraterShield0Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield0Tile5(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 5 (bottom right) of shield 0: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 5, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 77ca2c9f
BombCraterShield0Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield1Tile0(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 0 (top left) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 0, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: bd68764e
BombCraterShield1Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield1Tile1(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 1 (bottom left) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 1, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: f5054256
BombCraterShield1Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield1Tile2(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 2 (top middle) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 2, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: a64de171
BombCraterShield1Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield1Tile3(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 3 (bottom middle) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 3, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: e21bd2b7
BombCraterShield1Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield1Tile4(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 4 (top right) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 4, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: feef065c
BombCraterShield1Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield1Tile5(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 5 (bottom right) of shield 1: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 5, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 711c1b3c
BombCraterShield1Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield2Tile0(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 0 (top left) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 0, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: bc2fcac3
BombCraterShield2Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield2Tile1(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 1 (bottom left) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 1, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: f442fedb
BombCraterShield2Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield2Tile2(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 2 (top middle) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 2, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 5b03820c
BombCraterShield2Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield2Tile3(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 3 (bottom middle) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 3, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 1f55b1ca
BombCraterShield2Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield2Tile4(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 4 (top right) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 4, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: ffa8bad1
BombCraterShield2Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield2Tile5(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 5 (bottom right) of shield 2: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 5, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 705ba7b1
BombCraterShield2Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield3Tile0(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 0 (top left) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 0, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: bfe70f54
BombCraterShield3Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield3Tile1(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 1 (bottom left) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 1, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: f78a3b4c
BombCraterShield3Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield3Tile2(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 2 (top middle) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 2, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: skip the loop over the bombs goes on through BombShieldCheck, so a random state can run it without end
;@ sig: 87a021ca
BombCraterShield3Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield3Tile3(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 3 (bottom middle) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 3, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ Unlike its twins it moves the crater up or down in columns 0-1 instead of 1-2 when the hit is right of
;@ the middle, so the part pushed into tile 5 keeps its row.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: be4a916e
BombCraterShield3Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)  -- a slip in the game: this moves columns 0-1, so the part in tile 5 is not moved
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;>     else:
.up
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above  -- the same slip
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutBombCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutBombCraterLeft


;@ def BombCraterShield3Tile4(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 4 (top right) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 4, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: fc607f46
BombCraterShield3Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight


;@ def BombCraterShield3Tile5(mask: de)
;@ path: shields/craters/bomb
;@ An invader bomb hit tile 5 (bottom right) of shield 3: lays the bomb crater mask (de = wBombCraterMask)
;@ into scratch tile 5, moves it pixel by pixel onto the hit point - spilling into the neighbour
;@ tiles - and cuts it out of the shield. One of 24 such routines (BombCraterTable), one per shield tile.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD700
;@ sig: 73936226
BombCraterShield3Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutBombCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutBombCraterRight


;@ def CutBombCraterLeft(shield: hl)
;@ path: shields/craters/bomb
;@ Cuts the crater prepared in scratch tiles 0-3 (left and middle column) out of the four shield tiles at
;@ shield (the left and middle column of a shield's RAM copy): a pixel stays only where the mask has it too.
;@ Wipes the scratch back to $FF for the next crater and lets the bomb explode.
;@ test: shield = rng.choice([0xD300, 0xD320, 0xD400, 0xD520, 0xD600])
;@ sig: 6f2344a4
CutBombCraterLeft::
;> for i in range(0x40):
	ld de, wCraterScratch
	ld b, $40
	ld c, $ff
.loop
;>     mem[shield + i] &= wCraterScratch[i]
	ld a, [de]
	and [hl]
	ld [hli], a
;>     wCraterScratch[i] = 0xFF
	ld a, c
	ld [de], a
	inc e
	dec b
	jr nz, .loop
;> return ExplodeBombOnShield()
	jp ExplodeBombOnShield


;@ def CutBombCraterRight(shield: hl)
;@ path: shields/craters/bomb
;@ The same as CutBombCraterLeft for scratch tiles 2-5 (middle and right column); shield points at the
;@ shield's middle column. Runs on into ExplodeBombOnShield.
;@ test: shield = rng.choice([0xD300, 0xD320, 0xD400, 0xD520, 0xD600])
;@ sig: db2a5142
CutBombCraterRight::
;> for i in range(0x40):
	ld de, wCraterScratch + $20
	ld b, $40
	ld c, $ff
.loop
;>     mem[shield + i] &= wCraterScratch[0x20 + i]
	ld a, [de]
	and [hl]
	ld [hli], a
;>     wCraterScratch[0x20 + i] = 0xFF
	ld a, c
	ld [de], a
	inc e
	dec b
	jr nz, .loop
;> return ExplodeBombOnShield()                     # runs on into it

;@ def ExplodeBombOnShield()
;@ path: shields/hits
;@ The bomb being checked has cut its crater: marks it as exploding (bit 5 of its hBombFlags byte) and
;@ shows the explosion tile $0A on its sprite, then goes on with the next bomb.
;@ reads: hBombOamLow, hShieldCheckIndex
;@ test: hShieldCheckIndex = rand(0, 2); hBombOamLow = rand(0, 39) * 4
;@ sig: d2aea658
ExplodeBombOnShield::
;> sprite = wShadowOam + hBombOamLow                 # the bomb's entry in the OAM buffer
	ld h, HIGH(wShadowOam)
	ldh a, [hBombOamLow]
	ld l, a
;> # c = the address of this bomb's hBombFlags byte
	ld c, LOW(hBombFlags)
	ldh a, [hShieldCheckIndex]
	add c
	ld c, a
;> hBombFlags[hShieldCheckIndex] |= 0x20            # bit 5: exploding
	ldh a, [c]
	set 5, a
	ldh [c], a
;> mem[sprite + 2] = 0x0A                           # the sprite's tile: explosion
	ld a, $0a
	inc l
	inc l
	ld [hld], a
	dec l
;> return BombShieldDone()                          # runs on into it

;@ def BombShieldDone()
;@ path: shields/hits
;@ Done with the current bomb: points at its OAM-buffer entry again and goes on with the next one.
;@ reads: hBombOamLow
;@ sig: 6feb796a
BombShieldDone::
;> return BombShieldNext(wShadowOam + hBombOamLow)    # runs on into it
	ld h, HIGH(wShadowOam)
	ldh a, [hBombOamLow]
	ld l, a

;@ def BombShieldNext(sprite: hl)
;@ path: shields/hits
;@ Steps the shield check on to the next of the three invader bombs (whose sprite follows at sprite + 4);
;@ after the third one it checks the cannon's shot.
;@ writes: hShieldCheckIndex
;@ reads: hShieldCheckIndex
;@ test: skip the loop over the bombs goes on through BombShieldCheck, so a random state can run it without end
;@ sig: e866ae53
BombShieldNext::
;> hShieldCheckIndex += 1
	ldh a, [hShieldCheckIndex]
	inc a
	ldh [hShieldCheckIndex], a
;> if hShieldCheckIndex == 3:
;>     return CheckShotVsShields()                   # all three bombs done: now the cannon's shot
	cp $03
	jr z, CheckShotVsShields
;> return BombShieldCheck(sprite + 4)                # the next bomb's sprite
	inc l
	inc l
	inc l
	inc l
	jp BombShieldCheck


;@ def CheckShotVsShields()
;@ path: shields/hits
;@ Checks whether the cannon's shot touches a shield: it probes the shot's two pixel columns in the three
;@ rows near its tip. For each point the background tile under it is read from VRAM through the LCD hook;
;@ if it is a shield tile ($5A-$71), the tile's pixel row is read too, and if the pixel there is set the
;@ shot cuts its crater into the shield through ShotCraterTable (and explodes). Nothing happens while no
;@ shot flies or while it already explodes.
;@ writes: hHitPixelX, hHitPixelY, hHitTile, hLcdHook, hProbeCount, hSavedIE, hShieldCheckIndex, hVramAddrHi, hVramAddrLo
;@ reads: hActiveShots, hHitPixelX, hHitPixelY, hHitTile, hLcdHook, hProbeCount, hSavedIE, hShieldCheckIndex, hShotFlags, hVramData0, hVramData1, wShotSpriteX, wShotSpriteY
;@ test: skip waits for the LCD interrupt to read VRAM
;@ sig: 9d7f10d1
CheckShotVsShields::
;> if not hActiveShots & 0x01: return                # no shot in flight
	ldh a, [hActiveShots]
	bit 0, a
	jp z, ShieldCheckReturn
;> if hShotFlags & 0x10: return                      # the shot already explodes
	ldh a, [hShotFlags]
	bit 4, a
	jp nz, ShieldCheckReturn
;> for col in (2, 1):                                # the shot's two pixel columns
	ld a, $03
	ldh [hShieldCheckIndex], a
.nextColumn
	ldh a, [hShieldCheckIndex]
	dec a
	jp z, ShieldCheckReturn
;>     hShieldCheckIndex = col
	ldh [hShieldCheckIndex], a
;>     for row in (3, 2, 1):                         # three rows near the shot's tip
	ld a, $04
	ldh [hProbeCount], a
.nextRow
	ldh a, [hProbeCount]
	dec a
	jr z, .nextColumn
;>         hProbeCount = row
	ldh [hProbeCount], a
;>         y = wShotSpriteY - 16 + row               # the probe point in screen pixels
	ld l, a
	ld a, [wShotSpriteY]
	sub $10
	add l
	ld l, a
;>         hHitPixelY = y & 7
	and $07
	ldh [hHitPixelY], a
;>         x = wShotSpriteX - 8
	ld a, [wShotSpriteX]
	sub $08
	ld e, a
;>         x += col + 2                              # the shot's pixels are columns 3 and 4 of its tile
	ldh a, [hShieldCheckIndex]
	inc a
	inc a
	add e
	ld e, a
;>         hHitPixelX = x & 7
	and $07
	ldh [hHitPixelX], a
;>         if y <= 0x70 or y > 0x80: continue        # only the shields' rows
	ld a, $70
	cp l
	jp nc, .nextRow
	add $10
	cp l
	jp c, .nextRow
;>         column = x // 8
	srl e
	srl e
	srl e
	ld d, HIGH(_SCRN0)
;>         line = y // 8
	srl l
	srl l
	srl l
	ld h, $00
;>         cell = 0x9800 + line * 32 + column        # the background map cell under the point
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, de
;>         hVramAddrHi = hi(cell)
	ld a, h
	ldh [hVramAddrHi], a
;>         hVramAddrLo = lo(cell)
	ld a, l
	ldh [hVramAddrLo], a
;>         hSavedIE = rIE                            # meanwhile only VBlank and LCD STAT interrupts
	ldh a, [rIE]
	ldh [hSavedIE], a
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>         hLcdHook = lo(LcdReadTilePair)           # the LCD interrupt reads VRAM when it is safe
	ld a, LOW(LcdReadTilePair)
	ldh [hLcdHook], a
.waitTile
;>         while hLcdHook: LcdReadTilePair()         # it clears the hook when done
	ldh a, [hLcdHook]
	and a
	jr nz, .waitTile
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;>         tile = hVramData0
	ldh a, [hVramData0]
;>         if tile < 0x5A or tile >= 0x72: continue  # not a shield tile
	cp $5a
	jp c, .nextRow
	cp $72
	jp nc, .nextRow
;>         hHitTile = tile
	ldh [hHitTile], a
;>         addr = (0x90 + (tile >> 4)) << 8          # the tile's graphics at $9000 + tile * 16 ...
	ld l, a
	and $f0
	add $09
	swap a
	ld h, a
;>         addr += (tile & 0x0F) << 4
	ld a, l
	and $0f
	swap a
	ld l, a
;>         addr += hHitPixelY * 2                    # ... the pixel row of the probe point
	ldh a, [hHitPixelY]
	sla a
	ld e, a
	ld d, $00
	add hl, de
;>         hVramAddrHi = hi(addr)
	ld a, h
	ldh [hVramAddrHi], a
;>         hVramAddrLo = lo(addr)
	ld a, l
	ldh [hVramAddrLo], a
;>         hSavedIE = rIE
	ldh a, [rIE]
	ldh [hSavedIE], a
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = 0x03
	ld a, $03
	ldh [rIE], a
;>         hLcdHook = lo(LcdReadTilePair)           # read the row's two bit planes
	ld a, LOW(LcdReadTilePair)
	ldh [hLcdHook], a
.waitRow
;>         while hLcdHook: LcdReadTilePair()
	ldh a, [hLcdHook]
	and a
	jr nz, .waitRow
;>         rIF = 0
	xor a
	ldh [rIF], a
;>         rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
;>         n = hHitPixelX
	ldh a, [hHitPixelX]
	ld b, a
	inc b
;>         pixels = hVramData0 | hVramData1          # set where the row has a coloured pixel
	ldh a, [hVramData0]
	ld d, a
	ldh a, [hVramData1]
	or d
.rotate
;>         pixels = u8(pixels << n)                  # the probed pixel to bit 7
	dec b
	jr z, .test
	rlca
	jr .rotate
.test
;>         if not pixels & 0x80: continue            # an empty pixel: the shot passes
	and $80
	jp z, .nextRow
;>         n = hHitTile - 0x5A                       # entry n (4 bytes each): tile n % 6 of shield n / 6
	ldh a, [hHitTile]
	sub $5a
	sla a
	sla a
	ld d, $00
	ld e, a
;>         return ShotCraterTable[n](wShotCraterMask)    # cut the crater into that tile
	ld hl, ShotCraterTable
	add hl, de
	ld de, wShotCraterMask
	jp hl


;@ def ShotCraterTable(mask: de)
;@ path: shields/craters/shot
;@ The same jump table as BombCraterTable, for the cannon's shot: CheckShotVsShields jumps to
;@ entry hHitTile - $5A with de = wShotCraterMask. This first entry is tile 0 of shield 0.
;@ test: mask = 0xD710
;@ sig: 3022ba6e
ShotCraterTable::
;> return ShotCraterShield0Tile0(mask)
	jp ShotCraterShield0Tile0
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry1(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 1: shield tile $5B = tile 1 of shield 0.
;@ test: mask = 0xD710
;@ sig: a8e551fe
ShotCraterEntry1::
;> return ShotCraterShield0Tile1(mask)
	jp ShotCraterShield0Tile1
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry2(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 2: shield tile $5C = tile 2 of shield 0.
;@ test: mask = 0xD710
;@ sig: d7aee7b1
ShotCraterEntry2::
;> return ShotCraterShield0Tile2(mask)
	jp ShotCraterShield0Tile2
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry3(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 3: shield tile $5D = tile 3 of shield 0.
;@ test: mask = 0xD710
;@ sig: 5a27d281
ShotCraterEntry3::
;> return ShotCraterShield0Tile3(mask)
	jp ShotCraterShield0Tile3
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry4(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 4: shield tile $5E = tile 4 of shield 0.
;@ test: mask = 0xD710
;@ sig: 18e1305e
ShotCraterEntry4::
;> return ShotCraterShield0Tile4(mask)
	jp ShotCraterShield0Tile4
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry5(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 5: shield tile $5F = tile 5 of shield 0.
;@ test: mask = 0xD710
;@ sig: 39c5c34b
ShotCraterEntry5::
;> return ShotCraterShield0Tile5(mask)
	jp ShotCraterShield0Tile5
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry6(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 6: shield tile $60 = tile 0 of shield 1.
;@ test: mask = 0xD710
;@ sig: 5aa8d674
ShotCraterEntry6::
;> return ShotCraterShield1Tile0(mask)
	jp ShotCraterShield1Tile0
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry7(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 7: shield tile $61 = tile 1 of shield 1.
;@ test: mask = 0xD710
;@ sig: c752afd5
ShotCraterEntry7::
;> return ShotCraterShield1Tile1(mask)
	jp ShotCraterShield1Tile1
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry8(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 8: shield tile $62 = tile 2 of shield 1.
;@ test: mask = 0xD710
;@ sig: 9c72fc0a
ShotCraterEntry8::
;> return ShotCraterShield1Tile2(mask)
	jp ShotCraterShield1Tile2
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry9(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 9: shield tile $63 = tile 3 of shield 1.
;@ test: mask = 0xD710
;@ sig: 30adbe9b
ShotCraterEntry9::
;> return ShotCraterShield1Tile3(mask)
	jp ShotCraterShield1Tile3
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry10(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 10: shield tile $64 = tile 4 of shield 1.
;@ test: mask = 0xD710
;@ sig: 5c11902b
ShotCraterEntry10::
;> return ShotCraterShield1Tile4(mask)
	jp ShotCraterShield1Tile4
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry11(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 11: shield tile $65 = tile 5 of shield 1.
;@ test: mask = 0xD710
;@ sig: c6e24156
ShotCraterEntry11::
;> return ShotCraterShield1Tile5(mask)
	jp ShotCraterShield1Tile5
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry12(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 12: shield tile $66 = tile 0 of shield 2.
;@ test: mask = 0xD710
;@ sig: a58f5469
ShotCraterEntry12::
;> return ShotCraterShield2Tile0(mask)
	jp ShotCraterShield2Tile0
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry13(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 13: shield tile $67 = tile 1 of shield 2.
;@ test: mask = 0xD710
;@ sig: 13587e0b
ShotCraterEntry13::
;> return ShotCraterShield2Tile1(mask)
	jp ShotCraterShield2Tile1
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry14(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 14: shield tile $68 = tile 2 of shield 2.
;@ test: mask = 0xD710
;@ sig: 48782dd4
ShotCraterEntry14::
;> return ShotCraterShield2Tile2(mask)
	jp ShotCraterShield2Tile2
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry15(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 15: shield tile $69 = tile 3 of shield 2.
;@ test: mask = 0xD710
;@ sig: fdbc5e04
ShotCraterEntry15::
;> return ShotCraterShield2Tile3(mask)
	jp ShotCraterShield2Tile3
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry16(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 16: shield tile $6A = tile 4 of shield 2.
;@ test: mask = 0xD710
;@ sig: 910070b4
ShotCraterEntry16::
;> return ShotCraterShield2Tile4(mask)
	jp ShotCraterShield2Tile4
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry17(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 17: shield tile $6B = tile 5 of shield 2.
;@ test: mask = 0xD710
;@ sig: 00dd6240
ShotCraterEntry17::
;> return ShotCraterShield2Tile5(mask)
	jp ShotCraterShield2Tile5
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry18(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 18: shield tile $6C = tile 0 of shield 3.
;@ test: mask = 0xD710
;@ sig: 7f96d40f
ShotCraterEntry18::
;> return ShotCraterShield3Tile0(mask)
	jp ShotCraterShield3Tile0
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry19(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 19: shield tile $6D = tile 1 of shield 3.
;@ test: mask = 0xD710
;@ sig: c607483e
ShotCraterEntry19::
;> return ShotCraterShield3Tile1(mask)
	jp ShotCraterShield3Tile1
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry20(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 20: shield tile $6E = tile 2 of shield 3.
;@ test: mask = 0xD710
;@ sig: b94cfe71
ShotCraterEntry20::
;> return ShotCraterShield3Tile2(mask)
	jp ShotCraterShield3Tile2
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry21(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 21: shield tile $6F = tile 3 of shield 3.
;@ test: mask = 0xD710
;@ sig: 43c91b66
ShotCraterEntry21::
;> return ShotCraterShield3Tile3(mask)
	jp ShotCraterShield3Tile3
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry22(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 22: shield tile $70 = tile 4 of shield 3.
;@ test: mask = 0xD710
;@ sig: 2f7535d6
ShotCraterEntry22::
;> return ShotCraterShield3Tile4(mask)
	jp ShotCraterShield3Tile4
	db $00                                    ; padding to 4 bytes

;@ def ShotCraterEntry23(mask: de)
;@ path: shields/craters/shot
;@ ShotCraterTable entry 23: shield tile $71 = tile 5 of shield 3.
;@ test: mask = 0xD710
;@ sig: a9a047db
ShotCraterEntry23::
;> return ShotCraterShield3Tile5(mask)
	jp ShotCraterShield3Tile5
	db $00                                    ; padding to 4 bytes

;@ def ShieldCheckReturn()
;@ path: shields/hits
;@ The common way out of the shield checks.
;@ sig: 30ba9599
ShieldCheckReturn::
;> return
	ret


;@ path: unused
;@ A lone $C9 byte (a `ret`) that nothing reaches.
UnusedByte2671::
	db $c9

;@ path: unused
;@ Eight 8x8 tiles (2 bits per pixel) that nothing reads: a 2-pixel-wide upright bar like the cannon's shot,
;@ ragged crater-like patterns and two hollow squares.
;@ asset: tiles bpp=2 length=$80
UnusedTiles2672::
	db $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $18, $00, $00, $00, $00
	db $ff, $ff, $42, $66, $82, $c3, $41, $81, $a2, $81, $45, $c3, $22, $66, $ff, $ff
	db $ff, $ff, $dd, $ff, $bf, $f7, $e7, $c3, $e5, $c7, $a7, $c3, $e5, $c7, $ff, $ff
	db $ff, $ff, $a2, $e7, $45, $a5, $a2, $c3, $45, $c3, $a2, $a5, $45, $e7, $ff, $ff
	db $ff, $ff, $ff, $ff, $81, $81, $81, $81, $81, $81, $81, $81, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $81, $81, $81, $81, $81, $81, $81, $81, $ff, $ff
	db $ff, $ff, $f5, $ff, $bf, $eb, $f5, $e3, $a7, $c3, $ed, $c7, $af, $ff, $ff, $ff
	db $ff, $ff, $f5, $ff, $bf, $eb, $f5, $e3, $a7, $c3, $ed, $c7, $af, $ff, $ff, $ff

;@ def ShotCraterShield0Tile0(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile0, for the cannon's shot: tile 0 (top left) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6b5664fd
ShotCraterShield0Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield0Tile1(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile1, for the cannon's shot: tile 1 (bottom left) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 233b50e5
ShotCraterShield0Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield0Tile2(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile2, for the cannon's shot: tile 2 (top middle) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: b91843ce
ShotCraterShield0Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield0Tile3(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile3, for the cannon's shot: tile 3 (bottom middle) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: fd4e7008
ShotCraterShield0Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield0Tiles)
	ld hl, wShield0Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield0Tile4(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile4, for the cannon's shot: tile 4 (top right) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: ecabbf6f
ShotCraterShield0Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield0Tile5(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield0Tile5, for the cannon's shot: tile 5 (bottom right) of shield 0, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6358a20f
ShotCraterShield0Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield0Tiles + 0x20)
	ld hl, wShield0Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield1Tile0(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile0, for the cannon's shot: tile 0 (top left) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6d80535e
ShotCraterShield1Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield1Tile1(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile1, for the cannon's shot: tile 1 (bottom left) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 25ed6746
ShotCraterShield1Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield1Tile2(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile2, for the cannon's shot: tile 2 (top middle) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 2660617e
ShotCraterShield1Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield1Tile3(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile3, for the cannon's shot: tile 3 (bottom middle) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 623652b8
ShotCraterShield1Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield1Tiles)
	ld hl, wShield1Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield1Tile4(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile4, for the cannon's shot: tile 4 (top right) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: ea7d88cc
ShotCraterShield1Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield1Tile5(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield1Tile5, for the cannon's shot: tile 5 (bottom right) of shield 1, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 658e95ac
ShotCraterShield1Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield1Tiles + 0x20)
	ld hl, wShield1Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield2Tile0(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile0, for the cannon's shot: tile 0 (top left) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6cc7efd3
ShotCraterShield2Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield2Tile1(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile1, for the cannon's shot: tile 1 (bottom left) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 24aadbcb
ShotCraterShield2Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield2Tile2(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile2, for the cannon's shot: tile 2 (top middle) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: db2e0203
ShotCraterShield2Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield2Tile3(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile3, for the cannon's shot: tile 3 (bottom middle) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 9f7831c5
ShotCraterShield2Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield2Tiles)
	ld hl, wShield2Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield2Tile4(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile4, for the cannon's shot: tile 4 (top right) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: eb3a3441
ShotCraterShield2Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield2Tile5(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield2Tile5, for the cannon's shot: tile 5 (bottom right) of shield 2, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 64c92921
ShotCraterShield2Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield2Tiles + 0x20)
	ld hl, wShield2Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield3Tile0(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile0, for the cannon's shot: tile 0 (top left) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6f0f2a44
ShotCraterShield3Tile0::
;> for i in range(16):                               # lay the mask into scratch tile 0 (top left)
	ld hl, wCraterScratch
	ld b, $10
.copy
;>     wCraterScratch[0x00 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight0to2(hHitPixelX - 3)    # move it right, spilling into tile 2
	inc a
	call ShiftCraterRight0to2
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft2to0

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield3Tile1(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile1, for the cannon's shot: tile 1 (bottom left) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 27621e5c
ShotCraterShield3Tile1::
;> for i in range(16):                               # lay the mask into scratch tile 1 (bottom left)
	ld hl, wCraterScratch + $10
	ld b, $10
.copy
;>     wCraterScratch[0x10 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight1to3(hHitPixelX - 3)    # move it right, spilling into tile 3
	inc a
	call ShiftCraterRight1to3
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left (the shield's left edge: what moves out is lost)
	cpl
	inc a
	call ShiftCraterLeft3to1

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>     return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft

;> else:
.up
;>     ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>     return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield3Tile2(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile2, for the cannon's shot: tile 2 (top middle) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 078da1c5
ShotCraterShield3Tile2::
;> for i in range(16):                               # lay the mask into scratch tile 2 (top middle)
	ld hl, wCraterScratch + $20
	ld b, $10
.copy
;>     wCraterScratch[0x20 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right, spilling into tile 4
	inc a
	call ShiftCraterRight2to4

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>         return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>         return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft2to0(4 - hHitPixelX)    # move it left, spilling into tile 0
	cpl
	inc a
	call ShiftCraterLeft2to0

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield3Tile3(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile3, for the cannon's shot: tile 3 (bottom middle) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ Unlike its twins it moves the crater up or down in columns 0-1 instead of 1-2 when the hit is right of
;@ the middle, so the part pushed into tile 5 keeps its row.
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 3e671161
ShotCraterShield3Tile3::
;> for i in range(16):                               # lay the mask into scratch tile 3 (bottom middle)
	ld hl, wCraterScratch + $30
	ld b, $10
.copy
;>     wCraterScratch[0x30 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right, spilling into tile 5
	inc a
	call ShiftCraterRight3to5

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)  -- a slip in the game: this moves columns 0-1, so the part in tile 5 is not moved
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;>     else:
.up
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above  -- the same slip
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;> else:
.left
;>     ShiftCraterLeft3to1(4 - hHitPixelX)    # move it left, spilling into tile 1
	cpl
	inc a
	call ShiftCraterLeft3to1

;>     if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .leftUp

;>         ShiftCraterDownCols01(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols01
;>         return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft

;>     else:
.leftUp
;>         ShiftCraterUpCols01(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols01
;>         return CutShotCraterLeft(wShield3Tiles)
	ld hl, wShield3Tiles
	jp CutShotCraterLeft


;@ def ShotCraterShield3Tile4(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile4, for the cannon's shot: tile 4 (top right) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: e8f2f1d6
ShotCraterShield3Tile4::
;> for i in range(16):                               # lay the mask into scratch tile 4 (top right)
	ld hl, wCraterScratch + $40
	ld b, $10
.copy
;>     wCraterScratch[0x40 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight2to4(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight2to4
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft4to2(4 - hHitPixelX)    # move it left, spilling into tile 2
	cpl
	inc a
	call ShiftCraterLeft4to2

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down, spilling into the tile below
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up (the top edge: lost)
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight


;@ def ShotCraterShield3Tile5(mask: de)
;@ path: shields/craters/shot
;@ The same as BombCraterShield3Tile5, for the cannon's shot: tile 5 (bottom right) of shield 3, with the
;@ shot crater mask (de = wShotCraterMask). One of 24 such routines (ShotCraterTable).
;@ reads: hHitPixelX, hHitPixelY
;@ test: mask = 0xD710
;@ sig: 6701ecb6
ShotCraterShield3Tile5::
;> for i in range(16):                               # lay the mask into scratch tile 5 (bottom right)
	ld hl, wCraterScratch + $50
	ld b, $10
.copy
;>     wCraterScratch[0x50 + i] = mem[mask + i]
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .copy

;> if hHitPixelX >= 4:                               # hit right of the tile's middle
	ldh a, [hHitPixelX]
	sub $04
	jr c, .left

;>     ShiftCraterRight3to5(hHitPixelX - 3)    # move it right (the shield's right edge: what moves out is lost)
	inc a
	call ShiftCraterRight3to5
	jr .vertical

;> else:
.left
;>     ShiftCraterLeft5to3(4 - hHitPixelX)    # move it left, spilling into tile 3
	cpl
	inc a
	call ShiftCraterLeft5to3

.vertical
;> if hHitPixelY >= 4:                         # hit below the tile's middle
	ldh a, [hHitPixelY]
	sub $04
	jr c, .up

;>     ShiftCraterDownCols12(hHitPixelY - 3)    # move it down (the bottom edge: lost)
	inc a
	call ShiftCraterDownCols12
;>     return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight

;> else:
.up
;>     ShiftCraterUpCols12(4 - hHitPixelY)    # move it up, spilling into the tile above
	cpl
	inc a
	call ShiftCraterUpCols12
;>     return CutShotCraterRight(wShield3Tiles + 0x20)
	ld hl, wShield3Tiles + $20
	jp CutShotCraterRight


;@ def CutShotCraterLeft(shield: hl) -> a
;@ path: shields/craters/shot
;@ The same as CutBombCraterLeft, for the cannon's shot: cuts scratch tiles 0-3 into the shield, wipes the
;@ scratch, then makes the shot explode (hShotFlags bits 4 and 2, explosion tile $0A on its sprite).
;@ Returns wShotSpriteY - 6.
;@ writes: hShotFlags, wShotSpriteTile
;@ reads: hShotFlags, wShotSpriteY
;@ test: shield = rng.choice([0xD300, 0xD320, 0xD400, 0xD520, 0xD600])
;@ sig: 274e250d
CutShotCraterLeft::
;> for i in range(0x40):
	ld de, wCraterScratch
	ld b, $40
	ld c, $ff
.loop
;>     mem[shield + i] &= wCraterScratch[i]
	ld a, [de]
	and [hl]
	ld [hli], a
;>     wCraterScratch[i] = 0xFF
	ld a, c
	ld [de], a
	inc e
	dec b
	jr nz, .loop
;> hShotFlags |= 0x14                                # bit 4: exploding
	ldh a, [hShotFlags]
	set 4, a
	set 2, a
	ldh [hShotFlags], a
;> wShotSpriteTile = 0x0A                            # explosion
	ld a, $0a
	ld [wShotSpriteTile], a
;> return wShotSpriteY - 6
	ld a, [wShotSpriteY]
	sub $06
	ret


;@ def CutShotCraterRight(shield: hl) -> a
;@ path: shields/craters/shot
;@ The same as CutShotCraterLeft for scratch tiles 2-5 (middle and right column).
;@ writes: hShotFlags, wShotSpriteTile
;@ reads: hShotFlags, wShotSpriteY
;@ test: shield = rng.choice([0xD300, 0xD320, 0xD400, 0xD520, 0xD600])
;@ sig: 6c22164b
CutShotCraterRight::
;> for i in range(0x40):
	ld de, wCraterScratch + $20
	ld b, $40
	ld c, $ff
.loop
;>     mem[shield + i] &= wCraterScratch[0x20 + i]
	ld a, [de]
	and [hl]
	ld [hli], a
;>     wCraterScratch[0x20 + i] = 0xFF
	ld a, c
	ld [de], a
	inc e
	dec b
	jr nz, .loop
;> hShotFlags |= 0x14                                # bit 4: exploding
	ldh a, [hShotFlags]
	set 4, a
	set 2, a
	ldh [hShotFlags], a
;> wShotSpriteTile = 0x0A                            # explosion
	ld a, $0a
	ld [wShotSpriteTile], a
;> return wShotSpriteY - 6
	ld a, [wShotSpriteY]
	sub $06
	ret


;@ def UnusedScreenToMapAddr(x: b, y: c) -> hl
;@ path: unused
;@ Would turn a sprite position (sprite Y, so minus 16 for the screen row) into the address of the background
;@ map entry under it ($9800 + row * 32 + column). Nothing calls it.
;@ sig: 24c71875
UnusedScreenToMapAddr::
;> column = x >> 3
	ld a, b
	srl a
	srl a
	srl a
	ld d, $98
	ld e, a
;> row = u8(y - 0x10) >> 3
	ld a, c
	sub $10
	srl a
	srl a
	srl a
;>@ret return 0x9800 + row * 32 + column
	ld h, $00
	ld l, a
	add hl, hl
	add hl, hl
	add hl, hl
;=@ret
	add hl, hl
	add hl, hl
	add hl, de
	ret


;@ path: unused
;@ Four 8x8 tiles (2 bits per pixel) that no code loads: a pattern, two copies of a small figure and a
;@ framed pattern.
;@ asset: tiles bpp=2 length=$40
UnusedTiles2D45::
	db $ff, $ff, $f5, $ff, $bf, $eb, $f5, $e3, $a7, $c3, $ed, $c7, $af, $ff, $ff, $ff
	db $00, $00, $00, $22, $50, $08, $08, $3c, $1a, $3c, $18, $7c, $10, $3a, $00, $00
	db $08, $00, $00, $22, $50, $08, $08, $3c, $1a, $3c, $18, $7c, $10, $3a, $44, $10
	db $ff, $ff, $ad, $e7, $d7, $e7, $a5, $e7, $e7, $e7, $a9, $e7, $db, $e7, $ff, $ff

;@ def ShiftCraterUpCols01(rows: a)
;@ path: shields/craters
;@ Moves the crater picture in columns 0 and 1 of wCraterScratch up by `rows` pixel rows (both
;@ columns are 16 rows tall: a tile above a tile). Uses hHitPixelX for the count and hHitPixelY for the
;@ column's start offset.
;@ writes: hHitPixelX, hHitPixelY
;@ reads: hHitPixelX
;@ test: rows = rand(0, 4)
;@ sig: 80e53984
ShiftCraterUpCols01::
;> hHitPixelX = rows
	ldh [hHitPixelX], a
;> if rows == 0:
;>     return
	and a
	ret z

;> hHitPixelY = 0x03                       # column 0
	ld b, a
	ld a, $03
	ldh [hHitPixelY], a
;> ShiftCraterColumnUp(hHitPixelX)
	call ShiftCraterColumnUp
;> hHitPixelY = 0x23                       # column 1
	ldh a, [hHitPixelX]
	ld b, a
	ld a, $23
	ldh [hHitPixelY], a
;> ShiftCraterColumnUp(hHitPixelX)
	call ShiftCraterColumnUp
;> return
	ret


;@ def ShiftCraterUpCols12(rows: a)
;@ path: shields/craters
;@ Moves the crater picture in columns 1 and 2 of wCraterScratch up by `rows` pixel rows (both
;@ columns are 16 rows tall: a tile above a tile). Uses hHitPixelX for the count and hHitPixelY for the
;@ column's start offset.
;@ writes: hHitPixelX, hHitPixelY
;@ reads: hHitPixelX
;@ test: rows = rand(0, 4)
;@ sig: 25f0479b
ShiftCraterUpCols12::
;> hHitPixelX = rows
	ldh [hHitPixelX], a
;> if rows == 0:
;>     return
	and a
	ret z

;> hHitPixelY = 0x23                       # column 1
	ld b, a
	ld a, $23
	ldh [hHitPixelY], a
;> ShiftCraterColumnUp(hHitPixelX)
	call ShiftCraterColumnUp
;> hHitPixelY = 0x43                       # column 2
	ldh a, [hHitPixelX]
	ld b, a
	ld a, $43
	ldh [hHitPixelY], a
;> ShiftCraterColumnUp(hHitPixelX)
	call ShiftCraterColumnUp
;> return
	ret


;@ def ShiftCraterColumnUp(rows: b)
;@ path: shields/craters
;@ Moves one 16-row column of wCraterScratch up by `rows` pixel rows: each time rows 1-15 move to rows 0-14
;@ and row 15 keeps its value. hHitPixelY holds the offset of the column's row 1 second byte ($03, $23 or
;@ $43 for columns 0-2). Written out 15 times in a row (no inner loop) for speed.
;@ reads: hHitPixelY
;@ test: rows = rand(0, 4); hHitPixelY = 0x03 + 0x20 * rand(0, 2)
;@ sig: e2d302da
ShiftCraterColumnUp::
;>@loop while rows:
	ld a, b
	and a
	ret z

;>     rows -= 1
	dec b
;>     row1 = wCraterScratch + hHitPixelY - 1   # one pixel row = 2 bytes (the two bit planes)
	ld h, HIGH(wCraterScratch)
	ldh a, [hHitPixelY]
	ld l, a
	ld c, l
;>@rows     for k in range(15):
;>@ra         pixels = mem16[row1 + 2 * k]
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;>@rb         mem16[row1 + 2 * k - 2] = pixels       # one row higher
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@ra
	ld a, [hld]
	ld d, a
	ld a, [hld]
	ld e, a
;=@rb
	ld a, d
	ld [hld], a
	ld [hl], e
;=@rows
	inc c
	inc c
	ld l, c
;=@loop
	jp ShiftCraterColumnUp


;@ def ShiftCraterDownCols01(rows: a)
;@ path: shields/craters
;@ Moves the crater picture in columns 0 and 1 of wCraterScratch down by `rows` pixel rows (both
;@ columns are 16 rows tall: a tile above a tile). Uses hHitPixelX for the count and hHitPixelY for the
;@ column's start offset.
;@ writes: hHitPixelX, hHitPixelY
;@ reads: hHitPixelX
;@ test: rows = rand(0, 4)
;@ sig: c73de65a
ShiftCraterDownCols01::
;> hHitPixelX = rows
	ldh [hHitPixelX], a
;> if rows == 0:
;>     return
	and a
	ret z

;> hHitPixelY = 0x1C                       # column 0
	ld b, a
	ld a, $1c
	ldh [hHitPixelY], a
;> ShiftCraterColumnDown(hHitPixelX)
	call ShiftCraterColumnDown
;> hHitPixelY = 0x3C                       # column 1
	ldh a, [hHitPixelX]
	ld b, a
	ld a, $3c
	ldh [hHitPixelY], a
;> ShiftCraterColumnDown(hHitPixelX)
	call ShiftCraterColumnDown
;> return
	ret


;@ def ShiftCraterDownCols12(rows: a)
;@ path: shields/craters
;@ Moves the crater picture in columns 1 and 2 of wCraterScratch down by `rows` pixel rows (both
;@ columns are 16 rows tall: a tile above a tile). Uses hHitPixelX for the count and hHitPixelY for the
;@ column's start offset.
;@ writes: hHitPixelX, hHitPixelY
;@ reads: hHitPixelX
;@ test: rows = rand(0, 4)
;@ sig: 62289845
ShiftCraterDownCols12::
;> hHitPixelX = rows
	ldh [hHitPixelX], a
;> if rows == 0:
;>     return
	and a
	ret z

;> hHitPixelY = 0x3C                       # column 1
	ld b, a
	ld a, $3c
	ldh [hHitPixelY], a
;> ShiftCraterColumnDown(hHitPixelX)
	call ShiftCraterColumnDown
;> hHitPixelY = 0x5C                       # column 2
	ldh a, [hHitPixelX]
	ld b, a
	ld a, $5c
	ldh [hHitPixelY], a
;> ShiftCraterColumnDown(hHitPixelX)
	call ShiftCraterColumnDown
;> return
	ret


;@ def ShiftCraterColumnDown(rows: b)
;@ path: shields/craters
;@ Moves one 16-row column of wCraterScratch down by `rows` pixel rows: each time rows 0-14 move to rows 1-15
;@ (copied from the bottom up) and row 0 keeps its value. hHitPixelY holds the offset of the column's row 14
;@ ($1C, $3C or $5C for columns 0-2). Written out 15 times in a row for speed.
;@ reads: hHitPixelY
;@ test: rows = rand(0, 4); hHitPixelY = 0x1C + 0x20 * rand(0, 2)
;@ sig: cdcd58a9
ShiftCraterColumnDown::
;>@loop while rows:
	ld a, b
	and a
	ret z

;>     rows -= 1
	dec b
;>     row14 = wCraterScratch + hHitPixelY
	ld h, HIGH(wCraterScratch)
	ldh a, [hHitPixelY]
	ld l, a
	ld c, l
;>@rows     for k in range(15):
;>@ra         pixels = mem16[row14 - 2 * k]
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;>@rb         mem16[row14 - 2 * k + 2] = pixels      # one row lower
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@rows
	dec c
	dec c
	ld l, c
;=@ra
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
;=@rb
	ld a, d
	ld [hli], a
	ld [hl], e
;=@loop
	jp ShiftCraterColumnDown


;@ def ShiftCraterRight0to2(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 0 and 2 of wCraterScratch (two tiles side by side) right by
;@ `pixels` pixels: pixels leave tile 0 (top left) into tile 2 (top middle), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: ac7b5bc7
ShiftCraterRight0to2::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x00                  # tile 0
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $00
	ld h, a
;> dst = wCraterScratch + 0x20                  # tile 2
	ld a, $20
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] & 1
;>         mem[src + k] = mem[src + k] >> 1 | 0x80
	ld e, h
	ld a, [de]
	srl a
	set 7, a
	ld [de], a
;>         mem[dst + k] = mem[dst + k] >> 1 | carry << 7
	ld e, l
	ld a, [de]
	rra
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterRight1to3(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 1 and 3 of wCraterScratch (two tiles side by side) right by
;@ `pixels` pixels: pixels leave tile 1 (bottom left) into tile 3 (bottom middle), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: 37eab82b
ShiftCraterRight1to3::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x10                  # tile 1
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $10
	ld h, a
;> dst = wCraterScratch + 0x30                  # tile 3
	ld a, $30
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] & 1
;>         mem[src + k] = mem[src + k] >> 1 | 0x80
	ld e, h
	ld a, [de]
	srl a
	set 7, a
	ld [de], a
;>         mem[dst + k] = mem[dst + k] >> 1 | carry << 7
	ld e, l
	ld a, [de]
	rra
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterRight2to4(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 2 and 4 of wCraterScratch (two tiles side by side) right by
;@ `pixels` pixels: pixels leave tile 2 (top middle) into tile 4 (top right), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: 3698a489
ShiftCraterRight2to4::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x20                  # tile 2
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $20
	ld h, a
;> dst = wCraterScratch + 0x40                  # tile 4
	ld a, $40
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] & 1
;>         mem[src + k] = mem[src + k] >> 1 | 0x80
	ld e, h
	ld a, [de]
	srl a
	set 7, a
	ld [de], a
;>         mem[dst + k] = mem[dst + k] >> 1 | carry << 7
	ld e, l
	ld a, [de]
	rra
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterRight3to5(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 3 and 5 of wCraterScratch (two tiles side by side) right by
;@ `pixels` pixels: pixels leave tile 3 (bottom middle) into tile 5 (bottom right), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: ad094765
ShiftCraterRight3to5::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x30                  # tile 3
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $30
	ld h, a
;> dst = wCraterScratch + 0x50                  # tile 5
	ld a, $50
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] & 1
;>         mem[src + k] = mem[src + k] >> 1 | 0x80
	ld e, h
	ld a, [de]
	srl a
	set 7, a
	ld [de], a
;>         mem[dst + k] = mem[dst + k] >> 1 | carry << 7
	ld e, l
	ld a, [de]
	rra
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterLeft2to0(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 0 and 2 of wCraterScratch (two tiles side by side) left by
;@ `pixels` pixels: pixels leave tile 2 (top middle) into tile 0 (top left), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: 5e4521f9
ShiftCraterLeft2to0::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x20                  # tile 2
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $20
	ld h, a
;> dst = wCraterScratch + 0x00                  # tile 0
	ld a, $00
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] >> 7
;>         mem[src + k] = (mem[src + k] << 1 | 0x01) & 0xFF
	ld e, h
	ld a, [de]
	sla a
	set 0, a
	ld [de], a
;>         mem[dst + k] = (mem[dst + k] << 1 | carry) & 0xFF
	ld e, l
	ld a, [de]
	rla
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterLeft3to1(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 1 and 3 of wCraterScratch (two tiles side by side) left by
;@ `pixels` pixels: pixels leave tile 3 (bottom middle) into tile 1 (bottom left), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: c5d4c215
ShiftCraterLeft3to1::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x30                  # tile 3
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $30
	ld h, a
;> dst = wCraterScratch + 0x10                  # tile 1
	ld a, $10
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] >> 7
;>         mem[src + k] = (mem[src + k] << 1 | 0x01) & 0xFF
	ld e, h
	ld a, [de]
	sla a
	set 0, a
	ld [de], a
;>         mem[dst + k] = (mem[dst + k] << 1 | carry) & 0xFF
	ld e, l
	ld a, [de]
	rla
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterLeft4to2(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 2 and 4 of wCraterScratch (two tiles side by side) left by
;@ `pixels` pixels: pixels leave tile 4 (top right) into tile 2 (top middle), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: c7725bc4
ShiftCraterLeft4to2::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x40                  # tile 4
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $40
	ld h, a
;> dst = wCraterScratch + 0x20                  # tile 2
	ld a, $20
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] >> 7
;>         mem[src + k] = (mem[src + k] << 1 | 0x01) & 0xFF
	ld e, h
	ld a, [de]
	sla a
	set 0, a
	ld [de], a
;>         mem[dst + k] = (mem[dst + k] << 1 | carry) & 0xFF
	ld e, l
	ld a, [de]
	rla
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShiftCraterLeft5to3(pixels: a)
;@ path: shields/craters
;@ Moves the crater picture in tiles 3 and 5 of wCraterScratch (two tiles side by side) left by
;@ `pixels` pixels: pixels leave tile 5 (bottom right) into tile 3 (bottom middle), and "no hole" (1) bits
;@ come in at the other edge. Each of the 16 bytes (8 rows x 2 bit planes) is shifted on its own.
;@ writes: hHitPixelX
;@ reads: hHitPixelX
;@ test: pixels = rand(0, 4)
;@ sig: 5ce3b828
ShiftCraterLeft5to3::
;> hHitPixelX = pixels                          # shift count
	ldh [hHitPixelX], a
;> if pixels == 0:
;>     return
	and a
	ret z

;> src = wCraterScratch + 0x50                  # tile 5
	ld c, $10
	ld d, HIGH(wCraterScratch)
	ld a, $50
	ld h, a
;> dst = wCraterScratch + 0x30                  # tile 3
	ld a, $30
	ld l, a

;>@rows for k in range(16):
;>@bits     for _ in range(hHitPixelX):
.row
	ldh a, [hHitPixelX]
	ld b, a

.bit
	ld a, b
	and a
	jr z, .next

	dec b
;>         carry = mem[src + k] >> 7
;>         mem[src + k] = (mem[src + k] << 1 | 0x01) & 0xFF
	ld e, h
	ld a, [de]
	sla a
	set 0, a
	ld [de], a
;>         mem[dst + k] = (mem[dst + k] << 1 | carry) & 0xFF
	ld e, l
	ld a, [de]
	rla
	ld [de], a
;=@bits
	jr .bit

.next
;=@rows
	inc h
	inc l
	dec c
	jr nz, .row

;> return
	ret


;@ def ShowDeveloperCredit()
;@ path: title/credit
;@ The developer credit shown at power-on: the logo (CreditTiles) and its text (CreditScreenMap) fade in
;@ from white, stay, and fade out again (BGP $00, $64, $A4, $E4, $A4, $64, $00). Meanwhile the serial port
;@ listens: if the other Game Boy sends $E4 (it asks for a link game) the credit ends at once and a link game
;@ starts. Skipped when coming back from a game (hGameMode $BB).
;@ writes: hGameMode, hSerialOut
;@ reads: hGameMode, hSerialIn
;@ test: skip waits in long delay loops
;@ sig: 7894d5d8
ShowDeveloperCredit::
;> if hGameMode == 0xBB:
;>     return
	ldh a, [hGameMode]
	cp $bb
	jp z, CreditReturn

;> rSC = 0x80                                    # wait for a byte from the other Game Boy
	and $00
	set 7, a
	ldh [rSC], a
;> hSerialOut = 0xD0
	ld a, $d0
	ldh [hSerialOut], a
;> LcdOffClear()
	call LcdOffClear
;> CopyBytes(CreditTiles, 0x9600, 0xF0)          # tiles $60-$6E
	ld hl, CreditTiles
	ld de, $9600
	ld bc, $00f0
	call CopyBytes
;> DrawTilemapList(CreditScreenMap)
	ld de, CreditScreenMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;>@fade for bgp, steps in ((0x00, 0x30), (0x64, 0x40), (0xA4, 0x50), (0xE4, 0x70), (0xA4, 0x50), (0x64, 0x40), (0x00, 0x30)):  # fade in, stay, fade out
;>@pal     rBGP = bgp
	ld a, $00
	ldh [rBGP], a
;>@steps     for _ in range(steps):
	ld b, $30

.wait0
;>@delay         Delay(1)
	ld d, $01
	call Delay
;>@link         if hSerialIn == 0xE4:                  # the other Game Boy asks for a link game
;>@go             return CreditLinkRequest()
	ldh a, [hSerialIn]
	cp $e4
;=@go
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait0

;=@pal
	ld a, $64
	ldh [rBGP], a
;=@steps
	ld b, $40

.wait1
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait1

;=@pal
	ld a, $a4
	ldh [rBGP], a
;=@steps
	ld b, $50

.wait2
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait2

;=@pal
	ld a, $e4
	ldh [rBGP], a
;=@steps
	ld b, $70

.wait3
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait3

;=@pal
	ld a, $a4
	ldh [rBGP], a
;=@steps
	ld b, $50

.wait4
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait4

;=@pal
	ld a, $64
	ldh [rBGP], a
;=@steps
	ld b, $40

.wait5
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait5

;=@pal
	ld a, $00
	ldh [rBGP], a
;=@steps
	ld b, $30

.wait6
;=@delay
	ld d, $01
	call Delay
;=@link
	ldh a, [hSerialIn]
	cp $e4
;=@link
	jp z, CreditLinkRequest

;=@steps
	dec b
	jr nz, .wait6

;> hGameMode = 0                                 # nobody asked: go on to the title
	and $00
	ldh [hGameMode], a
;> return EndCreditScreen()
	jr EndCreditScreen

;@ def CreditLinkRequest()
;@ path: title/credit
;@ The other Game Boy asked for a link game during the credit: answers it and starts a link game.
;@ writes: hGameMode, hSyncFlags
;@ reads: hSyncFlags
;@ test: skip ends in the credit screen's LCD restart
;@ sig: 6fb0f58e
CreditLinkRequest::
;> AcceptLinkRequest()
	call AcceptLinkRequest
;> hSyncFlags |= 0x01
	ldh a, [hSyncFlags]
	set 0, a
	ldh [hSyncFlags], a
;> hGameMode = 0x55                              # a game is running
	ld a, $55
	ldh [hGameMode], a
;> return EndCreditScreen()                      # runs on into it

;@ def EndCreditScreen()
;@ path: title/credit
;@ Ends the credit screen: clears the screen and turns the LCD back on.
;@ test: skip turns the LCD off and on
;@ sig: 7dfd5f44
EndCreditScreen::
;> LcdOffClear()
	call LcdOffClear
;> LcdOn()
	call LcdOn

CreditReturn:
;> return
	ret


;@ def TitleIntro()
;@ path: title/intro
;@ The title screen's entrance: the SPACE INVADERS logo (TitleTiles, TitleScreenMap) scrolls up from below,
;@ then the window with the hi-score and the copyright lines appears at screen row $58 and a sprite is put
;@ on the logo; after a while everything fades to white. Start skips ahead and starts a game, as does a
;@ link request ($E4) from the other Game Boy. The secret codes are read during the scroll. When a game is
;@ already starting (hGameMode not 0) only the final fade-out runs.
;@ writes: hSavedOBP0, hSerialOut
;@ reads: hGameMode, hHiScoreHi, hHiScoreLo, hJoyPressed, hSavedOBP0, hSerialIn
;@ test: skip waits in long delay loops
;@ sig: fbdd2f35
TitleIntro::
;> if hGameMode != 0:
;>     return TitleFadeOut()
	ldh a, [hGameMode]
	and a
	jp nz, TitleFadeOut

;> rSC = 0x80                                    # wait for a byte from the other Game Boy
	and $00
	set 7, a
	ldh [rSC], a
;> hSerialOut = 0xD0
	ld a, $d0
	ldh [hSerialOut], a
;> LcdOffClear()
	call LcdOffClear
;> LoadBgTiles(TitleTiles)
	ld hl, TitleTiles
	call LoadBgTiles
;> DrawTilemapList(TitleScreenMap)
	ld de, TitleScreenMap
	call DrawTilemapList
;> # the hi-score as a tilemap list, built in an unused part of the OAM buffer
;> buf = wShadowOam + 0x4C
	ld hl, wShadowOam + $4c
;> mem[buf] = 0x9C                               # map address $9C0D: in the window
	ld a, $9c
	ld [hli], a
;> mem[buf + 1] = 0x0D
	ld a, $0d
	ld [hli], a
;> mem[buf + 2] = 0x05                           # 5 tiles follow
	ld a, $05
	ld [hli], a
;> WriteDigitTile(swap(hHiScoreHi), buf + 3)
	ldh a, [hHiScoreHi]
	swap a
	call WriteDigitTile
;> WriteDigitTile(hHiScoreHi, buf + 4)
	ldh a, [hHiScoreHi]
	inc hl
	call WriteDigitTile
;> WriteDigitTile(swap(hHiScoreLo), buf + 5)
	ldh a, [hHiScoreLo]
	swap a
	inc hl
	call WriteDigitTile
;> WriteDigitTile(hHiScoreLo, buf + 6)
	ldh a, [hHiScoreLo]
	inc hl
	call WriteDigitTile
;> WriteDigitTile(0x80, buf + 7)                 # a last 0: scores are multiples of 10
	ld a, $80
	inc hl
	call WriteDigitTile
;> DrawTilemapList(buf)                          # (the cleared OAM buffer ends the list)
	ld de, wShadowOam + $4c
	call DrawTilemapList
;> rSCX = 0
	and $00
	ldh [rSCX], a
;> rWY = 0x58
	ld a, $58
	ldh [rWY], a
;> rLCDC &= 0x9F                                 # window off for now
	ldh a, [rLCDC]
	and $9f
	ldh [rLCDC], a

;>@scroll for scy in range(0x80, 0x100):          # the logo scrolls up into place
	ld a, $80
;>     rSCY = scy
.scroll
	ldh [rSCY], a
;>     LcdOn()
	call LcdOn
;>     hSavedOBP0 = rOBP0
	ldh a, [rOBP0]
	ldh [hSavedOBP0], a
;>     rOBP0 = 0                                 # sprites invisible
	and $00
	ldh [rOBP0], a
;>     mem[wShadowOam] = 0xF0                    # sprite 0 off screen
	ld hl, wShadowOam
	ld a, $f0
	ld [hli], a
;>     mem[wShadowOam + 1] = 0xF0
	ld a, $f0
	ld [hli], a
;>     mem[wShadowOam + 2] = 0xA4
	ld a, $a4
	ld [hli], a
;>     mem[wShadowOam + 3] = 0x80
	ld a, $80
	ld [hl], a
;>     ReadJoypad()
	call ReadJoypad
;>     CheckTitleCheatCodes()
	call CheckTitleCheatCodes
;>     if hJoyPressed & 0x08:                    # Start
;>         return TitleStartPressed()
	ldh a, [hJoyPressed]
	and a
	bit 3, a
	jp nz, TitleStartPressed

;>     if hSerialIn == 0xE4:                     # the other Game Boy asks for a link game
;>         return TitleLinkRequest()
	ldh a, [hSerialIn]
	cp $e4
	jp z, TitleLinkRequest

;>     Delay(0x10)
	ld d, $10
	call Delay
;=@scroll
	ldh a, [rSCY]
	inc a
	jp nz, .scroll

;>@pause for _ in range(0x60):
	ld b, $60

;>     Delay(1)
.pause
	ld d, $01
	call Delay
;>     ReadJoypad()
	call ReadJoypad
;>     if hJoyPressed & 0x08:
;>         return TitleStartPressed()
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, TitleStartPressed

;>     if hSerialIn == 0xE4:
;>         return TitleLinkRequest()
	ldh a, [hSerialIn]
	cp $e4
	jp z, TitleLinkRequest

;=@pause
	dec b
	jr nz, .pause

;> # sprite 0: tile $39 at X $92, Y $49, behind the background
;> mem[wShadowOam] = 0x49
	ld hl, wShadowOam
	ld a, $49
	ld [hli], a
;> mem[wShadowOam + 1] = 0x92
	ld a, $92
	ld [hli], a
;> mem[wShadowOam + 2] = 0x39
	ld a, $39
	ld [hli], a
;> mem[wShadowOam + 3] = 0x80
	ld a, $80
	ld [hl], a
;> rOBP0 = hSavedOBP0                            # sprites visible again
	ldh a, [hSavedOBP0]
	ldh [rOBP0], a
;> rLCDC |= 0x60                                 # window on, from the map at $9C00
	ldh a, [rLCDC]
	or $60
	ldh [rLCDC], a

;>@show for _ in range(0x80):
	ld e, $80

;>     ReadJoypad()
.show
	call ReadJoypad
;>     if hJoyPressed & 0x08:
;>         return TitleStartPressed()
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, TitleStartPressed

;>     if hSerialIn == 0xE4:
;>         return TitleLinkRequest()
	ldh a, [hSerialIn]
	cp $e4
	jp z, TitleLinkRequest

;>     Delay(8)
	ld d, $08
	call Delay
;=@show
	dec e
	jr nz, .show

;>@fade for _ in range(4):                       # fade to white: shift the palettes 2 bits up
	ld b, $04

;>     rOBP0 = (rOBP0 << 2) & 0xFF
.fade
	ld hl, rBGP
	ld e, l
	ld d, h
	ld hl, rOBP0
	sla [hl]
	sla [hl]
;>     rBGP = (rBGP << 2) & 0xFF
	ld l, e
	ld h, d
	sla [hl]
	sla [hl]
;>     Delay(8)
	ld d, $08
	call Delay
;=@fade
	dec b
	jr nz, .fade

;> Delay(8)
	ld d, $08
	call Delay
;> return TitleFadeOut()
	jr TitleFadeOut

;@ def TitleLinkRequest()
;@ path: title/intro
;@ The other Game Boy asked for a link game during the title: answers it, then starts like Start does.
;@ test: skip ends in the title fade-out
;@ sig: e93d29f8
TitleLinkRequest::
;> AcceptLinkRequest()
	call AcceptLinkRequest
;> return TitleStartPressed()                    # runs on into it

;@ def TitleStartPressed()
;@ path: title/intro
;@ Start (or a link request) during the title: a game is to begin.
;@ writes: hGameMode, hSyncFlags
;@ reads: hSyncFlags
;@ test: skip ends in the title fade-out
;@ sig: ca89a873
TitleStartPressed::
;> hSyncFlags |= 0x01
	ldh a, [hSyncFlags]
	set 0, a
	ldh [hSyncFlags], a
;> hGameMode = 0x55                              # a game is running
	ld a, $55
	ldh [hGameMode], a
;> return TitleFadeOut()                         # runs on into it

;@ def TitleFadeOut()
;@ path: title/intro
;@ Ends the title entrance: logo in place (SCY 0) with the window on, then the background palette is shifted
;@ right one bit at a time until it is all white; finally the window goes off and the sprite palette is reset.
;@ test: skip waits in delay loops
;@ sig: 523a08fe
TitleFadeOut::
;> rSCY = 0
	and $00
	ldh [rSCY], a
;> rLCDC |= 0x60                                 # window on
	ldh a, [rLCDC]
	or $60
	ldh [rLCDC], a
;> Delay(8)
	ld d, $08
	call Delay
;>@fade for _ in range(8):
	ld c, $08
	ld hl, rBGP

;>     rBGP >>= 1                                # $E4, $72, $39 ... $00: fades to white
.fade
	srl [hl]
;>     Delay(4)
	ld d, $04
	call Delay
;=@fade
	dec c
	jr nz, .fade

;> Delay(4)
	ld d, $04
	call Delay
;> rSCY = 0
	and $00
	ldh [rSCY], a
;> rOBP0 = 0xE4
	ld a, $e4
	ldh [rOBP0], a
;> rLCDC &= 0x9F                                 # window off
	ldh a, [rLCDC]
	and $9f
	ldh [rLCDC], a
;> return
	ret


;@ def ShowScoreTableDemo()
;@ path: title/demo
;@ The attract demo after the title: "P L A" and "SPACE INVADERS" are typed out, the SCORE ADVANCE
;@ TABLE appears with the UFO and the three invaders (= ? MYSTERY, 30, 20, 10 POINTS), and on every
;@ second run the famous gag follows: the Y of "PLAY" stands upside down, an invader walks in from
;@ the right, carries the Y off the screen and brings it back the right way up. Holding A+B when it
;@ begins makes the score-table invaders flap. Start ends the demo, and so does a link request from
;@ the other Game Boy ($E4: AcceptLinkRequest); both go on to the menu (hGameMode = $55). Without
;@ either it returns with hGameMode still 0, and the title sequence goes on.
;@ writes: hGameMode, hSerialOut, hSyncFlags, wAttractCount, wBomb0SpriteTile, wBomb1SpriteTile, wBomb2SpriteTile, wBomb2SpriteX, wBomb2SpriteY, wCannonLeftTile, wLinkShotSpriteTile, wSceneFlags, wShadowOam, wShotSpriteTile, wUfoSpriteTile
;@ reads: hGameMode, hJoyHeld, hSerialIn, hSyncFlags, hTimerLo, wAttractCount, wBomb2SpriteX, wSceneFlags, wShadowOam
;@ test: skip waits for the VBlank hook, buttons and the link
;@ sig: 856fa5b3
ShowScoreTableDemo::
;> if hGameMode != 0:
;>@st0     hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hGameMode]
	and a
	jp nz, .start
;> wAttractCount += 1
	ld a, [wAttractCount]
	inc a
	ld [wAttractCount], a
;> wSceneFlags = 0
	xor a
	ld [wSceneFlags], a
;> ReadJoypad()
	call ReadJoypad
;> if hJoyHeld & 0x03 == 0x03:          # A+B held: the invaders of the table flap
	ldh a, [hJoyHeld]
	and $03
	cp $03
	jr nz, .noFlap
;>     wSceneFlags |= 0x10
	ld a, [wSceneFlags]
	set 4, a
	ld [wSceneFlags], a

.noFlap:
;> rSC = 0x80                           # wait for a byte from the other Game Boy
	and $00
	set 7, a
	ldh [rSC], a
;> hSerialOut = 0xD0
	ld a, $d0
	ldh [hSerialOut], a
;> LcdOffClear()
;> LcdOn()
	call LcdOffClear
	call LcdOn
;>@c1 for _ in range(32):             # a link request from the other Game Boy?
	ld b, $20
.check1:
;>@lk     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c1
	dec b
	jr nz, .check1
;> TypeText(TextPla, 0x9846, 5, 0xFF)      # "P L A" (the Y is a sprite)
	ld de, $9846
	ld hl, TextPla
	ld b, $05
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c2 for _ in range(32):
	ld b, $20
.check2:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c2
	dec b
	jr nz, .check2
;> wShadowOam[0x20] = 0x20                # sprite 8: the Y of PLAY
;> wShadowOam[0x21] = 0x68
	ld a, $20
	ld [wShadowOam + $20], a
	ld a, $68
	ld [wShadowOam + $21], a
;> wShadowOam[0x22] = 0xA2              # "Y"
	ld a, $a2
	ld [wShadowOam + $22], a
;>@flip wShadowOam[0x23] = 0x40 if wAttractCount & 0x01 else 0     # upside down on every second run
	ld c, $00
	ld a, [wAttractCount]
	bit 0, a
	jr z, .upright
;=@flip
	ld c, $40

.upright:
;=@flip
	ld a, c
	ld [wShadowOam + $23], a
;>@c3 for _ in range(32):
	ld b, $20
.check3:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c3
	dec b
	jr nz, .check3
;> TypeText(TextSpaceInvaders, 0x9883, 14, 0xFF)
	ld de, $9883
	ld hl, TextSpaceInvaders
	ld b, $0e
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c4 for _ in range(32):
	ld b, $20
.check4:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c4
	dec b
	jr nz, .check4
;> TypeText(TextScoreAdvanceTable, 0x98E1, 19, 0)   # at once
	ld de, $98e1
	ld hl, TextScoreAdvanceTable
	ld b, $13
	ld c, $00
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c5 for _ in range(32):
	ld b, $20
.check5:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c5
	dec b
	jr nz, .check5
;>@s0 wShadowOam[0:3] = [0x60, 0x28, 0x2C]   # sprite 0: UFO, left half
	ld hl, wShadowOam
	ld a, $60
	ld [hli], a
	ld a, $28
	ld [hli], a
;=@s0
	ld a, $2c
	ld [hli], a
;=@s0
	inc hl
;>@s1 wShadowOam[4:7] = [0x60, 0x30, 0x2C]   # sprite 1: UFO, right half (mirrored)
	ld a, $60
	ld [hli], a
	ld a, $30
	ld [hli], a
	ld a, $2c
	ld [hli], a
;> wShadowOam[7] = 0x20
	ld a, $20
	ld [hli], a
;>@s2 wShadowOam[8:11] = [0x70, 0x28, 0x20]   # sprite 2: 30-point invader
	ld a, $70
	ld [hli], a
	ld a, $28
	ld [hli], a
	ld a, $20
	ld [hli], a
;=@s2
	inc hl
;>@s3 wShadowOam[12:15] = [0x70, 0x30, 0x21]
	ld a, $70
	ld [hli], a
	ld a, $30
	ld [hli], a
	ld a, $21
	ld [hli], a
;=@s3
	inc hl
;>@s4 wShadowOam[16:19] = [0x80, 0x28, 0x24]   # sprite 4: 20-point invader
	ld a, $80
	ld [hli], a
	ld a, $28
	ld [hli], a
	ld a, $24
	ld [hli], a
;=@s4
	inc hl
;>@s5 wShadowOam[20:23] = [0x80, 0x30, 0x25]
	ld a, $80
	ld [hli], a
	ld a, $30
	ld [hli], a
	ld a, $25
	ld [hli], a
;=@s5
	inc hl
;>@s6 wShadowOam[24:27] = [0x90, 0x28, 0x28]   # sprite 6: 10-point invader
	ld a, $90
	ld [hli], a
	ld a, $28
	ld [hli], a
	ld a, $28
	ld [hli], a
;=@s6
	inc hl
;>@s7 wShadowOam[28:31] = [0x90, 0x30, 0x29]
	ld a, $90
	ld [hli], a
	ld a, $30
	ld [hli], a
	ld a, $29
	ld [hli], a
;=@s7
	inc hl
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c6 for _ in range(32):
	ld b, $20
.check6:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c6
	dec b
	jr nz, .check6
;> TypeText(TextMystery, 0x9946, 12, 0xFF)   # "= ? MYSTERY"
	ld de, $9946
	ld hl, TextMystery
	ld b, $0c
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c7 for _ in range(32):
	ld b, $20
.check7:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c7
	dec b
	jr nz, .check7
;> TypeText(Text30Points, 0x9986, 11, 0xFF)
	ld de, $9986
	ld hl, Text30Points
	ld b, $0b
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c8 for _ in range(32):
	ld b, $20
.check8:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c8
	dec b
	jr nz, .check8
;> TypeText(Text20Points, 0x99C6, 11, 0xFF)
	ld de, $99c6
	ld hl, Text20Points
	ld b, $0b
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c9 for _ in range(32):
	ld b, $20
.check9:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c9
	dec b
	jr nz, .check9
;> TypeText(Text10Points, 0x9A06, 11, 0xFF)
	ld de, $9a06
	ld hl, Text10Points
	ld b, $0b
	ld c, $ff
	call TypeText
;> if wSceneFlags & 0x04: hSyncFlags |= 0x01; hGameMode = 0x55; return      # Start pressed
	ld a, [wSceneFlags]
	bit 2, a
	jp nz, .start
;> if wSceneFlags & 0x08: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	bit 3, a
	jp nz, .linkRequest
;>@c10 for _ in range(32):
	ld b, $20
.check10:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c10
	dec b
	jr nz, .check10
;> wShadowOam[0x30] = 0x20                # sprites 12-13: the invader that fetches the Y,
;> wShadowOam[0x31] = 0xD7              # still off the screen on the right
	ld a, $20
	ld [wShadowOam + $30], a
	ld a, $d7
	ld [wShadowOam + $31], a
;> wShadowOam[0x32] = 0x2F
;> wShadowOam[0x34] = 0x20
	ld a, $2f
	ld [wShadowOam + $32], a
	ld a, $20
	ld [wShadowOam + $34], a
;> wShadowOam[0x35] = 0xDF
;> wShadowOam[0x36] = 0x30
	ld a, $df
	ld [wShadowOam + $35], a
	ld a, $30
	ld [wShadowOam + $36], a
;> wSceneFlags &= 0x10                  # keep only the A+B flag
	ld a, [wSceneFlags]
	and $10
	ld [wSceneFlags], a
;>@c11 for _ in range(32):
	ld b, $20
.check11:
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@c11
	dec b
	jr nz, .check11
;> if not wAttractCount & 0x01:        # the Y is upright: no walk this time
	ld a, [wAttractCount]
	bit 0, a
	jr nz, .walk
;>     Delay(0xFF)
	ld d, $ff
	call Delay
;>     return
	jp .return


.walk:
;>@walk while True:
;>     left, right = wShadowOam[0x31], wShadowOam[0x35]   # X of the two halves
	ld a, [wShadowOam + $31]
	ld b, a
	ld a, [wShadowOam + $35]
	ld c, a
;>     if wSceneFlags & 0x80:           # walking right
	ld a, [wSceneFlags]
	bit 7, a
	jr z, .walkingLeft
;>         if right == 0xBF:            # off the screen on the right: turn round
	ld a, c
	cp $bf
	jr nz, .stepRight
;>             wSceneFlags &= ~0x80
	ld a, [wSceneFlags]
	res 7, a
	ld [wSceneFlags], a
;>             if wSceneFlags & 0x20:   # carrying the Y
	bit 5, a
	jr z, .moved
;>                 if wSceneFlags & 0x40:   # (never happens: the swap is done only once)
	bit 6, a
	jr z, .swap
;>                     wSceneFlags &= ~0x40
	res 6, a
	ld [wSceneFlags], a
;>                     wShadowOam[0x22] = 0x2D
;>                     wShadowOam[0x23] = 0x40
	ld a, $2d
	ld [wShadowOam + $22], a
	ld a, $40
	ld [wShadowOam + $23], a
	jr .moved

.swap:
;>                 else:                # off screen the Y is turned the right way up
;>                     wSceneFlags |= 0x40
	set 6, a
	ld [wSceneFlags], a
;>                     wShadowOam[0x23] = 0
	xor a
	ld [wShadowOam + $23], a
	jr .moved

.stepRight:
;>         else:
;>             if wSceneFlags & 0x20:   # the Y moves along
	ld a, [wSceneFlags]
	bit 5, a
	jr z, .rightOnly
;>                 wShadowOam[0x21] += 1
	ld a, [wShadowOam + $21]
	inc a
	ld [wShadowOam + $21], a

.rightOnly:
;>             left += 1
;>             right += 1
	inc b
	inc c
	jr .moved

.walkingLeft:
;>     else:                            # walking left
;>         if left == 0x69:             # at the Y: pick it up or put it down, turn round
	ld a, b
	cp $69
	jr nz, .stepLeft
;>             wSceneFlags |= 0x80
	ld a, [wSceneFlags]
	set 7, a
	ld [wSceneFlags], a
;>@x20             wSceneFlags ^= 0x20
	bit 5, a
	jr z, .pickUp
;=@x20
	res 5, a
	ld [wSceneFlags], a
	jr .moved

.pickUp:
;=@x20
	set 5, a
	ld [wSceneFlags], a
	jr .moved

.stepLeft:
;>         else:
;>             if wSceneFlags & 0x20:
	ld a, [wSceneFlags]
	bit 5, a
	jr z, .leftOnly
;>                 wShadowOam[0x21] -= 1
	ld a, [wShadowOam + $21]
	dec a
	ld [wShadowOam + $21], a

.leftOnly:
;>             left -= 1
;>             right -= 1
	dec b
	dec c

.moved:
;>     wShadowOam[0x31] = left
;>     wShadowOam[0x35] = right
	ld a, b
	ld [wShadowOam + $31], a
	ld a, c
	ld [wShadowOam + $35], a
;>     if wSceneFlags & 0x01:           # walking frame
	ld a, [wSceneFlags]
	bit 0, a
	jr z, .frameA
;>         wSceneFlags &= ~0x01
	res 0, a
	ld [wSceneFlags], a
;>         wShadowOam[0x32] = 0x31
;>         wShadowOam[0x36] = 0x32
	ld a, $31
	ld [wShadowOam + $32], a
	ld a, $32
	ld [wShadowOam + $36], a
	jr .flap

.frameA:
;>     else:
;>         wSceneFlags |= 0x01
	set 0, a
	ld [wSceneFlags], a
;>         wShadowOam[0x32] = 0x2F
;>         wShadowOam[0x36] = 0x30
	ld a, $2f
	ld [wShadowOam + $32], a
	ld a, $30
	ld [wShadowOam + $36], a

.flap:
;>     if wSceneFlags & 0x10:           # A+B: the table's invaders flap with the timer
	ld a, [wSceneFlags]
	bit 4, a
	jr z, .pause
;>         if hTimerLo & 0x80:
	ldh a, [hTimerLo]
	bit 7, a
	jr z, .flapB
;>@fa             for spr, tile in zip(range(2, 8), (0x20, 0x21, 0x24, 0x25, 0x28, 0x29)):
;>                 wShadowOam[4 * spr + 2] = tile
	ld a, $20
	ld [wShadowOam + $0a], a
	ld a, $21
	ld [wShadowOam + $0e], a
;=@fa
	ld a, $24
	ld [wShadowOam + $12], a
	ld a, $25
	ld [wShadowOam + $16], a
;=@fa
	ld a, $28
	ld [wShadowOam + $1a], a
	ld a, $29
	ld [wShadowOam + $1e], a
	jr .pause

.flapB:
;>         else:
;>@fb             for spr, tile in zip(range(2, 8), (0x22, 0x23, 0x26, 0x27, 0x2A, 0x2B)):
;>                 wShadowOam[4 * spr + 2] = tile
	ld a, $22
	ld [wShadowOam + $0a], a
	ld a, $23
	ld [wShadowOam + $0e], a
;=@fb
	ld a, $26
	ld [wShadowOam + $12], a
	ld a, $27
	ld [wShadowOam + $16], a
;=@fb
	ld a, $2a
	ld [wShadowOam + $1a], a
	ld a, $2b
	ld [wShadowOam + $1e], a
;>             d = 16                   # the pause below (otherwise d is left over: 256 rounds)
	ld d, $10

.pause:
;>@pause     for _ in range(d):
;>         ReadJoypad()
	call ReadJoypad
;>         if hJoyHeld & 0x08: hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hJoyHeld]
	bit 3, a
	jp nz, .start
;>         if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@pause
	dec d
	jr nz, .pause
;>@done     if wSceneFlags & 0x40 and not wSceneFlags & 0x20:   # the Y is back: done
;>         break
	ld a, [wSceneFlags]
	bit 6, a
	jp z, .walk
;=@done
	bit 5, a
	jp nz, .walk
;>@end for _ in range(240):              # a last look at Start and the link
	ld d, $f0
.end:
;>     if hJoyHeld & 0x08: hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hJoyHeld]
	bit 3, a
	jp nz, .start
;>     if hSerialIn == 0xE4: AcceptLinkRequest(); hSyncFlags |= 0x01; hGameMode = 0x55; return
	ldh a, [hSerialIn]
	cp $e4
	jp z, .linkRequest
;=@end
	dec d
	jr nz, .end
;> return
	jr .return

.linkRequest:
;=@lk
	call AcceptLinkRequest

.start:
;=@st0
	ldh a, [hSyncFlags]
	set 0, a
	ldh [hSyncFlags], a
	ld a, $55
	ldh [hGameMode], a

.return:
	ret


;@ def SelectGameMode()
;@ path: title/menu
;@ The SELECT GAME MODE menu (1 PLAYER / 2 PLAYER), shown when the title sequence ends. Select
;@ switches the choice, Start takes it. Over the cable the two Game Boys talk in single bytes: $E4
;@ "let's play linked", $EC "I am in this menu", $A4 "start the link game", $55 "go", $4E "I play
;@ alone", $AE "I give up" (also sent after about 30 seconds without a choice: hGameMode = $44).
;@ The Game Boy that answered a link request (hSyncFlags bit 3) only follows the other one's choice.
;@ When the other one shows up in this menu, the choice switches to 2 PLAYER once by itself.
;@ writes: hGameMode, hIEMask, hLinkFlags, hSerialOut, hSyncFlags, hTimerHi, hTimerLo, wCheatFlags, wShadowOam
;@ reads: hGameMode, hJoyPressed, hLinkFlags, hSerialIn, hSyncFlags, hTimerHi
;@ test: skip talks to the other Game Boy and waits for buttons
;@ sig: 9b78ecf2
SelectGameMode::
;> if hGameMode != 0x55:
;>     return
	ldh a, [hGameMode]
	cp $55
	jp nz, .return
;> hTimerHi = 0
;> hTimerLo = 0
	and $00
	ldh [hTimerHi], a
	ldh [hTimerLo], a
;> hLinkFlags &= ~0x04                  # the menu is not done yet
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> hSerialOut = 0xEC
	ld a, $ec
	ldh [hSerialOut], a
;> LcdOffClear()
;> DrawTilemapList(ModeMenuMap)
	call LcdOffClear
	ld de, ModeMenuMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> wShadowOam[0x45] = 0x28              # X of the menu cursor
;> wShadowOam[0x47] = 0
	ld a, $28
	ld [wShadowOam + $45], a
	ld a, $00
	ld [wShadowOam + $47], a
;> if hSyncFlags & 0x08:                # this Game Boy answered a link request: the other one decides
	ldh a, [hSyncFlags]
	bit 3, a
	jp nz, .answering
;>@a1     hSerialOut = 0xEC
;>@a2     DrawModeCursor()
;>@a3     while True:
;>@a4         if hSerialIn == 0x4E:        # the other one plays alone: so may this one
;>@a5             CancelLink(); break
;>@a6         if hSerialIn == 0xA4:        # the other one starts the link game
;>@a7             hLinkFlags |= 0x01
;>@a8             DrawModeCursor()
;>@a9             rIF = 0
;>@a10             hIEMask = 0x0D; rIE = 0x0D       # VBlank, timer and serial interrupts
;>@a11             DrawModeCursor(); hLinkFlags |= 0x04; return
;>@a12         if hSerialIn == 0xAE or hTimerHi >= 0x20: hSerialOut = 0xAE; Delay(8); hGameMode = 0x44; return
;> else:
;>     rSC = 0x01                       # this Game Boy has the clock
;>     hSyncFlags = 0x01
	and $00
	set 0, a
	ldh [rSC], a
	ldh [hSyncFlags], a
;>     hSerialOut = 0xE4                # "let's play linked"
	ld a, $e4
	ldh [hSerialOut], a
;>@loop while True:
;>     DrawModeCursor()
.redraw:
	call DrawModeCursor
;>@wait     while True:
;>         if hTimerHi >= 0x20:         # about 30 seconds without a choice
.wait:
	ldh a, [hTimerHi]
	sub $20
	jp nc, .giveUp
;>@t1             hSerialOut = 0xAE; Delay(8); hGameMode = 0x44; return
;>         Delay(0x10)
	ld d, $10
	call Delay
;>         ReadJoypad()
	call ReadJoypad
;>         if hJoyPressed & 0x04:       # Select
;>             toggle = True; break
	ldh a, [hJoyPressed]
	bit 2, a
	jr nz, .toggle
;>         if hJoyPressed & 0x08:       # Start
;>             toggle = False; break
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, .start
;>         if hSerialIn == 0xEC:        # the other Game Boy is in this menu too
	ldh a, [hSerialIn]
	cp $ec
	jr nz, .wait
;>             hSyncFlags = 0x01
	and $00
	set 0, a
	ldh [hSyncFlags], a
;>             if not hLinkFlags & 0x02:   # switch to 2 PLAYER, once
;>                 toggle = True; break
	ldh a, [hLinkFlags]
	bit 1, a
	jr nz, .wait

.toggle:
;>     if toggle:
;>         if not hLinkFlags & 0x01:
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .toOne
;>             hLinkFlags |= 0x03       # 2 PLAYER (bit 1: it was chosen once)
	ldh a, [hLinkFlags]
	set 0, a
	set 1, a
	ldh [hLinkFlags], a
	jr .toggled

.toOne:
;>         else:
;>             hLinkFlags &= ~0x01      # 1 PLAYER
	ldh a, [hLinkFlags]
	res 0, a
	ldh [hLinkFlags], a

.toggled:
;>         continue
	jp .redraw


.start:
;>     if not hLinkFlags & 0x01:        # 1 PLAYER chosen
	ldh a, [hLinkFlags]
	bit 0, a
	jp z, .onePlayer
;>@op         hSerialOut = 0x4E; Delay(8); CancelLink(); break     # "I play alone"
;>     answer = None
;>     if hSyncFlags & 0x01:            # 2 PLAYER: ask the other one to start
	ldh a, [hSyncFlags]
	bit 0, a
	jr z, .noPartner
;>         hSerialOut = 0xA4
	ld a, $a4
	ldh [hSerialOut], a
;>@try         for _ in range(16):
	ld b, $10
.try:
;>             while rSC & 0x80:        # a transfer is still running
;>                 wait_serial()
	ldh a, [rSC]
	bit 7, a
	jr nz, .try
;>             hSyncFlags |= 0x80       # VBlank starts the next exchange
	ldh a, [hSyncFlags]
	set 7, a
	ldh [hSyncFlags], a
;>             while hSyncFlags & 0x80:
;>                 wait_vblank_flag()
.waitSent:
	ldh a, [hSyncFlags]
	bit 7, a
	jr nz, .waitSent
;>@in             if hSerialIn in (0xD4, 0xEC, 0xAE, 0x00, 0xFF):
	ldh a, [hSerialIn]
;=@d4
	cp $d4
	jr z, .gaveWay
;=@ec
	cp $ec
	jr z, .linkStart
;=@ae
	cp $ae
	jr z, .giveUp
;=@in
	cp $00
	jr z, .noPartner
	cp $ff
	jr z, .noPartner
;>                 answer = hSerialIn; break
;=@try
	dec b
	jr nz, .try
;>@d4         if answer == 0xD4:           # the other one answered a request itself: it decides
;>@d4b             hLinkFlags &= ~0x01; hSerialOut = 0xEC; continue
;>@ec         elif answer == 0xEC:         # it is ready: the link game starts
;>@ec1             hSyncFlags |= 0x01; hSerialOut = 0x55
;>@ec2             wCheatFlags = 0; hLinkFlags = 0x01     # no secret features in a link game
;>@ec3             rIF = 0; hIEMask = 0x0D; rIE = 0x0D; break
;>@ae         elif answer == 0xAE:
;>@ae2             hSerialOut = 0xAE; Delay(8); hGameMode = 0x44; return
;>     hSerialOut = 0xE4                # nobody there: back to the choice
.noPartner:
	ld a, $e4
	ldh [hSerialOut], a
;>     hLinkFlags = 0
	and $00
	ldh [hLinkFlags], a
;>     continue
	jp .redraw


.gaveWay:
;=@d4b
	ldh a, [hLinkFlags]
	res 0, a
	ldh [hLinkFlags], a
	ld a, $ec
	ldh [hSerialOut], a
	jp .redraw


.giveUp:
;=@t1
	ld a, $ae
	ldh [hSerialOut], a
	ld d, $08
	call Delay
	ld a, $44
	ldh [hGameMode], a
;=@t1
	jr .return

.linkStart:
;=@ec1
	ldh a, [hSyncFlags]
	set 0, a
	ldh [hSyncFlags], a
	ld a, $55
	ldh [hSerialOut], a
;=@ec2
	and $00
	ld [wCheatFlags], a
	set 0, a
	ldh [hLinkFlags], a
;=@ec3
	and $00
	ldh [rIF], a
	ld a, $0d
	ldh [hIEMask], a
	ldh [rIE], a
	jr .done

.onePlayer:
;=@op
	ld a, $4e
	ldh [hSerialOut], a
	ld d, $08
	call Delay
	call CancelLink

.done:
;> DrawModeCursor()
	call DrawModeCursor
;> hLinkFlags |= 0x04                   # the menu is done
	ldh a, [hLinkFlags]
	set 2, a
	ldh [hLinkFlags], a

.return:
;> return
	ret


.answering:
;=@a1
	ld a, $ec
	ldh [hSerialOut], a
;=@a2
	call DrawModeCursor

.follow:
;=@a4
	ldh a, [hSerialIn]
	cp $4e
	jr z, .otherAlone
;=@a6
	cp $a4
	jr z, .otherStarts
;=@a12
	cp $ae
	jr z, .giveUp
	ldh a, [hTimerHi]
	sub $20
	jp nc, .giveUp
;=@a3
	jr .follow

.otherAlone:
;=@a5
	call CancelLink
	jp .redraw


.otherStarts:
;=@a7
	ldh a, [hLinkFlags]
	set 0, a
	ldh [hLinkFlags], a
;=@a8
	call DrawModeCursor
;=@a9
	and $00
	ldh [rIF], a
;=@a10
	ld a, $0d
	ldh [hIEMask], a
	ldh [rIE], a
;=@a11
	jp .done


;@ def DrawModeCursor()
;@ path: title/menu
;@ Puts the cursor of the game-mode menu (sprite 17, a little invader) in front of "1 PLAYER" or,
;@ in a link game, "2 PLAYER". The Game Boy that answered the other's link request (hSyncFlags
;@ bit 3) shows a different invader. The tail stores the tile; DrawStockCursor ends here too.
;@ writes: wShadowOam
;@ reads: hLinkFlags, hSyncFlags
;@ sig: 39911922
DrawModeCursor::
;> if not hLinkFlags & 0x01:            # one player
	ldh a, [hSyncFlags]
	ld b, a
	ldh a, [hLinkFlags]
	bit 0, a
	jr nz, .twoPlayers
;>     wShadowOam[0x44] = 0x58           # Y of "1 PLAYER"
	ld a, $58
	ld [wShadowOam + $44], a
;>@t1     tile = 0xE1 if hSyncFlags & 0x08 else 0xD1
	bit 3, b
	jr nz, .answered1
;=@t1
	ld a, $d1
	jr SetCursorTile

.answered1:
;=@t1
	ld a, $e1
	jp SetCursorTile


.twoPlayers:
;> else:
;>     wShadowOam[0x44] = 0x70           # Y of "2 PLAYER"
	ld a, $70
	ld [wShadowOam + $44], a
;>@t2     tile = 0xC9 if hSyncFlags & 0x08 else 0xC8
	bit 3, b
	jr nz, .answered2
;=@t2
	ld a, $c8
	jr SetCursorTile

.answered2:
;=@t2
	ld a, $c9

SetCursorTile:
;> wShadowOam[0x46] = tile
	ld [wShadowOam + $46], a
	ret


;@ def CancelLink()
;@ path: link/menu
;@ Gives up on a link game: one player again, the serial port stopped, the serial interrupt
;@ switched off (hIEMask = VBlank, LCD STAT and timer), and the menu cursor back on "1 PLAYER".
;@ writes: hIEMask, hLinkFlags, hSyncFlags
;@ sig: e5d7e56b
CancelLink::
;> hLinkFlags = 0
;> rSC = 0
	and $00
	ldh [hLinkFlags], a
	ldh [rSC], a
;> hSyncFlags = 0
;> rIF = 0
	ldh [hSyncFlags], a
	and $00
	ldh [rIF], a
;> hIEMask = 0x07
;> rIE = 0x07
	ld a, $07
	ldh [hIEMask], a
	ldh [rIE], a
;> DrawModeCursor()
	call DrawModeCursor
	ret


;@ def SelectWeaponStock()
;@ path: link/menu
;@ The WEAPON STOCK menu of a link game: how many cannons each player gets (1, 3 or 5). Both Game
;@ Boys wait for each other ($DC "I am in this menu"); then the one that asked for the link game
;@ chooses with Select ($D1/$D3/$D5 = 1, 3, 5 cannons) and starts with Start ($DE), while the other
;@ one follows and answers each choice ($1D/$3D/$5D). $AE or about 30 seconds of silence give up.
;@ Also sets hRound to 1.
;@ writes: hLinkFlags, hRound, hSerialOut, hSyncFlags, hTimerHi, hTimerLo, hWeaponStock, wShadowOam
;@ reads: hGameMode, hJoyPressed, hLinkFlags, hSerialIn, hSyncFlags, hTimerHi, hWeaponStock
;@ test: skip talks to the other Game Boy and waits for buttons
;@ sig: 9c99582f
SelectWeaponStock::
;> if hGameMode != 0x55 or not hLinkFlags & 0x01:
;>     return
	ldh a, [hGameMode]
	cp $55
	jp nz, ApplyWeaponStock.done

	ldh a, [hLinkFlags]
	bit 0, a
	jp z, ApplyWeaponStock.done
;> hTimerHi = 0
;> hTimerLo = 0
	and $00
	ldh [hTimerHi], a
	ldh [hTimerLo], a
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> hSerialOut = 0xDC                    # "I am in the stock menu"
	ld a, $dc
	ldh [hSerialOut], a
;> hWeaponStock = 1
;> hRound = 1
	ld a, $01
	ldh [hWeaponStock], a
	ld a, $01
	ldh [hRound], a
;> LcdOffClear()
;> DrawTilemapList(StockMenuMap)
	call LcdOffClear
	ld de, StockMenuMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> wShadowOam[0x47] = 0
;> wShadowOam[0x45] = 0x20              # X of the cursor
	and $00
	ld [wShadowOam + $47], a
	ld a, $20
	ld [wShadowOam + $45], a
;>@dc while hSerialIn != 0xDC:          # wait for the other Game Boy
.waitOther:
	ldh a, [hSerialIn]
	cp $dc
	jr z, .bothHere
;>     if hTimerHi >= 0x20:
;>         return AbortLinkMenu()
	ldh a, [hTimerHi]
	sub $20
	jp nc, AbortLinkMenu
;=@dc
	jr .waitOther

.bothHere:
;>@loop while True:
;>     if hSyncFlags & 0x08:            # this one answered the link request: it follows
	ldh a, [hSyncFlags]
	bit 3, a
	jp nz, .follow
;>@f1         if hTimerHi >= 0x20: return AbortLinkMenu()
;>@f2         DrawStockCursor()
;>@f3         sel = hSerialIn
;>@f4         if sel == 0xD1: hSerialOut = 0x1D; hWeaponStock = 1
;>@f5         elif sel == 0xD3: hSerialOut = 0x3D; hWeaponStock = 3
;>@f6         elif sel == 0xD5: hSerialOut = 0x5D; hWeaponStock = 5
;>@f7         elif sel == 0xDE: return ApplyWeaponStock()    # the other one pressed Start
;>@f8         elif sel == 0xAE: return AbortLinkMenu()
;>@f9         else: continue
;>     else:                            # this one chooses
;>         DrawStockCursor()
.choose:
	call DrawStockCursor
;>@keys         while True:
;>             if hTimerHi >= 0x20:
;>                 return AbortLinkMenu()
.keys:
	ldh a, [hTimerHi]
	sub $20
	jp nc, AbortLinkMenu
;>             ReadJoypad()
	call ReadJoypad
;>             Delay(0x10)
	ld d, $10
	call Delay
;>             if hJoyPressed & 0x04:   # Select: the next choice
;>                 break
	ldh a, [hJoyPressed]
	bit 2, a
	jr nz, .next
;>             if hJoyPressed & 0x08:   # Start: tell the other one and begin
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, .begin
;>@s1                 hSerialOut = 0xDE
;>@s2                 hSyncFlags |= 0x80
;>@s3                 while hSyncFlags & 0x80: wait_vblank_flag()
;>@s4                 return ApplyWeaponStock()
;>             if hSerialIn == 0xAE:
;>                 return AbortLinkMenu()
	ldh a, [hSerialIn]
	cp $ae
	jp z, AbortLinkMenu
;=@keys
	jr .keys

.begin:
;=@s1
	ld a, $de
	ldh [hSerialOut], a
;=@s2
	ldh a, [hSyncFlags]
	set 7, a
	ldh [hSyncFlags], a
.waitStart:
;=@s3
	ldh a, [hSyncFlags]
	bit 7, a
	jr nz, .waitStart
;=@s4
	jp ApplyWeaponStock


.next:
;>@w         while hWeaponStock not in (1, 3, 5):
;>             hWeaponStock = 1
	ldh a, [hWeaponStock]
	cp $01
	jr z, .oneToThree
;=@w
	cp $03
	jr z, .threeToFive
	cp $05
	jr z, .fiveToOne
;=@w
	ld a, $01
	ldh [hWeaponStock], a
	jr .next
;>@k         hSerialOut = 0xD3 if hWeaponStock == 1 else 0xD5 if hWeaponStock == 3 else 0xD1
;>@k2         hWeaponStock = 3 if hWeaponStock == 1 else 5 if hWeaponStock == 3 else 1

.fiveToOne:
;=@k
	ld a, $d1
	jr .setOne

.ack1:
;=@f4
	ld a, $1d

.setOne:
;=@k
	ldh [hSerialOut], a
;=@k2
	ld a, $01
	ldh [hWeaponStock], a
	jr .send

.oneToThree:
;=@k
	ld a, $d3
	jr .setThree

.ack3:
;=@f5
	ld a, $3d

.setThree:
;=@k
	ldh [hSerialOut], a
;=@k2
	ld a, $03
	ldh [hWeaponStock], a
	jr .send

.threeToFive:
;=@k
	ld a, $d5
	jr .setFive

.ack5:
;=@f6
	ld a, $5d

.setFive:
;=@k
	ldh [hSerialOut], a
;=@k2
	ld a, $05
	ldh [hWeaponStock], a

.send:
;>     hSyncFlags |= 0xC0               # bit 7: VBlank sends it, bit 6: wait for the answer
	ldh a, [hSyncFlags]
	set 7, a
	set 6, a
	ldh [hSyncFlags], a
;>     if hSyncFlags & 0x08:
	ldh a, [hSyncFlags]
	bit 3, a
	jr nz, .waitAnswer
;>@x1         while hSyncFlags & 0x40: wait_vblank_flag()     # the other one's next byte
;>     else:
;>         while hSyncFlags & 0x80:     # until VBlank has sent it
;>             wait_vblank_flag()
.waitSent:
	ldh a, [hSyncFlags]
	bit 7, a
	jr nz, .waitSent
;=@loop
	jp .choose


.waitAnswer:
;=@x1
	ldh a, [hSyncFlags]
	bit 6, a
	jr nz, .waitAnswer

.follow:
;=@f1
	ldh a, [hTimerHi]
	sub $20
	jp nc, AbortLinkMenu
;=@f2
	call DrawStockCursor
;=@f3
	ldh a, [hSerialIn]
;=@f4
	cp $d1
	jr z, .ack1
;=@f5
	cp $d3
	jr z, .ack3
;=@f6
	cp $d5
	jr z, .ack5
;=@f7
	cp $de
	jr z, ApplyWeaponStock
;=@f8
	cp $ae
	jr z, AbortLinkMenu
;=@f9
	jr .follow

;@ def DrawStockCursor()
;@ path: link/menu
;@ Puts the cursor of the weapon-stock menu in front of "1 WEAPON", "3 WEAPONS" or "5 WEAPONS"
;@ (hWeaponStock; any other value is reset to 1). Each line has its own invader (another one on the
;@ Game Boy that answered the link request). Ends in DrawModeCursor's tail.
;@ writes: hWeaponStock, wShadowOam
;@ reads: hSyncFlags, hWeaponStock
;@ sig: bc798f16
DrawStockCursor::
;>@w while hWeaponStock not in (1, 3, 5):
;>     hWeaponStock = 1
	ldh a, [hSyncFlags]
	ld b, a
	ldh a, [hWeaponStock]
	cp $01
	jr z, .one
;=@w
	cp $03
	jr z, .three
	cp $05
	jr z, .five
;=@w
	ld a, $01
	ldh [hWeaponStock], a
	jr DrawStockCursor

.one:
;> if hWeaponStock == 1:
;>     wShadowOam[0x44] = 0x48
	ld a, $48
	ld [wShadowOam + $44], a
;>@t1     tile = 0xC8 if hSyncFlags & 0x08 else 0xD1
	bit 3, b
	jr nz, .one2
;=@t1
	ld a, $d1
	jp SetCursorTile


.one2:
;=@t1
	ld a, $c8
	jp SetCursorTile


.three:
;> elif hWeaponStock == 3:
;>     wShadowOam[0x44] = 0x58
	ld a, $58
	ld [wShadowOam + $44], a
;>@t3     tile = 0xC9 if hSyncFlags & 0x08 else 0xE1
	bit 3, b
	jr nz, .three2
;=@t3
	ld a, $e1
	jp SetCursorTile


.three2:
;=@t3
	ld a, $c9
	jp SetCursorTile


.five:
;> else:
;>     wShadowOam[0x44] = 0x68
	ld a, $68
	ld [wShadowOam + $44], a
;>@t5     tile = 0xCA if hSyncFlags & 0x08 else 0xF1
	bit 3, b
	jr nz, .five2
;=@t5
	ld a, $f1
	jp SetCursorTile


.five2:
;=@t5
	ld a, $ca
	jp SetCursorTile
;> wShadowOam[0x46] = tile              # (SetCursorTile)

; Unreachable leftover, a copy of SetCursorTile: ld [wShadowOam + $46], a / ret
	db $ea, $46, $c0, $c9

;@ def AbortLinkMenu()
;@ path: link/menu
;@ Gives up the link menus: sends $AE ("I give up"), waits a moment and sets hGameMode to $44.
;@ writes: hGameMode, hSerialOut
;@ sig: 4efe8849
AbortLinkMenu::
;> hSerialOut = 0xAE
	ld a, $ae
	ldh [hSerialOut], a
;> Delay(8)
	ld d, $08
	call Delay
;> hGameMode = 0x44
	ld a, $44
	ldh [hGameMode], a
;> return
	jr ApplyWeaponStock.done

;@ def ApplyWeaponStock()
;@ path: link/menu
;@ The stock is chosen: both players get hWeaponStock - 1 cannons in reserve (the one on screen is
;@ the first), and $DE is sent once more.
;@ writes: hLives, hOpponentLives, hSerialOut
;@ reads: hWeaponStock
;@ sig: 359aeac1
ApplyWeaponStock::
;> hLives = hWeaponStock - 1
	ldh a, [hWeaponStock]
	dec a
	ldh [hLives], a
;> hOpponentLives = hWeaponStock - 1
	ldh [hOpponentLives], a
;> hSerialOut = 0xDE
	ld a, $de
	ldh [hSerialOut], a

.done:
;> return
	ret


;@ def ShowCoffeeBreak1()
;@ path: game/coffeebreak
;@ The first coffee break, after round 10: a picture and "COFFEE BREAK! LET'S START THE NEXT GAME!",
;@ until Start is pressed; then the next round follows (hGameMode = $CC).
;@ writes: hGameMode, hLinkFlags
;@ reads: hLinkFlags
;@ sig: dfbd6131
ShowCoffeeBreak1::
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> LcdOffClear()
	call LcdOffClear
;> LoadBgTiles(CoffeeBreak1Tiles)
	ld hl, CoffeeBreak1Tiles
	call LoadBgTiles
;> DrawTilemapList(CoffeeBreak1Map)
	ld de, CoffeeBreak1Map
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> WaitForStart()
	call WaitForStart
;> hGameMode = 0xCC                     # go on with the next round
	ld a, $cc
	ldh [hGameMode], a
	ret


;@ def ShowCoffeeBreak2()
;@ path: game/coffeebreak
;@ The second coffee break, after round 20: a picture and "COFFEE BREAK! LET'S START THE NEXT GAME!",
;@ until Start is pressed; then the next round follows (hGameMode = $CC).
;@ writes: hGameMode, hLinkFlags
;@ reads: hLinkFlags
;@ sig: 324b8e44
ShowCoffeeBreak2::
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> LcdOffClear()
	call LcdOffClear
;> LoadBgTiles(CoffeeBreak2Tiles)
	ld hl, CoffeeBreak2Tiles
	call LoadBgTiles
;> DrawTilemapList(CoffeeBreak2Map)
	ld de, CoffeeBreak2Map
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> WaitForStart()
	call WaitForStart
;> hGameMode = 0xCC                     # go on with the next round
	ld a, $cc
	ldh [hGameMode], a
	ret


;@ def ShowEnding()
;@ path: game/ending
;@ The ending after round 30: the full-screen picture (EndingTiles, EndingMap) with "THE END" as 8
;@ sprites (tiles $40-$47) across the top, about 2.5 seconds of pause, then wait for Start; the game
;@ ends (hGameMode = $44).
;@ writes: hGameMode, hLinkFlags
;@ reads: hLinkFlags
;@ test: skip waits for a button
;@ sig: 42c9175c
ShowEnding::
;> hLinkFlags &= ~0x04
	ldh a, [hLinkFlags]
	res 2, a
	ldh [hLinkFlags], a
;> LcdOffClear()
	call LcdOffClear
;> LoadBgTiles(EndingTiles)
	ld hl, EndingTiles
	call LoadBgTiles
;> DrawTilemapList(EndingMap)
	ld de, EndingMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> rBGP = 0xE4
;> rOBP0 = 0xE4
	ld a, $e4
	ldh [rBGP], a
	ldh [rOBP0], a
;> rOBP1 = 0xE4
	ldh [rOBP1], a
;>@for for i in range(8):                # "THE END": sprites 0-7 at Y 40, X 56, 64, ...
	ld hl, wShadowOam
	ld c, $40
	ld b, $08
	ld d, $28
	ld e, $38
.sprite:
;>     wShadowOam[4 * i] = 0x28
	ld a, d
	ld [hli], a
;>     wShadowOam[4 * i + 1] = 0x38 + 8 * i
	ld a, e
	ld [hli], a
;>     wShadowOam[4 * i + 2] = 0x40 + i
	ld a, c
	ld [hli], a
;>     wShadowOam[4 * i + 3] = 0
	xor a
	ld [hli], a
;=@for
	inc c
	ld a, e
	add $08
	ld e, a
	dec b
	jr nz, .sprite
;> rOBP0 = 0xE4
	ld a, $e4
	ldh [rOBP0], a
;> Delay(0xC0)
	ld d, $c0
	call Delay
;> Delay(0xC0)
	ld d, $c0
	call Delay
;> WaitForStart()
	call WaitForStart
;> hGameMode = 0x44                     # the game is over
	ld a, $44
	ldh [hGameMode], a
	ret


;@ def WaitForStart()
;@ path: game/screens
;@ Waits until Start is pressed, checking the buttons about every 6 frames (a delay, then halt
;@ until the next interrupt). Used by the coffee breaks.
;@ reads: hJoyPressed
;@ test: skip waits for a button
;@ sig: d1c74639
WaitForStart::
;> while True:
;>     ReadJoypad()
	call ReadJoypad
;>     if hJoyPressed & 0x08:           # Start
;>         return
	ldh a, [hJoyPressed]
	bit 3, a
	jr nz, .done
;>     Delay(0x10)
	ld d, $10
	call Delay
;>     wait_vblank_flag()               # halt until the next interrupt
	halt
	jr WaitForStart

.done:
	ret


;@ def ShowLinkWin()
;@ path: link/result
;@ The link-game result of the winner: the ground of LinkResultTiles, then 19 invaders
;@ (LinkWinFormation) rise from below the screen, flapping, into a V. When the first one reaches
;@ Y 32 "YOU WON !" is typed and sound $18 plays. Then it waits for Start, the other Game Boy ($DD)
;@ or a timeout, and synchronises with LinkSync.
;@ writes: hSerialOut, hSfxRequest2, hTimerHi, hTimerLo, wSceneFlags
;@ reads: hJoyPressed, hSerialIn, hTimerHi, wSceneFlags
;@ test: skip waits for a button or the link
;@ sig: dad83fb2
ShowLinkWin::
;> wSceneFlags = 0
;> hTimerHi = 0
	xor a
	ld [wSceneFlags], a
	ldh [hTimerHi], a
;> hTimerLo = 0
	ldh [hTimerLo], a
;> LcdOffClear()
	call LcdOffClear
;> copy(0x9000, LinkResultTiles, 0x500)  # BG tiles $00-$4F
	ld hl, LinkResultTiles
	ld de, $9000
	ld bc, $0500
	call CopyBytes
;> DrawTilemapList(LinkResultMap)
	ld de, LinkResultMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> hSerialOut = 0xD0
	ld a, $d0
	ldh [hSerialOut], a
;>@for for i in range(19):               # each invader is two sprites side by side
	ld de, wShadowOam
	ld hl, LinkWinFormation
	ld b, $13
.place:
;>     wShadowOam[8 * i] = mem[LinkWinFormation + 3 * i]                # Y
;>@s1     wShadowOam[8 * i + 4] = wShadowOam[8 * i]
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s1
	inc de
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 1] = mem[LinkWinFormation + 3 * i + 1]        # X
;>@s3     wShadowOam[8 * i + 5] = wShadowOam[8 * i + 1] + 8
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s3
	inc de
	add $08
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 2] = mem[LinkWinFormation + 3 * i + 2]        # tile
;>@s5     wShadowOam[8 * i + 6] = wShadowOam[8 * i + 2] + 1
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s5
	inc de
	inc a
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 3] = 0x80        # behind the background
;>@s7     wShadowOam[8 * i + 7] = 0x81
	ld a, $80
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s7
	inc de
	inc a
	ld [de], a
	pop de
	inc de
;=@for
	inc de
	inc de
	inc de
	inc de
	dec b
	jr nz, .place
;>@loop while True:
;>     if wSceneFlags & 0x01:           # flip the animation frame
.step:
	ld a, [wSceneFlags]
	bit 0, a
	jr z, .frameB
;>@flag         wSceneFlags &= ~0x01
;>         step = -2
	res 0, a
	ld c, $fe
	jr .gotFrame

.frameB:
;>     else:
;>         wSceneFlags |= 0x01
;>         step = 2
	set 0, a
	ld c, $02

.gotFrame:
;=@flag
	ld [wSceneFlags], a
;>@move     for i in range(19):
	ld hl, wShadowOam
	ld b, $13
.move:
;>         for part in (0, 4):          # both sprites of invader i
;>@p2             if not wSceneFlags & 0x02:   # still rising: 2 pixels up
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .left
;>@p3                 wShadowOam[8 * i + part] -= 2
	dec [hl]
	dec [hl]

.left:
;>@p4             wShadowOam[8 * i + part + 2] = u8(wShadowOam[8 * i + part + 2] + step)   # the other frame
	inc hl
	inc hl
	ld a, [hl]
	add c
	ld [hli], a
	inc hl
;=@p2
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .right
;=@p3
	dec [hl]
	dec [hl]

.right:
;=@p4
	inc hl
	inc hl
	ld a, [hl]
	add c
	ld [hli], a
	inc hl
;=@move
	dec b
	jr nz, .move
;>@arrive     if not wSceneFlags & 0x02 and wShadowOam[0] == 0x20:   # the first one has arrived
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .wait
;=@arrive
	ld hl, wShadowOam
	ld a, [hl]
	cp $20
	jr nz, .wait
;>         wSceneFlags |= 0x02
	ld a, [wSceneFlags]
	set 1, a
	ld [wSceneFlags], a
;>         TypeText(TextYouWon, 0x99A6, 9, 0xFF)      # typed out
	ld de, $99a6
	ld hl, TextYouWon
	ld b, $09
	ld c, $ff
	call TypeText
;>         Delay(0x80)
	ld d, $80
	call Delay
;>         hSfxRequest2 = 0x18
	ld a, $18
	ldh [hSfxRequest2], a

.wait:
;>@wait     for _ in range(20):
	ld b, $14
.waitLoop:
;>         if hTimerHi >= 0x38:         # about a minute
;>@e1             return LinkSync()
	ldh a, [hTimerHi]
	sub $38
	jp nc, .done
;>         ReadJoypad()
	call ReadJoypad
;>         if hJoyPressed & 0x08:
;>             return LinkSync()
	ldh a, [hJoyPressed]
	bit 3, a
	jp nz, .done
;>         if hSerialIn == 0xDD:        # the other Game Boy is ready
;>             return LinkSync()
	ldh a, [hSerialIn]
	cp $dd
	jp z, .done
;>         Delay(1)
	ld d, $01
	call Delay
;=@wait
	dec b
	jr nz, .waitLoop
;=@loop
	jp .step


.done:
;=@e1
	call LinkSync
	ret


;@ def ShowLinkLoss()
;@ path: link/result
;@ The link-game result of the loser, in the same way as ShowLinkWin: 17 invaders (LinkLossFormation)
;@ rise into an X, "YOU LOST!" is typed when the first one reaches Y 40, and sound $19 plays.
;@ writes: hSerialOut, hSfxRequest2, hTimerHi, hTimerLo, wSceneFlags
;@ reads: hJoyPressed, hSerialIn, hTimerHi, wSceneFlags
;@ test: skip waits for a button or the link
;@ sig: 195f68c7
ShowLinkLoss::
;> wSceneFlags = 0
;> hTimerHi = 0
	xor a
	ld [wSceneFlags], a
	ldh [hTimerHi], a
;> hTimerLo = 0
	ldh [hTimerLo], a
;> LcdOffClear()
	call LcdOffClear
;> copy(0x9000, LinkResultTiles, 0x500)  # BG tiles $00-$4F
	ld hl, LinkResultTiles
	ld de, $9000
	ld bc, $0500
	call CopyBytes
;> DrawTilemapList(LinkResultMap)
	ld de, LinkResultMap
	call DrawTilemapList
;> LcdOn()
	call LcdOn
;> hSerialOut = 0xD0
	ld a, $d0
	ldh [hSerialOut], a
;>@for for i in range(17):               # each invader is two sprites side by side
	ld de, wShadowOam
	ld hl, LinkLossFormation
	ld b, $11
.place:
;>     wShadowOam[8 * i] = mem[LinkLossFormation + 3 * i]                # Y
;>@s1     wShadowOam[8 * i + 4] = wShadowOam[8 * i]
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s1
	inc de
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 1] = mem[LinkLossFormation + 3 * i + 1]        # X
;>@s3     wShadowOam[8 * i + 5] = wShadowOam[8 * i + 1] + 8
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s3
	inc de
	add $08
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 2] = mem[LinkLossFormation + 3 * i + 2]        # tile
;>@s5     wShadowOam[8 * i + 6] = wShadowOam[8 * i + 2] + 1
	ld a, [hli]
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s5
	inc de
	inc a
	ld [de], a
	pop de
	inc de
;>     wShadowOam[8 * i + 3] = 0x80        # behind the background
;>@s7     wShadowOam[8 * i + 7] = 0x81
	ld a, $80
	ld [de], a
	push de
	inc de
	inc de
	inc de
;=@s7
	inc de
	inc a
	ld [de], a
	pop de
	inc de
;=@for
	inc de
	inc de
	inc de
	inc de
	dec b
	jr nz, .place
;>@loop while True:
;>     if wSceneFlags & 0x01:           # flip the animation frame
.step:
	ld a, [wSceneFlags]
	bit 0, a
	jr z, .frameB
;>@flag         wSceneFlags &= ~0x01
;>         step = -2
	res 0, a
	ld c, $fe
	jr .gotFrame

.frameB:
;>     else:
;>         wSceneFlags |= 0x01
;>         step = 2
	set 0, a
	ld c, $02

.gotFrame:
;=@flag
	ld [wSceneFlags], a
;>@move     for i in range(17):
	ld hl, wShadowOam
	ld b, $11
.move:
;>         for part in (0, 4):          # both sprites of invader i
;>@p2             if not wSceneFlags & 0x02:   # still rising: 2 pixels up
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .left
;>@p3                 wShadowOam[8 * i + part] -= 2
	dec [hl]
	dec [hl]

.left:
;>@p4             wShadowOam[8 * i + part + 2] = u8(wShadowOam[8 * i + part + 2] + step)   # the other frame
	inc hl
	inc hl
	ld a, [hl]
	add c
	ld [hli], a
	inc hl
;=@p2
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .right
;=@p3
	dec [hl]
	dec [hl]

.right:
;=@p4
	inc hl
	inc hl
	ld a, [hl]
	add c
	ld [hli], a
	inc hl
;=@move
	dec b
	jr nz, .move
;>@arrive     if not wSceneFlags & 0x02 and wShadowOam[0] == 0x28:   # the first one has arrived
	ld a, [wSceneFlags]
	bit 1, a
	jr nz, .wait
;=@arrive
	ld hl, wShadowOam
	ld a, [hl]
	cp $28
	jr nz, .wait
;>         wSceneFlags |= 0x02
	ld a, [wSceneFlags]
	set 1, a
	ld [wSceneFlags], a
;>         TypeText(TextYouLost, 0x99A5, 9, 0xFF)      # typed out
	ld de, $99a5
	ld hl, TextYouLost
	ld b, $09
	ld c, $ff
	call TypeText
;>         Delay(0x80)
	ld d, $80
	call Delay
;>         hSfxRequest2 = 0x19
	ld a, $19
	ldh [hSfxRequest2], a

.wait:
;>@wait     for _ in range(20):
	ld b, $14
.waitLoop:
;>         if hTimerHi >= 0x38:         # about a minute
;>@e1             return LinkSync()
	ldh a, [hTimerHi]
	sub $38
	jp nc, .done
;>         ReadJoypad()
	call ReadJoypad
;>         if hJoyPressed & 0x08:
;>             return LinkSync()
	ldh a, [hJoyPressed]
	bit 3, a
	jp nz, .done
;>         if hSerialIn == 0xDD:        # the other Game Boy is ready
;>             return LinkSync()
	ldh a, [hSerialIn]
	cp $dd
	jp z, .done
;>         Delay(1)
	ld d, $01
	call Delay
;=@wait
	dec b
	jr nz, .waitLoop
;=@loop
	jp .step


.done:
;=@e1
	call LinkSync
	ret


;@ def LoadBgTiles(tiles: hl)
;@ path: gfx/tiles
;@ Copies $800 bytes of tile graphics (128 tiles) from `tiles` to $9000, the BG tiles $00-$7F
;@ (the game uses the $8800 tile addressing). Used for the title, coffee-break and ending screens.
;@ test: tiles = rand(0x4000, 0x7000)
;@ sig: e79606f1
LoadBgTiles::
;> copy(0x9000, tiles, 0x800)
	ld de, $9000
	ld bc, $0800
	call CopyBytes
	ret


;@ def AcceptLinkRequest()
;@ path: link/menu
;@ The other Game Boy asked for a link game ($E4 received): answer $D4, switch to a link game and
;@ remember that this Game Boy is the one that answered (hSyncFlags = bit 3 only).
;@ writes: hLinkFlags, hSerialOut, hSyncFlags
;@ reads: hLinkFlags
;@ sig: 10d53096
AcceptLinkRequest::
;> hSerialOut = 0xD4
	ld a, $d4
	ldh [hSerialOut], a
;> hLinkFlags |= 0x01
	ldh a, [hLinkFlags]
	set 0, a
	ldh [hLinkFlags], a
;> hSyncFlags = 0x08
	and $00
	set 3, a
	ldh [hSyncFlags], a
	ret


;@ def TypeText(text: hl, dest: de, count: b, slow: c)
;@ path: text/draw
;@ Writes `count` tiles from `text` to the BG map at `dest`, one after the other with the screen on:
;@ each goes through the VBlank hook (VBlankWriteTile). With `slow` != 0 it types like a typewriter:
;@ a pause after each letter, and a press of Start (wSceneFlags bit 2) or a link request from the
;@ other Game Boy (wSceneFlags bit 3) is noted for the caller.
;@ writes: hMainHook, hVramAddrHi, hVramAddrLo, hVramData0, wSceneFlags
;@ reads: hJoyPressed, hMainHook, hSerialIn, wSceneFlags
;@ test: skip waits for the VBlank hook
;@ sig: 12cb2695
TypeText::
;>@loop for i in range(count):
;>     hVramData0 = mem[text + i]
	ld a, [hli]
	ldh [hVramData0], a
;>     hVramAddrHi = hi(dest + i)
;>     hVramAddrLo = lo(dest + i)
	ld a, d
	ldh [hVramAddrHi], a
	ld a, e
	ldh [hVramAddrLo], a
;>     hMainHook = 0xBE                  # VBlankWriteTile
	ld a, $be
	ldh [hMainHook], a
;>     while hMainHook != 0:
;>         wait_vblank_flag()
.wait:
	ldh a, [hMainHook]
	and a
	jr nz, .wait
;>     if slow != 0:
	ld a, c
	and a
	jr z, .next
;>         Delay(0x10)
	push hl
	push bc
	push de
	push af
	ld d, $10
	call Delay
;>         ReadJoypad()
	call ReadJoypad
	pop af
	pop de
	pop bc
	pop hl
;>         if hJoyPressed & 0x08:       # Start
;>@start             wSceneFlags |= 0x04
	ldh a, [hJoyPressed]
	bit 3, a
	jr z, .noStart
;=@start
	ld a, [wSceneFlags]
	set 2, a
	ld [wSceneFlags], a

.noStart:
;>         if hSerialIn == 0xE4:        # the other Game Boy wants a link game
;>@link             wSceneFlags |= 0x08
	ldh a, [hSerialIn]
	cp $e4
	jr nz, .next
;=@link
	ld a, [wSceneFlags]
	set 3, a
	ld [wSceneFlags], a

.next:
;=@loop
	inc de
	dec b
	jr nz, TypeText
	ret


;@ def SerialHandler()
;@ path: link/serial
;@ Serial interrupt: a byte arrived from the other Game Boy (hSerialIn). On the Game Boy without
;@ the clock it loads hSerialOut for the next exchange and gets ready at once. Clears hSyncFlags
;@ bit 6 (transfer done). Two kinds of bytes are handled right here: $B0-$B4 carry the opponent's
;@ cannons in reserve, $F5 says the opponent's cannon was hit (hUfoFlags bit 0).
;@ writes: hOpponentLives, hSerialIn, hSyncFlags
;@ reads: hSerialIn, hSerialOut, hSyncFlags
;@ test: skip interrupt handler (ends in reti)
;@ sig: 4085fdc7
SerialHandler::
;> hSerialIn = rSB
	push af
	push hl
	ldh a, [rSB]
	ldh a, [rSB]
	ldh [hSerialIn], a
;> if not rSC & 0x01:                   # the other side has the clock
	ldh a, [rSC]
	bit 0, a
	jr nz, .flags
;>     rSB = hSerialOut
	ldh a, [hSerialOut]
	ldh [rSB], a
;>     rSC |= 0x80                       # ready for the next byte
	ldh a, [rSC]
	set 7, a
	ldh [rSC], a

.flags:
;> hSyncFlags &= ~0x40
	ldh a, [hSyncFlags]
	res 6, a
	ldh [hSyncFlags], a
;>@b0 if hSerialIn & 0xF0 == 0xB0 and hSerialIn & 0x0F < 5:
	ldh a, [hSerialIn]
	and $f0
	cp $b0
	jr nz, SerialCheckUfoCode
;=@b0
	ldh a, [hSerialIn]
	and $0f
	ld h, a
	sub $05
	jr nc, SerialCheckUfoCode
;>     hOpponentLives = hSerialIn & 0x0F
	ld a, h
	ldh [hOpponentLives], a
	jr SerialCheckUfoCode.done

SerialCheckUfoCode:
;> elif hSerialIn == 0xF5:
	ldh a, [hSerialIn]
	cp $f5
	jr nz, .done
;>     hUfoFlags |= 0x01
	ld hl, hUfoFlags
	set 0, [hl]

.done:
;> return
	pop hl
	pop af
	reti


;@ def UnusedRestartSerial()
;@ path: unused
;@ Nothing calls this. It would restart the serial port (internal clock: rSC = $01; external: rSC =
;@ $80) and then jump into SerialHandler's tail, which pops two registers this routine never pushed.
;@ test: skip jumps into the middle of SerialHandler
;@ sig: 9b0cea26
UnusedRestartSerial::
;> if rSC & 0x01:
	ldh a, [rSC]
	bit 0, a
	jr z, .external
;>     rSC = 0x01
	and $00
	set 0, a
	ldh [rSC], a
;>     goto(SerialCheckUfoCode)
	jr SerialCheckUfoCode

.external:
;> else:
;>     rSC = 0x80
	and $00
	set 7, a
	ldh [rSC], a
;>     goto(SerialCheckUfoCode)
	jr SerialCheckUfoCode

;@ def ReadJoypad()
;@ path: system/joypad
;@ Reads the buttons: hJoyHeld = held now, hJoyPressed = newly pressed (d-pad in the high nibble:
;@ Right, Left, Up, Down = bits 4-7; A, B, Select, Start = bits 0-3). Outside link games every new
;@ press is also pushed onto wPressHistory (newest first), where the secret codes are looked for.
;@ writes: hJoyHeld, hJoyPressed, wPressCount
;@ reads: hJoyHeld, hJoyPressed, hLinkFlags, wPressCount
;@ test: skip reads rP1
;@ sig: d7286906
ReadJoypad::
;>@buttons buttons = read_buttons()              # d-pad high nibble, buttons low nibble, 1 = pressed
	push af
	push bc
	ld a, $20
	ldh [rP1], a
	ldh a, [rP1]
	ldh a, [rP1]
;=@buttons
	cpl
	and $0f
	swap a
	ld b, a
	ld a, $10
	ldh [rP1], a
;=@buttons
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
	ldh a, [rP1]
;=@buttons
	cpl
	and $0f
	or b
	ld c, a
;> hJoyPressed = buttons & ~hJoyHeld
	ldh a, [hJoyHeld]
	xor c
	and c
	ldh [hJoyPressed], a
;> hJoyHeld = buttons
	ld a, c
	ldh [hJoyHeld], a
;> rP1 = 0x30                            # deselect both groups
	ld a, $30
	ldh [rP1], a
	pop bc
	pop af
;> if hLinkFlags & 0x01:                 # no secret codes in a link game
;>     return
	ldh a, [hLinkFlags]
	bit 0, a
	ret nz
;> if hJoyPressed != 0:
	ldh a, [hJoyPressed]
	and a
	jr z, .done
;>     wPressCount += 1
	ld c, a
	ld a, [wPressCount]
	inc a
	ld [wPressCount], a
;>@shift     for i in range(7, 0, -1):          # shift the history one place back
;>@shift2         wPressHistory[i] = wPressHistory[i - 1]
;=@shift
	ld hl, wPressHistory + 6
	ld a, [hli]
	ld [hld], a
	dec hl
;=@shift2
	ld a, [hli]
	ld [hld], a
	dec hl
	ld a, [hli]
	ld [hld], a
	dec hl
;=@shift2
	ld a, [hli]
	ld [hld], a
	dec hl
	ld a, [hli]
	ld [hld], a
	dec hl
;=@shift2
	ld a, [hli]
	ld [hld], a
	dec hl
	ld a, [hli]
	ld [hld], a
;>     wPressHistory[0] = hJoyPressed
	ld [hl], c
.done:
	ret


;@ def CopyOamDmaRoutine()
;@ path: gfx/oam
;@ Copies the 10-byte OamDmaRoutine to HRAM $FF80, where it runs every VBlank (`call $ff80`):
;@ during an OAM DMA the CPU can only read HRAM.
;@ sig: 2664bfd2
CopyOamDmaRoutine::
;>@c copy(0xFF80, OamDmaRoutine, 10)
	ld c, $80
	ld b, $0a
	ld hl, OamDmaRoutine
.loop:
	ld a, [hli]
	ldh [c], a
;=@c
	inc c
	dec b
	jr nz, .loop

	ret


;@ path: gfx/oam
;@ The OAM DMA routine, kept here as data and copied to HRAM $FF80 by CopyOamDmaRoutine:
;@     ld a, HIGH(wShadowOam)   ; $C0
;@     ldh [rDMA], a            ; start the copy of $C000-$C09F to OAM
;@     ld a, $28
;@ .wait: dec a / jr nz, .wait  ; 160 microseconds until the DMA is done
;@     ret
OamDmaRoutine::
	db $3e, $c0, $e0, $46, $3e, $28, $3d, $20, $fd, $c9

;@ def UnusedPixelToMapAddr()
;@ path: unused
;@ Nothing calls this. Turns a sprite position (hPixelY, hPixelX) into the address of the BG-map cell
;@ under it (hMapAddrHi/Lo): sprite coordinates are 16 (Y) and 8 (X) ahead of the screen.
;@ writes: hMapAddrHi, hMapAddrLo
;@ reads: hPixelX, hPixelY
;@ sig: 53e52e43
UnusedPixelToMapAddr::
;> row = u8(hPixelY - 16) >> 3
	ldh a, [hPixelY]
	sub $10
	srl a
	srl a
	srl a
;>@addr addr = 0x9800 + 32 * row
	ld de, $0000
	ld e, a
	ld hl, $9800
	ld b, $20
.addRow:
	add hl, de
;=@addr
	dec b
	jr nz, .addRow
;>@col addr += u8(hPixelX - 8) >> 3
	ldh a, [hPixelX]
	sub $08
	srl a
	srl a
	srl a
;=@col
	ld de, $0000
	ld e, a
	add hl, de
;> hMapAddrHi = hi(addr)
;> hMapAddrLo = lo(addr)
	ld a, h
	ldh [hMapAddrHi], a
	ld a, l
	ldh [hMapAddrLo], a
	ret


;@ def UnusedMapAddrToPixel()
;@ path: unused
;@ Nothing calls this. Meant as the way back from a BG-map address to a sprite position, but its Y
;@ comes out 24 pixels higher than UnusedPixelToMapAddr's input.
;@ writes: hPixelX, hPixelY
;@ reads: hMapAddrHi, hMapAddrLo
;@ sig: 587c07da
UnusedMapAddrToPixel::
;>@v v = u8(((hMapAddrHi << 8 | hMapAddrLo) >> 4) - 0x84) & 0xFE
	ldh a, [hMapAddrHi]
	ld d, a
	ldh a, [hMapAddrLo]
	ld e, a
	ld b, $04
.shift:
	rr d
;=@v
	rr e
	dec b
	jr nz, .shift
;=@v
	ld a, e
	sub $84
	and $fe
;> hPixelY = u8(((v << 2) | (v >> 6)) + 8)
	rlca
	rlca
	add $08
	ldh [hPixelY], a
;>@x hPixelX = ((hMapAddrLo & 0x1F) << 3) + 8
	ldh a, [hMapAddrLo]
	and $1f
	rla
	rla
	rla
;=@x
	add $08
	ldh [hPixelX], a
	ret


;@ def JumpTableDispatch(index: a)
;@ path: system/vectors
;@ The body of `rst $00`: the return address on the stack points at a table of 16-bit addresses
;@ right after the `rst` instruction. Jumps to entry `index` of that table (and never returns there).
;@ test: skip pops the return address and jumps through a table
;@ sig: a7c000c3
JumpTableDispatch::
;> table = pop_return_address()          # the table follows the rst $00
	add a
	pop hl
;> target = mem16[table + 2 * index]
	ld e, a
	ld d, $00
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
;> goto(target)
	push de
	pop hl
	jp hl


;@ def LcdOff()
;@ path: system/lcd
;@ Waits for line $91 (inside VBlank) and switches the LCD off, so VRAM can be written freely.
;@ rIE is saved in hSavedIE and put back unchanged (the `res 0` on the copy has no effect).
;@ The 9 bytes after it are a small fill routine nothing calls (see the comment there).
;@ writes: hSavedIE
;@ reads: hSavedIE
;@ test: skip waits for rLY
;@ sig: c38b6cd9
LcdOff::
;> hSavedIE = rIE
	ldh a, [rIE]
	ldh [hSavedIE], a
	res 0, a
;> wait_ly(0x91)                          # first line of VBlank + 1
.waitLy:
	ldh a, [rLY]
	cp $91
	jr nz, .waitLy
;> rLCDC &= 0x7F                         # bit 7 off: LCD off
	ldh a, [rLCDC]
	and $7f
	ldh [rLCDC], a
;> rIE = hSavedIE
	ldh a, [hSavedIE]
	ldh [rIE], a
	ret

; Unused leftover: a routine that clears bc bytes at hl. As code:
;     .loop: ld a, 0 / ld [hli], a / dec bc / ld a, c / or b / jr nz, .loop / ret
	db $3e, $00, $22, $0b, $79, $b0, $20, $f8, $c9

;@ def ClearBgMap()
;@ path: system/lcd
;@ Fills both BG maps ($9800-$9FFF, $800 bytes) with tile $A4, the blank (space) tile of the font.
;@ The LCD must be off.
;@ sig: b01c455a
ClearBgMap::
;>@for for addr in range(0x9800, 0xA000):
	ld hl, $9800
	ld bc, $0800
.loop:
;>     mem[addr] = 0xA4
	ld a, $a4
	ld [hli], a
;=@for
	dec bc
	ld a, b
	or c
	jr nz, .loop

	ret


;@ def CopyBytes(src: hl, dest: de, count: bc)
;@ path: system/memory
;@ Copies `count` bytes from `src` to `dest` (count 0 copies 65536 bytes).
;@ test: count = rand(1, 64); src = rand(0x4000, 0x7000); dest = rand(0xC100, 0xC800)
;@ sig: 994589e5
CopyBytes::
;>@cp copy(dest, src, count)
	ld a, [hli]
	ld [de], a
	inc de
;=@cp
	dec bc
	ld a, b
	or c
	jr nz, CopyBytes

	ret


;@ def DrawTilemapEntry(list: de, hi: a)
;@ path: gfx/tilemap
;@ Loop body of DrawTilemapList, placed in front of it: reads one entry of a tilemap list (a is its
;@ first byte, the high byte of the BG-map address; then the low byte and the control byte), draws it
;@ with DrawTilemapRun and goes on with the next entry.
;@ test: skip part of the DrawTilemapList loop
;@ sig: b3bf7e98
DrawTilemapEntry::
;> dest = hi << 8 | mem[list + 1]
	inc de
	ld h, a
	ld a, [de]
	ld l, a
;> control = mem[list + 2]
	inc de
	ld a, [de]
	inc de
;> list = DrawTilemapRun(dest, control, list + 3)
	call DrawTilemapRun
;> DrawTilemapList(list)                  # falls through to the next entry

;@ def DrawTilemapList(list: de)
;@ path: gfx/tilemap
;@ Draws a tilemap list into the BG map (the LCD must be off). A list is a series of entries ended
;@ by a 0 byte. Each entry is the BG-map address (high byte first), a control byte and the tiles:
;@ control bits 7-6 = mode (0: copy n tiles to the right, 1: one tile n times to the right,
;@ 2: copy n tiles downwards, 3: one tile n times downwards), bits 5-0 = n. All screens and menus
;@ of the game are drawn from such lists.
;@ test: skip walks a data list in ROM
;@ sig: 33d9826a
DrawTilemapList::
;> if mem[list] != 0:
;>     return DrawTilemapEntry(list, mem[list])   # draws it and comes back here for the next one
	ld a, [de]
	cp $00
	jr nz, DrawTilemapEntry
;> return
	ret


;@ def DrawTilemapRun(dest: hl, control: a, data: de) -> de
;@ path: gfx/tilemap
;@ Draws one entry of a tilemap list at `dest`: control bits 7-6 pick the mode, bits 5-0 the count n
;@ (0 means 256). Mode 0 copies n tiles to the right, 1 writes one tile n times to the right, 2 copies
;@ n tiles downwards (one BG row = 32 bytes apart), 3 writes one tile n times downwards. Returns the
;@ address after the entry's data.
;@ test: control = rand(1, 0x3F) | (rand(0, 3) << 6); dest = rand(0xC100, 0xC400); data = rand(0x4000, 0x7000)
;@ sig: 07185140
DrawTilemapRun::
;> n = control & 0x3F
	push af
	and $3f
	ld b, a
	pop af
;> mode = control >> 6
	rlca
	rlca
	and $03
;>@m0 if mode == 0:                      # copy n tiles to the right
	jr z, .copyRow
;>@r0     copy(dest, data, n); return data + n
;>@m1 elif mode == 1:                    # one tile n times to the right
	dec a
	jr z, .fillRow
;>@r1     fill(dest, mem[data], n); return data + 1
;>@m2 elif mode == 2:                    # copy n tiles downwards
	dec a
	jr z, .copyColumn
;>@c0     for i in range(n): mem[dest + 32 * i] = mem[data + i]
;>@c1     return data + n
;> else:                                 # one tile n times downwards
	jr .fillColumn
;>@f0     for i in range(n): mem[dest + 32 * i] = mem[data]
;>@f1     return data + 1

.copyRow:
;=@r0
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, .copyRow

	ret


.fillRow:
;=@r1
	ld a, [de]
	inc de
.fillRowLoop:
	ld [hli], a
	dec b
	jr nz, .fillRowLoop

	ret


.copyColumn:
;=@c0
	ld a, [de]
	ld [hl], a
	inc de
	ld a, b
	ld bc, $0020
	add hl, bc
;=@c0
	ld b, a
	dec b
	jr nz, .copyColumn
;=@c1
	ret


.fillColumn:
;=@f0
	ld a, [de]
	ld [hl], a
	ld a, b
	ld bc, $0020
	add hl, bc
;=@f0
	ld b, a
	dec b
	jr nz, .fillColumn
;=@f1
	inc de
	ret


;@ def ClearShadowOam()
;@ path: gfx/oam
;@ Clears the whole sprite buffer wShadowOam (40 sprites x 4 bytes): every sprite at Y 0 = hidden.
;@ sig: d9b80923
ClearShadowOam::
;>@f fill(wShadowOam, 0, 160)
	ld b, $a0
	ld a, $00
	ld hl, wShadowOam
.loop:
	ld [hli], a
;=@f
	dec b
	jr nz, .loop

	ret


;@ def InitSound()
;@ path: sound/engine
;@ Resets the sound engine: clears the four channel records (wSndCh1-4) and wSndNR52, starts the
;@ timer that drives the music (4096 Hz clock, reload $BC: an interrupt every 68 counts, about 60
;@ times a second), numbers the channel records 0-3 and silences all four sound channels
;@ (zero registers, then a restart with the volume at 0).
;@ writes: wSndCh1, wSndCh2, wSndCh3, wSndCh4
;@ test: skip writes the sound and timer hardware
;@ sig: 6250f054
InitSound::
;> fill(wSndCh1, 0, 0x21)               # the 4 channel records and wSndNR52
	xor a
	ld hl, wSndCh1
	ld b, $21
.clear:
	ld [hli], a
	dec b
	jr nz, .clear
;> rTIMA = 0xBC
;> rTMA = 0xBC                          # 256 - 68: about 60 timer interrupts a second
	ld a, $bc
	ldh [rTIMA], a
	ldh [rTMA], a
;> rNR51 = 0
;> rTAC = 0
	sub a
	ldh [rNR51], a
	ldh [rTAC], a
;> rTAC = 0x04                          # timer on, 4096 Hz
	ld a, $04
	ldh [rTAC], a
;> rNR51 = 0x80
	ld a, $80
	ldh [rNR51], a
;>@ids for i in range(4):                   # +0 of each record: its hardware channel
;>     mem[wSndCh1 + 8 * i] = i
	sub a
	ld [wSndCh1], a
	inc a
	ld [wSndCh2], a
;=@ids
	inc a
	ld [wSndCh3], a
	inc a
	ld [wSndCh4], a
;>@regs for reg in (0xFF10, 0xFF11, 0xFF12, 0xFF13, 0xFF16, 0xFF17, 0xFF18, 0xFF1A, 0xFF1B, 0xFF1C, 0xFF1D, 0xFF20, 0xFF21, 0xFF22): mem[reg] = 0   # NR10-13, NR21-23, NR30-33, NR41-43
	sub a
	ldh [rNR10], a
	ldh [rNR11], a
	ldh [rNR12], a
	ldh [rNR13], a
	ldh [rNR21], a
;=@regs
	ldh [rNR22], a
	ldh [rNR23], a
	ldh [rNR30], a
	ldh [rNR31], a
	ldh [rNR32], a
	ldh [rNR33], a
;=@regs
	ldh [rNR41], a
	ldh [rNR42], a
	ldh [rNR43], a
;> rNR14 = 0xC0
;> rNR24 = 0xC0                         # restart every channel (silent: the volume is 0)
	ld a, $c0
	ldh [rNR14], a
	ldh [rNR24], a
;> rNR34 = 0xC0
;> rNR44 = 0xC0
	ldh [rNR34], a
	ldh [rNR44], a
	ret


;@ def PlayQueuedSound()
;@ path: sound/engine
;@ Called every VBlank: while the sound queue has entries that were not started yet
;@ (wSoundQueuePos != wSoundQueueEnd), StartQueuedSound starts the next one and comes back here.
;@ In practice VBlank always queues one sound in entry 1 (pos 0, end 1).
;@ reads: wSoundQueueEnd, wSoundQueuePos
;@ test: skip loops through StartQueuedSound
;@ sig: 0370593b
PlayQueuedSound::
;> if wSoundQueuePos != wSoundQueueEnd:
;>     return StartQueuedSound(wSoundQueuePos)   # starts it and comes back here
	ld a, [wSoundQueueEnd]
	ld b, a
	ld a, [wSoundQueuePos]
	cp b
	jp nz, StartQueuedSound
;> return
	ret


;@ def UnusedPlaySound(sound: a)
;@ path: unused
;@ Nothing calls this. Starts sound `sound` at once (without the queue): the same loop as
;@ StartQueuedSound. Each part of the sound's header claims one channel record unless that channel
;@ is busy with a sound of higher priority.
;@ test: skip a part skipped for its priority misreads the header (see the note)
;@ sig: 7eeea300
UnusedPlaySound::
;>@hdr hdr = mem16[SoundTable + 2 * sound]
	ld h, $00
	ld l, a
	add hl, hl
	ld de, SoundTable
	add hl, de
	ld e, [hl]
;=@hdr
	inc hl
	ld d, [hl]
	ld b, d
	ld c, e
	ld d, h
	ld e, l
;=@hdr
	ld h, b
	ld l, c
;>@for for part in range(hdr + 1, hdr + 1 + 3 * mem[hdr], 3):   # one part per channel
	ld b, [hl]
.part:
;>     sel = mem[part]                  # high nibble: channel, low nibble: priority
	inc hl
	ld a, [hl]
	inc hl
;>@ch     ch = wSndCh1 + 8 * min(sel >> 4, 3)
	ld de, wSndCh1
	cp $10
	jr c, .gotChannel
;=@ch
	ld de, wSndCh2
	cp $20
	jr c, .gotChannel
;=@ch
	ld de, wSndCh3
	cp $30
	jr c, .gotChannel
;=@ch
	ld de, wSndCh4
.gotChannel:
;=@ch
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@ch
	ld l, c
	pop bc
;>     if sel & 0x0F >= mem[ch + 2]:   # lower priority than what plays there: skipped
	and $0f
	inc hl
	inc hl
	cp [hl]
	jr c, .next
;>         mem[ch + 1] = 0x03           # playing, start at the next tick
	dec hl
	ld [hl], $03
;>         mem[ch + 2] = sel & 0x0F
	inc hl
	ld [hl], a
;>@stream         mem16[ch + 3] = mem16[part + 1]     # the channel's stream
	ld a, [de]
	inc hl
	ld [hl], a
	inc de
	ld a, [de]
	inc hl
;=@stream
	ld [hl], a
.next:
;=@for
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@for
	ld l, c
	pop bc
	dec b
	jr nz, .part
;> # (a skipped part leaves the read pointer one byte short; every sound here has priority 8, so
;> # no part is ever skipped)
	ret


;@ def StartQueuedSound(pos: a)
;@ path: sound/engine
;@ Loop body of PlayQueuedSound: advances wSoundQueuePos to the next entry of wSoundQueue and starts
;@ that sound (see UnusedPlaySound for how the parts claim channels), then goes back to
;@ PlayQueuedSound for the next one.
;@ writes: wSoundQueuePos
;@ test: skip loops back into PlayQueuedSound
;@ sig: faad68a8
StartQueuedSound::
;> pos = (pos + 1) & 0x0F
;> wSoundQueuePos = pos
	inc a
	and $0f
	ld [wSoundQueuePos], a
;> sound = wSoundQueue[pos]
	ld c, a
	ld b, $00
	ld hl, wSoundQueue
	add hl, bc
	ld a, [hl]
;>@hdr hdr = mem16[SoundTable + 2 * sound]
	push hl
	push de
	push bc
	ld h, $00
	ld l, a
	add hl, hl
;=@hdr
	ld de, SoundTable
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
;=@hdr
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
	ld l, c
;>@for for part in range(hdr + 1, hdr + 1 + 3 * mem[hdr], 3):   # one part per channel
	ld b, [hl]
.part:
;>     sel = mem[part]                  # high nibble: channel, low nibble: priority
	inc hl
	ld a, [hl]
	inc hl
;>@ch     ch = wSndCh1 + 8 * min(sel >> 4, 3)
	ld de, wSndCh1
	cp $10
	jr c, .gotChannel
;=@ch
	ld de, wSndCh2
	cp $20
	jr c, .gotChannel
;=@ch
	ld de, wSndCh3
	cp $30
	jr c, .gotChannel
;=@ch
	ld de, wSndCh4
.gotChannel:
;=@ch
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@ch
	ld l, c
	pop bc
;>     if sel & 0x0F >= mem[ch + 2]:   # lower priority than what plays there: skipped
	and $0f
	inc hl
	inc hl
	cp [hl]
	jr c, .next
;>         mem[ch + 1] = 0x03           # playing, start at the next tick
	dec hl
	ld [hl], $03
;>         mem[ch + 2] = sel & 0x0F
	inc hl
	ld [hl], a
;>@stream         mem16[ch + 3] = mem16[part + 1]     # the channel's stream
	ld a, [de]
	inc hl
	ld [hl], a
	inc de
	ld a, [de]
	inc hl
;=@stream
	ld [hl], a
.next:
;=@for
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@for
	ld l, c
	pop bc
	dec b
	jr nz, .part
;> return PlayQueuedSound()
	pop bc
	pop de
	pop hl
	jp PlayQueuedSound


;@ def TimerHandler()
;@ path: sound/engine
;@ Timer interrupt, about 60 times a second: the tick of the sound engine. For each of the four
;@ channels UpdateSoundChannel moves its stream on when the channel has fallen silent (its note's
;@ length counter ran out; rNR52 bits 0-3) or when a new sound was just started on it.
;@ Quirk: after a call that read the stream, hl no longer points at the channel's flags but at the
;@ high byte of its stream pointer, so the second test looks at bit 1 of that byte instead - for
;@ streams stored at $4A00-$4BFF it is set, and the channel reads its next note in the same tick.
;@ writes: wSndNR52
;@ reads: wSndNR52
;@ test: skip interrupt handler (ends in reti)
;@ sig: 377ca11c
TimerHandler::
;> wSndNR52 = rNR52                     # which channels still sound
	push af
	push bc
	push de
	push hl
	ldh a, [rNR52]
	ld [wSndNR52], a
;>@loop for i in range(4):
;>     ch = wSndCh1 + 8 * i
	ld de, wSndCh1
	ld hl, wSndCh1 + 1
;>     if not wSndNR52 & (1 << i):      # its note is over
;>         UpdateSoundChannel(ch + 1, ch)
	bit 0, a
	call z, UpdateSoundChannel
;>     if mem[ch + 1] & 0x02:           # a new sound starts on it
;>         UpdateSoundChannel(ch + 1, ch)
	bit 1, [hl]
	call nz, UpdateSoundChannel
;=@loop
	ld de, wSndCh2
	ld hl, wSndCh2 + 1
	ld a, [wSndNR52]
	bit 1, a
	call z, UpdateSoundChannel
;=@loop
	bit 1, [hl]
	call nz, UpdateSoundChannel
	ld de, wSndCh3
	ld hl, wSndCh3 + 1
	ld a, [wSndNR52]
;=@loop
	bit 2, a
	call z, UpdateSoundChannel
	bit 1, [hl]
	call nz, UpdateSoundChannel
	ld de, wSndCh4
	ld hl, wSndCh4 + 1
;=@loop
	ld a, [wSndNR52]
	bit 3, a
	call z, UpdateSoundChannel
	bit 1, [hl]
	call nz, UpdateSoundChannel
;=@loop
	pop hl
;> return
	pop de
	pop bc
	pop af
	reti


;@ def UpdateSoundChannel(flags: hl, ch: de)
;@ path: sound/engine
;@ Plays the next step of a channel's stream (ch = its record, flags = ch + 1). A step is a length
;@ byte (0 = the end), then any number of commands ($8C-$BD, most with one argument byte) and
;@ usually one note ($A0-$FB: octave 2-7, see NoteFrequencies). The length byte goes into the
;@ channel's hardware length counter (NRx1), so the note stops by itself after (length + 1) / 256
;@ seconds and the next tick goes on with the next step. Commands: $BD n lengthen the note by n,
;@ $AC addr continue at addr (loops), $9F n master volume (NR50 = n | $88), $9E n panning (n = the
;@ NR51 bits for channel 1: $10 left, $01 right, $11 both), $9D n wave pattern n, $9C n noise note
;@ (NR43 = n), $8F n wave volume (NR32), $8E n duty bits, $8D n sweep (NR10), $8C n volume envelope.
;@ test: skip walks a sound stream in ROM
;@ sig: 329ac445
UpdateSoundChannel::
;> if not mem[flags] & 0x01:            # nothing playing on it
;>     return
	ld a, [hl]
	bit 0, a
	ret z
;> mem[flags] &= ~0x02                  # the start request is taken
	res 1, [hl]
;> p = mem16[ch + 3]                    # stream pointer
	ld hl, $0003
	add hl, de
	ld c, [hl]
	inc hl
	ld b, [hl]
;>@len length = mem[p]
	jr .length

;>@end if length == 0:                  # end of the stream
;>@end2     return StopSoundChannel(ch)
;>@set if mem[ch] == 2:                 # wave channel: 8-bit length counter
;>@setw     mem[ch + 7] = ~length & 0xFF
;> else:                                 # pulse and noise: 6 bits (the duty bits come from $8E)
;>@setp     mem[ch + 7] = ~length & 0x3F
;>@loop while True:
;>     p += 1
.next:
	inc bc
;>     cmd = mem[p]
	ld a, [bc]
;>@stop     if cmd < 0x80:               # the next step's length byte: wait for the next tick
;>@stop2         mem16[ch + 3] = p
;>@stop3         return
	bit 7, a
	jr z, .save
;>     p += 1                           # p -> the command's argument
	inc bc
;>     if cmd == 0xBD:                  # lengthen the note by arg
	cp $bd
	jr z, .lengthen
;>@bd         mem[ch + 7] = u8(mem[ch + 7] - mem[p])
;>     elif cmd == 0xAC:                # jump: the stream goes on at the address that follows
	cp $ac
	jr z, .jump
;>@ac         mem16[ch + 3] = mem16[p]; return      # read from the next tick on
;>     elif cmd == 0x9F:                # master volume
	cp $9f
	jr z, .masterVolume
;>@9f         rNR50 = mem[p] | 0x88
;>     elif cmd == 0x9E:                # panning, given as channel 1's bits and moved over
	cp $9e
	jr z, .panning
;>@9e         rNR51 = rNR51 & ~(0x11 << mem[ch]) | (mem[p] << mem[ch])
;>     elif cmd == 0x9D:                # wave pattern
	cp $9d
	jr z, .loadWave
;>@9d         copy(0xFF30, mem16[WaveTable + 2 * mem[p]], 16)
;>     elif cmd == 0x9C:                # noise note: NR43 = arg, length from the step
	cp $9c
	jp z, .noise
;>@9c         rNR41 = mem[ch + 7]; rNR43 = mem[p]; rNR44 = 0xC0
;>     elif cmd == 0x8F:                # wave volume
	cp $8f
	jp z, .waveVolume
;>@8f         rNR32 = mem[p]
;>     elif cmd == 0x8E:                # duty bits for NRx1
	cp $8e
	jp z, .duty
;>@8e         mem[ch + 7] |= mem[p]
;>     elif cmd == 0x8D:                # sweep of channel 1
	cp $8d
	jp z, .sweep
;>@8d         rNR10 = mem[p]
;>     elif cmd == 0x8C:                # volume envelope (channels 1, 2 and 4)
	cp $8c
	jp z, .envelope
;>@8c         if mem[ch] != 2: mem[(0xFF12, 0xFF17, 0, 0xFF21)[mem[ch]]] = mem[p]
;>     else:                            # a note: it has no argument byte
;>@note         p -= 1; PlayNote(ch, NoteFrequencies[cmd & 0x7F])
	jp .note


.save:
;=@stop2
	ld hl, $0003
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
;=@stop3
	ret


.length:
;=@set
	ld a, [de]
	cp $02
	jr z, .waveLength
;=@len
	ld a, [bc]
;=@end
	or a
;=@end2
	jp z, StopSoundChannel
;=@setp
	cpl
	and $3f
	jr .setLength

.waveLength:
;=@len
	ld a, [bc]
;=@end
	or a
;=@end2
	jp z, StopSoundChannel
;=@setw
	cpl
.setLength:
;=@set
	ld hl, $0007
	add hl, de
	ld [hl], a
;=@loop
	jr .next

.lengthen:
;=@bd
	ld hl, $0007
	add hl, de
	ld a, [hl]
	cpl
	ld [hl], a
	ld a, [bc]
;=@bd
	add [hl]
	cpl
	ld [hl], a
	jr .next

.jump:
;=@ac
	ld h, b
	ld l, c
	ld c, [hl]
	inc hl
	ld b, [hl]
	jr .save

.masterVolume:
;=@9f
	ld a, [bc]
	or $88
	ldh [rNR50], a
	jr .next

.panning:
;=@9e
	ld a, [bc]
	ld h, a
	ld l, $ee
	ld a, [de]
	and a
	jr z, .setPanning
;=@9e
	rlc h
	rlc l
	dec a
	jr z, .setPanning
;=@9e
	rlc h
	rlc l
	dec a
	jr z, .setPanning
;=@9e
	rlc h
	rlc l
.setPanning:
;=@9e
	ldh a, [rNR51]
	and l
	or h
	ldh [rNR51], a
	jp .next


.loadWave:
;=@9d
	ld a, [bc]
	push de
	ld hl, WaveTable
	add a
	add l
	ld l, a
;=@9d
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, $ff30
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	inc de
	ld [hli], a
;=@9d
	ld a, [de]
	inc de
	ld [hli], a
	ld a, [de]
	ld [hl], a
;=@9d
	pop de
	jp .next


.noise:
;=@9c
	ld hl, $0007
	add hl, de
	ld a, [hl]
	ldh [rNR41], a
	ld a, [bc]
	ldh [rNR43], a
;=@9c
	ld a, $c0
	ldh [rNR44], a
	jp .next


.waveVolume:
;=@8f
	ld a, [bc]
	ldh [rNR32], a
	jp .next


.duty:
;=@8e
	ld a, [bc]
	ld hl, $0007
	add hl, de
	or [hl]
	ld [hl], a
	jp .next


.sweep:
;=@8d
	ld a, [bc]
	ldh [rNR10], a
	jp .next


.envelope:
;=@8c
	ld a, [de]
	cp $00
	jr z, .envelope1
	cp $01
	jr z, .envelope2
;=@8c
	cp $03
	jr z, .envelope4
	jp .next


.envelope1:
;=@8c
	ld a, [bc]
	ldh [rNR12], a
	jp .next


.envelope2:
;=@8c
	ld a, [bc]
	ldh [rNR22], a
	jp .next


.envelope4:
;=@8c
	ld a, [bc]
	ldh [rNR42], a
	jp .next


.note:
;=@note
	dec bc
;=@note
	ld a, [bc]
	and $7f
	ld h, $00
	ld l, a
	push bc
	ld bc, NoteFrequencies
;=@note
	add hl, hl
	add hl, bc
	ld c, [hl]
	inc hl
	ld b, [hl]
	call PlayNote
;=@note
	pop bc
	jp .next


;@ def PlayNote(ch: de, freq: bc)
;@ path: sound/engine
;@ Starts a note on the channel of record `ch`: NRx1 = the record's duty/length byte (+7), the
;@ 11-bit frequency `freq`, and a restart with the length counter on (bit 6), so the note stops by
;@ itself. Channel 3 (wave) is switched on first. Any other channel number takes the wave path
;@ too (the noise channel plays its notes with command $9C instead).
;@ test: ch = rand(0xC100, 0xC800); freq = rand(0, 0x7FF)
;@ sig: dcea78fd
PlayNote::
;> if mem[ch] == 0:
	ld a, [de]
	cp $00
	jr z, .pulse1
;>@a1     rNR11 = mem[ch + 7]
;>@a2     rNR13 = freq & 0xFF
;>@a3     rNR14 = freq >> 8 | 0xC0      # restart, length counter on
;> elif mem[ch] == 1:
	cp $01
	jr z, .pulse2
;>@b1     rNR21 = mem[ch + 7]
;>@b2     rNR23 = freq & 0xFF; rNR24 = freq >> 8 | 0xC0
;> else:
	jr .wave

.pulse1:
;=@a1
	ld hl, $0007
	add hl, de
	ld a, [hl]
	ldh [rNR11], a
;=@a2
	ld a, c
	ldh [rNR13], a
;=@a3
	ld a, b
	or $c0
	ldh [rNR14], a
	ret


.pulse2:
;=@b1
	ld hl, $0007
	add hl, de
	ld a, [hl]
	ldh [rNR21], a
;=@b2
	ld a, c
	ldh [rNR23], a
	ld a, b
	or $c0
	ldh [rNR24], a
	ret


.wave:
;>     rNR30 = 0x80                     # wave channel on
	ld a, $80
	ldh [rNR30], a
;>     rNR31 = mem[ch + 7]
	ld hl, $0007
	add hl, de
	ld a, [hl]
	ldh [rNR31], a
;>     rNR33 = freq & 0xFF
	ld a, c
	ldh [rNR33], a
;>     rNR34 = freq >> 8 | 0xC0
	ld a, b
	or $c0
	ldh [rNR34], a
	ret


;@ path: sound/engine
;@ Frequency values (for NRx3/NRx4) of the notes, indexed by note byte & $7F: 16 entries per octave,
;@ C to B and 4 unused (0) slots, octaves 2 (note $A0) to 7. The rows $80-$9F are unused, and the
;@ command codes $8C-$8F, $9C-$9F, $AC and $BD sit on unused slots. On the wave channel the same
;@ value sounds an octave lower.
NoteFrequencies::
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000   ; notes $80-$87: unused (0)
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000   ; notes $88-$8F: unused; $8C-$8F are command codes
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000   ; notes $90-$97: unused (0)
	dw $0000, $0000, $0000, $0000, $0000, $0000, $0000, $0000   ; notes $98-$9F: unused; $9C-$9F are command codes
	dw $002C, $009D, $0107, $016B, $01C9, $0223   ; octave 2: C C# D D# E F (notes $A0-$A5)
	dw $0277, $02C7, $0312, $0358, $039B, $03DA   ; octave 2: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $AC-$AF: unused ($AC is a command code)
	dw $0416, $044E, $0483, $04B5, $04E5, $0511   ; octave 3: C C# D D# E F (notes $B0-$B5)
	dw $053B, $0563, $0589, $05AC, $05CE, $05ED   ; octave 3: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $BC-$BF: unused ($BD is a command code)
	dw $060B, $0627, $0642, $065B, $0672, $0689   ; octave 4: C C# D D# E F (notes $C0-$C5)
	dw $069E, $06B2, $06C4, $06D6, $06E7, $06F7   ; octave 4: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $CC-$CF: unused
	dw $0706, $0714, $0721, $072D, $0739, $0744   ; octave 5: C C# D D# E F (notes $D0-$D5)
	dw $074F, $0759, $0762, $076B, $0773, $077B   ; octave 5: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $DC-$DF: unused
	dw $0783, $078A, $0790, $0797, $079D, $07A2   ; octave 6: C C# D D# E F (notes $E0-$E5)
	dw $07A7, $07AC, $07B1, $07B6, $07BA, $07BE   ; octave 6: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $EC-$EF: unused
	dw $07C1, $07C5, $07C8, $07CB, $07CE, $07D1   ; octave 7: C C# D D# E F (notes $F0-$F5)
	dw $07D4, $07D6, $07D9, $07DB, $07DD, $07DF   ; octave 7: F# G G# A A# B
	dw $0000, $0000, $0000, $0000   ; notes $FC-$FF: unused

;@ def StopSoundChannel(ch: de)
;@ path: sound/engine
;@ End of a stream: takes the channel out of both speakers (rNR51) and clears the record's flags
;@ and priority, so any sound may use the channel again.
;@ test: ch = 0xD131 + 8 * rand(0, 3)
;@ sig: 2ebef24c
StopSoundChannel::
;>@keep keep = (0xEE, 0xDD, 0xBB, 0x77)[min(mem[ch], 3)]   # NR51 without this channel's two bits
	ld a, [de]
	ld h, $ee
	cp $00
	jr z, .mute
;=@keep
	ld h, $dd
	cp $01
	jr z, .mute
;=@keep
	ld h, $bb
	cp $02
	jr z, .mute
;=@keep
	ld h, $77
.mute:
;> rNR51 &= keep
	ldh a, [rNR51]
	and h
	ldh [rNR51], a
;> mem[ch + 1] = 0                      # not playing
	ld h, d
	ld l, e
	inc hl
	ld [hl], $00
;> mem[ch + 2] = 0                      # priority 0
	inc hl
	ld [hl], $00
	ret


;@ def UnusedPlaySoundKeepRegs(sound: a)
;@ path: unused
;@ Nothing calls this. Same as UnusedPlaySound (start a sound at once, without the queue), but it
;@ keeps bc, de and hl.
;@ test: skip a part skipped for its priority misreads the header (see the note)
;@ sig: 06ccb8b9
UnusedPlaySoundKeepRegs::
;>@hdr hdr = mem16[SoundTable + 2 * sound]
	push hl
	push de
	push bc
	ld h, $00
	ld l, a
	add hl, hl
;=@hdr
	ld de, SoundTable
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
;=@hdr
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
	ld l, c
;>@for for part in range(hdr + 1, hdr + 1 + 3 * mem[hdr], 3):   # one part per channel
	ld b, [hl]
.part:
;>     sel = mem[part]                  # high nibble: channel, low nibble: priority
	inc hl
	ld a, [hl]
	inc hl
;>@ch     ch = wSndCh1 + 8 * min(sel >> 4, 3)
	ld de, wSndCh1
	cp $10
	jr c, .gotChannel
;=@ch
	ld de, wSndCh2
	cp $20
	jr c, .gotChannel
;=@ch
	ld de, wSndCh3
	cp $30
	jr c, .gotChannel
;=@ch
	ld de, wSndCh4
.gotChannel:
;=@ch
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@ch
	ld l, c
	pop bc
;>     if sel & 0x0F >= mem[ch + 2]:   # lower priority than what plays there: skipped
	and $0f
	inc hl
	inc hl
	cp [hl]
	jr c, .next
;>         mem[ch + 1] = 0x03           # playing, start at the next tick
	dec hl
	ld [hl], $03
;>         mem[ch + 2] = sel & 0x0F
	inc hl
	ld [hl], a
;>@stream         mem16[ch + 3] = mem16[part + 1]     # the channel's stream
	ld a, [de]
	inc hl
	ld [hl], a
	inc de
	ld a, [de]
	inc hl
;=@stream
	ld [hl], a
.next:
;=@for
	push bc
	ld b, d
	ld c, e
	ld d, h
	ld e, l
	ld h, b
;=@for
	ld l, c
	pop bc
	dec b
	jr nz, .part
;> return
	pop bc
	pop de
	pop hl
	ret


;@ path: unused
;@ Unused space: $FF bytes up to the sound data at $4800.
PaddingFF_4227::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ path: sound/data
;@ The sound table: one pointer per sound number ($00-$1C) to its header. A sound is started by
;@ putting its number into hSfxRequest, hSfxRequest2 or hMarchSfxRequest; VBlank queues it and
;@ StartQueuedSound reads the header.
SoundTable::
	dw SndStopAll             ; $00
	dw SndStopCh1             ; $01
	dw SndStopCh2             ; $02
	dw SndStopCh3             ; $03
	dw SndStopCh4             ; $04
	dw SndShotLeft            ; $05
	dw SndShotCentre          ; $06
	dw SndShotRight           ; $07
	dw SndInvaderHitLeft      ; $08
	dw SndInvaderHitCentre    ; $09
	dw SndInvaderHitRight     ; $0A
	dw SndCannonExplodes      ; $0B
	dw SndUfoLeft             ; $0C
	dw SndUfoCentre           ; $0D
	dw SndUfoRight            ; $0E
	dw SndUfoHitLeft          ; $0F
	dw SndUfoHitCentre        ; $10
	dw SndUfoHitRight         ; $11
	dw SndTargetDown          ; $12
	dw SndBonus               ; $13
	dw SndMarch1              ; $14
	dw SndMarch2              ; $15
	dw SndMarch3              ; $16
	dw SndMarch4              ; $17
	dw SndLinkWin             ; $18
	dw SndLinkLoss            ; $19
	dw SndUnusedBlip          ; $1A
	dw SndSecretCode          ; $1B
	dw SndUnusedTune          ; $1C

;@ path: sound/headers
;@ Sound $00: Silences all four channels (each plays one short step at volume 0 and ends). VBlank starts it when hSoundOff is set.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndStopAll::
	db 4                      ; 4 parts
	db $08, LOW(SeqStopCh1), HIGH(SeqStopCh1)   ; channel 1 (pulse), priority 8
	db $18, LOW(SeqStopCh2), HIGH(SeqStopCh2)   ; channel 2 (pulse), priority 8
	db $28, LOW(SeqStopCh3), HIGH(SeqStopCh3)   ; channel 3 (wave), priority 8
	db $38, LOW(SeqStopCh4), HIGH(SeqStopCh4)   ; channel 4 (noise), priority 8
;@ path: sound/headers
;@ Sound $01: Silences channel 1.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndStopCh1::
	db 1                      ; 1 part
	db $08, LOW(SeqStopCh1), HIGH(SeqStopCh1)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $02: Silences channel 2.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndStopCh2::
	db 1                      ; 1 part
	db $18, LOW(SeqStopCh2), HIGH(SeqStopCh2)   ; channel 2 (pulse), priority 8

;@ path: sound/headers
;@ Sound $03: Silences channel 3.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndStopCh3::
	db 1                      ; 1 part
	db $28, LOW(SeqStopCh3), HIGH(SeqStopCh3)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $04: Silences channel 4.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndStopCh4::
	db 1                      ; 1 part
	db $38, LOW(SeqStopCh4), HIGH(SeqStopCh4)   ; channel 4 (noise), priority 8
;@ path: sound/headers
;@ Sound $05: The cannon fires: a short noise burst, heard on the left (the cannon is in the left part of the screen).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndShotLeft::
	db 1                      ; 1 part
	db $38, LOW(SeqShotLeft), HIGH(SeqShotLeft)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $06: The cannon fires, heard on both sides (the cannon is in the middle).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndShotCentre::
	db 1                      ; 1 part
	db $38, LOW(SeqShotCentre), HIGH(SeqShotCentre)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $07: The cannon fires, heard on the right.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndShotRight::
	db 1                      ; 1 part
	db $38, LOW(SeqShotRight), HIGH(SeqShotRight)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $08: An invader is hit: a falling sweep on channel 1, on the left.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndInvaderHitLeft::
	db 1                      ; 1 part
	db $08, LOW(SeqInvaderHitLeft), HIGH(SeqInvaderHitLeft)   ; channel 1 (pulse), priority 8
;@ path: sound/headers
;@ Sound $09: An invader is hit, on both sides.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndInvaderHitCentre::
	db 1                      ; 1 part
	db $08, LOW(SeqInvaderHitCentre), HIGH(SeqInvaderHitCentre)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $0A: An invader is hit, on the right.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndInvaderHitRight::
	db 1                      ; 1 part
	db $08, LOW(SeqInvaderHitRight), HIGH(SeqInvaderHitRight)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $0B: The cannon is destroyed: four long noise bursts.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndCannonExplodes::
	db 1                      ; 1 part
	db $38, LOW(SeqCannonExplodes), HIGH(SeqCannonExplodes)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $0C: The UFO flies: one swept tone repeated for as long as it is on screen (the stream loops), on the left.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoLeft::
	db 1                      ; 1 part
	db $08, LOW(SeqUfoLeft), HIGH(SeqUfoLeft)   ; channel 1 (pulse), priority 8
;@ path: sound/headers
;@ Sound $0D: The UFO flies, on both sides.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoCentre::
	db 1                      ; 1 part
	db $08, LOW(SeqUfoCentre), HIGH(SeqUfoCentre)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $0E: The UFO flies, on the right.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoRight::
	db 1                      ; 1 part
	db $08, LOW(SeqUfoRight), HIGH(SeqUfoRight)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $0F: The UFO is hit: a long noise burst, on the left.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoHitLeft::
	db 1                      ; 1 part
	db $38, LOW(SeqUfoHitLeft), HIGH(SeqUfoHitLeft)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $10: The UFO is hit, on both sides.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoHitCentre::
	db 1                      ; 1 part
	db $38, LOW(SeqUfoHitCentre), HIGH(SeqUfoHitCentre)   ; channel 4 (noise), priority 8
;@ path: sound/headers
;@ Sound $11: The UFO is hit, on the right.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUfoHitRight::
	db 1                      ; 1 part
	db $38, LOW(SeqUfoHitRight), HIGH(SeqUfoHitRight)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $12: A high swept tone that loops; requested when the UFO is hit and when the opponent is hit in a link game.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndTargetDown::
	db 1                      ; 1 part
	db $08, LOW(SeqTargetDown), HIGH(SeqTargetDown)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $13: Three noise bursts: an extra cannon is given, or a new hi-score is reached.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndBonus::
	db 1                      ; 1 part
	db $38, LOW(SeqBonus), HIGH(SeqBonus)   ; channel 4 (noise), priority 8

;@ path: sound/headers
;@ Sound $14: March beat, note 1 of 4 (wave channel, low C) - the invaders' four-note march, faster as fewer are left.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndMarch1::
	db 1                      ; 1 part
	db $28, LOW(SeqMarch1), HIGH(SeqMarch1)   ; channel 3 (wave), priority 8
;@ path: sound/headers
;@ Sound $15: March beat, note 2 (A#).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndMarch2::
	db 1                      ; 1 part
	db $28, LOW(SeqMarch2), HIGH(SeqMarch2)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $16: March beat, note 3 (G#).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndMarch3::
	db 1                      ; 1 part
	db $28, LOW(SeqMarch3), HIGH(SeqMarch3)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $17: March beat, note 4 (G).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndMarch4::
	db 1                      ; 1 part
	db $28, LOW(SeqMarch4), HIGH(SeqMarch4)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $18: Jingle of the link-game winner (all three tone channels).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndLinkWin::
	db 3                      ; 3 parts
	db $08, LOW(SeqLinkWinSq1), HIGH(SeqLinkWinSq1)   ; channel 1 (pulse), priority 8
	db $18, LOW(SeqLinkWinSq2), HIGH(SeqLinkWinSq2)   ; channel 2 (pulse), priority 8
	db $28, LOW(SeqLinkWinWave), HIGH(SeqLinkWinWave)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $19: Jingle of the link-game loser (an arpeggio on three channels).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndLinkLoss::
	db 3                      ; 3 parts
	db $08, LOW(SeqLinkLossSq1), HIGH(SeqLinkLossSq1)   ; channel 1 (pulse), priority 8
	db $18, LOW(SeqLinkLossSq2), HIGH(SeqLinkLossSq2)   ; channel 2 (pulse), priority 8
	db $28, LOW(SeqLinkLossWave), HIGH(SeqLinkLossWave)   ; channel 3 (wave), priority 8
;@ path: sound/headers
;@ Sound $1C: A three-channel tune that no code requests.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUnusedTune::
	db 3                      ; 3 parts
	db $08, LOW(SeqUnusedTuneSq1), HIGH(SeqUnusedTuneSq1)   ; channel 1 (pulse), priority 8
	db $18, LOW(SeqUnusedTuneSq2), HIGH(SeqUnusedTuneSq2)   ; channel 2 (pulse), priority 8
	db $28, LOW(SeqUnusedTuneWave), HIGH(SeqUnusedTuneWave)   ; channel 3 (wave), priority 8

;@ path: sound/headers
;@ Sound $1A: A short three-note blip that no code requests.
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndUnusedBlip::
	db 1                      ; 1 part
	db $08, LOW(SeqUnusedBlip), HIGH(SeqUnusedBlip)   ; channel 1 (pulse), priority 8

;@ path: sound/headers
;@ Sound $1B: A secret code was entered: one high beep (CheckTitleCheatCodes, CheckGameCheatCodes).
;@ Header: the number of parts, then per part a channel/priority byte (high nibble: channel
;@ 0-3, low nibble: priority) and the address of that channel's stream.
SndSecretCode::
	db 1                      ; 1 part
	db $08, LOW(SeqSecretCode), HIGH(SeqSecretCode)   ; channel 1 (pulse), priority 8

;@ path: sound/streams
;@ Stream of sound $00/$01: one step of length 1 with the volume envelope 0 (silent).
;@ Each line is one step: the length byte (the note sounds for (length + 1) / 256 seconds; the
;@ pulse and noise channels use only its low 6 bits), commands with their argument, then the note.
;@ $00 ends the stream (see UpdateSoundChannel).
SeqStopCh1::
	db $01, $8C, $00, $C0     ; length 2, envelope $00, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of sound $00/$02 (channel 2): silent step.
SeqStopCh2::
	db $01, $8C, $00, $C0     ; length 2, envelope $00, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of sound $00/$03 (channel 3): wave volume 0.
SeqStopCh3::
	db $01, $8F, $00, $C0     ; length 2, wave volume $00, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of sound $00/$04 (channel 4): silent step.
SeqStopCh4::
	db $01, $8C, $00, $C0     ; length 2, envelope $00, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndShotLeft on channel 4 (noise).
SeqShotLeft::
	db $3F, $8C, $F1, $9F, $77, $9E, $10, $9C, $22 ; length 64, envelope $F1, master volume $77, panning left, noise $22
	db $00                  ; end
;@ path: sound/streams
;@ Stream of SndShotCentre on channel 4 (noise).
SeqShotCentre::
	db $3F, $8C, $F1, $9F, $77, $9E, $11, $9C, $22 ; length 64, envelope $F1, master volume $77, panning both sides, noise $22
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndShotRight on channel 4 (noise).
SeqShotRight::
	db $3F, $8C, $F1, $9F, $77, $9E, $01, $9C, $22 ; length 64, envelope $F1, master volume $77, panning right, noise $22
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndInvaderHitLeft on channel 1 (pulse).
SeqInvaderHitLeft::
	db $30, $8C, $A2, $9F, $77, $9E, $10, $8E, $80, $8D, $16, $C0 ; length 49, envelope $A2, master volume $77, panning left, duty 50%, sweep $16, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndInvaderHitCentre on channel 1 (pulse).
SeqInvaderHitCentre::
	db $30, $8C, $A2, $9F, $77, $9E, $11, $8E, $80, $8D, $16, $C0 ; length 49, envelope $A2, master volume $77, panning both sides, duty 50%, sweep $16, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndInvaderHitRight on channel 1 (pulse).
SeqInvaderHitRight::
	db $30, $8C, $A2, $9F, $77, $9E, $01, $8E, $80, $8D, $16, $C0 ; length 49, envelope $A2, master volume $77, panning right, duty 50%, sweep $16, C4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndCannonExplodes on channel 4 (noise).
SeqCannonExplodes::
	db $3F, $8C, $F2, $9F, $77, $9E, $11, $9C, $54 ; length 64, envelope $F2, master volume $77, panning both sides, noise $54
	db $3F, $8C, $A4, $9F, $77, $9E, $11, $9C, $54 ; length 64, envelope $A4, master volume $77, panning both sides, noise $54
	db $3F, $8C, $A4, $9F, $77, $9E, $11, $9C, $54 ; length 64, envelope $A4, master volume $77, panning both sides, noise $54
	db $3F, $8C, $A4, $9F, $77, $9E, $11, $9C, $54 ; length 64, envelope $A4, master volume $77, panning both sides, noise $54
	db $00                  ; end
;@ path: sound/streams
;@ Stream of SndUfoLeft on channel 1 (pulse).
SeqUfoLeft::
	db $3F, $8C, $F0, $9F, $77, $9E, $10, $8E, $80, $8D, $17, $D2 ; length 64, envelope $F0, master volume $77, panning left, duty 50%, sweep $17, D5
	db $AC
	dw SeqUfoLeft             ; jump: start over (loops until another sound takes the channel)
	db $00                  ; (never reached)
;@ path: sound/streams
;@ Stream of SndUfoCentre on channel 1 (pulse).
SeqUfoCentre::
	db $3F, $8C, $F0, $9F, $77, $9E, $11, $8E, $80, $8D, $17, $D2 ; length 64, envelope $F0, master volume $77, panning both sides, duty 50%, sweep $17, D5
	db $AC
	dw SeqUfoCentre           ; jump: start over (loops until another sound takes the channel)
	db $00                  ; (never reached)
;@ path: sound/streams
;@ Stream of SndUfoRight on channel 1 (pulse).
SeqUfoRight::
	db $3F, $8C, $F0, $9F, $77, $9E, $01, $8E, $80, $8D, $17, $D2 ; length 64, envelope $F0, master volume $77, panning right, duty 50%, sweep $17, D5
	db $AC
	dw SeqUfoRight            ; jump: start over (loops until another sound takes the channel)
	db $00                  ; (never reached)
;@ path: sound/streams
;@ Stream of SndUfoHitLeft on channel 4 (noise).
SeqUfoHitLeft::
	db $3F, $8C, $F1, $9F, $77, $9E, $10, $9C, $88 ; length 64, envelope $F1, master volume $77, panning left, noise $88
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUfoHitCentre on channel 4 (noise).
SeqUfoHitCentre::
	db $3F, $8C, $F1, $9F, $77, $9E, $11, $9C, $88 ; length 64, envelope $F1, master volume $77, panning both sides, noise $88
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUfoHitRight on channel 4 (noise).
SeqUfoHitRight::
	db $3F, $8C, $F1, $9F, $77, $9E, $01, $9C, $88 ; length 64, envelope $F1, master volume $77, panning right, noise $88
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndTargetDown on channel 1 (pulse).
SeqTargetDown::
	db $30, $8C, $F0, $9F, $77, $9E, $11, $8E, $80, $8D, $1F, $D5 ; length 49, envelope $F0, master volume $77, panning both sides, duty 50%, sweep $1F, F5
	db $AC
	dw SeqTargetDown          ; jump: start over (loops until another sound takes the channel)
	db $00                  ; (never reached)

;@ path: sound/streams
;@ Stream of SndBonus on channel 4 (noise).
SeqBonus::
	db $30, $8C, $F1, $9F, $77, $9E, $11, $9C, $0B ; length 49, envelope $F1, master volume $77, panning both sides, noise $0B
	db $30, $8C, $F1, $9C, $0B ; length 49, envelope $F1, noise $0B
	db $3F, $8C, $F1, $9C, $0B ; length 64, envelope $F1, noise $0B
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndMarch1 on channel 3 (wave).
SeqMarch1::
	db $0F, $9D, $01, $9F, $77, $9E, $11, $8F, $20, $B0 ; length 16, wave 1, master volume $77, panning both sides, wave volume $20, C3
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndMarch2 on channel 3 (wave).
SeqMarch2::
	db $0F, $9D, $01, $9F, $77, $9E, $11, $8F, $20, $AA ; length 16, wave 1, master volume $77, panning both sides, wave volume $20, A#2
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndMarch3 on channel 3 (wave).
SeqMarch3::
	db $0F, $9D, $01, $9F, $77, $9E, $11, $8F, $20, $A8 ; length 16, wave 1, master volume $77, panning both sides, wave volume $20, G#2
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndMarch4 on channel 3 (wave).
SeqMarch4::
	db $0F, $9D, $01, $9F, $77, $9E, $11, $8F, $20, $A7 ; length 16, wave 1, master volume $77, panning both sides, wave volume $20, G2
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkWin on channel 1 (pulse).
SeqLinkWinSq1::
	db $20, $9F, $77, $9E, $11, $8C, $F1, $8D, $48, $8E, $80, $CB ; length 33, master volume $77, panning both sides, envelope $F1, sweep $48, duty 50%, B4
	db $20, $D1               ; length 33, C#5
	db $20, $D4               ; length 33, E5
	db $20, $D9               ; length 33, A5
	db $3F, $DB               ; length 64, B5
	db $3F, $E2               ; length 64, D6
	db $20, $E1               ; length 33, C#6
	db $20, $D9               ; length 33, A5
	db $1A, $D9               ; length 27, A5
	db $20, $D9               ; length 33, A5
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkWin on channel 2 (pulse).
SeqLinkWinSq2::
	db $20, $9F, $77, $9E, $11, $8C, $F2, $8E, $80, $BB ; length 33, master volume $77, panning both sides, envelope $F2, duty 50%, B3
	db $20, $C1               ; length 33, C#4
	db $20, $C4               ; length 33, E4
	db $20, $C9               ; length 33, A4
	db $3F, $CB               ; length 64, B4
	db $3F, $D2               ; length 64, D5
	db $20, $D1               ; length 33, C#5
	db $20, $C9               ; length 33, A4
	db $1A, $C9               ; length 27, A4
	db $20, $C9               ; length 33, A4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkWin on channel 3 (wave).
SeqLinkWinWave::
	db $20, $9F, $77, $9E, $11, $8F, $20, $9D, $01, $AB ; length 33, master volume $77, panning both sides, wave volume $20, wave 1, B2
	db $20, $B1               ; length 33, C#3
	db $20, $B4               ; length 33, E3
	db $20, $B9               ; length 33, A3
	db $3F, $BB               ; length 64, B3
	db $3F, $C2               ; length 64, D4
	db $20, $C1               ; length 33, C#4
	db $20, $B9               ; length 33, A3
	db $1A, $B9               ; length 27, A3
	db $20, $B9               ; length 33, A3
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkLoss on channel 1 (pulse).
SeqLinkLossSq1::
	db $17, $9F, $77, $9E, $11, $8C, $F1, $8D, $48, $8E, $00, $C0 ; length 24, master volume $77, panning both sides, envelope $F1, sweep $48, duty 12%, C4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $3F, $C3               ; length 64, D#4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkLoss on channel 2 (pulse).
SeqLinkLossSq2::
	db $20, $9F, $77, $9E, $11, $8C, $F1, $8E, $00, $C0 ; length 33, master volume $77, panning both sides, envelope $F1, duty 12%, C4
	db $17, $C0               ; length 24, C4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $34, $C3               ; length 53, D#4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndLinkLoss on channel 3 (wave).
SeqLinkLossWave::
	db $17, $9F, $77, $9E, $11, $8F, $40, $9D, $00, $C0 ; length 24, master volume $77, panning both sides, wave volume $40, wave 0, C4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $17, $C3               ; length 24, D#4
	db $17, $C9               ; length 24, A4
	db $17, $C6               ; length 24, F#4
	db $3F, $C3               ; length 64, D#4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUnusedBlip on channel 1 (pulse).
SeqUnusedBlip::
	db $10, $9F, $77, $9E, $11, $8C, $F1, $8D, $08, $8E, $00, $DB ; length 17, master volume $77, panning both sides, envelope $F1, sweep $08, duty 12%, B5
	db $10, $DA               ; length 17, A#5
	db $20, $DB               ; length 33, B5
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndSecretCode on channel 1 (pulse).
SeqSecretCode::
	db $3F, $9F, $77, $9E, $11, $8C, $F1, $8D, $08, $8E, $00, $F0 ; length 64, master volume $77, panning both sides, envelope $F1, sweep $08, duty 12%, C7
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUnusedTune on channel 2 (pulse).
SeqUnusedTuneSq2::
	db $20, $9F, $77, $9E, $11, $8C, $F2, $8E, $00, $C9 ; length 33, master volume $77, panning both sides, envelope $F2, duty 12%, A4
	db $20, $C7               ; length 33, G4
	db $20, $C9               ; length 33, A4
	db $20, $CB               ; length 33, B4
	db $20, $C9               ; length 33, A4
	db $20, $CB               ; length 33, B4
	db $20, $D0               ; length 33, C5
	db $20, $CB               ; length 33, B4
	db $20, $D0               ; length 33, C5
	db $20, $D5               ; length 33, F5
	db $20, $D4               ; length 33, E5
	db $20, $D2               ; length 33, D5
	db $20, $C5               ; length 33, F4
	db $20, $C4               ; length 33, E4
	db $20, $C5               ; length 33, F4
	db $20, $C7               ; length 33, G4
	db $20, $C5               ; length 33, F4
	db $20, $C7               ; length 33, G4
	db $3F, $C9               ; length 64, A4
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUnusedTune on channel 1 (pulse).
SeqUnusedTuneSq1::
	db $20, $9F, $77, $9E, $11, $8C, $F2, $8D, $48, $8E, $00, $B9 ; length 33, master volume $77, panning both sides, envelope $F2, sweep $48, duty 12%, A3
	db $20, $B7               ; length 33, G3
	db $20, $B9               ; length 33, A3
	db $20, $BB               ; length 33, B3
	db $20, $B9               ; length 33, A3
	db $20, $BB               ; length 33, B3
	db $20, $C0               ; length 33, C4
	db $20, $BB               ; length 33, B3
	db $20, $C0               ; length 33, C4
	db $20, $C5               ; length 33, F4
	db $20, $C4               ; length 33, E4
	db $20, $C2               ; length 33, D4
	db $20, $B5               ; length 33, F3
	db $20, $B4               ; length 33, E3
	db $20, $B5               ; length 33, F3
	db $20, $B7               ; length 33, G3
	db $20, $B5               ; length 33, F3
	db $20, $B7               ; length 33, G3
	db $3F, $B9               ; length 64, A3
	db $00                  ; end

;@ path: sound/streams
;@ Stream of SndUnusedTune on channel 3 (wave).
SeqUnusedTuneWave::
	db $20, $9E, $11, $8F, $00, $B5 ; length 33, panning both sides, wave volume $00, F3
	db $20, $C4               ; length 33, E4
	db $20, $C5               ; length 33, F4
	db $20, $C6               ; length 33, F#4
	db $20, $C5               ; length 33, F4
	db $20, $C6               ; length 33, F#4
	db $20, $D0               ; length 33, C5
	db $20, $C6               ; length 33, F#4
	db $20, $D0               ; length 33, C5
	db $20, $D3               ; length 33, D#5
	db $20, $D2               ; length 33, D5
	db $20, $D1               ; length 33, C#5
	db $20, $8F, $20, $9D, $01, $B9 ; length 33, wave volume $20, wave 1, A3
	db $20, $B7               ; length 33, G3
	db $20, $B9               ; length 33, A3
	db $20, $BB               ; length 33, B3
	db $20, $B9               ; length 33, A3
	db $20, $CB               ; length 33, B4
	db $0F, $C0               ; length 16, C4
	db $00                  ; end

;@ path: sound/data
;@ Pointers to the two wave patterns of channel 3 (command $9D n picks pattern n).
WaveTable::
	dw WaveTriangle, WaveBuzz

;@ path: sound/data
;@ Wave pattern 0: 32 4-bit samples rising from 0 to 15 and falling back - a triangle wave (used
;@ by the jingle of the link-game loser).
WaveTriangle::
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

;@ path: sound/data
;@ Wave pattern 1: a rough, buzzing shape (the march beat, the link-game winner jingle, the unused tune).
WaveBuzz::
	db $FA, $84, $04, $8A, $FA, $84, $04, $8A, $FF, $88, $44, $00, $44, $88, $FF, $AA

;@ path: title/credit
;@ The developer credit shown at power-on: the logo made of tiles $60-$6E (CreditTiles, loaded to $9600) and the text "THE 2ND DEVELOPMENT SECTION OGR TEAM" in the font.
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
CreditScreenMap::
	db $98, $a6, $07          ; BG row 5, column 6: 7 tiles across tiles
	db $60, $61, $62, $63, $64, $65, $66
	db $98, $c6, $07          ; BG row 6, column 6: 7 tiles across tiles
	db $67, $68, $69, $6a, $6b, $6c, $6d
	db $98, $89, $01          ; BG row 4, column 9: 1 tiles across tiles
	db $6e
	db $99, $26, $07          ; BG row 9, column 6: 7 tiles across "THE 2ND"
	db $9d, $91, $8e, $a4, $82, $97, $8d
	db $99, $64, $0b          ; BG row 11, column 4: 11 tiles across "DEVELOPMENT"
	db $8d, $8e, $9f, $8e, $95, $98, $99, $96, $8e, $97, $9d
	db $99, $86, $07          ; BG row 12, column 6: 7 tiles across "SECTION"
	db $9c, $8e, $8c, $9d, $92, $98, $97
	db $99, $c6, $08          ; BG row 14, column 6: 8 tiles across "OGR TEAM"
	db $98, $90, $9b, $a4, $9d, $8e, $8a, $96
	db $00                    ; end of the list

;@ path: title/screen
;@ The title screen: the SPACE INVADERS logo (tiles $00-$4F of TitleTiles, 16 x 5) and, in the window map, "HI-SCORE", "(c) TAITO 1990" and "LICENSED BY NINTENDO".
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
TitleScreenMap::
	db $98, $62, $10          ; BG row 3, column 2: 16 tiles across tiles
	db $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f
	db $98, $82, $10          ; BG row 4, column 2: 16 tiles across tiles
	db $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f
	db $98, $a2, $10          ; BG row 5, column 2: 16 tiles across tiles
	db $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f
	db $98, $c2, $10          ; BG row 6, column 2: 16 tiles across tiles
	db $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f
	db $98, $e2, $10          ; BG row 7, column 2: 16 tiles across tiles
	db $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	db $9c, $04, $09          ; window row 0, column 4: 9 tiles across "HI-SCORE "
	db $91, $92, $b6, $9c, $8c, $98, $9b, $8e, $a4
	db $9c, $85, $0c          ; window row 4, column 5: 12 tiles across "(c) TAITO 1990"
	db $af, $a4, $9d, $8a, $92, $9d, $98, $a4, $81, $89, $89, $80
	db $9c, $c1, $14          ; window row 6, column 1: 20 tiles across "LICENSED BY NINTENDO"
	db $95, $92, $8c, $8e, $97, $9c, $8e, $8d, $a4, $8b, $a2, $a4, $97, $92, $97, $9d, $8e, $97, $8d, $98
	db $00                    ; end of the list

;@ path: text/demo
;@ The first line of the score-table demo, "P L A" - the Y is a sprite that an invader turns the right way up. Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=5 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextPla::
	db $99, $a4, $95, $a4, $8a   ; "P L A"

;@ path: text/demo
;@ Demo text "SPACE INVADERS". Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=14 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextSpaceInvaders::
	db $9c, $99, $8a, $8c, $8e, $a4, $92, $97, $9f, $8a, $8d, $8e, $9b, $9c   ; "SPACE INVADERS"

;@ path: text/demo
;@ Demo text "SCORE ADVANCE TABLE". Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=19 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextScoreAdvanceTable::
	db $9c, $8c, $98, $9b, $8e, $a4, $8a, $8d, $9f, $8a, $97, $8c, $8e, $a4, $9d, $8a, $8b, $95, $8e   ; "SCORE ADVANCE TABLE"

;@ path: text/demo
;@ Score table line of the UFO: "= ? MYSTERY" (the UFO itself is a sprite). Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=12 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextMystery::
	db $ab, $a4, $ad, $a4, $a4, $96, $a2, $9c, $9d, $8e, $9b, $a2   ; "= ?  MYSTERY"

;@ path: text/demo
;@ Score table: "= 30 POINTS" (top-row invader). Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=11 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
Text30Points::
	db $ab, $a4, $83, $80, $a4, $99, $98, $92, $97, $9d, $9c   ; "= 30 POINTS"

;@ path: text/demo
;@ Score table: "= 20 POINTS" (middle rows). Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=11 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
Text20Points::
	db $ab, $a4, $82, $80, $a4, $99, $98, $92, $97, $9d, $9c   ; "= 20 POINTS"

;@ path: text/demo
;@ Score table: "= 10 POINTS" (bottom rows). Raw font tiles, written one by one by TypeText (ShowScoreTableDemo).
;@ asset: tilemap width=11 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
Text10Points::
	db $ab, $a4, $81, $80, $a4, $99, $98, $92, $97, $9d, $9c   ; "= 10 POINTS"

;@ path: link/result
;@ "YOU WON !", typed on the link-game result screen of the winner. Raw font tiles, written one by one by TypeText (ShowLinkWin).
;@ asset: tilemap width=9 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextYouWon::
	db $a2, $98, $9e, $a4, $a0, $98, $97, $a4, $d9   ; "YOU WON !"

;@ path: link/result
;@ "YOU LOST!", typed on the link-game result screen of the loser. Raw font tiles, written one by one by TypeText (ShowLinkLoss).
;@ asset: tilemap width=9 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800) addressing=8800
TextYouLost::
	db $a2, $98, $9e, $a4, $95, $98, $9c, $9d, $d9   ; "YOU LOST!"

;@ path: title/menu
;@ The game-mode menu: "SELECT GAME MODE", "1 PLAYER", "2 PLAYER".
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
ModeMenuMap::
	db $98, $a2, $10          ; BG row 5, column 2: 16 tiles across "SELECT GAME MODE"
	db $9c, $8e, $95, $8e, $8c, $9d, $a4, $90, $8a, $96, $8e, $a4, $96, $98, $8d, $8e
	db $99, $26, $08          ; BG row 9, column 6: 8 tiles across "1 PLAYER"
	db $81, $a4, $99, $95, $8a, $a2, $8e, $9b
	db $99, $86, $08          ; BG row 12, column 6: 8 tiles across "2 PLAYER"
	db $82, $a4, $99, $95, $8a, $a2, $8e, $9b
	db $00                    ; end of the list

;@ path: game/screens
;@ The playfield of a one-player game: the top line "SCORE ... 0  S-" and the four shields (tiles $5A-$71, 2 rows of 3 tiles each, built in RAM and uploaded by the frame handler).
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
PlayfieldMap::
	db $98, $02, $12          ; BG row 0, column 2: 18 tiles across "SCORE     0  S-   "
	db $9c, $8c, $98, $9b, $8e, $a4, $a4, $a4, $a4, $a4, $80, $a4, $a4, $9c, $b6, $a4, $a4, $a4
	db $99, $c3, $0f          ; BG row 14, column 3: 15 tiles across tiles
	db $5a, $5c, $5e, $a4, $60, $62, $64, $a4, $66, $68, $6a, $a4, $6c, $6e, $70
	db $99, $e3, $0f          ; BG row 15, column 3: 15 tiles across tiles
	db $5b, $5d, $5f, $a4, $61, $63, $65, $a4, $67, $69, $6b, $a4, $6d, $6f, $71
	db $00                    ; end of the list

;@ path: link/screen
;@ The top line of a link game, drawn over PlayfieldMap: "E-", "RD-" and "S-" (the opponent's cannons, the round, the own stock).
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
LinkHeaderMap::
	db $98, $02, $0f          ; BG row 0, column 2: 15 tiles across "E-    RD-    S-"
	db $8e, $b6, $a4, $a4, $a4, $a4, $9b, $8d, $b6, $a4, $a4, $a4, $a4, $9c, $b6
	db $00                    ; end of the list

;@ path: shields/gfx
;@ The intact shield: 6 tiles (3 columns of 2, column by column: top left, bottom left, top middle ...).
;@ They are copied into each shield's RAM copy, where the hits cut craters into them.
;@ asset: tiles bpp=2
ShieldTiles::
	db $00, $00, $00, $00, $0f, $0f, $1f, $1f, $3f, $3f, $7f, $7f, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $fe, $fe, $fe, $fe, $fc, $fc, $fc, $fc, $fc, $fc
	db $00, $00, $00, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $0f, $0f, $07, $07, $07, $07, $03, $03, $03, $03, $03, $03
	db $00, $00, $00, $00, $00, $00, $80, $80, $c0, $c0, $e0, $e0, $f0, $f0, $f0, $f0
	db $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0

;@ path: text/sprites
;@ "READY!" as sprite tiles: shown by InitNewGame (6 sprites, one letter each).
;@ asset: tilemap width=6 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
TextReady::
	db $9b, $8e, $8a, $8d, $a2, $d9   ; "READY!"

;@ path: unused
;@ "ROUND" as sprite tiles; no code shows it.
;@ asset: tilemap width=5 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
TextRound::
	db $9b, $98, $9e, $97, $8d   ; "ROUND"

;@ path: text/sprites
;@ "PAUSE" as sprite tiles (ShowPause).
;@ asset: tilemap width=5 height=1 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
TextPause::
	db $99, $8a, $9e, $9c, $8e   ; "PAUSE"

;@ path: link/result
;@ Three lines of sprite text, each ended by $FF: "YOUR", "ENEMY", "CLEARED" - shown in a link game
;@ when the other player cleared the round.
;@ asset: rows newline=$FF length=$14 tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
TextYourEnemyCleared::
	db $a2, $98, $9e, $9b, $a4, $ff   ; "YOUR "
	db $8e, $97, $8e, $96, $a2, $ff   ; "ENEMY"
	db $8c, $95, $8e, $8a, $9b, $8e, $8d, $ff   ; "CLEARED"

;@ path: game/start
;@ The sprite table at the start of a one-player round, copied to wShadowOam up to the $FF: the cannon, the shots and bombs (hidden) and the other objects.
;@ asset: oam end=$FF tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
SoloStartOam::
	db $98, $20, $00, $20   ; Y 152, X  32, tile $00, flipped
	db $00, $f8, $01, $20   ; Y   0, X 248, tile $01, flipped
	db $98, $18, $00, $00   ; Y 152, X  24, tile $00
	db $00, $f0, $01, $00   ; Y   0, X 240, tile $01
	db $00, $00, $02, $00   ; Y   0, X   0, tile $02
	db $f0, $f0, $a4, $00   ; Y 240, X 240, tile $A4
	db $00, $00, $03, $00   ; Y   0, X   0, tile $03
	db $00, $00, $04, $00   ; Y   0, X   0, tile $04
	db $00, $00, $02, $00   ; Y   0, X   0, tile $02
	db $00, $00, $a4, $00   ; Y   0, X   0, tile $A4
	db $10, $48, $80, $00   ; Y  16, X  72, tile $80
	db $10, $50, $80, $00   ; Y  16, X  80, tile $80
	db $10, $58, $80, $00   ; Y  16, X  88, tile $80
	db $10, $60, $80, $00   ; Y  16, X  96, tile $80
	db $10, $90, $80, $00   ; Y  16, X 144, tile $80
	db $ff                   ; end

;@ path: link/start
;@ The sprite table at the start of a link-game round (the opponent's cannon at the top instead of the UFO).
;@ asset: oam end=$FF tiles=CopyBytes(hl=SpriteTiles,de=$8000,bc=$1800)
LinkStartOam::
	db $98, $20, $00, $20   ; Y 152, X  32, tile $00, flipped
	db $18, $98, $05, $20   ; Y  24, X 152, tile $05, flipped
	db $98, $18, $00, $00   ; Y 152, X  24, tile $00
	db $18, $90, $05, $00   ; Y  24, X 144, tile $05
	db $f0, $f0, $02, $00   ; Y 240, X 240, tile $02
	db $f0, $f0, $02, $00   ; Y 240, X 240, tile $02
	db $f0, $f0, $03, $00   ; Y 240, X 240, tile $03
	db $f0, $f0, $04, $00   ; Y 240, X 240, tile $04
	db $f0, $f0, $02, $00   ; Y 240, X 240, tile $02
	db $f0, $f0, $a4, $00   ; Y 240, X 240, tile $A4
	db $f0, $f0, $a4, $00   ; Y 240, X 240, tile $A4
	db $10, $28, $80, $00   ; Y  16, X  40, tile $80
	db $f0, $f0, $a4, $00   ; Y 240, X 240, tile $A4
	db $10, $60, $80, $00   ; Y  16, X  96, tile $80
	db $10, $90, $80, $00   ; Y  16, X 144, tile $80
	db $ff                   ; end

;@ path: link/menu
;@ The link-game menu: "WEAPON STOCK", "1 WEAPON", "3 WEAPONS", "5 WEAPONS".
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
StockMenuMap::
	db $98, $83, $0c          ; BG row 4, column 3: 12 tiles across "WEAPON STOCK"
	db $a0, $8e, $8a, $99, $98, $97, $a4, $9c, $9d, $98, $8c, $94
	db $98, $e5, $08          ; BG row 7, column 5: 8 tiles across "1 WEAPON"
	db $81, $a4, $a0, $8e, $8a, $99, $98, $97
	db $99, $25, $09          ; BG row 9, column 5: 9 tiles across "3 WEAPONS"
	db $83, $a4, $a0, $8e, $8a, $99, $98, $97, $9c
	db $99, $65, $09          ; BG row 11, column 5: 9 tiles across "5 WEAPONS"
	db $85, $a4, $a0, $8e, $8a, $99, $98, $97, $9c
	db $00                    ; end of the list

;@ path: ufo/score
;@ What the UFO is worth, in tens of points (BCD), picked by hShotCount (the shots fired so far, 1-15
;@ round and round): 50, 50, 100, 150, 100, 100, 50, 300, 100, 100, 50, 50, 150, 100, 100. Entry 0 is
;@ never used. A UFO hit with the 8th shot (and every 15th after it) is worth 300.
UfoPointsTable::
	db $00, $05, $05, $10, $15, $10, $10, $05, $30, $10, $10, $05, $05, $15, $10, $10   ; 0, 50, 50, 100, 150, 100, 100, 50, 300, ...

;@ path: score/lives
;@ The scores (BCD, high byte first, in tens of points like hScoreHi/hScoreLo) at which an extra cannon
;@ is given: 6500, 11500, 16500, 20000 and 68000 points; $FFFF ends the list.
ExtraCannonScores::
	db $06, $50   ; 6500 points
	db $11, $50   ; 11500
	db $16, $50   ; 16500
	db $20, $00   ; 20000
	db $68, $00   ; 68000
	db $ff, $ff   ; end

;@ path: game/over
;@ "GAME OVER" in the middle of the screen.
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
GameOverMap::
	db $99, $05, $09          ; BG row 8, column 5: 9 tiles across "GAME OVER"
	db $90, $8a, $96, $8e, $a4, $98, $9f, $8e, $9b
	db $00                    ; end of the list

;@ path: game/over
;@ "YOU GET HI-SCORE !", shown after a game that set a new hi-score.
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
HiScoreMap::
	db $98, $c8, $03          ; BG row 6, column 8: 3 tiles across "YOU"
	db $a2, $98, $9e
	db $99, $08, $03          ; BG row 8, column 8: 3 tiles across "GET"
	db $90, $8e, $9d
	db $99, $46, $0a          ; BG row 10, column 6: 10 tiles across "HI-SCORE !"
	db $91, $92, $b6, $9c, $8c, $98, $9b, $8e, $a4, $d9
	db $00                    ; end of the list

;@ path: game/coffeebreak
;@ The first coffee break (after round 10): "COFFEE BREAK!", "LET'S START THE NEXT GAME!" and a picture of tiles $00-$39 (CoffeeBreak1Tiles).
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
CoffeeBreak1Map::
	db $98, $83, $06          ; BG row 4, column 3: 6 tiles across "COFFEE"
	db $8c, $98, $8f, $8f, $8e, $8e
	db $98, $ad, $02          ; BG row 5, column 13: 2 tiles across tiles
	db $00, $01
	db $98, $c4, $06          ; BG row 6, column 4: 6 tiles across "BREAK!"
	db $8b, $9b, $8e, $8a, $94, $d9
	db $98, $cd, $04          ; BG row 6, column 13: 4 tiles across tiles
	db $02, $03, $04, $05
	db $98, $ed, $04          ; BG row 7, column 13: 4 tiles across tiles
	db $06, $07, $08, $09
	db $99, $0b, $08          ; BG row 8, column 11: 8 tiles across tiles
	db $0a, $0b, $0c, $0d, $0e, $0f, $10, $11
	db $99, $83, $05          ; BG row 12, column 3: 5 tiles across "LET'S"
	db $95, $8e, $9d, $ae, $9c
	db $99, $a3, $05          ; BG row 13, column 3: 5 tiles across "START"
	db $9c, $9d, $8a, $9b, $9d
	db $99, $2b, $08          ; BG row 9, column 11: 8 tiles across tiles
	db $12, $13, $14, $15, $16, $17, $18, $19
	db $99, $4b, $08          ; BG row 10, column 11: 8 tiles across tiles
	db $1a, $1b, $1c, $1d, $1e, $1f, $20, $21
	db $99, $e3, $0e          ; BG row 15, column 3: 14 tiles across "THE NEXT GAME!"
	db $9d, $91, $8e, $a4, $97, $8e, $a1, $9d, $a4, $90, $8a, $96, $8e, $d9
	db $99, $6b, $08          ; BG row 11, column 11: 8 tiles across tiles
	db $22, $23, $24, $25, $26, $27, $28, $29
	db $99, $8b, $08          ; BG row 12, column 11: 8 tiles across tiles
	db $2a, $2b, $2c, $2d, $2e, $2f, $30, $31
	db $99, $ab, $08          ; BG row 13, column 11: 8 tiles across tiles
	db $32, $33, $34, $35, $36, $37, $38, $39
	db $00                    ; end of the list

;@ path: game/coffeebreak
;@ The second coffee break (after round 20): the same text and a larger picture of tiles $00-$60 (CoffeeBreak2Tiles).
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
CoffeeBreak2Map::
	db $98, $41, $0c          ; BG row 2, column 1: 12 tiles across "COFFEE BREAK"
	db $8c, $98, $8f, $8f, $8e, $8e, $a4, $8b, $9b, $8e, $8a, $94
	db $98, $82, $0c          ; BG row 4, column 2: 12 tiles across "LET'S START "
	db $95, $8e, $9d, $ae, $9c, $a4, $9c, $9d, $8a, $9b, $9d, $a4
	db $98, $a4, $0e          ; BG row 5, column 4: 14 tiles across "THE NEXT GAME!"
	db $9d, $91, $8e, $a4, $97, $8e, $a1, $9d, $a4, $90, $8a, $96, $8e, $d9
	db $98, $cc, $02          ; BG row 6, column 12: 2 tiles across tiles
	db $00, $01
	db $98, $eb, $02          ; BG row 7, column 11: 2 tiles across tiles
	db $02, $03
	db $99, $0a, $03          ; BG row 8, column 10: 3 tiles across tiles
	db $04, $05, $06
	db $99, $28, $04          ; BG row 9, column 8: 4 tiles across tiles
	db $07, $08, $09, $0a
	db $99, $2e, $06          ; BG row 9, column 14: 6 tiles across tiles
	db $07, $0b, $0c, $0d, $0e, $0f
	db $99, $45, $06          ; BG row 10, column 5: 6 tiles across tiles
	db $10, $11, $12, $13, $14, $15
	db $99, $4d, $07          ; BG row 10, column 13: 7 tiles across tiles
	db $16, $17, $18, $19, $1a, $1b, $1c
	db $99, $64, $10          ; BG row 11, column 4: 16 tiles across tiles
	db $1d, $1e, $1f, $20, $21, $22, $06, $07, $23, $24, $25, $26, $27, $28, $29, $2a
	db $99, $83, $11          ; BG row 12, column 3: 17 tiles across tiles
	db $2b, $2c, $2d, $2e, $2f, $30, $31, $a4, $32, $24, $33, $26, $34, $28, $35, $36, $37
	db $99, $a3, $11          ; BG row 13, column 3: 17 tiles across tiles
	db $38, $39, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $26, $26, $42, $43, $44, $37, $37
	db $99, $c3, $11          ; BG row 14, column 3: 17 tiles across tiles
	db $45, $46, $47, $48, $49, $4a, $a4, $4b, $24, $4c, $26, $1a, $4d, $4e, $2a, $37, $37
	db $99, $e3, $11          ; BG row 15, column 3: 17 tiles across tiles
	db $4f, $50, $51, $52, $53, $a4, $54, $40, $55, $26, $26, $56, $57, $58, $37, $37, $37
	db $9a, $03, $03          ; BG row 16, column 3: 3 tiles across tiles
	db $59, $5a, $5b
	db $9a, $09, $0b          ; BG row 16, column 9: 11 tiles across tiles
	db $5c, $24, $5d, $26, $26, $5e, $57, $5f, $37, $37, $37
	db $9a, $29, $0b          ; BG row 17, column 9: 11 tiles across tiles
	db $60, $24, $5d, $26, $26, $5e, $57, $5f, $37, $37, $37
	db $00                    ; end of the list
;@ path: link/result
;@ The bottom four rows of the link-game result screens (tiles $00-$4F of LinkResultTiles), under the invaders that rise into a V or an X.
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
LinkResultMap::
	db $99, $c0, $14          ; BG row 14, column 0: 20 tiles across tiles
	db $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0a, $0b, $0c, $0d, $0e, $0f, $10, $11, $12, $13
	db $99, $e0, $14          ; BG row 15, column 0: 20 tiles across tiles
	db $14, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d, $1e, $1f, $20, $21, $22, $23, $24, $25, $26, $27
	db $9a, $00, $14          ; BG row 16, column 0: 20 tiles across tiles
	db $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b
	db $9a, $20, $14          ; BG row 17, column 0: 20 tiles across tiles
	db $3c, $3d, $3e, $3f, $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
	db $00                    ; end of the list

;@ path: game/ending
;@ The ending after round 30: a whole screen (20 x 18 tiles of EndingTiles, row by row) with a picture in the lower half.
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
EndingMap::
	db $98, $00, $14          ; BG row 0, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $20, $14          ; BG row 1, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $40, $14          ; BG row 2, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $60, $14          ; BG row 3, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $80, $14          ; BG row 4, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $a0, $14          ; BG row 5, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $98, $c0, $14          ; BG row 6, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $02, $03, $04, $05, $06, $07, $08, $09, $01, $01, $01, $01, $01, $01
	db $98, $e0, $14          ; BG row 7, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $99, $00, $14          ; BG row 8, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $99, $20, $14          ; BG row 9, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01
	db $99, $40, $14          ; BG row 10, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $0a, $0b, $0c, $0d, $01, $01, $01, $01, $01, $01, $01, $01
	db $99, $60, $14          ; BG row 11, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $0e, $01, $0f, $10, $01, $01, $01, $01, $01, $01, $01, $01
	db $99, $80, $14          ; BG row 12, column 0: 20 tiles across tiles
	db $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $11
	db $99, $a0, $14          ; BG row 13, column 0: 20 tiles across tiles
	db $12, $13, $14, $01, $01, $01, $01, $01, $01, $01, $01, $15, $16, $17, $18, $19, $1a, $1b, $1c, $1d
	db $99, $c0, $14          ; BG row 14, column 0: 20 tiles across tiles
	db $1e, $1f, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2a, $2b, $2c, $2d, $2e, $2f, $30, $31
	db $99, $e0, $14          ; BG row 15, column 0: 20 tiles across tiles
	db $32, $33, $34, $35, $36, $37, $38, $39, $3a, $3b, $3c, $3d, $3e, $3f, $40, $41, $42, $43, $44, $45
	db $9a, $00, $14          ; BG row 16, column 0: 20 tiles across tiles
	db $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f, $50, $51, $52, $53, $54, $55, $56, $57, $58, $01
	db $9a, $20, $14          ; BG row 17, column 0: 20 tiles across tiles
	db $59, $5a, $5b, $5c, $5d, $5e, $6f, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6a, $01, $01
	db $00                    ; end of the list

;@ path: unused
;@ Four tilemap lists that nothing draws: each writes 8 tiles at row 6, column 5 (tile $82 eight times, then tiles $6A-$71, $72-$79 and $7A-$81).
;@ A tilemap list for DrawTilemapList: per entry the BG-map address (high byte first), a control byte (bits 7-6 mode, bits 5-0 count) and the tiles.
UnusedBannerMaps::
	db $98, $c5, $08          ; BG row 6, column 5: 8 tiles across "22222222"
	db $82, $82, $82, $82, $82, $82, $82, $82
	db $00                    ; end of the list
	db $98, $c5, $08          ; BG row 6, column 5: 8 tiles across tiles
	db $6a, $6b, $6c, $6d, $6e, $6f, $70, $71
	db $00                    ; end of the list
	db $98, $c5, $08          ; BG row 6, column 5: 8 tiles across tiles
	db $72, $73, $74, $75, $76, $77, $78, $79
	db $00                    ; end of the list
	db $98, $c5, $08          ; BG row 6, column 5: 8 tiles across tiles
	db $7a, $7b, $7c, $7d, $7e, $7f, $80, $81
	db $00                    ; end of the list

;@ path: invaders/formation
;@ How many rows lower the formation starts, indexed by hRound - 1 with hRound in BCD: round 1 = entry
;@ 0, round 9 = entry 8, round 10 = entry $0F, round 11 = entry $10 ... (entries 9-14 of each 16 are the
;@ unused BCD gaps). Rounds 1-10: 1, 1, 2, 2, 3, 3, 4, 4, 5, 5; rounds 11-20 one row lower, 21-30 two rows.
FormationDropTable::
	db $01, $01, $02, $02, $03, $03, $04, $04, $05, $00, $00, $00, $00, $00, $00, $05   ; rounds 1-10
	db $02, $02, $03, $03, $04, $04, $05, $05, $06, $00, $00, $00, $00, $00, $00, $06   ; rounds 11-20
	db $03, $03, $04, $04, $05, $05, $06, $06, $07, $00, $00, $00, $00, $00, $00, $07   ; rounds 21-30

;@ path: link/result
;@ 19 invaders (Y, X, tile) that rise from below the screen into a V on the winner's screen; each becomes two sprites side by side (tile and tile + 1). ShowLinkWin moves them up 2 pixels a step until the first one reaches Y 32.
LinkWinFormation::
	db $9e, $28, $28   ; Y 158, X  40, tile $28
	db $a6, $28, $28   ; Y 166, X  40, tile $28
	db $ae, $28, $28   ; Y 174, X  40, tile $28
	db $b6, $28, $28   ; Y 182, X  40, tile $28
	db $be, $28, $28   ; Y 190, X  40, tile $28
	db $c6, $30, $24   ; Y 198, X  48, tile $24
	db $ce, $38, $24   ; Y 206, X  56, tile $24
	db $d6, $40, $24   ; Y 214, X  64, tile $24
	db $de, $48, $20   ; Y 222, X  72, tile $20
	db $e6, $50, $20   ; Y 230, X  80, tile $20
	db $9e, $78, $28   ; Y 158, X 120, tile $28
	db $a6, $78, $28   ; Y 166, X 120, tile $28
	db $ae, $78, $28   ; Y 174, X 120, tile $28
	db $b6, $78, $28   ; Y 182, X 120, tile $28
	db $be, $78, $28   ; Y 190, X 120, tile $28
	db $c6, $70, $24   ; Y 198, X 112, tile $24
	db $ce, $68, $24   ; Y 206, X 104, tile $24
	db $d6, $60, $24   ; Y 214, X  96, tile $24
	db $de, $58, $20   ; Y 222, X  88, tile $20

;@ path: link/result
;@ 17 invaders (Y, X, tile) that rise into an X on the loser's screen (ShowLinkLoss, until the first one reaches Y 40).
LinkLossFormation::
	db $a6, $30, $28   ; Y 166, X  48, tile $28
	db $ae, $38, $28   ; Y 174, X  56, tile $28
	db $b6, $40, $24   ; Y 182, X  64, tile $24
	db $be, $48, $24   ; Y 190, X  72, tile $24
	db $c6, $51, $20   ; Y 198, X  81, tile $20
	db $ce, $58, $24   ; Y 206, X  88, tile $24
	db $d6, $60, $24   ; Y 214, X  96, tile $24
	db $de, $68, $28   ; Y 222, X 104, tile $28
	db $e6, $70, $28   ; Y 230, X 112, tile $28
	db $a6, $70, $28   ; Y 166, X 112, tile $28
	db $ae, $68, $28   ; Y 174, X 104, tile $28
	db $b6, $60, $24   ; Y 182, X  96, tile $24
	db $be, $58, $24   ; Y 190, X  88, tile $24
	db $ce, $48, $24   ; Y 206, X  72, tile $24
	db $d6, $40, $24   ; Y 214, X  64, tile $24
	db $de, $38, $28   ; Y 222, X  56, tile $28
	db $e6, $30, $28   ; Y 230, X  48, tile $28

;@ path: gfx/tiles
;@ Tiles $00-$7F at $8000, the sprites: the cannon, shots, bombs and explosions, the UFO, the three
;@ kinds of invaders in two frames (two tiles side by side), the Y of the score-table demo and
;@ "THE END" in three shades for the ending. Power-on copies $1800 bytes from here to $8000-$97FF in
;@ one go: this block, FontTiles and the $800 bytes after them.
;@ asset: tiles bpp=2
SpriteTiles::
	db $00, $00, $00, $00, $01, $01, $03, $03
	db $0f, $0f, $1f, $1f, $1f, $1f, $1f, $1f, $00, $00, $00, $00, $01, $01, $03, $03
	db $0f, $0f, $1a, $1a, $0f, $0f, $05, $05, $08, $18, $08, $18, $08, $18, $10, $18
	db $10, $18, $10, $18, $00, $00, $00, $00, $10, $30, $08, $18, $04, $0c, $08, $18
	db $10, $18, $08, $0c, $00, $00, $00, $00, $10, $18, $08, $0c, $10, $18, $08, $18
	db $10, $30, $08, $18, $00, $00, $00, $00, $00, $00, $01, $01, $03, $03, $05, $05
	db $0f, $0f, $15, $15, $0f, $0f, $05, $05, $00, $00, $08, $08, $05, $05, $00, $00
	db $0d, $0d, $15, $15, $27, $27, $af, $af, $40, $40, $00, $00, $40, $40, $48, $48
	db $82, $82, $e0, $e0, $f8, $f8, $fc, $fc, $20, $20, $98, $98, $03, $03, $40, $40
	db $8c, $8c, $23, $23, $0f, $0f, $4f, $4f, $08, $08, $41, $41, $08, $08, $40, $40
	db $d2, $d2, $84, $84, $f8, $f8, $ec, $ec, $04, $04, $11, $11, $2c, $2c, $1e, $1e
	db $1d, $1d, $3e, $3e, $1d, $1d, $2a, $2a, $94, $94, $43, $43, $06, $06, $1c, $1c
	db $b9, $b9, $0c, $0c, $46, $46, $90, $90, $21, $21, $02, $02, $38, $38, $f8, $f8
	db $6d, $6d, $78, $78, $12, $12, $49, $49, $0f, $0f, $7f, $7f, $ff, $ff, $e6, $e6
	db $ff, $ff, $19, $19, $36, $36, $c0, $c0, $00, $00, $e0, $e0, $f0, $f0, $70, $70
	db $f0, $f0, $80, $80, $c0, $c0, $30, $30, $0f, $0f, $7f, $7f, $ff, $ff, $e6, $e6
	db $ff, $ff, $39, $39, $66, $66, $30, $30, $00, $00, $e0, $e0, $f0, $f0, $70, $70
	db $f0, $f0, $c0, $c0, $60, $60, $c0, $c0, $20, $20, $91, $91, $bf, $bf, $ee, $ee
	db $ff, $ff, $7f, $7f, $20, $20, $40, $40, $80, $80, $20, $20, $a0, $a0, $e0, $e0
	db $e0, $e0, $c0, $c0, $80, $80, $40, $40, $20, $20, $11, $11, $3f, $3f, $6e, $6e
	db $ff, $ff, $bf, $bf, $a0, $a0, $1b, $1b, $80, $80, $00, $00, $80, $80, $c0, $c0
	db $e0, $e0, $a0, $a0, $a0, $a0, $00, $00, $99, $99, $42, $42, $24, $24, $81, $81
	db $81, $81, $24, $24, $42, $42, $99, $99, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $24, $24, $5a, $5a, $a5, $a5, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $5a, $5a, $81, $81, $42, $42, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $20, $20, $91, $91, $bf, $bf, $ee, $ee
	db $ff, $ff, $7f, $7f, $20, $20, $40, $40, $80, $80, $20, $20, $a0, $a0, $e0, $e0
	db $e0, $e0, $c0, $c0, $80, $80, $40, $40, $20, $20, $11, $11, $3f, $3f, $6e, $6e
	db $ff, $ff, $bf, $bf, $a0, $a0, $1b, $1b, $80, $80, $00, $00, $80, $80, $c0, $c0
	db $e0, $e0, $a0, $a0, $a0, $a0, $00, $00, $0f, $0f, $7f, $7f, $ff, $ff, $e6, $e6
	db $ff, $ff, $19, $19, $36, $36, $c0, $c0, $00, $00, $e0, $e0, $f0, $f0, $70, $70
	db $f0, $f0, $80, $80, $c0, $c0, $30, $30, $0f, $0f, $7f, $7f, $ff, $ff, $e6, $e6
	db $ff, $ff, $39, $39, $66, $66, $30, $30, $00, $00, $e0, $e0, $f0, $f0, $70, $70
	db $f0, $f0, $c0, $c0, $60, $60, $c0, $c0, $00, $00, $07, $07, $1f, $1f, $3f, $3f
	db $6d, $6d, $ff, $ff, $39, $39, $10, $10, $00, $00, $18, $18, $18, $18, $18, $18
	db $18, $18, $2c, $2c, $46, $46, $00, $00, $00, $00, $46, $46, $2c, $2c, $18, $18
	db $18, $18, $18, $18, $18, $18, $00, $00, $00, $00, $00, $00, $04, $04, $02, $02
	db $01, $01, $00, $00, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $24, $24, $5a, $5a, $a5, $a5, $00, $00, $00, $00, $04, $04, $02, $02
	db $01, $01, $00, $00, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $5a, $5a, $81, $81, $42, $42, $00, $00, $00, $00, $01, $01, $03, $03
	db $0f, $0f, $1a, $1a, $0f, $0f, $05, $05, $00, $00, $00, $00, $00, $00, $01, $01
	db $02, $02, $04, $0c, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $24, $24, $5a, $5a, $a5, $a5, $00, $00, $00, $00, $00, $00, $01, $01
	db $02, $02, $04, $0c, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $5a, $5a, $81, $81, $42, $42, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $3c, $3c, $42, $42, $b9, $b9, $a5, $a5
	db $b9, $b9, $a5, $a5, $42, $42, $3c, $3c, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $e7, $e7, $e7, $e7
	db $e7, $e7, $e7, $e7, $e7, $e7, $e7, $e7, $9e, $9e, $9e, $9e, $9e, $9e, $80, $80
	db $80, $80, $9e, $9e, $9e, $9e, $9e, $9e, $40, $40, $40, $40, $4f, $4f, $40, $40
	db $40, $40, $4f, $4f, $40, $40, $40, $40, $3f, $3f, $3f, $3f, $ff, $ff, $3f, $3f
	db $3f, $3f, $ff, $ff, $3f, $3f, $3f, $3f, $00, $00, $00, $00, $3f, $3f, $00, $00
	db $00, $00, $3f, $3f, $00, $00, $00, $00, $9e, $9e, $8e, $8e, $86, $86, $82, $82
	db $90, $90, $98, $98, $9c, $9c, $9e, $9e, $40, $40, $40, $40, $4e, $4e, $4f, $4f
	db $4f, $4f, $4e, $4e, $40, $40, $40, $40, $ff, $ff, $7f, $7f, $3f, $3f, $3f, $3f
	db $3f, $3f, $3f, $3f, $7f, $7f, $ff, $ff, $ff, $00, $ff, $00, $ff, $e7, $ff, $e7
	db $ff, $e7, $ff, $e7, $ff, $e7, $ff, $e7, $ff, $9e, $ff, $9e, $ff, $9e, $ff, $80
	db $ff, $80, $ff, $9e, $ff, $9e, $ff, $9e, $ff, $40, $ff, $40, $ff, $4f, $ff, $40
	db $ff, $40, $ff, $4f, $ff, $40, $ff, $40, $ff, $3f, $ff, $3f, $ff, $ff, $ff, $3f
	db $ff, $3f, $ff, $ff, $ff, $3f, $ff, $3f, $ff, $00, $ff, $00, $ff, $3f, $ff, $00
	db $ff, $00, $ff, $3f, $ff, $00, $ff, $00, $ff, $9e, $ff, $8e, $ff, $86, $ff, $82
	db $ff, $90, $ff, $98, $ff, $9c, $ff, $9e, $ff, $40, $ff, $40, $ff, $4e, $ff, $4f
	db $ff, $4f, $ff, $4e, $ff, $40, $ff, $40, $ff, $ff, $ff, $7f, $ff, $3f, $ff, $3f
	db $ff, $3f, $ff, $3f, $ff, $7f, $ff, $ff, $00, $ff, $00, $ff, $e7, $ff, $e7, $ff
	db $e7, $ff, $e7, $ff, $e7, $ff, $e7, $ff, $9e, $ff, $9e, $ff, $9e, $ff, $80, $ff
	db $80, $ff, $9e, $ff, $9e, $ff, $9e, $ff, $40, $ff, $40, $ff, $4f, $ff, $40, $ff
	db $40, $ff, $4f, $ff, $40, $ff, $40, $ff, $3f, $ff, $3f, $ff, $ff, $ff, $3f, $ff
	db $3f, $ff, $ff, $ff, $3f, $ff, $3f, $ff, $00, $ff, $00, $ff, $3f, $ff, $00, $ff
	db $00, $ff, $3f, $ff, $00, $ff, $00, $ff, $9e, $ff, $8e, $ff, $86, $ff, $82, $ff
	db $90, $ff, $98, $ff, $9c, $ff, $9e, $ff, $40, $ff, $40, $ff, $4e, $ff, $4f, $ff
	db $4f, $ff, $4e, $ff, $40, $ff, $40, $ff, $ff, $ff, $7f, $ff, $3f, $ff, $3f, $ff
	db $3f, $ff, $3f, $ff, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

;@ path: gfx/tiles
;@ Tiles $80-$FF at $8800, shared by sprites and background: digits $80-$89, letters A-Z $8A-$A3,
;@ the blank $A4, three grey blocks, signs (= $AB, * $AC, ? $AD, ' $AE, (c) $AF, - $B6, ! $D9),
;@ frame pieces, and the formation's invaders as background tiles.
;@ asset: tiles bpp=2
FontTiles::
	db $00, $00, $3c, $3c, $66, $66, $6e, $6e
	db $76, $76, $66, $66, $3c, $3c, $00, $00, $00, $00, $18, $18, $38, $38, $18, $18
	db $18, $18, $18, $18, $3c, $3c, $00, $00, $00, $00, $3c, $3c, $66, $66, $0c, $0c
	db $38, $38, $60, $60, $7e, $7e, $00, $00, $00, $00, $7e, $7e, $08, $08, $3c, $3c
	db $06, $06, $66, $66, $3c, $3c, $00, $00, $00, $00, $1c, $1c, $2c, $2c, $4c, $4c
	db $7e, $7e, $0c, $0c, $0c, $0c, $00, $00, $00, $00, $7c, $7c, $40, $40, $7c, $7c
	db $06, $06, $66, $66, $3c, $3c, $00, $00, $00, $00, $3c, $3c, $60, $60, $7c, $7c
	db $66, $66, $66, $66, $3c, $3c, $00, $00, $00, $00, $7e, $7e, $66, $66, $0c, $0c
	db $18, $18, $18, $18, $18, $18, $00, $00, $00, $00, $3c, $3c, $66, $66, $3c, $3c
	db $66, $66, $66, $66, $3c, $3c, $00, $00, $00, $00, $3c, $3c, $66, $66, $66, $66
	db $3e, $3e, $06, $06, $3c, $3c, $00, $00, $00, $00, $18, $18, $3c, $3c, $66, $66
	db $7e, $7e, $66, $66, $66, $66, $00, $00, $00, $00, $7c, $7c, $66, $66, $7c, $7c
	db $66, $66, $66, $66, $7e, $7e, $00, $00, $00, $00, $3c, $3c, $66, $66, $60, $60
	db $60, $60, $66, $66, $3c, $3c, $00, $00, $00, $00, $7c, $7c, $66, $66, $66, $66
	db $66, $66, $66, $66, $7c, $7c, $00, $00, $00, $00, $7e, $7e, $60, $60, $7c, $7c
	db $60, $60, $60, $60, $7e, $7e, $00, $00, $00, $00, $7e, $7e, $60, $60, $7c, $7c
	db $60, $60, $60, $60, $60, $60, $00, $00, $00, $00, $3c, $3c, $66, $66, $60, $60
	db $6e, $6e, $66, $66, $3e, $3e, $00, $00, $00, $00, $66, $66, $66, $66, $7e, $7e
	db $66, $66, $66, $66, $66, $66, $00, $00, $00, $00, $3c, $3c, $18, $18, $18, $18
	db $18, $18, $18, $18, $3c, $3c, $00, $00, $00, $00, $1e, $1e, $0c, $0c, $0c, $0c
	db $0c, $0c, $6c, $6c, $38, $38, $00, $00, $00, $00, $66, $66, $6c, $6c, $78, $78
	db $7c, $7c, $6e, $6e, $66, $66, $00, $00, $00, $00, $60, $60, $60, $60, $60, $60
	db $60, $60, $60, $60, $7e, $7e, $00, $00, $00, $00, $62, $62, $76, $76, $7e, $7e
	db $6a, $6a, $62, $62, $62, $62, $00, $00, $00, $00, $66, $66, $76, $76, $7e, $7e
	db $6e, $6e, $66, $66, $66, $66, $00, $00, $00, $00, $3c, $3c, $66, $66, $66, $66
	db $66, $66, $66, $66, $3c, $3c, $00, $00, $00, $00, $7c, $7c, $66, $66, $66, $66
	db $7c, $7c, $60, $60, $60, $60, $00, $00, $00, $00, $3c, $3c, $66, $66, $66, $66
	db $7e, $7e, $64, $64, $3a, $3a, $00, $00, $00, $00, $7c, $7c, $66, $66, $66, $66
	db $7c, $7c, $66, $66, $66, $66, $00, $00, $00, $00, $3c, $3c, $66, $66, $38, $38
	db $0c, $0c, $66, $66, $3c, $3c, $00, $00, $00, $00, $7e, $7e, $18, $18, $18, $18
	db $18, $18, $18, $18, $18, $18, $00, $00, $00, $00, $66, $66, $66, $66, $66, $66
	db $66, $66, $66, $66, $3c, $3c, $00, $00, $00, $00, $62, $62, $62, $62, $62, $62
	db $62, $62, $34, $34, $18, $18, $00, $00, $00, $00, $62, $62, $6a, $6a, $6a, $6a
	db $6a, $6a, $7e, $7e, $34, $34, $00, $00, $00, $00, $62, $62, $74, $74, $38, $38
	db $1c, $1c, $2e, $2e, $46, $46, $00, $00, $00, $00, $62, $62, $76, $76, $3c, $3c
	db $18, $18, $18, $18, $18, $18, $00, $00, $00, $00, $7e, $7e, $0c, $0c, $18, $18
	db $30, $30, $60, $60, $7e, $7e, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $00, $ff, $00, $ff, $00, $ff, $00, $ff
	db $00, $ff, $00, $ff, $00, $ff, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $7e, $7e, $00, $00
	db $00, $00, $7e, $7e, $00, $00, $00, $00, $00, $00, $18, $18, $5a, $5a, $3c, $3c
	db $7e, $7e, $3c, $3c, $5a, $5a, $00, $00, $00, $00, $3c, $3c, $46, $46, $0c, $0c
	db $18, $18, $00, $00, $18, $18, $00, $00, $60, $60, $60, $60, $20, $20, $40, $40
	db $80, $80, $00, $00, $00, $00, $00, $00, $3c, $3c, $42, $42, $99, $99, $a1, $a1
	db $a1, $a1, $99, $99, $42, $42, $3c, $3c, $ff, $ff, $80, $80, $80, $80, $80, $80
	db $80, $80, $80, $80, $80, $80, $80, $80, $ff, $ff, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $80, $80, $80, $80, $80, $80, $80, $80
	db $80, $80, $80, $80, $80, $80, $80, $80, $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $ff, $ff, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80, $80, $80, $80, $80
	db $80, $80, $80, $80, $80, $80, $ff, $ff, $00, $00, $00, $00, $00, $00, $7e, $7e
	db $7e, $7e, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $ff, $ff, $03, $03, $0c, $0c, $10, $10, $20, $20
	db $40, $40, $40, $40, $80, $80, $80, $80, $c0, $c0, $30, $30, $08, $08, $04, $04
	db $02, $02, $02, $02, $01, $01, $01, $01, $80, $80, $80, $80, $40, $40, $40, $40
	db $20, $20, $10, $10, $0c, $0c, $03, $03, $01, $01, $01, $01, $02, $02, $02, $02
	db $04, $04, $08, $08, $30, $30, $c0, $c0, $00, $00, $00, $00, $0f, $0f, $1f, $1f
	db $3f, $3f, $7f, $7f, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $80, $80
	db $c0, $c0, $e0, $e0, $f0, $f0, $f0, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $fe
	db $fe, $fe, $fc, $fc, $fc, $fc, $fc, $fc, $ff, $ff, $ff, $ff, $0f, $0f, $07, $07
	db $07, $07, $03, $03, $03, $03, $03, $03, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0
	db $f0, $f0, $f0, $f0, $f0, $f0, $f0, $f0, $40, $40, $40, $40, $38, $38, $0f, $0f
	db $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $06, $06, $1c, $1c, $f0, $f0
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $0f, $0f, $3f, $3f, $7f, $7f, $7f, $7f, $00, $00, $00, $00, $00, $00, $00, $00
	db $f0, $f0, $fc, $fc, $fe, $fe, $fe, $fe, $7f, $7f, $7f, $7f, $3f, $3f, $0f, $0f
	db $00, $00, $00, $00, $00, $00, $00, $00, $fe, $fe, $fe, $fe, $fc, $fc, $f0, $f0
	db $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $7e, $7e, $ff, $ff, $99, $99
	db $ff, $ff, $66, $66, $99, $99, $42, $42, $24, $24, $18, $18, $3c, $3c, $5a, $5a
	db $db, $db, $ff, $ff, $a5, $a5, $18, $18, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $5a, $5a, $81, $81, $42, $42, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $7e, $7e, $ff, $ff, $99, $99
	db $ff, $ff, $24, $24, $5a, $5a, $81, $81, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $06, $06, $1f, $1f, $3f, $3f, $26, $26
	db $3f, $3f, $19, $19, $26, $26, $10, $10, $00, $00, $80, $80, $c0, $c0, $40, $40
	db $c0, $c0, $80, $80, $40, $40, $80, $80, $01, $01, $07, $07, $0f, $0f, $09, $09
	db $0f, $0f, $02, $02, $05, $05, $08, $08, $80, $80, $e0, $e0, $f0, $f0, $90, $90
	db $f0, $f0, $40, $40, $a0, $a0, $10, $10, $00, $00, $01, $01, $03, $03, $02, $02
	db $03, $03, $01, $01, $02, $02, $01, $01, $60, $60, $f8, $f8, $fc, $fc, $64, $64
	db $fc, $fc, $98, $98, $64, $64, $08, $08, $10, $10, $38, $38, $38, $38, $38, $38
	db $38, $10, $10, $10, $00, $00, $38, $10, $3c, $3c, $42, $42, $99, $99, $a1, $a1
	db $a1, $a1, $99, $99, $42, $42, $3c, $3c, $00, $00, $01, $01, $03, $03, $02, $02
	db $03, $03, $01, $01, $02, $02, $01, $01, $18, $18, $7e, $7e, $ff, $ff, $99, $99
	db $ff, $ff, $24, $24, $5a, $5a, $81, $81, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $24, $24, $99, $99, $bd, $bd, $db, $db
	db $5a, $5a, $7e, $7e, $24, $24, $42, $42, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $09, $09, $06, $06, $0f, $0f, $16, $16
	db $36, $36, $3f, $3f, $29, $29, $06, $06, $00, $00, $00, $00, $00, $00, $80, $80
	db $c0, $c0, $c0, $c0, $40, $40, $00, $00, $02, $02, $09, $09, $0b, $0b, $0d, $0d
	db $05, $05, $07, $07, $02, $02, $04, $04, $40, $40, $90, $90, $d0, $d0, $b0, $b0
	db $a0, $a0, $e0, $e0, $40, $40, $20, $20, $00, $00, $00, $00, $00, $00, $01, $01
	db $03, $03, $03, $03, $02, $02, $00, $00, $90, $90, $60, $60, $f0, $f0, $68, $68
	db $6c, $6c, $fc, $fc, $94, $94, $60, $60, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $18, $18, $3c, $3c, $7e, $7e, $db, $db
	db $ff, $ff, $24, $24, $5a, $5a, $a5, $a5, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $06, $06, $0f, $0f, $1f, $1f, $36, $36
	db $3f, $3f, $16, $16, $20, $20, $10, $10, $00, $00, $00, $00, $80, $80, $c0, $c0
	db $c0, $c0, $80, $80, $40, $40, $80, $80, $01, $01, $03, $03, $07, $07, $0d, $0d
	db $0f, $0f, $02, $02, $05, $05, $0a, $0a, $80, $80, $c0, $c0, $e0, $e0, $b0, $b0
	db $f0, $f0, $40, $40, $a0, $a0, $50, $50, $00, $00, $00, $00, $01, $01, $03, $03
	db $03, $03, $01, $01, $02, $02, $01, $01, $60, $60, $f0, $f0, $f8, $f8, $6c, $6c
	db $fc, $fc, $68, $68, $04, $04, $08, $08, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

;@ path: title/credit
;@ The TAITO logo: 15 tiles copied to $9600 (BG tiles $60-$6E) by ShowDeveloperCredit.
;@ asset: tiles bpp=2
CreditTiles::
	db $00, $00, $00, $00, $3f, $3f, $3f, $3f
	db $3f, $3f, $03, $03, $03, $03, $03, $03, $00, $00, $00, $00, $f8, $f8, $f8, $f8
	db $f9, $f9, $81, $81, $83, $83, $83, $83, $00, $00, $61, $61, $f6, $f6, $fc, $fc
	db $e8, $e8, $d8, $d8, $9c, $9c, $bc, $bc, $00, $00, $00, $00, $1c, $1c, $1c, $1c
	db $1c, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $00, $00, $00, $00, $ff, $ff, $ff, $ff
	db $ff, $ff, $0e, $0e, $0e, $0e, $0e, $0e, $00, $00, $00, $00, $e1, $e1, $e7, $e7
	db $ef, $ef, $0f, $0f, $1e, $1e, $1e, $1e, $00, $00, $00, $00, $f0, $f0, $fc, $fc
	db $fe, $fe, $1e, $1e, $0f, $0f, $0f, $0f, $03, $03, $03, $03, $03, $03, $03, $03
	db $03, $03, $03, $03, $03, $03, $03, $03, $87, $87, $87, $87, $8e, $8e, $8e, $8e
	db $9e, $9e, $9c, $9c, $bc, $bc, $bc, $bc, $3e, $3e, $3e, $3e, $7f, $7f, $7f, $7f
	db $7f, $7f, $7f, $7f, $7f, $7f, $7f, $7f, $1c, $1c, $1c, $1c, $1c, $1c, $1c, $1c
	db $9c, $9c, $9c, $9c, $dc, $dc, $dc, $dc, $0e, $0e, $0e, $0e, $0e, $0e, $0e, $0e
	db $0e, $0e, $0e, $0e, $0e, $0e, $0e, $0e, $1c, $1c, $1c, $1c, $1e, $1e, $1e, $1e
	db $0f, $0f, $0f, $0f, $07, $07, $01, $01, $07, $07, $07, $07, $0f, $0f, $0f, $0f
	db $1e, $1e, $fe, $fe, $fc, $fc, $f0, $f0, $00, $00, $00, $00, $00, $00, $1c, $1c
	db $3e, $3e, $3e, $3e, $3e, $3e, $1c, $1c

;@ path: title/screen
;@ The SPACE INVADERS logo: 80 tiles for BG tiles $00-$4F (LoadBgTiles copies $800 bytes from here).
;@ asset: tiles bpp=2
TitleTiles::
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $07, $01, $03, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $f8, $f0, $fd, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $7f, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $f1, $e7, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $f0, $c0, $e0, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $01, $03, $00, $01, $00, $01, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $ff, $00, $ff, $80, $ff, $8f, $7c, $c4
	db $7c, $c7, $3f, $63, $3f, $60, $1f, $30, $ff, $02, $ff, $01, $ff, $ff, $01, $03
	db $00, $ff, $ff, $ff, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $1f, $f8, $88
	db $f8, $8f, $ff, $c7, $ff, $40, $ff, $20, $f8, $0f, $ff, $07, $ff, $e2, $3f, $72
	db $3f, $f2, $ff, $e2, $ff, $02, $ff, $06, $ff, $80, $ff, $00, $ff, $3f, $e0, $20
	db $e0, $3f, $ff, $3f, $ff, $00, $ff, $00, $f7, $1c, $ff, $0c, $ff, $c4, $7f, $44
	db $7f, $c4, $ff, $c4, $ff, $04, $ff, $04, $ff, $00, $ff, $00, $ff, $7f, $c0, $60
	db $c0, $60, $c0, $60, $c0, $60, $c0, $60, $ff, $01, $ff, $01, $ff, $e2, $3f, $22
	db $7f, $44, $7f, $7c, $0f, $08, $0f, $08, $ff, $00, $ff, $00, $ff, $3f, $e0, $38
	db $c0, $7f, $ff, $7f, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $ff, $00, $00
	db $00, $ff, $fe, $ff, $fe, $03, $fc, $06, $c0, $60, $80, $c0, $80, $80, $00, $00
	db $00, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $ff, $1f, $1f, $00, $00, $00, $1f, $07, $0f
	db $07, $0c, $03, $06, $03, $03, $00, $9f, $ff, $fe, $01, $01, $01, $ff, $ff, $ff
	db $ff, $00, $ff, $00, $ff, $ff, $00, $f8, $ff, $23, $ff, $11, $ff, $11, $ff, $88
	db $ff, $08, $ff, $04, $ff, $ff, $00, $3e, $fb, $fa, $03, $02, $03, $02, $83, $82
	db $83, $82, $c3, $42, $ff, $ff, $00, $7f, $ff, $3f, $e0, $20, $e0, $20, $e0, $20
	db $e0, $20, $e0, $20, $e0, $e0, $00, $f1, $ff, $c4, $7f, $44, $7f, $44, $7f, $44
	db $7f, $44, $7f, $44, $7f, $7f, $00, $ff, $c0, $60, $c1, $61, $c3, $7e, $ff, $7e
	db $ff, $00, $ff, $00, $ff, $ff, $00, $ff, $1f, $f0, $ff, $f1, $ff, $21, $ff, $23
	db $ff, $40, $ff, $40, $ff, $ff, $00, $ff, $ff, $ff, $00, $c0, $00, $ff, $ff, $ff
	db $ff, $00, $ff, $00, $ff, $ff, $00, $ff, $fc, $fc, $00, $00, $00, $fc, $f0, $f8
	db $f0, $18, $e0, $30, $e0, $e0, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $f1, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $ff, $3f, $7f, $3f, $60, $1f, $30, $1f, $1f
	db $00, $00, $00, $00, $00, $00, $00, $00, $ff, $ff, $ff, $00, $ff, $00, $ff, $e3
	db $3e, $62, $1f, $31, $1f, $31, $0f, $18, $ff, $ff, $ff, $20, $ff, $10, $ff, $f8
	db $0f, $18, $07, $0c, $07, $0c, $83, $86, $cf, $df, $e7, $2c, $f3, $1e, $fb, $8e
	db $fd, $c7, $ff, $63, $df, $71, $ef, $38, $fc, $fc, $fc, $44, $fe, $22, $fe, $22
	db $ff, $11, $ff, $11, $ff, $88, $ff, $88, $1f, $3f, $1f, $31, $1f, $31, $1f, $31
	db $1f, $31, $1f, $31, $9f, $b1, $9f, $b1, $3f, $ff, $7f, $c0, $ff, $80, $ff, $1f
	db $f0, $10, $f0, $1f, $ff, $1f, $ff, $00, $f3, $fb, $fb, $0e, $ff, $06, $ff, $e2
	db $3f, $62, $3f, $e2, $ff, $e2, $ff, $02, $ff, $ff, $ff, $00, $ff, $00, $ff, $3f
	db $e0, $30, $e0, $30, $e0, $30, $e1, $31, $ff, $ff, $ff, $02, $ff, $02, $ff, $c4
	db $7f, $44, $ff, $88, $ff, $88, $ff, $10, $ff, $ff, $ff, $00, $ff, $00, $ff, $7f
	db $c0, $60, $80, $ff, $ff, $ff, $ff, $00, $ff, $ff, $ff, $02, $ff, $04, $ff, $fc
	db $0f, $08, $0f, $f9, $ff, $f1, $ff, $10, $ff, $ff, $ff, $00, $ff, $00, $ff, $ff
	db $80, $c0, $01, $ff, $ff, $fe, $ff, $00, $e7, $ff, $f7, $1c, $ff, $08, $ff, $89
	db $ff, $91, $fe, $13, $ff, $23, $ff, $60, $ff, $ff, $ff, $00, $ff, $00, $ff, $ff
	db $00, $80, $00, $ff, $ff, $ff, $ff, $00, $fc, $fe, $fc, $06, $f8, $0c, $f0, $f0
	db $00, $00, $00, $f0, $c0, $e0, $c0, $60, $00, $00, $00, $00, $00, $00, $00, $01
	db $00, $00, $00, $00, $00, $00, $00, $00, $0f, $18, $07, $0c, $07, $0c, $03, $fe
	db $7f, $fe, $7f, $c0, $3f, $60, $3f, $3f, $83, $86, $c1, $43, $c1, $43, $e0, $3f
	db $ff, $3f, $ff, $00, $ff, $00, $ff, $ff, $e7, $2c, $f3, $16, $f1, $13, $f8, $89
	db $f8, $88, $fc, $44, $fc, $44, $fc, $fc, $ff, $44, $ff, $04, $ff, $02, $ff, $82
	db $7f, $c1, $3f, $61, $1f, $30, $0f, $1f, $df, $71, $df, $71, $ff, $31, $ff, $01
	db $ff, $01, $ff, $01, $ff, $81, $ff, $ff, $ff, $00, $ff, $1f, $f0, $10, $f0, $10
	db $f0, $10, $f0, $10, $f0, $10, $f0, $f0, $ff, $02, $ff, $e2, $3f, $62, $3f, $62
	db $3f, $62, $3f, $62, $3f, $62, $3f, $3f, $e1, $31, $e3, $32, $e3, $32, $e7, $3c
	db $ff, $3c, $ff, $00, $ff, $00, $ff, $ff, $ff, $10, $ff, $21, $fe, $23, $fe, $43
	db $ff, $47, $ff, $80, $ff, $80, $ff, $ff, $ff, $00, $ff, $ff, $00, $00, $00, $ff
	db $ff, $ff, $ff, $00, $ff, $01, $ff, $ff, $ff, $23, $fe, $e3, $7c, $46, $7c, $c6
	db $f8, $8c, $f8, $8c, $f0, $18, $f0, $f0, $ff, $f1, $0f, $08, $0f, $08, $1f, $11
	db $1f, $11, $3f, $22, $3f, $22, $7f, $7f, $ff, $c0, $ff, $ff, $80, $c0, $00, $ff
	db $ff, $ff, $ff, $00, $ff, $00, $ff, $ff, $ff, $00, $ff, $f8, $1f, $11, $3f, $e1
	db $fe, $e3, $fe, $03, $fc, $06, $fc, $fc, $80, $c0, $80, $c0, $00, $80, $00, $80
	db $00, $00, $00, $00, $00, $00, $00, $00

;@ path: game/coffeebreak
;@ The picture of the first coffee break: 58 tiles for BG tiles $00-$39 (ShowCoffeeBreak1).
;@ asset: tiles bpp=2
CoffeeBreak1Tiles::
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $00, $00, $00, $00, $81, $81
	db $42, $42, $24, $24, $24, $24, $42, $42, $00, $00, $80, $80, $80, $80, $00, $00
	db $00, $00, $00, $00, $00, $00, $20, $20, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $81, $81, $00, $00, $04, $04, $88, $88
	db $48, $48, $24, $24, $22, $22, $40, $40, $10, $10, $08, $08, $08, $08, $10, $10
	db $00, $00, $20, $20, $10, $10, $08, $08, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $01, $01, $01, $01, $00, $00, $00, $00, $03, $03, $1c, $1c
	db $60, $60, $80, $80, $07, $07, $18, $1f, $00, $00, $1f, $1f, $e0, $e0, $00, $00
	db $07, $07, $78, $7f, $80, $ff, $00, $ff, $00, $00, $c0, $c0, $3e, $3e, $01, $01
	db $00, $00, $f0, $f0, $0f, $ff, $00, $ff, $00, $00, $00, $00, $00, $00, $c0, $c0
	db $30, $30, $38, $08, $3f, $07, $fc, $c4, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $f8, $f8, $06, $06, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01
	db $01, $01, $01, $01, $01, $01, $01, $01, $20, $3f, $a0, $bf, $61, $7f, $1c, $1f
	db $03, $03, $00, $00, $80, $80, $60, $60, $30, $ff, $c3, $ff, $04, $ff, $00, $ff
	db $e0, $ff, $1f, $1f, $00, $00, $00, $00, $1c, $ff, $02, $ff, $02, $ff, $01, $ff
	db $3e, $fe, $c0, $c0, $00, $00, $00, $00, $3c, $e4, $3f, $ef, $3c, $f4, $fc, $c4
	db $7c, $04, $7c, $04, $7c, $0c, $7c, $34, $01, $01, $f0, $f0, $08, $08, $04, $04
	db $04, $04, $09, $09, $11, $11, $22, $22, $00, $00, $80, $80, $80, $80, $80, $80
	db $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $03, $03
	db $0c, $0c, $30, $30, $c0, $c0, $00, $00, $1c, $1c, $03, $03, $80, $80, $e0, $e0
	db $9c, $9c, $83, $83, $40, $40, $40, $40, $00, $00, $e0, $e0, $1f, $1f, $00, $00
	db $00, $00, $e0, $e0, $1f, $1f, $00, $00, $01, $01, $3f, $3e, $c1, $c0, $01, $00
	db $01, $01, $3f, $3e, $c3, $c0, $03, $00, $fc, $c4, $fc, $04, $fd, $0d, $fe, $3e
	db $fc, $cc, $f8, $08, $f0, $10, $f1, $11, $42, $42, $84, $84, $08, $08, $10, $10
	db $30, $30, $4c, $4c, $83, $83, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $80, $80, $02, $02, $04, $04, $08, $08, $10, $10
	db $20, $20, $20, $20, $20, $20, $20, $20, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $40, $40, $20, $20, $10, $10, $08, $08
	db $04, $04, $0e, $0e, $31, $31, $41, $41, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $87, $80, $ff, $ff, $07, $00, $0f, $00, $1f, $00, $3f, $00
	db $7f, $01, $ff, $03, $fc, $0c, $fc, $fc, $f2, $12, $e4, $24, $c8, $48, $f0, $f0
	db $00, $00, $80, $80, $60, $60, $10, $10, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $40, $40, $20, $20, $10, $10, $08, $08
	db $04, $04, $04, $04, $04, $04, $04, $04, $20, $20, $20, $20, $10, $10, $08, $08
	db $04, $04, $02, $02, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $c0, $c0, $41, $41, $30, $30, $0c, $0c, $03, $03
	db $00, $00, $00, $00, $00, $00, $00, $00, $ff, $00, $ff, $ff, $00, $00, $ff, $ff
	db $00, $00, $00, $00, $00, $00, $00, $00, $fc, $04, $f8, $f8, $01, $01, $fe, $fe
	db $00, $00, $00, $00, $00, $00, $00, $00, $10, $10, $60, $60, $80, $80, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $03, $03, $04, $04, $04, $04, $08, $08, $10, $10
	db $20, $20, $40, $40, $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $30, $30, $0c, $0c, $03, $03, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $78, $78
	db $07, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $80, $80, $7f, $7f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $01, $01, $fe, $fe, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $1e, $1e
	db $e0, $e0, $00, $00, $00, $00, $00, $00, $0c, $0c, $30, $30, $c0, $c0, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00

;@ path: game/coffeebreak
;@ The picture of the second coffee break: 97 tiles for BG tiles $00-$60 (ShowCoffeeBreak2).
;@ asset: tiles bpp=2
CoffeeBreak2Tiles::
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $01, $01, $02, $02, $0c, $0c, $00, $00, $00, $00, $00, $00, $20, $20
	db $40, $40, $80, $80, $00, $00, $80, $80, $00, $00, $00, $00, $00, $00, $01, $01
	db $01, $01, $02, $02, $06, $06, $04, $04, $31, $31, $42, $42, $84, $84, $08, $08
	db $10, $10, $10, $10, $20, $20, $40, $40, $00, $00, $00, $00, $00, $00, $00, $00
	db $01, $01, $02, $02, $04, $04, $08, $08, $08, $08, $14, $14, $24, $24, $c8, $c8
	db $11, $11, $21, $21, $42, $42, $84, $84, $40, $40, $80, $80, $80, $80, $80, $80
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $01, $01, $00, $00, $01, $01, $02, $02, $0c, $0c
	db $10, $10, $20, $20, $40, $40, $80, $80, $71, $71, $81, $81, $02, $02, $04, $04
	db $00, $00, $01, $01, $01, $01, $0a, $0a, $08, $08, $10, $10, $20, $20, $40, $40
	db $80, $80, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $03, $03, $3f, $3c, $ff, $c0, $00, $00, $00, $00, $00, $00, $00, $00
	db $3f, $3f, $ff, $e0, $ff, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $ff, $ff, $ff, $00, $fe, $01, $d5, $2a, $00, $00, $00, $00, $00, $00, $00, $00
	db $f8, $f8, $d7, $2f, $aa, $55, $55, $aa, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $f0, $f0, $af, $5f, $50, $af, $00, $00, $00, $00, $00, $00, $00, $00
	db $3e, $3e, $c1, $c1, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $f0, $f0, $0f, $0f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $03, $03, $fc, $fc, $00, $00, $00, $00, $03, $03, $04, $04, $08, $08, $30, $30
	db $c1, $c1, $02, $02, $04, $04, $00, $00, $10, $10, $20, $20, $40, $40, $80, $80
	db $00, $00, $01, $01, $01, $01, $02, $02, $12, $12, $24, $24, $4c, $4c, $08, $08
	db $90, $90, $30, $30, $20, $20, $40, $40, $00, $00, $00, $00, $00, $00, $01, $01
	db $07, $06, $1f, $18, $3f, $20, $ff, $c0, $07, $06, $3f, $38, $ff, $c0, $ff, $00
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $fe, $01, $fd, $02, $ea, $15, $d5, $2a, $fe, $01, $fd, $02, $ea, $15, $55, $aa
	db $aa, $55, $55, $aa, $aa, $55, $55, $aa, $aa, $55, $55, $aa, $aa, $55, $55, $aa
	db $aa, $55, $55, $aa, $aa, $55, $54, $ab, $aa, $55, $55, $aa, $a8, $57, $40, $bf
	db $80, $7f, $00, $ff, $01, $ff, $00, $ff, $81, $7f, $02, $ff, $05, $ff, $02, $ff
	db $45, $ff, $ab, $ff, $57, $ff, $af, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $01, $01, $03, $02, $07, $04, $0f, $08, $00, $00, $00, $00, $0f, $0f, $70, $70
	db $df, $8f, $f9, $11, $ea, $23, $cc, $4f, $00, $00, $ff, $ff, $06, $06, $bf, $18
	db $ff, $fe, $81, $ff, $00, $ff, $00, $ff, $3f, $3f, $e0, $e0, $aa, $00, $55, $00
	db $fa, $00, $fb, $83, $7c, $ff, $38, $ff, $e0, $e0, $1e, $1e, $a3, $03, $5e, $1f
	db $e0, $ff, $00, $ff, $00, $ff, $07, $ff, $00, $00, $00, $00, $c0, $c0, $20, $e0
	db $51, $f1, $31, $f1, $52, $f2, $32, $f2, $01, $01, $03, $02, $0f, $0c, $1f, $10
	db $3f, $20, $7f, $40, $ff, $80, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $fe, $01, $f5, $0a
	db $ea, $15, $d5, $2a, $aa, $55, $55, $aa, $aa, $55, $55, $aa, $aa, $55, $55, $aa
	db $aa, $55, $55, $aa, $aa, $55, $55, $aa, $aa, $55, $55, $aa, $aa, $55, $55, $aa
	db $aa, $55, $54, $ab, $a8, $57, $50, $af, $a0, $5f, $40, $bf, $80, $7f, $00, $ff
	db $00, $ff, $00, $ff, $00, $ff, $00, $ff, $01, $ff, $02, $ff, $05, $ff, $0a, $ff
	db $15, $ff, $2b, $ff, $57, $ff, $af, $ff, $5f, $ff, $bf, $ff, $7f, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $01, $01, $01, $01, $1f, $10, $3f, $20, $5f, $60, $5f, $67
	db $ad, $d9, $96, $f3, $26, $e5, $69, $ae, $dc, $5f, $ff, $63, $ff, $40, $ff, $80
	db $ff, $00, $7f, $80, $7f, $81, $3e, $c3, $00, $ff, $03, $ff, $cc, $ff, $f0, $3f
	db $e0, $3f, $c0, $ff, $00, $ff, $1c, $ff, $c0, $ff, $80, $ff, $00, $ff, $00, $ff
	db $00, $ff, $00, $ff, $01, $ff, $00, $ff, $08, $f8, $10, $f0, $20, $e0, $41, $c1
	db $c3, $81, $ce, $83, $fd, $8f, $fb, $ff, $d4, $f4, $a4, $e4, $e8, $e8, $48, $c8
	db $d0, $d0, $90, $90, $20, $20, $20, $20, $03, $02, $07, $04, $0f, $08, $1f, $10
	db $1f, $10, $3f, $20, $7f, $40, $ff, $80, $fe, $01, $fd, $02, $fa, $05, $f5, $0a
	db $fa, $05, $f5, $0a, $ea, $15, $d5, $2a, $aa, $55, $55, $aa, $aa, $55, $55, $aa
	db $aa, $55, $54, $ab, $a8, $57, $54, $ab, $01, $ff, $02, $ff, $01, $ff, $02, $ff
	db $05, $ff, $0a, $ff, $15, $ff, $2a, $ff, $5f, $ff, $bf, $ff, $5f, $ff, $bf, $ff
	db $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $02, $03, $02, $03, $02, $03, $04, $07
	db $04, $07, $05, $07, $05, $07, $06, $07, $b2, $7d, $71, $ae, $e8, $57, $d4, $eb
	db $a8, $d7, $54, $ab, $2b, $d5, $56, $ab, $9c, $67, $48, $bf, $91, $7f, $62, $be
	db $44, $fc, $8c, $f8, $0c, $f8, $19, $f0, $62, $e3, $82, $83, $04, $07, $04, $07
	db $08, $0f, $33, $1f, $77, $3c, $ef, $7b, $01, $ff, $00, $ff, $00, $ff, $3c, $ff
	db $fe, $c3, $fe, $3b, $c4, $c7, $04, $07, $56, $fe, $ac, $fc, $09, $f9, $0a, $fa
	db $14, $f4, $28, $e8, $48, $c8, $90, $90, $40, $40, $80, $80, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $03, $02, $03, $02
	db $07, $04, $07, $04, $0f, $08, $1f, $10, $ff, $80, $ff, $00, $ff, $00, $ff, $00
	db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $fe, $01, $ff, $00
	db $fe, $01, $fd, $02, $fa, $05, $f5, $0a, $a8, $57, $50, $af, $a0, $5f, $40, $bf
	db $a0, $5f, $40, $bf, $80, $7f, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff
	db $01, $ff, $02, $ff, $01, $ff, $02, $ff, $55, $ff, $2b, $ff, $57, $ff, $af, $ff
	db $5f, $ff, $af, $ff, $5f, $ff, $bf, $ff, $04, $07, $06, $07, $04, $07, $0a, $0f
	db $0c, $0f, $08, $0f, $14, $1f, $19, $1f, $2c, $d7, $58, $af, $30, $df, $20, $ff
	db $40, $ff, $40, $ff, $80, $ff, $00, $ff, $1f, $f1, $0e, $ff, $15, $ff, $0a, $ff
	db $01, $ff, $03, $fe, $03, $fe, $07, $fd, $dc, $f4, $b8, $e8, $70, $d0, $e0, $a0
	db $c1, $40, $c3, $81, $ce, $83, $bc, $0f, $09, $0f, $12, $1e, $24, $3c, $48, $78
	db $91, $f1, $26, $e6, $48, $c8, $90, $90, $20, $20, $20, $20, $40, $40, $80, $80
	db $00, $00, $00, $00, $00, $00, $00, $00, $1f, $10, $3f, $20, $3f, $20, $3f, $20
	db $7f, $40, $7f, $40, $ff, $80, $ff, $80, $fa, $05, $f5, $0a, $ea, $15, $f5, $0a
	db $ea, $15, $d5, $2a, $aa, $55, $d5, $2a, $80, $7f, $00, $ff, $00, $ff, $00, $ff
	db $00, $ff, $00, $ff, $00, $ff, $00, $ff, $05, $ff, $02, $ff, $05, $ff, $0a, $ff
	db $15, $ff, $0a, $ff, $15, $ff, $2b, $ff, $11, $1f, $1a, $1f, $25, $3f, $36, $3f
	db $2d, $3f, $3b, $3f, $2d, $3f, $3b, $3e, $00, $ff, $0e, $ff, $31, $f1, $c1, $c1
	db $81, $81, $86, $03, $8d, $07, $da, $0f, $07, $fd, $03, $ff, $05, $ff, $02, $ff
	db $01, $ff, $03, $ff, $0c, $fc, $10, $f0, $f7, $3f, $ec, $fc, $58, $f8, $e0, $e0
	db $80, $80, $00, $00, $00, $00, $00, $00, $20, $20, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01
	db $01, $01, $03, $02, $03, $02, $03, $02, $ff, $00, $ff, $00, $ff, $00, $ff, $00
	db $ff, $00, $ff, $00, $fe, $01, $ff, $00, $a8, $57, $54, $ab, $a8, $57, $54, $ab
	db $a8, $57, $50, $af, $a8, $57, $50, $af, $00, $ff, $00, $ff, $00, $ff, $00, $ff
	db $00, $ff, $00, $ff, $00, $ff, $00, $ff, $15, $ff, $2b, $ff, $15, $ff, $2b, $ff
	db $57, $ff, $2b, $ff, $57, $ff, $ab, $ff, $17, $1e, $1b, $1f, $0d, $0f, $06, $07
	db $03, $03, $00, $00, $00, $00, $00, $00, $f5, $1f, $eb, $ff, $56, $fe, $b8, $f8
	db $e0, $e0, $00, $00, $00, $00, $00, $00, $60, $e0, $80, $80, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $03, $02, $07, $04, $07, $04, $07, $04
	db $07, $04, $07, $04, $07, $04, $07, $04, $fe, $01, $fd, $02, $fe, $01, $fd, $02
	db $fe, $01, $fd, $02, $fe, $01, $fd, $02, $a0, $5f, $50, $af, $a0, $5f, $50, $af
	db $a0, $5f, $50, $af, $a0, $5f, $50, $af, $57, $ff, $af, $ff, $57, $ff, $af, $ff
	db $57, $ff, $af, $ff, $57, $ff, $af, $ff, $07, $04, $07, $04, $07, $04, $07, $04
	db $07, $04, $07, $04, $07, $04, $07, $04

;@ path: link/result
;@ The ground of the link-game result screens: 80 tiles for BG tiles $00-$4F (ShowLinkWin and
;@ ShowLinkLoss copy $500 bytes from here).
;@ asset: tiles bpp=2
LinkResultTiles::
	db $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $e0, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $ff, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $ff, $00, $fe, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $1f, $00, $ff, $1f, $f7, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $ff, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $fc, $00, $e3, $fc, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $1f, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $07, $00, $fe, $03, $fe, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $80, $00, $ff, $00, $3f, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $ff, $00, $ff, $ff, $fe, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $f8, $00, $1f, $f8, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $00, $00, $00, $00, $00, $ff, $00, $9f, $e0, $df, $ff, $e2, $ff, $d7, $ff
	db $fe, $ff, $fd, $ff, $ff, $ff, $f9, $ff, $e0, $00, $0f, $f0, $6f, $ff, $ff, $ff
	db $3f, $ff, $9f, $ff, $1f, $ff, $fd, $03, $07, $00, $fc, $07, $04, $ff, $f1, $ff
	db $e4, $ff, $ea, $ff, $7d, $ff, $00, $ff, $ff, $ff, $ee, $ff, $fb, $ff, $48, $ff
	db $7d, $ff, $3d, $ff, $d7, $ff, $3f, $f8, $e3, $ff, $9f, $ff, $a2, $ff, $67, $ff
	db $83, $ff, $3f, $ff, $fd, $ff, $f0, $0f, $f1, $ff, $ee, $ff, $5c, $ff, $d3, $ff
	db $af, $ff, $3e, $ff, $b9, $ff, $23, $ff, $9e, $ff, $3f, $ff, $74, $ff, $e1, $ff
	db $c7, $ff, $87, $ff, $ff, $f0, $c0, $ff, $ff, $ff, $53, $ff, $8f, $ff, $ff, $ff
	db $fc, $ff, $fe, $ff, $ed, $3f, $3e, $e3, $f8, $ff, $dc, $ff, $f5, $ff, $ef, $ff
	db $bb, $ff, $c4, $ff, $42, $ff, $91, $ff, $c0, $00, $3e, $c0, $57, $fe, $d7, $ff
	db $77, $ff, $d9, $ff, $f2, $ff, $5a, $ff, $00, $00, $00, $00, $ff, $00, $ff, $ff
	db $ff, $ff, $7f, $ff, $33, $ff, $4f, $ff, $00, $00, $00, $00, $00, $00, $ff, $00
	db $5f, $ff, $fb, $ff, $96, $ff, $e4, $ff, $00, $00, $0f, $00, $fc, $0f, $fc, $ff
	db $f9, $ff, $e9, $ff, $2e, $ff, $ab, $ff, $00, $00, $03, $00, $ff, $03, $17, $ff
	db $ff, $ff, $ff, $f8, $f8, $e7, $e7, $ff, $7f, $1f, $ff, $7f, $ff, $ff, $ff, $fc
	db $fc, $03, $02, $ff, $e4, $ff, $fa, $ff, $ff, $ff, $ef, $ff, $fd, $ff, $ff, $1f
	db $0a, $ff, $90, $ff, $15, $ff, $4f, $f8, $0f, $ff, $93, $ff, $7f, $ff, $fb, $ff
	db $64, $ff, $9f, $ff, $79, $ff, $f7, $1f, $ff, $ff, $ef, $ff, $df, $ff, $82, $ff
	db $c5, $ff, $f9, $ff, $e9, $ff, $07, $ff, $87, $ff, $f2, $ff, $eb, $ff, $7f, $ff
	db $7f, $f8, $20, $ff, $2a, $ff, $3c, $ff, $ff, $ff, $ef, $ff, $8d, $ff, $e1, $ff
	db $e9, $1f, $1e, $e3, $80, $ff, $77, $ff, $ff, $c0, $c0, $ff, $9d, $ff, $ce, $ff
	db $fe, $ff, $fc, $ff, $d8, $ff, $d7, $ff, $03, $fc, $ec, $ff, $7e, $ff, $bd, $ff
	db $1f, $ff, $bc, $ff, $1a, $ff, $ae, $ff, $e5, $1f, $18, $e7, $a7, $f8, $50, $ff
	db $aa, $ff, $11, $ff, $aa, $ff, $d3, $ff, $e0, $ff, $07, $ff, $c3, $3f, $10, $ef
	db $c3, $ff, $69, $ff, $9e, $ff, $57, $ff, $0f, $f0, $d0, $ff, $05, $ff, $72, $ff
	db $ff, $ff, $fe, $ff, $1f, $ff, $d5, $ff, $00, $ff, $fe, $01, $00, $ff, $ff, $ff
	db $93, $ff, $f8, $ff, $56, $ff, $d0, $ff, $2c, $ff, $db, $ff, $3f, $c0, $00, $ff
	db $b7, $ff, $51, $ff, $e6, $ff, $78, $ff, $83, $fc, $34, $ff, $d0, $ff, $3f, $ff
	db $cf, $ff, $d3, $ff, $00, $ff, $15, $ff, $e0, $1f, $1b, $e4, $a4, $ff, $78, $ff
	db $f6, $ff, $e7, $ff, $5e, $ff, $36, $ff, $14, $ff, $c2, $7f, $05, $ff, $83, $ff
	db $90, $ff, $fd, $ff, $fa, $ff, $1f, $ff, $3f, $fc, $78, $ff, $a5, $ff, $0f, $ff
	db $cd, $ff, $56, $ff, $af, $ff, $bf, $ff, $fe, $1f, $1f, $e7, $67, $f8, $c8, $ff
	db $e0, $ff, $ff, $ff, $ec, $ff, $d7, $ff, $f9, $ff, $fc, $8f, $8c, $7f, $7f, $ff
	db $ff, $ff, $f4, $ff, $65, $ff, $9f, $ff, $7f, $ff, $2a, $ff, $3d, $ff, $82, $ff
	db $dc, $ff, $fa, $ff, $a0, $ff, $af, $ff, $fd, $ff, $ff, $ff, $6f, $ff, $aa, $ff
	db $8d, $ff, $12, $ff, $e8, $ff, $10, $ff, $58, $e7, $c7, $ff, $eb, $ff, $ff, $ff
	db $7b, $ff, $41, $ff, $38, $ff, $9d, $ff, $1f, $f0, $e0, $ff, $d4, $ff, $ea, $ff
	db $d5, $ff, $fa, $ff, $b5, $ff, $ee, $ff, $21, $ff, $ff, $00, $20, $df, $12, $ed
	db $00, $ff, $91, $ff, $1a, $ff, $e9, $ff, $27, $ff, $ff, $7f, $0d, $ff, $17, $ff
	db $73, $ff, $c6, $ff, $bc, $ff, $03, $fc, $d9, $ff, $7d, $ff, $af, $ff, $ff, $ff
	db $af, $ff, $2f, $ff, $7f, $83, $8b, $7f, $fa, $ff, $ff, $ff, $f1, $ff, $ef, $fe
	db $bf, $ff, $f9, $ff, $6d, $ff, $ff, $ff, $01, $ff, $d9, $ff, $a1, $ff, $ff, $00
	db $df, $ff, $64, $ff, $fa, $ff, $ff, $ff, $64, $ff, $0f, $f0, $f0, $0f, $05, $ff
	db $7a, $ff, $7d, $ff, $3e, $ff, $af, $ff, $9e, $ff, $f9, $07, $06, $f9, $41, $fe
	db $a8, $ff, $50, $ff, $a2, $ff, $55, $ff, $6a, $ff, $95, $ff, $4f, $ff, $fe, $01
	db $01, $fe, $00, $ff, $07, $ff, $4f, $ff, $05, $ff, $42, $ff, $f5, $ff, $0f, $f0
	db $fe, $0f, $f9, $ff, $e2, $ff, $94, $ff, $d1, $ff, $aa, $ff, $d5, $ff, $fe, $7f
	db $39, $fe, $76, $f9, $ad, $f3, $02, $ff, $7e, $ff, $fe, $ff, $7f, $f8, $f8, $87
	db $87, $7f, $54, $ff, $3f, $ff, $ff, $ff, $cf, $f8, $f8, $07, $04, $ff, $db, $ff
	db $3a, $ff, $fd, $ff, $fa, $ff, $55, $ff, $c1, $3f, $38, $c7, $87, $f8, $00, $ff
	db $a8, $ff, $55, $ff, $ea, $ff, $5f, $ff, $fa, $ff, $d5, $ff, $07, $ff, $df, $23
	db $02, $ff, $40, $ff, $ad, $ff, $fa, $ff, $aa, $ff, $75, $ff, $ff, $ff, $d3, $ff
	db $9e, $ff, $a9, $ff, $54, $ff, $aa, $ff, $a7, $ff, $fa, $ff, $e7, $f8, $b8, $c7
	db $41, $ff, $0a, $ff, $55, $ff, $bf, $ff, $7a, $ff, $fc, $ff, $ff, $ff, $e6, $1f
	db $10, $ff, $be, $ff, $f1, $ff, $c3, $ff, $c6, $ff, $d9, $ff, $f7, $ff, $57, $ff
	db $82, $ff, $19, $ff, $f3, $ff, $7f, $ff, $ff, $fe, $fe, $fd, $fc, $e3, $e1, $df
	db $ca, $bf, $97, $ff, $ab, $ff, $7f, $ff, $f7, $ff, $7f, $ff, $ae, $ff, $58, $ff
	db $b4, $ff, $e9, $ff, $ed, $ff, $9f, $ff, $fc, $ff, $ff, $00, $00, $ff, $35, $ff
	db $7f, $ff, $3f, $ff, $cd, $ff, $ff, $ff, $fc, $03, $0d, $ff, $e4, $ff, $d5, $ff
	db $14, $ff, $e9, $ff, $fb, $ff, $ff, $ff, $ea, $ff, $2c, $ff, $45, $ff, $78, $ff
	db $0b, $ff, $98, $ff, $e0, $ff, $c0, $ff

;@ path: game/ending
;@ The picture of the ending: 107 tiles for BG tiles $00-$6A (ShowEnding; LoadBgTiles copies $800
;@ bytes, running on into the code after it).
;@ asset: tiles bpp=2
EndingTiles::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $00, $e7, $e7, $e7, $e7
	db $e7, $e7, $e7, $e7, $e7, $e7, $e7, $e7, $9e, $9e, $9e, $9e, $9e, $9e, $80, $80
	db $80, $80, $9e, $9e, $9e, $9e, $9e, $9e, $40, $40, $40, $40, $4f, $4f, $40, $40
	db $40, $40, $4f, $4f, $40, $40, $40, $40, $3f, $3f, $3f, $3f, $ff, $ff, $3f, $3f
	db $3f, $3f, $ff, $ff, $3f, $3f, $3f, $3f, $00, $00, $00, $00, $3f, $3f, $00, $00
	db $00, $00, $3f, $3f, $00, $00, $00, $00, $9e, $9e, $8e, $8e, $86, $86, $82, $82
	db $90, $90, $98, $98, $9c, $9c, $9e, $9e, $40, $40, $40, $40, $4e, $4e, $4f, $4f
	db $4f, $4f, $4e, $4e, $40, $40, $40, $40, $ff, $ff, $7f, $7f, $3f, $3f, $3f, $3f
	db $3f, $3f, $3f, $3f, $7f, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $fe, $fe, $fc, $fc, $f9, $f8, $fa, $f9, $ff, $ff, $f0, $f0, $c0, $c0, $04, $00
	db $59, $00, $35, $0a, $8f, $7f, $7f, $ff, $ff, $ff, $3f, $3f, $0f, $0f, $93, $03
	db $49, $01, $54, $a0, $ce, $f0, $f7, $f8, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7f, $7f, $7f, $7f, $f5, $f3, $fb, $f7, $e7, $ef, $ff, $ef
	db $ef, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fd, $fe, $fe, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $3f, $bf, $3f, $1f, $df, $bf, $df
	db $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $fe, $ff, $f8, $fe, $f1, $fe, $81, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $fc, $ff, $f8, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $8f, $b8, $07, $00, $7f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $7f, $ff, $ff, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $fd, $fc, $f9, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $fe, $fc, $7d, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $3f, $df, $2f, $3f, $d3, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ef, $fc, $ff, $90, $ff, $ff, $ff, $ff, $fb, $f7, $f4, $e3
	db $e9, $c6, $d8, $07, $fd, $02, $60, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $3e, $df, $1f, $e0, $3c, $c2, $f1, $0e, $ff, $ff, $ff, $ff, $cf, $f3, $93, $e4
	db $ae, $41, $3c, $83, $f1, $0f, $e9, $17, $ff, $fe, $ff, $fc, $fe, $f1, $0d, $f2
	db $8f, $78, $1f, $fc, $3b, $fc, $cf, $be, $fc, $03, $fe, $01, $78, $87, $70, $8f
	db $f0, $0f, $e2, $1d, $81, $7e, $01, $fe, $fc, $e8, $fc, $03, $f3, $0c, $00, $ff
	db $00, $ff, $ff, $00, $78, $87, $0a, $f5, $05, $fa, $a2, $5d, $92, $6d, $2c, $d3
	db $12, $ed, $84, $7b, $c5, $3a, $01, $fe, $1c, $e3, $e3, $1c, $3c, $c3, $12, $ed
	db $4f, $f0, $61, $be, $3e, $fd, $7d, $fa, $ff, $ff, $3f, $ff, $f0, $0f, $3e, $c1
	db $8b, $74, $c3, $3c, $00, $ff, $e0, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $f8, $07
	db $00, $ff, $c1, $3e, $f2, $0c, $0f, $f0, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $ff
	db $ff, $00, $df, $00, $73, $00, $ff, $00, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $0f, $ff, $f0, $0f, $d5, $2a, $aa, $55, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $f0, $ff, $6c, $f3, $9b, $64, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $7f, $ff, $83, $7f, $a0, $5f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $f0, $ff, $40, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $fe, $ff
	db $f1, $fe, $83, $fc, $04, $fb, $02, $ff, $fa, $f1, $fc, $e3, $d9, $86, $23, $9c
	db $56, $29, $d8, $27, $45, $ba, $39, $c6, $75, $82, $96, $69, $40, $bf, $8c, $73
	db $02, $ff, $39, $c7, $9f, $7f, $2d, $de, $26, $fd, $bd, $7e, $7f, $ff, $d3, $fe
	db $ee, $b9, $ff, $f0, $c7, $f8, $7e, $b5, $ca, $30, $b5, $48, $e3, $9c, $7d, $82
	db $8a, $75, $0b, $f7, $11, $ee, $02, $fd, $f5, $0a, $a3, $5c, $17, $e8, $e4, $1b
	db $25, $da, $0f, $f0, $c1, $fe, $fe, $1f, $ef, $10, $87, $78, $fd, $02, $3a, $c5
	db $75, $8a, $4a, $b5, $28, $d7, $01, $ff, $d3, $2f, $a6, $5f, $6b, $9c, $94, $7b
	db $2e, $f1, $58, $e7, $b9, $c7, $b1, $cf, $a2, $df, $99, $67, $0e, $f1, $19, $e6
	db $5f, $f0, $c2, $fd, $c0, $ff, $e1, $ff, $1b, $e4, $b9, $c6, $33, $ec, $5b, $a4
	db $e5, $1a, $80, $7f, $c6, $39, $ee, $91, $07, $f8, $17, $e8, $c8, $37, $e1, $1f
	db $83, $7f, $14, $ff, $00, $ff, $02, $fd, $8c, $7b, $31, $ff, $ff, $e0, $ff, $c0
	db $07, $f8, $bf, $c0, $df, $72, $fe, $1d, $fe, $e1, $1f, $e0, $f0, $0f, $bf, $40
	db $db, $00, $ff, $00, $fe, $01, $87, $78, $0f, $f0, $3f, $c0, $ff, $00, $ea, $00
	db $3b, $00, $f8, $07, $e0, $1f, $1f, $e0, $fb, $00, $cd, $10, $1b, $00, $f6, $01
	db $a0, $1f, $01, $fe, $4d, $b2, $02, $fd, $ee, $01, $bc, $03, $f0, $0f, $82, $7d
	db $29, $d6, $95, $6a, $4a, $b5, $af, $5b, $04, $fb, $21, $de, $2a, $d7, $d7, $2e
	db $a9, $5e, $fd, $7a, $2a, $d5, $5e, $a1, $fd, $00, $7f, $80, $7c, $01, $a2, $5d
	db $45, $ba, $0b, $f4, $14, $eb, $ab, $54, $00, $ff, $a8, $5f, $9a, $67, $f1, $0f
	db $84, $7b, $08, $f7, $d0, $2f, $20, $df, $0e, $fd, $30, $ff, $c9, $f6, $1d, $e2
	db $a6, $58, $15, $f8, $a3, $7f, $ce, $fd, $44, $bf, $7f, $98, $fd, $3a, $e0, $bf
	db $81, $7e, $00, $ff, $01, $fe, $02, $fd, $a2, $0f, $4f, $17, $3e, $cf, $fa, $7f
	db $6d, $ff, $27, $db, $9f, $7d, $3d, $fa, $9f, $fe, $bc, $7f, $78, $bf, $69, $ff
	db $e2, $ff, $a5, $df, $b3, $4f, $4f, $b7, $67, $ff, $4e, $f7, $1d, $fe, $5f, $fd
	db $bc, $fb, $7a, $f5, $e0, $ff, $c3, $bf, $09, $f6, $80, $ff, $57, $fd, $a8, $ff
	db $57, $fd, $bf, $fb, $5c, $ff, $fb, $fc, $fc, $7f, $fc, $ff, $bf, $e8, $bc, $73
	db $41, $be, $07, $f8, $01, $fe, $d0, $ef, $27, $db, $2e, $df, $3f, $f0, $78, $87
	db $f0, $0f, $c5, $3f, $0f, $fe, $fc, $fb, $23, $df, $07, $ff, $2b, $ff, $d6, $7f
	db $2d, $fe, $5d, $fa, $a8, $57, $65, $fb, $ef, $ff, $b9, $ff, $e2, $ff, $64, $bf
	db $08, $ff, $4a, $bf, $30, $ff, $ec, $ff, $3c, $c3, $3c, $c3, $78, $87, $70, $8f
	db $82, $7f, $0c, $ff, $1f, $ff, $7f, $ff, $ff, $00, $e4, $1b, $f9, $06, $ef, $10
	db $9d, $62, $02, $fd, $00, $ff, $28, $d7, $4e, $b7, $29, $d7, $c0, $3f, $80, $7f
	db $85, $7f, $48, $b7, $1f, $e0, $5e, $a1, $5f, $a0, $02, $fd, $03, $fc, $68, $ff
	db $e0, $df, $40, $bf, $06, $ff, $c3, $3f, $fe, $01, $47, $b8, $0d, $f2, $02, $fd
	db $0f, $fe, $03, $ff, $01, $ff, $80, $ff, $11, $ee, $aa, $55, $41, $be, $b7, $48
	db $50, $af, $a0, $df, $c1, $ff, $61, $ff, $71, $ae, $34, $cb, $00, $ff, $93, $6f
	db $86, $7f, $49, $b7, $40, $bf, $56, $a9, $3d, $c2, $6c, $93, $78, $87, $e0, $1f
	db $07, $ff, $bb, $c7, $d7, $e8, $8d, $72, $54, $ab, $18, $e7, $2c, $f3, $c0, $ff
	db $e8, $17, $47, $bf, $89, $77, $47, $be, $c7, $3c, $1e, $e9, $7c, $f3, $7b, $c7
	db $f0, $cf, $20, $ff, $f8, $ff, $e3, $fc, $01, $fe, $34, $fb, $ac, $d3, $00, $ff
	db $07, $fd, $0c, $f3, $78, $8f, $e8, $1f, $07, $fb, $0d, $ff, $1f, $ff, $9a, $7f
	db $c2, $fd, $14, $eb, $05, $fb, $37, $cf, $fa, $75, $75, $aa, $ee, $d5, $ff, $f9
	db $3e, $f3, $cf, $ff, $97, $ef, $8b, $76, $b6, $5f, $7e, $ad, $9b, $77, $66, $ff
	db $ce, $7f, $18, $ff, $b4, $ff, $68, $ff, $97, $7f, $1e, $ff, $34, $ff, $6b, $ff
	db $46, $ff, $ab, $ff, $55, $ff, $ba, $ff, $61, $ff, $c7, $f9, $8d, $f2, $9c, $e3
	db $38, $c7, $fa, $4d, $d6, $f9, $eb, $fe, $6c, $f7, $8e, $ff, $14, $ff, $30, $cf
	db $e9, $9f, $5a, $bf, $3d, $ff, $ff, $ff, $ff, $e4, $df, $bf, $3e, $cd, $2b, $d7
	db $56, $af, $ab, $d7, $55, $fb, $ac, $ff, $1b, $e7, $7e, $9f, $15, $ff, $6b, $ff
	db $ff, $7f, $ff, $ff, $5f, $ff, $3f, $ff, $58, $ff, $bb, $ff, $77, $ff, $ef, $ff
	db $df, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $7f, $80, $f8, $07, $c0, $3f, $94, $7f
	db $aa, $ff, $7d, $ff, $fe, $ff, $fd, $ff, $4d, $b2, $f1, $0a, $35, $c2, $1a, $e5
	db $15, $e2, $3a, $c5, $3d, $c2, $7a, $85, $c0, $3f, $e3, $1f, $51, $af, $39, $c7
	db $0a, $f7, $8f, $71, $45, $ba, $a0, $5f, $dc, $ff, $f8, $ff, $5e, $ff, $b7, $ff
	db $ef, $ff, $7d, $ff, $aa, $7f, $d4, $3f, $30, $ff, $9d, $ff, $87, $ff, $c0, $ff
	db $da, $ff, $fe, $ff, $bf, $ff, $57, $ff, $a8, $d7, $95, $ea, $ca, $f5, $e1, $fe
	db $30, $ff, $f8, $ff, $fe, $ff, $ff, $ff, $21, $de, $04, $fb, $aa, $55, $40, $bf
	db $0a, $ff, $54, $ff, $a5, $ff, $7f, $ff, $7f, $97, $73, $8d, $e3, $1c, $01, $fe
	db $80, $ff, $0f, $ff, $7f, $ff, $ff, $ff, $ef, $f0, $fc, $03, $c0, $3f, $00, $ff
	db $3f, $c0, $c7, $f8, $fe, $ff, $ff, $ff, $f0, $7f, $a0, $ff, $00, $ff, $f0, $0f
	db $f9, $07, $0f, $fd, $ff, $1d, $70, $ff, $0c, $ff, $1b, $fc, $b6, $f9, $f8, $c7
	db $fa, $af, $b0, $7f, $07, $ff, $3f, $ff, $ca, $35, $39, $df, $75, $db, $d7, $ff
	db $0f, $ff, $fe, $ff, $e8, $ff, $80, $ff, $f9, $ff, $ee, $ff, $ec, $ff, $f5, $bf
	db $a7, $ff, $de, $ff, $bd, $ff, $7a, $ff, $5f, $ff, $bf, $ff, $7d, $ff, $ea, $ff
	db $d0, $ff, $a1, $ff, $47, $ff, $2b, $ff, $fd, $ff, $cf, $ff, $03, $ff, $3f, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $bf, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $de, $ff, $ee, $ff, $f7, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $5d, $ff, $bf, $ff, $57, $ff, $af, $ff
	db $d7, $ff, $ff, $ff, $ff, $ff, $ff, $ff

;@ def CheckGameCheatCodes()
;@ path: game/cheats
;@ Called every frame of a one-player game: looks for the in-game secret codes at the end of
;@ wPressHistory, as long as no secret feature is on yet. Each code found sets its bit of wCheatFlags
;@ and plays sound $1B. Bits 2-4 give the invaders a different look (see SetupFormation), bit 5 makes
;@ the formation turn at the edges without stepping down (StartMarchSweep) and raises wHomingLevel
;@ by 2. The second code counts only while the UFO is on screen (if it does not match then, the
;@ rest is not checked either), the fourth only right after the 15th shot of a cycle.
;@ writes: hSfxRequest2, wCheatFlags, wHomingLevel
;@ reads: hShotCount, hUfoFlags, wCheatFlags, wHomingLevel
;@ test: skip compares button histories in RAM against ROM codes
;@ sig: 3d6de250
CheckGameCheatCodes::
;> if wCheatFlags & 0x80 or wCheatFlags != 0:
;>     return
	ld a, [wCheatFlags]
	bit 7, a
	jp nz, CheatCheckDone

	and a
	jp nz, CheatCheckDone
;> if MatchButtonCode(CodeInvaderLook2) == 0:
	ld de, CodeInvaderLook2
	call MatchButtonCode
	and a
	jr nz, .code2
;>     wCheatFlags |= 0x08
	ld a, [wCheatFlags]
	set 3, a
	ld [wCheatFlags], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.code2:
;> if hUfoFlags & 0x02:                 # the UFO is on screen
	ldh a, [hUfoFlags]
	bit 1, a
	jr z, .code3
;>     if MatchButtonCode(CodeInvaderLook3) != 0:
;>         return
	ld de, CodeInvaderLook3
	call MatchButtonCode
	and a
	jr nz, CheatCheckDone
;>     wCheatFlags |= 0x10
	ld a, [wCheatFlags]
	set 4, a
	ld [wCheatFlags], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.code3:
;> if MatchButtonCode(CodeInvaderLook1) == 0:
	ld de, CodeInvaderLook1
	call MatchButtonCode
	and a
	jr nz, .code4
;>     wCheatFlags |= 0x04
	ld a, [wCheatFlags]
	set 2, a
	ld [wCheatFlags], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.code4:
;>@c4 if hShotCount == 15 and MatchButtonCode(CodeMarchMode) == 0:
	ldh a, [hShotCount]
	cp $0f
	jr nz, CheatCheckDone

;=@c4
	ld de, CodeMarchMode
	call MatchButtonCode
	and a
	jr nz, CheatCheckDone
;>     wCheatFlags |= 0x20
	ld a, [wCheatFlags]
	set 5, a
	ld [wCheatFlags], a
;>     wHomingLevel += 2
	ld a, [wHomingLevel]
	inc a
	inc a
	ld [wHomingLevel], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

CheatCheckDone:
;> return
	ret


;@ path: game/cheats
;@ In-game code (wCheatFlags bit 3): Up, Down, B, Down, A, Select. Stored newest press first, as
;@ hJoyPressed bytes (A $01, B $02, Select $04, Start $08, Right $10, Left $20, Up $40, Down $80),
;@ ended by 0 (codes have 5 to 8 presses).
CodeInvaderLook2::
	db $04, $01, $80, $02, $80, $40, $00, $00   ; Select, A, Down, B, Down, Up

;@ path: game/cheats
;@ In-game code (bit 4, only while the UFO is on screen): Right, Left, Up, Up, Select, A, Select.
CodeInvaderLook3::
	db $04, $01, $04, $40, $40, $20, $10, $00   ; Select, A, Select, Up, Up, Left, Right
;@ path: game/cheats
;@ In-game code (bit 2): Start, A, B, B, A, Select, Start.
CodeInvaderLook1::
	db $08, $04, $01, $02, $02, $01, $08, $00   ; Start, Select, A, B, B, A, Start

;@ path: game/cheats
;@ In-game code (bit 5, only right after the 15th shot): Up, Up, Right, Left, Down, Down, Select.
CodeMarchMode::
	db $04, $80, $80, $20, $10, $40, $40, $00   ; Select, Down, Down, Left, Right, Up, Up

;@ def CheckTitleCheatCodes()
;@ path: game/cheats
;@ Called by the title screen: looks for the three title-screen codes in wPressHistory while no
;@ secret feature is on yet. They switch on the inverted palette (wCheatFlags bit 0), the
;@ invincible cannon (bit 1) and the homing bombs (wHomingBombs bit 1); each plays sound $1B.
;@ writes: hSfxRequest2, wCheatFlags, wHomingBombs, wPressHistory
;@ reads: wCheatFlags, wHomingBombs
;@ test: skip compares button histories in RAM against ROM codes
;@ sig: 5ae0b654
CheckTitleCheatCodes::
;>@guard if wCheatFlags & 0x80 or wCheatFlags != 0 or wHomingBombs != 0:
;>     return
	ld a, [wCheatFlags]
	bit 7, a
	jp nz, CheatCheckDone

	and a
	jp nz, CheatCheckDone
;=@guard
	ld a, [wHomingBombs]
	and a
	jp nz, CheatCheckDone
;> if MatchButtonCode(CodeInvertPalette) == 0:
	ld de, CodeInvertPalette
	call MatchButtonCode
	and a
	jr nz, .code2
;>     wCheatFlags |= 0x01
	ld a, [wCheatFlags]
	set 0, a
	ld [wCheatFlags], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.code2:
;> if MatchButtonCode(CodeInvincible) == 0:
	ld de, CodeInvincible
	call MatchButtonCode
	and a
	jr nz, .code3
;>     wCheatFlags |= 0x02
	ld a, [wCheatFlags]
	set 1, a
	ld [wCheatFlags], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.code3:
;> if MatchButtonCode(CodeHomingBombs) == 0:
	ld de, CodeHomingBombs
	call MatchButtonCode
	and a
	jr nz, .done
;>     wHomingBombs |= 0x02
	ld a, [wHomingBombs]
	set 1, a
	ld [wHomingBombs], a
;>     wPressHistory[0] = wHomingBombs  # spoils the newest press, so the code cannot match twice
	ld [wPressHistory], a
;>     hSfxRequest2 = 0x1B
	ld a, $1b
	ldh [hSfxRequest2], a

.done:
;> return
	ret


;@ path: game/cheats
;@ Title-screen code (inverted palette): A, Right, B, Up, A, Left, B, Down.
CodeInvertPalette::
	db $80, $02, $20, $01, $40, $02, $10, $01   ; Down, B, Left, A, Up, B, Right, A

;@ path: game/cheats
;@ Title-screen code (invincible cannon): A, B, Right, Left, Up, Down, Right, Left.
CodeInvincible::
	db $20, $10, $80, $40, $20, $10, $02, $01   ; Left, Right, Down, Up, Left, Right, B, A
;@ path: game/cheats
;@ Title-screen code (homing bombs): Right, Left, Right, Left, Right, Left.
CodeHomingBombs::
	db $20, $10, $20, $10, $20, $10, $00, $00   ; Left, Right, Left, Right, Left, Right

;@ def MatchButtonCode(code: de) -> a
;@ path: game/cheats
;@ Compares a secret code (newest press first) with wPressHistory: returns 0 when the last presses
;@ match it, $FF when not. The first five presses are always compared; after that a 0 in the code
;@ ends it early.
;@ test: code = rand(0x7EB4, 0x7EBC)
;@ sig: 913b56f2
MatchButtonCode::
;>@for for i in range(8):
	ld hl, wPressHistory
;>@end     if i >= 5 and mem[code + i] == 0:   # shorter code: all of it matched
;>@end2         return 0
;>     if mem[code + i] != wPressHistory[i]:
;>@ff         return 0xFF
	ld a, [hli]
	ld c, a
	ld a, [de]
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
;=@end
	and a
	jr z, .match
;=@for
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
;=@end
	and a
	jr z, .match
;=@for
	cp c
	jr nz, .different
;=@for
	inc de
	ld a, [hli]
	ld c, a
	ld a, [de]
;=@end
	and a
	jr z, .match
;=@for
	cp c
	jr nz, .different
;> return 0                             # all eight matched

.match:
;=@end2
	ld a, $00
	jr .return

.different:
;=@ff
	ld a, $ff
.return:
	ret


;@ path: unused
;@ Unused space: $FF bytes up to the end of the ROM.
PaddingFF_7F8C::
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
	db $ff, $ff, $ff, $ff
