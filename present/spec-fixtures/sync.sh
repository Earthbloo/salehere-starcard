#!/bin/zsh
# ดึงผล `-exportSpecs` จากซิมูเลเตอร์มาไว้ที่นี่ (fixture = สัญญาข้ามแพลตฟอร์ม · รูปไว้เทียบตา)
#   1. build + install แอป (xcodebuild … -derivedDataPath <dd>; xcrun simctl install <udid> <app>)
#   2. ./sync.sh <udid>
set -e
UD=${1:-9C523FA0-4148-4BB4-91EF-85722CE3D381}
HERE=$(cd "$(dirname "$0")" && pwd)
BID=com.salehere.alpha.app.starcard
C=$(xcrun simctl get_app_container "$UD" $BID data)
xcrun simctl terminate "$UD" $BID 2>/dev/null || true
rm -rf "$C/Documents/Specs"
xcrun simctl launch "$UD" $BID -exportSpecs >/dev/null
for i in $(seq 1 240); do [ -f "$C/Documents/Specs/sheet.png" ] && break; sleep 2; done
[ -f "$C/Documents/Specs/sheet.png" ] || { echo "export did not finish"; exit 1; }
rm -rf "$HERE/fixtures" "$HERE/cells"
mkdir -p "$HERE/fixtures" "$HERE/cells"
cp "$C/Documents/Specs/fixtures/"*.json "$HERE/fixtures/"
# เก็บแค่สองกรอบ (design · small) ให้ repo ไม่บวม — ครบ 6 กรอบดูได้จากซิมโดยตรง
cp "$C/Documents/Specs/"cell-*-design.png "$C/Documents/Specs/"cell-*-small.png "$HERE/cells/"
cp "$C/Documents/Specs/sheet.png" "$HERE/sheet.png"
# STATUS.md — ชนิดไหนวาดผ่านผังแล้ว
{
  echo "# สถานะการแปลง widget → ผัง JSON"
  echo
  echo "สร้างโดย sync.sh $(date '+%Y-%m-%d %H:%M') · ชนิดที่มีไฟล์ใน shared/WidgetSpecs/ วาดผ่าน SpecSolver + SpecPainter แล้ว"
  echo
  echo "| kind | ผัง | fixture |"
  echo "|---|---|---|"
  for f in "$HERE"/fixtures/*.json; do k=$(basename "$f" .json); echo "| $k | ✓ | fixtures/$k.json |"; done
} > "$HERE/STATUS.md"
xcrun simctl terminate "$UD" $BID 2>/dev/null || true
xcrun simctl launch "$UD" $BID >/dev/null
echo "synced $(ls "$HERE/fixtures" | wc -l | tr -d ' ') fixtures → $HERE"
