import json, collections, sys
R = json.load(open('out/report.json'))
F = {'M':1,'L':2,'XL':3,'XXL':4}
BEHIND = ('subject','cutout')
rows = []
for r in R:
    agg = {}
    for i in r['issues']:
        if i['type'] in ('tall','error'): continue
        v = i['variant']
        txt, fac = (v.split('·') + ['M'])[:2] if v != 'design' else ('คำเดิม','M')
        edited = v != 'design'
        other = (i['other'] or '').split('(')[0]
        typ = i['type']
        if typ == 'hit':
            typ = 'ทับรูป' if i['other'].endswith('(image)') or i['other'].endswith('(icon)') else 'ทับข้อความ'
            if other in BEHIND: typ = 'หลังคน(ตั้งใจ)'
        elif typ == 'out': typ = 'หลุดขอบ'
        elif typ == 'clip': typ = 'ถูกตัด'
        cause = 'แก้คำ/ขนาด' if edited else 'ย่อขยายอย่างเดียว'
        k = (typ, cause)
        lvl = F[fac]
        cur = agg.get(k)
        score = (lvl, 0 if i['size']=='ออกแบบ' else 1, -i['amount'])
        if not cur or score < cur[0]:
            agg[k] = (score, i)
    rows.append((r, agg))
json.dump([{ 'kind': r['kind'], 'title': r['title'], 'file': r['file'], 'editable': sorted(set(r['editable'])),
  'agg': [{'type':k[0],'cause':k[1],'minFactor':['','M','L','XL','XXL'][v[0][0]], **v[1]} for k,v in agg.items()]} for r,agg in rows],
  open('out/summary.json','w'), ensure_ascii=False, indent=1)
for r, agg in rows:
    if not agg: continue
    parts = []
    for (t,c),(s,i) in sorted(agg.items(), key=lambda x: x[1][0]):
        parts.append(f"{t}/{c[:3]}@{['','M','L','XL','XXL'][s[0]]}:{i['textId']}×{(i['other'] or '').split('(')[0]}[{i['size']}]")
    print(f"{r['kind']:20} " + ' | '.join(parts))
