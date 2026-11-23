# ป้ายสองคำ: ยาวเกินตัด … ไม่ล้นไปใต้รูปโพลารอยด์/หัวใจ (คำแรกจบก่อนหัวใจ x 168 · คำที่สองจบก่อนรูป x 220)
# คำแนะนำตัววางต่อจากป้าย (เดิมตายตัวที่ 104) — ผู้ใช้ขยายป้าย → คำแนะนำตัวเลื่อนลง ไม่ถูกป้ายทับ
from specio import *
j = load('scrapAbout')
root = j['root']; kids = root['children']
for t in by_id(j, 'text1'): t['maxW'] = 134; t['shrinkTo'] = 19      # 168 − 18 − ช่องในป้าย 16.2 · ย่อได้ถึง 70% ก่อนตัด …
for t in by_id(j, 'text2'): t['maxW'] = 140; t['shrinkTo'] = 16.2    # จบก่อนรูปโพลารอยด์ (เอียง) · ย่อได้ถึง 70% ก่อนตัด …
wrap = next(c for c in kids if c.get('id') == 'labelWrap')
abouts = [c for c in kids if c.get('id') in ('about', 'aboutBare')]
i = kids.index(wrap)
for c in [wrap] + abouts: kids.remove(c)
wrap['pad'] = [0, 0, 0, 18]
rows = [wrap]
for a in abouts:
    a.pop('dx'); a.pop('dy'); a['w'] = 193.9           # = 52.4% ของ 370 (keepAspect → กว้าง 370 เสมอ)
    a['shrink'] = 0
    rows.append({"type": "row", "if": a.pop('if'), "pad": [0, 0, 0, 20], "align": "start", "children": [a]})
left = {"type": "col", "id": "left", "pad": [22, 0, 0, 0], "gap": 4.8, "align": "start", "children": rows}   # ป้ายจบ 99.2 · คำแนะนำตัวเริ่ม 104 เท่าเดิม
kids.insert(i, left)
save('scrapAbout', j)
