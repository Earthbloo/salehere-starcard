// node diff.mjs a.png b.png … (คู่) — นับพิกเซลที่ต่าง (>8/255) ของภาพคู่
import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
const repo = path.resolve(path.dirname(new URL(import.meta.url).pathname), '../..')
const puppeteer = createRequire(path.join(repo, 'sync-server/package.json'))('puppeteer-core')
const b = await puppeteer.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true })
const p = await b.newPage()
const args = process.argv.slice(2)
for (let i = 0; i < args.length; i += 2) {
  const [x, y] = [args[i], args[i + 1]].map((f) => 'data:image/png;base64,' + fs.readFileSync(f).toString('base64'))
  const r = await p.evaluate(async (x, y) => {
    const load = (s) => new Promise((ok) => { const im = new Image(); im.onload = () => ok(im); im.src = s })
    const [A, B] = await Promise.all([load(x), load(y)])
    if (A.width !== B.width || A.height !== B.height) return `size ${A.width}x${A.height} vs ${B.width}x${B.height}`
    const c = (im) => { const cv = new OffscreenCanvas(im.width, im.height); const g = cv.getContext('2d'); g.drawImage(im, 0, 0); return g.getImageData(0, 0, im.width, im.height).data }
    const a = c(A), bb = c(B); let n = 0, x0 = 1e9, y0 = 1e9, x1 = 0, y1 = 0
    for (let k = 0; k < a.length; k += 4) if (Math.abs(a[k] - bb[k]) > 8 || Math.abs(a[k + 1] - bb[k + 1]) > 8 || Math.abs(a[k + 2] - bb[k + 2]) > 8) { n++; const q = k / 4, X = q % A.width, Y = (q - X) / A.width; x0 = Math.min(x0, X); y0 = Math.min(y0, Y); x1 = Math.max(x1, X); y1 = Math.max(y1, Y) }
    return `${n} px (${(100 * n / (A.width * A.height)).toFixed(2)}%)` + (n ? ` box ${x0},${y0}-${x1},${y1}` : "")
  }, x, y)
  console.log(path.basename(args[i]), '→', r)
}
await b.close()
