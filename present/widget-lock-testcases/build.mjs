// Rebuild index.html from shared/WidgetSpecs (requires) + template.html
// usage: node present/widget-lock-testcases/build.mjs
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const specDir = path.join(here, '../../shared/WidgetSpecs');
const widgets = fs.readdirSync(specDir).filter(f => f.endsWith('.json')).map(f => {
  const j = JSON.parse(fs.readFileSync(path.join(specDir, f), 'utf8'));
  const w = j.widget || {};
  return { kind: f.replace('.json', ''), title: w.title || '', category: w.category || '', requires: w.requires || [], pinned: !!w.pinned };
});
const tpl = fs.readFileSync(path.join(here, 'template.html'), 'utf8');
const frag = tpl.replace('/*__WIDGETS__*/', JSON.stringify(widgets));
// artifact.html = fragment for claude.ai Artifact publish (it adds the document skeleton) · index.html = standalone file
fs.writeFileSync(path.join(here, 'artifact.html'), frag);
fs.writeFileSync(path.join(here, 'index.html'), `<!doctype html>\n<html lang="th">\n<head>\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n<style>img{max-width:100%}[hidden]{display:none!important}</style>\n</head>\n<body>\n${frag}\n</body>\n</html>\n`);
console.log('index.html + artifact.html written ·', widgets.length, 'widgets');
