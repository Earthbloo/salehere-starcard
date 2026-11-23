# หัวข้อใหญ่ได้ แต่ไม่ทับแถวข้อมูล: หัวข้อ → เส้นบรรทัดแรก → แถวข้อมูล เรียงต่อกัน (เดิมตายตัวที่ 24/54)
# เส้นสมุดเลื่อนตามแถวข้อมูล (ทุก 28.5 เท่าเดิม) · เกินก้นการ์ดถูกตัดตามการ์ด · หัวข้อยาวเกินการ์ด → ย่อแล้วตัด …
from specio import *
j = load('scrapInfo')
card = by_id(j, 'card')[0]
kids = card['children']
LINE = "#C8D6E8"
hlines = [c for c in kids if c['type'] == 'rect' and c.get('h') == 1 and 'dy' in c]
assert [c['dy'] for c in hlines] == [54, 82.5, 111, 139.5, 168, 196.5]
margin = next(c for c in kids if c['type'] == 'rect' and c.get('w') == 1)
tw = next(c for c in kids if c.get('id') == 'titleWrap')
rows = next(c for c in kids if c.get('id') == 'rows')
tw['type'] = 'col'   # คอลัมน์ให้แถวหัวข้อรู้ความกว้าง → วัดความสูงตอนขึ้นบรรทัดใหม่ได้
tw['pad'] = [24, 8, 0, 35]; tw['minH'] = 54; tw['shrink'] = 0
for t in by_id(j, 'text1') + by_id(j, 'text2'): t['shrinkTo'] = 12.6
for r in by_id(j, 'title'): r['wrap'] = True     # ขยายแล้วสองคำไม่พอบรรทัด → คำที่สองขึ้นบรรทัดใหม่ แทนการตัดทั้งคู่
rows['pad'] = [0, 8, 0, 35]
block = lambda: {"type": "col", "h": 28.5, "justify": "end", "children": [{"type": "rect", "h": 1, "fill": LINE}]}
ruled = {"type": "stack", "id": "ruled", "h": "fill", "children": [
    {"type": "col", "id": "lines", "gap": 0, "children": [block() for _ in range(5)]},
    rows]}
body = {"type": "col", "id": "body", "gap": 0, "children": [tw, {"type": "rect", "h": 1, "fill": LINE, "shrink": 0}, ruled]}
card['children'] = [margin, body]   # เส้นขอบชมพูอยู่ใต้ทุกอย่างเหมือนเดิม
save('scrapInfo', j)
