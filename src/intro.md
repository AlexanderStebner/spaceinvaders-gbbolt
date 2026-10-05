# From power-on to the first shot

What the code does between switching the Game Boy on and the cannon firing its first shot, in the
order it happens.

## Power on

The CPU starts at `Boot`, which jumps past the header to `Start`. `Start` switches the screen off,
sets the stack, copies the OAM DMA routine into HRAM (`CopyOamDmaRoutine`; during a DMA the CPU can
only run code from there), silences the sound, loads all the tile graphics into VRAM and shows the
developer credit (`ShowDeveloperCredit`), which fades in from white and out again. The end of a game
comes back to `Start` too.

Four interrupts work behind the game:

- **VBlank** (`VBlankHandler`) copies the sprites to OAM, hands the most important sound request to
  the sound engine, counts the frame and a 16-bit timer, runs a VBlank hook if one is set and
  uploads one tile of the shields from RAM to VRAM. Every second frame it also starts the next byte
  over the link cable.
- **The LCD interrupt** is switched to HBlank mode, but it does nothing until the game needs to touch
  VRAM outside VBlank. Then the game puts the low byte of one of the small routines at `$0071`-`$00EF`
  into `hLcdHook`; at the next HBlank, when VRAM is free, `LcdStatHandler` jumps to it, it reads or
  writes one or two tiles and clears the hook. The main code waits for that before it goes on. Every
  invader that marches is moved this way, a tile pair at a time.
- **The timer** (`TimerHandler`) runs the sound engine about 60 times a second.
- **Serial** (`SerialHandler`) takes the byte that came over the link cable.

The game loop isn't paced by VBlank at all: it runs one pass and then waits in a busy loop
(`FrameDelay`, `Delay`).

## The title

`TitleAndMenu` resets the score, the cannons and the round and runs the title sequence. In
`TitleIntro` the SPACE INVADERS logo scrolls up from below. Then the hi-score and the copyright lines
appear in the window. After a while `ShowScoreTableDemo` types PLAY SPACE INVADERS and the score
table. Every second time the Y of PLAY stands on its head and an invader comes to fetch it and puts
it back the right way up. Then the title comes back.

While the logo scrolls, `CheckTitleCheatCodes` compares the last button presses (`wPressHistory`,
kept by `ReadJoypad`) with three secret codes: an inverted palette, an invincible cannon and homing
bombs.

START leads to `SelectGameMode`: 1 PLAYER or 2 PLAYER. Two players play over the link cable, each on
their own Game Boy. Then come the number of cannons (`SelectWeaponStock`) and a long exchange of
single bytes that keeps both machines in step.

## A round

`InitNewGame` sets the score to 0, the round to 1 and two cannons in reserve, with the first extra
cannon at 1500 points. `StartRound` shows ROUND and READY!. It draws the playfield and the four
shields, and `SetupFormation` builds the 40 invaders from `FormationLayout`. Later rounds start
lower: `FormationDropTable` moves them down one more row every second round, up to 7 rows.

`GameLoop` then runs, one pass per frame, until `hGameMode` changes:

- `MoveCannonAndFire`: Left and Right move the cannon a pixel. A or B fires, if no shot is flying.
  The shots are counted 1 to 15, and the count decides what the UFO is worth (`UfoPointsTable`). Hit
  it with the 8th shot, and with every 15th after that, and it gives 300 points.
- `SpawnUfo` / `UpdateUfo`: the UFO comes about every 21 seconds and flies across the top.
- `MarchInvaders`: one invader moves per frame, like on the arcade machine. So the fewer are left,
  the faster each one moves. `PlayMarchStep` plays the four-note march, and it speeds up the same way.
- `InvaderBombTurn` and `DropBomb0`-`2`: invaders with nothing below them take turns dropping up to
  three bombs. Some of the bombs are aimed at the cannon.
- `MoveShotsAndBombs`, then the hit checks. A bomb or the shot that hits a shield cuts a crater
  into it, pixel by pixel. The shields live as tiles in RAM, and one of 48 routines (one per shield
  tile, for bombs and for the shot) lays the crater mask onto the point of the hit.
- `CheckRoundClear`, `CheckInvaded`: when the last invader is gone the next round starts. Coffee
  breaks come after rounds 10 and 20 and the ending after round 30. When the invaders land, the game
  is over.

## Secrets

Besides the three title codes there are four button codes during play (`CheckGameCheatCodes`). They
give the invaders a different look, or make the formation turn at the edges without coming down.
There are also three orders of shooting invaders (`CheckKillOrder`). The bottom row from right to
left rebuilds the formation. Invader 8, then invader 1, restores the shields. Columns 8, 6, 4 and 2,
each from the bottom up, stop the bombs for the rest of the round. And holding Down and Select while
firing with B makes the shot home in on the UFO.
