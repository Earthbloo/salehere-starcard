# แก้ QA reject 23 พ.ย. 2569 (8 ใบ) + ใบอื่นที่เป็นบั๊กแบบเดียวกัน — รันซ้ำได้ (idempotent)
import json, glob, os, re
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../shared/WidgetSpecs')
FILES = {}
for f in glob.glob(ROOT + '/**/*.json', recursive=True):
    FILES[json.load(open(f))['kind']] = f
def load(k): return json.load(open(FILES[k]))
def save(k, j): open(FILES[k], 'w').write(json.dumps(j, ensure_ascii=False, indent=1) + '\n')
def nodes(n):
    yield n
    for c in n.get('children', []): yield from nodes(c)
    if 'each' in n: yield from nodes(n['each'])
def roots(j): return ([j['root']] if 'root' in j else []) + [v['root'] for v in j.get('variants', [])]
def every(j): return [n for r in roots(j) for n in nodes(r)]
log = []

# 1) หัวข้อชุดลายผ้า (Gingham) วางบนการ์ดขาวที่ไม่เปลี่ยนสี — เดิม ink+on:light → เลือกสีวิดเจ็ตเข้ม แผ่น light = สีนั้น หมึก = ขาว → หาย
#    ให้หัวข้อเป็นหมึกเข้มตายตัวแบบเดียวกับเนื้อหาในการ์ดขาว (#141417)
for k in sorted(x for x in FILES if x.startswith('kit') and x.endswith('Gingham')):
    j = load(k); n = 0
    for t in every(j):
        if t.get('id') == 'title' and t.get('type') == 'text' and t.get('color') == 'ink':
            t['color'] = '#141417'; t.pop('on', None); n += 1
    if n: save(k, j); log.append((k, f'title ink → #141417 ×{n}'))

# 2) ป้าย/ตัวเลขสแครปบุ๊กที่วางบนกล่องสีบทบาท (bg/bg2) แต่ใช้หมึก hex #141414 → สีวิดเจ็ตเข้ม กล่องเข้ม ตัวหนังสือเข้ม → หาย
#    เปลี่ยนเป็น ink (ตามกล่อง) — ธีมปกติ ink ของแผ่นสว่าง ≈ #1A1A1A เหมือนเดิม
SCRAP = {
    'scrapStats': lambda n: n.get('id') == 'text2' or n.get('text') in ('$engagement', '{name} · ER'),
    'scrapAbout': lambda n: n.get('id') == 'text2',
    'scrapTags': lambda n: n.get('id') == 'text2',
    'scrapPhones': lambda n: n.get('id') == 'text2',
    'scrapKeyTab': lambda n: n.get('slot') == '$followers',
    'scrapFeed': lambda n: n.get('id') == 'feed',
}
for k, pred in SCRAP.items():
    j = load(k); n = 0
    for t in every(j):
        if t.get('type') == 'text' and t.get('color') == '#141414' and pred(t):
            t['color'] = 'ink'; n += 1
    if n: save(k, j); log.append((k, f'#141414 → ink ×{n}'))

# 2b) ป้ายแท็กใบที่ 4 ของสายที่ใช่ (tag3) เป็นกล่อง bg2 → ชื่อสายใช้ ink (ใบ 1–3 เป็นกล่องสีตายตัว คงเดิม)
j = load('scrapTags'); n = 0
for c in every(j):
    if c.get('id') == 'tag3':
        for t in nodes(c):
            if t.get('type') == 'text' and t.get('color') == '#141414': t['color'] = 'ink'; n += 1
    # ดาวในวงกลม bg2 ของแท็กใบแรก (tag0) — วงกลมตามสีวิดเจ็ต ดาวต้องตามหมึก
    if c.get('id') == 'tag0':
        for t in nodes(c):
            if t.get('type') == 'icon' and t.get('tint') == '#141414': t['tint'] = 'ink'; n += 1
if n: save('scrapTags', j); log.append(('scrapTags', f'tag3 #141414 → ink ×{n}'))
# 2c) พวงกุญแจแนวนอน: ตัวเลขอยู่บนการ์ดขาว (ไม่ใช่แผ่น bg2) → คงหมึกเข้มตายตัว
j = load('scrapKeyTab'); n = 0
for v in j.get('variants', []):
    for t in nodes(v['root']):
        if t.get('slot') == '$followers' and t.get('color') == 'ink': t['color'] = '#141414'; n += 1
if n: save('scrapKeyTab', j); log.append(('scrapKeyTab', f'variant $followers back to #141414 ×{n}'))

# 3) ตัวเลข % ในแถว "ชื่อ ··· %" ห้ามหด — ชื่อเมืองยาวเคยแย่งที่จนเหลือ "2…" · ให้ชื่อหด/ตัด … แทน
NUM = {'$share', '$value', '$followers', '$followersFull', '$price', '$priceNum'}
for k in sorted(FILES):
    j = load(k); n = 0
    for r in every(j):
        if r.get('type') != 'row': continue
        kids = r.get('children', [])
        texts = [c for c in kids if c.get('type') == 'text']
        if not any(str(c.get('slot', '')).startswith('$name') or c.get('slot') == '$label' for c in texts): continue
        for c in texts:
            if c.get('slot') in NUM and c.get('shrink') != 0:
                c['shrink'] = 0; n += 1
    if n: save(k, j); log.append((k, f'% shrink 0 ×{n}'))

# 4) ช่องทางผ้าปิกนิก: แถบหัวข้อสูงตายตัว 31 → ผู้ใช้ขยายหัวข้อ (L…XXL) ตัวอักษรล้นลงไปใต้การ์ด · ให้แถบสูงตามตัวอักษร (ต่ำสุด 31 เท่าเดิม)
j = load('socialGingham')
for h in every(j):
    if h.get('id') == 'head' and 'h' in h:
        h.pop('h'); h['minH'] = 31; log.append(('socialGingham', 'head h 31 → minH 31'))
save('socialGingham', j)
for k, m in log: print(f'{k:22} {m}')
# ไฟล์เดิมไม่มีขึ้นบรรทัดท้าย → ไม่เติม (diff สะอาด) — ทำใน shell หลังรัน

# 5) Insight ชุดม่วง: กล่องเพศอยู่แถวเดียวกับกล่องเมือง — ชื่อเมืองยาวดันกล่องเพศจน % เหลือ "…" · กล่องเพศไม่หด (ชื่อเมืองหด/ตัดแทน)
j = load('kitInsightPurple'); n = 0
for g in every(j):
    if g.get('id') == 'gender' and g.get('type') == 'stack':
        g.pop('minW', None)
        if g.get('shrink') != 0: g['shrink'] = 0; n += 1
    # ชื่อเมือง (แถวเล็กที่อยู่คู่กล่องเพศ) กว้างไม่เกิน 110 — ชื่อยาวไม่ดันกล่องเมืองจนกล่องเพศเบียด · ชื่อสั้นของดีไซน์ไม่ถึง 110 → ที่เดิม
    if g.get('type') == 'text' and g.get('slot') == '$name' and g.get('size') == 11.5 and g.get('maxW') != 110:
        g['maxW'] = 110; n += 1
if n: save('kitInsightPurple', j); print(f'{"kitInsightPurple":22} gender box shrink 0 ×{n}')

# 6) บันทึกใน notes ของสเปก (ครั้งเดียว)
TAG = '23 พ.ย. 2569 (QA reject'
NOTE = {
    'gingham': 'หัวข้อบนการ์ดขาว = #141417 ตายตัว (เดิม ink on light → เลือกสีวิดเจ็ตเข้ม หมึกแผ่น light กลายเป็นสีอ่อน หัวข้อหายบนการ์ดขาว)',
    'scrap': 'ตัวหนังสือบนกล่อง bg/bg2 = ink (เดิม #141414 → สีวิดเจ็ตเข้ม กล่องเข้มตาม ตัวหนังสือจม)',
    'pct': 'ตัวเลข % ในแถว "ชื่อ ··· %" shrink 0 — ชื่อยาวหด/ตัด … แทน (เดิมเหลือ "2…")',
}
WHO = {k: 'gingham' for k in FILES if k.startswith('kit') and k.endswith('Gingham')}
WHO.update({k: 'scrap' for k in ('scrapStats', 'scrapAbout', 'scrapTags', 'scrapPhones', 'scrapKeyTab', 'scrapFeed')})
EXTRA = {
    'socialGingham': 'ขยายหัวข้อ (L…XXL) แล้วมุดใต้การ์ด → แถบหัวข้อ minH 31 + pad ล่าง −5.24 (ขนาด M อยู่ที่เดิมเป๊ะ) ไม่หด · เส้นสองข้างอยู่ในคอลัมน์ stretch (ระดับเดิม) · แถบท้ายใบหดก่อน (shrink 4) ให้การ์ดเหลือที่',
    'kitInsightPurple': 'กล่องเพศไม่หด + ชื่อเมืองแถวเล็ก maxW 110 (ชื่อยาวเคยดันกล่องเพศจน % เป็น "…")',
}
for k in sorted(FILES):
    j = load(k)
    if 'notes' not in j or TAG in j['notes']: continue
    parts = []
    if k in WHO: parts.append(NOTE[WHO[k]])
    if k in EXTRA: parts.append(EXTRA[k])
    if k in ('audienceAge', 'audienceMap', 'audiencePoster', 'audienceSplit', 'kitInsightCream', 'kitInsightGingham', 'kitInsightNight', 'kitInsightPurple'): parts.append(NOTE['pct'])
    if not parts: continue
    j['notes'] = j['notes'].rstrip() + f' · {TAG}): ' + ' · '.join(parts)
    save(k, j)

# 7) ช่องทางผ้าปิกนิก: หัวข้อที่ผู้ใช้พิมพ์ยาว ห้ามย่อตัวอักษร — ขนาดคงเดิม เต็มช่อง 252 แล้วตัด … (ผู้ใช้ 23 พ.ย. 2569)
j = load('socialGingham'); n = 0
for t in every(j):
    if t.get('id') == 'title' and 'shrinkTo' in t: t.pop('shrinkTo'); n += 1
if n:
    j['notes'] = j['notes'].rstrip() + ' · 23 พ.ย. 2569: หัวข้อพิมพ์ยาวไม่ย่อแล้ว (ถอด shrinkTo) — ขนาดเดิมเต็มช่อง maxW 252 แล้วตัด …'
    save('socialGingham', j); print('socialGingham          title shrinkTo removed')
