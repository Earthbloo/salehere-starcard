# เอาข้อความลายมือบน/ล่างออกทั้งคู่ (QA 23 พ.ย. 2569: ย่อกรอบแล้วคำบรรยายทับรูป · ผู้ใช้สั่งเอาข้อความออก)
from specio import *
j = load('wallMemory')
for r in all_roots(j):
    for p in nodes(r):
        p['children'] = [c for c in p.get('children', []) if c.get('id') not in ('top', 'bottom')] if 'children' in p else None
        if p['children'] is None: del p['children']
j['notes'] = j['notes'].replace('· ลายมือคร่อมบนล่าง (note#0 note#1) ', '· ไม่มีข้อความ (ลายมือบน/ล่างเอาออก 23 พ.ย. 2569 — ย่อกรอบแล้วทับรูป) ')
save('wallMemory', j)
