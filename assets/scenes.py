"""The rounds' starting formations, the two coffee breaks and the ending, drawn by the game's own code.

A one-player game is started from the mode select. To get to a later round the plugin sets hRound to
the round before it and hInvadersLeft to 0: the game then finds the round cleared and goes on by itself.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import Machine  # noqa: E402

GROUP = 'scenes'
START = 8
DRAWN = 100                                     # frames after a new round starts: the formation is drawn
DROPS = [(1, 1), (3, 2), (5, 3), (7, 4), (9, 5), (19, 6), (29, 7)]   # first round with each start height


USERS = {'coffee-break-1': ['ShowCoffeeBreak1', 'CoffeeBreak1Tiles', 'CheckRoundClear'],
         'coffee-break-2': ['ShowCoffeeBreak2', 'CoffeeBreak2Tiles', 'CheckRoundClear'],
         'ending': ['ShowEnding', 'EndingTiles', 'CheckRoundClear']}


def bcd(n):
    return (n // 10) << 4 | n % 10


def clear_round(m, round_before):
    """Let the game finish the round now: it counts up from round_before."""
    m.set('hRound', bcd(round_before))
    m.set('hInvadersLeft', 0)
    m.frame()


def new_round(m):
    """Run until the next round is under way and its formation drawn."""
    for _ in range(600):
        m.frame()
        if m.get('hGameMode') == 0x55:
            break
    for _ in range(DRAWN):
        m.frame()


def still(ctx, rows):
    return {'width': 160, 'height': 144, 'pixels': ctx.pixels(rows), 'scale': 1}


def build(ctx):
    m = Machine(ctx)
    m.play([(1100, START, 5), (1300, START, 5)], 1310)   # START on the title, START on "1 PLAYER"
    new_round(m)
    rows = []
    for rnd, drop in DROPS:
        if rnd > 1:
            clear_round(m, rnd - 1)
            new_round(m)
        rows.append([rnd, drop, {'image': still(ctx, m.screen())}])

    pictures = []
    for before, name, title in ((10, 'coffee-break-1', 'Coffee break after round 10'),
                                (20, 'coffee-break-2', 'Coffee break after round 20'),
                                (30, 'ending', 'The ending after round 30')):
        clear_round(m, before)
        for _ in range(400):
            m.frame()
        pictures.append((name, title, m.screen()))
        m.play([(0, START, 5)], 20)
        if before < 30:
            new_round(m)

    docs = {
        'coffee-break-1': 'After round 10 the game stops for a coffee break: a picture and "LET\'S START THE NEXT '
                          'GAME!" until START is pressed (ShowCoffeeBreak1, CoffeeBreak1Tiles).',
        'coffee-break-2': 'The second coffee break, after round 20 (ShowCoffeeBreak2, CoffeeBreak2Tiles).',
        'ending': 'After round 30 the game is over for good: the ending picture with THE END in sprites across '
                  'the top (ShowEnding, EndingTiles); START ends the game.',
    }
    out = [{
        'name': 'round-starts', 'type': 'table', 'title': 'Where the formation starts',
        'columns': ['first round', 'rows lower', 'the round as it starts'],
        'rows': rows,
        'doc': ['Every round starts with the same 40 invaders (FormationLayout), but later rounds start them '
                'lower: FormationDropTable gives the number of rows for each round, 1 for rounds 1 and 2 up to '
                '7 from round 29. Each picture is the first round with that height, drawn by the game a moment '
                'after READY!. To get there the game was started for one player and then told that the '
                'round before was cleared (hRound set, hInvadersLeft = 0).'],
        'users': ['FormationDropTable', 'SetupFormation', 'DrawFormation', 'CheckRoundClear'],
    }]
    for name, title, rows_ in pictures:
        out.append({
            'name': name, 'type': 'image', 'title': title,
            'width': 160, 'height': 144, 'pixels': ctx.pixels(rows_), 'scale': 2,
            'doc': [docs[name] + ' Reached the same way: the round before set as cleared.'],
            'users': USERS[name],
        })
    return out
