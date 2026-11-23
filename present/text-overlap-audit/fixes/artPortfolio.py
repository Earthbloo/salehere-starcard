# หัวข้อห้ามชนชื่อด้านบน (สระบนของคำไทย) + รูปคนวางต่อจากหัวข้อ (หัวข้อโต → รูปเลื่อนลง แทนการถูกรูปทับเพิ่ม)
import sys; from specio import *
G = float(sys.argv[1]) if len(sys.argv) > 1 else -4
j = load('artPortfolio')
root = j['root']
zone = next(c for c in root['children'] if c.get('id') == 'subjectZone')
subject = zone['children'][0]
root['children'].remove(zone)
for t in [c for c in root['children'] if c.get('id') == 'type']:
    tb = t['children'][0]
    old_gap = tb['gap']               # -14
    tb['gap'] = G
    t['pad'][0] = round(t['pad'][0] - (G - old_gap), 2)   # หัวข้ออยู่ที่เดิม ชื่อขยับขึ้นแทน
    # รูปต่อจากหัวข้อ: ขอบบนรูปเดิม 99 · ก้อนหัวข้อเดิมจบที่ 131.7 → ซ้อนเข้าไป 32.7
    t['gap'] = -32.7
    s = dict(subject); s['w'] = '78.6%'; t['children'].append(s)
    t['justify'] = 'start'
save('artPortfolio', j)
