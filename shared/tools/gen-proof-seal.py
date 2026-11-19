# สร้าง shared/WidgetSpecs/02-ตรารับรอง/proofSeal.json — ตรา Verified by Sale Here สามสี (ดำ/แดง/ขาว)
# python3 -I gen_seal.py <repo>
import json, sys, os, copy

REPO = sys.argv[1]
OUT = os.path.join(REPO, 'shared', 'WidgetSpecs', '02-ตรารับรอง', 'proofSeal.json')

# ค่าตั้ง (หน่วยออกแบบ 366×232) — วัดจากรูปของทีม Design (756 px กว้าง ≈ ×2.04)
T = dict(
    radius=20,
    seal=dict(x=18.6, y=18.6, s=58),
    title=dict(x=89.5, y=16.9, size=27.2, byY=54.6, by=12, logo=18.5, brand=11.5),
    rule=dict(x=19, y=90, w=266),
    rows=dict(x=19, y=97, w=252, h=24.5, tick=13, gap=8, label=12.5, lw=400, value=11.2),
    qr=dict(x=285.5, y=131.5, w=65, h=71, inner=56, top=4.5, label=9.2, gap=3),
    foot=dict(x=19, y=207, k=9.2, v=10.4, vw=500),
    stamp=dict(x=249.5, y=-60.2, s=161.6),
)

TONES = {
    'dark':  dict(bg='#161616', ink='white', ink2='#B9B4C4', line='white@0.16', wave='white@0.07',  stamp='white@0.30', seal='sh:sealRed',   edge=None),
    'red':   dict(bg='#DA0510', ink='white', ink2='white@0.80', line='white@0.30', wave='white@0.10', stamp='white@0.35', seal='sh:sealWhite', edge=None),
    'white': dict(bg='white',   ink='#161616', ink2='#6F6B78', line='black@0.12', wave='black@0.06', stamp='black@0.09', seal='sh:sealRed',  edge='black@0.08'),
}

ROWS = [
    ('ตัวตนจริง', 'ผ่านการตรวจสอบ', None),
    ('ยอดผู้ติดตาม', 'ตรวจสอบเมื่อ 18 พ.ย. 69', 'done:socials'),
    ('Insight', 'ตรวจสอบเมื่อ 18 พ.ย. 69', 'done:insight'),
]


def at(node, x, y):
    node.update(place='top-left', dx=x, dy=y)
    return node


def text(t, size, weight, color, **kw):
    # role deco ทุกคำ: ตราเป็นภาพตายตัว (ย้าย/ยืดไม่ได้) — story = ใบเดียวกันย่อทั้งก้อน ไม่ยกตัวอักษรทีละคำจนแถวล้น
    n = dict(type='text', text=t, face='noto', size=size, weight=weight, color=color, maxLines=1, role='deco')
    n.update(kw)
    return n


def build(c, big):
    """c = สีของโทน · big = story (ไม่มี QR แถวใหญ่ขึ้น)"""
    s, ti, ru, ro, q, f, st = (T[k] for k in ('seal', 'title', 'rule', 'rows', 'qr', 'foot', 'stamp'))
    k = 1.3 if big else 1.0   # ขยายแถว/ท้ายใบใน story
    kids = []
    kids.append(dict(type='rect', id='plate', fill=c['bg'], **({'stroke': {'color': c['edge'], 'width': 1}} if c['edge'] else {})))
    kids.append(at(dict(type='icon', id='waves', icon='sh:verifiedWaves', w=366, h=232, tint=c['wave']), 0, 0))
    kids.append(at(dict(type='icon', id='stamp', icon='sh:stampLine', w=st['s'], h=st['s'], tint=c['stamp']), st['x'], st['y']))
    kids.append(at(dict(type='icon', id='seal', icon=c['seal'], w=s['s'], h=s['s']), s['x'], s['y']))
    kids.append(at(text('Verified', ti['size'], 800, c['ink'], id='verified', kerning=-0.4, role='deco'), ti['x'], ti['y']))
    kids.append(at(dict(type='row', id='by', h=ti['logo'], gap=5, align='center', children=[
            text('by', ti['by'], 500, c['ink'], role='deco'),
            dict(type='stack', id='logo', w=ti['logo'], h=ti['logo'], children=[
                dict(type='rect', circle=True, fill='white'),
                dict(type='rect', circle=True, fill='#DA0510', w=ti['logo'] - 2.4, h=ti['logo'] - 2.4, place='center'),
                dict(type='icon', icon='sh:wordmark', w=ti['logo'] * 0.58, h=ti['logo'] * 0.58, tint='white', place='center'),
            ]),
            text('SALE HERE', ti['brand'], 700, c['ink'], tracking=1.6, role='deco'),
        ]), ti['x'] + 0.3, ti['byY']))
    kids.append(at(dict(type='rect', id='rule', w=(366 - 2 * ru['x']) if big else ru['w'], h=0.8, fill=c['line']), ru['x'], ru['y']))
    rows = []
    for label, value, cond in ROWS:
        r = dict(type='row', gap=ro['gap'] * k, align='center', h=ro['h'] * k, children=[
            dict(type='icon', icon=c['seal'], w=ro['tick'] * k, h=ro['tick'] * k),
            text(label, ro['label'] * k, ro['lw'], c['ink']),
            dict(type='spacer', grow=1, minW=6),
            text(value, ro['value'] * k, 400, c['ink2'], role='deco'),
        ])
        if cond:
            r['if'] = cond
        rows.append(r)
    kids.append(at(dict(type='col', id='rows', w=(366 - 2 * ro['x']) if big else ro['w'], gap=0, align='stretch', children=rows), ro['x'], ro['y']))
    if not big:
        kids.append(at(dict(type='col', id='scan', w=q['w'], gap=q['gap'], align='center', children=[
            dict(type='stack', w=q['w'], h=q['h'], radius=9, fill='white', **({'stroke': {'color': c['edge'], 'width': 1}} if c['edge'] else {}), children=[
                dict(type='icon', id='qr', icon='qr', slot='stat:verifyURL', w=q['inner'], h=q['inner'], tint='#161616', place='top-center', dy=q['top']),
            ]),
            text('สแกนตรวจสอบ', q['label'], 400, c['ink2']),
        ], **{'if': 'has:stat:verifyURL'}), q['x'], q['y']))
    kids.append(dict(type='row', id='number', gap=4, align='end', place='bottom-left', dx=f['x'], dy=-(232 - f['y'] - 14) if not big else -12, children=[
        text('STAR NUMBER', f['k'] * (1.25 if big else 1), 400, c['ink2'], tracking=0.4),
        text('STAR-2611-0482', f['v'] * (1.25 if big else 1), f['vw'], c['ink'], tracking=0.2),
    ]))
    return dict(type='stack', id='sheet', clip=True, radius=T['radius'], w='fill', h='fill', children=kids)


spec = json.load(open(OUT, encoding='utf-8'))
widget = spec['widget']
widget.pop('surfaces', None); widget.pop('surfaceNames', None)
widget['ownBorder'] = True
widget['controls'] = [{'type': 'segment', 'label': 'สี', 'opt': 'tone', 'options': [[None, 'ดำ'], ['red', 'แดง'], ['white', 'ขาว']]}]

out = {
    'kind': 'proofSeal',
    'design': {'w': 366, 'h': 232},
    'widget': widget,
    'notes': ('ตรารับรอง Verified by Sale Here · แบบทีม Design 19 พ.ย. 2569 (logo-export: 01-seal · 02-stamp-line) · '
              'สามสีแบรนด์ตายตัว ไม่ตามธีมการ์ด: ดำ #161616 (ตั้งต้น) · แดง #DA0510 (ตรา sh:sealWhite) · ขาว (เส้นขอบ black@0.08) — ตัวเลือก `opt:tone` · '
              'แถว: ตัวตนจริง (เสมอ — ตราปลดล็อกเมื่อ KYC ผ่าน) · ยอดผู้ติดตาม `done:socials` · Insight `done:insight` (ยังไม่กรอก = ไม่มีแถว) · '
              'story = ใบเดียวกันย่อ 67% ทั้งก้อน (ทุกคำ role deco — ถ้ายกตัวอักษรตามขั้นต่ำ แถวล้นใน 246×156) · ค่าตัวอย่าง: วันที่ตรวจ 18 พ.ย. 69 และ STAR-2611-0482 (ยังไม่มีใน SpecDataSource) · '
              'QR = `stat:verifyURL` ที่ client ส่งมา (ไม่ส่ง = ไม่มี QR และคำใต้ QR) · ฟอนต์ดีไซน์ Prompt → ใช้ noto ของแอป · สร้างจาก shared/tools/gen-proof-seal.py'),
    'variants': [],
    'root': build(TONES['dark'], False),
}
for tone in ('red', 'white'):
    out['variants'].append({'when': f'opt:tone={tone}', 'root': build(TONES[tone], False)})

with open(OUT, 'w', encoding='utf-8') as fh:
    json.dump(out, fh, ensure_ascii=False, indent=1)
    fh.write('\n')
print('wrote', OUT)
