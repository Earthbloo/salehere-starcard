import json,sys,glob
k=sys.argv[1]; maxd=int(sys.argv[2]) if len(sys.argv)>2 else 99
f=[f for f in glob.glob('../../shared/WidgetSpecs/**/*.json',recursive=True) if json.load(open(f)).get('kind')==k][0]
j=json.load(open(f))
print(f, j['design'], {x:j['widget'].get(x) for x in ('keepAspect','resize','lockAspect') if x in j['widget']})
SKIP={'children','root','each','notes','type','id','pattern','gradient','shadow','stroke'}
def show(n,d,path):
    if d>maxd: return
    props={x:n[x] for x in n if x not in SKIP and x not in ('fill','color','radius','on','tint','face','weight','textAlign','textCase','tracking','opacity','clip','circle')}
    print('  '*d+f"{n.get('type')}#{n.get('id','')}", json.dumps(props,ensure_ascii=False)[:220])
    for c in n.get('children',[]): show(c,d+1,path)
    if 'each' in n: show(n['each'],d+1,path)
show(j['root'],0,[])
for v in j.get('variants',[]): print('VARIANT',v['when']); show(v['root'],1,[])
