package co.salehere.starcard.model

import androidx.compose.runtime.compositionLocalOf
import co.salehere.starcard.layout.SpecDataSource
import co.salehere.starcard.layout.SpecFont
import co.salehere.starcard.layout.SpecItem
import co.salehere.starcard.layout.swiftDouble
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.WidgetTextStyle
import java.util.Locale
import java.util.UUID

// MARK: - แหล่งข้อมูลของผัง (Android) (= `IOSSpecData` ท้าย Views/Widgets/SpecPainter.swift)
//
// ชื่อฟิลด์ของทุกรายการและรูปแบบตัวเลขต้องตรง WIDGET-SPEC.md §3.2 ทุกตัว — fixture เทียบสตริงตรง ๆ
// ค่าทศนิยมดิบ (`shareRaw` · `engagementRaw`) เขียนแบบ `String(Double)` ของ Swift (`swiftDouble`)

/**
 * แหล่งข้อมูลที่ส่งแทนของแอป — ใช้ตอนส่งออกเทียบภาพกับ iOS (เล่นคำตอบที่ iOS บันทึกไว้ใน fixture ซ้ำ)
 * null = ใช้ `AndroidSpecData` ตามปกติ
 */
val LocalSpecDataOverride = compositionLocalOf<SpecDataSource?> { null }

/** = `Fmt.thousands` ของ iOS — เลขพันคั่นลูกน้ำ (12,000) */
fun Fmt.thousands(n: Int): String = baht(n)

/** ชื่อ icon ในผังของช่องนี้ — `sh:<platform>` (iOS ส่งชื่อ asset ตรง ๆ · Android asset เป็น id จึงส่งชื่อสั้นให้ `SpecIcon` แปลง) */
private val SocialType.specIcon: String get() = "sh:$raw"

/** ตรารับรองผ่านแล้ว (= `VerifiedFacts.sealed` ใน VerifiedSealWidget.swift) */
private val sealed: Boolean get() = VerifiedFacts.labForce || StarFlow.shared.isVerified

data class AndroidSpecData(
    val sample: Boolean,
    val widget: UUID?,
    val inkLight: Boolean = false,
    val kit: KitConfig = KitConfig(),
    val border: Boolean = false,
    /** พื้นผิวที่ผู้ใช้เลือกให้ชิ้น — ผังอ่านเป็น `surface=glass` · `papered` (WIDGET-SPEC.md §3.4) */
    val surface: WidgetSurface = WidgetSurface.glass,
    /** การ์ดคู่สีอยู่ไหม — สำรับกระดาษ/โปสเตอร์สลับแผ่นเป็นสีเข้มของคู่ */
    val duo: Boolean = false,
    /** ใบนี้ได้ป้าย "Verified by Sale Here" — ผังวาดพิลเมื่อ `stamped` */
    val stamped: Boolean = false,
    /** รูปช่อง 1 เป็นคนที่ตัดพื้นแล้ว — ใบโปสเตอร์สลับ "คนยืนคร่อม" กับ "รูปในกรอบ" */
    val cutout: Boolean = false,
    /** แผ่นของชุดห้าสไตล์มืดไหม (`KitLook.dark`) */
    val kitDark: Boolean = false,
) : SpecDataSource {

    // ชุดที่ "โชว์" — ตระกูลที่ยังไม่มีข้อมูลยืมตัวอย่างมาวาด (= `shown…` ใน Profile.swift)
    private val p: Profile get() = Profile.me
    private fun lacks(f: WidgetFamily): Boolean = f in p.sampleFamilies
    private val shownSocials: List<SocialProfile> get() = if (lacks(WidgetFamily.followers)) Mock.creator.socials else p.creator.socials
    private val shownRates: List<RateItem> get() = if (lacks(WidgetFamily.rate)) Mock.creator.rates else p.creator.rates
    private val shownAudience: AudienceInsight get() = if (lacks(WidgetFamily.audience)) Mock.creator.audience else p.creator.audience
    private fun shownTrack(f: WidgetFamily): TrackRecord = if (lacks(f)) Mock.creator.track else p.creator.track
    private val shownAbout: String get() = p.shownAbout

    private fun pct0(v: Double): String = Fmt.f(v, 0) + "%"

    override fun text(slot: String, preset: String?): String {
        // ค่าที่ระบบคิดให้ (อ่านอย่างเดียว) — `stat:<name>`
        if (slot.startsWith("stat:")) {
            val a = shownAudience
            return when (slot.drop(5)) {
                // ช่องทางติดต่อของ Star Profile (เบอร์จัดรูป 3-3-4) — iOS อ่าน `StarFlow.phone/lineID/website` ตรง ๆ (ว่าง = ว่าง ไม่ใช่ประโยคชวนกรอก)
                // Android เก็บค่าเดียวกันในโปรไฟล์ (`Profile.sync` ของ iOS เขียน `values.phone/lineId/website` = StarFlow · ซิงก์มาทางห้องลองทำ) จึงอ่าน `stored` ไม่ใช่ `text`
                "phoneFmt" -> {
                    val v = p.stored(ProfileField.phone) ?: ""
                    if (v.isEmpty()) return if (sample) "081-234-5678" else ""
                    val d = v.filter { it.isDigit() }
                    if (d.length == 10) "${d.take(3)}-${d.substring(3, 6)}-${d.takeLast(4)}" else v
                }
                "site" -> {
                    val v = (p.stored(ProfileField.website) ?: "").replace("https://", "").replace("http://", "")
                    if (v.isEmpty() && sample) "nirabeauty.co" else v
                }
                "lineFlow" -> (p.stored(ProfileField.lineId) ?: "").ifEmpty { if (sample) "@nirabeauty" else "" }
                "totalFollowers" -> Fmt.compact(shownSocials.sumOf { it.followerCount })
                "avgViews" -> Fmt.compact(shownSocials.sumOf { it.avgViewCount } / maxOf(1, shownSocials.size))
                "brandCount" -> shownTrack(WidgetFamily.brand).brands.size.toString()
                "workCount" -> shownTrack(WidgetFamily.verified).works.size.toString()
                "socialCount" -> shownSocials.size.toString()
                // ประเภทครีเอเตอร์ (API `creatorType`) — ยังไม่ตอบ = ว่าง (= iOS)
                "creatorKind" -> when (p.intake?.kind) { CreatorKind.creator -> "บุคคล"; CreatorKind.page -> "เพจ"; null -> if (sample) "บุคคล" else "" }
                "rateCount" -> shownRates.count { it.price > 0 }.toString()
                "cardURL" -> "https://salehere.co.th/star/" + p.handle
                "year" -> "2026"
                "placeCount" -> a.places.size.toString()
                // ยังไม่มีการเข้าถึง (0) = ว่าง — ผังซ่อนบล็อกด้วย `has:stat:reach` (= iOS)
                "reach" -> if (a.reach.accounts > 0) Fmt.compact(a.reach.accounts) else ""
                "reachRaw" -> if (a.reach.accounts > 0) a.reach.accounts.toString() else ""
                "reachDelta" -> if (a.reach.accounts > 0) (if (a.reach.delta >= 0) "+" else "") + Fmt.pct(a.reach.delta) else ""
                "reachNew" -> if (a.reach.accounts > 0) Fmt.pct(a.reach.newShare) else ""
                "reachWindow" -> a.reach.window
                "reachPlatform" -> a.reach.platform.name
                "reachIcon" -> a.reach.platform.specIcon
                else -> ""
            }
        }
        // จำนวนชิ้นของรายการ — `count:<list>`
        if (slot.startsWith("count:")) return list(slot.drop(6)).size.toString()
        val parts = slot.split("#", limit = 2)
        val field = ProfileField.from(parts[0]) ?: return ""
        val index = if (parts.size > 1) parts[1].toIntOrNull() else null
        if (field == ProfileField.about && sample) return shownAbout
        // ช่องอิสระของชิ้น: ค่าที่พิมพ์ → ข้อความตั้งต้นของดีไซน์ (preset) → ป้ายชวนพิมพ์
        val id = TextSlotID(field = field, index = index, widget = if (field == ProfileField.note) widget else null, preset = preset ?: "")
        return p.text(id)
    }

    override fun flag(name: String): Boolean {
        when (name) {
            "owner.verified" -> return sealed || p.creator.verified
            "sample" -> return sample
            "ink.light" -> return inkLight
            "bordered" -> return border
            // พื้นผิวของชิ้น: `papered` = ใบวาดแผ่น/กระดาษของตัวเอง (กระจก · เข้ม)
            "papered" -> return surface == WidgetSurface.glass || surface == WidgetSurface.dim
            "duo" -> return duo
            "stamped" -> return stamped
            "cutout" -> return cutout
            "kit.dark" -> return kitDark
        }
        if (name.startsWith("surface=")) return surface.raw == name.drop(8)
        // ค่าของชิ้นในชุดห้าสไตล์: `cfg:style=mac` · `opt:qr` · `opt:mode=fmt` · `hidden:instagram`
        if (name.startsWith("cfg:")) {
            val body = name.drop(4)
            val eq = body.indexOf('=')
            if (eq < 0) return false
            val k = body.substring(0, eq); val v = body.substring(eq + 1)
            return when (k) {
                "fill" -> kit.fill.raw == v
                "corner" -> kit.corner.raw == v
                else -> false
            }
        }
        if (name.startsWith("opt:")) {
            val body = name.drop(4)
            val eq = body.indexOf('=')
            if (eq >= 0) return (kit.opts[body.substring(0, eq)] ?: "") == body.substring(eq + 1)
            val v = kit.opts[body] ?: ""
            return v.isNotEmpty() && v != "0"
        }
        if (name.startsWith("hidden:")) return kit.list(KitOpt.hide).contains(name.drop(7))
        return false
    }

    override fun list(name: String): List<SpecItem> = when (name) {
        "categories" -> p.categories.mapIndexed { i, c -> SpecItem("cat$i", i, mapOf("text" to c)) }
        "socials" -> shownSocials.mapIndexed { i, s ->
            SpecItem(s.type.raw, i, mapOf(
                "platform" to s.type.raw, "name" to s.type.name, "short" to s.type.shortName,
                "icon" to s.type.specIcon, "tint" to s.type.tintHex, "handle" to s.handle, "followers" to Fmt.compact(s.followerCount),
                "followersRaw" to s.followerCount.toString(), "followersFull" to Fmt.thousands(s.followerCount),
                "viewsFull" to Fmt.thousands(s.avgViewCount),
                "views" to Fmt.compact(s.avgViewCount), "viewsRaw" to s.avgViewCount.toString(), "engagement" to Fmt.f(s.engagementRate, 1) + "%",
                "engagementRaw" to swiftDouble(s.engagementRate), "synced" to s.syncedAgo, "verified" to (if (s.source.isVerified) "1" else ""),
            ))
        }
        "rates" -> shownRates.filter { it.price > 0 }.mapIndexed { i, r ->
            SpecItem(r.id, i, mapOf(
                "label" to r.label, "price" to "฿" + Fmt.thousands(r.price), "priceRaw" to r.price.toString(),
                "unit" to r.unit, "platform" to r.platform.raw, "platformName" to r.platform.name,
                "platformOrder" to SocialType.entries.indexOf(r.platform).let { if (it < 0) 99 else it }.toString(),
                "priceNum" to Fmt.thousands(r.price), "icon" to r.platform.specIcon, "tint" to r.platform.tintHex, "format" to r.format.raw,
            ))
        }
        "brands" -> shownTrack(WidgetFamily.brand).brands.mapIndexed { i, b ->
            SpecItem(b.name, i, mapOf("name" to b.name, "logo" to (b.logo ?: ""), "industry" to b.industry))
        }
        "works" -> {
            val track = shownTrack(WidgetFamily.verified)
            track.works.mapIndexed { i, w ->
                SpecItem(w.id.toString(), i, mapOf(
                    "brand" to w.brand, "ep" to w.ep, "campaign" to w.campaign, "platform" to w.platform.raw,
                    "icon" to w.platform.specIcon, "tint" to w.platform.tintHex, "format" to w.format, "views" to Fmt.compact(w.views),
                    "viewsRaw" to w.views.toString(), "photo" to (4 + i).toString(),
                    // ผลงานตัวจริงของชิ้น: ปก asset ก่อน · ไม่มีก็ช่องรูปของผลงาน
                    "workPhoto" to w.photo.toString(), "cover" to (w.cover ?: ""),
                    "saves" to Fmt.compact(w.saves), "savesRaw" to w.saves.toString(), "shares" to Fmt.compact(w.shares), "sharesRaw" to w.shares.toString(),
                    "likes" to Fmt.compact(w.likes), "comments" to Fmt.compact(w.comments),
                    "engageRaw" to (w.likes + w.comments + w.shares + w.saves).toString(),
                    "engagement" to Fmt.f(w.engagementRate, 1) + "%", "viralTag" to (w.viralTag ?: ""),
                    // โลโก้แบรนด์ของผลงาน: URL ก่อน · ไม่มีก็ asset ในแอป (= iOS `logo ?? asset`)
                    "brandLogo" to (track.brands.firstOrNull { it.name == w.brand }?.let { it.logo ?: it.asset } ?: ""),
                ))
            }
        }
        "body" -> {
            // สัดส่วน (= `StarFlow.bodyInfo` ของ iOS) — Android เก็บเป็นค่าพร้อมหน่วยในโปรไฟล์ ("165 ซม." · "32 นิ้ว" · "38 EU" ที่ `Profile.sync` ของ iOS เขียน)
            // id h/w/g/s · label · value ("165 cm") · num · unit · wide ("1" = เต็มแถว) · ยังไม่กรอก + sample = ชุดเดียวกับ `StarBody.sample`
            val real = SpecBody.fromProfile(p)
            val b = if (real.filled || !sample) real else SpecBody.sample
            b.rows().mapIndexed { i, c ->
                SpecItem(c[0], i, mapOf("kind" to c[0], "label" to c[1], "value" to c[2], "num" to c[3], "unit" to c[4], "wide" to c[5]))
            }
        }
        "avail" -> {
            // วันเวลารับงาน (= `StarFlow.availSummary` ของ iOS: วันที่ช่วงเหมือนกันรวมกลุ่ม · ช่วงติดกันรวม) — ตารางรายวันมาจาก
            // ฟอร์ม (`intake.availability.days/slots` ที่ iOS แบนมาให้ทุกวันช่วงเดียวกัน) · ไม่มีฟอร์มใช้ป้ายของ wizard เครื่องนี้ (`availDays` · `availTime`)
            val s = availSummary(SpecAvail.week(p.intake?.availability, StarFlow.shared))
            val lines = if (s.isEmpty() && sample) listOf("ส–อา 17.00 เป็นต้นไป") else s
            lines.mapIndexed { i, t -> SpecItem("t$i", i, mapOf("text" to t)) }
        }
        "areas" -> {
            val lines = StarFlow.shared.provinces.ifEmpty { if (sample) listOf("กรุงเทพมหานคร", "นนทบุรี") else emptyList() }
            lines.mapIndexed { i, t -> SpecItem("a$i", i, mapOf("text" to t)) }
        }
        "contacts" -> {
            val out = ArrayList<SpecItem>()
            // = iOS ตัวต่อตัว: อ่าน `text` (ยังไม่กรอก = ประโยคชวนกรอกของช่อง) · ไอคอนที่สร้างที่นี่ต้องมี asset ทั้งสามแพลตฟอร์ม (`SpecIconCoverageTest`)
            val pairs = listOf(
                arrayOf("phone", p.phone, "ph:phone", "phone"), arrayOf("email", p.email, "ph:envelope", "email"),
                arrayOf("line", p.lineId, "sh:line", "lineId"), arrayOf("web", p.website, "ph:globe", "website"),
            )
            for ((k, v, icon, slot) in pairs) if (v.isNotEmpty()) {
                out.add(SpecItem(k, out.size, mapOf("kind" to k, "value" to v, "icon" to icon, "slot" to slot)))
            }
            out
        }
        "ages" -> shownAudience.ages.mapIndexed { i, a ->
            SpecItem(a.label, i, mapOf("label" to a.label, "share" to pct0(a.share), "shareRaw" to swiftDouble(a.share)))
        }
        "places" -> shownAudience.places.mapIndexed { i, a ->
            SpecItem(a.name, i, mapOf("name" to a.name, "share" to pct0(a.share), "shareRaw" to swiftDouble(a.share)))
        }
        "gender" -> {
            val a = shownAudience
            listOf(Triple("หญิง", a.female, "#FF8CBD"), Triple("ชาย", a.male, "#8299FF"), Triple("อื่น ๆ", a.other, "#5CE6AD")).mapIndexed { i, g ->
                SpecItem(g.first, i, mapOf("label" to g.first, "share" to pct0(g.second), "shareRaw" to swiftDouble(g.second), "tint" to g.third))
            }
        }
        "photos" -> (0 until 6).map { SpecItem("p$it", it, mapOf("photo" to (4 + it).toString())) }
        else -> emptyList()
    }

    override fun font(slot: String?, face: String, size: Double, weight: Int): SpecFont {
        var f = SpecFont(face = CardFont.from(face)?.raw ?: "noto", size = size, weight = weight)
        if (slot != null) {
            val parts = slot.split("#", limit = 2)
            val field = ProfileField.from(parts[0])
            // ช่องที่ผูกข้อมูลจำกัดขนาด 6–160 (ไม่มีการปรับขนาด/ฟอนต์ของผู้ใช้แล้ว)
            if (field != null) f = f.copy(size = minOf(maxOf(size, 6.0), 160.0))
        }
        return f
    }
}

// MARK: - สัดส่วน (= `StarBody` ของ iOS · ค่าดิบไม่มีหน่วย + หน่วยรอบตัวต่อช่อง)

internal class SpecBody(
    val weight: String = "", val height: String = "", val chest: String = "", val waist: String = "", val hip: String = "", val shoe: String = "",
    val chestUnit: String = inch, val waistUnit: String = inch, val hipUnit: String = inch,
) {
    val filled: Boolean get() = listOf(weight, height, chest, waist, hip, shoe).any { it.isNotEmpty() }

    /** แถวของรายการ `body`: kind · label · value · num · unit · wide — ลำดับและข้อความ = `IOSSpecData.list("body")` */
    fun rows(): List<List<String>> {
        val out = ArrayList<List<String>>()
        if (height.isNotEmpty()) out += listOf("h", "ส่วนสูง", "$height cm", height, cm, "")
        if (weight.isNotEmpty()) out += listOf("w", "น้ำหนัก", "$weight kg", weight, "กก.", "")
        val girth = listOf(chest, waist, hip)
        if (girth.any { it.isNotEmpty() }) {
            val same = setOf(chestUnit, waistUnit, hipUnit).size == 1
            val v = if (same) girth.joinToString(" / ") { it.ifEmpty { "–" } }
                    else listOf(chest to chestUnit, waist to waistUnit, hip to hipUnit).joinToString(" · ") { "${it.first} ${it.second}" }
            out += listOf("g", "รอบอก / เอว / สะโพก", v, v, if (same) chestUnit else "", "1")
        }
        if (shoe.isNotEmpty()) out += listOf("s", "ไซซ์รองเท้า", "EU $shoe", shoe, "EU", "")
        return out
    }

    companion object {
        const val inch = "นิ้ว"
        const val cm = "ซม."
        val sample = SpecBody(weight = "48", height = "165", chest = "32", waist = "25", hip = "35", shoe = "38")

        private val numUnit = Regex("""^\s*(\d+(?:\.\d+)?)\s*(.*)$""")

        /** "32 นิ้ว" → (32, นิ้ว) · "165 ซม." → (165, ซม.) · "38 EU" → (38, EU) · ไม่ขึ้นต้นด้วยตัวเลข (ว่าง/ประโยคชวนกรอก) = ("", "") */
        private fun split(v: String?): Pair<String, String> {
            val m = numUnit.find(v ?: return "" to "") ?: return "" to ""
            return m.groupValues[1] to m.groupValues[2].trim()
        }

        /** ช่องสัดส่วนของโปรไฟล์ (ค่าที่ `Profile.sync` ของ iOS เขียน: `weight/height/bust/waist/hips/shoe` พร้อมหน่วย) */
        fun fromProfile(p: Profile): SpecBody {
            val (chest, cu) = split(p.stored(ProfileField.bust))
            val (waist, wu) = split(p.stored(ProfileField.waist))
            val (hip, hu) = split(p.stored(ProfileField.hips))
            return SpecBody(
                weight = split(p.stored(ProfileField.weight)).first, height = split(p.stored(ProfileField.height)).first,
                chest = chest, waist = waist, hip = hip, shoe = split(p.stored(ProfileField.shoe)).first,
                chestUnit = cu.ifEmpty { inch }, waistUnit = wu.ifEmpty { inch }, hipUnit = hu.ifEmpty { inch },
            )
        }
    }
}

// MARK: - วันเวลารับงาน (= `StarFlow.availSummary` · `slotText` ของ iOS)

internal object SpecAvail {
    /** ชื่อย่อ 7 วันเรียง จ→อา (= `IntakeCatalog.weekShort` ของ iOS · ดัชนี 0 = จันทร์) */
    val weekShort = listOf("จ", "อ", "พ", "พฤ", "ศ", "ส", "อา")
    /** 4 ช่วงของแอปหลัก (slot_09_12 · slot_12_14 · slot_14_17 · slot_17_late) — ชั่วโมงเริ่ม–จบ (null = เป็นต้นไป) */
    private val slotHours: List<Pair<Int, Int?>> = listOf(9 to 12, 12 to 14, 14 to 17, 17 to null)

    private fun hourText(from: Int, to: Int?): String =
        if (to != null) String.format(Locale.US, "%02d.00–%02d.00", from, to) else String.format(Locale.US, "%02d.00 เป็นต้นไป", from)

    /** ครบ 4 = "ตลอดวัน" · ติดกันรวมเป็น "09.00–14.00" · ห่างกันคั่นด้วย " + " · ว่าง = "" */
    fun slotText(slots: Set<Int>): String {
        val picked = slotHours.indices.filter { it in slots }
        if (picked.isEmpty()) return ""
        if (picked.size == slotHours.size) return "ตลอดวัน"
        val runs = ArrayList<Pair<Int, Int?>>()
        for (i in picked) {
            val h = slotHours[i]
            val last = runs.lastOrNull()
            if (last != null && last.second == h.first) runs[runs.size - 1] = last.first to h.second else runs += h
        }
        return runs.joinToString(" + ") { hourText(it.first, it.second) }
    }

    /**
     * ตารางรายวัน week[0 = จันทร์ … 6 = อาทิตย์] = ชุดช่วงที่ว่าง
     * ฟอร์มมี = `availability.days` (0 = อาทิตย์) × `slots` (ทุกวันช่วงเดียวกัน — iOS แบนตารางมาแบบนี้ตอน sync) ·
     * ไม่มีฟอร์ม = ป้ายของ wizard เครื่องนี้ ("ทุกวัน" · "ส.–อา." · "จ.–ศ." · "จ อ ส อา" + เช้า/บ่าย/เย็น/ตลอดวัน)
     */
    fun week(a: Availability?, f: StarFlow): List<Set<Int>> {
        val days: Set<Int>; val slots: Set<Int>
        if (a != null && a.days.isNotEmpty()) { days = a.days; slots = a.slots }
        else { days = daysOf(f.availDays); slots = IntakeCatalog.timeOptions.firstOrNull { it.value == f.availTime }?.slots ?: emptySet() }
        return weekShort.indices.map { i -> if ((i + 1) % 7 in days) slots else emptySet() }
    }

    /** ป้ายวันของ wizard → ชุดวัน 0 = อาทิตย์ (= `IntakeCatalog.days` ของ iOS) */
    private fun daysOf(label: String): Set<Int> {
        val parts = label.split(" ").filter { it.isNotEmpty() }
        if (parts.isNotEmpty() && parts.all { it in weekShort }) return parts.map { (weekShort.indexOf(it) + 1) % 7 }.toSet()
        IntakeCatalog.dayOptions.firstOrNull { it.value == label }?.let { return it.days }
        if (label.startsWith("ส")) return setOf(0, 6)
        if (label.startsWith("จ")) return (1..5).toSet()
        return (0 until 7).toSet()
    }
}

/** "จ–ศ 17.00 เป็นต้นไป" · "ส อา ตลอดวัน" — วันที่ช่วงเหมือนกันรวมเป็นกลุ่ม · ติดกันเกิน 2 วันเขียนเป็นช่วง (= iOS ทุกตัวอักษร) */
internal fun availSummary(week: List<Set<Int>>): List<String> {
    val groups = ArrayList<Pair<Set<Int>, MutableList<Int>>>()
    for ((i, s) in week.withIndex()) {
        if (s.isEmpty()) continue
        val g = groups.firstOrNull { it.first == s }
        if (g != null) g.second += i else groups += s to mutableListOf(i)
    }
    return groups.map { (slots, days) ->
        val run = days.size > 2 && days.last() - days.first() == days.size - 1
        val d = if (run) "${SpecAvail.weekShort[days.first()]}–${SpecAvail.weekShort[days.last()]}" else days.joinToString(" ") { SpecAvail.weekShort[it] }
        "$d ${SpecAvail.slotText(slots)}"
    }
}
