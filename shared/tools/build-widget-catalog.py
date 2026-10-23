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
# ---- ชิปในตู้ของ iOS (= `TrayGroup` ใน WidgetModel.swift) — ลำดับ + ชื่อ ตรงกับแอป 1:1 · หมวด (WidgetFamily) → ชิป = `WidgetFamily.trayGroup`
TRAY = [('profile', 'โปรไฟล์'), ('channels', 'ช่องทาง'), ('niche', 'สายที่ใช่'), ('intro', 'แนะนำตัว'), ('body', 'สัดส่วน'), ('rate', 'เรทรับงาน'),
        ('schedule', 'วันเวลา·พื้นที่'), ('audience', 'ข้อมูลผู้ติดตาม'), ('verify', 'ยืนยันตัวตน'), ('work', 'ผลงาน'), ('contact', 'ติดต่อ'), ('decor', 'ข้อความ')]
TRAY_OF = dict(hero='profile', followers='channels', tags='niche', intro='intro', body='body', rate='rate', availability='schedule', audience='audience',
               seal='verify', photo='work', showcase='work', brand='work', verified='work', contact='contact', text='decor')
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

# ---- token สี (WIDGET-SPEC.md §4): ผังเขียนแค่บทบาท 6 ชื่อ · สีจริง = บทบาท × พื้นที่ใบนั่ง (`widget.on` / โหนด `on`: card · light · dark) × ธีมการ์ด
SURF_TH = {
    'card': ('นั่งบนการ์ด', 'ไม่มีแผ่นของตัวเอง — หมึกผ่านตัวยันความอ่านออกของธีม (InkStyle) · สีเน้น = cardAccent'),
    'light': ('แผ่นสว่าง', 'กระดาษ/กล่องสว่างของใบ — กระดาษครีมอมเฉดของธีม · คู่สี = สีอ่อนของคู่ (หมึก = สีเข้ม)'),
    'dark': ('แผ่นเข้ม', 'แผ่นอิ่มสีของใบ (PosterPlate) — เฉดจากสีการ์ด · คู่สี = สีเข้มของคู่ (หมึก = สีอ่อน)'),
}
ROLE_TH = {'bg': 'พื้นของที่ที่ใบ/โหนดนั่ง', 'bg2': 'พื้นชั้นสอง — กล่องย่อย ชิป แถบหัว', 'ink': 'ตัวหนังสือ', 'ink2': 'หมึกจาง — ป้าย ตัวรอง ตัวอักษรฉากหลัง',
           'accent': 'สีเน้นของการ์ด ปรับให้เข้ากับพื้นนั้นแล้ว', 'line': 'เส้นขอบ เส้นคั่น'}
# สูตรของแต่ละบทบาทบนแต่ละพื้น (= SpecPalette.swift `card` / `sheet(_:light:)` · SpecPalette.kt · specPalette() ใน theme.js)
FORMULA = {
    'card': {'bg': 'ขาว (หมึกมืด) · ถ่าน 8% (หมึกสว่าง)', 'bg2': 'หมึกจาง 14% (InkStyle.fill)', 'ink': 'หมึกของการ์ด (InkStyle.text · ค่าตั้งต้น 100%)',
             'ink2': 'หมึกจาง 50% (InkStyle.ghost)', 'accent': 'สีเน้นของธีมที่ปรับอ่านออกบนการ์ดแล้ว (cardAccent)', 'line': 'เส้นหมึก 12% (InkStyle.line)'},
    'light': {'bg': 'กระดาษครีมอมเฉด hsb(hue การ์ด, .10, .97) · คู่สี = สีอ่อน (+7% เข้าหาสีเข้มเมื่อพลิก)', 'bg2': 'กระดาษผสมหมึก 6%',
              'ink': 'ถ่านอมเฉด hsb(hue, .06, .11) · คู่สี = สีเข้ม', 'ink2': 'หมึกผสมกระดาษ 38%',
              'accent': 'สีเน้นดิบปรับลงบนพื้นสว่าง (onLightSurface) · คู่สี = สีเข้ม', 'line': 'หมึก 20%'},
    'dark': {'bg': 'แผ่นอิ่มสี PosterPlate.plate hsb(hue, .60, .255) · คู่สี = สีเข้ม', 'bg2': 'แผ่นผสมครีม 6%',
             'ink': 'ครีมอมเฉด PosterPlate.cream hsb(hue, .085, .95) · คู่สี = สีอ่อน', 'ink2': 'ครีมผสมแผ่น 38%',
             'accent': 'สีเน้นดิบของธีม (rawAccent) · คู่สี = สีอ่อน', 'line': 'ครีม 20%'},
}
# สีจริงของทุกคู่ (พื้น, token) ใต้ธีมตั้งต้นของตัวส่งออก — คิดด้วย specPalette ของเว็บ (ตัวเดียวกับที่วาดใบ) · เติมใน main()
PAL = {}

def load_presets():
    """พาเลตต์/คู่สีสำเร็จรูปของถาด (hex) จาก sync-server/web/js/theme.js — ปุ่มลัดในแท็บ "ลองวางการ์ด" (doc เก็บแค่ hex)"""
    node = node_bin()
    if not node: return {}
    js = """import { PRESETS, DUO_PRESETS, DEFAULT_PRIMARY } from %s;
console.log(JSON.stringify({ palettes: PRESETS, duos: DUO_PRESETS, defaultPrimary: DEFAULT_PRIMARY }));""" % json.dumps(os.path.join(ROOT, 'sync-server/web/js/theme.js'))
    try:
        with tempfile.TemporaryDirectory() as td:
            f = os.path.join(td, 'presets.mjs'); open(f, 'w').write(js)
            r = subprocess.run([node, f], capture_output=True, text=True, timeout=60)
            return json.loads(r.stdout)
    except Exception:
        return {}

def default_surface(w):
    """พื้นผิวตั้งต้นของชิ้น (= `WidgetKind.defaultSurface`): `widget.surfaces[0]` · ไม่ระบุ = glass"""
    return (w.get('surfaces') or ['glass'])[0]

def load_palette(pairs):
    """[(itemSurface, base, on, token)] → {'itemSurface|base|on|token': 'rgba(...)'} จาก theme.js ใต้ธีม WidgetMatrixExport.baseTheme
    on = '' คือโหนดที่ไม่ได้ระบุ `on` (ใช้พื้นตั้งต้นของใบ — และตกเป็น card เมื่อชิ้นไม่ได้วาดแผ่น: กติกา noSheet ใน WIDGET-SPEC §4)"""
    node = node_bin()
    if not node or not pairs: return {}
    js = """import { makeTheme, specPalette, css } from %s;
const pairs = %s;
const t = makeTheme({ colors: { primary: '#1A1F35' }, ink: 'night', backdrop: 'solid' });
const pals = {};
const out = {};
for (const [itemSurface, base, on, tok] of pairs) {
  const key = itemSurface + '|' + base;
  pals[key] ??= specPalette({ t, ink: t.inkStyle, accent: t.accent, surface: itemSurface, skin: null, kit: {}, border: false, base });
  out[itemSurface + '|' + base + '|' + on + '|' + tok] = css(pals[key].color(tok, on || null));
}
console.log(JSON.stringify(out));""" % (json.dumps(os.path.join(ROOT, 'sync-server/web/js/theme.js')), json.dumps(sorted(pairs)))
    try:
        with tempfile.TemporaryDirectory() as td:
            f = os.path.join(td, 'pal.mjs'); open(f, 'w').write(js)
            r = subprocess.run([node, f], capture_output=True, text=True, timeout=60)
            return json.loads(r.stdout)
    except Exception:
        return {}

COLOR_KEYS = ('fill', 'stroke', 'color', 'tint', 'color2', 'platePattern')
WHERE_TH = {'fill': 'พื้น', 'stroke': 'เส้นขอบ', 'color': 'ตัวหนังสือ', 'tint': 'ไอคอน', 'color2': 'ลายสีสอง', 'platePattern': 'ลายแผ่น',
            'shadow': 'เงา', 'gradient': 'ไล่สี', 'pattern': 'ลาย', 'fillCycle': 'พื้นวนตามรายการ'}

def colour_refs(n):
    """[(token, ที่ใช้)] ของโหนดหนึ่ง (ลำดับเดียวกับ shared/tools/color-tokens-v2.mjs)"""
    out = []
    for k in COLOR_KEYS:
        v = n.get(k)
        if isinstance(v, str): out.append((v, WHERE_TH[k]))
    st = n.get('stroke')
    if isinstance(st, dict) and isinstance(st.get('color'), str): out.append((st['color'], 'เส้นขอบ'))
    for v in (n.get('fillCycle') or []):
        if isinstance(v, str): out.append((v, 'พื้นวนตามรายการ'))
    g = n.get('gradient')
    if isinstance(g, dict):
        for k in ('from', 'to'):
            if isinstance(g.get(k), str): out.append((g[k], 'ไล่สี'))
    sh = n.get('shadow')
    if isinstance(sh, dict): out.append((sh.get('color') or 'black@0.25', 'เงา'))
    pt = n.get('pattern')
    if isinstance(pt, dict):
        for k in ('color', 'color2'):
            if isinstance(pt.get(k), str): out.append((pt[k], 'ลาย'))
    return out

def walk_nodes(n, fn):
    if isinstance(n, list):
        for x in n: walk_nodes(x, fn)
        return
    if not isinstance(n, dict): return
    if isinstance(n.get('type'), str): fn(n)
    for k, v in n.items():
        if k != 'widget' and isinstance(v, (dict, list)): walk_nodes(v, fn)

def colour_block(spec):
    """ส่วน "สี (token)" ของหน้ารายละเอียด — พื้นตั้งต้น · token ที่ใช้ต่อพื้น พร้อมสูตร · สีตรงตัว · โหนดที่นั่งคนละพื้น"""
    base = spec['widget'].get('on') or 'card'
    item_surface = default_surface(spec['widget'])
    per = collections.OrderedDict()           # (พื้น, on ที่ระบุ|'') → {token → {where → count}}
    lit, dyn, overs = collections.Counter(), collections.Counter(), collections.Counter()
    def visit(n):
        explicit = n.get('on') if n.get('on') in SURF_TH else None
        surf = explicit or (base if base in SURF_TH else 'card')
        if explicit and explicit != base: overs[explicit] += 1
        for tok, where in colour_refs(n):
            if tok.startswith('$'): dyn[tok] += 1; continue
            name = tok.split('@')[0]
            if name.startswith('#') or name in ('white', 'black', 'clear'): lit[tok] += 1; continue
            per.setdefault((surf, explicit or ''), collections.OrderedDict()).setdefault(tok, collections.Counter())[where] += 1
    walk_nodes([spec['root'], spec.get('variants') or []], visit)
    title, desc = SURF_TH.get(base, SURF_TH['card'])
    out = [f'<section class="blk tokens" data-k="{spec["kind"]}" data-base="{base}" data-surface="{item_surface}"><h3>สี (token) <small>ผังเขียนแค่บทบาท 6 ชื่อ · สีจริง = บทบาท × พื้นที่ใบนั่ง (card · light · dark) × ธีมการ์ด (WIDGET-SPEC §4) · swatch = ธีมตั้งต้นของตัวส่งออก หรือสีที่เลือกในแผง 🎨</small></h3>',
           f'<p class="surf"><b>พื้นตั้งต้นของใบ</b> <code>on: {base}</code> <span class="sname">{esc(title)}</span> <span class="mut">— {esc(desc)}</span></p>']
    order = ['bg', 'bg2', 'ink', 'ink2', 'accent', 'line']
    nosheet = f'<p class="nosheet"><b>พื้นผิวตั้งต้นของชิ้น</b> <code>{item_surface}</code> · <span class="mut">ถ้าชิ้นไม่ได้วาดแผ่นของตัวเอง (พื้นผิว clear/pane · หรือชุด Canva เลือก fill=clear) โหนดที่ไม่ได้ระบุ <code>on</code> เองจะใช้สีของ <code>card</code> แทนพื้นตั้งต้น — โหนดที่ระบุ <code>on</code> เองยังใช้พื้นนั้น (กติกา noSheet · WIDGET-SPEC §4)</span></p>'
    out.append(nosheet)
    for (surf, explicit), toks in per.items():
        st_title = SURF_TH.get(surf, SURF_TH['card'])[0]
        head = f'<h4><code>{surf}</code> {esc(st_title)}{" <small>โหนดที่ใส่ on เอง — ใช้พื้นนี้เสมอ</small>" if explicit else " <small>ตามพื้นตั้งต้นของใบ — ตกเป็น card เมื่อไม่มีแผ่น</small>"}</h4>'
        rows = []
        for tok in sorted(toks, key=lambda t: (order.index(t.split("@")[0]) if t.split("@")[0] in order else 99, t)):
            name, _, a = tok.partition('@')
            wh = ' · '.join(f'{w} ×{c}' if c > 1 else w for w, c in toks[tok].most_common())
            formula = FORMULA.get(surf, {}).get(name, '')
            if a: formula = f'{formula} · ความทึบ {a}' if surf != 'card' or name == 'accent' or name == 'bg' else f'{formula.split(" (")[0]} ที่ {a}'
            sw = PAL.get(f'{item_surface}|{base}|{explicit}|{tok}', '')
            rows.append(f'<tr><td><s class="sw" data-tok="{esc(tok)}" data-on="{explicit}" style="background:{sw}" title="{esc(sw)}"></s><code class="tk {name}">{esc(tok)}</code></td><td>{esc(ROLE_TH.get(name, ""))}</td><td>{esc(formula)}</td><td class="mut">{esc(wh)}</td></tr>')
        out.append(head + f'<div class="tw"><table class="tk"><thead><tr><th>สี · token</th><th>บทบาท</th><th>บนพื้นนี้ = </th><th>ใช้ที่</th></tr></thead><tbody>{"".join(rows)}</tbody></table></div>')
    extra = []
    if lit:
        chips = ''.join(f'<i><s style="background:{esc(t.split("@")[0] if t.split("@")[0].startswith("#") else t.split("@")[0])}"></s>{esc(t)}{f" ×{c}" if c > 1 else ""}</i>' for t, c in lit.most_common())
        extra.append(f'<p><b>สีตรงตัว</b> (ไม่เปลี่ยนตามธีม) <span class="lits">{chips}</span></p>')
    if dyn:
        extra.append('<p><b>สีจากรายการ</b> ' + ' · '.join(f'<code>{esc(t)}</code>' for t in dyn) + ' <span class="mut">— ค่าในฟิลด์ของชิ้นนั้น เช่นสีแบรนด์ของช่องทาง</span></p>')
    if overs:
        extra.append('<p><b>โหนดที่นั่งคนละพื้น</b> ' + ' · '.join(f'<code>on: {s}</code> {c} โหนด' for s, c in overs.most_common()) + '</p>')
    if not per and not lit and not dyn: extra.append('<p class="mut">ใบนี้ไม่ได้ระบุสีเอง — ใช้ค่าตั้งต้นของตัววาด (ตัวหนังสือ = ink · เส้น = ink@0.12)</p>')
    out.append(''.join(extra) + '</section>')
    return ''.join(out)

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
    meta.append(f'พื้นสี: {w.get("on") or "card"}')
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
{colour_block(spec)}
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
  .grp { scroll-margin-top:104px; }
  .gh { font:700 24px/1.2 var(--display); color:var(--ink); display:flex; align-items:baseline; gap:10px; } .gh::after { content:""; flex:1; height:2px; background:var(--g); opacity:.25; align-self:center; }
  .gh code { font:500 13px var(--mono); color:var(--g); background:var(--gs); padding:2px 8px; border-radius:6px; } .gh .n { font:500 13px var(--sans); color:var(--faint); }
  .ng a.g-me, .ng a.g-job, .ng a.g-work { --g:var(--me); } .ng a.g-job { --g:var(--job); } .ng a.g-work { --g:var(--work); }
  .cat.sub { margin-top:14px; } .cat.sub .ch h2 { font-size:15px; } .cat:not(.sub) .ch { margin-top:4px; }
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
  /* ถาดพื้นหลังของการ์ด = ถาดของแอป (`buildTray` + TRAY_CSS จาก sync-server) — ก่อนโหลดเป็นกล่องว่าง */
  .ptheme { margin:0 0 10px; min-height:0; }
  .bar .status { font-size:12.5px; color:var(--pt); } .bar .status code { font:12px var(--mono); }
  /* ชิ้นบนการ์ด = widget จริงที่ `mountWidget` วาด — ลูกทั้งหมดไม่รับ pointer (ลาก/เลือกที่กล่อง) ยกเว้นหมุดมุม */
  .it { position:absolute; cursor:grab; touch-action:none; user-select:none; -webkit-user-select:none; }
  .it > * { pointer-events:none; }
  .it.sel { outline:3px solid var(--pt); outline-offset:2px; border-radius:10px; }
  .it.live { outline-color:#fff; }
  .it .err { position:absolute; inset:0; margin:0; color:#f77; font:10px var(--mono); overflow:hidden; white-space:pre-wrap; }
  .it .rs { position:absolute; right:-11px; bottom:-11px; width:22px; height:22px; border-radius:50%; background:#fff; border:1.6px solid var(--pt); box-shadow:0 1px 3px rgba(0,0,0,.4); cursor:nwse-resize; pointer-events:auto; }
  .it .rs::after { content:"⤡"; position:absolute; inset:0; display:grid; place-items:center; font:700 11px var(--display); color:var(--pt); }
  .it.pin::after { content:"ตรึง"; position:absolute; left:6px; top:6px; font:700 11px var(--body); color:#1d1416; background:var(--pt); padding:1px 6px; border-radius:6px; }
  .ghost { position:fixed; z-index:50; pointer-events:none; opacity:.85; width:120px; border-radius:8px; box-shadow:0 8px 24px rgba(0,0,0,.35); }
  /* ถาดชิ้น (= `pieceTray` ของแอป) — ใช้ชั้น .bt ของถาดแอปเมื่อมีชิ้นเลือก */
  .sel { background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:10px 12px; font-size:13.5px; display:flex; flex-wrap:wrap; gap:6px 12px; align-items:center; }
  /* มีชิ้นเลือก = ถาดลอยติดขอบล่างของจอเหมือน dock sheet ของแอป — เลื่อนดูการ์ดยาว ๆ แล้วถาดยังอยู่ */
  .sel.bt { display:flex; flex-direction:column; align-items:stretch; gap:8px; position:sticky; bottom:10px; z-index:6; box-shadow:0 10px 30px rgba(0,0,0,.45); max-height:46vh; overflow:auto; }
  .sel .ph { display:flex; flex-wrap:wrap; gap:6px 12px; align-items:center; }
  .sel .ph b { font:600 15px var(--display); color:#fff; } .sel .ph code { font:12px var(--mono); color:rgba(255,255,255,.6); }
  .sel .ph a { color:#9ab; font-size:12.5px; }
  .sel .act { font:inherit; font-size:12.5px; padding:4px 10px; border-radius:8px; border:1px solid rgba(255,255,255,.18); background:rgba(255,255,255,.06); color:#fff; cursor:pointer; }
  .sel .act[disabled] { opacity:.4; cursor:not-allowed; }
  .sel .hintrow { font-size:12px; } .sel .mut { color:rgba(255,255,255,.5); }
  .sel .vars { display:flex; gap:10px; overflow-x:auto; padding:2px 1px; scrollbar-width:none; }
  .sel .vars button { flex:0 0 auto; width:127px; border:0; background:transparent; color:rgba(255,255,255,.8); font:600 11px var(--display); cursor:pointer; padding:0; display:flex; flex-direction:column; gap:5px; align-items:center; }
  .sel .vars img { width:127px; height:84px; object-fit:cover; border-radius:12px; box-shadow:inset 0 0 0 .6px rgba(255,255,255,.14); display:block; background:#0e1024; }
  .sel .vars button.on img { box-shadow:inset 0 0 0 2px var(--pt); }
  .sel .chk { display:flex; flex-wrap:wrap; gap:6px; }
  .sel .chk button { display:inline-flex; align-items:center; gap:6px; height:30px; padding:0 10px; border-radius:999px; border:0; background:rgba(255,255,255,.05); color:rgba(255,255,255,.55); font:600 12px var(--display); cursor:pointer; }
  .sel .chk button.on { background:rgba(255,255,255,.12); color:rgba(255,255,255,.92); } .sel .chk button.locked { opacity:.6; cursor:default; }
  .sel .chk i { font-style:normal; font-size:14px; }
  .sel .stp { display:inline-flex; align-items:center; height:32px; border-radius:999px; background:rgba(0,0,0,.28); }
  .sel .stp button { width:40px; height:32px; border:0; background:transparent; color:rgba(255,255,255,.9); font:700 14px var(--display); cursor:pointer; } .sel .stp button.off { color:rgba(255,255,255,.25); cursor:default; }
  .sel .stp b { width:40px; text-align:center; color:#fff; font:700 14px var(--display); font-variant-numeric:tabular-nums; }
  .sel .swrow { justify-content:space-between; } .sel .swrow .lbl { min-width:0; color:rgba(255,255,255,.8); font-size:12px; }
  .sel .sw { width:51px; height:31px; border-radius:999px; border:0; background:rgba(120,120,128,.32); position:relative; cursor:pointer; padding:0; transition:background .15s; }
  .sel .sw i { position:absolute; top:2px; left:2px; width:27px; height:27px; border-radius:50%; background:#fff; box-shadow:0 2px 4px rgba(0,0,0,.3); transition:left .15s; }
  .sel .sw.on { background:#34C759; } .sel .sw.on i { left:22px; }
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
  /* ===== สี (token) ของใบ ===== */
  .card code .surf { font-style:normal; font-size:10px; padding:1px 6px; border-radius:999px; background:var(--chip); color:var(--mute); margin-left:4px; }
  .tokens h4 { margin:16px 0 6px; font:600 14px var(--display); } .tokens h4 small { color:var(--faint); font-weight:500; font-size:12px; margin-left:6px; }
  .tokens .surf { font-size:14px; margin:10px 0 0; } .tokens .surf .sname { font-weight:600; margin-left:4px; }
  .tokens .tw { overflow:auto; }
  table.tk { border-collapse:collapse; width:100%; font-size:13px; } table.tk th { text-align:left; font-weight:600; color:var(--mute); font-size:11.5px; padding:4px 8px; border-bottom:1px solid var(--line); }
  table.tk td { padding:6px 8px; border-bottom:1px solid var(--line); vertical-align:top; } table.tk td:first-child { white-space:nowrap; } table.tk td:nth-child(2) { min-width:150px; }
  code.tk { padding:1px 7px; border-radius:6px; background:var(--chip); font-weight:600; }
  s.sw { display:inline-block; width:18px; height:18px; border-radius:5px; border:1px solid var(--line); text-decoration:none; vertical-align:middle; margin-right:6px;
         background-image:linear-gradient(45deg,#8883 25%,transparent 25%,transparent 75%,#8883 75%),linear-gradient(45deg,#8883 25%,transparent 25%,transparent 75%,#8883 75%); background-size:8px 8px; background-position:0 0,4px 4px; }
  s.sw[style] { background-image:none; }
  code.tk.bg { background:#e9e4e6; color:#1d1416; } code.tk.bg2 { background:#f3eef0; color:#1d1416; } code.tk.ink { background:#1d1416; color:#fff; } code.tk.ink2 { background:#6c5d61; color:#fff; }
  code.tk.accent { background:var(--accent); color:#fff; } code.tk.line { background:transparent; border:1px dashed var(--mute); }
  .tokens .lits i { font-style:normal; display:inline-flex; align-items:center; gap:5px; margin:0 8px 4px 0; font:12px var(--mono); }
  .tokens .lits s { display:inline-block; width:14px; height:14px; border-radius:4px; border:1px solid var(--line); text-decoration:none; }
  .tokens p { font-size:13.5px; margin:10px 0 0; }
  .tokens .nosheet { font-size:12.5px; margin-top:6px; }
  /* ===== สีพื้นหลังตามแอป (วาดสดจากตัววาดเว็บของ sync-server) ===== */
  .colour { margin:14px 0 0; }
  .colour .col-head { display:flex; gap:10px; align-items:center; flex-wrap:wrap; }
  .colour .pill { font:600 13px var(--display); padding:6px 12px; border-radius:999px; border:1px solid var(--line); background:var(--paper); cursor:pointer; color:var(--ink); }
  .colour .pill.on { background:var(--ink); color:var(--paper); border-color:var(--ink); }
  .colour .note { color:var(--mute); font-size:12.5px; }
  #col-tray { margin-top:8px; }
  .cw { min-width:0; display:flex; flex-direction:column; }
  .cw .col-tray { margin:2px 4px 6px; } .cw .col-tray .bt { padding:8px 10px; }
  .cw .col-state { font-size:11px; color:var(--mute); padding:0 8px; }
  .th .live { position:absolute; inset:6px; overflow:hidden; }
  .th .live > div { position:absolute !important; left:50%; top:50%; transform-origin:center; }
  .th .col-adj { position:absolute; right:6px; top:6px; z-index:3; font:600 11px var(--display); padding:3px 8px; border-radius:999px; border:0; background:rgba(0,0,0,.55); color:#fff; cursor:pointer; display:none; }
  body.live .th .col-adj { display:block; }
  .cw.over .col-adj { background:var(--accent); }
'''

COLOUR_HTML = '''<div class="colour" id="colour">
      <div class="col-head"><button type="button" class="pill" id="col-toggle">🎨 สีพื้นหลังตามแอป</button><span class="note" id="col-note">เลือกสีเดียว/ไล่เฉด · สี · โทน (เฉพาะคู่สี) เหมือนถาด "พื้นหลัง" ในแอป แล้วทุก widget วาดใหม่ด้วยสีนั้น · กด "ปรับ" บนใบไหนก็ตั้งสีเฉพาะใบนั้นได้</span></div>
      <div id="col-tray" hidden></div>
    </div>'''

# สคริปต์ module: โหลดตัววาดเว็บเมื่อผู้ใช้เปิดแผงสี · ธีมตั้งต้น = ภาพ iOS เดิม
# แหล่งตัววาด: (1) ก้อนที่ฝังในไฟล์ (`window.SC_BUNDLE` จาก shared/tools/bundle-catalog.mjs — โค้ด · ผัง · ฟอนต์ · ไอคอน · fixture) → เปิดไฟล์เดียวก็เล่นได้
#               (2) ไม่มีก้อน → sync-server พอร์ต 8787 (อ่านสดจาก sync-server/web/js + shared/WidgetSpecs)
LIB_JS = r'''
// ---------- ตัววาดเว็บ (sync-server/web/js) — โหลดครั้งเดียว ใช้ร่วมกันระหว่างแผงสีของแคตตาล็อกกับแท็บ "ลองวางการ์ด" ----------
const SERVER = 'http://localhost:8787';
const BUNDLE = window.SC_BUNDLE || null;   // ก้อนที่ฝังโดย bundle-catalog.mjs — มี = ไม่ต้องเปิด sync-server
const NO_LIB = 'ไฟล์นี้ไม่มีตัววาดฝังไว้ — รัน node shared/tools/bundle-catalog.mjs หรือเปิด sync-server ก่อน (preview "sync-server" · node sync-server/server.mjs · พอร์ต 8787)';
let _lib = null, _libP = null;
// โมดูลที่ฝัง → blob: URL ตามลำดับพึ่งพา (import './x.js' ภายในชี้ไป URL ของ x) · เบราว์เซอร์ที่ไม่ยอม import blob: บนหน้า file:// ใช้ data: แทน
function bundleImporter(asData) {
  const urls = {};
  for (const name of BUNDLE.order) {
    const code = BUNDLE.modules[name].replace(/from '\.\/([\w-]+\.js)'/g, (m, f) => `from '${urls[f]}'`);
    urls[name] = asData ? 'data:text/javascript;charset=utf-8,' + encodeURIComponent(code) : URL.createObjectURL(new Blob([code], { type: 'text/javascript' }));
  }
  return (f) => import(urls[f]);
}
async function importer() {
  if (!BUNDLE) return (f) => import(`${SERVER}/card/js/${f}`);
  const blob = bundleImporter(false);
  try { await blob('theme.js'); return blob; } catch (e) { return bundleImporter(true); }
}
function loadLib() {
  if (_lib) return Promise.resolve(_lib);
  if (_libP) return _libP;
  _libP = (async () => {
    const j = await importer();
    const [tray, model, measure, data, chrome, backdrop, replay, theme, page] = await Promise.all([j('backdrop-tray.js'), j('spec-model.js'), j('measure.js'), j('data.js'), j('chrome.js'), j('backdrop.js'), j('replay.js'), j('theme.js'), j('page.js')]);
    document.head.appendChild(Object.assign(document.createElement('style'), { textContent: tray.TRAY_CSS }));
    await measure.loadFonts(BUNDLE ? (f) => BUNDLE.fonts[f] : `${SERVER}/card/fonts/`);
    // ผัง: จากก้อนที่ฝัง หรือ GET ธรรมดา (ไม่มี preflight ข้าม origin) อ่านสดจาก shared/WidgetSpecs ชุดเดียวกับ GraphQL
    const raw = BUNDLE ? BUNDLE.specs : (await (await fetch(`${SERVER}/api/specs`)).json()).specs;
    const specs = Object.fromEntries(Object.entries(raw).map(([k, j]) => [k, model.parseSpec(j)]));
    // base = ที่มาของไอคอน (function ชื่อ→data: ที่ฝัง · ไม่มีชื่อนั้นค่อยไปถาม server) · imageURL = รูปที่อัปขึ้น sync-server (แคตตาล็อกไม่ใช้)
    const base = BUNDLE ? (name) => BUNDLE.icons[name] || `${SERVER}/card/icon/${encodeURIComponent(name)}` : `${SERVER}/card/`;
    const fixture = BUNDLE ? async (k) => BUNDLE.fixtures[k] || null
      : async (k) => fetch(`${SERVER}/card/fixtures/fixtures/${k}.json`).then(r => (r.ok ? r.json() : null)).then(f => f?.cases.find(c => c.probe === 'design') || null).catch(() => null);
    _lib = { ...tray, ...data, ...chrome, ...backdrop, ...replay, ...page, specs, theme, measurer: new measure.WebMeasurer(), specPalette: theme.specPalette, css: theme.css, makeTheme: theme.makeTheme,
      base, imageURL: (id) => `${SERVER}/api/images/${id}`, fixture, bundled: !!BUNDLE, builtAt: BUNDLE?.builtAt || null };
    return _lib;
  })().catch((e) => { _libP = null; throw e; });
  return _libP;
}
'''

LIVE_JS = r'''
// ---------- สีพื้นหลังตามแอป: วาด widget สดด้วยตัววาดเว็บ (sync-server/web/js) — ภาพนิ่งคือธีมตั้งต้นของตัวส่งออก iOS ----------
const KEY = 'sc-cat-colour-v2';   // v2 = เก็บ hex (colors.primary/secondary) ไม่ใช่ชื่อพาเลตต์
const trayEl = document.getElementById('col-tray'), note = document.getElementById('col-note'), toggle = document.getElementById('col-toggle');
const cards = [...document.querySelectorAll('#home .cw')];
let lib = null, state = { page: null, per: {} };
try { const s = JSON.parse(localStorage.getItem(KEY)); if (s && s.page) state = { page: s.page, per: s.per || {} }; } catch (e) {}
const save = () => { try { localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) {} };
const fixtures = {};
const fixture = async (k) => (fixtures[k] ??= await lib.fixture(k));   // กรณี `design` ของ fixture (ค่าที่ iOS วาดภาพนิ่ง) — จากก้อนที่ฝังหรือจาก server

async function load() {
  if (lib) return lib;
  note.textContent = BUNDLE ? 'กำลังโหลดตัววาด…' : 'กำลังโหลดตัววาดจาก sync-server…';
  try {
    lib = await loadLib();
    if (!state.page) state.page = lib.defaultChoice();
    document.body.classList.add('live');
    note.textContent = 'ธีมตั้งต้น = ภาพจาก iOS · เลือกสีแล้วทุกใบวาดใหม่ด้วยตัววาดเว็บ (ผัง JSON ชุดเดียวกัน) · "ปรับ" บนใบ = สีเฉพาะใบนั้น' + (lib.bundled ? ' · ตัววาดฝังในไฟล์ ' + lib.builtAt : ' · ตัววาดสดจาก sync-server');
    return lib;
  } catch (e) { note.textContent = (BUNDLE ? 'โหลดตัววาดไม่ได้: ' : NO_LIB + ': ') + e.message; throw e; }
}

const choiceFor = (k) => state.per[k] || state.page;
function fit(live) { const inner = live.firstChild; if (!inner) return; const r = live.getBoundingClientRect(); if (!r.width || !inner.offsetWidth) return; const k = Math.min(r.width / inner.offsetWidth, r.height / inner.offsetHeight); inner.style.transform = `translate(-50%,-50%) scale(${k})`; }
// วาดตอนแท็บนี้ถูกซ่อน (เปิดหน้าที่ #color · #play …) กรอบกว้าง 0 → ย่อไม่ได้ · คิดใหม่ทุกครั้งที่กรอบภาพเปลี่ยนขนาด รวมถึงตอนกลับมาที่แท็บนี้
const fitRO = new ResizeObserver((es) => es.forEach((e) => { const l = e.target.querySelector('.live'); if (l) fit(l); }));
cards.forEach((cw) => fitRO.observe(cw.querySelector('.th')));
window.addEventListener('hashchange', () => setTimeout(() => document.querySelectorAll('#home .th .live').forEach(fit), 0));   // กลับมาแท็บนี้ (route ซ่อน/โชว์ #home ก่อน)

async function renderCard(cw) {
  const kind = cw.dataset.k, th = cw.querySelector('.th'), img = th.querySelector('img[data-k]');
  let live = th.querySelector('.live');
  const choice = choiceFor(kind);
  cw.classList.toggle('over', !!state.per[kind]);
  cw.querySelector('.col-state').textContent = state.per[kind] ? 'ใบนี้: ' + lib.describe(state.per[kind]) : '';
  if (lib.isDefault(choice)) { live?.remove(); img.style.visibility = ''; return; }   // ธีมตั้งต้น = ภาพ iOS เดิม
  const spec = lib.specs[kind]; if (!spec) return;
  const W = spec.design.w, H = spec.design.h, M = 12;
  if (!live) { live = document.createElement('div'); live.className = 'live'; th.appendChild(live); }
  live.innerHTML = '';
  const inner = document.createElement('div');
  inner.style.cssText = `width:${W + M * 2}px;height:${H + M * 2}px;overflow:hidden;position:relative;border-radius:10px`;
  live.appendChild(inner);
  const theme = lib.themeOf(choice);
  lib.paintBackdrop(inner, theme, W + M * 2, H + M * 2);
  const fx = await fixture(kind);
  const profile = new lib.Profile({}, {});
  const fallback = new lib.WebSpecData({ profile, item: {}, sample: true, surface: 'glass' });
  const item = { id: '00000000-0000-0000-0000-000000000000', kind, x: M, y: M, w: W, h: H, surface: 'glass', border: false };
  const env = { doc: { photos: {}, owner: {}, notes: {} }, theme, profile, specs: lib.specs, measurer: lib.measurer, base: lib.base,
    imageURL: lib.imageURL, makeData: fx ? () => new lib.ReplayData(fx.data, fallback) : null };
  try { lib.mountWidget(inner, item, { x: M, y: M, width: W, height: H }, env); } catch (e) { inner.innerHTML = `<pre style="color:#f77;font-size:10px">${e.message}</pre>`; }
  img.style.visibility = 'hidden';
  fit(live);
}
async function renderAll(onlyPage) {
  for (const cw of cards) { if (onlyPage && state.per[cw.dataset.k]) continue; await renderCard(cw); }
  paintSwatches();
}
// swatch ในส่วน "สี (token)" ของหน้ารายละเอียด = สีจริงใต้สีที่เลือก (ของหน้า หรือของใบนั้น) — ตัวคิดเดียวกับที่วาดใบ
function paintSwatches() {
  if (!lib) return;
  for (const sec of document.querySelectorAll('section.tokens[data-k]')) {
    const t = lib.themeOf(choiceFor(sec.dataset.k));
    // พื้นผิวตั้งต้นของชิ้น + พื้นตั้งต้นของใบ (widget.on) — กติกา noSheet ทำงานตามพื้นผิวนั้น · โหนดที่ไม่ระบุ on ส่ง null
    const pal = lib.specPalette({ t, ink: t.inkStyle, accent: t.accent, surface: sec.dataset.surface || 'glass', skin: null, kit: {}, border: false, base: sec.dataset.base || 'card' });
    for (const sw of sec.querySelectorAll('s.sw[data-tok]')) { const c = lib.css(pal.color(sw.dataset.tok, sw.dataset.on || null)); sw.style.background = c; sw.title = c; }
  }
}

// แผงของทั้งหน้า
let open = false;
function rebuildPage() {
  const reset = document.createElement('button'); reset.type = 'button'; reset.className = 'link'; reset.textContent = 'ตั้งต้น (ภาพ iOS)';
  reset.onclick = () => { state.page = lib.defaultChoice(); state.per = {}; save(); rebuildPage(); cards.forEach(cw => { cw.querySelector('.col-tray').hidden = true; }); renderAll(false); };
  lib.buildTray(trayEl, state.page, () => { save(); rebuildPage(); renderAll(true); }, { extra: reset });
}
toggle.addEventListener('click', async () => {
  open = !open; toggle.classList.toggle('on', open); trayEl.hidden = !open;
  if (open) { try { await load(); rebuildPage(); } catch (e) { open = false; toggle.classList.remove('on'); trayEl.hidden = true; } }
});

// "ปรับ" บนใบ — สีเฉพาะใบนั้น (เริ่มจากค่าของหน้า) · "ตามหน้า" = เลิกปรับ
for (const cw of cards) {
  const k = cw.dataset.k, mini = cw.querySelector('.col-tray');
  const rebuildMini = () => {
    const back = document.createElement('button'); back.type = 'button'; back.className = 'link'; back.textContent = 'ตามหน้า';
    back.onclick = () => { delete state.per[k]; save(); mini.hidden = true; renderCard(cw); paintSwatches(); };
    lib.buildTray(mini, state.per[k], () => { save(); rebuildMini(); renderCard(cw); paintSwatches(); }, { extra: back });
  };
  cw.querySelector('.col-adj').addEventListener('click', async (e) => {
    e.preventDefault(); e.stopPropagation();
    await load();
    if (state.per[k] && !mini.hidden) { mini.hidden = true; return; }
    if (!state.per[k]) { state.per[k] = { ...state.page }; save(); }
    rebuildMini(); mini.hidden = false; renderCard(cw);
  });
}

// เคยเลือกไว้ → วาดต่อให้เลยตอนเปิดหน้า (โหลดตัววาดไม่ได้ก็ยังเห็นภาพ iOS ตามเดิม)
if (state.page && (Object.keys(state.per).length || state.page.backdrop !== 'solid' || (state.page.primary || '').toUpperCase() !== '#1A1F35' || state.page.secondary || state.page.tone !== 'dark')) {
  load().then(() => { renderAll(false); for (const cw of cards) if (state.per[cw.dataset.k]) { cw.querySelector('.col-adj').click(); } }).catch(() => {});
}
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
  document.body.classList.toggle('color', h === 'color');
  if (h === 'color') {   // แท็บสี — เขียนแยกก่อนบรรทัด view เพราะ build-flow.mjs --splice แทนที่บรรทัดนั้นตรงตัว
    ['detail', 'play', 'render', 'flow'].forEach(c => document.body.classList.remove(c));
    document.querySelectorAll('nav.tabs a').forEach(a => a.classList.toggle('on', a.dataset.tab === 'color'));
    document.title = 'สีทำงานยังไง · Widget Catalog'; window.scrollTo(0, 0); window.dispatchEvent(new Event('color-open')); return;
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
    <p class="lede">ลาก widget จากซ้ายลงการ์ด (หรือแตะเพื่อเพิ่ม) · ลากย้าย · ลากมุมขวาล่างเพื่อปรับขนาด · แตะชิ้นแล้วปรับกล่อง/ตัวเลือก/ขอบเหมือนถาดในแอป · การ์ดวาดสดด้วยตัววาดเว็บ (กติกาเดียวกับ iOS) · ขวามือคือสิ่งที่แอปส่งไปบันทึกจริง</p>
  </header>
  <div class="pl">
    <aside class="pal" aria-label="widget ทั้งหมด"><input id="pq" type="search" placeholder="ค้นหา widget" aria-label="ค้นหา widget"><div id="pal"></div></aside>
    <div class="boardwrap">
      <div class="bar"><span>สตอรี่ 540 × 960</span><span id="cnt"></span><span id="pstatus" class="status"></span><button type="button" id="preset">ตัวอย่าง</button><button type="button" id="reset">ล้าง</button></div>
      <div class="ptheme" id="ptheme" aria-label="พื้นหลังของการ์ด"></div>
      <div class="board" id="board"><div class="page9" id="page9"></div></div>
      <div class="sel" id="sel"><span class="mut">แตะชิ้นบนการ์ดเพื่อดูว่าเก็บอะไร · ปรับได้เหมือนถาดในแอป</span></div>
    </div>
    <aside class="api" aria-label="API">
      <div class="ptabs" role="tablist"><button type="button" class="on" data-p="doc">doc ที่เก็บ</button><button type="button" data-p="save">บันทึก</button><button type="button" data-p="load">เปิดการ์ด</button></div>
      <div class="pp" data-p="doc"><p class="hint">เก็บแค่ <b>ตำแหน่ง · ขนาด · ตัวเลือกของชิ้น</b> + <b>theme</b> 3 อย่างตามถาดพื้นหลัง: <b>colors</b> (hex เท่านั้น — พาเลตต์/คู่สีในแอปเป็นแค่ปุ่มลัด) · <b>ink</b> (โทน) · <b>backdrop</b> (สีเดียว/ไล่เฉด) — ไม่มีข้อความหรือข้อมูลเจ้าของในการ์ด · โทน (<b>ink</b>) ของสีเดียวเลือกเองจากความสว่างของพื้น ผู้ใช้เลือกโทนเข้ม/อ่อนได้เฉพาะคู่สี</p><pre id="doc"></pre></div>
      <div class="pp" data-p="save" hidden><p class="hint">แอปบันทึกร่างอัตโนมัติหลังแก้ · <b>baseRev</b> ต้องตรงกับฉบับล่าสุด ไม่ตรง = มีคนแก้ซ้อน</p><ol id="log" class="log"></ol><pre id="mut"></pre></div>
      <div class="pp" data-p="load" hidden><p class="hint">เปิดการ์ด = โหลด doc 1 ครั้ง + query ของ<b>หมวดละ 1 ครั้ง</b> ไม่ว่าหมวดนั้นจะมีกี่ใบ</p><div id="calls"></div></div>
    </aside>
  </div>
</section>'''

PLAY_JS = r'''
// ---------- ลองวางการ์ด: การ์ดสตอรี่ 540×960 **วาดจริง** ด้วยตัววาดเว็บ (sync-server/web/js — ผัง JSON · ตัวคิด · ตัวทาสี ชุดเดียวกับ iOS) ----------
// กติกาของกระดาน = iOS: ขอบเขต `PageLayout.bounds` (ชนขอบหน้าได้) · เล็กสุด 100×40 · ที่วางอัตโนมัติเว้นขอบ 18 ห่าง 10 สแนป 6
// · ยืดอิสระจากมุม (เพดาน = ขอบหน้า) · ผัง `solvePage` ดันชิ้นที่ทับลง · ตราที่ตรึงนั่งก้นหน้าเสมอ
// ถาดพื้นหลัง = `buildTray` (ชุดเดียวกับแอป) · ถาดชิ้น = `pieceTray` ของ CardScreen.swift: แบบ · กล่อง · `widget.controls` · ขอบ
(() => {
  const PAGE = { w: 540, h: 960 }, M = 18, GAP = 10, STEP = 6, MIN = { w: 100, h: 40 };
  const byK = Object.fromEntries(PLAY.map(p => [p.k, p]));
  const $ = id => document.getElementById(id);
  const page = $('page9'), board = $('board'), pal = $('pal'), docEl = $('doc'), mutEl = $('mut'), logEl = $('log'), callsEl = $('calls'), selEl = $('sel'), cntEl = $('cnt'), themeHost = $('ptheme'), statusEl = $('pstatus');
  const uid = () => 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => { const r = Math.random() * 16 | 0; return (c === 'x' ? r : (r & 3 | 8)).toString(16); });
  const snap = v => Math.round(v / STEP) * STEP;
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const KEY = 'sc-play-v3';
  let lib = null, items = [], sel = null, rev = 1, scale = 1, saveT = null, log = [], choice = null, live = null, raf = 0, frames = new Map(), profile = null;

  // ---- คุณสมบัติของชนิด (= `WidgetKind` ของ iOS) — อ่านจากบล็อก `widget` ของผังเท่านั้น
  const meta = k => lib.specs[k]?.widget || {};
  const design = k => lib.specs[k]?.design || { w: byK[k].dw, h: byK[k].dh };
  const defaultSize = k => meta(k).size || design(k);
  const ownSurface = k => !!meta(k).ownSurface;
  const surfaceOptions = k => meta(k).surfaces || (ownSurface(k) ? [] : ['glass', 'dim', 'clear']);
  const SURF_NAME = { glass: 'กระจก', dim: 'เข้ม', clear: 'ไม่มีพื้น', pane: 'กระจก' };   // = `WidgetSurface.name`
  const LOOK_NAME = { purple: 'ม่วงสติกเกอร์', cream: 'ครีมนุ่ม', gingham: 'กรอบตาราง', night: 'กลางคืน', mac: 'หน้าต่าง Mac' };   // = `KitStyle.name`
  const variantTitle = k => meta(k).kit ? (LOOK_NAME[meta(k).kit.look] || meta(k).kit.look || byK[k].t) : byK[k].t;
  const surfaceName = (k, s) => meta(k).surfaceNames?.[s] || SURF_NAME[s] || s;
  const defaultSurface = k => surfaceOptions(k)[0] || 'glass';
  const defaultBorder = k => meta(k).border ?? !ownSurface(k);
  const canResize = k => meta(k).resize ?? true;
  const isPinned = k => !!meta(k).pinned;
  const famOf = k => meta(k).category || byK[k]?.c;
  /** ความสูงที่คู่กับความกว้างนี้ตามสัดส่วนที่ออกแบบ (= `WidgetKind.height(forWidth:)`) */
  const aspectH = (k, w) => { const d = defaultSize(k); return Math.max(1, Math.round(w * d.h / Math.max(d.w, 1))); };

  // ---- ชิ้นในไฟล์ = 8 ฟิลด์หลัก + `options` (ค่าที่เปลี่ยนจากค่าตั้งต้นของ `widget.controls` · ค่าตั้งต้นไม่เก็บ)
  function mk(kind, x, y, w, h) { const d = defaultSize(kind); return { id: uid(), kind, x, y, w: w ?? d.w, h: h ?? d.h, surface: defaultSurface(kind), border: defaultBorder(kind), options: {} }; }
  const sealKind = () => (PLAY.find(p => p.pin) || {}).k;
  const seal = () => { const k = sealKind(); const w = 246, h = aspectH(k, w); return mk(k, PAGE.w - M - w, PAGE.h - M - h, w, h); };
  /** = `PageLayout.clamp`: จำกัดขนาดก่อน แล้วค่อยรูดตำแหน่งเข้าหน้า (ขอบเขต = ทั้งหน้า ไม่หักขอบกระดาษ) */
  function clampRect(it) { const w = clamp(it.w, MIN.w, PAGE.w), h = clamp(it.h, MIN.h, PAGE.h); it.w = w; it.h = h; it.x = clamp(it.x, 0, PAGE.w - w); it.y = clamp(it.y, 0, PAGE.h - h); return it; }
  /** ชิ้นในรูปที่ตัววาดใช้ (= `flatItem` ของเว็บดูการ์ด) — `kit.opts` = options ให้เงื่อนไข `opt:` `hidden:` ของผังอ่าน */
  function flat(it) {
    const o = {}; for (const [k, v] of Object.entries(it.options || {})) if (v != null && typeof v !== 'object') o[k] = String(v);
    const f = { id: it.id, kind: it.kind, x: it.x, y: it.y, w: it.w, h: it.h, surface: it.surface, border: it.border, options: o,
      kit: { fill: o.fill || 'solid', corner: o.corner || 'round', opts: o }, pattern: o.pattern || 'plain', pinned: isPinned(it.kind) };
    if (live && live.id === it.id) Object.assign(f, live);   // ระหว่างลาก: ที่/ขนาดตามนิ้วจริง (= `resizeLive`) — ข้อมูลจริงยังไม่ถูกแตะ
    return f;
  }
  function order(it) { const { id, kind, x, y, w, h, surface, border, options, ...rest } = it; return { id, kind, x, y, w, h, surface, border, options: options || {}, ...rest }; }
  function save() { try { localStorage.setItem(KEY, JSON.stringify({ items, rev, choice })); } catch (e) {} }
  function load() { try { const s = JSON.parse(localStorage.getItem(KEY)); if (s && s.items) { items = s.items.filter(i => lib.specs[i.kind]).map(i => ({ ...mk(i.kind, i.x, i.y, i.w, i.h), ...i })); rev = s.rev || 1; if (s.choice && s.choice.primary) choice = s.choice; return items.length > 0; } } catch (e) {} return false; }
  const firstOf = (k, cat) => byK[k] ? k : (PLAY.find(p => p.c === cat && !p.pin) || {}).k;
  function preset() {
    const hero = firstOf('heroMinimal', 'hero'), stat = firstOf('statPoster', 'followers'), rate = firstOf('kitRatePurple', 'rate');
    items = [];
    if (hero) { const w = PAGE.w - M * 2; items.push(mk(hero, M, M, w, aspectH(hero, w))); }
    if (stat) { const w = PAGE.w - M * 2; items.push(mk(stat, M, M, w, aspectH(stat, w))); }
    if (rate) items.push(mk(rate, M, M, 246, aspectH(rate, 246)));
    let y = M; for (const it of items) { it.y = y; y += it.h + GAP; }
    items.push(seal());
  }

  // ---- จานซ้าย (รูปย่อจาก iOS — แค่ไว้เลือก ชิ้นบนการ์ดวาดสด)
  function paletteHTML(q) {
    const g = {}; PLAY.filter(p => !p.pin && (!q || (p.t + p.k + p.cl).toLowerCase().includes(q))).forEach(p => (g[p.c] ??= []).push(p));
    return Object.values(g).map(ps => `<div class="pg" data-g="${ps[0].g}"><b>${ps[0].cl}</b>` + ps.map(p => `<div class="pw" data-k="${p.k}" title="${p.k}"><img src="${IMG[p.k] || ''}" alt=""><span>${p.t}</span></div>`).join('') + '</div>').join('');
  }
  pal.innerHTML = paletteHTML('');
  $('pq').addEventListener('input', e => { pal.innerHTML = paletteHTML(e.target.value.trim().toLowerCase()); });

  // ---- วาด: ฉากหลังจากธีม → ผังดันชิ้นที่ทับ (`solvePage`) → `mountWidget` ทุกชิ้นที่ขนาดจริง
  function fitScale() { const avail = board.clientWidth - 28; scale = Math.min(1, avail / PAGE.w, (window.innerHeight - 200) / PAGE.h); scale = Math.max(scale, .3);
    page.style.transform = `scale(${scale})`; page.parentElement.style.height = (PAGE.h * scale + 28) + 'px'; page.style.marginRight = (PAGE.w * scale - PAGE.w) + 'px'; page.style.marginBottom = (PAGE.h * scale - PAGE.h) + 'px'; }
  function envOf(theme) {
    return { doc: { photos: {}, owner: OWNER, notes: {} }, theme, profile, specs: lib.specs, measurer: lib.measurer, base: lib.base, imageURL: lib.imageURL };
  }
  function paint() {
    if (!lib) return;
    const theme = lib.themeOf(choice);
    page.innerHTML = '';
    lib.paintBackdrop(page, theme, PAGE.w, PAGE.h, { pageW: PAGE.w });
    const placed = lib.solvePage(items.map(flat), { width: PAGE.w, height: PAGE.h });
    const env = envOf(theme);
    frames = new Map();
    for (const p of placed) {
      const it = p.item, f = p.frame; frames.set(it.id, f);
      const host = document.createElement('div');
      host.className = 'it' + (it.id === sel ? ' sel' : '') + (it.pinned ? ' pin' : '') + (live && live.id === it.id ? ' live' : '');
      host.dataset.id = it.id; host.style.cssText = `left:${f.x}px;top:${f.y}px;width:${f.width}px;height:${f.height}px`;
      try { lib.mountWidget(host, it, { x: 0, y: 0, width: f.width, height: f.height }, env); } catch (e) { host.innerHTML = `<pre class="err">${e.message}</pre>`; }
      if (it.id === sel && canResize(it.kind) && !it.pinned) host.insertAdjacentHTML('beforeend', '<span class="rs" data-rs="1" title="ลากเพื่อปรับขนาด"></span>');
      page.appendChild(host);
    }
    cntEl.textContent = items.length + ' ชิ้น';
  }
  function render() { paint(); renderSel(); renderDoc(); renderCalls(); }
  /** หลังปล่อยนิ้ว: เขียนกรอบที่ผังดันแล้วลงชิ้น — doc ขวามือจึงตรงกับที่เห็นบนการ์ด */
  function settle() { for (const it of items) { const f = frames.get(it.id); if (f) { it.x = Math.round(f.x); it.y = Math.round(f.y); it.w = Math.round(f.width); it.h = Math.round(f.height); } } }

  // ---- doc · บันทึก · เปิดการ์ด (ขวามือ)
  function docObj() { return { schemaVersion: 1, format: 'story', name: 'การ์ดของฉัน', theme: lib.docTheme(choice), pages: [{ items: items.map(order) }] }; }
  const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
  function hl(s) { return esc(s).replace(/("[^"]*")(\s*:)/g, '<span class="jk">$1</span>$2').replace(/(:\s*)("[^"]*")/g, '$1<span class="js">$2</span>').replace(/(:\s*)(-?\d+(?:\.\d+)?|true|false|null)/g, '$1<span class="jn">$2</span>'); }
  function renderDoc() {
    if (!lib) return;
    const d = docObj(); const parts = JSON.stringify({ ...d, pages: [{ items: '§' }] }, null, 2).split('"§"');
    const its = d.pages[0].items.map(it => { const t = JSON.stringify(it, null, 2).replace(/\n/g, '\n        '); return it.id === sel ? `<span class="isel">        ${hl(t)}</span>` : '        ' + hl(t); });
    docEl.innerHTML = hl(parts[0]) + '[\n' + its.join(',\n') + '\n      ]' + hl(parts[1]);
  }
  function renderCalls() {
    const by = {}; items.forEach(it => (by[byK[it.kind].c] ??= []).push(it));
    const cats = Object.keys(by);
    callsEl.innerHTML = `<div class="call"><span class="n">1 ครั้ง</span><b>myStarCard(id: 128)</b> <span class="mut">{ draftDoc draftRev images { image { imgPath } role } }</span></div>` +
      cats.map(c => { const p = byK[by[c][0].kind]; return `<div class="call" data-g="${p.g}"><span class="n">${by[c].length} ใบ · เรียก 1 ครั้ง</span><b>${CATQ[c]}</b> <span class="mut">หมวด${p.cl}</span><div class="ws">${by[c].map(i => `<span>${i.kind}</span>`).join('')}</div></div>`; }).join('') +
      `<p class="hint">รวม <b>${cats.length + 1}</b> request สำหรับ ${items.length} ชิ้น · query ของแต่ละหมวดดูได้ในหน้า widget ช่อง ②</p>`;
  }
  function renderMut() {
    if (!lib) return;
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
  function remove(id) { const it = items.find(i => i.id === id); if (!it || isPinned(it.kind)) return; items = items.filter(i => i.id !== id); sel = null; change(`ลบ ${it.kind}`); }
  /** = `PageLayout.freeSpot`: หาที่ว่างในกระดาษ (เว้นขอบ 18) จากบนลงล่าง ห่างชิ้นอื่น 10 สแนป 6 — ไม่เจอ = มุมบนซ้าย */
  function free(w, h) {
    const taken = [...frames.values()].map(f => ({ x: f.x - GAP / 2, y: f.y - GAP / 2, w: f.width + GAP, h: f.height + GAP }));
    for (let y = M; y + h <= PAGE.h - M; y += STEP) for (let x = M; x + w <= PAGE.w - M; x += STEP) {
      if (!taken.some(o => x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y)) return { x, y };
    } return { x: M, y: M };
  }
  function add(k, at) {
    const d = defaultSize(k); let w = d.w, h = d.h;
    if (w > PAGE.w - M * 2) { h = aspectH(k, PAGE.w - M * 2); w = PAGE.w - M * 2; }
    const pos = at ? { x: snap(clamp(at.x - w / 2, 0, PAGE.w - w)), y: snap(clamp(at.y - h / 2, 0, PAGE.h - h)) } : free(w, h);
    const it = mk(k, pos.x, pos.y, w, h); const pinIdx = items.findIndex(i => isPinned(i.kind));
    pinIdx >= 0 ? items.splice(pinIdx, 0, it) : items.push(it);
    sel = it.id; paint(); settle(); change(`วาง ${k} → pages[0].items[${items.indexOf(it)}]`);
  }

  // ---- ถาดชิ้น (= `pieceTray` ใน CardScreen.swift): แบบอื่นในหมวด · กล่อง · ตัวเลือกจาก `widget.controls` · ขอบ
  const listOf = s => (s || '').split(',').filter(Boolean);
  const flagOf = (o, k, d) => o[k] == null ? d : o[k] === '1';
  const intOf = (o, k, d) => o[k] == null ? d : (parseInt(o[k], 10) || d);
  function controlItems(src) {
    if (Array.isArray(src)) return src.filter(p => p.length >= 2).map(p => [p[0], p[1]]);
    const short = t => lib.SOCIAL[t]?.short || t;
    const rates = lib.MOCK.rates.filter(r => r.price > 0);
    switch (src) {
      case 'socials': case 'shownSocials': return lib.MOCK.socials.map(s => [s.type, short(s.type)]);
      case 'rates': return rates.map(r => [r.id, r.label]);
      case 'ratePlatforms': return [...new Set(rates.map(r => r.platform))].map(t => [t, short(t)]);
      case 'categories': return profile.items('categories').map(c => [c, c]);
      default: return [];
    }
  }
  /** เงื่อนไขของแถว (= `controlCondition`): `opt:k=v` · `opt:k` · `hidden:key` · `surface=glass` · `bordered` · นำหน้า `!` = กลับค่า */
  function cond(c, it) {
    let t = (c || '').trim(); if (!t) return true;
    const neg = t.startsWith('!'); if (neg) t = t.slice(1);
    const o = it.options || {}; let v = false;
    if (t.startsWith('opt:')) { const b = t.slice(4), eq = b.indexOf('='); v = eq >= 0 ? o[b.slice(0, eq)] === b.slice(eq + 1) : o[b] != null; }
    else if (t.startsWith('hidden:')) v = listOf(o.hide).includes(t.slice(7));
    else if (t.startsWith('surface=')) v = it.surface === t.slice(8);
    else if (t === 'bordered') v = !!it.border;
    return neg ? !v : v;
  }
  /** แก้ตัวเลือกของชิ้น แล้ว (ถ้า refit) รูดกรอบกลับเข้าหน้า (= `editOptions`) */
  function edit(it, what, refit, fn) { fn(it); if (refit) clampRect(it); change(what); }
  const h = (tag, cls, html) => { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; };
  function row(label, ...kids) { const d = h('div', 'row'); if (label) d.appendChild(h('span', 'lbl', esc(label))); kids.forEach(k => d.appendChild(k)); return d; }
  function seg(opts, value, pick) {
    const s = h('div', 'seg');
    for (const [v, title] of opts) { const b = h('button', (v ?? null) === (value ?? null) ? 'on' : '', esc(title)); b.type = 'button'; b.onclick = () => pick(v); s.appendChild(b); }
    return s;
  }
  function controlRow(it, ctl) {
    const o = it.options, refit = ctl.refit ?? true, label = ctl.label || '';
    if (!cond(ctl.if, it)) return null;
    switch (ctl.type) {
      case 'pick': {
        const list = controlItems(ctl.items); if (!ctl.opt || list.length < (ctl.minItems ?? 0)) return null;
        const cur = o[ctl.opt] ?? list[0]?.[0] ?? '';
        return row(label, seg(list, cur, v => edit(it, `ตัวเลือก ${it.kind}.${ctl.opt} = ${v}`, refit, w => { w.options[ctl.opt] = v; })));
      }
      case 'segment': {
        if (!ctl.opt) return null;
        const opts = (ctl.options || []).map(p => [p[0] ?? null, p[1] ?? '']);
        return row(label, seg(opts, o[ctl.opt] ?? null, v => edit(it, `ตัวเลือก ${it.kind}.${ctl.opt} = ${v ?? 'ค่าตั้งต้น'}`, refit, w => {
          if (v == null) delete w.options[ctl.opt]; else w.options[ctl.opt] = v;
          for (const k of ctl.clears || []) delete w.options[k];
        })));
      }
      case 'stepper': {
        if (!ctl.opt) return null;
        const values = ctl.values || [], cur = intOf(o, ctl.opt, Number(ctl.default) || 0), i = Math.max(0, values.indexOf(cur));
        const s = h('div', 'stp'); const go = v => edit(it, `ตัวเลือก ${it.kind}.${ctl.opt} = ${v}`, refit, w => { w.options[ctl.opt] = String(v); });
        const minus = h('button', i > 0 ? '' : 'off', '−'); minus.type = 'button'; minus.onclick = () => { if (i > 0) go(values[i - 1]); };
        const plus = h('button', i < values.length - 1 ? '' : 'off', '+'); plus.type = 'button'; plus.onclick = () => { if (i < values.length - 1) go(values[i + 1]); };
        s.append(minus, h('b', '', String(cur)), plus);
        return row(label, s);
      }
      case 'switch': {
        if (!ctl.opt) return null;
        const d = ctl.default === true || ctl.default === 'true', on = flagOf(o, ctl.opt, d);
        const sw = h('button', 'sw' + (on ? ' on' : ''), '<i></i>'); sw.type = 'button'; sw.setAttribute('role', 'switch'); sw.setAttribute('aria-checked', on);
        sw.onclick = () => edit(it, `ตัวเลือก ${it.kind}.${ctl.opt} = ${!on}`, refit, w => { const v = !on; if (v === d) delete w.options[ctl.opt]; else w.options[ctl.opt] = v ? '1' : '0'; });
        const r = row(label, sw); r.classList.add('swrow'); return r;
      }
      case 'checks': {
        const list = controlItems(ctl.items); if (list.length < (ctl.minItems ?? 0)) return null;
        const opt = ctl.opt || 'hide', flags = ctl.flags || null;
        const hidden = new Set(flags ? list.map(p => p[0]).filter(k => flags[k] && flagOf(o, flags[k], false)) : listOf(o[opt]));
        const shown = list.filter(p => !hidden.has(p[0])).length;
        const wrap = h('div', 'chk');
        for (const [key, title] of list) {
          const on = !hidden.has(key), locked = on && shown <= 1;   // เหลือได้น้อยสุดหนึ่งช่องเสมอ
          const b = h('button', (on ? 'on' : '') + (locked ? ' locked' : ''), `<i>${on ? '☑' : '☐'}</i>${esc(title)}`); b.type = 'button';
          b.onclick = () => { if (locked) return; edit(it, `${on ? 'ซ่อน' : 'แสดง'} ${key} ใน ${it.kind}`, true, w => {
            if (flags && flags[key]) { const f = flags[key]; w.options[f] === '1' ? delete w.options[f] : (w.options[f] = '1'); }
            else { const s = new Set(listOf(w.options[opt])); s.has(key) ? s.delete(key) : s.add(key); if (s.size) w.options[opt] = [...s].sort().join(','); else delete w.options[opt]; }
          }); };
          wrap.appendChild(b);
        }
        return row(label, wrap);
      }
      default: return null;
    }
  }
  function swap(it, kind) {
    if (kind === it.kind || isPinned(it.kind)) return;
    // แบบใหม่มีสัดส่วนของตัวเอง — คงความกว้าง ความสูงมาจากผังของแบบใหม่ · กลับไปใช้พื้น/ขอบตั้งต้นของมัน (= `swap` ใน CardScreen)
    edit(it, `สลับ ${it.kind} → ${kind}`, true, w => { w.kind = kind; w.h = aspectH(kind, w.w); w.surface = defaultSurface(kind); w.border = defaultBorder(kind); });
  }
  function renderSel() {
    const it = items.find(i => i.id === sel);
    selEl.classList.toggle('bt', !!it && !!lib);
    if (!it || !lib) { selEl.innerHTML = '<span class="mut">แตะชิ้นบนการ์ดเพื่อดูว่าเก็บอะไร · ปรับได้เหมือนถาดในแอป</span>'; return; }
    const p = byK[it.kind], pinned = isPinned(it.kind), f = frames.get(it.id) || it;
    selEl.innerHTML = '';
    const head = h('div', 'ph', `<b>${esc(p.t)}</b><code>${it.kind}</code><span class="mut">หมวด${esc(p.cl)} · x ${Math.round(f.x)} · y ${Math.round(f.y)} · ${Math.round(f.width ?? f.w)}×${Math.round(f.height ?? f.h)}</span>
      <a href="#w/${it.kind}">ดู widget →</a><button type="button" class="act" id="up">ขึ้นบน</button><button type="button" class="act" id="del" ${pinned ? 'disabled title="ตราที่ตรึงลบไม่ได้"' : ''}>ลบ</button>`);
    head.querySelector('#del').onclick = () => remove(it.id);
    head.querySelector('#up').onclick = () => { items = items.filter(i => i !== it).concat(it); const pi = items.findIndex(i => isPinned(i.kind)); if (pi >= 0 && pi < items.length - 1) { const pin = items.splice(pi, 1)[0]; items.push(pin); } change(`ยก ${it.kind} ขึ้นบนสุด`); };
    selEl.appendChild(head);
    // แบบอื่นในหมวดเดียวกัน (= `variantsRow`) — ตราที่ตรึงไม่มีแบบอื่นให้สลับ
    if (!pinned) {
      const sib = PLAY.filter(q => !q.pin && famOf(q.k) === famOf(it.kind));
      if (sib.length > 1) {
        const v = h('div', 'vars');
        for (const q of sib) { const b = h('button', q.k === it.kind ? 'on' : '', `<img src="${IMG[q.k] || ''}" alt=""><span>${esc(variantTitle(q.k))}</span>`); b.type = 'button'; b.title = q.k; b.onclick = () => swap(it, q.k); v.appendChild(b); }
        selEl.appendChild(row('แบบ', v));
      }
    }
    // กล่อง (`widget.surfaces`) — ใบที่วาดพื้นเองไม่มีแถวนี้
    const surfs = surfaceOptions(it.kind);
    if (surfs.length > 1) selEl.appendChild(row('กล่อง', seg(surfs.map(s => [s, surfaceName(it.kind, s)]), it.surface, v => edit(it, `กล่อง ${it.kind} = ${v}`, false, w => { w.surface = v; }))));
    for (const ctl of meta(it.kind).controls || []) { const r = controlRow(it, ctl); if (r) selEl.appendChild(r); }
    selEl.appendChild(row('ขอบ', seg([[true, 'มีขอบ'], [false, 'ไม่มีขอบ']], !!it.border, v => edit(it, `ขอบ ${it.kind} = ${v}`, false, w => { w.border = v; }))));
    const hint = pinned ? 'Sale Here วางให้ทุกการ์ด · ย้ายหรือลบไม่ได้' : canResize(it.kind) ? 'ลากเพื่อย้าย · หมุดมุมยืดกว้าง/สูง' : 'ลากเพื่อย้าย · ขนาดล็อก หลักฐานต้องเทียบกันได้';
    selEl.appendChild(h('div', 'hintrow', `<span class="mut">${hint}</span>`));
  }

  // ---- ลากจากจาน (pointer — ใช้ได้ทั้งเมาส์และนิ้ว)
  let drag = null;
  const toPage = (cx, cy) => { const r = page.getBoundingClientRect(); return { x: (cx - r.left) / scale, y: (cy - r.top) / scale, inside: cx >= r.left && cx <= r.right && cy >= r.top && cy <= r.bottom }; };
  pal.addEventListener('pointerdown', e => {
    const pw = e.target.closest('.pw'); if (!pw || !lib) return;
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
  // ---- ย้าย / ปรับขนาดบนการ์ด — ระหว่างลากวาดที่ขนาดนิ้วจริงและผังดันชิ้นอื่นลงเป็นลูกโซ่ (= `resizeLive` + `resizePush`)
  let act = null;
  const schedule = () => { if (!raf) raf = requestAnimationFrame(() => { raf = 0; paint(); renderSel(); }); };
  page.addEventListener('pointerdown', e => {
    if (!lib) return;
    const el = e.target.closest('.it'); if (!el) { sel = null; render(); return; }
    const it = items.find(i => i.id === el.dataset.id); if (!it) return; sel = it.id;
    const f = frames.get(it.id) || it;
    act = { it, rs: !!e.target.dataset.rs, sx: e.clientX, sy: e.clientY, x: f.x, y: f.y, w: f.width ?? f.w, h: f.height ?? f.h, moved: false };
    try { page.setPointerCapture(e.pointerId); } catch (_) {} render();
  });
  page.addEventListener('pointermove', e => {
    if (!act) return; const dx = (e.clientX - act.sx) / scale, dy = (e.clientY - act.sy) / scale; const it = act.it;
    if (Math.abs(dx) + Math.abs(dy) > 2) act.moved = true; if (!act.moved) return;
    if (isPinned(it.kind) || (act.rs && !canResize(it.kind))) return;
    if (act.rs) {
      // เพดานคือขอบหน้า (ยืดจนเต็มได้) · พื้นคือขนาดเล็กสุด (= `sizeHandle`: roomWidth/roomHeight จากมุมบนซ้ายของกรอบปัจจุบัน)
      const roomW = Math.max(MIN.w, PAGE.w - act.x), roomH = Math.max(MIN.h, PAGE.h - act.y);
      live = { id: it.id, w: clamp(act.w + dx, MIN.w, roomW), h: clamp(act.h + dy, MIN.h, roomH) };
    } else {
      live = { id: it.id, x: clamp(act.x + dx, 0, PAGE.w - act.w), y: clamp(act.y + dy, 0, PAGE.h - act.h) };
    }
    schedule();
  });
  const endAct = () => {
    if (!act) return; const a = act; act = null; if (raf) { cancelAnimationFrame(raf); raf = 0; }
    if (!a.moved || isPinned(a.it.kind)) { live = null; render(); return; }
    const it = a.it;
    if (live && live.w != null) { it.w = Math.round(live.w); it.h = Math.round(live.h); }           // ปัดเป็นจุดเต็ม ไม่สแนปขั้น (= `endResize`)
    else if (live) { it.x = snap(live.x); it.y = snap(live.y); clampRect(it); }                         // ย้าย: สแนป 6 แล้วรูดเข้าหน้า
    live = null; paint(); settle();
    change(a.rs ? `ปรับขนาด ${it.kind} → ${it.w}×${it.h}` : `ย้าย ${it.kind} → x ${it.x} · y ${it.y}`);
  };
  page.addEventListener('pointerup', endAct); page.addEventListener('pointercancel', endAct);
  document.addEventListener('keydown', e => { if (!document.body.classList.contains('play') || !sel || e.target.closest('input')) return; if (e.key === 'Delete' || e.key === 'Backspace') { e.preventDefault(); remove(sel); } });
  // ---- แท็บขวา
  document.querySelector('.ptabs').addEventListener('click', e => { const b = e.target.closest('button'); if (!b) return;
    document.querySelectorAll('.ptabs button').forEach(x => x.classList.toggle('on', x === b)); document.querySelectorAll('.api .pp').forEach(x => x.hidden = x.dataset.p !== b.dataset.p); });
  $('reset').onclick = () => { if (!lib) return; items = [seal()]; sel = null; change('ล้างการ์ด (เหลือตราที่ตรึง)'); };
  $('preset').onclick = () => { if (!lib) return; preset(); sel = null; paint(); settle(); change('ใส่การ์ดตัวอย่าง'); };
  // ---- ถาดพื้นหลัง = ถาดของแอป (`buildTray`) — ค่าที่เลือกคือ `theme` ใน doc
  function rebuildTray() { lib.buildTray(themeHost, choice, () => { save(); rebuildTray(); change('เปลี่ยนพื้นหลัง → theme (' + lib.describe(choice) + ')'); }); }

  // ---- ข้อมูลเจ้าของ (ตัวอย่าง) — ชิ้นบนการ์ดอ่านจาก Profile เหมือนแอป · doc ไม่เก็บข้อความพวกนี้
  const OWNER = { values: { name: 'นิรา ภัทรวดี', nickname: 'นิรา', about: 'รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป', quote: 'ทำงานไว ส่งตรงเวลา แก้ได้ 2 รอบ',
      handle: 'nira.beauty', contactName: 'นิรา ภัทรวดี', role: 'ติดต่อโดยตรง', phone: '081-234-5678', email: 'nira@email.com', lineId: '@nirabeauty', website: 'nirabeauty.co', workArea: 'กรุงเทพมหานคร' },
    list: { categories: ['บิวตี้', 'สกินแคร์', 'ไลฟ์สไตล์'] },
    // ฟอร์ม Star Profile (= `owner.intake`): ช่องทาง · เรต · วันเวลา/พื้นที่ — ใบที่อ่านของพวกนี้จึงมีค่าจริงไม่ใช่ตัวอย่างจาง
    intake: { kind: 'creator', interests: ['บิวตี้', 'สกินแคร์', 'ไลฟ์สไตล์'],
      socials: [{ type: 'instagram', link: 'https://instagram.com/nira.beauty', followers: 184000, enabled: true, source: 'connected' },
                { type: 'tiktok', link: 'https://tiktok.com/@nirabeauty', followers: 320500, enabled: true, source: 'connected' },
                { type: 'youtube', link: 'https://youtube.com/@niraskin', followers: 41200, enabled: true, source: 'connected' }],
      rates: [{ platform: 'tiktok', formatKey: 'short', price: 35000 }, { platform: 'instagram', formatKey: 'reels', price: 25000 }, { platform: 'instagram', formatKey: 'story', price: 12000 }, { platform: 'youtube', formatKey: 'integrated', price: 18000 }],
      availability: { days: [1, 2, 3, 4, 5], slots: [3], provinces: ['กรุงเทพมหานคร', 'นนทบุรี'] } } };
  async function boot() {
    statusEl.textContent = BUNDLE ? 'กำลังโหลดตัววาด…' : 'กำลังโหลดตัววาดจาก sync-server…';
    try { lib = await loadLib(); }
    catch (e) { statusEl.innerHTML = '<b>โหลดตัววาดไม่ได้</b> — ' + esc(BUNDLE ? e.message : NO_LIB + ' แล้วรีเฟรช · ' + e.message); return; }
    profile = new lib.Profile(OWNER, {});
    statusEl.textContent = '';
    if (!load()) { choice = choice || lib.defaultChoice(); preset(); } else { choice = choice || lib.defaultChoice(); }
    if (!items.some(i => isPinned(i.kind)) && sealKind()) items.push(seal());
    log.push({ rev, t: 'เปิดการ์ด' });
    rebuildTray(); fitScale(); paint(); settle(); render(); renderMut();
  }
  window.addEventListener('resize', fitScale);
  let booted = false;
  const open = () => { if (!booted) { booted = true; boot(); } else { fitScale(); render(); renderMut(); } };
  window.addEventListener('play-open', open);
  if (location.hash === '#play') open();
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

# แท็บ "สีทำงานยังไง" (#color): hex ที่เลือก → token 6 × 3 พื้น (specPalette) → ทุกส่วนใน widget ที่วาดสด
TOKENS_CSS = '''
  /* ===== แท็บ สีทำงานยังไง ===== */
  #color { display:none; } body.color #color { display:block; } body.color #home, body.color article.wd { display:none !important; }
  #color h2.cx-h { font:700 22px/1.25 var(--display); margin:0 0 4px; display:flex; align-items:center; gap:10px; }
  #color h2.cx-h i { font:700 13px/1 var(--mono); font-style:normal; width:26px; height:26px; border-radius:50%; display:grid; place-items:center; background:var(--ink); color:var(--bg); flex:none; }
  #color .cx-sec { margin-top:34px; } #color .cx-sec > .lede { margin-bottom:14px; max-width:780px; }
  .cx-sw { --c:transparent; display:inline-block; width:18px; height:18px; border-radius:5px; flex:none; box-shadow:inset 0 0 0 1px rgba(0,0,0,.12);
           background:linear-gradient(var(--c),var(--c)), repeating-conic-gradient(#d4d4d4 0 25%, #fff 0 50%) 0 0/8px 8px; }
  .cx-sw.lg { width:34px; height:34px; border-radius:9px; }
  code.cx-tok { font:600 11.5px var(--mono); padding:2px 7px; border-radius:6px; background:var(--chip); white-space:nowrap; }
  .cx-on { font:600 10.5px var(--mono); padding:1px 6px; border-radius:999px; border:1px solid var(--line); color:var(--mute); white-space:nowrap; }
  .cx-on.card { background:#1a1f35; color:#dfe3f5; border-color:#1a1f35; } .cx-on.light { background:#f6f0e6; color:#5b4a2c; border-color:#e5dccb; } .cx-on.dark { background:#4a1d2b; color:#f5e4e9; border-color:#4a1d2b; }
  .cx-on.fixed { border-style:dashed; }
  /* แผนภาพ 4 กล่อง */
  .cx-flow { display:grid; grid-template-columns:repeat(4, minmax(0,1fr)); gap:14px; }
  .cx-step { position:relative; background:var(--paper); border:1px solid var(--line); border-radius:14px; padding:12px 14px 14px; min-width:0; display:flex; flex-direction:column; gap:4px; }
  .cx-step:not(:last-child)::after { content:"→"; position:absolute; right:-13px; top:22px; color:var(--faint); font-size:15px; }
  .cx-step > b { font:600 15px/1.3 var(--display); display:flex; align-items:center; gap:7px; }
  .cx-step > b i { font:700 11px/1 var(--mono); font-style:normal; width:20px; height:20px; border-radius:50%; display:grid; place-items:center; border:1.5px solid currentColor; flex:none; }
  .cx-step > p { margin:0; color:var(--mute); font-size:12.5px; line-height:1.5; } .cx-step > p code { font-size:11.5px; }
  .cx-body { margin-top:8px; display:flex; flex-wrap:wrap; gap:6px; align-items:flex-start; }
  .cx-hex { display:inline-flex; align-items:center; gap:7px; } .cx-hex code { font:600 12.5px var(--mono); }
  .cx-tp { flex:1; min-width:58px; text-align:center; font:600 12.5px var(--display); padding:14px 4px; border-radius:9px; box-shadow:inset 0 0 0 1px rgba(127,127,127,.25); }
  .cx-g18 { display:grid; grid-template-columns:auto repeat(3, 1fr); gap:4px 6px; align-items:center; width:100%; }
  .cx-g18 code { font:11px var(--mono); color:var(--mute); padding-right:6px; } .cx-g18 em { font:600 11px var(--display); font-style:normal; color:var(--mute); text-align:center; }
  .cx-g18 > span { display:flex; justify-content:center; } .cx-g18 > span[data-r] { cursor:default; }
  .cx-mini { flex:1; min-width:70px; border-radius:9px; padding:8px; display:flex; flex-direction:column; gap:3px; box-shadow:inset 0 0 0 1px rgba(127,127,127,.25); }
  .cx-mini b { font:700 12.5px/1.2 var(--display); } .cx-mini small { font-size:10px; } .cx-mini > i { height:1px; margin:2px 0; }
  .cx-mini span { display:flex; align-items:center; gap:4px; } .cx-mini em { font-size:9.5px; font-style:normal; padding:1px 6px; border-radius:999px; } .cx-mini strong { font:700 12px var(--display); }
  @media (max-width:980px) { .cx-flow { grid-template-columns:repeat(2, minmax(0,1fr)); } .cx-step:nth-child(2)::after { display:none; } }
  @media (max-width:560px) { .cx-flow { grid-template-columns:minmax(0,1fr); } .cx-step::after { display:none; } }
  .cx-pick { margin-bottom:18px; } .cx-pick .bt { border-radius:14px; }
  @media (min-width:900px) and (min-height:900px) { .cx-pick { position:sticky; top:50px; z-index:6; } }
  /* ลองดูใน widget */
  .cx-a { display:grid; grid-template-columns:minmax(0,1.1fr) minmax(0,1fr); gap:16px; align-items:start; }
  @media (max-width:900px) { .cx-a { grid-template-columns:minmax(0,1fr); } }
  .cx-box { background:var(--paper); border:1px solid var(--line); border-radius:16px; padding:14px; min-width:0; }
  .cx-ctl { display:flex; flex-wrap:wrap; gap:8px 14px; align-items:center; margin-bottom:10px; font-size:13px; }
  .cx-ctl label { color:var(--mute); font-size:12.5px; } .cx-ctl select { font:14px var(--body); padding:6px 8px; border-radius:9px; border:1px solid var(--line); background:var(--bg); color:var(--ink); max-width:100%; }
  .cx-seg { display:inline-flex; background:var(--chip); border-radius:999px; padding:2px; } .cx-seg button { border:0; background:transparent; font:600 12.5px var(--body); padding:5px 11px; border-radius:999px; color:var(--mute); cursor:pointer; }
  .cx-seg button.on { background:var(--paper); color:var(--ink); box-shadow:0 0 0 1px var(--line); }
  .cx-stage { position:relative; border-radius:12px; overflow:hidden; display:grid; place-items:center; background:#202024; min-height:260px; transition:background .2s; }
  .cx-stage .cx-w { position:relative; } .cx-stage .cx-in { position:absolute; left:0; top:0; transform-origin:0 0; }
  .cx-hl { position:absolute; pointer-events:none; border:2px solid #ffd36b; border-radius:4px; box-shadow:0 0 0 2px rgba(0,0,0,.45), 0 0 18px rgba(255,211,107,.55); transition:all .12s; }
  .cx-hl.soft { border-color:rgba(255,211,107,.85); box-shadow:0 0 0 1px rgba(0,0,0,.35); }
  .cx-tip { position:absolute; pointer-events:none; z-index:3; background:rgba(16,16,20,.94); color:#eee; font:12px/1.45 var(--body); padding:7px 9px; border-radius:9px; max-width:240px; }
  .cx-tip code { font-size:11px; color:#ffd36b; }
  .cx-note { font-size:12.5px; color:var(--mute); margin:10px 0 0; line-height:1.5; } .cx-note b { color:var(--ink); }
  .cx-parts { list-style:none; margin:8px 0 0; padding:0; max-height:420px; overflow:auto; border-top:1px solid var(--line); }
  .cx-parts li { display:grid; grid-template-columns:18px minmax(0,1fr) auto auto; gap:8px; align-items:center; padding:7px 6px; border-bottom:1px solid var(--line); cursor:pointer; font-size:13.5px; border-radius:8px; }
  .cx-parts li:hover { background:var(--bg); } .cx-parts li.on { background:color-mix(in srgb, #ffd36b 22%, var(--paper)); }
  .cx-parts .pl { min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; } .cx-parts .pl small { color:var(--faint); margin-left:6px; font-size:12px; }
  .cx-parts .grp { display:block; cursor:default; padding:10px 6px 4px; font:600 12px var(--display); color:var(--mute); border-bottom:0; } .cx-parts .grp:hover { background:none; }
  /* token ของใบ */
  .cx-sum { display:flex; flex-wrap:wrap; align-items:center; gap:6px 10px; font-size:14px; padding:2px 2px 10px; }
  .cx-sum .pk { display:inline-flex; align-items:center; gap:6px; font:12px var(--mono); } .cx-sum .ar { color:var(--faint); } .cx-sum b { font:700 18px var(--display); }
  .cx-toks { list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:4px; }
  .cx-toks li { display:grid; grid-template-columns:18px auto auto minmax(0,1fr) auto; gap:8px; align-items:center; padding:6px 8px; border-radius:9px; background:var(--bg); border:1px solid var(--line); cursor:pointer; font-size:13px; }
  .cx-toks li:hover { border-color:var(--faint); } .cx-toks li.on { border-color:#e0b43f; background:color-mix(in srgb, #ffd36b 16%, var(--paper)); }
  .cx-toks .hx { font:11.5px var(--mono); color:var(--mute); } .cx-toks .al { font-family:var(--body); color:var(--faint); } .cx-toks .n { font-size:12px; color:var(--faint); white-space:nowrap; }
  .cx-sub { font:600 12px var(--display); color:var(--mute); margin:14px 0 6px; }
'''

TOKENS_HTML = '''
<section id="color" aria-label="สีทำงานยังไง">
  <header class="top ptop">
    <div class="eyebrow">Star Card · สี</div>
    <h1>สีทำงานยังไง</h1>
  </header>
  <div class="cx-pick" id="cxpick"><p class="mut">กำลังโหลดตัววาด…</p></div>
  <div class="cx-sec" style="margin-top:0">
    <div id="cxdia"></div>
  </div>
  <div class="cx-sec">
    <h2 class="cx-h">ใน widget</h2>
    <div class="cx-a">
      <div class="cx-box">
        <div class="cx-ctl"><label for="cxk">widget</label><select id="cxk"></select><span id="cxsurf"></span></div>
        <div class="cx-stage" id="cxstage"></div>
        <p class="cx-note" id="cxnote"></p>
      </div>
      <div class="cx-box">
        <div id="cxchain"></div>
        <ul class="cx-parts" id="cxparts"></ul>
      </div>
    </div>
  </div>
</section>'''

TOKENS_JS = r'''
// ---------- สีทำงานยังไง: hex ที่เลือก → token 6 บทบาท × 3 พื้น (specPalette) → ทุกส่วนใน widget ----------
// ตัวคิดทุกตัวคือของตัววาดเว็บ (sync-server/web/js) — ส่วนที่ตัววาดวาดจริงถือกล่องของตัวเองไว้ที่ `el.__spec` · ตัวแปลงของใบอยู่ที่ `host.__palette`
(() => {
  const sec = document.getElementById('color'); if (!sec) return;
  const $ = (id) => document.getElementById(id);
  const KEY = 'sc-cat-tokens-v1';
  const ROLES = ['bg', 'bg2', 'ink', 'ink2', 'accent', 'line'];
  const ROLE = { bg: ['พื้น', 'พื้นของแผ่นที่ส่วนนั้นนั่ง'], bg2: ['พื้นรอง', 'กล่องย่อย ชิป แถบหัว · คำตัวใหญ่ฉากหลัง'], ink: ['หมึก', 'ตัวหนังสือหลัก ไอคอน'],
    ink2: ['หมึกจาง', 'ป้าย ตัวรอง คำอธิบาย'], accent: ['สีเน้น', 'ตัวเลขเด่น จุดเน้น'], line: ['เส้น', 'เส้นขอบ เส้นคั่น'] };
  const SURF = { card: ['บนการ์ด', 'ไม่มีแผ่นของตัวเอง — ตัวหนังสือวางบนพื้นการ์ดตรง ๆ ใช้หมึกของการ์ดแล้วปรับแค่ความทึบ'],
    light: ['แผ่นสว่าง', 'กระดาษครีมของใบ — สีเดียวอมเฉดของสีที่เลือก · คู่สี = สีอ่อนของคู่ หมึก = สีเข้ม'],
    dark: ['แผ่นเข้ม', 'แผ่นอิ่มสีของใบ — สีเดียวคิดจากเฉด · คู่สี = สีเข้มของคู่ หมึก = สีอ่อน'] };
  const LIVE_FLAGS = new Set(['ink.light', 'bordered', 'papered', 'duo', 'kit.dark']);
  const BOX = { glass: 'กระจก', dim: 'เข้ม', clear: 'ไม่มีพื้น', pane: 'กระจก (chrome)' };
  const WHERE = { fill: 'พื้น', fillCycle: 'พื้น', gradient: 'ไล่สี', stroke: 'เส้นขอบ', color: 'ตัวหนังสือ', tint: 'ไอคอน', shadow: 'เงา', pattern: 'ลาย', platePattern: 'ลายแผ่น' };
  const esc = (s) => String(s ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
  const short = (s, n = 18) => { s = String(s ?? '').replace(/\s+/g, ' ').trim(); return s.length > n ? s.slice(0, n - 1) + '…' : s; };
  const f2 = (v) => (+v).toFixed(2), deg = (h) => Math.round(h * 360) + '°', pct = (a) => Math.round(a * 100) + '%';

  let lib = null, T = null, choice = null, kind = null, surf = null, built = false;
  let theme = null, palette = null, parts = [], rows = [], selRow = 0, B = null;
  try { const s = JSON.parse(localStorage.getItem(KEY)); if (s) { choice = s.choice || null; kind = s.kind || null; surf = s.surf || null; } } catch (e) {}
  const save = () => { try { localStorage.setItem(KEY, JSON.stringify({ choice, kind, surf })); } catch (e) {} };

  const hexA = (c) => T.hexOf(c) + (c.a < 0.999 ? ' · ' + pct(c.a) : '');
  const sw = (c, cls = '') => `<span class="cx-sw ${cls}" style="--c:${lib.css(c)}" title="${hexA(c)}"></span>`;
  const tokChip = (tok) => `<code class="cx-tok">${esc(tok)}</code>`;
  const onPill = (s) => `<span class="cx-on ${s}">${s === 'fixed' ? 'ตายตัว' : s}</span>`;

  // สีที่ user เลือก (hex ใน doc)
  const bases = (t) => ({ primary: { c: t.primary }, secondary: t.secondary ? { c: t.secondary } : null });

  // ---------- ส่วนของ widget ที่ตัววาดวาดจริง ----------
  function refsOf(b) {
    const n = b.node, out = [];
    if (n.type === 'text') { out.push(['color', n.color ?? 'ink']); if (n.shadow) out.push(['shadow', n.shadow.color]); return out; }
    if (n.type === 'icon') { if (n.tint) out.push(['tint', n.tint]); return out; }
    const cyc = n.fillCycle?.length && b.item ? n.fillCycle[b.item.i % n.fillCycle.length] : null;
    const fill = cyc ?? n.fill ?? (n.type === 'line' ? 'ink@0.12' : null);
    if (typeof fill === 'string') out.push([cyc ? 'fillCycle' : 'fill', fill]);
    if (n.gradient) { out.push(['gradient', n.gradient.from]); out.push(['gradient', n.gradient.to]); }
    if (n.stroke?.color) out.push(['stroke', n.stroke.color]);
    if (n.pattern) { out.push(['pattern', n.pattern.color]); if (n.pattern.color2) out.push(['pattern', n.pattern.color2]); }
    if (n.platePattern) out.push(['platePattern', n.platePattern]);
    if (n.shadow) out.push(['shadow', n.shadow.color]);
    return out.filter(([, t]) => typeof t === 'string');
  }
  function label(b) {
    const n = b.node, nm = n.slot ? (SLOT_TH[n.slot] || n.slot) : n.id || '';
    if (n.type === 'text') return (nm ? nm + ' ' : '') + '“' + short(b.text?.string || n.text || '') + '”';
    if (n.type === 'icon') return 'ไอคอน ' + short(n.icon || nm, 22);
    if (n.type === 'image') return 'รูป ' + nm;
    if (n.type === 'line') return 'เส้นคั่น ' + nm;
    if (b.id === 'r') return 'พื้นทั้งใบ';
    return (n.type === 'chips' ? 'ชิป ' : 'กล่อง ') + nm;
  }
  const surfOf = (tok, n) => {
    const name = tok.split('@')[0];
    if (tok.startsWith('$') || !ROLES.includes(name)) return 'fixed';
    const ex = ['card', 'light', 'dark'].includes(n.on) ? n.on : null;
    return ex ?? (palette.pal.noSheet ? 'card' : palette.pal.base);
  };

  function collect(host) {
    const all = [...host.querySelectorAll('*')];
    const palHost = all.find((e) => e.__palette); palette = palHost ? palHost.__palette : null;
    const byNode = new Map();
    for (const e of all) { const b = e.__spec; if (!b) continue; if (!byNode.has(b.node)) byNode.set(b.node, { b, els: [] }); byNode.get(b.node).els.push(e); }
    parts = []; rows = [];
    if (!palette) return;
    for (const { b, els } of byNode.values()) {
      const refs = refsOf(b); if (!refs.length) continue;
      const p = { b, els, label: label(b), rows: [] }; parts.push(p);
      const seen = new Set();
      for (const [where, tok] of refs) {
        const key = where + '|' + tok; if (seen.has(key)) continue; seen.add(key);
        const s = surfOf(tok, b.node), c = palette.colorObj(tok, b.node.on, b.item);
        const r = { p, where, tok, s, c, i: rows.length }; rows.push(r); p.rows.push(r);
      }
    }
  }

  // ---------- วาด ----------
  const stage = $('cxstage');
  let hl = [], tip = null;
  function clearHL() { hl.forEach((x) => x.remove()); hl = []; }
  function outline(els, soft) {
    const sr = stage.getBoundingClientRect();
    for (const e of els) {
      const r = e.getBoundingClientRect(); if (r.width < 1 && r.height < 1) continue;
      const d = document.createElement('div'); d.className = 'cx-hl' + (soft ? ' soft' : '');
      d.style.cssText = `left:${r.left - sr.left - 3}px;top:${r.top - sr.top - 3}px;width:${r.width + 6}px;height:${r.height + 6}px`;
      stage.appendChild(d); hl.push(d);
    }
  }
  function select(i, scroll) {
    const r = rows[i]; if (!r) { $('cxchain').innerHTML = '<p class="mut">ใบนี้ไม่มีส่วนที่ใช้ token สี</p>'; return; }
    selRow = i;
    document.querySelectorAll('#cxparts li[data-i]').forEach((li) => li.classList.toggle('on', +li.dataset.i === i));
    if (scroll) document.querySelector(`#cxparts li[data-i="${i}"]`)?.scrollIntoView({ block: 'nearest' });
    clearHL(); outline(r.p.els);
    document.querySelectorAll('#cxchain li[data-t]').forEach((li) => li.classList.toggle('on', li.dataset.t === keyOf(r)));
  }
  // token ที่สีที่เลือกถูกแปลงออกมาในใบนี้ — นับ (บทบาท × พื้น) ไม่ซ้ำ · `@ความทึบ` เป็นแค่การใช้ token เดิมที่จางลง จึงรวมแถวเดียว
  // สีตายตัว/จากข้อมูลไม่แสดงในรายการนี้ เพราะไม่ได้มาจากสีที่เลือก
  let toks = [];
  const keyOf = (r) => (r.s === 'fixed' ? r.tok : r.tok.split('@')[0]) + '|' + r.s;
  function renderTokens() {
    const by = new Map();
    for (const r of rows) {
      const k = keyOf(r), name = r.s === 'fixed' ? r.tok : r.tok.split('@')[0];
      if (!by.has(k)) by.set(k, { k, tok: name, s: r.s, c: r.s === 'fixed' ? r.c : palette.colorObj(name, r.s === 'card' ? 'card' : r.s, r.p.b.item), rows: [], alphas: new Set() });
      const t = by.get(k); t.rows.push(r); if (r.s !== 'fixed' && r.tok.includes('@')) t.alphas.add(r.tok.split('@')[1]);
    }
    const SO = { light: 0, dark: 1, card: 2, fixed: 3 }, ro = (t) => { const i = ROLES.indexOf(t.split('@')[0]); return i < 0 ? 99 : i; };
    toks = [...by.values()].sort((a, b) => SO[a.s] - SO[b.s] || ro(a.tok) - ro(b.tok) || a.tok.localeCompare(b.tok));
    const mine = toks.filter((t) => t.s !== 'fixed');
    const pick = [B.primary.c].concat(B.secondary ? [B.secondary.c] : []);
    const li = (t) => `<li data-t="${esc(t.k)}">${sw(t.c)}${tokChip(t.tok)}${onPill(t.s)}<span class="hx">${hexA(t.c)}${t.alphas.size ? ` <span class="al">ใช้จางด้วย ${[...t.alphas].map((a) => '@' + a).join(' ')}</span>` : ''}</span><span class="n">${t.rows.length} ส่วน</span></li>`;
    $('cxchain').innerHTML = `<div class="cx-sum"><span class="mut">สีที่เลือก</span>${pick.map((c) => `<span class="pk">${sw(c)}${T.hexOf(c)}</span>`).join('')}<span class="ar">→</span><b>${mine.length} token</b><span class="mut">ในใบนี้</span></div>` +
      `<ul class="cx-toks">${mine.map(li).join('') || '<li class="mut">ใบนี้ไม่ได้ใช้สีจากสีที่เลือก</li>'}</ul>` +
      '<div class="cx-sub">แต่ละส่วนใช้ token ไหน</div>';
  }
  function renderParts() {
    const ul = $('cxparts');
    const groups = { light: [], dark: [], card: [], fixed: [] };
    rows.forEach((r) => groups[r.s].push(r));
    const GT = { light: 'บนแผ่นสว่าง (light)', dark: 'บนแผ่นเข้ม (dark)', card: 'บนการ์ด (card)', fixed: 'สีตายตัว / จากข้อมูล' };
    ul.innerHTML = Object.entries(groups).filter(([, rs]) => rs.length).map(([g, rs]) => `<li class="grp">${GT[g]} · ${rs.length}</li>` +
      rs.map((r) => `<li data-i="${r.i}">${sw(r.c)}<span class="pl">${esc(r.p.label)}<small>${WHERE[r.where]}</small></span>${tokChip(r.tok)}${onPill(r.s)}</li>`).join('')).join('')
      || '<li class="grp">ใบนี้ไม่ได้ใช้ token สี</li>';
  }
  let drawGen = 0;
  async function drawWidget() {
    const spec = lib.specs[kind]; if (!spec) return;
    const gen = ++drawGen;   // กดเร็ว ๆ หลายครั้ง → รอบเก่าที่ยังรอ fixture ทิ้งไป ไม่เขียนทับรอบใหม่
    const surfaces = spec.widget?.surfaces?.length ? spec.widget.surfaces : ['glass'];
    if (!surfaces.includes(surf)) surf = surfaces[0];
    $('cxsurf').innerHTML = surfaces.length > 1 ? '<label>กล่อง</label> <span class="cx-seg">' + surfaces.map((s) => `<button type="button" data-s="${s}" class="${s === surf ? 'on' : ''}">${esc(spec.widget?.surfaceNames?.[s] || BOX[s] || s)}</button>`).join('') + '</span>' : '';
    const W = spec.design.w, H = spec.design.h, M = 10, CW = W + M * 2, CH = H + M * 2;
    const k = Math.max(0.5, Math.min(1.7, (stage.clientWidth - 24) / CW, 560 / CH));
    stage.innerHTML = '';
    const wrap = document.createElement('div'); wrap.className = 'cx-w'; wrap.style.cssText = `width:${CW * k}px;height:${CH * k}px;margin:12px`;
    const inner = document.createElement('div'); inner.className = 'cx-in'; inner.style.cssText = `width:${CW}px;height:${CH}px;transform:scale(${k})`;
    wrap.appendChild(inner); stage.appendChild(wrap);
    // ไม่วาดพื้นการ์ด — widget ลอยบนเวทีกลาง ๆ (เทาอ่อนเมื่อหมึกการ์ดมืด · เทาเข้มเมื่อหมึกขาว ให้ตัวหนังสือบนการ์ดยังอ่านออก)
    stage.style.background = theme.inkStyle.isLight ? '#E6E6EA' : '#202024';
    const fx = await lib.fixture(kind);
    if (gen !== drawGen) return;
    const profile = new lib.Profile({}, {});
    const item = { id: '00000000-0000-0000-0000-000000000000', kind, x: M, y: M, w: W, h: H, surface: surf, border: false };
    // ข้อความ/รายการ = ค่าที่ iOS บันทึกไว้ · เงื่อนไขที่ขึ้นกับกล่องหรือสี (papered · duo · ink.light …) คิดสดจากที่เลือก — fixture จดไว้ใต้ธีมตั้งต้น + กล่องแรก
    const live = new lib.WebSpecData({ profile, item, sample: true, surface: surf, inkLight: surf === 'dim' ? false : theme.inkStyle.isLight, duo: !!theme.activeDuo, kitDark: spec.widget?.on === 'dark' });
    const replay = () => { const d = new lib.ReplayData(fx.data, live), own = d.flag.bind(d); d.flag = (n) => (LIVE_FLAGS.has(n) || n.startsWith('surface=') || n.startsWith('cfg:') ? live.flag(n) : own(n)); return d; };
    const env = { doc: { photos: {}, owner: {}, notes: {} }, theme, profile, specs: lib.specs, measurer: lib.measurer, base: lib.base, imageURL: lib.imageURL,
      makeData: fx ? replay : null };
    try { lib.mountWidget(inner, item, { x: M, y: M, width: W, height: H }, env); } catch (e) { inner.innerHTML = `<pre style="color:#f77">${esc(e.message)}</pre>`; }
    collect(inner);
    const base = spec.widget?.on || 'card';
    $('cxnote').innerHTML = `Type ${onPill(base)}` + (palette?.pal.noSheet && base !== 'card' ? ` → ${onPill('card')} (ไม่มีพื้น)` : '');
    renderParts();
    renderTokens();
    select(Math.min(selRow, rows.length - 1), false);
  }

  // ---------- ขั้น 1 · 2 · 3 + สายพาน ----------
  // ---------- แผนภาพ 4 กล่อง: hex ที่เลือก → 3 Types → 6 Tokens ต่อ Type → รวมกันใน widget ----------
  const TYPE = { card: 'Card', light: 'Light', dark: 'Dark' };
  const TYPES = ['card', 'light', 'dark'];
  function renderDiagram() {
    const pal = lib.specPalette({ t: theme, ink: theme.inkStyle, accent: theme.accent, surface: 'glass', skin: null, kit: {}, border: false, base: 'card' });
    const C = (r, s) => lib.css(pal.color(r, s)), bd = theme.backdropColors;
    const cardBg = `linear-gradient(${lib.css(bd.top)},${lib.css(choice.backdrop === 'gradient' ? bd.bottom : bd.top)})`;
    const pick = [B.primary.c].concat(B.secondary ? [B.secondary.c] : []);
    const bgOf = (s) => (s === 'card' ? cardBg : C('bg', s));
    const box = (n, title, sub, body) => `<div class="cx-step"><b><i>${n}</i>${title}</b><p>${sub}</p><div class="cx-body">${body}</div></div>`;
    $('cxdia').innerHTML = '<div class="cx-flow">' + [
      box(1, 'hex ที่เลือก', `user เลือก${pick.length > 1 ? 'คู่สี 2 สี' : 'สีเดียว'} · API เก็บแค่ hex นี้ ไม่มี token`,
        pick.map((c) => `<span class="cx-hex">${sw(c, 'lg')}<code>${T.hexOf(c)}</code></span>`).join('')),
      box(2, '3 Types ของ widget', 'Card · Light · Dark — คนทำ widget เลือกใน JSON (<code>widget.on</code>) ว่าใบนั้นนั่งบน Type ไหน',
        TYPES.map((s) => `<span class="cx-tp" style="background:${bgOf(s)};color:${C('ink', s)}">${TYPE[s]}</span>`).join('')),
      box(3, '6 Tokens ต่อ Type = 18 สี', 'bg · bg2 · ink · ink2 · accent · line — ผังของ widget อ้างแค่ชื่อพวกนี้ ตัววาดเติมสีตาม Type',
        `<div class="cx-g18"><span></span>${TYPES.map((s) => `<em>${TYPE[s]}</em>`).join('')}` +
        ROLES.map((r) => `<code>${r}</code>` + TYPES.map((s) => `<span data-s="${s}" data-r="${r}" title="${TYPE[s]} · ${r} · ${hexA(pal.color(r, s))}">${sw(pal.color(r, s))}</span>`).join('')).join('') + '</div>'),
      box(4, 'รวมกัน = สีใน widget', 'พื้นใช้ bg · ตัวหนังสือใช้ ink/ink2 · ป้ายใช้ bg2 · ตัวเลขเด่นใช้ accent · เส้นใช้ line',
        TYPES.map((s) => `<div class="cx-mini" style="background:${bgOf(s)}"><b style="color:${C('ink', s)}">${TYPE[s]}</b><small style="color:${C('ink2', s)}">@handle</small><i style="background:${C('line', s)}"></i><span><em style="background:${C('bg2', s)};color:${C('ink', s)}">Tag</em><strong style="color:${C('accent', s)}">58.3K</strong></span></div>`).join('')),
    ].join('') + '</div>';
  }

  function buildTray() {
    lib.buildTray($('cxpick'), choice, () => { save(); buildTray(); redraw(); });
  }
  async function redraw() {
    theme = lib.themeOf(choice); B = bases(theme);
    await drawWidget();
    renderDiagram();
  }

  async function boot() {
    try { lib = await loadLib(); } catch (e) { $('cxpick').innerHTML = `<p class="mut">${esc((BUNDLE ? 'โหลดตัววาดไม่ได้: ' : NO_LIB + ': ') + e.message)}</p>`; return; }
    T = lib.theme;
    if (!choice) choice = { ...lib.defaultChoice(), primary: '#3D5AFE' };
    const ks = PLAY.filter((p) => lib.specs[p.k]);
    if (!kind || !lib.specs[kind]) kind = lib.specs.aboutEditorial ? 'aboutEditorial' : ks[0].k;
    const groups = {}; ks.forEach((p) => (groups[p.cl] ??= []).push(p));
    const sel = $('cxk');
    sel.innerHTML = Object.entries(groups).map(([g, ps]) => `<optgroup label="${esc(g)}">` + ps.map((p) => `<option value="${p.k}">${esc(p.t)} · ${p.k}</option>`).join('') + '</optgroup>').join('');
    sel.value = kind;
    sel.onchange = () => { kind = sel.value; selRow = 0; save(); redraw(); };
    $('cxsurf').addEventListener('click', (e) => { const b = e.target.closest('button[data-s]'); if (!b) return; surf = b.dataset.s; selRow = 0; save(); redraw(); });
    $('cxparts').addEventListener('click', (e) => { const li = e.target.closest('li[data-i]'); if (li) select(+li.dataset.i, false); });
    $('cxparts').addEventListener('mouseover', (e) => { const li = e.target.closest('li[data-i]'); if (!li) return; const r = rows[+li.dataset.i]; clearHL(); outline(rows[selRow]?.p.els || []); if (r && r !== rows[selRow]) outline(r.p.els, true); });
    $('cxparts').addEventListener('mouseleave', () => { clearHL(); outline(rows[selRow]?.p.els || []); });
    // ชี้ token → ทุกส่วนที่ใช้ token นั้น · แตะ = เลือกส่วนแรกของมัน
    $('cxchain').addEventListener('mouseover', (e) => { const li = e.target.closest('li[data-t]'); if (!li) return; const t = toks.find((t) => t.k === li.dataset.t); clearHL(); if (t) outline(t.rows.flatMap((r) => r.p.els)); });
    $('cxchain').addEventListener('mouseleave', () => { clearHL(); outline(rows[selRow]?.p.els || []); });
    $('cxchain').addEventListener('click', (e) => { const li = e.target.closest('li[data-t]'); if (!li) return; const t = toks.find((t) => t.k === li.dataset.t); if (t) select(t.rows[0].i, true); });
    // ชี้บน widget → ส่วนที่ลึกที่สุดที่ใช้สี
    const hit = (e) => { let x = e.target; while (x && x !== stage) { if (x.__spec) { const p = parts.find((p) => p.els.includes(x)); if (p) return p; } x = x.parentElement; } return null; };
    stage.addEventListener('mousemove', (e) => {
      const p = hit(e); tip?.remove(); tip = null; clearHL(); outline(rows[selRow]?.p.els || []);
      if (!p) return;
      if (rows[selRow]?.p !== p) outline(p.els, true);
      const sr = stage.getBoundingClientRect();
      tip = document.createElement('div'); tip.className = 'cx-tip';
      tip.innerHTML = `<b>${esc(p.label)}</b><br>` + p.rows.map((r) => `${WHERE[r.where]} <code>${esc(r.tok)}</code> บน ${r.s === 'fixed' ? 'ตายตัว' : r.s}`).join('<br>');
      tip.style.left = Math.min(e.clientX - sr.left + 14, sr.width - 250) + 'px'; tip.style.top = (e.clientY - sr.top + 14) + 'px';
      stage.appendChild(tip);
    });
    stage.addEventListener('mouseleave', () => { tip?.remove(); tip = null; clearHL(); outline(rows[selRow]?.p.els || []); });
    stage.addEventListener('click', (e) => { const p = hit(e); if (p) select(p.rows[0].i, true); });
    // ชี้แถวในตาราง 3 พื้น → ไฮไลต์ทุกจุดในใบที่ใช้ token นั้น
    // ชี้ token ในแผนภาพ → ทุกจุดใน widget ที่ใช้ token นั้น
    $('cxdia').addEventListener('mouseover', (e) => { const li = e.target.closest('[data-r]'); if (!li) return; clearHL(); outline(rows.filter((x) => x.s === li.dataset.s && x.tok.split('@')[0] === li.dataset.r).flatMap((x) => x.p.els), true); });
    $('cxdia').addEventListener('mouseleave', () => { clearHL(); outline(rows[selRow]?.p.els || []); });
    let rt = 0; addEventListener('resize', () => { if (!document.body.classList.contains('color')) return; clearTimeout(rt); rt = setTimeout(() => drawWidget(), 200); });
    buildTray(); await redraw();
  }
  const open = () => { if (!built) { built = true; boot(); } };
  window.addEventListener('color-open', open);
  if (location.hash === '#color') open();
})();
'''

def main():
    specs = [json.load(open(f)) for f in sorted(glob.glob(os.path.join(SPECS, '*.json')))]
    cm = json.load(open(os.path.join(ROOT, 'shared/category-models.json')))
    SAMPLE.update(load_sample())
    bycat = collections.defaultdict(list)
    for s in specs: bycat[s['widget']['category']].append(s)
    # ลำดับในหมวด = ตู้ iOS (`WidgetGallery.orderedEntries`): ชุดห้าสไตล์ (kit) ขึ้นก่อน แล้วค่อยตาม order
    for c in bycat: bycat[c].sort(key=lambda s: (not s['widget'].get('kit'), s['widget'].get('order', 10**9), s['kind']))
    cats = [c for c in ORDER if bycat.get(c)]
    groups = collections.OrderedDict((g, []) for g, _l in TRAY)
    for c in cats: groups[TRAY_OF[c]].append(c)
    groups = collections.OrderedDict((g, cs) for g, cs in groups.items() if cs)
    TRAY_TH = dict(TRAY)
    pairs = set()
    for s0 in specs:
        base0 = s0['widget'].get('on') or 'card'
        surf0 = default_surface(s0['widget'])
        def _v(n, base0=base0, surf0=surf0):
            explicit = n.get('on') if n.get('on') in SURF_TH else ''
            for tok, _w in colour_refs(n):
                name = tok.split('@')[0]
                if not tok.startswith('$') and not name.startswith('#') and name not in ('white', 'black', 'clear'): pairs.add((surf0, base0, explicit, tok))
        walk_nodes([s0['root'], s0.get('variants') or []], _v)
    PAL.update(load_palette(list(pairs)))
    imgs, index, details, nav, play, rdat = {}, [], [], [], [], {}
    for g, cs in groups.items():
        gk = GROUP_KEY[cs[0]]
        n_g = sum(len(bycat[c]) for c in cs)
        nav.append(f'<a class="g-{gk}" href="#cat-{g}">{TRAY_TH[g]}<small>{n_g}</small></a>')
        # หนึ่งชิป = หนึ่งหัวข้อ · ชิปที่รวมหลายหมวด (ผลงาน) แยกหัวข้อย่อยตามหมวดเหมือน section ในตู้ iOS
        index.append(f'<div class="grp g-{gk}" id="cat-{g}"><div class="gh">{TRAY_TH[g]}<code>{g}</code><span class="n">{n_g} widget</span></div>')
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
                cards.append(f'<div class="cw" data-k="{k}"><a class="card" href="#w/{k}"><span class="th"><img data-k="{k}" alt=""><button type="button" class="col-adj" title="ปรับสีเฉพาะใบนี้">ปรับ</button></span><b>{esc(w["title"])}</b><code>{k} <i class="surf">{w.get("on") or "card"}</i></code></a><div class="col-tray" hidden></div><span class="col-state"></span></div>')
            meta = [TIER_TH[TIER.get(c, 'personal')]] + ([f'ล็อกจนกรอก{LOCK[c]}'] if LOCK.get(c) else [])
            sub = len(cs) > 1
            index.append(f'<section class="cat{" sub" if sub else ""}" id="cat-{c}"><div class="ch">{f"<h2>{LABEL[c]}</h2>" if sub else ""}<code>{c}</code>{f"<span class=n>{len(items)} widget</span>" if sub else ""}'
                         f'<span class="cm">{" · ".join(meta)}</span></div><div class="cards">{"".join(cards)}</div></section>')
        index.append('</div>')
    page = f'''<!doctype html>
<html lang="th">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Star Card Widget Catalog</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Anuphan:wght@500;600;700&family=IBM+Plex+Sans+Thai:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>{CSS}{TOKENS_CSS}</style>
<nav class="tabs" aria-label="หน้า"><a href="#" data-tab="cat">Widget ทั้งหมด</a><a href="#play" data-tab="play">ลองวางการ์ด <small>ดูว่า API เก็บยังไง</small></a><a href="#color" data-tab="color">สีทำงานยังไง <small>hex → token → widget</small></a><a href="#render" data-tab="render">วิธีวาด <small>ข้อมูล merge ตรงไหน</small></a></nav>
<div class="page">
<div id="home">
  <header class="top">
    <div class="eyebrow">Star Card · Widget Catalog</div>
    <h1>Widget ทั้งหมด</h1>
    <p class="lede">{len(specs)} widget · {len(groups)} หัวข้อ (= ชิปในตู้ของแอป) · {len(cats)} หมวด · แตะ widget เพื่อดูว่าใช้ข้อมูลอะไร มาจากไหน</p>
    {COLOUR_HTML}
  </header>
  <nav class="cats" aria-label="ไปยังหมวด"><div class="ng">{"".join(nav)}</div></nav>
  {"".join(index)}
</div>
{"".join(details)}
{PLAY_HTML}
{TOKENS_HTML}
{RENDER_HTML}
</div>
<script>
const IMG = {json.dumps(imgs)};
const PLAY = {json.dumps(play, ensure_ascii=False)};
const RD = {json.dumps(rdat, ensure_ascii=False)};
const CATQ = {json.dumps({c: 'StarCard' + c[0].upper() + c[1:] + 'Model' for c in cats})};
const PRESETS = {json.dumps(load_presets())};
const SLOT_TH = {json.dumps(SLOT_TH, ensure_ascii=False)};
{JS}
{RENDER_JS}
</script>
<script type="module">
{LIB_JS}
{LIVE_JS}
{PLAY_JS}
{TOKENS_JS}
</script>
'''
    open(OUT, 'w', encoding='utf-8').write(page)
    print('wrote', os.path.relpath(OUT, ROOT), f'{os.path.getsize(OUT)//1024} KB · {len(specs)} widget · {len(cats)} หมวด')
    # ฝังตัววาดเว็บ + ผัง + ฟอนต์ + ไอคอน + fixture ลงไฟล์ → ส่งไฟล์เดียวให้ทีมอื่นแล้วปรับสี/ลองวางการ์ดได้โดยไม่ต้องเปิด sync-server
    r = subprocess.run(['node', os.path.join(ROOT, 'shared/tools/bundle-catalog.mjs')])
    if r.returncode: print('bundle-catalog.mjs ล้มเหลว — ไฟล์นี้ยังต้องเปิด sync-server ถึงปรับสีได้', file=sys.stderr)

main()
