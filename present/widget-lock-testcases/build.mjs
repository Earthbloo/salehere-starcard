// Rebuild index.html from shared/WidgetSpecs (requires) + template.html
// usage: node present/widget-lock-testcases/build.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const specDir = path.join(here, '../../shared/WidgetSpecs');
// ผังแบ่งโฟลเดอร์ย่อยตามหมวดถาดของ API (`<NN-หมวด>/<kind>.json`) → กวาดทุกชั้น · คืน path เต็ม เรียงตามชื่อไฟล์ (= kind)
const specFiles = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? specFiles(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const listSpecs = (d) => specFiles(d).sort((a, b) => path.basename(a) < path.basename(b) ? -1 : 1)
const widgets = listSpecs(specDir).map(p => {
  const f = path.basename(p);
  const j = JSON.parse(fs.readFileSync(p, 'utf8'));
  const w = j.widget || {};
  return { kind: f.replace('.json', ''), title: w.title || '', category: w.category || '', requires: w.requires || [], pinned: !!w.pinned };
});
const tpl = fs.readFileSync(path.join(here, 'template.html'), 'utf8');
const frag = tpl.replace('/*__WIDGETS__*/', JSON.stringify(widgets));
// artifact.html = fragment for claude.ai Artifact publish (it adds the document skeleton) · index.html = standalone file
fs.writeFileSync(path.join(here, 'artifact.html'), frag);
fs.writeFileSync(path.join(here, 'index.html'), `<!doctype html>\n<html lang="th">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n<style>img{max-width:100%}[hidden]{display:none!important}</style>\n</head>\n<body>\n${frag}\n</body>\n</html>\n`);
console.log('index.html + artifact.html written ·', widgets.length, 'widgets');
