import json,glob,os,re,sys
base=os.path.dirname(os.path.abspath(__file__))+'/../../shared/WidgetSpecs/'
ROLE=re.compile(r'^(bg|bg2|ink|ink2|accent|line)(@[\d.]+)?$')
def kind(c):
    if not isinstance(c,str): return None
    if ROLE.match(c): return 'role'
    if c.startswith('#') or c.split('@')[0] in ('white','black'):
        a=float(c.split('@')[1]) if '@' in c else 1
        return 'fixed' if a>=0.6 else None
    return None
def covers(n):
    return n.get('type') in ('rect','stack') and not any(k in n for k in ('w','h','place','dx','dy','pct'))
def first_fill(n):
    if n.get('type')=='rect' and isinstance(n.get('fill'),str): return n['fill']
    if n.get('type')=='stack':
        f=None
        for c in n.get('children',[]):
            if covers(c):
                x=first_fill(c)
                if x: f=x
        return f
    return None
out=[]
def walk(n,bg,path,kindname):
    if isinstance(n.get('fill'),str) and n.get('type')!='rect': bg=(n['fill'],n.get('id') or n.get('type'))
    if n.get('type')=='text':
        c=n.get('color'); tk,bk=kind(c),kind(bg[0]) if bg else None
        if bg and tk and bk and tk!=bk and c.split('@')[0] not in ('white',) or (bg and tk=='role' and bk=='fixed'):
            if tk!=bk and tk and bk:
                out.append((kindname,'/'.join(path),n.get('id') or n.get('text') or n.get('slot'),c,n.get('on'),bg))
    kids=n.get('children',[])
    cur=bg
    for i,c in enumerate(kids):
        walk(c,cur,path+[c.get('id') or c.get('type')],kindname)
        if n.get('type')=='stack' and covers(c):
            f=first_fill(c)
            if f: cur=(f,c.get('id') or c.get('type'))
    if 'each' in n: walk(n['each'],bg,path+['each'],kindname)
for f in sorted(glob.glob(base+'**/*.json',recursive=True)):
    j=json.load(open(f))
    if 'root' in j: walk(j['root'],None,['root'],j['kind'])
    for v in j.get('variants',[]): walk(v['root'],None,['V:'+v['when']],j['kind'])
seen=set()
for o in out:
    key=(o[0],o[2],o[3],o[5][0])
    if key in seen: continue
    seen.add(key); print(o[0],'|',o[2],'|',o[3],'on=',o[4],'| bg',o[5], '|', o[1][-120:] if len(sys.argv)>1 else '')
