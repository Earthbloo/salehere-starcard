# python3 to-paper.py <in-dir> <out-dir> — ชมพูคงที่ #B8446F (fixes.py) → accent + "on": "paper" (ต้องมี salehere-ios-paper.patch ก่อน)
import json,glob,os,sys
src,dst=sys.argv[1],sys.argv[2]
def walk(n):
    c=0
    for k in ('color','fill'):
        if n.get(k)=='#B8446F': n[k]='accent'; n['on']='paper'; c+=1
    for x in n.get('children',[]): c+=walk(x)
    if 'each' in n: c+=walk(n['each'])
    return c
for k in ('scrapBadge','scrapInfo','scrapNote'):
    p=glob.glob(os.path.join(src,'*',k+'.json'))[0]; s=open(p).read(); j=json.loads(s)
    n=walk(j['root'])+sum(walk(v['root']) for v in j.get('variants',[]))
    q=os.path.join(dst,os.path.relpath(p,src)); os.makedirs(os.path.dirname(q),exist_ok=True)
    open(q,'w').write(json.dumps(j,ensure_ascii=False,indent=1)+('\n' if s.endswith('\n') else '')); print(k,n)
