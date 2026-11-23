// node boxes.mjs <kind> <W> <H> [text|-] [k] [idFilter,…] — print solved boxes (+ ink) for nodes with ids
import { execFileSync } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
const here = path.dirname(fileURLToPath(import.meta.url))
const [kind, W, H, t = '-', k = '1', ids = ''] = process.argv.slice(2)
const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.json') ? [path.join(d, e.name)] : [])
const json = walk(path.join(here, '../../shared/WidgetSpecs')).map((f) => JSON.parse(fs.readFileSync(f, 'utf8'))).find((j) => j.kind === kind)
const expr = `(() => { const [j] = withText(${JSON.stringify(json)}, ${t === '-' ? 'null' : JSON.stringify(t)}, ${+k}); const c = solveCase(j, ${+W || json.design.w}, ${+H || json.design.h}); const want = ${JSON.stringify(ids.split(',').filter(Boolean))};
  return { box: c.box, nodes: c.nodes.filter(n => n.nid && n.nid !== n.type && (!want.length || want.includes(n.nid))).map(n => [n.nid, n.type, +n.x.toFixed(1), +n.y.toFixed(1), +n.w.toFixed(1), +n.h.toFixed(1), n.ink ? [+n.ink.y.toFixed(1), +(n.ink.y+n.ink.h).toFixed(1), n.size] : '' ]) } })()`
console.log(execFileSync('node', [path.join(here, 'evalh.mjs'), expr], { encoding: 'utf8' }))
