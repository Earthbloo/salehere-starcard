#!/bin/zsh
# คืนค่าการทดลอง "web + GraphQL" (14 ต.ค. 2569) — กลับเป็น sync-server เดิม
# ไม่แตะ: ข้อมูลการ์ด (data/) · shared/WidgetSpecs · หลังรันแล้วต้อง build แอปใหม่
# แอปที่เปิดโหมดลองทำไว้: iOS `-labSync NO` · Android `adb shell am start -S -n co.salehere.starcard/.MainActivity --es labSync off`
set -e
cd "$(dirname "$0")/../.."
# โค้ดแอป (iOS · Android) — ถอดเฉพาะส่วนที่ทดลองนี้เพิ่ม (patch ย้อน) ของที่คนอื่นแก้ในไฟล์เดียวกันยังอยู่
patch -R -p0 < sync-server/trial/apps.patch
cd sync-server
cp trial/orig/sync-server/server.mjs server.mjs
cp trial/orig-gitignore .gitignore
rm -rf web web-icons.mjs graphql.mjs MODEL.md package.json package-lock.json node_modules
rm -rf trial
echo "reverted sync-server"
