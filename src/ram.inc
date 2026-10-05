; Named RAM / IO addresses.
; Format: DEF name EQU $addr ;@ type description
;   type: u8 | u16 (little endian) | u8[N] | code[N] | const
; Lines without ";@" are plain constants.

DEF wCraterScratch EQU $D200 ;@ u8[96] Six-tile scratch area (3 columns of 2 tiles, column-major: 0 top left, 1 bottom left, 2 top middle ...) where a crater mask is moved into place before it is cut out of a shield; all $FF between uses
DEF wShield0Tiles EQU $D300 ;@ u8[96] RAM copy of the 6 tiles of shield 0 (tiles $5A-$5F), same layout as wCraterScratch
DEF wShield1Tiles EQU $D400 ;@ u8[96] RAM copy of the 6 tiles of shield 1 (tiles $60-$65)
DEF wShield2Tiles EQU $D500 ;@ u8[96] RAM copy of the 6 tiles of shield 2 (tiles $66-$6B)
DEF wShield3Tiles EQU $D600 ;@ u8[96] RAM copy of the 6 tiles of shield 3 (tiles $6C-$71)
DEF wBombCraterMask EQU $D700 ;@ u8[16] 8x8 tile mask (0 bits = hole) that an invader bomb cuts into a shield
DEF wShotCraterMask EQU $D710 ;@ u8[16] 8x8 tile mask (0 bits = hole) that the cannon's shot cuts into a shield
DEF hHitPixelX EQU $FFBC ;@ u8 Column (0-7) of the probed pixel inside its tile; the crater shift helpers reuse it for their shift count
DEF hHitPixelY EQU $FFBD ;@ u8 Row (0-7) of the probed pixel inside its tile; the crater shift helpers reuse it for a start offset
DEF hHitTile EQU $FFBE ;@ u8 Background tile under the probe point ($5A-$71 = shield tiles)
DEF hShieldCheckIndex EQU $FFBF ;@ u8 Bomb being checked against the shields (0-2); for the cannon's shot the probe column counter
DEF hProbeCount EQU $FFC0 ;@ u8 Count-down of probe points still to test for the current bomb or shot column
DEF hBombActiveBits EQU $FFC1 ;@ u8 hActiveShots rotated so that bit 7 is the bomb being checked
DEF hBombOamLow EQU $FFC2 ;@ u8 Low byte of the OAM-buffer entry (at $C0xx) of the bomb being checked
DEF hVramAddrHi EQU $FF99 ;@ u8 High byte of the VRAM address the LCD hook reads or writes
DEF hVramAddrLo EQU $FF9A ;@ u8 Low byte of the VRAM address the LCD hook reads or writes
DEF hVramData0 EQU $FF9B ;@ u8 First byte read from (or to write to) VRAM by the LCD hook
DEF hVramData1 EQU $FF9C ;@ u8 Second byte read from VRAM by the LCD hook
DEF hLcdHook EQU $FF91 ;@ u8 Low byte of the LCD-interrupt handler to run at $00xx (0 = none); the handler clears it when done
DEF hSavedIE EQU $FF93 ;@ u8 rIE saved while a VRAM access through the LCD hook is pending
DEF hActiveShots EQU $FFDC ;@ u8 Bit 0: the cannon's shot is flying; bit 1: the opponent's shot in a link game; bits 2-4: invader bombs 0-2 are falling
DEF hShotFlags EQU $FFE7 ;@ u8 Cannon-shot state bits; bit 4: the shot has hit something and explodes
DEF hBombFlags EQU $FFE9 ;@ u8[3] One state byte per invader bomb; bit 5: the bomb has hit something and explodes
DEF wShotSpriteY EQU $C010 ;@ u8 OAM-buffer Y of the cannon's shot sprite
DEF wShotSpriteX EQU $C011 ;@ u8 OAM-buffer X of the cannon's shot sprite
DEF wShotSpriteTile EQU $C012 ;@ u8 OAM-buffer tile of the cannon's shot sprite ($0A = explosion)
DEF hLinkShotFlags EQU $FFE8 ;@ u8 State bits of the opponent's shot in link mode; bit 4: it has hit something and explodes
DEF wCannonSpriteY EQU $C008 ;@ u8 OAM-buffer Y of the cannon sprite
DEF wCannonSpriteX EQU $C009 ;@ u8 OAM-buffer X of the cannon sprite
DEF wUfoSpriteY EQU $C00C ;@ u8 OAM-buffer Y of the UFO sprite (in link mode: the opponent's cannon at the top)
DEF wUfoSpriteX EQU $C00D ;@ u8 OAM-buffer X of the UFO sprite (in link mode: the opponent's cannon at the top)
DEF wLinkShotSpriteY EQU $C014 ;@ u8 OAM-buffer Y of the opponent's shot in link mode (falls from the top)
DEF wLinkShotSpriteX EQU $C015 ;@ u8 OAM-buffer X of the opponent's shot in link mode
DEF wLinkShotSpriteTile EQU $C016 ;@ u8 OAM-buffer tile of the opponent's shot ($0A = explosion)
DEF wBomb0SpriteY EQU $C018 ;@ u8 OAM-buffer Y of invader bomb 0
DEF wBomb0SpriteX EQU $C019 ;@ u8 OAM-buffer X of invader bomb 0
DEF wBomb0SpriteTile EQU $C01A ;@ u8 OAM-buffer tile of invader bomb 0 ($0A = explosion)
DEF wBomb1SpriteY EQU $C01C ;@ u8 OAM-buffer Y of invader bomb 1
DEF wBomb1SpriteX EQU $C01D ;@ u8 OAM-buffer X of invader bomb 1
DEF wBomb1SpriteTile EQU $C01E ;@ u8 OAM-buffer tile of invader bomb 1 ($0A = explosion)
DEF wBomb2SpriteY EQU $C020 ;@ u8 OAM-buffer Y of invader bomb 2
DEF wBomb2SpriteX EQU $C021 ;@ u8 OAM-buffer X of invader bomb 2
DEF wBomb2SpriteTile EQU $C022 ;@ u8 OAM-buffer tile of invader bomb 2 ($0A = explosion)
DEF wCheatFlags EQU $D122 ;@ u8 Secret features: bit 0 inverted palette, bit 1 invincible cannon, bit 6 the shot in flight homes in on the UFO, bit 7 homing shot not allowed
DEF wHomingBombs EQU $D123 ;@ u8 Homing invader bombs: bit 0 bomb 0 steers toward the cannon, bit 1 bomb 1 always homes, bit 2 bomb 1 steers toward the cannon
DEF wBomb0TargetX EQU $D124 ;@ u8 X that homing bomb 0 steers toward (cannon X + 3, taken while it tracks)
DEF wBomb1TargetX EQU $D125 ;@ u8 X that homing bomb 1 steers toward (cannon X + 3, taken while it tracks)
DEF wBomb0HomingTimer EQU $D126 ;@ u8 Frame counter of homing bomb 0, counts down from 0; at $EC and above the bomb only notes the cannon's X
DEF wBomb1HomingTimer EQU $D127 ;@ u8 Frame counter of homing bomb 1, counts down from 0; at $E5 and above the bomb only notes the cannon's X
DEF hLinkFlags EQU $FFD7 ;@ u8 Bit 0: two-player link-cable game
DEF hUfoFlags EQU $FFDA ;@ u8 UFO state bits; bit 1: the UFO (or the opponent's cannon) is on screen; bit 7: it has been hit
DEF hSerialOut EQU $FFC7 ;@ u8 Byte sent to the other Game Boy at the next link exchange
DEF hSerialIn EQU $FFC8 ;@ u8 Last byte received over the link cable ($E4 = the other Game Boy wants a link game)
DEF hUfoHitCode EQU $FFC9 ;@ u8 hSerialIn at the moment the UFO or the opponent was hit
DEF hGameMode EQU $FFD8 ;@ u8 Game phase: 0 = title sequence, $55 = a game is running; other values mark how the last game or stage ended
DEF hSyncFlags EQU $FFC6 ;@ u8 Frame and link flags; bit 0: a link partner answered, the frame handler exchanges link bytes
DEF hJoyPressed EQU $FF8F ;@ u8 Buttons newly pressed this frame (bit 0 A, 1 B, 2 Select, 3 Start, 4 Right, 5 Left, 6 Up, 7 Down)
DEF hJoyHeld EQU $FF90 ;@ u8 Buttons held this frame (same bits as hJoyPressed)
DEF hHiScoreLo EQU $FFCF ;@ u8 Hi-score, low two BCD digits
DEF hHiScoreHi EQU $FFD0 ;@ u8 Hi-score, high two BCD digits
DEF hSavedOBP0 EQU $FFE4 ;@ u8 rOBP0 saved while the title screen hides the sprites
DEF hShieldUploadTile EQU $FFA1 ;@ u8 Tile (0-5) of the shield that the frame handler copied to VRAM last
DEF hShieldUploadSrcHi EQU $FFA2 ;@ u8 High byte of the RAM shield tile ($D3-$D6) the frame handler copies next
DEF hShieldUploadSrcLo EQU $FFA3 ;@ u8 Low byte of the RAM shield tile the frame handler copies next
DEF hShieldUploadDstHi EQU $FF9D ;@ u8 High byte of the VRAM address the next shield tile is copied to
DEF hShieldUploadDstLo EQU $FF9E ;@ u8 Low byte of the VRAM address the next shield tile is copied to
DEF hUnusedA7 EQU $FFA7 ;@ u8 Cleared when the shields are reset, never read
DEF hMainHook EQU $FF92 ;@ u8 Low byte of a VRAM-access routine at $00xx that the VBlank handler runs once and then clears (0 = none)
DEF hUnusedFF95 EQU $FF95 ;@ u8 Cleared when the screen is switched on; nothing reads it
DEF hShieldUpload EQU $FFA4 ;@ u8 Nonzero: VBlank copies one shield tile (16 bytes) from RAM to VRAM per frame
DEF hWipeRow EQU $FFA5 ;@ u8 Screen wipe: next background row to clear (0-17), then 18 = draw the header, 19 = done
DEF hInvadersLeft EQU $FFAA ;@ u8 Invaders still alive (40 at the start of a round); also sets the march tempo
DEF hMarchNote EQU $FFB1 ;@ u8 Which of the four notes of the marching beat comes next (1-4, 0 = none yet)
DEF hFrameCounter EQU $FFB4 ;@ u8 Counts VBlanks; the march beat resets it
DEF hUnusedFFB5 EQU $FFB5 ;@ u8 Set to 1 with hSoundOff; nothing reads it
DEF hSoundOff EQU $FFB6 ;@ u8 Nonzero: VBlank silences the sound (and clears it again)
DEF hSfxRequest EQU $FFB7 ;@ u8 Sound effect to start at the next VBlank (0 = none); beats hSfxRequest2
DEF hMarchSfxRequest EQU $FFB8 ;@ u8 March-beat note (or other top-priority sound) to start at the next VBlank (0 = none)
DEF hSfxRequest2 EQU $FFB9 ;@ u8 Sound effect to start at the next VBlank, lowest priority (0 = none)
DEF hPointsToAdd EQU $FFBA ;@ u8 Points (BCD, in tens) to add to the score at the next AddScore
DEF hSerialFrame EQU $FFCA ;@ u8 Counts VBlanks; a byte is sent every second frame
DEF hScoreLo EQU $FFCD ;@ u8 Score, low two BCD digits (the score is kept in tens; a fixed 0 is drawn after it)
DEF hScoreHi EQU $FFCE ;@ u8 Score, high two BCD digits
DEF hNextLifeHi EQU $FFD2 ;@ u8 Score (high BCD byte) at which the next extra cannon is given
DEF hNextLifeLo EQU $FFD3 ;@ u8 Score (low BCD byte) at which the next extra cannon is given
DEF hExtraLivesGiven EQU $FFD4 ;@ u8 Extra cannons given so far (at most 7 are checked)
DEF hRound EQU $FFD5 ;@ u8 Round number (BCD, 1 at the start)
DEF hTimerHi EQU $FFDD ;@ u8 High byte of a 16-bit counter that VBlank raises by 4 per frame (link timeouts; the UFO appears when it reaches $14)
DEF hTimerLo EQU $FFDE ;@ u8 Low byte of the VBlank counter
DEF hIEMask EQU $FFDF ;@ u8 Interrupts enabled when the screen is switched on ($0F, or $0D in a link game)
DEF hLives EQU $FFE0 ;@ u8 Cannons in reserve
DEF hOpponentLives EQU $FFE1 ;@ u8 Link game: the other player's cannons in reserve, as last received
DEF hShotCount EQU $FFE2 ;@ u8 Shots fired, counting 1-15 round and round (picks the UFO score)
DEF hTemp EQU $FFE3 ;@ u8 Scratch byte (loop counters, the READY text's Y)
DEF wShadowOam EQU $C000 ;@ u8[160] Copy of the sprite table, sent to OAM by DMA every VBlank
DEF wCannonRightX EQU $C001 ;@ u8 OAM-buffer X of the cannon's right half (cannon X + 8)
DEF wCannonRightTile EQU $C002 ;@ u8 OAM-buffer tile of the cannon's right half
DEF wCannonLeftTile EQU $C00A ;@ u8 OAM-buffer tile of the cannon's left half
DEF wPauseTimerHi EQU $D11C ;@ u8 hTimerHi saved during the pause
DEF wPauseTimerLo EQU $D11D ;@ u8 hTimerLo saved during the pause
DEF wSoundQueueEnd EQU $D800 ;@ u8 Sound queue: index of the last queued sound
DEF wSoundQueuePos EQU $D801 ;@ u8 Sound queue: index of the last sound started; a sound starts when it differs from wSoundQueueEnd
DEF wSoundQueue EQU $D802 ;@ u8[16] Sound queue (VBlank only ever uses entry 1)
DEF hUfoSubX EQU $FFDB ;@ u8 Fraction of the UFO's X position: $AA is added every frame, so the UFO moves 2 pixels in 3 frames
DEF hUfoHitTimer EQU $FFE5 ;@ u8 Counts up after the UFO is hit: 0-$1F explosion (tile swaps at bit 3), $20 award the points, $40-$7F show them, $80 remove the UFO
DEF hUfoPoints EQU $FFD1 ;@ u8 Points of the UFO just hit, in tens, packed BCD ($05 = 50, $30 = 300); shown where the UFO was
DEF hMarchPtrHi EQU $FFA8 ;@ u8 High byte of the wInvaders entry that moves next
DEF hMarchPtrLo EQU $FFA9 ;@ u8 Low byte of the wInvaders entry that moves next
DEF hMarchToGo EQU $FFAB ;@ u8 Invaders still to move in this sweep of the formation (the sweep ends when it equals hMarchRemoved)
DEF hMarchRemoved EQU $FFAC ;@ u8 Invaders removed from wInvaders during this sweep (they are not moved any more)
DEF hMarchPhase EQU $FFAD ;@ u8 Fine X step of the formation: 0, 2, 4 or 6 pixels into a tile (picks one of 4 shifted invader tile pairs)
DEF hMarchLeftward EQU $FFAE ;@ u8 1 while the formation marches left, 0 while it marches right
DEF hMarchEdgeHit EQU $FFAF ;@ u8 Non-zero once an invader touched a screen edge in this sweep: the next sweep moves the formation down
DEF hMarchDescend EQU $FFB0 ;@ u8 Non-zero during a sweep that moves the formation one row down instead of sideways
DEF hMarchFlags EQU $FFA6 ;@ u8 Bit 0: this sweep wipes the formation off the screen (a secret code); bit 3: a secret-code effect ran
DEF hHitLoopCount EQU $FFBB ;@ u8 Invaders still to test against the cannon's shot
DEF hUfoTargetX EQU $FFCC ;@ u8 X the opponent's cannon sprite (in link mode) should move to: 160 minus the opponent's own X
DEF wFormationDrop EQU $CFFF ;@ u8 How many rows (of 8 pixels) lower the formation starts in this round
DEF wInvaders EQU $D000 ;@ u8[280] The formation: 40 entries of 7 bytes, bottom row first: tile, VRAM address (hi, lo), X, Y, bomb turn (0 = has an invader below it), number 1-40
DEF wBombRateMask EQU $D118 ;@ u8 Invaders drop a bomb only when hTimerHi AND this is non-zero ($1F in the first rounds, less later; 0 = no bombs)
DEF wBombHoldoff EQU $D119 ;@ u8 Sweeps left before the invaders may drop their first bomb
DEF wLastKill EQU $D11A ;@ u8 Number (1-40) of the invader removed last, for the secret kill orders ($FF = stop checking); cleared once read
DEF wKillCount EQU $D11B ;@ u8 How many numbers are in wKillOrder
DEF wKillOrder EQU $D720 ;@ u8[40] Numbers of the invaders in the order they were shot, compared against the secret kill orders
DEF wKillCodeFlags EQU $D120 ;@ u8 Secret kill order found: bit 0 wipe and rebuild the formation, bit 3 repair the shields, bit 4 no more bombs; bit 7 done (no more checks)
DEF wHomingLevel EQU $D121 ;@ u8 Raised in the secret modes as the rounds go by; from 9 bomb 0 homes in on the cannon, from $31 bomb 1 does too
DEF wUfoRightSpriteY EQU $C004 ;@ u8 OAM-buffer Y of the UFO's right half
DEF wUfoRightSpriteX EQU $C005 ;@ u8 OAM-buffer X of the UFO's right half (wUfoSpriteX + 8)
DEF wUfoRightSpriteTile EQU $C006 ;@ u8 OAM-buffer tile of the UFO's right half (also the last digit of its points)
DEF wUfoRightSpriteAttr EQU $C007 ;@ u8 OAM-buffer attributes of the UFO's right half ($20 = mirrored, so one tile draws both halves)
DEF wUfoSpriteTile EQU $C00E ;@ u8 OAM-buffer tile of the UFO's left half ($01 UFO, $05 opponent's cannon, $0B/$0C explosion, or the first digit of its points)
DEF wUfoSpriteAttr EQU $C00F ;@ u8 OAM-buffer attributes of the UFO's left half
DEF wUfoZeroSpriteY EQU $C048 ;@ u8 OAM-buffer Y of the "0" sprite after the UFO's points
DEF wUfoZeroSpriteX EQU $C049 ;@ u8 OAM-buffer X of the "0" sprite after the UFO's points
DEF wUfoZeroSpriteTile EQU $C04A ;@ u8 OAM-buffer tile of the "0" sprite after the UFO's points
DEF wLivesDigitTile EQU $C03A ;@ u8 OAM-buffer tile of the sprite that shows hLives
DEF wOpponentLivesDigitTile EQU $C02E ;@ u8 OAM-buffer tile of a digit sprite: hOpponentLives in a link game, a score digit otherwise
DEF wSceneFlags EQU $D11E ;@ u8 State bits of the attract and link-result scenes: bit 0 animation frame, bit 1 arrived / text shown, bit 2 Start pressed, bit 3 a link request came in, bit 4 A+B were held when the demo began (the score-table invaders animate); in the demo bit 5 the walking invader carries the Y, bit 6 the Y has been swapped, bit 7 it walks right
DEF wAttractCount EQU $D11F ;@ u8 Counts the runs of the score-table demo; bit 0 picks which way the upside-down Y is handled
DEF wPressHistory EQU $D128 ;@ u8[8] The last eight button presses (one hJoyPressed byte each), newest first; the secret codes are matched against it
DEF wPressCount EQU $D130 ;@ u8 Counts button presses (raised with every new entry in wPressHistory)
DEF wSndCh1 EQU $D131 ;@ u8[8] Sound engine state of pulse channel 1: +0 hardware channel (0), +1 flags (bit 0 playing, bit 1 start at the next tick), +2 priority, +3/+4 stream pointer, +7 NRx1 value (duty and length)
DEF wSndCh2 EQU $D139 ;@ u8[8] Sound engine state of pulse channel 2 (same layout as wSndCh1, +0 = 1)
DEF wSndCh3 EQU $D141 ;@ u8[8] Sound engine state of the wave channel 3 (same layout as wSndCh1, +0 = 2)
DEF wSndCh4 EQU $D149 ;@ u8[8] Sound engine state of the noise channel 4 (same layout as wSndCh1, +0 = 3)
DEF wSndNR52 EQU $D151 ;@ u8 rNR52 read at the start of a sound tick: bits 0-3 tell which channels are still sounding
DEF hPixelY EQU $FF8B ;@ u8 Screen Y (sprite coordinates) converted by the unused map-address helpers
DEF hPixelX EQU $FF8C ;@ u8 Screen X (sprite coordinates) converted by the unused map-address helpers
DEF hMapAddrHi EQU $FF8D ;@ u8 High byte of the BG-map address of the unused map-address helpers
DEF hMapAddrLo EQU $FF8E ;@ u8 Low byte of the BG-map address of the unused map-address helpers
DEF hWeaponStock EQU $FFD6 ;@ u8 Link game: cannons each player starts with, picked in the menu (1, 3 or 5)
DEF hUnusedED EQU $FFED ;@ u8[6] Six bytes cleared together with the shields and never used otherwise
DEF hRoundFlags EQU $FFD9 ;@ u8 Bit 0: the round number was already advanced for the cleared formation (reset when the next formation is drawn)
DEF hOamDma EQU $FF80 ;@ code[10] OAM DMA routine, copied here from ROM at power-on (the CPU can only run from HRAM during the DMA)
