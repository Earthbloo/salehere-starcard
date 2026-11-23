import json, glob, os
specs={}
for f in glob.glob('../../shared/WidgetSpecs/**/*.json', recursive=True):
    j=json.load(open(f))
    if 'kind' in j: specs[j['kind']]=j
def find(n, nid, path):
    if n.get('id')==nid and n.get('type')=='text': return path+[n]
    for c in n.get('children',[]):
        r=find(c,nid,path+[n])
        if r: return r
    return None
for x in json.load(open('out/first.json')):
    j=specs[x['kind']]
    roots=[j['root']]+[v['root'] for v in j.get('variants',[])]
    p=None
    for r in roots:
        p=find(r,x['textId'],[])
        if p: break
    if not p: print(x['kind'],'?'); continue
    t=p[-1]; par=p[-2] if len(p)>1 else {}
    feats=[]
    for k in ('size','growTo','shrinkTo','maxLines','w','h','dy','place'):
        if k in t: feats.append(f"{k}={t[k]}")
    anc=[f"{a['type']}{'#'+a['id'] if a.get('id') else ''}(h={a.get('h')},gap={a.get('gap')})" for a in p[-4:-1]]
    sib=[c.get('type')+'#'+str(c.get('id','')) for c in par.get('children',[]) if c is not t]
    print(f"{x['kind']:18} {x['textId']:8} ×{x['other']:18} | {' '.join(feats)} | {' > '.join(anc)} | sib {sib[:4]}")
