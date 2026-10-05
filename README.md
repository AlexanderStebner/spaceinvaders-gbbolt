# Space Invaders (Game Boy) - gbbolt disassembly

**Open it: <https://gbbolt.lingora.org/spaceinvaders/>**

A complete, matching disassembly of *Space Invaders* for the Game Boy (Taito, 1990, Japan), with
pseudo-code written next to every function and checked against the original code in an emulator. It
is read with [gbbolt](https://github.com/AlexanderStebner/gbbolt): code and pseudo-code side by
side, each short piece of Python directly above the few instructions that do it.

- **306 of 306 code units** have pseudo-code. 133 are verified by differential testing: the
  pseudo-code and the original code give identical results on 64 random machine states. The other
  173 are checked: they wait for an interrupt, the link cable or a button, or run the game loop, so
  they can't run in isolation.
- **Every routine, table and RAM variable is named**, and everything sits in a virtual folder
  (`invaders/march`, `shields/craters/bomb`, `ufo/score`, `link/sync`, `sound/streams`, ...).
- **Screens, played by the game's own code**: the title, the attract mode, the starting formation
  of every round height, both coffee breaks and the ending.
- **Sound**: the sound engine is fully annotated; its jingles and sound effects are rendered from
  it, with a piano roll and mute / solo per channel.

Some things the code shows:

- One invader moves per frame, as on the arcade machine, so the formation speeds up as it thins
  out, and so does the four-note march.
- The shields are tiles kept in RAM. A hit cuts a crater into them pixel by pixel: one of 48
  unrolled routines (one per shield tile, for bombs and for the shot) shifts the crater mask onto
  the point of the hit.
- The game writes VRAM from the HBlank interrupt, one tile pair at a time, through tiny hook
  routines at `$0071`-`$00EF` that it selects by the low byte of their address.
- What the UFO is worth depends on the number of shots fired: the 8th shot, and every 15th after
  it, gives 300 points.
- Seven button codes and three orders of shooting the invaders switch on secret features: an
  invincible cannon, homing bombs, other invader shapes, a formation that never comes down, rebuilt
  shields, a round without bombs. Holding Down and Select while firing with B makes the shot home in
  on the UFO.
- Two players can play over the link cable; the opponent's cannon flies across the top of the screen
  in place of the UFO.
- In the attract mode the Y of PLAY sometimes stands on its head, and an invader comes and puts it
  right.

## Building

The disassembly rebuilds the original ROM byte for byte. You need
[RGBDS](https://rgbds.gbdev.io) 1.0.1, Python 3.9+ with numpy, and gbbolt next to this folder:

```
git clone https://github.com/AlexanderStebner/gbbolt
git clone https://github.com/AlexanderStebner/spaceinvaders-gbbolt
cd spaceinvaders-gbbolt
python ../gbbolt/tools/audio.py             # render the sounds (needs ffmpeg)
python ../gbbolt/tools/gbbolt.py            # build, verify, write out/site/index.html
```

The build is checked against the SHA1 of the original ROM
(`9e94553ecb76e95eb85a5f8fbbb201b96271710a`, *Space Invaders (Japan)*). No ROM is needed to build it.
If you put your own dump next to `game.json` as `spaceinvaders.gb`, it is compared byte by byte.

## Layout

```
game.json           what gbbolt needs to know about the game
src/game.asm        the main file
src/bank_000.asm    the disassembly with its annotations
src/ram.inc         RAM variables: names, types, descriptions
src/hardware.inc    hardware registers
src/folders.txt     the virtual folders
src/intro.md        the book's first chapter: from power-on to the first shot
src/sound.json      how to drive the sound engine
assets/*.py         asset plugins: title and attract mode, rounds, coffee breaks, ending
```

## Legal

Space Invaders and its code, graphics and music are the property of their respective owners (Taito).
This repository contains no ROM. It is a research and documentation project in the tradition of other
community disassemblies; please buy the game.

The annotations, names, pseudo-code, descriptions, plugins and configuration written for this project
are available under the MIT license (see [LICENSE](LICENSE)), as far as they are separable from the
game itself.
