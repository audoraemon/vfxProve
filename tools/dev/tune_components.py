"""The automatic half of the redraw loop: tune each component's size and colour against the town reference.

Each round tries, for every knob in turn (a decor's scale, then the red, green and blue of every component's tint),
one step up and one step down on all components at once:
1. write src/environment/art/art_tuning.json;
2. render the components once (tools/dev/preview_components.gd);
3. score them with tools/dev/match_components.py;
4. keep, per tuning key, whichever change raised that key's score. Keys are independent, so one render tests
   every component's candidate.
A round that improves nothing halves the steps; the loop stops after --rounds rounds or when the steps get too
small. It never makes a key worse: the file it leaves holds each key's best setting.

Shapes and features are not tunable: those are redrawn by hand (the other half of the loop), and re-measured
with match_components.py.

usage: python tools/dev/tune_components.py [--rounds N] [--below PERCENT] [--keys a,b] [--dry]
  --rounds  most rounds to run (default 8)
  --below   only tune keys whose score is under PERCENT (default 100: all)
  --keys    only these tuning keys
  --dry     report what it would change, and leave art_tuning.json as it was
Needs numpy, scipy and Pillow; runs Godot like match_components.py --render.
"""
import argparse
import copy
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import match_components as mc  # noqa: E402

TUNING = mc.ROOT / 'src' / 'environment' / 'art' / 'art_tuning.json'
## Decor kinds: the only keys whose size can be tuned (a structure's size is its footprint).
DECOR_KEYS = {'barrel', 'crates', 'bench', 'fence', 'garden', 'bush', 'rock', 'oak', 'pine', 'lamp', 'bunting',
              'scarecrow', 'signpost', 'reeds', 'flowers', 'table', 'ship', 'boat', 'dock', 'sheep', 'cow', 'cart'}
BOUNDS = {'scale': (0.7, 1.4), 'r': (0.8, 1.25), 'g': (0.8, 1.25), 'b': (0.8, 1.25)}
## A tint may change a component's brightness freely, but no channel may stray further than this from the tint's
## mean: the score alone would happily turn reeds blue to match the water in their reference crop.
HUE_SPREAD = 0.06
START = {'scale': 0.12, 'r': 0.06, 'g': 0.06, 'b': 0.06}
MIN_STEP = 0.015
GAIN = 0.002


def get(state, key, param):
    e = state.get(key, {})
    if param == 'scale':
        return float(e.get('scale', 1.0))
    return float(e.get('tint', [1.0, 1.0, 1.0])['rgb'.index(param)])


def put(state, key, param, value):
    e = state.setdefault(key, {})
    if param == 'scale':
        e['scale'] = round(value, 3)
    else:
        t = list(e.get('tint', [1.0, 1.0, 1.0]))
        t['rgb'.index(param)] = round(value, 3)
        e['tint'] = keep_hue(t)


def keep_hue(t):
    """Pull every channel to within HUE_SPREAD of the tint's mean."""
    mean = sum(t) / 3.0
    return [round(min(mean + HUE_SPREAD, max(mean - HUE_SPREAD, v)), 3) for v in t]


def clean(state):
    """Drop fields at their defaults, and keys left empty."""
    out = {}
    for key, e in sorted(state.items()):
        f = {}
        if abs(float(e.get('scale', 1.0)) - 1.0) > 1e-6:
            f['scale'] = e['scale']
        t = e.get('tint', [1.0, 1.0, 1.0])
        if any(abs(float(v) - 1.0) > 1e-6 for v in t):
            f['tint'] = t
        if f:
            out[key] = f
    return out


def evaluate(state):
    TUNING.write_text(json.dumps(clean(state), indent=1) + '\n', encoding='utf-8', newline='\n')
    mc.render()
    per_key = {}
    for r in mc.score_all():
        per_key.setdefault(r['key'], []).append(r['total'])
    return {k: sum(v) / len(v) for k, v in per_key.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--rounds', type=int, default=8)
    parser.add_argument('--below', type=float, default=100.0)
    parser.add_argument('--keys')
    parser.add_argument('--dry', action='store_true')
    args = parser.parse_args()
    original = TUNING.read_text(encoding='utf-8') if TUNING.exists() else '{}\n'
    state = json.loads(original)
    for e in state.values():
        if 'tint' in e:
            e['tint'] = keep_hue(e['tint'])
    best = evaluate(state)
    start = dict(best)
    keys = [k for k, v in best.items() if v * 100 < args.below]
    if args.keys:
        wanted = set(args.keys.split(','))
        keys = [k for k in keys if k in wanted]
    print('tuning %d keys: %s' % (len(keys), ', '.join(sorted(keys))))
    steps = dict(START)
    for rnd in range(args.rounds):
        improved = False
        for param in ['scale', 'r', 'g', 'b']:
            tunable = [k for k in keys if param != 'scale' or k in DECOR_KEYS]
            if not tunable:
                continue
            for sign in (1, -1):
                cand = copy.deepcopy(state)
                lo, hi = BOUNDS[param]
                for k in tunable:
                    put(cand, k, param, min(hi, max(lo, get(state, k, param) + sign * steps[param])))
                scores = evaluate(cand)
                for k in tunable:
                    if scores.get(k, 0.0) > best[k] + GAIN:
                        put(state, k, param, get(cand, k, param))
                        best[k] = scores[k]
                        improved = True
        print('round %d: overall %.1f%%  steps scale %.3f tint %.3f' % (
            rnd + 1, 100 * sum(best.values()) / len(best), steps['scale'], steps['r']))
        if not improved:
            steps = {p: s * 0.5 for p, s in steps.items()}
            if steps['r'] < MIN_STEP:
                break
    # Leave the file holding each key's best setting (the last candidate written may be worse).
    final = clean(state)
    if args.dry:
        TUNING.write_text(original, encoding='utf-8', newline='\n')
    else:
        TUNING.write_text(json.dumps(final, indent=1) + '\n', encoding='utf-8', newline='\n')
    mc.render()
    print()
    print('%-16s %7s %7s  %s' % ('key', 'before', 'after', 'setting'))
    for k in sorted(start):
        if k in keys:
            print('%-16s %6.1f%% %6.1f%%  %s' % (k, 100 * start[k], 100 * best[k], json.dumps(final.get(k, {}))))
    print('overall %.1f%% -> %.1f%%%s' % (100 * sum(start.values()) / len(start), 100 * sum(best.values()) / len(best),
        '  (dry run: art_tuning.json unchanged)' if args.dry else ''))
    return 0


if __name__ == '__main__':
    sys.exit(main())
