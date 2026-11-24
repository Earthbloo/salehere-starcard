import json,glob,os
base=os.path.dirname(os.path.abspath(__file__))+'/../../shared/WidgetSpecs/'
def walk(n,f):
    yield n
    for c in n.get('children',[]): yield from walk(c,f)
    if 'each' in n: yield from walk(n['each'],f)
for f in sorted(glob.glob(base+'**/*.json',recursive=True)):
    j=json.load(open(f)); roots=[j['root']] if 'root' in j else []
    roots+=[v['root'] for v in j.get('variants',[])]
    hits=0
    for r in roots:
        for n in walk(r,f):
            if n.get('type')!='row': continue
            ch=n.get('children',[])
            texts=[c for c in ch if c.get('type')=='text']
            names=[c for c in texts if str(c.get('slot','')).startswith('$name') or c.get('slot')=='$label']
            nums=[c for c in texts if c.get('slot') in ('$share','$value','$followers','$followersFull','$price','$priceNum') and c.get('shrink')!=0]
            if names and nums: hits+=1
    if hits: print(j['kind'],hits)
