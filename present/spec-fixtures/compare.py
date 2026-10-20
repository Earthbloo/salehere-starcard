#!/usr/bin/env python3
"""เทียบ fixture ของสองแพลตฟอร์ม (iOS = สัญญา · อีกฝั่ง = ผู้ถูกทดสอบ)

    python3 -I compare.py <ios-fixtures-dir> <other-fixtures-dir> [--tol 0.01] [--text-tol 1.0]

กติกา (WIDGET-SPEC.md §7–§8): กล่องของโหนดที่ไม่ใช่ข้อความต้องต่างไม่เกิน tol ·
กล่อง/ขนาด/บรรทัดของข้อความยอมต่างได้ text-tol (ฟอนต์ตามแพลตฟอร์ม) แต่ x/y ต้องตรง tol
"""
import json, os, sys

def load(d):
    out = {}
    for f in sorted(os.listdir(d)):
        if f.endswith('.json'):
            out[f[:-5]] = json.load(open(os.path.join(d, f)))
    return out

def main():
    a = sys.argv[1]; b = sys.argv[2]
    tol = float(sys.argv[sys.argv.index('--tol') + 1]) if '--tol' in sys.argv else 0.01
    ttol = float(sys.argv[sys.argv.index('--text-tol') + 1]) if '--text-tol' in sys.argv else 1.0
    A, B = load(a), load(b)
    total_ok = total_bad = 0
    rows = []
    for kind, fa in A.items():
        fb = B.get(kind)
        if not fb:
            rows.append((kind, 'MISSING', 0, 0, '')); continue
        casesB = {c['probe']: c for c in fb['cases']}
        ok = bad = 0; first = ''
        for ca in fa['cases']:
            cb = casesB.get(ca['probe'])
            if not cb:
                bad += 1; first = first or f"{ca['probe']}: no case"; continue
            boxesB = {bx['id']: bx for bx in cb['boxes']}
            for ba in ca['boxes']:
                bb = boxesB.get(ba['id'])
                if not bb:
                    bad += 1; first = first or f"{ca['probe']} {ba['id']}: missing"; continue
                isText = ba['type'] == 'text'
                diffs = []
                for k in ('x', 'y'):
                    if abs(ba[k] - bb[k]) > tol: diffs.append(f"{k} {ba[k]}≠{bb[k]}")
                for k in ('w', 'h'):
                    lim = ttol if isText else tol
                    if abs(ba[k] - bb[k]) > lim: diffs.append(f"{k} {ba[k]}≠{bb[k]}")
                if isText:
                    if ba.get('size') is not None and bb.get('size') is not None and abs(ba['size'] - bb['size']) > ttol:
                        diffs.append(f"size {ba['size']}≠{bb['size']}")
                    if (ba.get('lines') or 0) != (bb.get('lines') or 0) and abs((ba.get('lines') or 0) - (bb.get('lines') or 0)) > 1:
                        diffs.append(f"lines {ba.get('lines')}≠{bb.get('lines')}")
                if diffs:
                    bad += 1; first = first or f"{ca['probe']} {ba['id']}: " + ', '.join(diffs)
                else:
                    ok += 1
        rows.append((kind, 'OK' if bad == 0 else 'DIFF', ok, bad, first))
        total_ok += ok; total_bad += bad
    w = max(len(r[0]) for r in rows)
    for kind, st, ok, bad, first in rows:
        print(f"{kind.ljust(w)}  {st:7} ok={ok:4} bad={bad:3}  {first}")
    print(f"\nboxes equal: {total_ok} · different: {total_bad} · kinds: {sum(1 for r in rows if r[1]=='OK')}/{len(rows)} identical")
    sys.exit(0 if total_bad == 0 else 1)

if __name__ == '__main__':
    main()
