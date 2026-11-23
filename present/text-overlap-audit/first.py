import json
R = json.load(open('out/report.json'))
F = {'M':1,'L':2,'XL':3,'XXL':4}
TX = ['คำเดิม','ไทยสั้น','ไทยกลาง','ไทยยาว','สระซ้อน','อังกฤษยาว']
out=[]
for r in R:
    best=None
    for i in r['issues']:
        if i['type'] not in ('hit','out','clip'): continue
        o=(i['other'] or '').split('(')[0]
        if o in ('subject','cutout'): continue
        if i['area'] if 'area' in i else False: pass
        v=i['variant']
        t,f=(v.split('·')) if v!='design' else ('คำเดิม','M')
        # ignore tiny mark collisions
        if i['amount'] < 60: continue
        key=(F[f], 0 if i['size']=='ออกแบบ' else 1, -i['amount'])
        if best is None or key<best[0]: best=(key,i,t,f)
    if best:
        k,i,t,f=best
        out.append(dict(kind=r['kind'],title=r['title'],file=r['file'],factor=f,text=t,size=i['size'],W=i['W'],H=i['H'],type=i['type'],textId=i['textId'],other=i['other'],amount=i['amount'],sample=i['text']))
out.sort(key=lambda x:(F[x['factor']], x['size']!='ออกแบบ', -x['amount']))
json.dump(out,open('out/first.json','w'),ensure_ascii=False,indent=1)
for x in out: print(f"{x['kind']:18} {x['factor']:3} {x['text']:9} {x['size']:8} {x['type']:4} {x['textId']}×{x['other']} +{x['amount']}  [{x['title']}]")
print(len(out))
