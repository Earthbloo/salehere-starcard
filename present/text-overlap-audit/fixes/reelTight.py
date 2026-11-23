# ช่องไฟหัวเรื่องย่อ/ขยายตามขนาดตัวอักษร: ใช้ lineHeight ตัดที่ว่างใต้บรรทัด (ตัดเป็นสัดส่วน) แทนระยะตายตัว
# usage: reelTight.py <kind> <offRatio> <titleLH>   offRatio = ขอบบนบรรทัดล่างอยู่ที่ x × สูงบรรทัดบน (เดิม 24/28.7 = 0.836)
import sys; from specio import *
kind, a, b = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
M_GAP_TO_PHONE = 45.3 + 5.2          # ขอบบนบรรทัดล่าง → มือถือ ที่ขนาด M (คงตำแหน่งมือถือเดิม)
j = load(kind)
for h in by_id(j, 'header'):
    recent, title = h['children']
    recent['lineHeight'] = round(a, 4); h['gap'] = 0
    title['lineHeight'] = round(b, 4)
for r in all_roots(j):
    for p in nodes(r):
        ch = p.get('children', [])
        for i, c in enumerate(ch):
            if c.get('id') in ('header', 'headerStack') and i + 1 < len(ch) and ch[i + 1]['type'] == 'spacer':
                # มือถือที่ขนาด M = ขอบบนบรรทัดล่าง + 50.5 → spacer = 50.5 − สูงบรรทัดล่าง(M) × b ... แต่เมื่อ a เปลี่ยน ขอบบนบรรทัดล่างเปลี่ยนด้วย
                top_old, top_new = 24, 28.7 * a
                ch[i + 1]['h'] = round(M_GAP_TO_PHONE - 45.3 * b + (top_old - top_new), 2)
save(kind, j)
