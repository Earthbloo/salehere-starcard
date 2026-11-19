#!/bin/zsh
# อัปไฟล์ผัง widget ตัวเดียวขึ้น API แทนของเดิม — การ์ดทุกใบที่วาง kind นี้ได้ผังใหม่ทันที (iOS/Android/web โหลดจาก schemaUrl)
# ต้องใช้ token ของ staff (บัญชีหลังบ้านที่มี role) ใน env SH_TOKEN — token ผู้ใช้ทั่วไปเรียก updateStarCardWidget ไม่ผ่าน
#   SH_TOKEN='...' zsh shared/tools/upload-widget-spec.sh proofSeal            # SIT (ค่าเริ่มต้น)
#   SH_TOKEN='...' ENV=uat zsh shared/tools/upload-widget-spec.sh proofSeal    # uat | prod
#   DRY=1 SH_TOKEN='...' zsh shared/tools/upload-widget-spec.sh proofSeal      # ดูอย่างเดียว ไม่อัป
# ขั้น: หา id ตาม kind → generateStarCardWidgetSchemaUploadUrl → PUT ไฟล์ขึ้น S3 → updateStarCardWidget → อ่านกลับมาเทียบ
set -e
cd "${0:A:h}/../.."
KIND=$1
[[ -n "$KIND" ]] || { echo "ใส่ kind เช่น proofSeal"; exit 1; }
case "${ENV:-sit}" in
  sit)  URL=https://sit-api.sh-pxmer.co/graphql ;;
  uat)  URL=https://uat-api.sh-pxmer.co/graphql ;;
  prod) URL=https://api.salehere.co.th/graphql ;;
  *) echo "ENV ต้องเป็น sit | uat | prod"; exit 1 ;;
esac
URL=${API_URL:-$URL}   # * API_URL = ทดสอบกับ server จำลองในเครื่อง
[[ -n "$SH_TOKEN" ]] || { echo "ใส่ SH_TOKEN (token staff) ก่อน"; exit 1; }

FILE=$(find shared/WidgetSpecs -name "$KIND.json" | head -1)
[[ -f "$FILE" ]] || { echo "ไม่พบ shared/WidgetSpecs/**/$KIND.json"; exit 1; }
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d.get("kind", sys.argv[2]) == sys.argv[2], "kind ในไฟล์ไม่ตรงชื่อไฟล์"' "$FILE" "$KIND"
SIZE=$(wc -c < "$FILE" | tr -d ' ')

# * ส่ง query เป็น JSON ผ่าน python — ไม่ต่อ string เอง (กัน quote พัง)
gql() {
  python3 -c 'import json,sys; print(json.dumps({"query": sys.argv[1], "variables": json.loads(sys.argv[2])}))' "$1" "${2:-{\}}" \
    | curl -sS -m 60 -X POST "$URL" -H 'Content-Type: application/json' -H "Authorization: $SH_TOKEN" --data-binary @-
}
pick() { local code=$1; shift; python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit('API error: '+json.dumps(d.get('errors'),ensure_ascii=False)[:400]) if d.get('errors') else None; $code" "$@"; }

echo "→ $KIND ($FILE, $SIZE bytes) · ${ENV:-sit}"
CUR=$(gql '{ starCardWidgets(limit: 0) { starCardWidgets { id kind schemaUrl } } }' \
  | pick 'w=[x for x in d["data"]["starCardWidgets"]["starCardWidgets"] if x["kind"]==sys.argv[1]]; print(w[0]["id"], w[0]["schemaUrl"]) if w else sys.exit("ไม่มี widget "+sys.argv[1]+" ในระบบ — ต้องใช้ createStarCardWidget")' "$KIND")
ID=${CUR%% *}; OLD=${CUR#* }
echo "  id $ID"
echo "  เดิม $OLD"
if [[ -n "$DRY" ]]; then echo "DRY — ไม่อัป"; exit 0; fi

UP=$(gql 'mutation($kind: String!, $size: Int!) { generateStarCardWidgetSchemaUploadUrl(kind: $kind, sizeBytes: $size) { successful entity { uploadUrl fileUrl } errors { path message } } }' \
  "{\"kind\":\"$KIND\",\"size\":$SIZE}" \
  | pick 'r=d["data"]["generateStarCardWidgetSchemaUploadUrl"]; sys.exit("ขอ URL ไม่ได้: "+json.dumps(r.get("errors"),ensure_ascii=False)) if not r["successful"] else print(r["entity"]["uploadUrl"], r["entity"]["fileUrl"])')
UPLOAD_URL=${UP%% *}; FILE_URL=${UP#* }

CODE=$(curl -sS -m 60 -o /dev/null -w '%{http_code}' -X PUT "$UPLOAD_URL" -H 'Content-Type: application/json' --data-binary @"$FILE")
[[ "$CODE" == 200 ]] || { echo "PUT ขึ้น S3 ไม่ผ่าน (HTTP $CODE) — ของเดิมยังไม่ถูกแตะ"; exit 1; }
echo "  อัปไฟล์แล้ว $FILE_URL"

NEW=$(gql 'mutation($id: String!, $url: String!) { updateStarCardWidget(id: $id, schemaUrl: $url) { successful entity { kind schemaUrl } errors { path message } } }' \
  "{\"id\":\"$ID\",\"url\":\"$FILE_URL\"}" \
  | pick 'r=d["data"]["updateStarCardWidget"]; sys.exit("update ไม่ผ่าน: "+json.dumps(r.get("errors"),ensure_ascii=False)) if not r["successful"] else print(r["entity"]["schemaUrl"])')
echo "  ใหม่ $NEW"

# * อ่านไฟล์จากลิงก์ที่แอปจะโหลดจริง แล้วเทียบกับไฟล์ในเครื่อง
TMP=$(mktemp)
curl -sS -m 60 -o "$TMP" "$NEW"
if cmp -s "$TMP" "$FILE"; then echo "✓ ไฟล์บน CDN ตรงกับในเครื่อง"; else echo "⚠ ไฟล์บน CDN ไม่ตรงกับในเครื่อง — ลองเปิด $NEW ดู"; fi
rm -f "$TMP"
echo "ย้อนกลับได้: updateStarCardWidget(id: \"$ID\", schemaUrl: \"$OLD\")"
