"""The secret codes: what to press, when, and what it does, with the game's own pictures of the effects.

Every code below was entered as button presses into the running game and the game's flags checked
afterwards; the pictures are what the game then draws. To reach later rounds the plugin tells the
game the round was cleared (hRound set, hInvadersLeft = 0), as the scenes plugin does.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _game import Machine  # noqa: E402

GROUP = 'secrets'
A, B, SELECT, START, RIGHT, LEFT, UP, DOWN = 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80
NAMES = {A: 'A', B: 'B', SELECT: 'SELECT', START: 'START', RIGHT: '→', LEFT: '←', UP: '↑', DOWN: '↓'}
HOLD = 6                                        # frames each button is held, and released after it

TITLE_CODES = [
    ('CodeInvertPalette', [A, RIGHT, B, UP, A, LEFT, B, DOWN],
     'The game is played in inverted shades: dark background, light invaders.', 'wCheatFlags', 0x01),
    ('CodeInvincible', [A, B, RIGHT, LEFT, UP, DOWN, RIGHT, LEFT],
     'The cannon can\'t be hit: bombs fall through it.', 'wCheatFlags', 0x02),
    ('CodeHomingBombs', [RIGHT, LEFT, RIGHT, LEFT, RIGHT, LEFT],
     'From the first round on, one of the invaders\' bombs steers toward the cannon (otherwise they '
     'only start doing that in later rounds).', 'wHomingBombs', 0x02),
]
GAME_CODES = [
    ('CodeInvaderLook1', [START, A, B, B, A, SELECT, START], 'any time (START pauses, the last START goes on)',
     'Every invader of the next round has the shape of the bottom rows.', 0x04),
    ('CodeInvaderLook2', [UP, DOWN, B, DOWN, A, SELECT], 'any time',
     'Every invader of the next round has the shape of the middle rows.', 0x08),
    ('CodeInvaderLook3', [RIGHT, LEFT, UP, UP, SELECT, A, SELECT], 'while the UFO is on screen',
     'Every invader of the next round has the shape of the top row.', 0x10),
    ('CodeMarchMode', [UP, UP, RIGHT, LEFT, DOWN, DOWN, SELECT], 'right after the 15th shot of the round',
     'The formation turns at the edges without coming down. The bombs get more dangerous.', 0x20),
]
KILL_ORDERS = [
    ('KillOrderRebuild', 'The bottom row from right to left, 8 down to 1.',
     'At the end of the next sweep every invader is wiped off and a full new formation is built.'),
    ('KillOrderShields', 'First invader 8, then invader 1.', 'The four shields are back as new.'),
    ('KillOrderNoBombs', 'Columns 8, 6, 4 and 2, each from the bottom up (20 invaders).',
     'No more bombs for the rest of the round.'),
]


def buttons(code):
    return [{'tag': NAMES[b]} for b in code]


def enter(m, code):
    sched, f = [], 0
    for b in code:
        sched.append((f, b, HOLD))
        f += 2 * HOLD
    m.play(sched, f + 20)


def run_frames(m, n):
    for _ in range(n):
        m.frame()


def bcd(n):
    return (n // 10) << 4 | n % 10


def new_round(m):
    """Run until the round is under way: READY! is gone and the formation marches."""
    for _ in range(600):
        m.frame()
        if m.get('hGameMode') == 0x55:
            break
    run_frames(m, 160)


def next_round(m, current):
    m.play([(0, LEFT, 3)], 8)                   # one more press, so a code is not found a second time
    m.set('hRound', bcd(current))
    m.set('hInvadersLeft', 0)
    m.frame()
    new_round(m)


def start_game(m):
    m.play([(1100, START, 5), (1300, START, 5)], 1310)   # START on the title, START on "1 PLAYER"
    new_round(m)


def check(ok, what):
    if not ok:
        raise RuntimeError('secret code not taken: ' + what)


def image(ctx, rows, marks=None, scale=2):
    out = {'type': 'image', 'width': 160, 'height': 144, 'pixels': ctx.pixels(rows), 'scale': scale}
    if marks:
        out['marks'] = marks
    return out


def invader_marks(ctx, m, order=None):
    """Boxes over the invaders, from their tilemap addresses in wInvaders: numbered 1-40, or by place
    in `order`."""
    base = ctx.addr('wInvaders')
    scx, scy = m.mem[0xFF43], m.mem[0xFF42]
    rows = m.screen()
    marks = []
    for i in range(40):
        e = base + 7 * i
        vram = m.mem[e + 1] << 8 | m.mem[e + 2]
        num = m.mem[e + 6]
        if order is not None and num not in order:
            continue
        col, row = (vram - 0x9800) % 32, (vram - 0x9800) // 32
        tx, ty = (col * 8 - scx) % 256, (row * 8 - scy) % 256
        # the march shifts the picture inside its two tiles: box the invader's own pixels
        ink = [(x, y) for y in range(ty, min(ty + 8, 144)) for x in range(tx, min(tx + 16, 160)) if rows[y][x]]
        if not ink:
            continue
        x0, x1 = min(p[0] for p in ink), max(p[0] for p in ink)
        y0, y1 = min(p[1] for p in ink), max(p[1] for p in ink)
        x, y, w, h = x0 - 1, y0 - 1, x1 - x0 + 3, y1 - y0 + 3
        label = str(order.index(num) + 1) if order is not None else str(num)
        marks.append({'x': x, 'y': y, 'w': w, 'h': h, 'label': label,
                      'text': 'invader {}'.format(num) + ('' if order is None else
                                                          ', shot {}.'.format(order.index(num) + 1))})
    return marks


def kill_order(ctx, label):
    a, out = ctx.addr(label), []
    while ctx.rom[a]:
        out.append(ctx.rom[a])
        a += 1
    return out


def build(ctx):
    # The title codes: each typed while the logo scrolls up, then a game started.
    title_rows = []
    for label, code, effect, var, bit in TITLE_CODES:
        m = Machine(ctx)
        m.play([], 150)                         # the logo has started to scroll
        enter(m, code)
        check(m.get(var) & bit, label)
        picture = ''
        if label == 'CodeInvertPalette':
            m.play([(0, START, 5), (200, START, 5)], 210)
            new_round(m)
            picture = {'image': image(ctx, m.screen(), scale=1)}
        title_rows.append([buttons(code), effect, picture, {'text': label, 'code': label}])

    # The in-game codes, in one game: a look code in round 1 shows in round 2, and so on.
    m = Machine(ctx)
    start_game(m)
    formation = m.screen()
    numbers = invader_marks(ctx, m)
    orders = [(label, kill_order(ctx, label), how, effect) for label, how, effect in KILL_ORDERS]
    kill_pics = {label: invader_marks(ctx, m, order) for label, order, _, _ in orders}

    looks = {}
    rnd = 1
    for label, code, when, effect, bit in GAME_CODES[:3]:
        if label == 'CodeInvaderLook3':
            m.set('hTimerHi', 0x13)             # call the UFO a little early
            for _ in range(1500):
                m.frame()
                if m.get('hUfoFlags') & 0x02:
                    break
        enter(m, code)
        check(m.get('wCheatFlags') & bit, label)
        next_round(m, rnd)
        looks[label] = {'image': image(ctx, m.screen(), scale=1)}
        next_round(m, rnd + 1)                  # the look is gone again
        rnd += 2

    label, code, when, effect, bit = GAME_CODES[3]
    for _ in range(40):                         # fire until the shot counter stands at 15
        if m.get('hShotCount') == 15:
            break
        m.play([(0, A, 3)], 4)
        for _ in range(300):
            m.frame()
            if not m.get('hActiveShots') & 0x01:
                break
    enter(m, code)
    check(m.get('wCheatFlags') & bit, label)

    game_rows = [[buttons(c), when, e, looks.get(lb, ''), {'text': lb, 'code': lb}]
                 for lb, c, when, e, _ in GAME_CODES]
    kill_rows = [[how, effect, {'image': image(ctx, formation, kill_pics[lb], scale=1)}, {'text': lb, 'code': lb}]
                 for lb, order, how, effect in orders]

    how = [
        'The game keeps the last eight new button presses (ReadJoypad, wPressHistory) and compares them '
        'with the codes, newest press first (MatchButtonCode). A press counts when the button goes down; '
        'two buttons going down together make one press that matches nothing. Each button has to be held '
        'for a moment and let go before the next.',
        'Title codes: they are only checked while the SPACE INVADERS logo scrolls up from the bottom, about '
        'nine seconds (TitleIntro, CheckTitleCheatCodes). Once the logo stands still, presses are still '
        'recorded but nothing looks at them. While it scrolls the buttons are read only about every fourth '
        'frame, so quick taps can be missed. When the title comes round again in the attract mode the logo '
        'scrolls again, and with it comes another chance. A high beep (sound $1B) says a code was taken; '
        'then press START.',
        'Only one title code per game: once one is on, the others are no longer checked. The inverted shades '
        'and the invincible cannon also switch the in-game codes off for the whole game, and all of it is '
        'reset when the game ends (Start).',
        'In-game codes: checked on every pass of the game loop in a one-player game, again only while no '
        'other one is on (CheckGameCheatCodes). The invader shapes are picked when a round is set up '
        '(SetupFormation), so a look code changes the next round, not the current one. When a round is '
        'cleared and the next round is odd, the code is switched off again (CheckRoundClear). A look code '
        'entered in round 1, 3, 5, ... shows in round 2, 4, 6, ..., but one entered in an even round '
        'is gone before it can show. The formation code works at once. Each time a code is switched off '
        'this way the bombs get a little more dangerous (wHomingLevel).',
        'While the UFO is on screen only the UFO code is looked for: the other three can\'t be found then.',
    ]
    shots = [
        'Kill orders: the game writes down the number of every invader shot in the round (wKillOrder, '
        'CheckKillOrder) and compares the first ones with three orders. So it counts from the first '
        'invader shot in a round. One kill order per round; it is carried out at the end of the next sweep '
        'of the formation (EndMarchSweep). In the pictures the invaders of each order are marked; '
        'pointing at one says when to shoot it.',
        'The homing shot: holding ↓ and SELECT while firing with B, with the UFO on screen, makes the shot '
        'steer toward the UFO (MoveCannonAndFire).',
    ]
    return [{
        'name': 'secret-codes', 'type': 'card', 'title': 'Secret codes',
        'subtitle': '{} button codes, {} kill orders'.format(len(TITLE_CODES) + len(GAME_CODES), len(KILL_ORDERS)),
        'summary': 'what to press, when, and what it does',
        'sections': [
            {'title': 'How the codes are read', 'text': how, 'wide': True},
            {'title': 'On the title screen, while the logo scrolls up',
             'columns': ['press in this order', 'what it does', 'in the game', 'code'],
             'rows': title_rows, 'wide': True},
            {'title': 'During a one-player game',
             'columns': ['press in this order', 'when', 'what it does', 'the next round', 'code'],
             'rows': game_rows, 'wide': True},
            {'title': 'Shooting orders', 'text': shots, 'wide': True},
            {'title': 'Kill orders, counted from the first invader shot in a round',
             'columns': ['shoot', 'what it does', 'the order', 'table'],
             'rows': kill_rows, 'wide': True},
        ],
        'doc': ['Every code here was typed into the running game as button presses and checked against the '
                'game\'s flags; the pictures are what the game then draws. To show later rounds the game was '
                'told the round before was cleared (hRound set, hInvadersLeft = 0), and for the UFO code the '
                'UFO was called a little early (hTimerHi).'],
        'users': ['CheckTitleCheatCodes', 'CheckGameCheatCodes', 'MatchButtonCode', 'ReadJoypad',
                  'CheckKillOrder', 'MatchKillOrder', 'MoveCannonAndFire'],
    }, {
        'name': 'invader-numbers', 'type': 'image', 'title': 'The invaders\' numbers',
        'width': 160, 'height': 144, 'pixels': ctx.pixels(formation), 'scale': 2, 'marks': numbers,
        'doc': ['Round 1 as it starts, with the number each invader has in FormationLayout: 1-8 the bottom '
                'row from left to right, 9-16 the row above, up to 33-40 at the top. The kill orders are '
                'lists of these numbers.'],
        'users': ['FormationLayout', 'CheckKillOrder'],
    }]
