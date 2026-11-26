# python3 present/verified-works-fill/fill.py — ผลงานยืนยัน 4 ใบ: ชิ้นงานโตตามที่ว่าง (26 พ.ย. 2569)
#
# ผู้ใช้: "พอมันมีชิ้นเดียว ไม่มีขยายใหญ่ตามพื้นที่ทั้งๆที่ทำได้" → ทุก widget ที่ร่วมงานกับ Sale Here
# เดิม: ชิ้นกว้าง/สูงตายตัว (78×110 ฯลฯ) หรือเพดานความสูงค่าเดียว (reelBrand maxH 212.4) → กรอบสูง/ชิ้นน้อย = ที่ว่างโล่ง
# ใหม่ (JSON ล้วน ไม่แตะ engine):
#   - แถวผลงานกินความสูงที่เหลือ (`h: fill`) · ชิ้นสูงเต็มแถว (`h: "100%"`) กว้างตามสัดส่วนเดิม (`aspect`) · รูป `grow: 1`
#   - เพดานความสูงแยกตามจำนวนชิ้น (สำเนาแถวละจำนวน `if: list:works=N`) = สูงสุดที่ N ชิ้นยังวางเรียงในความกว้างเดิมได้
#     → 4 ชิ้นที่กรอบออกแบบ = เท่าเดิมทุกพิกเซล · ชิ้นน้อย/กรอบสูง = ชิ้นโตจนชนขอบด้านใดด้านหนึ่ง
# อ่านจาก git HEAD เสมอ → รันซ้ำได้ผลเดิม
import copy, json, os, subprocess

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
DIR = 'shared/WidgetSpecs/12-ผลงานยืนยัน'
COUNTS = [(1, 'list:works=1'), (2, 'list:works=2'), (3, 'list:works=3'), (4, 'list:works>3')]


def head(kind):
    out = subprocess.run(['git', '-c', 'core.quotepath=off', 'show', f'HEAD:{DIR}/{kind}.json'], cwd=REPO, capture_output=True, check=True)
    return json.loads(out.stdout.decode('utf-8'))


def save(kind, j):
    with open(os.path.join(REPO, DIR, kind + '.json'), 'w', encoding='utf-8') as f:
        f.write(json.dumps(j, ensure_ascii=False, indent=1) + '\n')


def find(n, nid):
    if n.get('id') == nid: return n
    for c in n.get('children', []) + ([n['each']] if 'each' in n else []):
        r = find(c, nid)
        if r: return r
    return None


def parent_of(n, target):
    for i, c in enumerate(n.get('children', [])):
        if c is target: return n, i
        r = parent_of(c, target)
        if r: return r
    return None


def grow_photo(piece, pid='photo'):
    p = find(piece, pid)
    p.pop('h', None); p['grow'] = 1


def caps(total, gap, a, cap4=None):
    """เพดานความสูงของแถวเมื่อมี n ชิ้น — n ชิ้นกว้างเท่ากันรวม gap ไม่เกิน `total`"""
    out = {n: round(((total - gap * (n - 1)) / n) / a, 2) for n, _ in COUNTS}
    if cap4: out[4] = cap4
    return out


def per_count(works, cap, keep, extra=None):
    """สำเนาแถวผลงาน 1 ชุดต่อจำนวน — เก็บแค่ spot ที่ใช้ · เพดาน `maxH`"""
    rows = []
    for n, cond in COUNTS:
        r = copy.deepcopy(works)
        r['children'] = [c for c in r['children'] if keep(c) < n]
        r['if'] = cond; r['h'] = 'fill'; r['maxH'] = cap[n]
        if extra: extra(r, n)
        rows.append(r)
    return rows


def spot_index(c):
    return int(c['id'][4:])


# ── proofWork ─────────────────────────────────────────────────────────────
def proof_work():
    j = head('proofWork')
    root = j['root']
    works = find(root, 'works')
    a = round(78 / 167.13, 4)                      # ชิ้น 78 × แถว 167.13 ที่กรอบออกแบบ (342×230 หลังขอบกระจก)
    for s in works['children']:
        e = s['each']; e.pop('w', None); e['h'] = '100%'; e['aspect'] = a
        grow_photo(e)
    cap = caps(336, 8, a, 167.13)
    area = {'type': 'col', 'id': 'worksArea', 'h': 'fill', 'justify': 'center', 'align': 'stretch',
            'children': per_count(works, cap, spot_index)}
    root['children'][root['children'].index(works)] = area
    j['notes'] += (' · 26 พ.ย. 2569 โตตามที่ว่าง: แถวผลงาน (worksArea) กินความสูงที่เหลือแล้วจัดกึ่งกลาง · ชิ้นสูงเต็มแถว h 100% '
                   f'กว้างตาม aspect {a} · รูป grow · เพดานสูงต่อจำนวนชิ้น (สำเนาแถว if list:works=N) {cap} = N ชิ้นยังเรียงในกว้าง 336 · '
                   '4 ชิ้นที่ขนาดออกแบบเท่าเดิม · 1–3 ชิ้น/กรอบสูง = ชิ้นโตจนชนขอบ')
    save('proofWork', j)


# ── proofTicket ───────────────────────────────────────────────────────────
def proof_ticket():
    j = head('proofTicket')
    content = find(j['root'], 'content')
    ticket = find(content, 'ticket')
    works = find(ticket, 'works')
    a0 = round(85 / 154.71, 4)                     # ช่องแรก 85 × แถว 154.71
    a1 = round(86.2 / 154.71, 4)                   # ช่องถัดไป = รอยปรุ 1.2 + 85
    for s in works['children']:
        e = s['each']
        if e['type'] == 'col':
            e.pop('w', None); e['h'] = '100%'; e['aspect'] = a0; grow_photo(e)
        else:
            e['h'] = '100%'; e['aspect'] = a1
            piece = e['children'][1]; piece.pop('w', None); piece['w'] = 'fill'; grow_photo(piece)
    cap = {n: round(154.71 * 4 / n, 2) for n, _ in COUNTS}
    head_h = 66.79                                  # หัวตั๋ว + เส้นคั่น (ticket 221.5 − แถว 154.71)
    tickets = []
    for n, cond in COUNTS:
        t = copy.deepcopy(ticket)
        w = find(t, 'works')
        w['children'] = [c for c in w['children'] if spot_index(c) < n]
        w['h'] = 'fill'
        t['if'] = cond; t['h'] = 'fill'; t['maxH'] = round(head_h + cap[n], 2)
        tickets.append(t)
    content['children'] = tickets
    j['notes'] += (' · 26 พ.ย. 2569 โตตามที่ว่าง: ตั๋วสูงได้ถึงเต็มกรอบ (h fill · maxH = หัว 66.79 + เพดานแถว) จัดกึ่งกลาง · '
                   f'ช่องสูงเต็มแถว h 100% กว้างตาม aspect {a0} (ช่องมีรอยปรุ {a1}) · รูป grow · '
                   f'สำเนาตั๋วต่อจำนวนชิ้น (if list:works=N) เพดานแถว {cap} = N ช่องยังเต็มกว้าง 340 พอดี · 4 ชิ้นที่ขนาดออกแบบเท่าเดิม')
    save('proofTicket', j)


# ── wallPolaroid ──────────────────────────────────────────────────────────
def wall_polaroid():
    j = head('wallPolaroid')
    content = find(j['root'], 'content')
    works = find(content, 'works')
    holder, _ = parent_of(content, works)
    a = round(80 / 160.11, 4)                      # ชิ้น 80 × แถว 160.11
    for s in works['children']:
        e = s['each']; e.pop('w', None); e['h'] = '100%'; e['aspect'] = a
        find(e, 'polaroidFrame')['grow'] = 1
        grow_photo(e)
    cap = caps(344, 8, a, 160.11)
    holder['h'] = 'fill'                           # แถวหุ้ม (pad ข้าง 11) กินความสูงที่เหลือ · ชิดบนเสมอ (หมุดห้อยจากเชือก)
    holder['children'] = per_count(works, cap, spot_index)
    j['notes'] += (' · 26 พ.ย. 2569 โตตามที่ว่าง: แถวผลงานกินความสูงที่เหลือ ชิดบน (หมุดยังห้อยจากเชือก) · ชิ้นสูงเต็มแถว h 100% '
                   f'กว้างตาม aspect {a} · กรอบโพลารอยด์ + รูป grow · เพดานสูงต่อจำนวนชิ้น (สำเนาแถว if list:works=N) {cap} = '
                   'N ชิ้นยังเรียงในกว้าง 344 · 4 ชิ้นที่ขนาดออกแบบเท่าเดิม')
    save('wallPolaroid', j)


# ── reelBrand ─────────────────────────────────────────────────────────────
def reel_brand():
    j = head('reelBrand')
    a = 0.3861
    cap = caps(349, 7, a, 212.4)
    for content in [c for c in j['root']['children'] if c.get('id') == 'content']:
        cols = find(content, 'columns')
        i = content['children'].index(cols)
        rows = []
        for n, cond in COUNTS:
            r = copy.deepcopy(cols)
            r['if'] = cond; r['maxH'] = cap[n]
            rows.append(r)
        content['children'][i] = {'type': 'col', 'id': 'worksArea', 'h': 'fill', 'justify': 'center', 'align': 'stretch', 'children': rows}
    j['notes'] += (' · 26 พ.ย. 2569 โตตามที่ว่าง: เดิมเพดาน maxH 212.4 ค่าเดียว (1 เครื่องก็เล็กเท่า 4) → สำเนา columns ต่อจำนวนชิ้น '
                   f'(if list:works=N) เพดาน {cap} = N เครื่องยังเรียงในกว้าง 349 · แถวอยู่ใน worksArea (h fill) จัดกึ่งกลาง')
    save('reelBrand', j)


proof_work(); proof_ticket(); wall_polaroid(); reel_brand()
print('ok')
