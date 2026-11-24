import json,sys,glob
k=sys.argv[1]; maxd=int(sys.argv[2]) if len(sys.argv)>2 else 99
f=[f for f in glob.glob(__import__('os').path.dirname(__import__('os').path.abspath(__file__))+'/../../shared/WidgetSpecs/**/*.json',recursive=True) if json.load(open(f)).get('kind')==k][0]
j=json.load(open(f))
print(f, j['design'], j['widget'].get('on'))
SKIP={'children','root','each','notes','type','id','pattern','gradient','shadow'}
def show(n,d):
    if d>maxd: return
    props={x:n[x] for x in n if x not in SKIP}
    print('  '*d+f"{n.get('type')}#{n.get('id','')}", json.dumps(props,ensure_ascii=False)[:260])
    for c in n.get('children',[]): show(c,d+1)
    if 'each' in n: show(n['each'],d+1)
if 'root' in j: print('ROOT'); show(j['root'],0)
if len(sys.argv)>3:
  for v in j.get('variants',[]): print('VARIANT',v['when']); show(v['root'],1)
