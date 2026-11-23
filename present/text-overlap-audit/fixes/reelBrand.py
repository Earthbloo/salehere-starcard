# เหมือน reelShowcase: หัวเรื่องสองบรรทัดสูงตามตัวอักษร + บรรทัดล่างเว้น 24 · คอลัมน์แบรนด์/มือถือ/ยอด ย่อตามที่เหลือ (สูงสุด 212.4 = เดิม)
from specio import *
import importlib.util, sys
spec = importlib.util.spec_from_file_location('rs', 'reelShowcase.py')
j = load('reelBrand')
def fix_header(header, parent):
    rs, ts = header['children']
    recent, title = rs['children'][0], ts['children'][0]
    for n in (recent, title):
        n.pop('place', None); n.pop('dy', None)
    title['alignSelf'] = 'center'
    recent['w'] = 105; recent['alignSelf'] = 'center'   # กลางใบ ไม่ล้นถึงป้าย Verified มุมขวาบน (ป้ายเริ่ม x 239.5 · กลาง 183)
    header['gap'] = -4.7
    header['children'] = [recent, title]
def fix_columns(chips, parent):
    chips['h'] = 'fill'; chips['maxH'] = 212.4; chips['align'] = 'stretch'
    reel = chips['each']
    reel.pop('w'); reel['h'] = 'fill'; reel['aspect'] = round(82 / 212.4, 4)   # กว้าง 82 ที่สูงเต็ม · หดตามสูง
    for ch in reel['children']:
        if ch.get('id') == 'phone':
            ch.pop('w'); ch['w'] = 'fill'; ch['h'] = 'fill'
    kids = parent['children']
    if kids[-1]['type'] == 'spacer' and kids[-1].get('grow') == 1: kids.pop()
for r in all_roots(j):
    for p in list(nodes(r)):
        for c in list(p.get('children', [])):
            if c.get('id') == 'header': fix_header(c, p)
            if c.get('id') == 'columns': fix_columns(c, p)
            if c.get('id') == 'headerStack':
                i = p['children'].index(c); sp = p['children'][i + 1]
                assert sp['type'] == 'spacer' and sp.get('h') == 9, sp
                sp['h'] = 5.2
save('reelBrand', j)
