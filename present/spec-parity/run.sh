#!/bin/zsh
# พิสูจน์ "ผัง JSON ชุดเดียว → iOS กับ Android วาดออกมาเหมือนกัน" ครบวงจร
#   1. iOS: ./present/spec-fixtures/sync.sh <udid>   (build + install แอปไว้ก่อน — ดูหัวไฟล์นั้น)
#   2. ./present/spec-parity/run.sh [ios-udid]
# ผล: present/spec-parity/out/report.html
set -e
UD=${1:-E68D4085-0BD3-4DBB-A231-51EFE7795BB0}
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
A=${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb
PKG=co.salehere.starcard
export JAVA_HOME=${JAVA_HOME:-"/Applications/Android Studio.app/Contents/jbr/Contents/Home"}
IOS=$(xcrun simctl get_app_container "$UD" com.salehere.alpha.app.starcard data)/Documents/Specs
[ -f "$IOS/sheet.png" ] || { echo "ยังไม่มีผลของ iOS — รัน present/spec-fixtures/sync.sh ก่อน"; exit 1; }
# ตัวคำนวณล้วน ๆ (JVM · เล่นคำตอบของ iOS ซ้ำ)
(cd "$ROOT/StarCardAndroid" && ./gradlew :app:testDebugUnitTest --tests '*SpecSolverFixtureTest*' -q) || true
grep "kinds passing" "$ROOT/StarCardAndroid/app/build/spec-fixture-summary.txt"
# รูปผลงาน/ครีเอเตอร์เป็นข้อมูลของเครื่อง — เทียบภาพให้ยุติธรรมต้องใช้ชุดเดียวกัน: ก๊อปของซิม iOS ไปใส่ Android
# (ชื่อไฟล์เป็นตัวเล็ก — Android หาไฟล์ด้วย UUID ตัวเล็ก) · ของเดิมของ Android ถูกทับ — สำรองเองก่อนถ้าต้องการ
PORT=$(dirname "$IOS")/starcard-portfolio
if [ -d "$PORT" ]; then
  COPYFILE_DISABLE=1 tar -C "$(dirname "$PORT")" -cf - starcard-portfolio | $A shell "run-as $PKG sh -c 'rm -rf files/starcard-portfolio && tar -xf - -C files'"
  $A shell "run-as $PKG sh -c 'cd files/starcard-portfolio && for f in work-* video-*; do l=\$(echo \$f | tr A-Z a-z); [ \"\$f\" != \"\$l\" ] && mv \"\$f\" \"\$l\"; done; true'"
  python3 -c "import json,sys;d=json.load(open('$PORT/manifest.json'));[v.update(fileName=v['fileName'].lower()) for v in d.get('videos',[])];print(json.dumps(d))" | $A shell "run-as $PKG sh -c 'cat > files/starcard-portfolio/manifest.json'"
fi
# Android บนเครื่อง: ติดตั้ง · ส่ง fixture ของ iOS เข้า filesDir · ส่งออก
(cd "$ROOT/StarCardAndroid" && ./gradlew :app:installDebug -q)
COPYFILE_DISABLE=1 tar -C "$IOS" -cf - fixtures | $A shell "run-as $PKG sh -c 'rm -rf files/ios-fixtures && mkdir -p files/ios-fixtures && tar -xf - -C files/ios-fixtures --strip-components=1'"
$A shell am start -S -n $PKG/.MainActivity --es exportSpecs 1 >/dev/null
sleep 20
for i in $(seq 1 240); do $A exec-out run-as $PKG ls files/Specs 2>/dev/null | grep -q sheet.png && break; sleep 5; done
rm -rf "$HERE/android"; mkdir -p "$HERE/android"
$A exec-out run-as $PKG tar -C files -cf - Specs | tar -xf - -C "$HERE/android"
python3 -I "$HERE/compare.py" "$IOS" "$HERE/android/Specs" "$HERE/out" --probes design
echo "→ $HERE/out/report.html"
