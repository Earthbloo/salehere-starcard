# ป้ายสองคำกว้างไม่เกิน 190 (จบก่อนประกายดาว x 212 และมือถือ) · ย่อได้ถึง 70% แล้วตัด … · ไม่ลอดใต้มือถืออีก
# แถวสถิติวางต่อจากป้าย (เดิมตายตัวที่ 70) — ผู้ใช้ขยายป้าย → แถวสถิติเลื่อนลง ไม่ถูกป้ายทับ
from specio import *
j = load('scrapStats')
kids = j['root']['children']
label = next(c for c in kids if c.get('id') == 'label')
rows = next(c for c in kids if c.get('id') == 'rows')
for t in by_id(j, 'text1'): t['shrinkTo'] = 19; t['maxW'] = 110   # คำแรกได้ที่ก่อน (ไม่ถูกหดตามคำที่สอง)
for r in by_id(j, 'first'): r['shrink'] = 0
for t in by_id(j, 'text2'): t['shrinkTo'] = 16.2
i = kids.index(label)
kids.remove(label); kids.remove(rows)
for k in ('place', 'dx', 'dy'): label.pop(k); rows.pop(k)
label['w'] = 190
left = {"type": "col", "id": "left", "place": "top-left", "dx": 15, "dy": 15, "gap": 4.6, "align": "start",   # ป้ายจบ 65.4 · แถวสถิติเริ่ม 70 เท่าเดิม
        "children": [label, {"type": "row", "pad": [0, 0, 0, 3], "align": "start", "children": [rows]}]}
kids.insert(i, left)
save('scrapStats', j)
