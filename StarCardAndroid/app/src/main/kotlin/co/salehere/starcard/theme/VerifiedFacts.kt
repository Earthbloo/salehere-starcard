package co.salehere.starcard.theme

import co.salehere.starcard.model.CreatorProfile
import co.salehere.starcard.model.Profile
import java.util.Locale

// MARK: - ข้อเท็จจริงที่ตรารับรอง (= `struct VerifiedFacts` ใน Views/Widgets/VerifiedSealWidget.swift — เฉพาะ struct นี้)

/**
 * สิ่งที่ตรา "Verified by Sale Here" ยืนยันจริง — แถวที่ผ่าน/ไม่ผ่าน กับเลขประจำการ์ด
 * widget ตรารับรองวาด `core` · แผ่นตรวจสอบ (`VerifySheet`) วาดครบทุกแถว
 */
data class VerifiedFacts(val rows: List<Row>, val serial: String) {

    data class Row(
        val id: Int,
        val title: String,
        val detail: String,
        val value: String,
        val ok: Boolean,
        /** แถวที่ตราต้องผ่าน — ประวัติงานเป็นแถวเสริม ไม่มีก็ยังได้ตรา */
        val required: Boolean = true,
    )

    /** ได้ตราเมื่อผ่านครบทุกแถว — ตราที่ขึ้นทั้งที่ยังมียอดพิมพ์เองคือคำโฆษณา ไม่ใช่คำรับรอง */
    val verified: Boolean get() = core.all { it.ok }

    /** สามแถวที่ตรารับรอง */
    val core: List<Row> get() = rows.filter { it.required }

    companion object {
        /** ยอดผู้ติดตามทุกช่องมาจากแพลตฟอร์มไหม — ใบที่โชว์ยอดใช้ตัดสินว่าจะปั๊มตรา/ติดป้าย Verified ได้หรือยัง */
        val numbersVerified: Boolean
            get() {
                if (labForce) return true
                val s = Profile.me.creator.socials
                return s.isNotEmpty() && s.all { it.source.isVerified }
            }

        /**
         * โต๊ะตรวจงาน (`VerifiedLab`) บังคับสถานะ "ผ่านครบ" เพื่อดูหน้าตาเต็มโดยไม่ต้องแก้ข้อมูลในเครื่อง
         * iOS อ่านจาก launch argument `-labVerified` — Android ไม่มี จึงเป็นค่าที่โต๊ะตรวจงานตั้งเอง
         */
        var labForce: Boolean = false

        val current: VerifiedFacts
            get() {
                if (labForce) {
                    return VerifiedFacts(
                        rows = listOf(
                            Row(id = 0, title = "ตัวตนจริง", detail = "ตรวจบัตรประชาชนแล้ว", value = Signature.verifiedOn, ok = true),
                            Row(id = 1, title = "เจ้าของช่องจริง", detail = "TikTok · Instagram · YouTube", value = "3 ช่อง", ok = true),
                            Row(id = 2, title = "ยอดจากแพลตฟอร์ม", detail = "ไม่ใช่ตัวเลขพิมพ์เอง", value = "2 ชม.ที่แล้ว", ok = true),
                        ) + workRow(Profile.me.creator),
                        serial = serial(Profile.me.handle),
                    )
                }
                val c = Profile.me.creator
                val linked = c.socials.filter { it.source.isVerified }
                val allLinked = c.socials.isNotEmpty() && linked.size == c.socials.size
                val fresh = linked.firstOrNull()?.syncedAgo ?: ""
                val names = linked.take(3).joinToString(" · ") { it.type.name }

                return VerifiedFacts(
                    rows = listOf(
                        // วันที่ยืนยันตัวตนยังเป็นค่าจำลอง (ดู `Signature.verifiedOn`) จนกว่าจะต่อ `userVerify`
                        Row(id = 0, title = "ตัวตนจริง", detail = "ตรวจบัตรประชาชนแล้ว",
                            value = Signature.verifiedOn, ok = true),
                        Row(id = 1, title = "เจ้าของช่องจริง",
                            detail = if (names.isEmpty()) "ยังไม่ได้เชื่อมบัญชี" else names,
                            value = if (linked.isEmpty()) "รอเชื่อม" else "${linked.size} ช่อง", ok = linked.isNotEmpty()),
                        Row(id = 2, title = "ยอดจากแพลตฟอร์ม",
                            detail = if (allLinked) "ไม่ใช่ตัวเลขพิมพ์เอง" else "บางช่องยังกรอกเอง",
                            value = if (allLinked) (if (fresh.isEmpty()) "ล่าสุด" else fresh) else "รอตรวจ", ok = allLinked),
                    ) + workRow(c),
                    serial = serial(Profile.me.handle),
                )
            }

        /** แถวเสริม — คนที่แตะป้าย "Verified by" บนผลงานมาถึงแผ่นนี้ต้องเจอคำตอบเรื่องงานด้วย */
        private fun workRow(c: CreatorProfile): List<Row> {
            val n = c.track.works.size
            if (n <= 0) return emptyList()
            return listOf(
                Row(id = 3, title = "ประวัติงานในระบบ", detail = "งานที่ทำผ่าน Sale Here",
                    value = "$n งาน", ok = true, required = false),
            )
        }

        /** เลขประจำการ์ด — คงที่ต่อชื่อผู้ใช้ (FNV-1a 32 บิต · ของจริงจะเป็นเลขที่ระบบออกให้) */
        private fun serial(handle: String): String {
            var h = 2166136261u
            for (b in handle.toByteArray(Charsets.UTF_8)) {
                h = (h xor b.toUByte().toUInt()) * 16777619u
            }
            return String.format(Locale.US, "TH %07d", (h % 9_000_000u).toInt() + 1_000_000)
        }

        /** ปลายทางของการแตะในหน้าดู — `CardScreen.open` รับไปเปิดแผ่นตรวจสอบ */
        const val sheetURL = "starcard://verified"
    }
}
