import json,glob
R='/Users/earthbloo/salehere-starcard/shared/WidgetSpecs'
def size(k,maxw=342,sc=1):
    d=json.load(open(glob.glob(f'{R}/*/{k}.json')[0]))['design']; w,h=d['w'],d['h']; f=min(1,maxw/w)*sc
    return round(w*f),round(h*f)
C=[c for c in json.load(open('cases.json')) if not c['name'].startswith('r-')]
cats5=['ความงามและสุขภาพ','แฟชั่นและช้อปปิ้ง','อาหารและเครื่องดื่ม','การเงินการของและขนส่ง','ท่องเที่ยว']
socials=[dict(type=t,link=l,followers=f,enabled=True,source='connected') for t,l,f in [('instagram','https://instagram.com/tnn_health',37778),('tiktok','https://tiktok.com/@taotaoaima',1703983),('facebook','https://facebook.com/share',673000),('youtube','https://youtube.com/@TrueVisionsOfficial',5710000),('lemon8','https://lemon8-app.com/x',218000)]]
def own(n=5): return dict(values=dict(name='หกห้า มาแล้ว',about='หกห้า มาแล้ว มาร่วมความสนุก 😅😁',handle='sit167',lineId='@sit167',phone='0811111165',website='https://staging.internal.co'),list=dict(categories=cats5[:n]),intake=dict(socials=socials))
def add(name,kind,t='navy',item=None,sc=1,n=5,wh=None):
    w,h=wh or size(kind,sc=sc); C.append(dict(name='r-'+name,kind=kind,w=w,h=h,t=t,src='work',item=item or {},owner=own(n)))
for n in (2,3,4,5): add(f'scrapTags-{n}','scrapTags',n=n)
add('scrapTags-5-small','scrapTags',sc=0.6); add('scrapTags-5-tall','scrapTags',wh=(200,340))
add('aboutText','aboutText'); add('rateTags','rateTags',item=dict(border=True)); add('rateTags-nb','rateTags',item=dict(border=False))
add('proofWork','proofWork'); add('contactPoster','contactPoster',t='light'); add('scrapFeed','scrapFeed')
TAGS=['kitNicheCream','kitNicheGingham','kitNicheMac','kitNicheNight','kitNichePurple','nichePoster','nicheTags','popNicheGlass','popNichePaper','scrapTags','stickerTags']
for k in TAGS:
    b=json.load(open(glob.glob(f'{R}/*/{k}.json')[0]))['widget'].get('border',False)
    add(f'tag-{k}-5',k,item=dict(border=b))
    add(f'tag-{k}-hide',k,item=dict(border=b,kit=dict(opts=dict(hide='ความงามและสุขภาพ,อาหารและเครื่องดื่ม,ท่องเที่ยว'))))
json.dump(C,open('cases.json','w'),ensure_ascii=False,indent=1); print(len(C))
