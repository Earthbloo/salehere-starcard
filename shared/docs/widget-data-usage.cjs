Object.fromEntries=Object.fromEntries||(a=>{const o={};for(const[k,v]of a)o[k]=v;return o});
const fs=require("fs");const R=require("path").resolve(__dirname,"../..")+"/";
// หมวดมาจาก `widget.category` ของไฟล์ผัง (ตารางชื่อใน kinds.js ถูกลบแล้ว 15 ต.ค. 2569) · ตัวตรวจเต็มคือ shared/tools/check-widgets.mjs --usage
const fam={};
const SKIPF=new Set(["i","rank","rank2"]);
const res=[];
const rx=(s,re,cb)=>{let m;re.lastIndex=0;while((m=re.exec(s)))cb(m)};
for(const file of fs.readdirSync(R+"shared/WidgetSpecs").sort()){if(!file.endsWith(".json"))continue;
 const s=JSON.parse(fs.readFileSync(R+"shared/WidgetSpecs/"+file,"utf8"));
 const u={kind:s.kind,cat:fam[s.kind]||(s.widget&&s.widget.category)||"?",slots:new Set(),lists:{},stats:new Set(),photo:new Set(),flags:new Set()};
 const addF=(list,f)=>{if(!list||SKIPF.has(f)||/^(max|sum)$/.test(f))return;(u.lists[list]=u.lists[list]||new Set()).add(f)};
 const cond=(str,list)=>{for(const t0 of str.split(/[&|]/)){const t=t0.trim().replace(/^!/,"");if(!t)continue;
   if(t.startsWith("list:")){const l=t.slice(5).replace(/[<>=].*/,"");u.lists[l]=u.lists[l]||new Set();}
   else if(t.startsWith("has:"))u.slots.add(t.slice(4).replace(/#\d+$/,"#N"));
   else if(t.startsWith("$")){const f=t.slice(1).replace(/[<>=].*/,"");addF(list,f)}
   else if(t.startsWith("hidden:")){const f=t.slice(7);rx(f,/\$(\w+)/g,m=>addF(list,m[1]))}
   else if(/^(owner\.|sample|ink\.|bordered|papered|stamped|duo|cutout|kit\.|surface=|cfg:|opt:|[wh]\W|ratio)/.test(t)){if(/^(owner\.|cutout|stamped)/.test(t))u.flags.add(t)}
   else u.flags.add(t)}};
 const walk=(n,list)=>{if(!n||typeof n!=="object")return;if(Array.isArray(n)){n.forEach(x=>walk(x,list));return}
  if(typeof n.slot==="string"){const v=n.slot;
    if(/^(stat|count):/.test(v))u.stats.add(v);
    else if(v.startsWith("$"))addF(list,v.slice(1));
    else if(/#\$i$/.test(v))u.slots.add(v.replace(/#\$i$/,"#N"));
    else u.slots.add(v.replace(/#\d+$/,"#N"));}
  if(n.photo!==undefined){if(typeof n.photo==="string"&&n.photo.startsWith("$"))addF(list,n.photo.slice(1));else u.photo.add("photo")}
  if(typeof n.photoRef==="string")addF(list,n.photoRef.replace("$",""));
  if(typeof n.text==="string")rx(n.text,/\{(\w+)\}/g,m=>addF(list,m[1]));
  for(const k of["icon","pct","src","fill","color","tint","sort","group"])if(typeof n[k]==="string"){rx(n[k],/\$(\w+)/g,m=>addF(list,m[1])); if((k==="sort"||k==="group")&&list) addF(list,n[k].split(" ")[0])}
  for(const k of["if","where"])if(typeof n[k]==="string")cond(n[k],list);
  if(typeof n.list==="string"){u.lists[n.list]=u.lists[n.list]||new Set();}
  const inner=typeof n.list==="string"?n.list:list;
  if(n.each)walk(n.each,inner);
  if(n.children)walk(n.children,list===undefined?inner:inner);
  for(const [k,v] of Object.entries(n)) if(!["each","children"].includes(k)&&typeof v==="object") walk(v,list);
 };
 walk(s.root);(s.variants||[]).forEach(v=>{if(typeof v.when==="string")cond(v.when);walk(v.root)});
 res.push({kind:u.kind,cat:u.cat,slots:[...u.slots].sort(),lists:Object.fromEntries(Object.entries(u.lists).map(([k,v])=>[k,[...v].sort()])),stats:[...u.stats].sort(),photo:u.photo.size>0,flags:[...u.flags].sort()});
}
fs.writeFileSync(process.argv[2]||"usage.json",JSON.stringify(res,null,1));
const by={};for(const r of res)(by[r.cat]=by[r.cat]||[]).push(r);
for(const[c,rs]of Object.entries(by)){console.log("\n## "+c);for(const r of rs)console.log(` ${r.kind}: slots[${r.slots.join(" ")}] lists{${Object.entries(r.lists).map(([k,v])=>k+":"+v.join(",")).join(" ; ")}} stats[${r.stats.join(" ")}] photo=${r.photo} flags[${r.flags.join(" ")}]`)}
