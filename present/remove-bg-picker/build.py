#!/usr/bin/env python3
"""สร้าง present/remove-bg-picker/index.html — หน้าเลือกว่ารูปช่องไหนของ widget ไหนต้อง removeBg

อ่าน shared/WidgetSpecs/*.json ทุกไฟล์ · รูปพรีวิว = present/spec-fixtures/cells/cell-<kind>-design.png
รัน: python3 -I present/remove-bg-picker/build.py
"""
import json, glob, os, html

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'present', 'remove-bg-picker', 'index.html')

TRAY = [('profile', 'โปรไฟล์'), ('channels', 'ช่องทาง'), ('niche', 'สายที่ใช่'), ('intro', 'แนะนำตัว'), ('body', 'สัดส่วน'),
        ('rate', 'เรทรับงาน'), ('schedule', 'วันเวลา·พื้นที่'), ('audience', 'ข้อมูลผู้ติดตาม'), ('verify', 'ยืนยันตัวตน'),
        ('work', 'ผลงาน'), ('contact', 'ติดต่อ'), ('decor', 'ข้อความ')]
TRAY_OF = dict(hero='profile', followers='channels', tags='niche', intro='intro', body='body', rate='rate',
               availability='schedule', audience='audience', seal='verify', photo='work', showcase='work',
               brand='work', verified='work', contact='contact', text='decor')


def what(n):
    """ช่องรูปนี้คือรูปอะไร (กฎช่อง: 1–3 = รูปเจ้าของการ์ด · อื่น ๆ = รูปผลงาน)"""
    if 'photo' in n:
        s = n['photo']
        return f'photo:{s}', f'ช่อง {s}', ('รูปเจ้าของการ์ด' if 1 <= s <= 3 else 'รูปผลงาน'), (1 <= s <= 3)
    src = n.get('src') or n.get('photoRef')
    if src == '$brandLogo':
        return 'src:$brandLogo', 'โลโก้แบรนด์', 'โลโก้แบรนด์', False
    if src:
        return f'src:{src}', 'ปกผลงาน', 'รูปปกผลงาน', False
    return 'none', 'รูป', 'รูป', False


widgets = []
for f in sorted(glob.glob(os.path.join(ROOT, 'shared', 'WidgetSpecs', '**', '*.json'), recursive=True), key=os.path.basename):
    d = json.load(open(f, encoding='utf-8'))
    kind = d['kind']
    w = d.get('widget', {})
    slots = {}

    def walk(x, conds=()):
        if isinstance(x, dict):
            # เงื่อนไข `if` มักอยู่ที่กลุ่มที่ครอบรูป ไม่ใช่ที่โหนดรูปเอง → สะสมจากบนลงล่าง
            conds = conds + ((x['if'],) if 'if' in x else ())
            if x.get('type') == 'image':
                key, label, desc, person = what(x)
                if key != 'none':
                    # 1 แถวต่อ 1 รูป — โหนดที่ใช้รูปเดียวกัน (ท่ากรอบ/ท่าคนยืน · สกินสว่าง/มืด) รวมเป็นแถวเดียว
                    s = slots.setdefault(key, dict(key=key, label=label, desc=desc, person=person,
                                                   cutout=False, framed=False, mono=False, already=False))
                    s['cutout'] |= 'cutout' in conds
                    s['framed'] |= '!cutout' in conds
                    s['mono'] |= bool(x.get('mono'))
                    s['already'] |= 'removeBg' in x
            for v in x.values():
                walk(v, conds)
        elif isinstance(x, list):
            for v in x:
                walk(v, conds)

    walk(d)
    cell = os.path.join(ROOT, 'present', 'spec-fixtures', 'cells', f'cell-{kind}-design.png')
    widgets.append(dict(kind=kind, title=w.get('title', kind), category=w.get('category', ''),
                        group=TRAY_OF.get(w.get('category', ''), 'decor'), order=w.get('order', 999),
                        img=f'../spec-fixtures/cells/cell-{kind}-design.png' if os.path.exists(cell) else None,
                        slots=sorted(slots.values(), key=lambda s: (not s['person'], s['label']))))

gi = {g: i for i, (g, _) in enumerate(TRAY)}
widgets.sort(key=lambda w: (gi.get(w['group'], 99), w['order'], w['kind']))

data = json.dumps(dict(groups=TRAY, widgets=widgets), ensure_ascii=False)
tpl = open(os.path.join(os.path.dirname(__file__), 'template.html'), encoding='utf-8').read()
open(OUT, 'w', encoding='utf-8').write(tpl.replace('/*__DATA__*/null', data))
n_slots = sum(len(w['slots']) for w in widgets)
print(f'{len(widgets)} widgets · {sum(1 for w in widgets if w["slots"])} มีรูป · {n_slots} ช่องรูป → {OUT}')
