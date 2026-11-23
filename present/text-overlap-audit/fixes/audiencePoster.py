# ก้อนข้อมูลเว้นระยะกันเสมอ: ย่อกรอบแล้วตัวอักษรถูกยกให้อ่านออก → ก้อนบน (เมืองหลัก/ช่วงอายุ) สูงขึ้น
# เดิมก้อนล่าง (เพศ/การเข้าถึง) ตายตัวที่ 312/340 → ทับกัน · ตอนนี้ก้อนล่างวางต่อจากก้อนบนเว้น 12 (ขนาดออกแบบอยู่ที่เดิม)
# ก้อนซ้าย/ขวากว้างได้ไม่เกิน 175 (ครึ่งใบเว้นกลาง 16) — เดิมขยายตามตัวอักษรจนชนกันกลางใบ
from specio import *
GAP = 12
j = load('audiencePoster')
for r in all_roots(j):
    block = next(n for n in nodes(r) if n.get('id') == 'block')
    kids = block['children']
    slot = lambda i: next(c for c in kids if c.get('id') == i)
    ps, ags, gs, rs = slot('placesSlot'), slot('agesSlot'), slot('genderSlot'), slot('reachSlot')
    i = kids.index(ps)
    def flow(top_slot, bottom_slot, side):
        top_y, bot_y = top_slot['pad'][0], bottom_slot['pad'][0]
        top = {"type": "col", "maxW": 175, "minH": bot_y - top_y - GAP, "align": "start", "children": top_slot['children']}
        bot = {"type": "col", "maxW": 175, "align": "start", "children": bottom_slot['children']}
        return {"type": "col", "id": top_slot['id'].replace('Slot', 'Flow'), "pad": [top_y, 0, 0, 0], "gap": GAP, "align": side, "children": [top, bot]}
    left = flow(ps, gs, 'start')
    right = flow(ags, rs, 'end')       # ชิดขวา (= ขอบขวาเดิม 224+142 / 214+152 = 366)
    for c in (ps, ags, gs, rs): kids.remove(c)
    kids[i:i] = [left, right]
save('audiencePoster', j)
