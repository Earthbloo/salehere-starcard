#!/usr/bin/env python3
"""สร้าง shared/docs/widget-catalog.html — Dev Spec: widget ทั้งหมดในระบบ แยกหมวด

    python3 shared/tools/build-widget-catalog.py

หน้าแรก = หมวด + รูป widget ล้วน · แตะใบไหน (#w/<kind>) ค่อยเปิดรายละเอียด: จุดข้อมูลบนรูป · Model ของหมวดเป็นชิป · ปรับอะไรได้

อ่านจาก shared/WidgetSpecs/*.json · shared/category-models.json · present/spec-fixtures/{fixtures,cells}
ไม่ต้องมี dependency (ใช้ sips ของ macOS ย่อรูปเป็น JPEG ถ้ามี) · HTML ที่ได้อ่านออฟไลน์ได้ (รูปฝังครั้งเดียวใน JS)
"""
import base64, collections, glob, html, json, os, re, subprocess, sys, tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SPECS = os.path.join(ROOT, 'shared/WidgetSpecs')
FIX = os.path.join(ROOT, 'present/spec-fixtures/fixtures')
CELLS = os.path.join(ROOT, 'present/spec-fixtures/cells')
OUT = os.path.join(ROOT, 'shared/docs/widget-catalog.html')

ORDER = ['hero','seal','intro','text','followers','audience','tags','brand','verified','photo','showcase','rate','availability','body','contact']
LABEL = dict(hero='โปรไฟล์', seal='ตรารับรอง', intro='แนะนำตัว', text='ข้อความ', followers='ผู้ติดตาม', audience='ผู้ชม', tags='หมวดหมู่',
             brand='แบรนด์', verified='ผลงานยืนยัน', photo='รูปผลงาน', showcase='แผ่นโชว์ผลงาน', rate='เรตราคา',
             availability='วันเวลาและพื้นที่', body='สัดส่วน', contact='ติดต่อ')
GROUP = {**{k:'เกี่ยวกับฉัน' for k in 'hero seal intro text followers audience tags body'.split()},
         **{k:'รับงาน' for k in 'rate availability contact'.split()}, **{k:'ผลงาน' for k in 'brand verified photo showcase'.split()}}
GROUP_KEY = {k: {'เกี่ยวกับฉัน': 'me', 'รับงาน': 'job', 'ผลงาน': 'work'}[v] for k, v in GROUP.items()}
TIER = {**{k:'connected' for k in 'followers audience rate'.split()}, **{k:'verified' for k in 'brand verified seal'.split()}}
TIER_TH = dict(personal='ใช้ได้ทุกคน', connected='ต้องเชื่อมข้อมูลก่อน', verified='ต้องผ่าน Sale Here ก่อน')
LOCK = dict(hero='สายงาน', tags='สายงาน', followers='ช่องทาง', intro='แนะนำตัว', rate='เรต', audience='insight ผู้ชม', seal='ยืนยันตัวตน (KYC)',
            brand='งานผ่าน Sale Here ≥ 1', verified='งานผ่าน Sale Here ≥ 1', availability='วันเวลารับงาน', body='สัดส่วน')
SURF = dict(glass='กระจก', dim='เข้ม', clear='ไม่มีพื้น', pane='กระจก (chrome)')
SLOT_TH = dict(name='ชื่อ', nickname='ชื่อเล่น', tagline='สายงานใต้ชื่อ', about='แนะนำตัว', handle='แฮนเดิล', phone='เบอร์', email='อีเมล', lineId='LINE', website='เว็บไซต์',
               workArea='พื้นที่รับงาน', categories='สายงาน', rateLabels='ชื่อเรต', ratePrices='ราคาเรต')
STAMP_TH = dict(followers='ยอดผู้ติดตาม', insight='insight ผู้ชม', work='ผลงาน')

# ---- ชื่อภาษาคนของทุก field ใน Model (ใช้ทั้ง legend และชิป)
LIST_DOC = dict(socials='ช่องทางโซเชียลที่เชื่อมไว้', categories='สายงาน', rates='เรตราคา (เฉพาะที่ตั้งราคา > 0)', brands='แบรนด์ที่เคยร่วมงานผ่าน Sale Here', works='ผลงานที่ทำผ่าน Sale Here',
                gender='สัดส่วนเพศผู้ชม (หญิง/ชาย/อื่น)', ages='ช่วงอายุผู้ชม', places='จังหวัดผู้ชม', contacts='ช่องทางติดต่อ (เฉพาะที่กรอก)', avail='วันเวลารับงาน', areas='จังหวัดรับงาน', body='สัดส่วนร่างกาย', photos='รูปผลงาน')
STAT_TH = dict(totalFollowers='ยอดผู้ติดตามรวม', avgViews='วิวเฉลี่ย', brandCount='จำนวนแบรนด์', workCount='จำนวนผลงาน', socialCount='จำนวนช่องทาง', rateCount='จำนวนเรต',
               placeCount='จำนวนจังหวัด', reach='การเข้าถึง', reachRaw='การเข้าถึง (ตัวเลข)', reachDelta='การเข้าถึงเปลี่ยนไป', reachNew='ผู้ชมใหม่', reachWindow='ช่วงเวลาของ insight',
               reachPlatform='ช่องทางของ insight', reachIcon='โลโก้ช่องทาง insight', cardURL='ลิงก์การ์ด', year='ปี', phoneFmt='เบอร์โทร', site='เว็บไซต์', lineFlow='LINE',
               creatorKind='ประเภทครีเอเตอร์', places='จำนวนจังหวัด', socials='จำนวนช่องทาง')
LIST_TH = dict(socials='ช่องทางโซเชียล', categories='สายงาน', rates='เรตราคา', brands='แบรนด์ที่เคยร่วมงาน', works='ผลงานผ่าน Sale Here',
               gender='เพศผู้ชม', ages='ช่วงอายุผู้ชม', places='จังหวัดผู้ชม', contacts='ช่องทางติดต่อ', avail='วันเวลารับงาน', areas='พื้นที่รับงาน', body='สัดส่วนร่างกาย', photos='รูปผลงาน')
FIELD_TH = dict(followers='ยอดผู้ติดตาม', followersFull='ยอดผู้ติดตาม (เต็ม)', followersRaw='ยอดผู้ติดตาม (ตัวเลข)', name='ชื่อช่องทาง', short='ชื่อย่อ', icon='โลโก้', tint='สีประจำช่อง',
                handle='แฮนเดิล', views='วิวเฉลี่ย', viewsRaw='วิว (ตัวเลข)', engagement='engagement', engagementRaw='engagement (ตัวเลข)', synced='สถานะซิงก์', verified='เชื่อมบัญชีแล้ว',
                platform='แพลตฟอร์ม', text='ข้อความ', label='ชื่อ', price='ราคา', priceRaw='ราคา (ตัวเลข)', priceNum='ราคา (ไม่มี ฿)', unit='หน่วย', platformName='ช่องทาง',
                platformOrder='ลำดับช่องทาง', format='รูปแบบงาน', logo='โลโก้', industry='ประเภทธุรกิจ', brand='แบรนด์', brandLogo='โลโก้แบรนด์', campaign='แคมเปญ', ep='ตอน (EP)',
                cover='ปก', workPhoto='รูปงาน', saves='เซฟ', shares='แชร์', likes='ไลก์', comments='คอมเมนต์', viralTag='ป้ายไวรัล', share='สัดส่วน %', shareRaw='สัดส่วน (ตัวเลข)',
                kind='ชนิด', value='ค่า', num='ตัวเลข', wide='เต็มแถว', photo='รูป', slot='ช่อง')
POINT_TH = dict(ep='ตอน (EP)', icon='โลโก้ช่องทาง', followers='ยอดผู้ติดตาม', followersFull='ยอดผู้ติดตาม', name='ชื่อช่องทาง', short='ชื่อย่อช่องทาง', handle='แฮนเดิล', views='วิว', engagement='engagement',
                text='ข้อความ', label='ชื่อ', price='ราคา', priceNum='ราคา', unit='หน่วย', platformName='ช่องทาง', logo='โลโก้', brand='แบรนด์', campaign='แคมเปญ', cover='รูปปก', workPhoto='รูปงาน',
                share='สัดส่วน %', value='ค่า', num='ค่า', photo='รูป', brandLogo='โลโก้แบรนด์', viralTag='ป้ายไวรัล', likes='ไลก์', saves='เซฟ', shares='แชร์', comments='คอมเมนต์')
# ชื่อ field ที่ความหมายเปลี่ยนตามรายการ (name ของ places = จังหวัด ไม่ใช่ชื่อช่องทาง)
LISTF = dict(brands=dict(name='ชื่อแบรนด์'), places=dict(name='จังหวัด'), gender=dict(label='เพศ'), ages=dict(label='ช่วงอายุ'), areas=dict(text='จังหวัด'), avail=dict(text='วันเวลา'))
SOURCE_TH = dict(socials='บัญชีโซเชียลที่เชื่อมใน Star Profile', categories='สายที่ใช่ใน Star Profile', rates='เรตใน Star Profile', brands='ระบบเติมจากงานที่ผ่าน Sale Here',
                 works='ระบบเติมจากงานที่ผ่าน Sale Here', gender='insight ที่อัปโหลดใน Star Profile', ages='insight ที่อัปโหลดใน Star Profile', places='insight ที่อัปโหลดใน Star Profile',
                 contacts='ช่องทางติดต่อใน Star Profile', avail='วันเวลารับงานใน Star Profile', areas='จังหวัดรับงานใน Star Profile', body='สัดส่วนใน Star Profile', photos='รูปผลงานใน Star Profile')
FLAG_TH = {'owner.verified': 'ผ่าน KYC', 'stamped': 'ได้ป้าย Verified', 'cutout': 'มีรูปตัดพื้นหลัง'}
TPL_SKIP = {'i', 'rank', 'rank2', 'max', 'sum'}

def fth(lst, f, base): return LISTF.get(lst, {}).get(f) or base.get(f, f)
esc = html.escape
def J(o): return esc(json.dumps(o, ensure_ascii=False, indent=2))

# ---- ภาพชี้จุด: กล่องจริงจาก fixture → โหนดในผัง → field ของ Model
def spec_paths(spec):
    """path แบบเดียวกับ id ใน fixture (each → '*' แทน c0 c1 …) → โหนด"""
    out = {}
    def walk(n, path):
        out[path] = n
        if n.get('each'): walk(n['each'], path + '/*')
        for i, c in enumerate(n.get('children') or []): walk(c, f'{path}/{i}')
    walk(spec['root'], 'r')
    for v in spec.get('variants', []): walk(v['root'], 'r')
    return out

def annotate(spec, fixture):
    """คืน (pts, deco) · pts = จุดที่ใช้ข้อมูลจริง [(box, ชื่อ, มาจาก, field)] (เฉพาะชิ้นแรกของแต่ละรายการ) · deco = ป้ายตายตัวในดีไซน์"""
    if not fixture: return [], []
    case = fixture['cases'][0]
    paths = spec_paths(spec)
    pts, deco, seen = [], [], set()
    for b in case['boxes']:
        if b['type'] not in ('text', 'icon', 'image'): continue
        if re.search(r'/c[1-9]\d*(/|$)', b['id']): continue            # ชิ้นที่ 2 ขึ้นไปของรายการ
        key = re.sub(r'/c\d+', '/*', b['id'])
        n = paths.get(key)
        if not n: continue
        lst = None
        if '/*' in key:                                            # หา list ที่ครอบ
            lst = (paths.get(key[:key.index('/*')]) or {}).get('list')
        slot, icon, src = n.get('slot') or '', n.get('icon') or '', n.get('src') or n.get('photoRef') or ''
        if b['type'] == 'text':
            tx = n.get('text') or ''
            tf = [tx[1:]] if tx.startswith('$') else [f for f in re.findall(r'\{(\w+)\}', tx) if f not in TPL_SKIP]
            if slot.startswith('$'): f = slot[1:]; what, src_th, mk = fth(lst, f, POINT_TH), LIST_DOC.get(lst, lst), f'{lst}[].{f}'
            elif lst and not tf and re.search(r'\{rank\d*\}', tx): what, src_th, mk = 'ลำดับที่ระบบนับให้', LIST_DOC.get(lst, lst), f'{lst}[].rank'
            elif tf and lst: what, src_th, mk = ' + '.join(fth(lst, f, POINT_TH) for f in tf), LIST_DOC.get(lst, lst), ' '.join(f'{lst}[].{f}' for f in tf)
            elif slot.startswith(('stat:', 'count:')): what, src_th, mk = STAT_TH.get(slot.split(':', 1)[1], 'ตัวเลขที่ระบบคิดให้'), 'ระบบคิดให้', slot
            elif slot == 'tagline': what, src_th, mk = SLOT_TH['tagline'], 'ระบบต่อจากสายที่ใช่ใน Star Profile', slot
            elif slot: what, src_th, mk = SLOT_TH.get(slot.split('#')[0], slot), 'Star Profile', slot
            elif tx.strip(' ·•—-'): deco.append(tx.strip()); continue
            else: continue
        elif b['type'] == 'icon':
            if icon.startswith('$'): f = icon[1:]; what, src_th, mk = fth(lst, f, POINT_TH), LIST_DOC.get(lst, lst), f'{lst}[].{f}'
            elif icon in ('verifiedBadge', 'byline', 'byline:dark', 'byline:light', 'verifiedPill'): what, src_th, mk = 'ป้าย Verified by Sale Here', 'ขึ้นเมื่อข้อมูลมาจากบัญชีที่เชื่อม', 'stamped'
            elif icon in ('qr',): what, src_th, mk = 'QR ลิงก์การ์ด', 'ระบบสร้าง', 'cardURL'
            else: continue
        else:
            if src.startswith('$'): f = src[1:]; what, src_th, mk = fth(lst, f, POINT_TH), LIST_DOC.get(lst, lst), f'{lst}[].{f}'
            else: what, src_th, mk = f'รูปช่องที่ {n.get("photo", 0) + 1}', 'รูปที่ใส่ในชิ้น (ไม่มี → รูปโปรไฟล์/ผลงาน)', f'photo({n.get("photo", 0) + 1})'
        if (what, mk) in seen: continue
        seen.add((what, mk)); pts.append((b, what, src_th, mk))
    return pts, list(dict.fromkeys(deco))

def figure(spec, fixture, pts):
    """SVG: รูปจริง + กรอบเลขของจุดข้อมูล · รูปมาจาก IMG ใน JS (ฝังครั้งเดียว ใช้ทั้งรูปย่อและหน้ารายละเอียด)"""
    if not fixture: return ''
    W, H = fixture['cases'][0]['box']
    # รูปจากตัวส่งออก = กรอบออกแบบ + ขอบ 12 รอบด้าน (`WidgetMatrixExport.margin`) · กล่องใน fixture วัดจากเนื้อหา
    # (ใบที่ chrome วาดพื้นให้ หักระยะขอบในอีก 12) → วางรูปให้มุมเนื้อหาตรงกับ 0,0 ของกล่อง
    pw, ph = spec['design']['w'] + 24, spec['design']['h'] + 24
    ox, oy = (pw - W) / 2, (ph - H) / 2
    out = [f'<svg class="fig" viewBox="{-ox:.1f} {-oy:.1f} {pw} {ph}" role="img" aria-label="จุดที่ใช้ข้อมูล"><image data-k="{spec["kind"]}" x="{-ox:.1f}" y="{-oy:.1f}" width="{pw}" height="{ph}"/>']
    for i, (b, *_r) in enumerate(pts, 1):
        x, y, w, h = b['x'], b['y'], b['w'], b['h']
        out.append(f'<g class="pt" data-i="{i}"><rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="3"/>'
                   f'<g transform="translate({x - 2:.1f},{y - 2:.1f})"><circle r="9"/><text dy="3.4">{i}</text></g></g>')
    out.append('</svg>')
    return ''.join(out)

def analyze(spec):
    """ดึงจากผัง: ช่องโปรไฟล์ · รายการ + field ที่ใช้ · stat · ธง (widget ไม่มีช่องพิมพ์ตั้งแต่ 19 ต.ค. 2569)"""
    prof, lists, stats, flags = set(), collections.OrderedDict(), set(), set()
    def conds(expr):
        for part in re.split(r'[&|]', expr or ''):
            p = part.strip().lstrip('!'); p = re.sub(r'[=<>].*', '', p)
            if p and not p.startswith('$') and p not in ('', 'w', 'h', 'ratio'): flags.add(p)
    def walk(n, lst=None):
        if isinstance(n, dict):
            if n.get('type') == 'chips' and n.get('list'):
                lists.setdefault(n['list'], set()); lst = n['list']
                conds(n.get('where'))
            s = n.get('slot')
            if n.get('type') == 'text' and s:
                if s.startswith('$'):
                    if lst: lists[lst].add(s[1:])
                elif '#$i' in s:
                    if lst: lists[lst].add(s.split('#')[0] + '#i')
                elif s.startswith(('stat:', 'count:')): stats.add(s)
                else: prof.add(s.split('#')[0])
            if lst:
                for k in ('text', 'icon', 'fill', 'tint', 'pct', 'color', 'src', 'photoRef'):
                    v = n.get(k)
                    if isinstance(v, str):
                        for m in re.findall(r'\$([A-Za-z]+)', v): lists[lst].add(m)
                        if k == 'text':
                            for m in re.findall(r'\{(\w+)\}', v): lists[lst].add(m)
                for m in re.findall(r'\$([A-Za-z]+)', (n.get('if') or '') + ' ' + (n.get('where') or '')): lists[lst].add(m)
            conds(n.get('if'))
            for v in n.values(): walk(v, lst)
        elif isinstance(n, list):
            for x in n: walk(x, lst)
    walk(spec['root']); [walk(v['root']) for v in spec.get('variants', [])]
    for L in lists: lists[L] -= TPL_SKIP
    return sorted(prof), lists, sorted(stats), sorted(flags)

SRC_ITEMS = dict(socials=['Instagram', 'TikTok', 'YouTube'], shownSocials=['Instagram', 'TikTok', 'YouTube'], categories=['บิวตี้', 'สกินแคร์', 'คาเฟ่'],
                 rates=['IG Reels', 'TikTok Video', 'FB Post'], ratePlatforms=['Instagram', 'TikTok', 'Facebook'])

def ui_seg(opts, on=0): return '<span class="ui seg">' + ''.join(f'<i{" class=on" if i == on else ""}>{esc(o)}</i>' for i, o in enumerate(opts)) + '</span>'
def ui_tog(on, note=''): return f'<span class="ui tog{" on" if on else ""}"></span>' + (f'<small>{esc(note)}</small>' if note else '')
def ui_chk(items): return '<span class="ui chk">' + ''.join(f'<i>{esc(x)}</i>' for x in items) + '</span>'

def controls(w):
    """ถาดของ widget เป็นตัวควบคุมจำลอง: (ชื่อแถว, html) · ค่าตั้งต้นถูกเลือกไว้"""
    out = []
    surfs = w.get('surfaces') or ([] if w.get('ownSurface') else ['glass', 'dim', 'clear'])
    names = w.get('surfaceNames', {})
    if surfs: out.append(('พื้นหลัง', ui_seg([names.get(x, SURF[x]) for x in surfs])))
    if not w.get('ownBorder'): out.append(('เส้นขอบ', ui_tog(w.get('border', not w.get('ownSurface', False)))))
    # ตัวเลือกทั้งหมดของใบ = `widget.controls` (19 ต.ค. 2569) — ชื่อแถว + คีย์ที่เก็บใน `options`
    for c in w.get('controls', []):
        t = c['type']
        key = c.get('opt') or '/'.join((c.get('flags') or {}).values())
        lab = f"{esc(c.get('label', t))} <code>{esc(key)}</code>" if key else c.get('label', t)
        items = c.get('items') or c.get('options') or []
        items = SRC_ITEMS.get(items, [items]) if isinstance(items, str) else [x[1] if isinstance(x, list) else x for x in items]
        if t == 'checks': out.append((lab, ui_chk(items)))
        elif t in ('segment', 'pick'): out.append((lab, ui_seg(items)))
        elif t == 'switch': out.append((lab, ui_tog(c.get('default', False))))
        elif t == 'stepper': out.append((lab, f'<span class="ui stp"><i>−</i><b>{c.get("default", "")}</b><i>+</i></span><small>{" · ".join(map(str, c.get("values", [])))}</small>'))
    if w.get('photo'): out.append(('รูป', '<span class="ui btn">อัปโหลดรูป</span>'))
    if w.get('resize', True): out.append(('ย่อ/ขยาย', '<span class="ui btn">↘ ลากมุม</span>' + ('<small>ล็อกสัดส่วน</small>' if w.get('keepAspect') else '')))
    return out

# ---- Model ของหมวด เป็นชิป
def field_name(key):
    """ชื่อภาษาคนของ key ใน Model เช่น 'list:socials.followers' → ('ยอดผู้ติดตาม', 'followers')"""
    kind, _, rest = key.partition(':')
    if key == 'photo': return 'รูปในช่อง', 'photo(N)'
    if kind == 'slot': nm = rest.replace('#N', ''); return (SLOT_TH.get(nm, nm) + (' ข้อที่ N' if rest.endswith('#N') else '')), rest
    if kind == 'stat': return STAT_TH.get(rest, rest), key
    if kind == 'count': return 'จำนวน' + LIST_TH.get(rest, rest), key
    if kind == 'flag': return FLAG_TH.get(rest, rest), rest
    if kind == 'list':
        L, _, f = rest.partition('.')
        return (fth(L, f, FIELD_TH) if f else LIST_TH.get(L, L)), (f or L)
    return key, key

def example(key, seen):
    """ค่าตัวอย่างจาก fixture จริง (เฉพาะที่ใบนี้ถามจริง)"""
    kind, _, rest = key.partition(':')
    if kind == 'slot': v = seen['texts'].get(rest.replace('#N', '#0'))
    elif kind in ('stat', 'count'): v = seen['texts'].get(key)
    elif kind == 'flag': v = seen['flags'].get(rest); v = None if v is None else ('ใช่' if v else 'ไม่')
    elif kind == 'list':
        L, _, f = rest.partition('.'); items = seen['lists'].get(L) or []
        v = (items[0].get(f) if f and items else (f'{len(items)} รายการ' if items else None))
    else: v = None
    if v is None or v == '': return ''
    v = str(v)
    if v.startswith(('about-', 'sh:', 'ph:', 'http')) or re.fullmatch(r'#[0-9A-Fa-f]{6}', v): return ''   # ชื่อไอคอน/สี ไม่ใช่ค่าที่คนอ่าน
    return v if len(v) <= 28 else v[:26] + '…'

def chip(key, used, seen):
    th, code = field_name(key)
    ex = example(key, seen) if used else ''
    return f'<span class="f{" on" if used else ""}"><b>{esc(th)}</b>{f"<i>{esc(ex)}</i>" if ex else ""}<code>{esc(code)}</code></span>'

def model_cards(cat, cm, used, seen):
    """ข้อมูลเดี่ยวที่ใบนี้ใช้ (มีค่าตัวอย่าง) · รายการแยกแถว · ที่เหลือพับไว้"""
    m = cm['categories'].get(cat, {})
    keys = list(cm['base']) + list(m.get('fields', [])) + list(m.get('borrow', []))
    borrow = set(m.get('borrow', []))
    plain = [k for k in keys if not k.startswith('list:')]
    lists = collections.OrderedDict()
    for k in keys:
        if k.startswith('list:'):
            L, _, f = k[5:].partition('.'); lists.setdefault(L, [])
            if f: lists[L].append(k)
    on = [k for k in plain if k in used]; off = [k for k in plain if k not in used]
    h = ['<div class="mdl">']
    h.append('<div class="mrow on"><div class="mh">ข้อมูลเดี่ยว</div><div class="fs">' + (''.join(chip(k, True, seen) for k in on) or '<span class="none">ใบนี้ไม่ใช้</span>') + '</div></div>')
    for L, fks in lists.items():
        lused = f'list:{L}' in used
        fon = [k for k in fks if k in used]; foff = [k for k in fks if k not in used]
        n = len(seen['lists'].get(L) or [])
        h.append(f'<div class="mrow list{" on" if lused else ""}"><div class="mh">{esc(LIST_TH.get(L, L))}{" ↗" if f"list:{L}" in borrow else ""}'
                 f'<small><code>{L}[]</code>{f" · ตัวอย่าง {n} รายการ" if lused and n else ("" if lused else " · ใบนี้ไม่ใช้")}</small><small class="src">{esc(SOURCE_TH.get(L, ""))}</small></div>'
                 f'<div class="fs">{"".join(chip(k, True, seen) for k in fon) if lused else ""}'
                 f'{"".join(chip(k, False, seen) for k in (foff if lused else fks))}</div></div>')
    if off:
        h.append(f'<details class="rest"><summary>ข้อมูลเดี่ยวที่มีในหมวด แต่ใบนี้ไม่ใช้ · {len(off)}</summary><div class="fs">' + ''.join(chip(k, False, seen) for k in off) + '</div></details>')
    h.append('</div>')
    return ''.join(h)

def img_data(kind):
    """รูปเรนเดอร์จริงของ iOS — เลือก PNG หรือ JPEG ที่เล็กกว่า (ฝังครั้งเดียวใน JS)"""
    p = os.path.join(CELLS, f'cell-{kind}-design.png')
    if not os.path.exists(p): return ''
    data, mime = open(p, 'rb').read(), 'image/png'
    try:
        with tempfile.TemporaryDirectory() as td:
            out = os.path.join(td, 'x.jpg')
            subprocess.run(['sips', '-s', 'format', 'jpeg', '-s', 'formatOptions', '84', p, '--out', out], capture_output=True, check=True)
            j = open(out, 'rb').read()
            if len(j) < len(data) * 0.85: data, mime = j, 'image/jpeg'
    except Exception:
        pass
    return f'data:{mime};base64,' + base64.b64encode(data).decode()

# ---- ภาพระดับ data: ① ชิ้นบนกระดาน → ② API ของหมวด (ตัวเดียวใช้ได้ทั้งหมวด) → ③ widget ได้ค่าอะไร
# API คืน Model ของหมวดตรง ๆ (ชื่อ field = category-models.json) · ทุก widget ในหมวดได้ก้อนเดียวกัน แล้วเลือกใช้เอง
NOT_IN_API = {'list:gender', 'list:ages', 'list:places', 'list:brands', 'list:works', 'stat:reach', 'stat:reachDelta', 'stat:reachNew', 'stat:reachWindow',
              'stat:reachRaw', 'stat:reachPlatform', 'stat:reachIcon', 'count:places', 'stat:brandCount', 'stat:workCount', 'list:socials.synced', 'slot:email', 'stat:creatorKind'}
DEVICE_ONLY = {'flag:cutout'}                                # แอปคิดเอง (ตัดพื้นหลังบนเครื่อง) — ไม่ส่งใน API
FROM = {'slot:name': 'myProfile.name', 'slot:handle': 'socialProfiles.profileUrl', 'slot:nickname': 'myProfile.nickname', 'slot:about': 'myProfile.caption',
        'slot:workArea': 'preferredProvinces[0]', 'slot:tagline': 'ต่อจาก categories', 'slot:phone': 'creatorProfile.tel', 'slot:lineId': 'creatorProfile.lineId',
        'slot:website': 'creatorProfile.website', 'flag:owner.verified': 'userVerify.status', 'flag:stamped': 'ทุกช่องทางผูก OAuth', 'photo': 'profileImages + portfolio',
        'list:socials': 'socialProfiles', 'list:rates': 'socialProfiles.*Price', 'list:categories': 'categories.name', 'list:contacts': 'creatorProfile (show*)',
        'list:avail': 'availableTimes', 'list:areas': 'preferredProvinces', 'list:body': 'bodyMeasurement', 'stat:totalFollowers': 'รวม followerCount',
        'count:socials': 'นับ socialProfiles', 'stat:phoneFmt': 'creatorProfile.tel', 'stat:site': 'creatorProfile.website', 'stat:lineFlow': 'creatorProfile.lineId'}
SAMPLE = {}                                                  # ค่าตัวอย่างของทุก field (ตัวข้อมูลเว็บ) — main() เติม
# ช่องโปรไฟล์ของตัวข้อมูลเว็บที่ว่าง = ข้อความชวนกรอก — ตัวอย่าง API ใช้ค่าจริงแบบนี้แทน
NICE = {'slot:name': 'นิรา ภัทรวดี', 'slot:handle': 'nira.beauty', 'slot:nickname': 'นิรา', 'slot:about': 'รีวิวสกินแคร์แบบพูดตรง ใช้จริงก่อนพูดทุกครั้ง',
        'slot:workArea': 'กรุงเทพมหานคร', 'slot:tagline': 'บิวตี้ · สกินแคร์', 'slot:phone': '081-234-5678', 'slot:lineId': '@nirabeauty',
        'slot:website': 'nirabeauty.co', 'slot:email': 'nira@beautyworks.co'}
LIST_SLOTS = {'slot:categories#N', 'slot:rateLabels#N', 'slot:ratePrices#N'}   # ซ้ำกับรายการ categories / rates — ไม่แยกใน API

def node_bin():
    for c in ['node'] + sorted(glob.glob(os.path.expanduser('~/.nvm/versions/node/*/bin/node')), reverse=True) + ['/opt/homebrew/bin/node']:
        try:
            v = subprocess.run([c, '-v'], capture_output=True, text=True).stdout.strip()
            if v and int(v.lstrip('v').split('.')[0]) >= 18: return c
        except Exception: pass
    return None

def load_sample():
    """ค่าตัวอย่างของทุก key ใน category-models.json จาก sync-server/web/js/data.js (MOCK ของเว็บ)"""
    node = node_bin()
    if not node: return {}
    js = """import { Profile, WebSpecData } from %s;
import fs from 'node:fs';
const cm = JSON.parse(fs.readFileSync(%s, 'utf8'));
const d = new WebSpecData({ profile: new Profile({}, {}), item: {}, sample: true, surface: 'glass' });
const keys = new Set(cm.base); for (const c of Object.values(cm.categories)) [...(c.fields || []), ...(c.borrow || [])].forEach(k => keys.add(k));
const out = {};
for (const k of keys) {
  const [kind, rest] = [k.split(':')[0], k.slice(k.indexOf(':') + 1)];
  try {
    if (kind === 'list') { const L = rest.split('.')[0]; if (!out['list:' + L]) out['list:' + L] = d.list(L).slice(0, 2).map(i => i.fields ?? i); }
    else if (kind === 'flag') out[k] = d.flag(rest);
    else if (kind === 'slot') out[k] = d.text(rest.replace('#N', '#0'));
    else if (kind === 'stat' || kind === 'count') out[k] = d.text(k);
  } catch (e) {}
}
console.log(JSON.stringify(out));""" % (json.dumps(os.path.join(ROOT, 'sync-server/web/js/data.js')), json.dumps(os.path.join(ROOT, 'shared/category-models.json')))
    try:
        with tempfile.TemporaryDirectory() as td:
            f = os.path.join(td, 'dump.mjs'); open(f, 'w').write(js)
            r = subprocess.run([node, f], capture_output=True, text=True, timeout=60)
            return json.loads(r.stdout)
    except Exception:
        return {}

def api_name(key):
    kind, _, rest = key.partition(':')
    if key == 'photo': return 'photos'
    if kind == 'slot': return rest.replace('#N', '')
    if kind == 'stat': return rest
    if kind == 'count': return rest + 'Count'
    if kind == 'flag': return rest.replace('owner.', '')
    return rest

def typed(name, v):
    if v is None: return None
    if isinstance(v, bool): return v
    s = str(v)
    if name.endswith('Raw') or name.endswith('Count') or name in ('priceRaw',):
        try: x = float(s.replace(',', '')); return int(x) if x == int(x) else x
        except ValueError: return s
    if name in ('verified',) and s in ('0', '1', 'true', 'false'): return s in ('1', 'true')
    return s

# ---- ② query ของหมวด บน API จริงของ salehere-ios (schema.json) — ทุก field อยู่ใต้ myProfile: User
SCHEMA = os.path.expanduser('~/salehere-ios/SaleHere/Resources/API/schema.json')
CAMPAIGNS = 'brandCampaigns(limit: 20, filter: { status: reviewed })'       # งานที่ส่งรีวิวแล้ว = ผลงาน/แบรนด์ที่ยืนยันได้
SOC = 'socialProfiles'
CP = 'creatorProfile'
INS = f'{CAMPAIGNS}.items.myActivityInfo.myApplication.socialInsights'
def _p(*xs): return list(xs)
# Model key → path ใน schema (นับจาก myProfile) · ไม่มีใน dict = ยังไม่มีใน API (❗) · DEVICE_ONLY = แอปคิดเอง
REAL = {
    'slot:name': _p('displayName'), 'slot:nickname': _p('nickname'), 'slot:about': _p('caption(autoGenerateWhenEmpty: false)'),
    'slot:handle': _p(f'{SOC}.type', f'{SOC}.accountId', f'{SOC}.profileUrl'),
    'slot:tagline': _p('categories(limit: 20).name'), 'slot:categories#N': _p('categories(limit: 20).name'),
    'list:categories': _p('categories(limit: 20).name'), 'list:categories.text': _p('categories(limit: 20).name'),
    'slot:workArea': _p(f'{CP}.preferredProvinces'), 'list:areas': _p(f'{CP}.preferredProvinces'), 'list:areas.text': _p(f'{CP}.preferredProvinces'),
    'photo': _p('profileImage.imgPath', f'{CP}.profileImages.seq', f'{CP}.profileImages.image.imgPath', f'{CP}.portfolio.images.seq', f'{CP}.portfolio.images.image.imgPath',
                f'{CP}.portfolio.videos.videoThumbnail.imgPath'),
    'flag:owner.verified': _p('isVerify', 'verifyStatus'), 'flag:stamped': _p(f'{SOC}.statusSyncFollower'),
    'stat:cardURL': _p('userSlug'),
    # ช่องทาง
    'list:socials': _p(f'{SOC}.type'), 'count:socials': _p(f'{SOC}.type'), 'stat:socialCount': _p(f'{SOC}.type'),
    **{f'list:socials.{f}': _p(f'{SOC}.type') for f in ('platform', 'name', 'short', 'icon', 'tint')},
    'list:socials.handle': _p(f'{SOC}.accountId', f'{SOC}.displayName'),
    **{f'list:socials.{f}': _p(f'{SOC}.followerCount') for f in ('followers', 'followersFull', 'followersRaw')},
    **{f'list:socials.{f}': _p(f'{SOC}.avgViewCount') for f in ('views', 'viewsRaw')},
    **{f'list:socials.{f}': _p(f'{SOC}.avgEngagementCount', f'{SOC}.followerCount') for f in ('engagement', 'engagementRaw')},
    'list:socials.verified': _p(f'{SOC}.statusSyncFollower'),
    'stat:totalFollowers': _p(f'{SOC}.followerCount'), 'stat:avgViews': _p(f'{SOC}.avgViewCount'),
    # ผู้ชม = insight ที่อัปโหลดต่อช่องทาง
    **{f'list:gender{f}': _p(f'{SOC}.type', f'{SOC}.insight.gender.label', f'{SOC}.insight.gender.displayName', f'{SOC}.insight.gender.percentage') for f in ('', '.label', '.share', '.shareRaw', '.tint')},
    **{f'list:ages{f}': _p(f'{SOC}.type', f'{SOC}.insight.age.label', f'{SOC}.insight.age.displayName', f'{SOC}.insight.age.percentage') for f in ('', '.label', '.share', '.shareRaw')},
    **{f'list:places{f}': _p(f'{SOC}.type', f'{SOC}.insight.location.label', f'{SOC}.insight.location.displayName', f'{SOC}.insight.location.percentage') for f in ('', '.name', '.share', '.shareRaw')},
    'count:places': _p(f'{SOC}.insight.location.label'), 'stat:placeCount': _p(f'{SOC}.insight.location.label'),
    # เรต
    **{f'list:rates{f}': _p(f'{SOC}.type', f'{SOC}.photoPrice', f'{SOC}.shortVdoPrice', f'{SOC}.longVdoPrice', f'{SOC}.sharingPrice')
       for f in ('', '.label', '.price', '.priceRaw', '.priceNum', '.unit', '.platform', '.platformName', '.platformOrder', '.icon', '.tint', '.format')},
    'slot:rateLabels#N': _p(f'{SOC}.type'), 'slot:ratePrices#N': _p(f'{SOC}.shortVdoPrice'), 'stat:rateCount': _p(f'{SOC}.photoPrice', f'{SOC}.shortVdoPrice'),
    # ติดต่อ
    'slot:phone': _p(f'{CP}.tel', f'{CP}.showTel'), 'stat:phoneFmt': _p(f'{CP}.tel', f'{CP}.showTel'),
    'slot:lineId': _p(f'{CP}.lineId', f'{CP}.showLineId'), 'stat:lineFlow': _p(f'{CP}.lineId', f'{CP}.showLineId'),
    'slot:website': _p(f'{CP}.website', f'{CP}.showWebsite'), 'stat:site': _p(f'{CP}.website', f'{CP}.showWebsite'),
    'list:contacts': _p(f'{CP}.tel', f'{CP}.showTel', f'{CP}.lineId', f'{CP}.showLineId', f'{CP}.website', f'{CP}.showWebsite'),
    # วันเวลา · สัดส่วน
    **{f'list:avail{f}': _p(f'{CP}.availableTimes.day', f'{CP}.availableTimes.displayText', f'{CP}.availableTimes.timeSlots.timeSlotKey', f'{CP}.availableTimes.timeSlots.isSelected') for f in ('', '.text')},
    **{f'list:body{f}': [f'{CP}.bodyMeasurement.{m}.{x}' for m in ('height', 'weight', 'chest', 'waist', 'hip', 'shoeSize') for x in ('value', 'unit')]
       for f in ('', '.kind', '.label', '.value', '.num', '.unit', '.wide')},
    # แบรนด์ · ผลงาน = แคมเปญที่ส่งรีวิวแล้ว
    'list:brands': _p(f'{CAMPAIGNS}.items.brand.id'), 'list:brands.name': _p(f'{CAMPAIGNS}.items.brand.name'),
    'list:brands.logo': _p(f'{CAMPAIGNS}.items.brand.logoImg.imgPath'), 'list:brands.industry': _p(f'{CAMPAIGNS}.items.brand.categories(limit: 1).name'),
    'stat:brandCount': _p(f'{CAMPAIGNS}.items.brand.id'),
    'list:works': _p(f'{CAMPAIGNS}.items.id'), 'list:works.brand': _p(f'{CAMPAIGNS}.items.brand.name'), 'list:works.brandLogo': _p(f'{CAMPAIGNS}.items.brand.logoImg.imgPath'),
    'list:works.campaign': _p(f'{CAMPAIGNS}.items.title'), 'list:works.ep': _p(f'{CAMPAIGNS}.items.title'),
    **{f'list:works.{f}': _p(f'{INS}.socialType') for f in ('platform', 'icon', 'tint')}, 'list:works.format': _p(f'{INS}.postFormat'),
    'list:works.cover': _p(f'{CAMPAIGNS}.items.coverImage.imgPath'), 'list:works.workPhoto': _p(f'{CAMPAIGNS}.items.coverImage.imgPath'),
    **{f'list:works.{f}': _p(f'{INS}.metrics.views') for f in ('views', 'viewsRaw', 'viralTag')},
    'list:works.saves': _p(f'{INS}.metrics.saves'), 'list:works.shares': _p(f'{INS}.metrics.shares'), 'list:works.likes': _p(f'{INS}.metrics.likes'),
    'list:works.comments': _p(f'{INS}.metrics.comments'), 'list:works.engagement': _p(f'{INS}.metrics.engagement'),
    'stat:workCount': _p(f'{CAMPAIGNS}.totalItem'),
}
# ❗ ยังไม่มีใน API ของ salehere-ios — บอกสิ่งที่ต้องเพิ่มเป็นคำ
MISSING_NOTE = {'stat:reach': 'reach / การเข้าถึง (insight มีแค่ เพศ · อายุ · เมือง)', 'stat:reachDelta': 'reach', 'stat:reachNew': 'reach', 'stat:reachWindow': 'reach',
                'stat:reachRaw': 'reach', 'stat:reachPlatform': 'reach', 'stat:reachIcon': 'reach', 'list:socials.synced': 'เวลาซิงก์ล่าสุด (มีแค่ statusSyncFollower)',
                'slot:email': 'อีเมล (creatorProfile ไม่มี email)', 'stat:creatorKind': 'creatorType บน creatorProfile (บุคคล / เพจ)'}

def schema_check(paths):
    """ตรวจทุก path กับ schema.json ของ salehere-ios · คืนรายการที่ไม่ผ่าน (ไม่มีไฟล์ = ข้าม)"""
    if not os.path.exists(SCHEMA): return []
    global _T
    if '_T' not in globals():
        _T = {t['name']: t for t in json.load(open(SCHEMA))['__schema']['types']}
    def named(t):
        while t.get('ofType'): t = t['ofType']
        return t
    bad = []
    for p in paths:
        cur = _T['User']
        for seg in p.split('.'):
            f = next((x for x in (cur.get('fields') or []) if x['name'] == seg.split('(')[0]), None)
            if not f: bad.append(p); break
            nt = named(f['type']); cur = _T[nt['name']]
        else:
            if cur['kind'] not in ('SCALAR', 'ENUM'): bad.append(p + ' (ต้องเลือก field ย่อย)')
    return bad

EX = dict(displayName='นิรา ภัทรวดี', nickname='นิรา', caption='รีวิวสกินแคร์แบบพูดตรง ใช้จริงก่อนพูดทุกครั้ง', userSlug='nira-beauty', isVerify=True, verifyStatus='approved',
          imgPath='https://img.salehere.co.th/p/1200x0/2026/10/19/nira01.jpg', seq=1, accountId='nira.beauty', profileUrl='https://instagram.com/nira.beauty',
          followerCount=184000, avgViewCount=92000, avgEngagementCount=8648, statusSyncFollower='completed', photoPrice=3000, shortVdoPrice=5000, longVdoPrice=None, sharingPrice=1500,
          preferredProvinces=['กรุงเทพมหานคร', 'นนทบุรี'], tel='0812345678', showTel=True, lineId='@nirabeauty', showLineId=True, website='nirabeauty.co', showWebsite=True,
          day='saturday', timeSlotKey='slot_17_late', isSelected=True, value=165, unit='cm', title='EP.1335 Sivanna Colors Ballet Dream', id=1335, totalItem=5,
          postFormat='video', views=1200000, saves=2400, shares=310, likes=18000, comments=420, engagement=4.2)
LISTY = {SOC, 'profileImages', 'images', 'videos', 'items', 'gender', 'age', 'location', 'availableTimes', 'timeSlots', 'socialInsights', 'categories'}
TWO = {SOC, 'gender', 'age', 'location', 'categories', 'items'}
def ex_leaf(k, i, parent):
    if k == 'type': return ['instagram', 'tiktok'][i % 2]
    if k == 'socialType': return 'tiktok'
    if k == 'name': return {'categories': ['บิวตี้', 'สกินแคร์'][i % 2], 'brand': ['Sivanna Colors', 'Cathy Doll'][i % 2]}.get(parent, 'ความงาม')
    if k == 'label': return {'gender': ['female', 'male'], 'age': ['18-24', '25-34'], 'location': ['bangkok', 'chonburi']}.get(parent, ['a', 'b'])[i % 2]
    if k == 'displayName': return {'gender': ['หญิง', 'ชาย'], 'age': ['18–24 ปี', '25–34 ปี'], 'location': ['กรุงเทพฯ', 'ชลบุรี']}.get(parent, [EX['displayName']] * 2)[i % 2]
    if k == 'percentage': return [68.2, 30.1][i % 2]
    if k == 'displayText': return 'ส. 17.00 เป็นต้นไป' if parent == 'availableTimes' else '17.00 เป็นต้นไป'
    if k == 'value': return dict(height=165, weight=48, chest=32, waist=25, hip=35, shoeSize=38).get(parent, 165)
    if k == 'unit': return dict(weight='kg', chest='inch', waist='inch', hip='inch', shoeSize='eur').get(parent, 'cm')
    if k == 'followerCount': return [184000, 320500][i % 2]
    if k == 'title': return ['EP.1335 Sivanna Colors Ballet Dream', 'EP.1286 Cathy Doll Glow Serum'][i % 2]
    return EX.get(k)

def fill(tree, parent='', i=0):
    """คำตอบตัวอย่างตามรูปจริงของ schema · รายการได้ 1–2 ชิ้น"""
    o = {}
    for k, sub in tree.items():
        nm = k.split('(')[0]
        if sub:
            if nm in LISTY: o[nm] = [fill(sub, nm, j) for j in range(2 if nm in TWO else 1)]
            else: o[nm] = fill(sub, nm, i)
        else: o[nm] = ex_leaf(nm, i, parent)
    return o

def model_api(cat, cm, used, seen):
    """② query ของหมวดบน API จริง (salehere-ios) · บรรทัด = field ใน schema · คอมเมนต์ = field ของ Model ที่ได้ค่าจากบรรทัดนั้น"""
    m = cm['categories'].get(cat, {})
    keys = [k for k in list(cm['base']) + list(m.get('fields', [])) + list(m.get('borrow', [])) if k not in DEVICE_ONLY]
    feeds = collections.OrderedDict()                       # path → [model key]
    for k in keys:
        for p in REAL.get(k, []): feeds.setdefault(p, []).append(k)
    missing = [k for k in keys if k not in REAL]
    bad = schema_check(list(feeds))
    tree = {}
    for p in feeds:
        cur = tree
        for seg in p.split('.'): cur = cur.setdefault(seg, {})
    def short(k):
        kind, _, rest = k.partition(':')
        if kind == 'list': return rest if '.' in rest else rest + '[]'
        return rest.replace('#N', '') if kind in ('slot', 'flag') else k
    def render(t, ind, prefix):
        out = []
        for seg, sub in t.items():
            path = f'{prefix}.{seg}' if prefix else seg
            under = [k for p, ks in feeds.items() if p == path or p.startswith(path + '.') for k in ks]
            on = any(k in used for k in under)
            if sub:
                out.append(f'<span class="ln {"on" if on else "off"}">{" " * ind}<span class="jk">{esc(seg)}</span> {{</span>')
                out += render(sub, ind + 2, path)
                out.append(f'<span class="ln {"on" if on else "off"}">{" " * ind}}}</span>')
            else:
                ks = list(dict.fromkeys(short(k) for k in feeds.get(path, [])))
                cm_ = f'  <span class="c"># → {esc(" · ".join(ks[:4]))}{" …" if len(ks) > 4 else ""}</span>' if ks else ''
                out.append(f'<span class="ln {"on" if on else "off"}">{" " * ind}<span class="jk">{esc(seg)}</span>{cm_}</span>')
        return out
    name = 'StarCard' + cat[0].upper() + cat[1:] + 'Model'
    Q = [f'<span class="c"># {name} — ตัวเดียวใช้ได้ทั้งหมวด{LABEL[cat]} · ตรวจกับ salehere-ios schema.json แล้ว</span>', f'query {name} {{', '  <span class="jk">myProfile</span> {']
    Q += render(tree, 4, '')
    Q += ['  }', '}']
    notes = list(dict.fromkeys(MISSING_NOTE.get(k, short(k)) for k in missing))
    if notes: Q.append('<span class="miss">' + '\n'.join(f'# ❗ ยังไม่มีใน API: {esc(n)}' for n in notes) + '</span>')
    if bad: Q.append('<span class="miss">' + '\n'.join(f'# ⚠ ไม่ผ่าน schema: {esc(b)}' for b in bad) + '</span>')
    resp = {'data': {'myProfile': fill(tree)}}
    return '\n'.join(Q), resp, len(notes), bad

def hl_json(o):
    s = esc(json.dumps(o, ensure_ascii=False, indent=2))
    s = re.sub(r'(&quot;[^&]*?&quot;)(\s*:)', r'<span class="jk">\1</span>\2', s)
    s = re.sub(r'(:\s*)(&quot;.*?&quot;)', r'\1<span class="js">\2</span>', s)
    s = re.sub(r'(:\s*|^\s*|\[\s*)(-?\d+(?:\.\d+)?|true|false|null)(?=\s*[,\n\]}])', r'\1<span class="jn">\2</span>', s, flags=re.M)
    return s

def ctl_block(spec):
    """ตัวเลือกของใบจากไฟล์ผัง — front อ่านอันนี้อันเดียวก็รู้ว่าใบนี้ปรับอะไรได้ เก็บที่คีย์ไหน"""
    c = spec['widget'].get('controls')
    if not c: return '<p class="fnote">ใบนี้ไม่มีตัวเลือก (<code>widget.controls</code> ไม่มี) — <code>options</code> ว่างเสมอ</p>'
    return ('<div class="ph" style="margin-top:10px"><b>ตัวเลือกของใบ · <code>widget.controls</code></b>'
            '<small>ค่าที่ผู้ใช้เลือกเก็บที่ <code>options[opt]</code> · ค่าตั้งต้นไม่เก็บ</small></div>'
            f'<pre>{hl_json(c)}</pre>')

def board_item(spec, photo_slots):
    w = spec['widget']; d = w.get('size') or spec['design']
    # ทุกชิ้นทรงเดียวกัน: ฟิลด์หลัก 8 ตัวครบเสมอ + `options` (ของพิเศษของใบนั้น ระบบไม่ต้องรู้จัก) — ค่าตั้งต้นตาม WidgetKind.defaultSurface/defaultBorder
    it = dict(id='3f2a9c1e-5b7d-4e8a-9c41-2d6f8b0a7e15', kind=spec['kind'], x=18, y=96, w=d['w'], h=d['h'],
              surface=(w.get('surfaces') or ['glass'])[0],
              border=bool(w.get('border', not w.get('ownSurface', False))))
    # `options` = ค่าที่ผู้ใช้เปลี่ยนจากค่าตั้งต้นของ `widget.controls` (คีย์ = `opt`) — ชิ้นที่วางใหม่ยังไม่ได้ปรับ = ว่าง
    it['options'] = {}
    it['photos'] = {str(min(photo_slots)): dict(imageId=918273)} if photo_slots else {}
    return it

def data_flow(spec, cm, seen, used, pts):
    cat = spec['widget']['category']
    photo_slots = sorted({int(re.search(r'\d+', mk).group()) for (_b, _w, _s, mk) in pts if mk.startswith('photo(')})
    item = board_item(spec, photo_slots)
    q, resp, miss, bad = model_api(cat, cm, used, seen)
    if bad: print('⚠', spec['kind'], bad)
    return f'''
  <section class="blk flow">
    <h3>ภาพระดับ data <small>วางบนกระดาน → ขอ API ของหมวด → widget เลือกใช้</small></h3>
    <div class="fl">
      <div class="pane"><div class="ph"><span class="st">①</span><b>ชิ้นบนกระดาน</b><small>เก็บใน <code>pages[].items[]</code> ของการ์ด · ไม่มีข้อความ ไม่มีข้อมูลเจ้าของ</small></div><pre>{hl_json(item)}</pre>{ctl_block(spec)}</div>
      <div class="pane"><div class="ph"><span class="st">②</span><b>query ของหมวด{LABEL[cat]} บน salehere-ios</b><small>ตัวเดียวใช้ได้ทั้งหมวด · <span class="lg on">เข้ม</span> = ใบนี้ใช้ · <span class="lg off">จาง</span> = ใบอื่นในหมวดใช้ · <code># →</code> = field ของ Model ที่ได้ค่า{f" · ❗ {miss} อย่างยังไม่มีใน API" if miss else ""}</small></div>
        <pre class="q">{q}</pre><details class="raw"><summary>ตัวอย่างคำตอบ (JSON)</summary><pre>{hl_json(resp)}</pre></details></div>
    </div>
    <p class="fnote">③ แอปแปลงคำตอบเป็น Model ของหมวด (184000 → “184K” · percentage → share) ทุก widget ในหมวดได้ก้อนเดียวกันแล้วหยิบเฉพาะ field ที่ผังอ้าง — ค่าที่ใช้จริงอยู่ในชิปข้างล่าง</p>
  </section>'''

def detail(spec, fixture, siblings, cm):
    kind, w = spec['kind'], spec['widget']
    cat = w['category']
    prof, lists, stats, flags = analyze(spec)
    design = spec['design']
    pts, deco = annotate(spec, fixture)
    fig = figure(spec, fixture, pts) or f'<img class="shot" data-k="{kind}" alt="{kind}">'
    # ---- สรุปบนสุด
    meta = [LABEL[cat], TIER_TH[w.get('tier') or TIER.get(cat, 'personal')]]
    if LOCK.get(cat): meta.append(f'ล็อกจนกรอก{LOCK[cat]}')
    meta.append(f'{design["w"]}×{design["h"]}')
    if w.get('stamp'): meta.append(f'ป้าย Verified: {STAMP_TH[w["stamp"]]}')
    if w.get('pinned'): meta.append('ตรึงก้นหน้า ลบไม่ได้')
    # ---- จุดข้อมูล (เลขตรงกับรูป) + ป้ายตายตัว
    rows = ''.join(f'<li data-i="{i}"><span class="num">{i}</span><span class="w">{esc(what)}</span><span class="s">{esc(src_th)}</span><code>{esc(mk)}</code></li>'
                   for i, (b, what, src_th, mk) in enumerate(pts, 1))
    deco_html = (f'<p class="deco"><b>ป้ายตายตัวในดีไซน์</b> {" · ".join(esc(d) for d in deco[:14])}{" …" if len(deco) > 14 else ""}</p>' if deco else '')
    # ---- ปรับอะไรได้
    can = ''.join(f'<li><b>{a if "<code>" in a else esc(a)}</b><span class="ctl">{b}</span></li>' for a, b in controls(w))
    # ---- Model + ค่าตัวอย่าง
    used = set()
    for p in prof: used.add('slot:' + p)
    for L, fs in lists.items():
        used.add('list:' + L); [used.add(f'list:{L}.{f}') for f in fs]
    for st in stats: used.add(st)
    for f in flags:
        if f in ('stamped', 'cutout', 'owner.verified'): used.add('flag:' + f)
    if any(k in ('photo', 'photoRef') for k in json.dumps(spec).split('"')): used.add('photo')
    fd = (fixture or {}).get('cases', [{}])[0].get('data', {})
    seen = dict(texts={t['slot']: t['v'] for t in fd.get('texts', [])},
                lists={L: [it['fields'] for it in items] for L, items in fd.get('lists', {}).items()},
                flags=dict(fd.get('flags', {})))
    raw = dict(seen['texts'])
    for L in lists: raw[L] = [{k: v for k, v in it.items() if k in lists[L]} for it in (seen['lists'].get(L) or [])[:3]]
    i = siblings.index(kind)
    prev, nxt = (siblings[i - 1] if i else None), (siblings[i + 1] if i + 1 < len(siblings) else None)
    nav = (f'<div class="pn">{f"<a href=#w/{prev}>← ใบก่อน</a>" if prev else "<span></span>"}'
           f'<span>{i + 1} / {len(siblings)} ในหมวด{LABEL[cat]}</span>{f"<a href=#w/{nxt}>ใบถัดไป →</a>" if nxt else "<span></span>"}</div>')
    return f'''
<article class="wd" data-k="{kind}" data-g="{GROUP_KEY[cat]}" hidden>
  <a class="back" href="#cat-{cat}">← {LABEL[cat]}</a>
  <div class="hero">
    <div class="stage">{fig}</div>
    <div class="info">
      <div class="eyebrow">{LABEL[cat]} · {GROUP[cat]}</div>
      <h2>{esc(w["title"])}</h2>
      <code class="kind">{kind}</code>
      <div class="meta">{"".join(f"<span>{esc(m)}</span>" for m in meta)}</div>
      <h3>ใช้ข้อมูลอะไร <small>เลขตรงกับรูป</small></h3>
      {f'<ol class="pts">{rows}</ol>' if rows else '<p class="mut">ไม่ใช้ข้อมูลของเจ้าของการ์ด — เป็นดีไซน์ล้วน</p>'}
      {deco_html}
    </div>
  </div>
{data_flow(spec, cm, seen, used, pts)}
  <section class="blk"><h3>③ widget ได้ค่าอะไร · Model ของหมวด{LABEL[cat]} <small>สีเข้ม = ใบนี้ใช้ · ตัวหนา = ค่าจริงตอนวาด</small></h3>{model_cards(cat, cm, used, seen)}</section>
  <section class="blk two">
    <div><h3>ผู้ใช้ปรับอะไรได้ <small>ค่าตั้งต้นถูกเลือกไว้ · ข้อความแก้ไม่ได้</small></h3><ul class="kv tray">{can}</ul></div>
    <div><h3>สำหรับ dev</h3><ul class="kv"><li><b>ไฟล์ผัง</b><span><code>shared/WidgetSpecs/{kind}.json</code></span></li><li><b>fixture</b><span><code>present/spec-fixtures/fixtures/{kind}.json</code></span></li><li><b>ลำดับในตู้</b><span>{w.get("order", "—")}</span></li></ul>
      <details class="raw"><summary>ค่าที่ widget ได้รับจริง (JSON)</summary><pre>{J(raw)}</pre></details></div>
  </section>
  {nav}
</article>'''

CSS = '''
  :root { --bg:#f6f4f5; --paper:#fff; --ink:#1d1416; --mute:#6c5d61; --faint:#a1959a; --line:#e6dde0; --chip:#f2edef; --accent:#9c2236; --stage:#1a1f35;
          --me:#9c2236; --me-soft:#f8e6ea; --job:#1f6f5c; --job-soft:#e1f2ec; --work:#3d4fb0; --work-soft:#e5e9fa; --pt:#ffd36b;
          --display:"Anuphan","IBM Plex Sans Thai",system-ui,sans-serif; --body:"IBM Plex Sans Thai",system-ui,sans-serif; --mono:"IBM Plex Mono",ui-monospace,Menlo,monospace; }
  @media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { --bg:#131012; --paper:#1c181a; --ink:#f1e9eb; --mute:#a8999d; --faint:#6f6468; --line:#33292d; --chip:#272023; --accent:#ff8597;
          --me:#ff8597; --me-soft:#3a2229; --job:#6fd3b4; --job-soft:#163029; --work:#a3b1ff; --work-soft:#1f2442; color-scheme:dark; } }
  :root[data-theme="dark"] { --bg:#131012; --paper:#1c181a; --ink:#f1e9eb; --mute:#a8999d; --faint:#6f6468; --line:#33292d; --chip:#272023; --accent:#ff8597;
          --me:#ff8597; --me-soft:#3a2229; --job:#6fd3b4; --job-soft:#163029; --work:#a3b1ff; --work-soft:#1f2442; color-scheme:dark; }
  * { box-sizing:border-box; }
  body { margin:0; background:var(--bg); color:var(--ink); font:15px/1.6 var(--body); padding:0 16px 80px; }
  a { color:inherit; } code { font:12px var(--mono); }
  .page { max-width:1120px; margin:0 auto; }
  .g-me, [data-g="me"] { --g:var(--me); --gs:var(--me-soft); } .g-job, [data-g="job"] { --g:var(--job); --gs:var(--job-soft); } .g-work, [data-g="work"] { --g:var(--work); --gs:var(--work-soft); }
  /* หน้าแรก: หมวด + รูป widget */
  header.top { padding:40px 0 18px; }
  .eyebrow { font:500 12px/1 var(--mono); letter-spacing:.08em; text-transform:uppercase; color:var(--g, var(--accent)); }
  h1 { font:700 clamp(28px,4.4vw,42px)/1.15 var(--display); margin:10px 0 6px; }
  .lede { color:var(--mute); margin:0; }
  nav.cats { position:sticky; top:0; z-index:5; background:color-mix(in srgb, var(--bg) 92%, transparent); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px);
             margin:0 -16px; padding:10px 16px; border-bottom:1px solid var(--line); display:flex; gap:16px; overflow-x:auto; scrollbar-width:none; }
  .ng { display:flex; align-items:center; gap:6px; flex:none; } .ng > span { font:600 12px var(--display); color:var(--g); margin-right:2px; }
  .ng a { text-decoration:none; font-size:13px; padding:5px 10px; border-radius:999px; background:var(--paper); border:1px solid var(--line); white-space:nowrap; }
  .ng a small { color:var(--faint); margin-left:5px; font-size:11.5px; } .ng a:hover { border-color:var(--g); }
  .grp { margin-top:34px; }
  .gh { font:600 13px var(--display); color:var(--g); letter-spacing:.02em; display:flex; align-items:center; gap:10px; } .gh::after { content:""; flex:1; height:2px; background:var(--g); opacity:.25; }
  section.cat { margin-top:16px; background:var(--paper); border:1px solid var(--line); border-top:4px solid var(--g); border-radius:16px; padding:18px 18px 20px; scroll-margin-top:64px; }
  .ch { display:flex; flex-wrap:wrap; align-items:baseline; gap:4px 12px; margin-bottom:14px; }
  .ch h2 { font:700 24px/1.2 var(--display); margin:0; } .ch code { color:var(--g); background:var(--gs); padding:2px 8px; border-radius:6px; }
  .ch .n { font-weight:600; } .ch .cm { color:var(--mute); font-size:13.5px; }
  .cards { display:grid; grid-template-columns:repeat(auto-fill, minmax(210px, 1fr)); gap:14px; }
  .card { text-decoration:none; display:flex; flex-direction:column; gap:3px; border-radius:14px; padding:8px 8px 10px; border:1px solid transparent; transition:border-color .15s, transform .15s, background .15s; }
  .card:hover { border-color:var(--line); background:var(--bg); transform:translateY(-2px); }
  .card .th { position:relative; aspect-ratio:4/3; background:var(--stage); border-radius:10px; overflow:hidden; margin-bottom:6px; }
  .card img { position:absolute; inset:6px; width:calc(100% - 12px); height:calc(100% - 12px); object-fit:contain; }
  .card b { font:600 15px/1.3 var(--display); } .card code { color:var(--faint); }
  @media (max-width:520px) { .cards { grid-template-columns:repeat(2, minmax(0, 1fr)); gap:8px; } .card { padding:4px 4px 8px; } .card b { font-size:13.5px; } section.cat { padding:14px 10px 14px; } }
  /* หน้ารายละเอียดของ widget */
  body.detail #home { display:none; }
  .wd { padding-top:22px; }
  .back { display:inline-block; text-decoration:none; font-size:14px; color:var(--mute); padding:6px 0; } .back:hover { color:var(--ink); }
  .hero { display:grid; grid-template-columns:minmax(0,1.15fr) minmax(0,1fr); gap:24px; align-items:start; margin-top:8px; }
  @media (max-width:820px) { .hero { grid-template-columns:minmax(0,1fr); } }
  .stage { background:var(--stage); border-radius:16px; padding:10px; position:sticky; top:12px; }
  @media (max-width:820px) { .stage { position:static; } }
  svg.fig, .shot { width:100%; height:auto; display:block; border-radius:10px; }
  svg.fig .pt rect { fill:none; stroke:var(--pt); stroke-width:1.6; } svg.fig .pt circle { fill:var(--pt); } svg.fig .pt text { font:700 11px var(--mono); fill:#1d1416; text-anchor:middle; }
  svg.fig .pt.hl rect { stroke-width:3; fill:rgba(255,211,107,.2); }
  .info h2 { font:700 30px/1.15 var(--display); margin:8px 0 2px; } .kind { color:var(--faint); }
  .meta { display:flex; flex-wrap:wrap; gap:6px; margin:12px 0 4px; } .meta span { font-size:12.5px; padding:3px 10px; border-radius:999px; background:var(--chip); }
  .meta span:first-child { background:var(--gs); color:var(--g); font-weight:600; }
  h3 { font:600 16px/1.3 var(--display); margin:22px 0 10px; } h3 small { font:400 12.5px var(--body); color:var(--faint); margin-left:6px; }
  ol.pts { list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:2px; }
  ol.pts li { display:grid; grid-template-columns:24px minmax(0,1fr) auto; grid-template-areas:"n w c" "n s s"; column-gap:10px; padding:7px 8px; border-radius:10px; }
  ol.pts li:hover, ol.pts li.hl { background:var(--chip); }
  .num { grid-area:n; display:inline-grid; place-items:center; width:22px; height:22px; border-radius:50%; background:var(--pt); color:#1d1416; font:700 11px var(--mono); }
  ol.pts .w { grid-area:w; font-weight:600; } ol.pts .s { grid-area:s; font-size:13px; color:var(--mute); } ol.pts code { grid-area:c; color:var(--faint); align-self:center; }
  .deco { font-size:13px; color:var(--mute); margin:12px 0 0; padding:10px 12px; background:var(--chip); border-radius:10px; } .deco b { color:var(--ink); font-weight:600; margin-right:6px; }
  .blk { margin-top:28px; border-top:1px solid var(--line); }
  .blk.two { display:grid; grid-template-columns:repeat(2, minmax(0,1fr)); gap:24px; } @media (max-width:820px) { .blk.two { grid-template-columns:minmax(0,1fr); } }
  .mdl { display:flex; flex-direction:column; gap:10px; }
  .mrow { display:grid; grid-template-columns:200px minmax(0,1fr); gap:12px; padding:12px; border-radius:12px; background:var(--paper); border:1px solid var(--line); }
  .mrow.list:not(.on) { opacity:.55; }
  @media (max-width:640px) { .mrow { grid-template-columns:minmax(0,1fr); } }
  .mh { font:600 14.5px/1.35 var(--display); } .mh small { display:block; font:400 12px var(--body); color:var(--faint); margin-top:2px; } .mh small.src { color:var(--mute); }
  .fs { display:flex; flex-wrap:wrap; gap:6px; align-content:flex-start; }
  .f { display:inline-flex; flex-direction:column; gap:1px; padding:6px 10px; border-radius:10px; background:var(--chip); min-width:0; max-width:100%; }
  .f b { font-weight:500; font-size:13px; } .f code { font-size:11px; color:var(--faint); }
  .f i { font-style:normal; font-weight:700; font-size:14px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
  .f.on { background:var(--gs); box-shadow:inset 0 0 0 1px color-mix(in srgb, var(--g) 35%, transparent); } .f.on b { color:var(--g); font-weight:600; }
  .f:not(.on) { opacity:.7; } .none { color:var(--faint); font-size:13px; }
  details.rest summary, details.raw summary { cursor:pointer; font-size:13px; color:var(--mute); padding:4px 0; } details.rest .fs { margin-top:8px; }
  ul.kv { list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:8px; }
  ul.kv li { display:grid; grid-template-columns:140px minmax(0,1fr); gap:10px; font-size:14px; } ul.kv b { font-weight:600; } ul.kv span { color:var(--mute); min-width:0; overflow-wrap:anywhere; }
  @media (max-width:520px) { ul.kv li { grid-template-columns:minmax(0,1fr); gap:0; } }
  pre { margin:8px 0 0; background:var(--chip); border-radius:10px; padding:10px 12px; font:11.5px/1.55 var(--mono); overflow:auto; max-height:360px; }
  .pn { display:flex; justify-content:space-between; align-items:center; gap:10px; margin-top:32px; padding-top:16px; border-top:1px solid var(--line); font-size:13.5px; color:var(--mute); }
  .pn a { text-decoration:none; color:var(--ink); font-weight:600; padding:8px 12px; border-radius:10px; background:var(--paper); border:1px solid var(--line); white-space:nowrap; }
  .mut { color:var(--mute); }

  #render { display:none; } body.render #render { display:block; } body.render #home, body.render article.wd { display:none !important; }
  .mg { display:inline-block; font:700 10.5px var(--mono); letter-spacing:.04em; text-transform:uppercase; color:#1d1416; background:var(--pt); padding:1px 7px; border-radius:6px; margin-left:8px; vertical-align:2px; }
  .rp { display:grid; grid-template-columns:minmax(0,1.25fr) minmax(0,1fr); gap:18px; align-items:start; }
  @media (max-width:900px) { .rp { grid-template-columns:minmax(0,1fr); } }
  .rstage { background:var(--paper); border:1px solid var(--line); border-radius:16px; padding:14px; min-width:0; position:sticky; top:64px; }
  @media (max-width:900px) { .rstage { position:static; } }
  .rpick { display:flex; align-items:center; gap:8px; margin-bottom:12px; font-size:13px; color:var(--mute); }
  .rpick select { font:inherit; font-size:14px; padding:6px 10px; border-radius:9px; border:1px solid var(--line); background:var(--bg); color:var(--ink); max-width:100%; min-width:0; flex:1; }
  .rview { min-height:420px; display:flex; align-items:center; justify-content:center; background:var(--chip); border-radius:12px; padding:16px; overflow:auto; }
  .rlist { list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:6px; }
  .rlist li { position:relative; overflow:hidden; display:grid; grid-template-columns:32px minmax(0,1fr); gap:10px; padding:10px 12px; border-radius:14px; cursor:pointer; border:1px solid transparent; }
  .rlist .pg { position:absolute; left:0; bottom:0; height:3px; width:100%; background:var(--pt); transform-origin:left; animation:rBar linear both; }
  .rlist.paused .pg { animation-play-state:paused; opacity:.5; }
  .rlist li:hover { background:var(--paper); } .rlist li.on { background:var(--paper); border-color:var(--line); }
  .rlist .sn { width:28px; height:28px; border-radius:50%; display:grid; place-items:center; font:700 13px var(--mono); border:1px solid var(--line); color:var(--mute); }
  .rlist li.on .sn { background:var(--accent); color:#fff; border-color:var(--accent); } .rlist li.done .sn { background:var(--chip); color:var(--ink); } .rlist li.merge .sn { box-shadow:0 0 0 2px var(--pt); }
  .rlist b { font:600 16px var(--display); } .rlist code { float:right; color:var(--faint); font-size:12px; }
  .rlist p { margin:6px 0 8px; font-size:14px; color:var(--ink); }
  .rlist dl { display:grid; grid-template-columns:44px minmax(0,1fr); gap:4px 10px; margin:0; font-size:13.5px; } .rlist dt { color:var(--faint); font-size:12px; } .rlist dd { margin:0; }
  .rlist dd.mm { font-weight:600; color:var(--ink); background:color-mix(in srgb, var(--pt) 30%, transparent); padding:0 6px; border-radius:6px; justify-self:start; }
  .rnav { display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-top:12px; }
  .rnav button { font:600 14px var(--display); padding:10px; border-radius:12px; border:1px solid var(--line); background:var(--paper); color:var(--ink); cursor:pointer; }
  .rnav button.pri { background:var(--ink); color:var(--paper); border-color:var(--ink); } .rnav button:disabled { opacity:.35; cursor:default; }
  .pair { display:flex; align-items:center; gap:16px; flex-wrap:wrap; justify-content:center; width:100%; } .pair.v { align-items:flex-start; }
  .arrow { font-size:28px; color:var(--faint); }
  .cardj { background:var(--paper); border:1px solid var(--line); border-radius:12px; padding:10px; max-width:320px; min-width:0; } .cardj.wide { max-width:100%; width:100%; }
  .cardj pre { max-height:380px; margin:6px 0 0; } .cap { font-size:12.5px; color:var(--mute); margin-bottom:4px; }
  .mini { position:relative; flex:none; border-radius:14px; background:radial-gradient(120% 80% at 20% 0%, #2a3160, #141834 60%, #0f1226); overflow:hidden; }
  .mini .ml { position:absolute; left:8px; bottom:6px; font:500 10.5px var(--mono); color:rgba(255,255,255,.45); }
  .mf { position:absolute; border:2px solid var(--pt); border-radius:6px; background:rgba(255,211,107,.12); display:flex; flex-direction:column; align-items:center; justify-content:center; color:#fff; font:12px var(--mono); text-align:center; overflow:hidden; }
  .mf b { font:700 13px var(--mono); } .mf span { color:var(--pt); font-size:10.5px; } .mf.img { background:none; } .mf img { position:absolute; }
  .conv { width:100%; display:flex; flex-direction:column; gap:6px; }
  .conv .ch { display:grid; grid-template-columns:minmax(0,1fr) 28px minmax(0,1fr); font-size:12px; color:var(--faint); padding:0 8px; }
  .cr { display:grid; grid-template-columns:minmax(0,1fr) 28px minmax(0,1fr); align-items:center; background:var(--paper); border:1px solid var(--line); border-radius:10px; padding:8px; }
  .cr > div { display:flex; flex-direction:column; min-width:0; } .cr code { font-size:11.5px; color:var(--faint); overflow-wrap:anywhere; } .cr b { font-size:14.5px; overflow-wrap:anywhere; } .cr small { font-size:12px; color:var(--g, var(--accent)); }
  .cr .ar { text-align:center; color:var(--pt); font-weight:700; font-size:18px; }
  .scl { display:flex; flex-direction:column; align-items:flex-start; gap:12px; position:relative; }
  .sb { border:2px dashed var(--faint); border-radius:10px; position:relative; } .sb.fr { border:2px solid var(--pt); background:rgba(255,211,107,.12); }
  .sb span { position:absolute; left:8px; top:6px; font:12px var(--mono); color:var(--mute); } .fx { font-size:14px; margin:4px 0 0; } .fx b { font-size:16px; }
  .stg { background:var(--stage); border-radius:12px; padding:8px; flex:1 1 300px; min-width:0; max-width:460px; }
  .rsv { width:100%; height:auto; display:block; }
  /* การ์ดที่ประกอบทีละขั้น: .sc.rN = ถึงขั้น N แล้ว (สะสม) · .cN = ขั้นปัจจุบัน */
  .sc { position:relative; margin:0 auto; width:calc(540px * var(--s, .6)); height:calc(960px * var(--s, .6)); }
  .scin { position:absolute; left:0; top:0; width:540px; height:960px; transform:scale(var(--s, .6)); transform-origin:0 0; border-radius:34px; overflow:hidden;
    background:radial-gradient(120% 70% at 15% 0%, #33407a, #1a1f45 55%, #10132b); box-shadow:0 18px 50px rgba(0,0,0,.35); }
  .scin .lab { position:absolute; left:20px; bottom:16px; font:500 15px var(--mono); color:rgba(255,255,255,.4); }
  .sc .ly { position:absolute; opacity:0; transition:opacity .45s ease var(--d, 0ms), transform .5s cubic-bezier(.2,.8,.2,1) var(--d, 0ms), background .4s, color .4s, border-color .4s; }
  .sc .seal { opacity:1; } .sc .seal img { position:absolute; }
  .sc .frame { border:3px dashed var(--pt); border-radius:10px; transform:scale(1.08); background:rgba(255,211,107,.07); }
  .sc.r0 .frame { opacity:1; transform:none; } .sc.r5 .frame { background:transparent; } .sc.r6 .frame { border-color:transparent; }
  .sc .pos { font:700 17px var(--mono); color:#1d1416; background:var(--pt); padding:3px 9px; border-radius:7px; white-space:nowrap; transform:translateY(6px); }
  .sc.r0 .pos { opacity:1; transform:none; } .sc.r6 .pos { opacity:0; }
  .sc .tag { font:700 15px var(--mono); padding:3px 9px; border-radius:7px; white-space:nowrap; right:0; top:-34px; }
  .sc .tag.api { background:#3B82F6; color:#fff; } .sc .tag.mod { background:var(--pt); color:#1d1416; }
  .sc.c1 .tag.api, .sc.c2 .tag.mod { opacity:1; }
  .sc .chip { transform:translate(-50%, -50%) scale(.5); font:700 17px var(--mono); padding:4px 9px; border-radius:8px; white-space:nowrap; z-index:3;
    background:#3B82F6; color:#fff; box-shadow:0 4px 14px rgba(0,0,0,.35); }
  .sc .chip .m { display:none; } .sc.r2 .chip { background:var(--pt); color:#1d1416; } .sc.r2 .chip .a { display:none; } .sc.r2 .chip .m { display:inline; }
  .sc.r1 .chip { opacity:1; transform:translate(-50%, -50%); } .sc.c2 .chip { animation:rFlip .5s ease var(--d, 0ms) both; } .sc.r5 .chip { opacity:0; transform:translate(-50%, -50%) scale(.6); }
  @keyframes rFlip { 0% { transform:translate(-50%, -50%) rotateX(0); } 50% { transform:translate(-50%, -50%) rotateX(90deg); } 100% { transform:translate(-50%, -50%) rotateX(0); } }
  .sc .ghost { border:3px solid #A5B4FC; border-radius:8px; transition:opacity .3s, width 1s cubic-bezier(.6,0,.2,1) .25s, height 1s cubic-bezier(.6,0,.2,1) .25s, left 1s cubic-bezier(.6,0,.2,1) .25s, top 1s cubic-bezier(.6,0,.2,1) .25s; }
  .sc .ghost span { position:absolute; left:6px; top:calc(100% + 8px); background:#1a1f45; padding:2px 8px; border-radius:6px; font:700 16px var(--mono); color:#C7D2FE; white-space:nowrap; }
  .sc.c3 .ghost { opacity:1; }
  .sc .wire { pointer-events:none; } .sc.r4 .wire { opacity:1; } .sc.r5 .wire { opacity:0; }
  .sc .wire .lay { fill:none; stroke:rgba(160,175,255,.55); stroke-dasharray:4 4; stroke-width:1.2; } .sc .wire .bg { fill:rgba(255,255,255,.05); stroke:rgba(255,255,255,.18); stroke-width:1; }
  .sc .wire .cnt { fill:rgba(255,255,255,.08); stroke:rgba(255,255,255,.5); stroke-width:1.2; } .sc .wire .bo { fill:rgba(255,211,107,.2); stroke:var(--pt); stroke-width:2.2; }
  .sc.c4 .wire rect { animation:rPop .45s cubic-bezier(.2,.8,.2,1) var(--d, 0ms) both; transform-box:fill-box; transform-origin:center; }
  .sc .wimg { overflow:hidden; } .sc .wimg img { position:absolute; } .sc.r5 .wimg { opacity:1; transition-duration:.9s; }
  .sc .png { left:50%; top:22px; transform:translate(-50%, -8px); font:700 18px var(--mono); color:#1d1416; background:#fff; padding:5px 14px; border-radius:999px; }
  .sc.r6 .png { opacity:1; transform:translate(-50%, 0); } .sc.c6 .scin { animation:rShot .6s ease both; }
  @keyframes rShot { 0% { filter:brightness(1); } 30% { filter:brightness(1.6); } 100% { filter:brightness(1); } }
  .rcap { text-align:center; font-size:14px; margin:12px 0 0; min-height:2.6em; } .rcap b { color:var(--ink); } .rcap .mg { margin-left:0; margin-right:6px; }
  .rdet { margin-top:10px; } .rdet pre { max-height:260px; overflow:auto; margin:0; font-size:12px; } .rdet .conv { gap:4px; } .rdet .cr { padding:6px 8px; } .rdet .cr b { font-size:13px; }
  .rdet .bl { gap:3px; } .rdet .tk { gap:5px; } .rdet .fx { font-size:13.5px; }
  @media (prefers-reduced-motion: reduce) { .sc .ly, .sc .ghost { transition:none !important; animation:none !important; } .sc.c6 .scin, .sc.c4 .wire rect, .sc.c2 .chip { animation:none !important; } }
  /* motion: ทุกขั้นเล่นเองเมื่อเปิด · --d = หน่วงของชิ้นนั้น */
  @keyframes rBar { from { transform:scaleX(0); } to { transform:scaleX(1); } }
  @keyframes rUp { from { opacity:0; transform:translateY(12px); } }
  @keyframes rIn { from { opacity:0; transform:translateX(-22px); } }
  @keyframes rPop { 0% { opacity:0; transform:scale(.4); } 70% { transform:scale(1.12); } 100% { opacity:1; transform:scale(1); } }
  @keyframes rFade { from { opacity:0; } }
  @keyframes rOut { to { opacity:0; } }
  @keyframes rDrop { from { opacity:0; transform:translateY(-36px) scale(1.25); } }
  @keyframes rGrow { from { width:var(--w0); height:var(--h0); } }
  @keyframes rReveal { from { clip-path:inset(0 0 100% 0); } to { clip-path:inset(0 0 0 0); } }
  @keyframes rGlow { 0%,100% { box-shadow:0 0 0 0 rgba(255,211,107,0); } 40% { box-shadow:0 0 0 6px rgba(255,211,107,.35); } }
  .a-up { animation:rUp .45s cubic-bezier(.2,.8,.2,1) var(--d,0ms) both; } .a-in { animation:rIn .45s cubic-bezier(.2,.8,.2,1) var(--d,0ms) both; }
  .a-pop { animation:rPop .5s cubic-bezier(.2,.8,.2,1) var(--d,0ms) both; } .a-fade { animation:rFade .35s ease var(--d,0ms) both; }
  .a-drop { animation:rDrop .7s cubic-bezier(.2,.8,.2,1) var(--d,0ms) both; } .a-rev { animation:rReveal 1.6s ease-out var(--d,0ms) both; }
  .a-grow { animation:rGrow 1.1s cubic-bezier(.6,0,.2,1) var(--d,0ms) both; } .a-glow { animation:rGlow 1.2s ease var(--d,0ms) both; }
  .rsv .bd, .rsv rect, .rsv g { transform-box:fill-box; transform-origin:center; }
  .rsv.paint image { animation:rFade 1.2s ease .5s both; } .rsv.paint .wire { opacity:1; animation:rOut 1s ease 1.1s both; } .rsv.paint .bd rect { animation:rOut .8s ease 1.4s both; }
  @media (prefers-reduced-motion: reduce) { .rview *, .rlist .pg { animation:none !important; } .rsv.paint .wire, .rsv.paint .bd rect { opacity:0; } }
  .rmap { margin-top:22px; background:var(--paper); border:1px solid var(--line); border-radius:16px; padding:16px; }
  .rmap h2 { font:700 20px var(--display); margin:0 0 4px; } .rmap .lede { margin:0 0 12px; }
  .rmap .mh, .mr { display:grid; grid-template-columns:minmax(0,1fr) 92px minmax(0,1fr) 78px minmax(0,1.1fr); align-items:center; gap:4px; }
  .rmap .mh { font-size:12.5px; color:var(--mute); padding:0 10px 6px; } .rmap .mh i { font-style:normal; margin-right:4px; } .rmap .mh small { color:var(--faint); margin-left:4px; font-size:11.5px; }
  .rmap .mh .key { color:var(--ink); font-weight:600; }
  .mr { padding:8px 10px; border-top:1px solid var(--line); }
  .mr > div[class^=c] { display:flex; flex-direction:column; min-width:0; } .mr code { font-size:11.5px; color:var(--faint); overflow-wrap:anywhere; } .mr b { font-size:14.5px; overflow-wrap:anywhere; }
  .mr .c2 { background:color-mix(in srgb, var(--pt) 22%, transparent); border:1px solid color-mix(in srgb, var(--pt) 60%, transparent); border-radius:10px; padding:6px 8px; }
  .mr .c2 code { color:var(--ink); font-weight:700; font-size:12.5px; } .mr .c2 small { font-size:12px; color:var(--mute); }
  .mr .c3 code { color:var(--ink); background:var(--chip); padding:4px 7px; border-radius:7px; align-self:flex-start; font-size:12px; }
  .mr .hw { display:flex; flex-direction:column; align-items:center; text-align:center; } .mr .hw span { font-size:11px; color:var(--mute); line-height:1.25; } .mr .hw i { font-style:normal; color:var(--pt); font-weight:700; font-size:18px; line-height:1; }
  .mr.miss .c1 b.no { font-size:13px; color:#E5484D; }
  .rnote { margin:12px 0 0; font-size:13.5px; color:var(--mute); }
  @media (max-width:700px) { .rmap .mh { display:none; } .mr { grid-template-columns:minmax(0,1fr); gap:2px; } .mr .hw { flex-direction:row; gap:6px; justify-content:flex-start; } .mr .hw i { transform:rotate(90deg); font-size:14px; } }
  .rsv.wireonly image { opacity:0; }
  .rsv .lay { fill:none; stroke:rgba(160,175,255,.35); stroke-dasharray:3 3; stroke-width:.8; } .rsv .bg { fill:rgba(255,255,255,.04); stroke:rgba(255,255,255,.12); stroke-width:.6; }
  .rsv .cnt { fill:rgba(255,255,255,.06); stroke:rgba(255,255,255,.4); stroke-width:.8; }
  .rsv .bd rect { fill:rgba(255,211,107,.18); stroke:var(--pt); stroke-width:1.6; } .rsv .bd circle { fill:var(--pt); } .rsv .bd text { font:700 10px var(--mono); fill:#1d1416; text-anchor:middle; }
  .rsv.paint .bd rect { fill:none; }
  .bl { list-style:none; margin:0; padding:0; flex:1 1 240px; min-width:0; display:flex; flex-direction:column; gap:4px; }
  .bl li { display:grid; grid-template-columns:22px minmax(0,1fr) auto; grid-template-areas:"n w v" "n c c"; column-gap:8px; background:var(--paper); border:1px solid var(--line); border-radius:9px; padding:6px 8px; font-size:13px; }
  .bl .num { grid-area:n; } .bl b { grid-area:w; font-weight:600; } .bl code { grid-area:c; color:var(--faint); font-size:11px; } .bl i { grid-area:v; font-style:normal; font-weight:700; color:var(--ink); }
  .tk { flex:1 1 220px; min-width:0; display:flex; flex-wrap:wrap; gap:6px; align-content:flex-start; } .tk .cap { width:100%; margin-top:6px; }
  .tk > span { display:inline-flex; align-items:center; gap:6px; font:12px var(--mono); background:var(--paper); border:1px solid var(--line); padding:3px 8px; border-radius:999px; }
  .tk i { width:12px; height:12px; border-radius:50%; box-shadow:inset 0 0 0 1px rgba(0,0,0,.2); } .tk pre { width:100%; margin:0; }
  .fin { max-width:280px; font-size:13.5px; }

  /* แท็บบนสุด */
  nav.tabs { position:sticky; top:0; z-index:8; display:flex; gap:4px; padding:8px 16px; margin:0 -16px; background:color-mix(in srgb, var(--bg) 94%, transparent); backdrop-filter:blur(8px); -webkit-backdrop-filter:blur(8px); border-bottom:1px solid var(--line); overflow-x:auto; }
  nav.tabs a { text-decoration:none; font:600 14px var(--display); padding:7px 14px; border-radius:10px; color:var(--mute); white-space:nowrap; }
  nav.tabs a small { font:400 12px var(--body); color:var(--faint); margin-left:6px; }
  nav.tabs a.on { background:var(--paper); color:var(--ink); box-shadow:0 0 0 1px var(--line); }
  @media (max-width:640px) { nav.tabs a small { display:none; } nav.tabs a { padding:7px 10px; } }
  nav.cats { top:50px; }
  #play { display:none; } body.play #play { display:block; } body.play #home, body.play article.wd { display:none !important; }
  .ptop { padding-top:26px; }
  .pl { display:grid; grid-template-columns:220px minmax(0,1fr) minmax(0,400px); gap:16px; align-items:start; }
  @media (max-width:1100px) { .pl { grid-template-columns:200px minmax(0,1fr); } .pl .api { grid-column:1 / -1; } .pl .pal { position:static; max-height:720px; } }
  @media (max-width:700px) { .pl { grid-template-columns:minmax(0,1fr); } }
  .pal { position:sticky; top:62px; max-height:calc(100vh - 80px); overflow:auto; background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:10px; }
  @media (max-width:700px) { .pl .pal { position:static; max-height:none; } #pal { display:flex; gap:8px; overflow-x:auto; } #pal .pg { display:contents; } #pal .pg > b { display:none; } }
  .pal input { width:100%; font:inherit; font-size:13px; padding:7px 10px; border-radius:9px; border:1px solid var(--line); background:var(--bg); color:var(--ink); margin-bottom:8px; }
  .pg { margin-bottom:10px; } .pg > b { display:block; font:600 12px var(--display); color:var(--g); margin:6px 2px; }
  .pw { display:grid; grid-template-columns:44px minmax(0,1fr); gap:8px; align-items:center; padding:5px; border-radius:9px; cursor:grab; touch-action:none; user-select:none; -webkit-user-select:none; font-size:13px; line-height:1.25; }
  .pw:hover { background:var(--chip); } .pw img { width:44px; height:34px; object-fit:contain; background:var(--stage); border-radius:6px; pointer-events:none; }
  @media (max-width:700px) { .pw { grid-template-columns:minmax(0,1fr); width:96px; flex:none; text-align:center; } .pw img { width:96px; height:72px; } }
  .boardwrap { display:flex; flex-direction:column; gap:10px; min-width:0; }
  .bar { display:flex; align-items:center; gap:8px; font-size:13px; color:var(--mute); } .bar #cnt { margin-right:auto; }
  .bar button, .ptabs button { font:inherit; font-size:13px; padding:5px 12px; border-radius:9px; border:1px solid var(--line); background:var(--paper); color:var(--ink); cursor:pointer; }
  .board { background:var(--chip); border-radius:16px; padding:14px; display:flex; justify-content:center; overflow:hidden; }
  .page9 { position:relative; width:540px; height:960px; transform-origin:top left; border-radius:22px; background:radial-gradient(120% 80% at 20% 0%, #2a3160, #141834 60%, #0f1226); box-shadow:0 10px 30px rgba(0,0,0,.25); flex:none; touch-action:none; }
  .page9::before { content:""; position:absolute; inset:18px; border:1px dashed rgba(255,255,255,.12); border-radius:12px; pointer-events:none; }
  .page9.drop { outline:3px solid var(--pt); outline-offset:4px; }
  .it { position:absolute; cursor:grab; touch-action:none; user-select:none; -webkit-user-select:none; }
  .it .im { position:absolute; inset:0; overflow:hidden; border-radius:10px; pointer-events:none; } .it .im img { position:absolute; pointer-events:none; }
  .it.sel { outline:3px solid var(--pt); outline-offset:2px; border-radius:10px; z-index:5; }
  .it .rs { position:absolute; right:-10px; bottom:-10px; width:22px; height:22px; border-radius:50%; background:var(--pt); border:3px solid #1d1416; cursor:nwse-resize; display:none; }
  .it.sel .rs { display:block; } .it.pin::after { content:"ตรึง"; position:absolute; left:6px; top:6px; font:700 11px var(--body); color:#1d1416; background:var(--pt); padding:1px 6px; border-radius:6px; }
  .ghost { position:fixed; z-index:50; pointer-events:none; opacity:.85; width:120px; border-radius:8px; box-shadow:0 8px 24px rgba(0,0,0,.35); }
  .sel { background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:10px 12px; font-size:13.5px; display:flex; flex-wrap:wrap; gap:6px 12px; align-items:center; }
  .sel b { font:600 15px var(--display); } .sel button { font:inherit; font-size:13px; padding:4px 10px; border-radius:8px; border:1px solid var(--line); background:var(--bg); color:var(--ink); cursor:pointer; }
  .sel button[disabled] { opacity:.4; cursor:not-allowed; }
  .api { background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:10px; position:sticky; top:62px; max-height:calc(100vh - 80px); overflow:auto; }
  @media (max-width:1100px) { .api { position:static; max-height:none; } }
  .ptabs { display:flex; gap:4px; margin-bottom:8px; } .ptabs button.on { background:var(--ink); color:var(--paper); border-color:var(--ink); }
  .hint { font-size:12.5px; color:var(--mute); margin:0 0 8px; }
  #doc .isel { background:color-mix(in srgb, var(--pt) 28%, transparent); display:block; border-radius:4px; }
  .flash { animation:fl .7s ease-out; } @keyframes fl { from { background:color-mix(in srgb, var(--pt) 45%, transparent); } }
  .log { list-style:none; margin:0 0 8px; padding:0; font-size:12.5px; display:flex; flex-direction:column; gap:3px; max-height:150px; overflow:auto; }
  .log li { display:grid; grid-template-columns:54px minmax(0,1fr); gap:6px; padding:4px 6px; border-radius:7px; background:var(--chip); } .log li b { font-family:var(--mono); font-size:11.5px; color:var(--g, var(--accent)); }
  .call { border:1px solid var(--line); border-radius:10px; padding:8px 10px; margin-bottom:8px; font-size:13px; }
  .call b { font-family:var(--mono); font-size:12.5px; } .call .ws { display:flex; flex-wrap:wrap; gap:4px; margin-top:6px; } .call .ws span { font-size:12px; padding:2px 8px; border-radius:999px; background:var(--gs, var(--chip)); color:var(--g, var(--ink)); }
  .call .n { float:right; color:var(--faint); font-size:12px; }
  @media (prefers-reduced-motion: reduce) { .flash { animation:none; } }
  .flow .fl { display:grid; grid-template-columns:minmax(0,.75fr) minmax(0,1.25fr); gap:14px; align-items:start; }
  @media (max-width:820px) { .flow .fl { grid-template-columns:minmax(0,1fr); } }
  .pane { background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:12px; min-width:0; }
  .ph { display:grid; grid-template-columns:auto minmax(0,1fr); column-gap:8px; align-items:baseline; margin-bottom:8px; } .ph b { font:600 15px var(--display); } .ph small { grid-column:2; color:var(--mute); font-size:12.5px; }
  .st { display:inline-grid; place-items:center; width:24px; height:24px; border-radius:50%; background:var(--gs); color:var(--g); font-weight:700; grid-row:span 2; }
  .pane pre { max-height:420px; } .pane pre + pre { margin-top:8px; } pre.q { color:var(--mute); }
  .jk { color:var(--g); } .js { color:var(--ink); } .jn { color:#c2711b; } .c { color:var(--faint); } .miss { color:#d14343; font-family:var(--body); font-size:11.5px; }
  pre.q { max-height:none; } pre.q .ln.off { opacity:.38; } pre.q .ln.on .jk { font-weight:600; } .lg.on { color:var(--g); font-weight:600; } .lg.off { opacity:.5; }
  ul.kv.tray li { grid-template-columns:96px minmax(0,1fr); align-items:center; } ul.kv.tray b { font-weight:500; color:var(--mute); font-size:13.5px; }
  .ctl { display:flex; flex-wrap:wrap; align-items:center; gap:6px 8px; color:var(--ink) !important; } .ctl small { color:var(--faint); font-size:12px; }
  .ui.seg { display:inline-flex; background:var(--chip); border-radius:9px; padding:2px; gap:2px; flex-wrap:wrap; }
  .ui.seg i { font-style:normal; font-size:12.5px; padding:3px 10px; border-radius:7px; color:var(--mute); }
  .ui.seg i.on { background:var(--paper); color:var(--ink); font-weight:600; box-shadow:0 1px 2px rgba(0,0,0,.12); }
  .ui.tog { width:34px; height:20px; border-radius:10px; background:var(--line); position:relative; flex:none; }
  .ui.tog::after { content:""; position:absolute; top:2px; left:2px; width:16px; height:16px; border-radius:50%; background:#fff; box-shadow:0 1px 2px rgba(0,0,0,.25); }
  .ui.tog.on { background:#34C759; } .ui.tog.on::after { left:16px; }
  .ui.chk { display:flex; flex-wrap:wrap; gap:4px 10px; } .ui.chk i { font-style:normal; font-size:12.5px; display:inline-flex; align-items:center; gap:5px; }
  .ui.chk i::before { content:"✓"; display:inline-grid; place-items:center; width:15px; height:15px; border-radius:4px; background:var(--ink); color:var(--paper); font-size:10px; font-weight:700; }
  .ui.stp { display:inline-flex; align-items:center; border:1px solid var(--line); border-radius:9px; overflow:hidden; } .ui.stp i { font-style:normal; padding:1px 9px; color:var(--mute); }
  .ui.stp b { padding:1px 10px; border-inline:1px solid var(--line); font-variant-numeric:tabular-nums; }
  .ui.btn { font-size:12.5px; padding:3px 10px; border-radius:8px; border:1px solid var(--line); background:var(--paper); }
  .fnote { font-size:13px; color:var(--mute); margin:10px 0 0; }
'''

JS = '''
const home = document.getElementById('home');
let cur = null;
function fill(root) { root.querySelectorAll('img[data-k], image[data-k]').forEach(el => { const u = IMG[el.dataset.k]; if (!u) return; el.tagName.toLowerCase() === 'img' ? (el.src = u) : el.setAttribute('href', u); }); }
function route() {
  const h = decodeURIComponent(location.hash.slice(1));
  if (cur) { cur.hidden = true; cur = null; }
  if (h.startsWith('w/')) {
    const a = document.querySelector('article.wd[data-k="' + h.slice(2) + '"]');
    if (a) { fill(a); a.hidden = false; cur = a; document.body.classList.add('detail'); window.scrollTo(0, 0); document.title = a.querySelector('h2').textContent + ' · Widget Catalog'; return; }
  }
  const view = (h === 'play' || h === 'render') ? h : 'cat';
  document.body.classList.toggle('play', view === 'play'); document.body.classList.toggle('render', view === 'render');
  document.querySelectorAll('nav.tabs a').forEach(a => a.classList.toggle('on', a.dataset.tab === view));
  if (view !== 'cat') { document.body.classList.remove('detail'); document.title = (view === 'play' ? 'ลองวางการ์ด' : 'วิธีวาด') + ' · Widget Catalog'; window.scrollTo(0, 0); window.dispatchEvent(new Event(view + '-open')); return; }
  document.body.classList.remove('detail'); document.title = 'Star Card Widget Catalog';
  const t = h && document.getElementById(h); if (t) t.scrollIntoView(); else if (!h) window.scrollTo(0, 0);
}
fill(home);
window.addEventListener('hashchange', route); route();
// ชี้รายการ ↔ กรอบบนรูป
document.addEventListener('mouseover', e => {
  const art = e.target.closest('article.wd'); if (!art) return;
  art.querySelectorAll('.hl').forEach(x => x.classList.remove('hl'));
  const li = e.target.closest('ol.pts li');
  if (li) { li.classList.add('hl'); art.querySelector('.pt[data-i="' + li.dataset.i + '"]')?.classList.add('hl'); }
});
'''

PLAY_HTML = '''
<section id="play" aria-label="ลองวางการ์ด">
  <header class="top ptop">
    <div class="eyebrow">Star Card · ลองวางการ์ด</div>
    <h1>วาง widget แล้วดูว่า API เก็บอะไร</h1>
    <p class="lede">ลาก widget จากซ้ายลงการ์ด (หรือแตะเพื่อเพิ่ม) · ลากย้าย · ลากมุมขวาล่างเพื่อปรับขนาด · ขวามือคือสิ่งที่แอปส่งไปบันทึกจริง</p>
  </header>
  <div class="pl">
    <aside class="pal" aria-label="widget ทั้งหมด"><input id="pq" type="search" placeholder="ค้นหา widget" aria-label="ค้นหา widget"><div id="pal"></div></aside>
    <div class="boardwrap">
      <div class="bar"><span>สตอรี่ 540 × 960</span><span id="cnt"></span><button type="button" id="preset">ตัวอย่าง</button><button type="button" id="reset">ล้าง</button></div>
      <div class="board" id="board"><div class="page9" id="page9"></div></div>
      <div class="sel" id="sel"><span class="mut">แตะชิ้นบนการ์ดเพื่อดูว่าเก็บอะไร</span></div>
    </div>
    <aside class="api" aria-label="API">
      <div class="ptabs" role="tablist"><button type="button" class="on" data-p="doc">doc ที่เก็บ</button><button type="button" data-p="save">บันทึก</button><button type="button" data-p="load">เปิดการ์ด</button></div>
      <div class="pp" data-p="doc"><p class="hint">เก็บแค่ <b>ตำแหน่ง · ขนาด · ตัวเลือกของชิ้น</b> — ไม่มีข้อความหรือข้อมูลเจ้าของในการ์ด</p><pre id="doc"></pre></div>
      <div class="pp" data-p="save" hidden><p class="hint">แอปบันทึกร่างอัตโนมัติหลังแก้ · <b>baseRev</b> ต้องตรงกับฉบับล่าสุด ไม่ตรง = มีคนแก้ซ้อน</p><ol id="log" class="log"></ol><pre id="mut"></pre></div>
      <div class="pp" data-p="load" hidden><p class="hint">เปิดการ์ด = โหลด doc 1 ครั้ง + query ของ<b>หมวดละ 1 ครั้ง</b> ไม่ว่าหมวดนั้นจะมีกี่ใบ</p><div id="calls"></div></div>
    </aside>
  </div>
</section>'''

PLAY_JS = r'''
// ---------- ลองวางการ์ด: การ์ดสตอรี่ 540×960 · doc = สิ่งที่แอปบันทึกจริง ----------
(() => {
  const PAGE = { w: 540, h: 960 }, M = 18, STEP = 6, MIN = 100;
  const byK = Object.fromEntries(PLAY.map(p => [p.k, p]));
  const page = document.getElementById('page9'), board = document.getElementById('board');
  const pal = document.getElementById('pal'), docEl = document.getElementById('doc'), mutEl = document.getElementById('mut');
  const logEl = document.getElementById('log'), callsEl = document.getElementById('calls'), selEl = document.getElementById('sel'), cntEl = document.getElementById('cnt');
  const uid = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => { const r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 3 | 8)).toString(16); });
  const snap = v => Math.round(v / STEP) * STEP;
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  let items = [], sel = null, rev = 1, scale = 1, saveT = null, log = [];
  const seal = () => { const p = byK.proofSeal; const w = 246, h = Math.round(w * p.dh / p.dw); return mk('proofSeal', PAGE.w - M - w, PAGE.h - M - h, w, h); };
  function mk(k, x, y, w, h) { const p = byK[k]; return Object.assign({ id: uid(), kind: k, x, y, w: w ?? p.it.w, h: h ?? p.it.h }, JSON.parse(JSON.stringify(p.it)), { w: w ?? p.it.w, h: h ?? p.it.h, x, y }); }
  function order(it) { const { id, kind, x, y, w, h, ...rest } = it; return { id, kind, x, y, w, h, ...rest }; }
  function save() { try { localStorage.setItem('sc-play-v1', JSON.stringify({ items, rev })); } catch (e) {} }
  function load() { try { const s = JSON.parse(localStorage.getItem('sc-play-v1')); if (s && s.items) { items = s.items.filter(i => byK[i.kind]); rev = s.rev || 1; return true; } } catch (e) {} return false; }
  function preset() {
    items = [mk('heroMinimal', 18, 18, 504, null), mk('statPoster', 18, 0), mk('kitRate', 18, 0), seal()];
    items[1].y = items[0].y + items[0].h + 10; items[2].y = items[1].y + items[1].h + 10; items[2].w = 246; items[2].h = Math.round(246 * byK.kitRate.dh / byK.kitRate.dw);
    items[0].h = Math.round(504 * byK.heroMinimal.dh / byK.heroMinimal.dw);
    items[1].y = items[0].y + items[0].h + 10; items[2].y = items[1].y + items[1].h + 10;
  }
  // ---- จานซ้าย
  function paletteHTML(q) {
    const g = {}; PLAY.filter(p => !p.pin && (!q || (p.t + p.k + p.cl).toLowerCase().includes(q))).forEach(p => (g[p.c] ??= []).push(p));
    return Object.values(g).map(ps => `<div class="pg" data-g="${ps[0].g}"><b>${ps[0].cl}</b>` + ps.map(p => `<div class="pw" data-k="${p.k}" title="${p.k}"><img src="${IMG[p.k] || ''}" alt=""><span>${p.t}</span></div>`).join('') + '</div>').join('');
  }
  pal.innerHTML = paletteHTML('');
  document.getElementById('pq').addEventListener('input', e => { pal.innerHTML = paletteHTML(e.target.value.trim().toLowerCase()); });
  // ---- วาด
  function fitScale() { const avail = board.clientWidth - 28; scale = Math.min(1, avail / PAGE.w, (window.innerHeight - 200) / PAGE.h); scale = Math.max(scale, .3);
    page.style.transform = `scale(${scale})`; page.parentElement.style.height = (PAGE.h * scale + 28) + 'px'; page.style.marginRight = (PAGE.w * scale - PAGE.w) + 'px'; page.style.marginBottom = (PAGE.h * scale - PAGE.h) + 'px'; }
  function imgBox(it) { const p = byK[it.kind], k = Math.min(it.w / p.dw, it.h / p.dh); const W = (p.dw + 24) * k, H = (p.dh + 24) * k;
    return `left:${(it.w - p.dw * k) / 2 - 12 * k}px;top:${(it.h - p.dh * k) / 2 - 12 * k}px;width:${W}px;height:${H}px`; }
  function render() {
    page.innerHTML = items.map((it, i) => `<div class="it${it.id === sel ? ' sel' : ''}${it.pinned || it.options?.pinned ? ' pin' : ''}" data-id="${it.id}" style="left:${it.x}px;top:${it.y}px;width:${it.w}px;height:${it.h}px;z-index:${i + 1}">
      <div class="im"><img src="${IMG[it.kind] || ''}" style="${imgBox(it)}" alt="${it.kind}"></div><span class="rs" data-rs="1"></span></div>`).join('');
    cntEl.textContent = items.length + ' ชิ้น';
    renderSel(); renderDoc(); renderCalls();
  }
  function docObj() { return { schemaVersion: 1, format: 'story', name: 'การ์ดของฉัน', theme: { palette: 'midnight', ink: 'night', backdrop: 'solid', corner: 'round' }, pages: [{ items: items.map(order) }] }; }
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
  function hl(s) { return esc(s).replace(/("[^"]*")(\s*:)/g, '<span class="jk">$1</span>$2').replace(/(:\s*)("[^"]*")/g, '$1<span class="js">$2</span>').replace(/(:\s*)(-?\d+(?:\.\d+)?|true|false|null)/g, '$1<span class="jn">$2</span>'); }
  function renderDoc() {
    const d = docObj(); const parts = JSON.stringify({ ...d, pages: [{ items: '§' }] }, null, 2).split('"§"');
    const its = d.pages[0].items.map(it => { const t = JSON.stringify(it, null, 2).replace(/\n/g, '\n        '); return it.id === sel ? `<span class="isel">        ${hl(t)}</span>` : '        ' + hl(t); });
    docEl.innerHTML = hl(parts[0]) + '[\n' + its.join(',\n') + '\n      ]' + hl(parts[1]);
  }
  function renderSel() {
    const it = items.find(i => i.id === sel);
    if (!it) { selEl.innerHTML = '<span class="mut">แตะชิ้นบนการ์ดเพื่อดูว่าเก็บอะไร</span>'; return; }
    const p = byK[it.kind], pinned = it.options?.pinned;
    selEl.innerHTML = `<b>${p.t}</b><code>${it.kind}</code><span class="mut">หมวด${p.cl} · x ${it.x} · y ${it.y} · ${it.w}×${it.h}</span>
      <a href="#w/${it.kind}">ดู widget →</a><button type="button" id="up">ขึ้นบน</button><button type="button" id="del" ${pinned ? 'disabled title="ตราที่ตรึงลบไม่ได้"' : ''}>ลบ</button>`;
    selEl.querySelector('#del').onclick = () => remove(it.id);
    selEl.querySelector('#up').onclick = () => { items = items.filter(i => i !== it).concat(it); change(`ยก ${it.kind} ขึ้นบนสุด`); };
  }
  function renderCalls() {
    const by = {}; items.forEach(it => (by[byK[it.kind].c] ??= []).push(it));
    const cats = Object.keys(by);
    callsEl.innerHTML = `<div class="call"><span class="n">1 ครั้ง</span><b>myStarCard(id: 128)</b> <span class="mut">{ draftDoc draftRev images { image { imgPath } role } }</span></div>` +
      cats.map(c => { const p = byK[by[c][0].kind]; return `<div class="call" data-g="${p.g}"><span class="n">${by[c].length} ใบ · เรียก 1 ครั้ง</span><b>${CATQ[c]}</b> <span class="mut">หมวด${p.cl}</span><div class="ws">${by[c].map(i => `<span>${i.kind}</span>`).join('')}</div></div>`; }).join('') +
      `<p class="hint">รวม <b>${cats.length + 1}</b> request สำหรับ ${items.length} ชิ้น · query ของแต่ละหมวดดูได้ในหน้า widget ช่อง ②</p>`;
  }
  function renderMut() {
    const doc = JSON.stringify(docObj());
    mutEl.innerHTML = `<span class="c"># ส่งทั้ง doc เป็นข้อความ JSON · server ตรวจแล้วเก็บ rev ใหม่</span>
mutation SaveStarCardDraft($id: Int!, $doc: String!, $baseRev: Int!) {
  <span class="jk">saveStarCardDraft</span>(id: $id, doc: $doc, baseRev: $baseRev) {
    successful  errors { path message }  entity { id draftRev }
  }
}
<span class="c"># variables</span>
` + hl(JSON.stringify({ id: 128, baseRev: rev - 1, doc: doc.length > 160 ? doc.slice(0, 157) + '…' : doc }, null, 2)) + `
<span class="c"># คำตอบ · doc ${doc.length.toLocaleString()} ตัวอักษร</span>
` + hl(JSON.stringify({ data: { saveStarCardDraft: { successful: true, errors: null, entity: { id: 128, draftRev: rev } } } }, null, 2));
    logEl.innerHTML = log.slice(-30).reverse().map(l => `<li><b>rev ${l.rev}</b><span>${l.t}</span></li>`).join('');
  }
  function change(what) {
    render(); save();
    clearTimeout(saveT);
    saveT = setTimeout(() => { rev += 1; log.push({ rev, t: what }); renderMut(); save(); docEl.classList.remove('flash'); void docEl.offsetWidth; docEl.classList.add('flash'); }, 450);
  }
  function remove(id) { const it = items.find(i => i.id === id); if (!it || it.options?.pinned) return; items = items.filter(i => i.id !== id); sel = null; change(`ลบ ${it.kind}`); }
  function free(w, h) {          // หาที่ว่างจากบนลงล่าง (สแนป 6) — ไม่เจอ = วางบนสุด
    for (let y = M; y + h <= PAGE.h - M; y += STEP) for (let x = M; x + w <= PAGE.w - M; x += STEP) {
      if (!items.some(o => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y)) return { x, y };
    } return { x: M, y: M };
  }
  function add(k, at) {
    const p = byK[k]; let w = p.it.w, h = p.it.h;
    if (w > PAGE.w - M * 2) { h = Math.round(h * (PAGE.w - M * 2) / w); w = PAGE.w - M * 2; }
    const pos = at ? { x: snap(clamp(at.x - w / 2, M, PAGE.w - M - w)), y: snap(clamp(at.y - h / 2, M, PAGE.h - M - h)) } : free(w, h);
    const it = mk(k, pos.x, pos.y, w, h); const pinIdx = items.findIndex(i => i.options?.pinned);
    pinIdx >= 0 ? items.splice(pinIdx, 0, it) : items.push(it);
    sel = it.id; change(`วาง ${k} → pages[0].items[${items.indexOf(it)}]`);
  }
  // ---- ลากจากจาน (pointer — ใช้ได้ทั้งเมาส์และนิ้ว)
  let drag = null;
  const toPage = (cx, cy) => { const r = page.getBoundingClientRect(); return { x: (cx - r.left) / scale, y: (cy - r.top) / scale, inside: cx >= r.left && cx <= r.right && cy >= r.top && cy <= r.bottom }; };
  pal.addEventListener('pointerdown', e => {
    const pw = e.target.closest('.pw'); if (!pw) return;
    drag = { k: pw.dataset.k, sx: e.clientX, sy: e.clientY, moved: false, ghost: null }; try { pw.setPointerCapture(e.pointerId); } catch (_) {}
  });
  pal.addEventListener('pointermove', e => {
    if (!drag) return;
    if (!drag.moved && Math.hypot(e.clientX - drag.sx, e.clientY - drag.sy) > 6) { drag.moved = true; drag.ghost = Object.assign(document.createElement('img'), { src: IMG[drag.k], className: 'ghost' }); document.body.appendChild(drag.ghost); }
    if (drag.ghost) { drag.ghost.style.left = e.clientX - 60 + 'px'; drag.ghost.style.top = e.clientY - 40 + 'px'; page.classList.toggle('drop', toPage(e.clientX, e.clientY).inside); }
  });
  pal.addEventListener('pointerup', e => {
    if (!drag) return; const d = drag; drag = null; d.ghost?.remove(); page.classList.remove('drop');
    if (!d.moved) { add(d.k); return; }
    const pt = toPage(e.clientX, e.clientY); if (pt.inside) add(d.k, pt);
  });
  // ---- ย้าย / ปรับขนาดบนการ์ด
  let act = null;
  page.addEventListener('pointerdown', e => {
    const el = e.target.closest('.it'); if (!el) { sel = null; render(); return; }
    const it = items.find(i => i.id === el.dataset.id); sel = it.id;
    act = { it, rs: !!e.target.dataset.rs, sx: e.clientX, sy: e.clientY, x: it.x, y: it.y, w: it.w, h: it.h, moved: false };
    try { page.setPointerCapture(e.pointerId); } catch (_) {} render();
  });
  page.addEventListener('pointermove', e => {
    if (!act) return; const dx = (e.clientX - act.sx) / scale, dy = (e.clientY - act.sy) / scale; const it = act.it, p = byK[it.kind];
    if (Math.abs(dx) + Math.abs(dy) > 2) act.moved = true;
    if (it.options?.pinned) return;
    if (act.rs) { let w = snap(clamp(act.w + dx, MIN, PAGE.w - it.x - M)); let h = p.ka ? Math.round(w * p.dh / p.dw) : snap(clamp(act.h + dy, MIN * .6, PAGE.h - it.y - M)); it.w = w; it.h = h; }
    else { it.x = snap(clamp(act.x + dx, M, PAGE.w - M - it.w)); it.y = snap(clamp(act.y + dy, M, PAGE.h - M - it.h)); }
    const el = page.querySelector(`.it[data-id="${it.id}"]`); el.style.cssText = `left:${it.x}px;top:${it.y}px;width:${it.w}px;height:${it.h}px;z-index:${items.indexOf(it) + 1}`; el.querySelector('img').style.cssText = imgBox(it);
  });
  page.addEventListener('pointerup', () => { if (!act) return; const a = act; act = null; if (a.moved && !a.it.options?.pinned) change(a.rs ? `ปรับขนาด ${a.it.kind} → ${a.it.w}×${a.it.h}` : `ย้าย ${a.it.kind} → x ${a.it.x} · y ${a.it.y}`); });
  document.addEventListener('keydown', e => { if (!document.body.classList.contains('play') || !sel || e.target.closest('input')) return; if (e.key === 'Delete' || e.key === 'Backspace') { e.preventDefault(); remove(sel); } });
  // ---- แท็บขวา
  document.querySelector('.ptabs').addEventListener('click', e => { const b = e.target.closest('button'); if (!b) return;
    document.querySelectorAll('.ptabs button').forEach(x => x.classList.toggle('on', x === b)); document.querySelectorAll('.api .pp').forEach(x => x.hidden = x.dataset.p !== b.dataset.p); });
  document.getElementById('reset').onclick = () => { items = [seal()]; sel = null; change('ล้างการ์ด (เหลือตราที่ตรึง)'); };
  document.getElementById('preset').onclick = () => { preset(); sel = null; change('ใส่การ์ดตัวอย่าง'); };
  if (!load()) preset();
  if (!items.some(i => i.options?.pinned)) items.push(seal());
  log.push({ rev, t: 'เปิดการ์ด' });
  window.addEventListener('resize', fitScale);
  window.addEventListener('play-open', () => { fitScale(); render(); renderMut(); });
  if (location.hash === '#play') { fitScale(); render(); renderMut(); }
})();
'''


# ---- แท็บ "วิธีวาด": ข้อมูลจริงของแต่ละใบ — กรอบ · คำตอบ API · API→Model · กล่องจาก SpecSolver · สี/ตัวเลือก
TOKEN_SW = {'ink': '#F3F4F6', 'plateInk': '#F6EFE6', 'plate': '#5B1A2A', 'accent': '#E85C9E', 'rawAccent': '#E85C9E', 'line': '#9AA0B4', 'soft': '#B9BED0',
            'kit.title': '#141417', 'kit.ink': '#141417', 'kit.fill': '#B57EF7', 'scrap.paper': '#F8E6EA', 'scrap.ink': '#3B1F28', 'pop.ink': '#1D1D22', 'pop.sheet': '#FFFFFF',
            'ed.ink': '#2A2522', 'ed.sheet': '#F4EFE6', 'accentPaper': '#C2185B'}
def spec_refs(spec):
    """field ของ Model → ที่ผังอ้างถึงครั้งแรก ('"slot": "$followers"')"""
    out, conds = {}, {}
    def put(d, key, attr, v):
        if key not in d: d[key] = f'"{attr}": "{v}"'
    def walk(n, L):
        if isinstance(n, list):
            for x in n: walk(x, L)
            return
        if not isinstance(n, dict): return
        if isinstance(n.get('list'), str): L = n['list']; put(out, 'list:' + L, 'list', L)
        for a_, v in n.items():
            if not isinstance(v, str) or a_ in ('list', 'notes', 'kind'): continue
            if a_ == 'if':
                for tok in re.findall(r'[\w:.]+', v):
                    if tok in ('stamped', 'cutout', 'owner.verified'): put(conds, 'flag:' + tok, 'if', v)
                    elif tok.startswith('has:'): put(conds, tok[4:] if ':' in tok[4:] else 'slot:' + tok[4:].split('#')[0], 'if', v)
                for f_ in re.findall(r'\$(\w+)', v):
                    if L and f_ not in TPL_SKIP: put(conds, f'list:{L}.{f_}', 'if', v)
                continue
            for f_ in re.findall(r'\$(\w+)', v) + re.findall(r'\{(\w+)\}', v):
                if L and f_ not in TPL_SKIP: put(out, f'list:{L}.{f_}', a_, v)
            if a_ == 'slot' and not v.startswith('$'):
                put(out, v.split('#')[0] if v.startswith(('stat:', 'count:')) else 'slot:' + v.split('#')[0], a_, v)
        for v in n.values():
            if isinstance(v, (dict, list)): walk(v, L)
    walk(spec['root'], None)
    walk([v.get('root') for v in spec.get('variants', [])], None)
    for k_, v in conds.items(): out.setdefault(k_, v)
    return out

def how(k, path):
    """วิธีที่ adapter แปลงค่า API → ค่า Model (ภาษาคน)"""
    f_ = k.split('.')[-1].split(':')[-1]
    if not path: return 'ยังไม่มีใน API'
    if k.startswith('list:') and '.' not in k: return '1 รายการ = 1 แถว'
    if k == 'flag:stamped': return 'ทุกช่อง completed → true'
    if k.startswith('flag:'): return 'ใช่/ไม่ใช่'
    if path.endswith('.type'): return 'เปิดตารางตาม type'
    if f_.endswith('Raw'): return 'ตัวเลขเดิม'
    if f_ in ('followersFull',): return 'ใส่จุลภาค'
    if f_ in ('followers', 'views', 'engagement', 'totalFollowers', 'reach', 'saves', 'shares', 'likes', 'comments'): return 'ย่อตัวเลข'
    if f_ == 'handle': return 'เติม @'
    if f_ in ('share',): return '% ปัดเศษ'
    if f_ in ('price', 'prices'): return 'ใส่ ฿ + จุลภาค'
    return 'ใช้ตามเดิม'

def render_data(spec, fixture, cm):
    kind, w = spec['kind'], spec['widget']; cat = w['category']
    prof, lists, stats, flags = analyze(spec)
    pts, _deco = annotate(spec, fixture)
    fd = (fixture or {}).get('cases', [{}])[0].get('data', {})
    seen = dict(texts={t['slot']: t['v'] for t in fd.get('texts', [])},
                lists={L: [it['fields'] for it in items] for L, items in fd.get('lists', {}).items()}, flags=dict(fd.get('flags', {})))
    used = set('slot:' + p for p in prof) | set(stats)
    for L, fs in lists.items(): used |= {'list:' + L} | {f'list:{L}.{f}' for f in fs}
    for f in flags:
        if f in ('stamped', 'cutout', 'owner.verified'): used.add('flag:' + f)
    if any(k in ('photo', 'photoRef') for k in json.dumps(spec).split('"')): used.add('photo')
    photo_slots = sorted({int(re.search(r'\d+', mk).group()) for (_b, _w, _s, mk) in pts if mk.startswith('photo(')})
    item = board_item(spec, photo_slots)
    case = (fixture or {}).get('cases', [{}])[0]
    W, H = case.get('box', [spec['design']['w'], spec['design']['h']])
    pw, ph = spec['design']['w'] + 24, spec['design']['h'] + 24
    def val(mk):
        mk = mk.split(' ')[0]
        if mk.startswith('photo('): return 'รูปช่อง ' + mk[6:-1]
        if mk == 'stamped': return 'Verified'
        if '[].' in mk:
            L, f = mk.split('[].'); it = (seen['lists'].get(L) or [{}])[0]
            return str(it.get(f, '1' if f == 'rank' else ''))
        return str(seen['texts'].get(mk, ''))
    boxes = [[round(b['x'], 1), round(b['y'], 1), round(b['w'], 1), round(b['h'], 1), b['type']] for b in case.get('boxes', [])
             if b['type'] in ('text', 'icon', 'image', 'rect', 'row', 'col', 'chips') and b['w'] > 1 and b['h'] > 1][:220]
    binds = [[round(b['x'], 1), round(b['y'], 1), round(b['w'], 1), round(b['h'], 1), what, mk, val(mk)[:24]] for (b, what, _s, mk) in pts]
    # API → Model (เฉพาะ field ที่ใบนี้ใช้)
    conv, seen_k, refs = [], set(), spec_refs(spec)
    order = lambda k: (0 if k.startswith('list:') and '.' not in k else 2 if k.startswith('list:') else 3 if k.startswith('flag:') else 1, k)
    for k in sorted(used, key=order):
        if k in DEVICE_ONLY or k in seen_k or k in LIST_SLOTS: continue
        if k not in REAL and k.startswith('slot:') and 'list:' + k[5:] in REAL:      # categories#0 = แถวของรายการ categories
            refs.setdefault('list:' + k[5:], refs.get(k, '')); k = 'list:' + k[5:]
            if k in seen_k: continue
        if k not in REAL:
            if k.startswith(('slot:', 'stat:', 'list:')) and k in refs:
                rest_ = k.partition(':')[2]
                conv.append(['', '❗', field_name(k)[1] if not k.startswith('list:') else rest_.replace('.', '[].'), example(k, seen) or '—', field_name(k)[0], how(k, ''), refs.get(k, '')])
                seen_k.add(k)
            continue
        paths = [p for p in REAL[k] if not p.endswith('.type') and not p.endswith('.seq')] or REAL[k]
        path = paths[0]; leaf = path.split('.')[-1]
        mv = example(k, seen)
        kind_, _, rest = k.partition(':')
        av = None
        if kind_ == 'list' and '.' in rest:
            L, f = rest.split('.', 1); it = (seen['lists'].get(L) or [{}])[0]
            raw = it.get(f + 'Raw') if not f.endswith('Raw') else it.get(f)
            av = raw if raw not in (None, '') else it.get(f)
            if leaf in ('percentage',) and it.get('shareRaw'): av = it.get('shareRaw')
        if kind_ == 'list' and '.' not in rest:                    # ทั้งรายการ
            items_ = seen['lists'].get(rest) or []
            av = [i.get('platform') or i.get('label') or i.get('name') or i.get('text') for i in items_][:3] or None
        elif kind_ == 'list' and path.endswith('.type'):            # ชื่อ/โลโก้/สีของช่อง = คิดจาก type
            it = (seen['lists'].get(rest.split('.')[0]) or [{}])[0]
            av = it.get('platform') or 'instagram'
            if not mv: mv = 'ตาม ' + str(av)
        if av in (None, ''): av = mv if mv else ex_leaf(leaf, 0, path.split('.')[-2] if '.' in path else '')
        if k == 'photo': av = 'https://img.salehere.co.th/…/profile.jpg'; mv = 'รูปช่อง 1–3'
        if k == 'flag:stamped': av = 'completed'; mv = mv or 'ใช่'
        elif k.startswith('flag:'): av = True; mv = mv or 'ใช่'
        try: av = int(str(av).replace(',', '')) if re.fullmatch(r'[\d,]+', str(av)) else av
        except ValueError: pass
        disp = re.sub(r'\([^)]*\)', '', path)
        ref = refs.get(k, '')
        if k == 'photo': ref = next((f'"{x}": "…"' for x in ('photo', 'photoRef') if f'"{x}"' in json.dumps(spec)), '')
        conv.append([disp, av, field_name(k)[1] if not k.startswith('list:') else rest.replace('.', '[].'), mv or '—', field_name(k)[0], how(k, path), ref])
        seen_k.add(k)
        if len(conv) >= 16: break
    # คำตอบ API เฉพาะ field ที่ใบนี้ใช้
    tree = {}
    for k in used:
        for pth in REAL.get(k, []):
            cur = tree
            for seg in pth.split('.'): cur = cur.setdefault(seg, {})
    api = fill(tree)
    def put_api(path, v):                                          # ให้ตัวอย่าง API ตรงกับค่าที่ขึ้นบนการ์ด
        node, segs = api, path.split('.')
        for j, seg in enumerate(segs):
            if isinstance(node, list): node = node[0] if node else None
            if not isinstance(node, dict) or seg not in node: return
            if j < len(segs) - 1: node = node[seg]
            elif not isinstance(node[seg], (dict, list)): node[seg] = v
    def put_list(path, vals):                                      # type ของทุกช่อง (instagram, tiktok…)
        segs = path.split('.'); node = api
        for seg in segs[:-1]:
            node = node.get(seg) if isinstance(node, dict) else None
            if isinstance(node, list): break
        if isinstance(node, list):
            for x, it_ in zip(vals, node):
                if isinstance(it_, dict) and segs[-1] in it_: it_[segs[-1]] = x
    for c in conv:
        if not c[0] or c[1] == '❗': continue
        if isinstance(c[1], list): put_list(c[0], c[1])
        elif not isinstance(c[1], str) or not c[1].startswith(('ตาม', 'รูป', 'https')): put_api(c[0], c[1])
    # สี (token ของธีม) ที่ผังอ้าง
    toks = []
    def walk(n):
        if isinstance(n, list): [walk(x) for x in n]; return
        if not isinstance(n, dict): return
        for key in ('color', 'fill', 'tint'):
            v = n.get(key)
            if isinstance(v, str) and not v.startswith('#') and not v.startswith('$'):
                t = v.split('@')[0]
                if t and t not in toks: toks.append(t)
        for v in n.values():
            if isinstance(v, (dict, list)): walk(v)
    walk(spec['root'])
    return dict(k=kind, t=w['title'], c=cat, cl=LABEL[cat], g=GROUP_KEY[cat], q='StarCard' + cat[0].upper() + cat[1:] + 'Model',
                item=item, dw=spec['design']['w'], dh=spec['design']['h'], W=W, H=H, pw=pw, ph=ph, ox=(pw - W) / 2, oy=(ph - H) / 2,
                boxes=boxes, binds=binds, conv=conv, api=api, toks=[[t, TOKEN_SW.get(t, '#8A8F9E')] for t in toks[:8]], ka=bool(w.get('keepAspect')))

RENDER_HTML = '''
<section id="render" aria-label="วิธีวาด">
  <header class="top ptop">
    <div class="eyebrow">Star Card · วิธีวาด</div>
    <h1>จากข้อมูลถึงภาพ ทีละขั้น</h1>
    <p class="lede">กด “ถัดไป” แล้วดูการ์ดด้านซ้าย — แต่ละขั้นเพิ่มของลงบน Star Card ทีละชั้น · ขั้นที่มีป้าย <span class="mg">merge</span> คือจุดที่ข้อมูลสองแหล่งมารวมกัน</p>
  </header>
  <div class="rp">
    <div class="rstage"><div class="rpick"><label for="rk">widget</label><select id="rk"></select></div><div id="rcard" class="sc"></div><p id="rcap" class="rcap"></p></div>
    <div class="rsteps"><ol id="rlist" class="rlist"></ol>
      <div class="rnav"><button type="button" id="rprev">◀ ก่อนหน้า</button><button type="button" id="rnext" class="pri">ถัดไป ▶</button></div></div>
  </div>
  <div class="rmap">
    <h2>Map field ยังไง</h2>
    <p class="lede">ทั้ง 3 ชั้นคุยกันด้วย <b>ชื่อ field ของ Model</b> (<code>shared/category-models.json</code>) · adapter แปลง API → ชื่อกลาง · ผังของ widget อ้างแค่ชื่อกลาง ไม่เคยเห็นชื่อ API</p>
    <div class="mh"><span><i>①</i>คำตอบ API <small>salehere-ios</small></span><span></span><span class="key"><i>②</i>Model <small>ชื่อกลาง</small></span><span></span><span><i>③</i>JSON ของ widget <small id="rmk"></small></span></div>
    <div id="rmap"></div>
    <p class="rnote">API เปลี่ยนชื่อ field → แก้แค่ adapter (คอลัมน์ ① → ②) · ผัง ③ และตัววาดไม่ต้องแก้ · ถ้าให้ backend ส่งชื่อ ② มาเลย แอปไม่ต้องแปลงอีก</p>
  </div>
</section>'''

RENDER_JS = r'''
// ---------- วิธีวาด: Star Card ที่ประกอบทีละขั้น (กดเปลี่ยนขั้น = เพิ่ม/ถอดชั้นบนการ์ด) ----------
(() => {
  const card = document.getElementById('rcard'), cap = document.getElementById('rcap'), list = document.getElementById('rlist'), pick = document.getElementById('rk'), stage = card.parentElement;
  const STEPS = [
    { t: 'วางบนหน้า', e: 'PageLayout.solve', in: 'items[] ของการ์ด (x y w h)', out: 'กรอบจริงของชิ้นบนหน้า', d: 'อ่านกรอบจาก doc แล้ววางบนหน้า ถ้าทับกันจะดันลงจนไม่ทับ', add: 'กรอบของชิ้นบนการ์ด' },
    { t: 'ขอข้อมูลของหมวด', e: 'API · myProfile', in: 'query ของหมวด (1 ครั้ง / หมวด)', out: 'คำตอบดิบจาก salehere-ios', d: 'ทุก widget ในหมวดเดียวกันใช้คำตอบก้อนเดียวกัน — ตัวเลขยังเป็นตัวเลขดิบ', add: 'ค่าดิบจาก API (สีน้ำเงิน)' },
    { t: 'แปลงเป็น Model', e: 'SpecDataSource', m: 'API + ค่าที่ระบบคิด', in: 'คำตอบดิบ', out: 'Model ของหมวด (ข้อความพร้อมวาด)', d: 'จัดรูปตัวเลข (24800 → 24.8K) · เปิดตารางชื่อ/โลโก้ตาม type · ช่องว่างเป็นข้อความว่าง', add: 'ค่าดิบพลิกเป็นค่า Model (สีเหลือง)' },
    { t: 'ย่อ/ขยายทั้งก้อน', e: 'WidgetChrome', in: 'กรอบ w×h · ผังออกแบบ dw×dh', out: 'ตัวคูณ k', d: 'ผังออกแบบไว้ที่ขนาดเดียว — ตัววาดคิดในหน่วยออกแบบแล้วคูณ k ทั้งก้อน', add: 'ผังขนาดออกแบบ หดลงให้พอดีกรอบ' },
    { t: 'จัดกล่อง', e: 'SpecSolver', m: 'ผัง JSON × Model', in: 'ผัง (shared/WidgetSpecs) + Model', out: 'กล่องทุกชิ้น + ข้อความที่วัดแล้ว', d: 'slot / $field ในผังถูกแทนด้วยค่าจาก Model · รายการปั๊มแม่พิมพ์ตามจำนวน · วัดตัวอักษร ย่อ ตัดบรรทัด', add: 'โครงกล่องของผัง ค่า Model ลงช่องของมัน' },
    { t: 'ทาสี', e: 'SpecPainter', m: 'กล่อง × ธีม × ตัวเลือกของชิ้น', in: 'กล่อง + ธีมการ์ด + surface/border/options', out: 'ภาพของ widget', d: 'token สีในผัง (ink · accent · plate) อ่านจากธีมของการ์ด · ตัวเลือกของชิ้นสลับกิ่งของผัง', add: 'สีและภาพจริงทับโครงกล่อง' },
    { t: 'อยู่บนการ์ด', e: 'CardScreen · export', in: 'ภาพของทุกชิ้น', out: 'การ์ด / PNG', d: 'วางภาพในกรอบจริง · ตราที่ตรึงอยู่ล่างขวาเสมอ', add: 'เส้นช่วยหายไป เหลือการ์ดจริง → PNG' },
  ];
  let k = 'statPoster', step = 0;
  const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');
  const hl = s => esc(s).replace(/("[^"]*")(\s*:)/g, '<span class="jk">$1</span>$2').replace(/(:\s*)("[^"]*")/g, '$1<span class="js">$2</span>').replace(/(:\s*)(-?\d+(?:\.\d+)?|true|false|null)/g, '$1<span class="jn">$2</span>');
  const groups = {}; Object.values(RD).forEach(r => (groups[r.cl] ??= []).push(r));
  pick.innerHTML = Object.entries(groups).map(([g, rs]) => `<optgroup label="${g}">` + rs.map(r => `<option value="${r.k}">${r.t} · ${r.k}</option>`).join('') + '</optgroup>').join('');
  pick.value = k; pick.onchange = () => { k = pick.value; build(); };
  const fit = () => { const w = stage.clientWidth - 28, h = innerWidth > 900 ? innerHeight - 200 : 1e4; card.style.setProperty('--s', Math.max(.36, Math.min(.72, w / 540, h / 960)).toFixed(3)); };
  addEventListener('resize', fit);
  new ResizeObserver(fit).observe(stage);
  // ค่าดิบของ API ที่ตรงกับช่องข้อมูล (bind) นั้น
  function rawOf(r, field) {
    const c = r.conv.find(c => c[2] === field);
    if (!c) return null; if (!c[0]) return '❗ ไม่มีใน API';
    const v = Array.isArray(c[1]) ? c[1][0] : c[1]; return typeof v === 'string' ? `"${v}"` : String(v);
  }
  const short = s => { s = String(s); return s.length > 16 ? s.slice(0, 15) + '…' : s; };
  // ตัวอย่าง: ผู้ใช้ลากย่อชิ้นลงเหลือ ~82% (snap 6) เพื่อให้ขั้น “ย่อ/ขยาย” มีให้เห็น
  const demo = r => { const w = Math.max(60, Math.round(r.item.w * .82 / 6) * 6); return { ...r.item, w, h: Math.round(w * r.item.h / r.item.w) }; };
  // วาดการ์ด (ทุกชั้นอยู่ครบ — ขั้นเป็นตัวเปิด/ปิดชั้นด้วย class)
  function build() {
    const r = RD[k], it = demo(r), kk = Math.min(it.w / r.W, it.h / r.H), offX = (it.w - r.W * kk) / 2, offY = (it.h - r.H * kk) / 2;
    const P = (x, y, w, h) => `left:${x}px;top:${y}px;width:${w}px;height:${h}px`;
    const imgBox = P(offX - r.ox * kk, offY - r.oy * kk, r.pw * kk, r.ph * kk);
    const sp = RD.proofSeal, sw = 246, sh = Math.round(sw * sp.dh / sp.dw), sx = 540 - 18 - sw, sy = 960 - 18 - sh, sk = Math.min(sw / sp.W, sh / sp.H);
    const seal = k === 'proofSeal' ? '' : `<div class="ly seal" style="${P(sx, sy, sw, sh)}"><img src="${IMG.proofSeal}" style="${P((sw - sp.W * sk) / 2 - sp.ox * sk, (sh - sp.H * sk) / 2 - sp.oy * sk, sp.pw * sk, sp.ph * sk)}" alt=""></div>`;
    const n = r.boxes.length, per = Math.min(12, 700 / Math.max(n, 1));
    const wire = `<svg class="ly wire" style="${imgBox}" viewBox="${-r.ox} ${-r.oy} ${r.pw} ${r.ph}">` + r.boxes.map((b, i) => `<rect class="${['row', 'col', 'chips'].includes(b[4]) ? 'lay' : b[4] === 'rect' ? 'bg' : 'cnt'}" style="--d:${Math.round(i * per)}ms" x="${b[0]}" y="${b[1]}" width="${b[2]}" height="${b[3]}" rx="2"/>`).join('')
      + r.binds.map((b, i) => `<rect class="bo" style="--d:${Math.round(n * per + i * 160)}ms" x="${b[0]}" y="${b[1]}" width="${b[2]}" height="${b[3]}" rx="3"/>`).join('') + '</svg>';
    const chips = r.binds.map((b, i) => { const raw = rawOf(r, b[5]) ?? short(b[6] || '—'); const mv = /icon$/.test(b[5]) ? 'โลโก้ ' + (b[6] || '').replace(/^about-social-/, '') : (b[6] || '—');
      return `<span class="ly chip" style="--d:${i * 140}ms;left:${offX + (b[0] + b[2] / 2) * kk}px;top:${offY + (b[1] + b[3] / 2) * kk}px"><span class="a">${esc(short(raw))}</span><span class="m">${esc(short(mv))}</span></span>`; }).join('');
    const gw = r.W, gh = r.H;
    card.innerHTML = `<div class="scin"><span class="lab">ST★R Card · 540 × 960</span>${seal}
      <div class="ly frame" style="${P(it.x, it.y, it.w, it.h)}">
        <div class="ly wimg" style="${P(0, 0, it.w, it.h)}"><img src="${IMG[r.k]}" style="${imgBox}" alt=""></div>
        ${wire}
        <div class="ly ghost" style="left:0;top:0;width:${gw}px;height:${gh}px;--gw:${gw}px;--gh:${gh}px;--fw:${r.W * kk}px;--fh:${r.H * kk}px;--fx:${offX}px;--fy:${offY}px"><span>ผังออกแบบ ${r.W}×${r.H} → k ${kk.toFixed(2)}</span></div>
        ${chips}
        <span class="ly tag api">API</span><span class="ly tag mod">Model</span>
      </div>
      <span class="ly pos" style="left:${it.x}px;top:${Math.max(4, it.y - 34)}px">x ${it.x} · y ${it.y} · ${it.w}×${it.h}</span>
      <span class="ly png">การ์ด → PNG</span></div>`;
    fit(); card.className = 'sc'; void card.offsetWidth; apply();
  }
  function apply() {
    card.className = 'sc ' + STEPS.map((_, i) => i <= step ? 'r' + i : '').join(' ') + ' c' + step;
    const g = card.querySelector('.ghost');                         // ผังขนาดออกแบบ → หดเท่ากรอบ (เล่นตอนเข้าขั้น 4)
    if (g) { const st = g.style; const toFit = () => { st.left = st.getPropertyValue('--fx'); st.top = st.getPropertyValue('--fy'); st.width = st.getPropertyValue('--fw'); st.height = st.getPropertyValue('--fh'); };
      st.left = '0px'; st.top = '0px'; st.width = st.getPropertyValue('--gw'); st.height = st.getPropertyValue('--gh');
      if (step >= 3) { void g.offsetWidth; toFit(); } }
    const s = STEPS[step]; cap.innerHTML = `${s.m ? '<span class="mg">merge</span>' : ''}ขั้น ${step + 1} เพิ่ม: <b>${s.add}</b>`;
    steps();
  }
  function detail(r) {
    if (step === 0) return `<pre>${hl(JSON.stringify(demo(r), null, 2))}</pre>`;
    if (step === 1) return `<div class="cap"><b>${r.q}</b> · ตัดเฉพาะ field ที่ ${r.k} ใช้</div><pre>${hl(JSON.stringify({ data: { myProfile: r.api } }, null, 2))}</pre>`;
    if (step === 2) return '<div class="conv">' + (r.conv.length ? r.conv.map(c => `<div class="cr"><div>${c[0] ? `<code>${esc(c[0])}</code><b>${esc(JSON.stringify(c[1]))}</b>` : '<code>ยังไม่มีใน API</code><b>❗</b>'}</div><span class="ar">→</span><div><code>${esc(c[2])}</code><b>${esc(c[3])}</b></div></div>`).join('') : '<p class="mut">ใบนี้ไม่ใช้ข้อมูลเจ้าของ</p>') + '</div>';
    if (step === 3) { const it = demo(r), kk = Math.min(it.w / r.W, it.h / r.H).toFixed(2); return `<p class="fx">k = min(${it.w} ÷ ${r.W}, ${it.h} ÷ ${r.H}) = <b>${kk}</b> — ทุกกล่องและตัวอักษรคูณ ${kk} พร้อมกัน${r.ka ? ' · ใบนี้ล็อกสัดส่วน' : ''}</p>`; }
    if (step === 4) return `<ol class="bl">${r.binds.map((b, i) => `<li><span class="num">${i + 1}</span><b>${esc(b[4])}</b><code>${esc(b[5])}</code><i>${esc(b[6]) || '—'}</i></li>`).join('') || '<li class="mut">ไม่มีช่องข้อมูล — ป้ายตายตัวล้วน</li>'}</ol>`;
    if (step === 5) return `<div class="tk"><div class="cap">สีจากธีมการ์ด</div>${r.toks.map(t => `<span><i style="background:${t[1]}"></i>${esc(t[0])}</span>`).join('') || '<span class="mut">ใช้สีตายตัวของดีไซน์</span>'}<div class="cap">ตัวเลือกของชิ้น</div><pre>${hl(JSON.stringify(Object.fromEntries(['surface', 'border', 'options'].filter(x => x in r.item).map(x => [x, r.item[x]])), null, 2))}</pre></div>`;
    const it = demo(r); return `<p class="mut">ภาพของ ${r.k} วางลงกรอบ x ${it.x} · y ${it.y} · ${it.w}×${it.h} · export = ภาพทั้งหน้าเป็น PNG</p>`;
  }
  function steps() {
    const r = RD[k];
    list.innerHTML = STEPS.map((s, i) => `<li class="${i === step ? 'on' : ''}${i < step ? ' done' : ''}${s.m ? ' merge' : ''}" data-i="${i}"><span class="sn">${i < step ? '✓' : i + 1}</span><div><b>${s.t}</b>${s.m ? '<span class="mg">merge</span>' : ''}<code>${s.e}</code>` +
      (i === step ? `<p>${s.d}</p><dl><dt>เข้า</dt><dd>${s.in}</dd>${s.m ? `<dt>รวม</dt><dd class="mm">${s.m}</dd>` : ''}<dt>ออก</dt><dd>${s.out}</dd></dl><div class="rdet">${detail(r)}</div>` : '') + '</div></li>').join('');
    document.getElementById('rprev').disabled = step === 0; document.getElementById('rnext').disabled = step === STEPS.length - 1;
    document.getElementById('rmk').textContent = 'shared/WidgetSpecs/' + r.k + '.json';
    document.getElementById('rmap').innerHTML = r.conv.map(c => `<div class="mr${c[0] ? '' : ' miss'}">
      <div class="c1">${c[0] ? `<code>${esc(c[0])}</code><b>${esc(JSON.stringify(c[1]))}</b>` : '<b class="no">❗ ยังไม่มีใน API</b><code>ตอนนี้ใช้ค่าตัวอย่าง</code>'}</div>
      <div class="hw"><span>${esc(c[5] || '')}</span><i>→</i></div>
      <div class="c2"><code>${esc(c[2])}</code><b>${esc(c[3])}</b><small>${esc(c[4])}</small></div>
      <div class="hw"><span>อ้างด้วยชื่อ</span><i>→</i></div>
      <div class="c3">${c[6] ? `<code>${esc(c[6])}</code>` : '<span class="mut">ไม่อ้างตรง ๆ (ใช้คิดค่าอื่น)</span>'}</div></div>`).join('') || '<p class="mut">ใบนี้ไม่ใช้ข้อมูลเจ้าของ — มีแต่ป้ายตายตัว</p>';
  }
  const go = i => { if (i < 0 || i >= STEPS.length || i === step) return; step = i; apply(); };
  list.addEventListener('click', e => { const li = e.target.closest('li'); if (li) go(+li.dataset.i); });
  document.getElementById('rprev').onclick = () => go(step - 1);
  document.getElementById('rnext').onclick = () => go(step + 1);
  document.addEventListener('keydown', e => { if (!document.body.classList.contains('render') || e.target.closest('select')) return; if (e.key === 'ArrowRight') go(step + 1); if (e.key === 'ArrowLeft') go(step - 1); });
  let built = false; const open = () => { if (!built) { built = true; build(); } else fit(); };
  window.addEventListener('render-open', open);
  if (location.hash === '#render') open();
})();
'''

def main():
    specs = [json.load(open(f)) for f in sorted(glob.glob(os.path.join(SPECS, '*.json')))]
    cm = json.load(open(os.path.join(ROOT, 'shared/category-models.json')))
    SAMPLE.update(load_sample())
    bycat = collections.defaultdict(list)
    for s in specs: bycat[s['widget']['category']].append(s)
    for c in bycat: bycat[c].sort(key=lambda s: (s['widget'].get('order', 10**9), s['kind']))
    cats = [c for c in ORDER if bycat.get(c)]
    groups = collections.OrderedDict((g, []) for g in ('เกี่ยวกับฉัน', 'รับงาน', 'ผลงาน'))
    for c in cats: groups[GROUP[c]].append(c)
    imgs, index, details, nav, play, rdat = {}, [], [], [], [], {}
    for g, cs in groups.items():
        gk = GROUP_KEY[cs[0]]
        nav.append(f'<div class="ng g-{gk}"><span>{g}</span>' + ''.join(f'<a href="#cat-{c}">{LABEL[c]}<small>{len(bycat[c])}</small></a>' for c in cs) + '</div>')
        index.append(f'<div class="grp g-{gk}"><div class="gh">ตู้ “{g}”</div>')
        for c in cs:
            items = bycat[c]; kinds = [s['kind'] for s in items]
            cards = []
            for s in items:
                k, w = s['kind'], s['widget']
                imgs[k] = img_data(k)
                fx = os.path.join(FIX, k + '.json')
                fixture = json.load(open(fx)) if os.path.exists(fx) else None
                details.append(detail(s, fixture, kinds, cm))
                ps = sorted({int(re.search(r'\d+', mk).group()) for (_b, _w, _s, mk) in annotate(s, fixture)[0] if mk.startswith('photo(')})
                it = board_item(s, ps); [it.pop(x) for x in ('id', 'x', 'y')]
                rdat[k] = render_data(s, fixture, cm)
                play.append(dict(k=k, t=w['title'], c=c, cl=LABEL[c], g=GROUP_KEY[c], dw=s['design']['w'], dh=s['design']['h'],
                                 own=bool(w.get('ownSurface')), ka=bool(w.get('keepAspect')), pin=bool(w.get('pinned')), it=it))
                cards.append(f'<a class="card" href="#w/{k}"><span class="th"><img data-k="{k}" alt=""></span><b>{esc(w["title"])}</b><code>{k}</code></a>')
            meta = [TIER_TH[TIER.get(c, 'personal')]] + ([f'ล็อกจนกรอก{LOCK[c]}'] if LOCK.get(c) else [])
            index.append(f'<section class="cat" id="cat-{c}"><div class="ch"><h2>{LABEL[c]}</h2><code>{c}</code><span class="n">{len(items)} widget</span>'
                         f'<span class="cm">{" · ".join(meta)}</span></div><div class="cards">{"".join(cards)}</div></section>')
        index.append('</div>')
    page = f'''<!doctype html>
<html lang="th">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Star Card Widget Catalog</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anuphan:wght@500;600;700&family=IBM+Plex+Sans+Thai:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>{CSS}</style>
<nav class="tabs" aria-label="หน้า"><a href="#" data-tab="cat">Widget ทั้งหมด</a><a href="#play" data-tab="play">ลองวางการ์ด <small>ดูว่า API เก็บยังไง</small></a><a href="#render" data-tab="render">วิธีวาด <small>ข้อมูล merge ตรงไหน</small></a></nav>
<div class="page">
<div id="home">
  <header class="top">
    <div class="eyebrow">Star Card · Widget Catalog</div>
    <h1>Widget ทั้งหมด</h1>
    <p class="lede">{len(specs)} widget · {len(cats)} หมวด · แตะ widget เพื่อดูว่าใช้ข้อมูลอะไร มาจากไหน</p>
  </header>
  <nav class="cats" aria-label="ไปยังหมวด">{"".join(nav)}</nav>
  {"".join(index)}
</div>
{"".join(details)}
{PLAY_HTML}
{RENDER_HTML}
</div>
<script>
const IMG = {json.dumps(imgs)};
const PLAY = {json.dumps(play, ensure_ascii=False)};
const RD = {json.dumps(rdat, ensure_ascii=False)};
const CATQ = {json.dumps({c: 'StarCard' + c[0].upper() + c[1:] + 'Model' for c in cats})};
{JS}
{PLAY_JS}
{RENDER_JS}
</script>
'''
    open(OUT, 'w', encoding='utf-8').write(page)
    print('wrote', os.path.relpath(OUT, ROOT), f'{os.path.getsize(OUT)//1024} KB · {len(specs)} widget · {len(cats)} หมวด')

main()
