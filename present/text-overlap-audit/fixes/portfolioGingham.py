# หัวข้อสูงไม่เกินแถบ 108 (ขนาดเริ่ม 71 = สูงบรรทัด 107) + ผ้า/รูปวางต่อจากแถบหัวข้อ: ผู้ใช้ขยายหัวข้อ → แถบสูงขึ้น รูปเตี้ยลง แทนการถูกทับ
from specio import *
j = load('portfolioGingham')
root = j['root']; kids = root['children']
get = lambda i: next(c for c in kids if c.get('id') == i)
cloth_frame, print_area, head = get('clothFrame'), get('printArea'), get('headBand')
for c in (cloth_frame, print_area, head): kids.remove(c)
head.pop('h'); head.pop('place'); head.pop('dy')
head["minH"] = 108; head["shrink"] = 0
hl = head['children'][0]
hl['size'] = 71
print_area['pad'] = [14, 20, 20, 20]          # ห่างขอบผ้า (เดิม 200−186 · 34.8−14.8)
cloth_area = {"type": "stack", "id": "clothArea", "h": "fill", "pad": [2, 14.8, 14.8, 14.8],   # ผ้าเริ่ม 186 = แถบจบ 184 + 2
              "children": [cloth_frame['children'][0], print_area]}
body = {"type": "col", "id": "body", "pad": [76, 0, 0, 0], "gap": 0, "children": [head, cloth_area]}
kids.insert(0, body)
save('portfolioGingham', j)
