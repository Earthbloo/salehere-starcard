# หัวข้อ "Audience" ใต้ป้าย "อัปเดตเมื่อ" (ป้ายสูงถึง 21): ตอนมีป้าย เลื่อนหัวข้อลงเป็น dy 21 ให้สระบนของคำไทยไม่ชนป้าย · ไม่มีป้าย = dy 4 เท่าเดิม
import copy; from specio import *
j = load('audiencePoster')
for r in all_roots(j):
    for p in nodes(r):
        ch = p.get('children', [])
        out = []
        for c in ch:
            if c.get('id') == 'script' and 'has:stat:countsUpdated' not in c.get('if', ''):
                base = c.get('if')
                a = copy.deepcopy(c); a['if'] = (base + ' & ' if base else '') + '!has:stat:countsUpdated'
                b = copy.deepcopy(c); b['if'] = (base + ' & ' if base else '') + 'has:stat:countsUpdated'; b['dy'] = 21
                out += [a, b]
            else: out.append(c)
        if ch: p['children'] = out
j['notes'] = j['notes'].rstrip() + ' · หัวข้อ dy 21 เมื่อมีป้ายอัปเดต (สระบนไม่ชนป้าย)'
save('audiencePoster', j)
