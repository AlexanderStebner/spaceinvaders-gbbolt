"""The title screen and the attract mode, played by the game's own code from power-on."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import Machine, FRAME_HZ  # noqa: E402

GROUP = 'screens'
TITLE_FRAME = 540                               # the title screen, fully drawn
LOOP = (452, 2374)                              # title, scene, title, the other scene, title


def build(ctx):
    m = Machine(ctx)
    frames = []
    for f in range(LOOP[1]):
        m.frame()
        if f == TITLE_FRAME:
            title = m.screen()
        if f >= LOOP[0]:
            frames.append(m.screen())
    ctx.poster(title, 'title')                  # gen/screens_title.png: the hub's thumbnail
    url = ctx.video(frames, 'attract')
    poster = ctx.poster(frames[700], 'attract')
    return [{
        'name': 'title-screen', 'type': 'image', 'title': 'Title screen',
        'width': 160, 'height': 144, 'pixels': ctx.pixels(title), 'scale': 2,
        'doc': ['The title screen as the game draws it after power-on: the logo, the hi-score and the '
                'copyright lines. START leads to the choice of one or two players.'],
    }, {
        'name': 'attract', 'type': 'video', 'title': 'Attract mode',
        'subtitle': '{} frames, {:.0f} s'.format(len(frames), len(frames) / FRAME_HZ),
        'file': url, 'poster': poster, 'width': 160, 'height': 144, 'fps': FRAME_HZ,
        'doc': ['One full round of the attract mode, played by the game\'s own code without a button '
                'pressed: the title, the PLAY SPACE INVADERS screen with the score table, the title '
                'again and the screen once more. The text is typed in letter by letter. The first time '
                'the Y of PLAY stands upside down: an invader flies in, carries it off and brings it '
                'back the right way up. The second time the screen is just typed.'],
    }]
