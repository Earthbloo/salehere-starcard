#!/bin/sh
# ไฟล์เดิมไม่มีขึ้นบรรทัดท้าย → ตัดออกให้เหมือนเดิม (diff สะอาด)
cd "$(dirname "$0")/../.."
git -c core.quotepath=off diff --name-only -- shared/WidgetSpecs | while read f; do
  b="present/qa-reject-nov23/before/${f#shared/WidgetSpecs/}"
  if [ -f "$b" ] && [ -n "$(tail -c1 "$b")" ]; then python3 -c "import sys;p=sys.argv[1];s=open(p).read();open(p,'w').write(s.rstrip('\n'))" "$f"; fi
done
