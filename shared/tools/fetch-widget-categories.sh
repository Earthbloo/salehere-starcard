#!/bin/zsh
# ดึงหมวดถาดวิดเจ็ต (starCardWidgetCategories) จาก API จริง — query เดียวกับ salehere-ios StarCard.graphql
# ต้องล็อกอิน: ใส่ token ของตัวเองใน env SH_TOKEN (ค่า header Authorization ที่แอปส่ง)
#   SH_TOKEN='...' zsh shared/tools/fetch-widget-categories.sh            # SIT (ค่าเริ่มต้น)
#   SH_TOKEN='...' ENV=uat zsh shared/tools/fetch-widget-categories.sh    # uat | prod
# ผล → shared/widget-categories.api.json (ไม่มี token อยู่ในไฟล์)
set -e
cd "${0:A:h}/../.."
case "${ENV:-sit}" in
  sit)  URL=https://sit-api.sh-pxmer.co/graphql ;;
  uat)  URL=https://uat-api.sh-pxmer.co/graphql ;;
  prod) URL=https://api.salehere.co.th/graphql ;;
  *) echo "ENV ต้องเป็น sit | uat | prod"; exit 1 ;;
esac
[[ -n "$SH_TOKEN" ]] || { echo "ใส่ SH_TOKEN ก่อน"; exit 1; }
OUT=shared/widget-categories.api.json
curl -sS -m 60 -X POST "$URL" \
  -H 'Content-Type: application/json' -H "Authorization: $SH_TOKEN" \
  -d '{"query":"{ starCardWidgetCategories { id name description sequence widgets { id kind categoryId schemaUrl sequence } } }"}' \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit("API error: "+json.dumps(d.get("errors"),ensure_ascii=False)[:300]) if d.get("errors") else None; c=d["data"]["starCardWidgetCategories"]; json.dump(c,open(sys.argv[1],"w"),ensure_ascii=False,indent=2); print("ok", len(c), "หมวด →", sys.argv[1])' "$OUT"
