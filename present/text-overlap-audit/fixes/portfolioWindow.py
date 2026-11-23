# หัวข้อห้ามชนชื่อ (สระบนของคำไทย): ชื่อขึ้น 4 · หัวข้อลง 4
# รูปวางต่อจากหัวข้อ: คอลัมน์ "photoFlow" = หัวข้อล่องหน (คำ/ขนาดเดียวกัน — id ซ้ำคนละกิ่ง ตามกติกา editable) + รูปกินที่เหลือ
# หัวข้อตัวจริงยังวาดหลังรูป (ตัววาดวาดตามลำดับโหนด) · ขอบบนรูปที่ขนาดออกแบบยังเป็น 102 เท่าเดิม
import copy; from specio import *
j = load('portfolioWindow')
for r in all_roots(j):
    page = next(n for n in nodes(r) if n.get('id') == 'page')
    kids = page['children']
    pr = next(c for c in kids if c.get('id') == 'print')
    name = next(c for c in kids if c.get('id') == 'nameRow')
    hl = next(c for c in kids if c.get('id') == 'headline')
    name['dy'] = 12
    hl['dy'] = 44
    ghost = copy.deepcopy(hl)
    for k in ('place', 'dy'): ghost.pop(k)
    ghost['opacity'] = 0
    ghost['alignSelf'] = 'center'
    ghost['w'] = 342.6          # = 93.6% ของ 366 (keepAspect → กล่องกว้าง 366 เสมอ) · % ในคอลัมน์ถูกวัด hug ที่กว้างอื่น
    pr.pop('pad')
    pr['h'] = 'fill'
    flow = {"type": "col", "id": "photoFlow", "pad": [44, 0, 0, 0], "gap": -32.7, "children": [ghost, pr]}
    kids[kids.index(pr)] = flow
save('portfolioWindow', j)
