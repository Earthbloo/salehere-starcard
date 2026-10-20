Object.fromEntries=Object.fromEntries||(a=>{const o={};for(const[k,v]of a)o[k]=v;return o});
const U=require(require("path").resolve(process.argv[2]||"usage.json"));
// ฐานที่ทุก category ใช้ได้
const BASE=new Set(["slot:name","slot:handle","slot:note#N","photo","flag:owner.verified","flag:stamped","flag:cutout"]);
// โมเดลที่เสนอต่อ category (ชุดที่ใช้ได้ = ฐาน + ชุดนี้)
const M={
 hero:["slot:nickname","slot:tagline","slot:workArea","slot:categories#N","list:categories","list:categories.text"],
 intro:["slot:about","slot:tagline","slot:nickname","slot:workArea"],
 tags:["slot:categories#N","list:categories","list:categories.text"],
 followers:["list:socials","list:socials.platform","list:socials.name","list:socials.short","list:socials.icon","list:socials.tint","list:socials.handle","list:socials.followers","list:socials.followersFull","list:socials.followersRaw","list:socials.views","list:socials.viewsRaw","list:socials.engagement","list:socials.engagementRaw","list:socials.verified","list:socials.synced","stat:stat:totalFollowers","stat:count:socials"],
 audience:["list:gender","list:gender.label","list:gender.share","list:gender.shareRaw","list:gender.tint","list:ages","list:ages.label","list:ages.share","list:ages.shareRaw","list:places","list:places.name","list:places.share","list:places.shareRaw","stat:count:places","stat:stat:reach","stat:stat:reachDelta","stat:stat:reachNew","stat:stat:reachWindow","slot:stat:reachWindow"],
 brand:["list:brands","list:brands.name","list:brands.logo","list:brands.industry","stat:stat:brandCount"],
 verified:["list:works","list:works.brand","list:works.brandLogo","list:works.campaign","list:works.ep","list:works.platform","list:works.icon","list:works.tint","list:works.format","list:works.cover","list:works.workPhoto","list:works.views","list:works.viewsRaw","list:works.saves","list:works.shares","list:works.likes","list:works.comments","list:works.engagement","list:works.viralTag","stat:stat:workCount"],
 photo:[],
 showcase:[],
 rate:["slot:rateLabels#N","slot:ratePrices#N","list:rates","list:rates.label","list:rates.price","list:rates.priceRaw","list:rates.priceNum","list:rates.unit","list:rates.platform","list:rates.platformName","list:rates.icon","list:rates.format","stat:stat:rateCount"],
 contact:["slot:phone","slot:email","slot:lineId","slot:website","list:contacts","stat:stat:phoneFmt","stat:stat:site","stat:stat:lineFlow","slot:stat:phoneFmt","slot:stat:site","slot:stat:lineFlow"],
 availability:["list:avail","list:avail.text","list:areas","list:areas.text","slot:workArea"],
 body:["list:body","list:body.label","list:body.value","list:body.num","list:body.unit","list:body.wide"],
 seal:[],
};
const BORROW={hero:["list:socials","list:socials.handle"],intro:["slot:categories#N","list:categories","list:categories.text"],followers:["slot:tagline"],audience:["list:socials","list:socials.name"],photo:["list:works","list:works.icon"],seal:["stat:count:socials"]};
const keys=(r)=>{const k=[];r.slots.forEach(s=>k.push("slot:"+s));for(const[l,fs]of Object.entries(r.lists)){k.push("list:"+l);fs.forEach(f=>k.push("list:"+l+"."+f))}r.stats.forEach(s=>k.push("stat:"+s));if(r.photo)k.push("photo");r.flags.forEach(f=>k.push("flag:"+f));return k};
const nice=(k)=>k==="photo"?"รูปช่อง":k.startsWith("flag:")?"ธง "+k.slice(5):k.slice(5);
const by={};for(const r of U)(by[r.cat]=by[r.cat]||[]).push(r);
let md="";
for(const c of Object.keys(M)){const rs=by[c]||[];const ok=new Set([...BASE,...M[c]]);const bor=new Set(BORROW[c]||[]);
 md+=`\n#### ${c} (${rs.length})\n\n| widget | ใช้ข้อมูล (↗ = ยืมจากส่วนอื่นของ API · อยู่ใน Model ของหมวดนี้) | นอก Model |\n|---|---|---|\n`;
 for(const r of rs){const ks=keys(r);const used=ks.filter(k=>ok.has(k)||bor.has(k)).map(k=>(bor.has(k)?"↗":"")+nice(k));const over=ks.filter(k=>!ok.has(k)&&!bor.has(k)).map(nice);
  // ย่อ: list ที่มีฟิลด์แล้วไม่ต้องโชว์ชื่อ list เดี่ยว
  const uu=[...new Set(used)],oo=[...new Set(over)];const u=uu.filter(x=>!uu.some(y=>y!==x&&y.replace("↗","").startsWith(x.replace("↗","")+".")));const o=oo.filter(x=>!oo.some(y=>y!==x&&y.replace("↗","").startsWith(x.replace("↗","")+".")));
  md+=`| \`${r.kind}\` | ${u.map(x=>"`"+x+"`").join(" ")||"—"} | ${o.length?"⚠️ "+o.map(x=>"`"+x+"`").join(" "):""} |\n`}}
const rest=Object.keys(by).filter(c=>!M[c]);if(rest.length)md+="\n(ไม่มีโมเดล: "+rest.join(", ")+")\n";
console.log(md)
