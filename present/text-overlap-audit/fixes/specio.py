import json, glob, os
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '../../../shared/WidgetSpecs')
def path(kind):
    for f in glob.glob(ROOT + '/**/*.json', recursive=True):
        if json.load(open(f)).get('kind') == kind: return f
def load(kind):
    return json.load(open(path(kind)))
def save(kind, j):
    open(path(kind), 'w').write(json.dumps(j, ensure_ascii=False, indent=1) + '\n')
def nodes(n):
    yield n
    for c in n.get('children', []): yield from nodes(c)
    if 'each' in n: yield from nodes(n['each'])
def all_roots(j):
    return [j['root']] + [v['root'] for v in j.get('variants', [])]
def find_all(j, pred):
    return [n for r in all_roots(j) for n in nodes(r) if pred(n)]
def by_id(j, i):
    return find_all(j, lambda n: n.get('id') == i)
