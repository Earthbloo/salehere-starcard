package co.salehere.starcard.model

// MARK: - สัญญาข้อมูลของแต่ละตระกูล (= Model/WidgetContent.swift)
//
// widget บางตัวให้เจ้าของการ์ดพิมพ์ข้อความเองได้ ซึ่งแปลว่า **ข้อความนั้นต้องเก็บใน API**
// กติกา: **เก็บต่อ "ตระกูล" ไม่ใช่ต่อ "แบบ"** — หนึ่งตระกูล = หนึ่ง payload ที่ API คืนมาชุดเดียว
// การกด "แบบอื่น" จึงเปลี่ยนแค่ *วิธีวาด* ไม่ใช่ *ข้อมูลที่ต้องดึง*
//
// รูปร่างที่ API เก็บจริง:
//   StarCard
//   ├─ layout   ← ตำแหน่ง/ขนาด/พื้นผิว เก็บต่อ "ชิ้น" · pages[].items[] { family, variant, col, row, cols, rows, surface, border }
//   └─ content  ← เนื้อหา เก็บต่อ "ตระกูล" ทั้งการ์ดมีชุดเดียว · hero { name, tagline } · intro { about } · tags { items[] } ·
//                 words { quote } · contact { name, role, phone, email, lineId }

/** ชนิดของช่องกรอก — ตัวกำหนดคีย์บอร์ด การตรวจค่า และหน้าตาของช่องในชีตแต่ง */
enum class FieldKind {
    /** บรรทัดเดียว */
    line,
    /** ย่อหน้า */
    paragraph,
    /** รายการคำ (ชิป) */
    list,
    phone, email
}

/**
 * หนึ่งช่องที่เจ้าของการ์ดพิมพ์เองได้
 * `key` คือคีย์ที่ API เก็บจริง — ตั้งให้ตรงกับชื่อฟิลด์ใน `CreatorProfile`
 */
data class EditableField(
    val key: String,
    val label: String,
    val kind: FieldKind,
    /** จำกัดความยาว — null = ไม่จำกัด · ค่านี้ต้องบังคับทั้งฝั่งแอปและฝั่ง API */
    val limit: Int? = null,
) {
    val id: String get() = key
}

/** สัญญาของหนึ่งตระกูล — **ทุกแบบในตระกูลต้องใช้ฟิลด์ชุดนี้ครบเท่ากัน** */
data class FamilyContract(
    /** ฟิลด์ที่เจ้าของการ์ดพิมพ์เอง — เก็บใน API ต่อตระกูล */
    val editable: List<EditableField>,
    /**
     * ฟิลด์ที่ระบบออกให้ — **ห้ามมีช่องกรอกเด็ดขาด**
     * ถ้าเปิดให้กรอก ตัวเลขจะกลายเป็นคำโฆษณา แล้วลากความน่าเชื่อของทั้งการ์ดลงไปด้วย
     */
    val system: List<String>,
    /** ที่มาของฟิลด์ระบบ — ใช้ตัดสินว่าต่อ backend ตัวไหนก่อน */
    val source: Source,
) {
    enum class Source(val raw: String) {
        none("—"),
        profile("โปรไฟล์ในระบบ"),
        oauth("OAuth ของแพลตฟอร์ม"),
        campaign("ประวัติแคมเปญในระบบ"),
        inbox("อินบ็อกซ์ในระบบ");

        companion object {
            fun from(raw: String?): Source? = entries.firstOrNull { it.raw == raw }
        }
    }
}

/**
 * สัญญาข้อมูลของตระกูลนี้
 * อ่านคู่กับคอมเมนต์บน `WidgetFamily` — ตัวนั้นบอก *กติกา* ตัวนี้บอก *ค่าจริง*
 */
val WidgetFamily.contract: FamilyContract
    get() = when (this) {
        WidgetFamily.hero ->
            // ตรายืนยันไม่ใช่ฟิลด์ที่แก้ได้ — มันคือสถานะที่ระบบออกให้ ติดมากับชื่อเสมอ
            // ชื่อเล่นเป็นช่องของตัวเอง ไม่ใช่คำแรกของชื่อ
            FamilyContract(
                editable = listOf(
                    EditableField("name", "ชื่อแสดงผล", FieldKind.line, limit = 40),
                    EditableField("nickname", "ชื่อเล่น", FieldKind.line, limit = 18),
                    EditableField("tagline", "สายงาน", FieldKind.line, limit = 100),
                ),
                system = listOf("verified"), source = FamilyContract.Source.profile,
            )

        WidgetFamily.intro ->
            FamilyContract(
                editable = listOf(
                    EditableField("about", "แนะนำตัว", FieldKind.paragraph, limit = 240),
                    EditableField("tagline", "สายงาน", FieldKind.line, limit = 100),
                ),
                system = emptyList(), source = FamilyContract.Source.none,
            )

        WidgetFamily.tags ->
            // สอง array อยู่ใน payload เดียวกัน — หมวดหมู่ทางการเป็น system ไม่ใช่ editable
            // เพราะค่านี้ถูกใช้จับคู่งานจริง ถ้าพิมพ์อิสระได้ ระบบจับคู่ไม่ได้
            FamilyContract(
                editable = listOf(EditableField("categories", "สายงานที่พิมพ์เอง", FieldKind.list, limit = 8)),
                system = listOf("interests"), source = FamilyContract.Source.profile,
            )

        WidgetFamily.words ->
            FamilyContract(
                editable = listOf(EditableField("quote", "คำพูด", FieldKind.line, limit = 120)),
                system = emptyList(), source = FamilyContract.Source.none,
            )

        WidgetFamily.text ->
            // **ข้อยกเว้นข้อเดียวของกติกา "เก็บต่อตระกูล"** — "ข้อความอิสระ" ไม่ใช่ข้อเท็จจริง
            // มันคือ *ของตกแต่งที่มีตัวอักษร* · ค่าจึงเก็บ **ต่อชิ้น** โดยอ้างด้วย id ของ widget (ดู `Profile.notes`)
            FamilyContract(
                editable = listOf(EditableField("note", "ข้อความ", FieldKind.paragraph, limit = 200)),
                system = emptyList(), source = FamilyContract.Source.none,
            )

        WidgetFamily.contact ->
            FamilyContract(
                editable = listOf(
                    EditableField("contactName", "ชื่อผู้รับงาน", FieldKind.line, limit = 40),
                    EditableField("role", "สถานะผู้รับงาน", FieldKind.line, limit = 60),
                    EditableField("phone", "เบอร์โทร", FieldKind.phone),
                    EditableField("email", "อีเมล", FieldKind.email),
                    EditableField("lineId", "ไลน์ไอดี", FieldKind.line, limit = 40),
                ),
                // เวลาตอบกลับต้องคำนวณจากอินบ็อกซ์จริง ให้กรอกเองเมื่อไหร่มันคือคำโฆษณา
                system = listOf("responseTime"), source = FamilyContract.Source.inbox,
            )

        WidgetFamily.rate ->
            // ราคาผู้ใช้ตั้งเอง แต่ "ราคาที่ตลาดจ่าย" มาจากระบบ — สองค่านี้ต้องอยู่คู่กันเสมอ
            // สองรายการคู่ขนาน — ลำดับที่ i ของทั้งสองคือเรตอันเดียวกัน
            FamilyContract(
                editable = listOf(
                    EditableField("rateLabels", "ชื่อรายการ", FieldKind.list, limit = 24),
                    EditableField("ratePrices", "ราคา", FieldKind.list, limit = 7),
                ),
                system = listOf("marketRate"), source = FamilyContract.Source.profile,
            )

        WidgetFamily.followers ->
            // แบบชิปกับการ์ดสรุปยอดวาดแค่ยอดฟอลโลว์ — ไม่ผิดสัญญา เพราะ payload เดียวกัน
            FamilyContract(
                editable = emptyList(),
                system = listOf(
                    "socials.followerCount", "socials.avgViewCount",
                    "socials.engagementRate", "socials.syncedAgo",
                ),
                source = FamilyContract.Source.oauth,
            )

        WidgetFamily.audience ->
            // สี่ตัวท้ายคือ **บรรทัดที่มา** ที่ทุกแบบต้องวาด (ดู `AudienceBasis`)
            FamilyContract(
                editable = emptyList(),
                system = listOf(
                    "audience.gender", "audience.ages", "audience.places",
                    "audience.platform", "audience.window",
                    "audience.totalViewers", "audience.newViewers",
                ),
                source = FamilyContract.Source.oauth,
            )

        WidgetFamily.brand ->
            FamilyContract(
                editable = emptyList(),
                system = listOf("track.brands", "track.brandCount"), source = FamilyContract.Source.campaign,
            )

        WidgetFamily.seal ->
            // ทั้งใบเป็นของระบบ — คำรับรองที่เจ้าของพิมพ์เองได้คือคำโฆษณา
            FamilyContract(
                editable = emptyList(),
                system = listOf(
                    "verify.identity", "verify.identityDate",
                    "socials.source", "socials.syncedAgo", "card.serial",
                ),
                source = FamilyContract.Source.profile,
            )

        WidgetFamily.verified ->
            FamilyContract(
                editable = emptyList(),
                system = listOf(
                    "works.photo", "works.brand", "works.platform",
                    "works.views", "works.saves", "works.shares",
                    "works.viralTag",
                ),
                source = FamilyContract.Source.campaign,
            )

        WidgetFamily.photo ->
            // รูปเก็บเป็น asset id ต่อ "ช่อง" ของ widget — ดูรายละเอียดที่ `PhotoStore`
            FamilyContract(
                editable = listOf(EditableField("photos", "รูปผลงาน", FieldKind.list)),
                system = emptyList(), source = FamilyContract.Source.none,
            )

        WidgetFamily.showcase ->
            // **เก็บต่อชิ้น เหมือนตระกูล `text`** — หัวเรื่องกับคำบรรยายใต้คลิปแต่ละใบ
            // เป็น *คำที่เขียนถึงงานชิ้นนั้น* — วางแผ่นนี้สองแผ่นเพื่อเล่าคนละชุดงานเป็นเรื่องปกติ
            FamilyContract(
                editable = listOf(
                    EditableField("note", "หัวเรื่อง · ชื่อลูกค้า · สรุปงาน", FieldKind.paragraph, limit = 200),
                    EditableField("photos", "รูปปกคลิป", FieldKind.list),
                ),
                system = emptyList(), source = FamilyContract.Source.none,
            )

        WidgetFamily.body ->
            // สัดส่วนร่างกาย — พิมพ์เองทุกช่อง (เป็นข้อเท็จจริงที่ระบบไม่มีทางรู้)
            // เก็บเป็นช่องแยกตามธรรมเนียมวงการ: หน่วยผสม กก./ซม./นิ้ว/EU พิมพ์ติดค่ามาเลย
            FamilyContract(
                editable = listOf(
                    EditableField("weight", "น้ำหนัก", FieldKind.line, limit = 12),
                    EditableField("height", "ส่วนสูง", FieldKind.line, limit = 12),
                    EditableField("bust", "รอบอก", FieldKind.line, limit = 12),
                    EditableField("waist", "เอว", FieldKind.line, limit = 12),
                    EditableField("hips", "สะโพก", FieldKind.line, limit = 12),
                    EditableField("shoe", "ขนาดรองเท้า", FieldKind.line, limit = 12),
                ),
                system = emptyList(), source = FamilyContract.Source.none,
            )
    }
