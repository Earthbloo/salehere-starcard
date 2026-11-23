# กรอบแก้ข้อความ (salehere-ios slotRects = กล่องของโหนด text) ต้องตรงกับตัวอักษรจริง:
# 1) กว้างเท่าคำ (hug + maxW แทน w ตายตัว/ยืดเต็ม)  2) lineHeight ไม่ต่ำกว่า 0.70 (ขอบล่างกรอบ = เส้นฐาน · ตัวอักษรไม่ล้นกรอบ)
# 3) ไม่มีหัวข้อล่องหนซ้ำ (เป็นช่องแก้ซ้อนอีกกรอบ)
import subprocess, sys
from specio import *
def run(*a): subprocess.run([sys.executable, *a], check=True)

# reel ×2: ช่องไฟเป็นสัดส่วน lineHeight 0.70 + กว้างเท่าคำ
run('reelTight.py', 'reelShowcase', '0.70', '0.70')
run('reelTight.py', 'reelBrand', '0.70', '0.70')
for k, rw in (('reelShowcase', 350), ('reelBrand', 105)):
    j = load(k)
    for t in by_id(j, 'recent'):
        t.pop('w', None); t['maxW'] = rw; t['alignSelf'] = 'center'
    for t in by_id(j, 'title'):
        t.pop('w', None); t['maxW'] = 252; t['alignSelf'] = 'center'
    j['notes'] = j['notes'].replace('lineHeight 0.66', 'lineHeight 0.70').replace('(สองบรรทัด lineHeight 0.66)', '(สองบรรทัด lineHeight 0.70)')
    j['notes'] += ' · คำบน/ล่างกว้างเท่าคำ (maxW) ให้กรอบแก้ข้อความตรงตัวอักษร'
    save(k, j)

# kitSocialNight: หัวข้อกว้างเท่าคำ (คอลัมน์ยังกินที่เหลือไว้ตัด …)
j = load('kitSocialNight')
for h in by_id(j, 'header'): h['children'][0]['align'] = 'start'
save('kitSocialNight', j)

# artPortfolio: กว้างเท่าคำ · lineHeight 0.70 · รูปเกย 4.2 (ขอบบนรูปที่ขนาดออกแบบ = 99 เท่าเดิม)
j = load('artPortfolio')
for h in by_id(j, 'headline'):
    h.pop('w', None); h['maxW'] = 306.3; h['lineHeight'] = 0.70
for t in by_id(j, 'type'): t['gap'] = -7.3
j['notes'] = j['notes'].replace('lineHeight 0.612', 'lineHeight 0.70 (กรอบแก้ข้อความจบที่เส้นฐาน)').replace('lineHeight 0.648', 'lineHeight 0.70')
save('artPortfolio', j)

# portfolioGingham: กว้างเท่าคำ
j = load('portfolioGingham')
for h in by_id(j, 'headline'): h.pop('w', None); h['maxW'] = 314.8
save('portfolioGingham', j)

# portfolioWindow: เอาหัวข้อล่องหนออก → หัวข้อจริงอยู่ในคอลัมน์ต่อด้วยรูป (lineHeight 0.70 · รูปเกย 2 ≈ ดีไซน์ 2.4)
j = load('portfolioWindow')
for r in all_roots(j):
    page = next(n for n in nodes(r) if n.get('id') == 'page')
    kids = page['children']
    flow = next(c for c in kids if c.get('id') == 'photoFlow')
    real = next(c for c in kids if c.get('id') == 'headline')
    kids.remove(real)
    for k in ('place', 'dy', 'w'): real.pop(k, None)
    real['maxW'] = 342.6; real['alignSelf'] = 'center'; real['lineHeight'] = 0.70
    flow['children'][0] = real
    flow['gap'] = -2
save('portfolioWindow', j)
j = load('portfolioWindow')
j['notes'] = j['notes'].replace('รูปเริ่มที่ 64% ของความสูงหัวข้อผ่าน col#photoFlow ที่มีหัวข้อล่องหน (opacity 0 · lineHeight 0.64 · id/คำเดียวกัน)', 'หัวข้ออยู่ใน col#photoFlow ต่อด้วยรูป (lineHeight 0.70 = จบที่เส้นฐาน · รูปเกย 2 ≈ ดีไซน์)')
save('portfolioWindow', j)

# audiencePoster: หัวข้อในแถวที่กว้างตามคำ (ลูกของ stack ที่ไม่ระบุกว้าง = เต็มกว้าง → กรอบยาวเกินคำ)
j = load('audiencePoster')
for r in all_roots(j):
    for p in nodes(r):
        ch = p.get('children', [])
        for i, c in enumerate(ch):
            if c.get('id') == 'script' and c.get('type') == 'text':
                row = {"type": "row", "if": c.pop('if'), "place": c.pop('place'), "dx": c.pop('dx'), "dy": c.pop('dy'), "align": "start", "children": [c]}
                c.pop('w'); c['maxW'] = 315
                ch[i] = row
save('audiencePoster', j)
print('done')
