#!/bin/zsh
# เทียบตัววาด SwiftUI (ต้นแบบ iOS 26) กับตัววาด UIKit (Render/ · iOS 16) จากกล่องชุดเดียวกัน
#   1. build + install แอป (Debug) ลงซิม แล้ว:  ./present/render-ab/run.sh <udid> --launch   (ลบผลเก่า · เปิดแอปด้วย -exportRenderAB · รอ DONE.txt)
#      หรือเปิดเอง: xcrun simctl launch <udid> com.salehere.alpha.app.starcard -exportRenderAB -exportPerson (ลบ DONE.txt เก่าก่อน ไม่งั้นได้ผลครึ่ง ๆ)
#   2. ./present/render-ab/run.sh [udid]   → present/render-ab/out/report.html
set -e
UD=${1:-9C523FA0-4148-4BB4-91EF-85722CE3D381}
HERE=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$HERE/../.." && pwd)
SRC=$(xcrun simctl get_app_container "$UD" com.salehere.alpha.app.starcard data)/Documents/RenderAB
if [ "$2" = "--launch" ]; then
  rm -f "$SRC/DONE.txt"; xcrun simctl terminate "$UD" com.salehere.alpha.app.starcard 2>/dev/null || true
  xcrun simctl launch "$UD" com.salehere.alpha.app.starcard -exportRenderAB -exportPerson >/dev/null
  for i in $(seq 1 240); do [ -f "$SRC/DONE.txt" ] && break; sleep 5; done
fi
[ -f "$SRC/DONE.txt" ] || { echo "ยังไม่มีผล — เปิดแอปด้วย -exportRenderAB -exportPerson แล้วรอ DONE.txt"; exit 1; }
rm -rf "$HERE/swiftui" "$HERE/uikit"; cp -R "$SRC/swiftui" "$HERE/swiftui"; cp -R "$SRC/uikit" "$HERE/uikit"
cat "$SRC/DONE.txt"
python3 -I "$ROOT/present/spec-parity/compare.py" "$HERE/swiftui" "$HERE/uikit" "$HERE/out" --probes design
echo "→ $HERE/out/report.html"
