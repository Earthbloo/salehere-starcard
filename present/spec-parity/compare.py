#!/usr/bin/env python3
"""เทียบผลของผัง JSON ชุดเดียวกันบน iOS กับ Android — ตัวเลข + ตัววัดตัวอักษร + ภาพ

    python3 -I compare.py <ios-Specs-dir> <android-Specs-dir> <out-dir>

<ios-Specs-dir>     = Documents/Specs ของซิม iOS (`-exportSpecs`)  — fixtures/*.json + cell-*.png
<android-Specs-dir> = files/Specs ของ Android (`--es exportSpecs 1`) — ข้อมูลที่ใช้วาดเล่นซ้ำจาก fixture ของ iOS
<out-dir>           = report.html + summary.json + cells/ (รูปสามช่อง iOS · Android · ต่าง)

ไม่มี dependency นอก stdlib (ถอด/เขียน PNG เอง)
"""
import json, os, sys, zlib, struct, html, shutil

# MARK: PNG

def read_png(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    pos = 8; w = h = None; ct = bd = None; idat = b''; plte = None
    while pos < len(data):
        ln, = struct.unpack('>I', data[pos:pos + 4]); typ = data[pos + 4:pos + 8]; body = data[pos + 8:pos + 8 + ln]
        pos += 12 + ln
        if typ == b'IHDR':
            w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', body)
            assert bd == 8 and il == 0, (path, bd, il)
        elif typ == b'IDAT': idat += body
        elif typ == b'PLTE': plte = body
        elif typ == b'IEND': break
    ch = {2: 3, 6: 4, 0: 1, 4: 2, 3: 1}[ct]
    raw = zlib.decompress(idat)
    stride = w * ch
    out = bytearray(h * w * 3)
    prev = bytearray(stride)
    i = 0
    for y in range(h):
        f = raw[i]; i += 1
        line = bytearray(raw[i:i + stride]); i += stride
        if f == 1:
            for x in range(ch, stride): line[x] = (line[x] + line[x - ch]) & 255
        elif f == 2:
            for x in range(stride): line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride): line[x] = (line[x] + ((line[x - ch] if x >= ch else 0) + prev[x]) // 2) & 255
        elif f == 4:
            for x in range(stride):
                a = line[x - ch] if x >= ch else 0; b = prev[x]; c = prev[x - ch] if x >= ch else 0
                p = a + b - c; pa = abs(p - a); pb = abs(p - b); pc = abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (b if pb <= pc else c))) & 255
        prev = line
        o = y * w * 3
        if ch >= 3:
            for x in range(w):
                s = x * ch
                if ch == 4:
                    al = line[s + 3]  # ทึบบนดำ (= ImageRenderer.isOpaque)
                    out[o + x * 3:o + x * 3 + 3] = bytes((line[s] * al // 255, line[s + 1] * al // 255, line[s + 2] * al // 255))
                else:
                    out[o + x * 3:o + x * 3 + 3] = line[s:s + 3]
        elif ct == 3:
            for x in range(w):
                k = line[x] * 3; out[o + x * 3:o + x * 3 + 3] = plte[k:k + 3]
        else:
            for x in range(w):
                g = line[x * ch]; out[o + x * 3:o + x * 3 + 3] = bytes((g, g, g))
    return w, h, out

def write_png(path, w, h, rgb):
    raw = bytearray()
    for y in range(h):
        raw.append(0); raw += rgb[y * w * 3:(y + 1) * w * 3]
    def chunk(t, b): return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
                           + chunk(b'IDAT', zlib.compress(bytes(raw), 6)) + chunk(b'IEND', b''))

def image_diff(a, b):
    """(ร้อยละพิกเซลที่ต่างชัด > 24/255, ค่าต่างเฉลี่ย 0–255, รูปต่าง) — ขนาดไม่เท่ากันเทียบส่วนที่ทับกัน"""
    wa, ha, pa = a; wb, hb, pb = b
    w = min(wa, wb); h = min(ha, hb)
    diff = bytearray(w * h * 3)
    bad = 0; total = 0
    for y in range(h):
        oa = y * wa * 3; ob = y * wb * 3; od = y * w * 3
        for x in range(w):
            i = x * 3
            d = max(abs(pa[oa + i] - pb[ob + i]), abs(pa[oa + i + 1] - pb[ob + i + 1]), abs(pa[oa + i + 2] - pb[ob + i + 2]))
            total += d
            if d > 24:
                bad += 1
                diff[od + i:od + i + 3] = bytes((255, 40, 90))
            else:
                g = (pa[oa + i] + pa[oa + i + 1] + pa[oa + i + 2]) // 12
                diff[od + i:od + i + 3] = bytes((g, g, g))
    n = max(1, w * h)
    return 100.0 * bad / n, total / n, (w, h, diff)

# MARK: fixtures

def load(d):
    out = {}
    for f in sorted(os.listdir(d)):
        if f.endswith('.json'):
            out[f[:-5]] = json.load(open(os.path.join(d, f)))
    return out

NO_IMAGES = '--no-images' in sys.argv
# รายงานแบบเบา: เก็บรูปเฉพาะกรอบที่ระบุ (ตัวเลขยังเทียบครบทุกกรอบ) · ย่อครึ่ง
REPORT_PROBES = sys.argv[sys.argv.index('--probes') + 1].split(',') if '--probes' in sys.argv else None
# ชื่อฝั่งที่สอง (ค่าตั้งต้น Android · present/web-parity ส่ง --label web)
LABEL = sys.argv[sys.argv.index('--label') + 1] if '--label' in sys.argv else 'Android'

def half(img):
    w, h, p = img; w2, h2 = w // 2, h // 2
    out = bytearray(w2 * h2 * 3)
    for y in range(h2):
        r0 = (2 * y) * w * 3; r1 = (2 * y + 1) * w * 3; o = y * w2 * 3
        for x in range(w2):
            i = 2 * x * 3
            for c in range(3):
                out[o + x * 3 + c] = (p[r0 + i + c] + p[r0 + i + 3 + c] + p[r1 + i + c] + p[r1 + i + 3 + c]) // 4
    return w2, h2, out

def main():
    ios, andr, out = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(os.path.join(out, 'cells'), exist_ok=True)
    I = load(os.path.join(ios, 'fixtures')); A = load(os.path.join(andr, 'fixtures'))
    TOL = 0.0101
    kinds = []
    m_total = m_w = m_lines = 0
    worst_measures = []
    for kind in sorted(I):
        fi = I[kind]; fa = A.get(kind)
        row = {'kind': kind, 'cases': [], 'boxes': 0, 'boxDiffs': 0, 'firstDiffs': []}
        casesA = {c['probe']: c for c in (fa or {}).get('cases', [])}
        for ci in fi['cases']:
            p = ci['probe']; ca = casesA.get(p)
            case = {'probe': p, 'diffs': 0}
            if ca is None:
                case['missing'] = True; row['cases'].append(case); continue
            bA = {b['id']: b for b in ca['boxes']}
            for bi in ci['boxes']:
                row['boxes'] += 1
                ba = bA.get(bi['id'])
                why = None
                if ba is None: why = f'missing on {LABEL}'
                elif ba['type'] != bi['type']: why = f"type {ba['type']} ≠ {bi['type']}"
                else:
                    bad = [k for k in ('x', 'y', 'w', 'h') if abs(ba[k] - bi[k]) > TOL]
                    if bad: why = ' '.join(f"{k} {ba[k]:.2f}≠{bi[k]:.2f}" for k in bad)
                    elif bi.get('text') is not None:
                        pr = []
                        if ba.get('text') != bi.get('text'): pr.append('text')
                        if abs((ba.get('size') or 0) - (bi.get('size') or 0)) > TOL: pr.append(f"size {ba.get('size')}≠{bi.get('size')}")
                        if ba.get('lines') != bi.get('lines'): pr.append(f"lines {ba.get('lines')}≠{bi.get('lines')}")
                        if pr: why = ' · '.join(pr) + f" «{(bi.get('text') or '')[:24]}»"
                if why:
                    case['diffs'] += 1; row['boxDiffs'] += 1
                    if len(row['firstDiffs']) < 5: row['firstDiffs'].append(f"{p} {bi['id']}: {why}")
            if abs(ca.get('scale', 1) - ci.get('scale', 1)) > 1e-9:
                case['diffs'] += 1; row['boxDiffs'] += 1
                row['firstDiffs'].append(f"{p}: fitScale {ca.get('scale')} ≠ {ci.get('scale')}")
            # ตัววัดตัวอักษร: คำถามเดียวกัน (ข้อความ · ฟอนต์ · ความกว้าง) ตอบต่างกันเท่าไร
            mi = {}
            for m in ci.get('measures', []):
                mi[(m['t'], m['face'], m['weight'], round(m['size'], 3), round(m.get('tracking', 0), 3), round(m.get('kerning', 0), 3), None if m.get('width') is None else round(m['width'], 2))] = m
            for m in ca.get('measures', []):
                k = (m['t'], m['face'], m['weight'], round(m['size'], 3), round(m.get('tracking', 0), 3), round(m.get('kerning', 0), 3), None if m.get('width') is None else round(m['width'], 2))
                if k in mi:
                    x = mi[k]; m_total += 1
                    dw = abs(x['w'] - m['w'])
                    if dw <= 0.5: m_w += 1
                    if x['lines'] == m['lines']: m_lines += 1
                    worst_measures.append((dw, x['t'][:30], x['face'], x['size'], x['weight'], x['w'], m['w'], x['lines'], m['lines']))
            # ภาพ
            fn = f"cell-{kind}-{p}.png"
            pi = os.path.join(ios, fn); pa = os.path.join(andr, fn)
            if NO_IMAGES: pass
            elif os.path.exists(pi) and os.path.exists(pa):
                a = read_png(pi); b = read_png(pa)
                pct, mean, dimg = image_diff(a, b)
                case['pixelPct'] = round(pct, 2); case['mean'] = round(mean, 2)
                case['size'] = [a[0], a[1], b[0], b[1]]
                if REPORT_PROBES is None or p in REPORT_PROBES:
                    case['shown'] = True
                    write_png(os.path.join(out, 'cells', f"{kind}-{p}-ios.png"), *half(a))
                    write_png(os.path.join(out, 'cells', f"{kind}-{p}-and.png"), *half(b))
                    write_png(os.path.join(out, 'cells', f"{kind}-{p}-diff.png"), *half(dimg))
            row['cases'].append(case)
        row['ok'] = row['boxDiffs'] == 0 and all(not c.get('missing') for c in row['cases'])
        px = [c['pixelPct'] for c in row['cases'] if 'pixelPct' in c]
        row['pixelMax'] = max(px) if px else None
        row['pixelAvg'] = round(sum(px) / len(px), 2) if px else None
        kinds.append(row)
    worst_measures.sort(reverse=True)
    summary = {
        'kinds': len(kinds), 'numbersOK': sum(1 for k in kinds if k['ok']),
        'boxes': sum(k['boxes'] for k in kinds), 'boxDiffs': sum(k['boxDiffs'] for k in kinds),
        'measures': m_total, 'measuresWithin05': m_w, 'measuresSameLines': m_lines,
        'worstMeasures': worst_measures[:25], 'perKind': kinds,
    }
    json.dump(summary, open(os.path.join(out, 'summary.json'), 'w'), ensure_ascii=False, indent=1)
    if not NO_IMAGES: write_html(out, summary)
    print(f"kinds {summary['numbersOK']}/{summary['kinds']} numbers-equal · boxes {summary['boxes']} diffs {summary['boxDiffs']} · "
          f"measures {m_w}/{m_total} within 0.5pt · same lines {m_lines}/{m_total}")

def write_html(out, s):
    e = html.escape
    rows = []
    for k in s['perKind']:
        cells = []
        for c in k['cases']:
            if 'pixelPct' not in c or not c.get('shown'): continue
            p = c['probe']; base = f"cells/{k['kind']}-{p}"
            tone = 'ok' if c['pixelPct'] < 1 else ('warn' if c['pixelPct'] < 5 else 'bad')
            cells.append(f"""<figure class="case"><figcaption><b>{e(p)}</b> <span class="pill {tone}">{c['pixelPct']:.2f}% px</span>
              <span class="pill {'ok' if c['diffs'] == 0 else 'bad'}">{'ตัวเลขตรง' if c['diffs'] == 0 else str(c['diffs']) + ' กล่องต่าง'}</span></figcaption>
              <div class="trip"><div><img loading="lazy" src="{base}-ios.png"><span>iOS</span></div>
              <div><img loading="lazy" src="{base}-and.png"><span>{e(LABEL)}</span></div>
              <div><img loading="lazy" src="{base}-diff.png"><span>ต่าง (แดง)</span></div></div></figure>""")
        diffs = ''.join(f"<li>{e(d)}</li>" for d in k['firstDiffs'])
        rows.append(f"""<section class="kind" id="{e(k['kind'])}"><h2>{e(k['kind'])}
          <span class="pill {'ok' if k['ok'] else 'bad'}">{'ตัวเลขตรงทุกกล่อง' if k['ok'] else str(k['boxDiffs']) + ' กล่องต่าง'}</span>
          <span class="pill">ภาพต่างเฉลี่ย {k['pixelAvg']}% · สูงสุด {k['pixelMax']}%</span></h2>
          {('<ul class="diffs">' + diffs + '</ul>') if diffs else ''}<div class="cases">{''.join(cells)}</div></section>""")
    wm = ''.join(f"<tr><td>{e(str(w[1]))}</td><td>{e(w[2])} {w[3]} / {w[4]}</td><td>{w[5]:.2f}</td><td>{w[6]:.2f}</td><td>{w[0]:.2f}</td><td>{w[7]} / {w[8]}</td></tr>" for w in s['worstMeasures'])
    page = f"""<!doctype html><html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Spec Parity</title><style>
:root{{--bg:#f6f6f4;--fg:#1b1b1f;--mut:#6b6b73;--card:#fff;--line:#e3e3e0;--ok:#1f8a4c;--warn:#b7791f;--bad:#c2334d}}
@media (prefers-color-scheme:dark){{:root{{--bg:#141417;--fg:#ececf0;--mut:#9a9aa3;--card:#1d1d22;--line:#2c2c33}}}}
body{{margin:0;background:var(--bg);color:var(--fg);font:14px/1.5 -apple-system,system-ui,sans-serif}}
main{{max-width:1200px;margin:0 auto;padding:24px 16px}} h1{{margin:0 0 4px}} .lede{{color:var(--mut);margin:0 0 20px}}
.stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:24px}}
.stat{{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:14px}} .stat b{{font-size:26px;display:block}}
.kind{{background:var(--card);border:1px solid var(--line);border-radius:14px;padding:16px;margin:0 0 16px}}
.kind h2{{font-size:16px;margin:0 0 10px;display:flex;gap:8px;flex-wrap:wrap;align-items:center}}
.pill{{font-size:12px;font-weight:600;padding:2px 8px;border-radius:99px;background:var(--line)}} .ok{{background:#1f8a4c22;color:var(--ok)}} .warn{{background:#b7791f22;color:var(--warn)}} .bad{{background:#c2334d22;color:var(--bad)}}
.cases{{display:grid;grid-template-columns:repeat(auto-fill,minmax(340px,1fr));gap:14px}}
.case{{margin:0}} .case figcaption{{display:flex;gap:6px;align-items:center;margin-bottom:6px;flex-wrap:wrap}}
.trip{{display:grid;grid-template-columns:repeat(3,1fr);gap:4px}} .trip div{{position:relative}} .trip img{{width:100%;display:block;border-radius:6px;background:#000}}
.trip span{{position:absolute;left:4px;top:4px;font-size:10px;background:#000a;color:#fff;padding:1px 5px;border-radius:4px}}
.diffs{{color:var(--bad);font-size:12px;margin:0 0 10px;padding-left:18px}}
table{{border-collapse:collapse;width:100%;font-size:12px;background:var(--card)}} td,th{{border-bottom:1px solid var(--line);padding:4px 6px;text-align:left}}
</style></head><body><main>
<h1>ผัง JSON ชุดเดียว · iOS กับ {e(LABEL)}</h1>
<p class="lede">ทุกใบวาดจาก <code>shared/WidgetSpecs/*.json</code> ชุดเดียวกัน ด้วยข้อมูลชุดเดียวกัน (เล่นซ้ำจากรอบวาดของ iOS) — {e(LABEL)} ใช้ตัววัดตัวอักษร · ตัวคำนวณ · ตัววาดของตัวเองทั้งหมด</p>
<div class="stats">
<div class="stat"><b>{s['numbersOK']}/{s['kinds']}</b>ชนิดที่ตัวเลขตรงทุกกล่องทุกกรอบ</div>
<div class="stat"><b>{s['boxes'] - s['boxDiffs']}/{s['boxes']}</b>กล่องที่ตรง (±0.01)</div>
<div class="stat"><b>{s['measuresWithin05']}/{s['measures']}</b>การวัดตัวอักษรที่กว้างต่างไม่เกิน 0.5pt</div>
<div class="stat"><b>{s['measuresSameLines']}/{s['measures']}</b>การวัดที่ได้จำนวนบรรทัดเท่ากัน</div></div>
{''.join(rows)}
<h2>การวัดตัวอักษรที่ต่างมากสุด</h2><table><tr><th>ข้อความ</th><th>ฟอนต์</th><th>iOS w</th><th>{e(LABEL)} w</th><th>ต่าง</th><th>บรรทัด iOS/{e(LABEL)}</th></tr>{wm}</table>
</main></body></html>"""
    open(os.path.join(out, 'report.html'), 'w').write(page)

if __name__ == '__main__':
    main()
