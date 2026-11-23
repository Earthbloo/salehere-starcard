# หัวเรื่องสองบรรทัด (Recent / VIDEOGRAPHY) เป็นข้อความในคอลัมน์ที่สูงตามตัวอักษร (เดิมกล่องตายตัว 23/36 → ขยายหัวข้อแล้วล้นไปหลังมือถือ)
# บรรทัดล่างเว้นจากบรรทัดบน 24 (เดิม 14.5) ให้สระบนของคำไทยไม่ชนสระล่างของบรรทัดบน
# มือถือสูงตามที่เหลือ (สูงสุด 153 · สัดส่วน 82:153) — หัวข้อโต → มือถือเล็กลงแทนการโดนตัดก้นใบ
from specio import *
import sys
KIND = sys.argv[1] if len(sys.argv) > 1 else 'reelShowcase'
TITLE_OFF = 24          # ขอบบนบรรทัดล่าง − ขอบบนบรรทัดบน
def fix_header(header, parent):
    rs, ts = header['children']
    recent, title = rs['children'][0], ts['children'][0]
    for n in (recent, title):
        n.pop('place', None); n.pop('dy', None)
    title['alignSelf'] = 'center'
    header['gap'] = -4.7            # = TITLE_OFF − สูงบรรทัด "Recent" 28.7
    header['children'] = [recent, title]
    i = parent['children'].index(header)
    sp = parent['children'][i + 1]
    assert sp['type'] == 'spacer' and sp.get('h') == 9, sp
    sp['h'] = 5.2                    # มือถืออยู่ใต้บรรทัดล่างเท่าเดิม (ขอบล่างบรรทัด + 5.2)
def fix_columns(row, parent):
    row['h'] = 'fill'; row['maxH'] = 159; row['align'] = 'stretch'
    for col in row['children']:
        col.pop('w', None)
        col['aspect'] = round(82 / 159, 4)     # กว้าง 82 ที่สูง 159 (มือถือ 153 + เว้น 6) · กว้างตามสูงเมื่อหด
        col['align'] = 'stretch'; col['h'] = 'fill'
        for ph in col['children']:
            if ph['type'] == 'stack':
                ph.pop('w'); ph['h'] = 'fill'
    kids = parent['children']
    last = kids[-1]
    if last['type'] == 'spacer' and last.get('grow') == 1: kids.pop()
j = load(KIND)
for r in all_roots(j):
    for p in list(nodes(r)):
        for c in list(p.get('children', [])):
            if c.get('id') == 'header': fix_header(c, p)
            if c.get('id') == 'columns': fix_columns(c, p)
save(KIND, j)
