import plistlib, json, uuid, time, sys
C=sys.argv[1]; path=C+"/Library/Preferences/com.salehere.alpha.app.starcard.plist"
p=plistlib.load(open(path,'rb'))
lib=json.loads(p['starcard.library.v1'])
RID="B0E1A7C5-0000-4000-8000-0000000000B1"
lib=[r for r in lib if r['id']!=RID]
def item(kind,x,y,w,h,kit=None,surface="glass",border=True,extra=None):
    d={"align":"leading","border":border,"face":"noto","h":h,"id":str(uuid.uuid4()).upper(),"kind":kind,
       "points":28,"scale":"medium","slotFaces":{},"slotSizes":{},"slotTints":{},"surface":surface,"tint":"ink","w":w,"x":x,"y":y}
    if kit: d["kit"]={"style":"purple","fill":kit,"corner":"round","opts":{}}
    if extra: d.update(extra)
    return d
L=json.load(open(sys.argv[2]))
items=[item(*a[:5],kit=a[5] if len(a)>5 else None,surface=a[6] if len(a)>6 else "glass",border=a[7] if len(a)>7 else True,extra=a[8] if len(a)>8 else None) for a in L]
now=time.time()-978307200
rec={"id":RID,"name":"สติกเกอร์ มีเดียคิท","formatRaw":"story","createdAt":now,"updatedAt":now,
     "snapshot":{"index":0,"version":2,"pages":[{"items":items}],
       "theme":{"duo":"field","duoFlipped":True,"ink":"paper","inkAuto":False,"backdrop":"solid","corner":"round","strip":"line","hueShift":0,"brightness":0.3,"palette":"midnight","photoEffect":"none","photoDim":0.42}}}
lib.append(rec)
p['starcard.library.v1']=json.dumps(lib,ensure_ascii=False).encode()
plistlib.dump(p,open(path,'wb'),fmt=plistlib.FMT_BINARY)
print("written",len(lib))
