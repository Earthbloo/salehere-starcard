import sys,glob,os
from PIL import Image,ImageDraw
ids=sys.argv[1:]; rows=[]
for f in sorted(glob.glob('img/*-before.png')):
    base=os.path.basename(f)[:-11]
    if ids and base.split('-')[0] not in ids: continue
    a=Image.open(f); b=Image.open(f.replace('-before','-after'))
    s=0.5; a=a.resize((int(a.width*s),int(a.height*s))); b=b.resize((int(b.width*s),int(b.height*s)))
    r=Image.new('RGB',(a.width+b.width+30,max(a.height,b.height)+24),'white'); r.paste(a,(0,24)); r.paste(b,(a.width+30,24))
    ImageDraw.Draw(r).text((4,4),base+'   BEFORE | AFTER',fill='black'); rows.append(r)
W=max(r.width for r in rows); H=sum(r.height for r in rows)
o=Image.new('RGB',(W,H),'white'); y=0
for r in rows: o.paste(r,(0,y)); y+=r.height
o.save('/private/tmp/claude-501/-Users-earthbloo-salehere-starcard/f78d982b-de09-4ede-8ccf-0d0e9a43d5b2/scratchpad/pairs.png')
print(o.size)
