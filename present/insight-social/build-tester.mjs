// รวม tester.src.html + img/*.png เป็นไฟล์เดียว insight-social-tester.html (รูปฝังเป็น base64)
import { readFileSync, readdirSync, writeFileSync } from 'node:fs'
const dir = new URL('.', import.meta.url).pathname
const imgs = Object.fromEntries(readdirSync(dir + 'img').filter((f) => f.endsWith('.png')).map((f) =>
  [f.slice(0, -4), 'data:image/png;base64,' + readFileSync(dir + 'img/' + f).toString('base64')]))
const html = readFileSync(dir + 'tester.src.html', 'utf8').replace('__IMGS__', () => JSON.stringify(imgs))
writeFileSync(dir + 'insight-social-tester.html', html)
console.log(Object.keys(imgs).length, 'images,', (html.length / 1024 / 1024).toFixed(2), 'MB')
