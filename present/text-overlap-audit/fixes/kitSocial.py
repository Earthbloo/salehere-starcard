# หัวข้อบรรทัดเดียว ยาวเกินตัด … (ห้ามขึ้นบรรทัดใหม่) และไม่ลอดใต้ป้าย "อัปเดตเมื่อ"
from specio import *
# Night: หัวข้อกับป้ายเดิมซ้อนกันในกล่องเดียว → แถวเดียวกัน หัวข้อกินที่เหลือ ป้ายชิดขวา
j = load('kitSocialNight')
for h in by_id(j, 'header'):
    h['type'] = 'row'; h['gap'] = 8; h['align'] = 'start'
    col = h['children'][0]
    col['w'] = 'fill'
    t = col['children'][0]; t['maxLines'] = 1
    slot = h['children'][1]; slot.pop('justify', None)
save('kitSocialNight', j)
# Mac: หัวข้ออยู่กลางแถบหน้าต่าง (เว้นข้างละ 64) · บรรทัดเดียว · แถบสูงตามตัวอักษรเมื่อผู้ใช้ขยายหัวข้อ (ต่ำสุด 34 เท่าเดิม)
j = load('kitSocialMac')
for b in by_id(j, 'bar'):
    b.pop('h'); b['minH'] = 34
for t in by_id(j, 'title'): t['maxLines'] = 1
save('kitSocialMac', j)
