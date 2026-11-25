# python3 fixes.py — 25 พ.ย. 2569 "สีวิดเจ็ตดำ ตัวหนังสือหายกลืนกับการ์ด" (idempotent)
# สีวิดเจ็ตดำ/เทา → accent กับ ink ของแผ่น = ขาว (salehere-ios StarCardTheme.widgetAccent: แผ่นสีเทา = สีหมึก)
# 1) ข้อความ/ตรา accent ที่นั่งบนกระดาษสีคงที่ (#FFFDF8 / ซอง #FBF1E6) → ชมพูสแครปบุ๊ก #B8446F (5.0:1 บนครีม)
# 2) ตัวหนังสือ/วงกลมขาว บนกล่อง accent/ink → bg (กล่องกับตัวหนังสือสลับกันเสมอ ไม่ขาวทับขาว)
# 3) scrapTags ป้ายดำ: วงกลม accent + ดาวขาว → วงกลมขาว + ดาว #141414 (คู่กับป้ายครีมที่วงดำดาวขาว)
import json,glob,os,re
base=os.path.dirname(os.path.abspath(__file__))+'/../../shared/WidgetSpecs/'
PINK='#B8446F'
ROLE=re.compile(r'^(bg|bg2|ink|ink2|accent|line)(@[\d.]+)?$')
def fixedhex(f): return isinstance(f,str) and f.startswith('#')
def onpaper(n,ground):
    # accent → ชมพู เมื่อพื้นใต้มันเป็นกระดาษ hex
    if ground and n.get('type')=='text' and n.get('color')=='accent': n['color']=PINK; return 1
    if ground and n.get('type')=='stack' and n.get('fill')=='accent': n['fill']=PINK; return 1
    return 0
def walk1(n,ground):
    c=onpaper(n,ground)
    g=ground or (n.get('type')!='rect' and fixedhex(n.get('fill')))
    for k in n.get('children',[]): c+=walk1(k,g)
    if 'each' in n: c+=walk1(n['each'],g)
    return c
def walk2(n,box):
    c=0
    if box:
        if n.get('type')=='text' and n.get('color')=='white': n['color']='bg'; c+=1
        if n.get('type')=='icon' and n.get('tint')=='white': n['tint']='bg'; c+=1
        if n.get('type')=='rect' and n.get('fill')=='white' and n.get('circle'): n['fill']='bg'; c+=1
    f=n.get('fill'); nb=box
    if n.get('type')!='rect' and isinstance(f,str): nb=f in ('accent','ink')
    for k in n.get('children',[]): c+=walk2(k,nb)
    if 'each' in n: c+=walk2(n['each'],nb)
    return c
def walk3(n):
    c=0
    if n.get('type')=='stack' and n.get('circle') and n.get('fill')=='accent':
        n['fill']='white'; c+=1
        for k in n.get('children',[]):
            if k.get('tint')=='white': k['tint']='#141414'; c+=1
    for k in n.get('children',[]): c+=walk3(k)
    if 'each' in n: c+=walk3(n['each'])
    return c
JOBS={'scrapBadge':walk1,'scrapInfo':walk1,'scrapNote':walk1,
      'popStatsGlass':lambda r,_: walk2(r,False),'popNicheGlass':lambda r,_: walk2(r,False),'popContactGlass':lambda r,_: walk2(r,False),
      'popWorkGlass':lambda r,_: walk2(r,False),'popVideoPaper':lambda r,_: walk2(r,False),'scrapTags':lambda r,_: walk3(r)}
for k,fn in JOBS.items():
    p=glob.glob(base+'*/'+k+'.json')[0]; s=open(p).read(); j=json.loads(s)
    n=fn(j['root'],False)+sum(fn(v['root'],False) for v in j.get('variants',[]))
    o=json.dumps(j,ensure_ascii=False,indent=1)+('\n' if s.endswith('\n') else '')
    if o!=s: open(p,'w').write(o)
    print(k,n)
