package co.salehere.starcard.model

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import co.salehere.starcard.components.EntranceStyle
import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.WidgetTextStyle
import java.util.UUID
import kotlin.math.roundToInt

// MARK: - Tier

/**
 * ชั้นของ widget — กำหนดว่าผู้ใช้แต่งได้แค่ไหน
 * กฎหลักของโปรดักต์: ชั้น `verified` แต่งหน้าตาไม่ได้ เพราะมันคือหลักฐาน ไม่ใช่งานศิลปะ
 */
enum class WidgetTier {
    /** แพลตฟอร์มออกให้ · ลากย้ายได้ · ขนาด/หน้าตาล็อก */
    verified,
    /** มาจาก OAuth · เลือก variant + ขนาดได้ · ตัวเลขแก้ไม่ได้ */
    connected,
    /** ตัวตน · อิสระเต็มที่ */
    personal;

    val label: String
        get() = when (this) {
            verified -> "หลักฐาน"
            connected -> "เชื่อมต่อ"
            personal -> "ตัวตน"
        }
    val icon: String
        get() = when (this) {
            verified -> "checkmark.seal.fill"
            connected -> "link"
            personal -> "paintbrush.fill"
        }
}

/**
 * หมวดใน gallery — แบ่งตาม "คำถามที่แบรนด์ถาม" เหลือสามคำถามใหญ่
 * ฉันเป็นใคร · จ้างฉันยังไง · ฉันทำอะไรมาแล้ว
 */
enum class WidgetGroup {
    about, booking, work;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            about -> "เกี่ยวกับฉัน"
            booking -> "รับงาน"
            work -> "ผลงาน"
        }
    val icon: String
        get() = when (this) {
            about -> "person.crop.square"
            booking -> "briefcase.fill"
            work -> "photo.on.rectangle.angled"
        }

    companion object {
        fun from(raw: String?): WidgetGroup? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ตระกูลของ widget — กลุ่มที่ "สลับหน้าตากันได้" เพราะเล่าเรื่องเดียวกัน
 *
 * กติกาข้อบังคับของทุกตระกูล: **ทุกแบบต้องแสดงฟิลด์ชุดเดียวกัน**
 * ถ้าแบบหนึ่งโชว์สองบรรทัดแต่อีกแบบโชว์บรรทัดเดียว การกด "แบบอื่น" จะกลายเป็นการ
 * *เพิ่ม/ลดข้อมูล* แทนที่จะเป็นการ *เปลี่ยนหน้าตา*
 */
enum class WidgetFamily {
    // ลำดับนี้คือลำดับที่โผล่ในตู้ — ของหลักมาก่อน ถ้อยคำปิดท้ายทั้งสองหมวด
    // `text` อยู่ต่อจาก `intro` ไม่ใช่ท้ายสุด · `seal` ต่อจาก `hero` ทันที
    hero, seal, intro, text, followers, audience, tags, brand, verified,
    photo, showcase, words, rate,
    // ชุดห้าสไตล์ — สองหัวข้อที่ตู้เดิมไม่มี (ผู้ใช้ 12 ต.ค. 2569)
    availability,
    /** สัดส่วนร่างกาย — สายแฟชั่น/บิวตี้/นายแบบ */
    body,
    contact;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            hero -> "โปรไฟล์"
            body -> "สัดส่วน"
            intro -> "แนะนำตัว"
            brand -> "แบรนด์"
            verified -> "ผลงานยืนยัน"
            seal -> "ตรารับรอง"
            followers -> "ผู้ติดตาม"
            photo -> "รูปผลงาน"
            showcase -> "แผ่นโชว์ผลงาน"
            words -> "ถ้อยคำ"
            text -> "ข้อความ"
            tags -> "หมวดหมู่"
            audience -> "ผู้ชม"
            rate -> "เรตราคา"
            contact -> "ติดต่อ"
            availability -> "วันเวลาและพื้นที่"
        }

    /**
     * หัวข้อใน Star Profile ที่ตระกูลนี้ดึงข้อมูลมาโชว์ — null = ไม่ผูก (ของตกแต่ง / ผลงานจาก Portfolio / ข้อมูลบัญชี)
     * ผูกแล้วได้สองอย่าง: ยังไม่กรอกหัวข้อนั้น = ช่องในตู้พาไปกรอกข้อนั้นข้อเดียว ·
     * กรอกครบ = ทุกแบบในตระกูลใช้ได้ทันที (ผู้ใช้ 23 ก.ย. 2569)
     */
    val topic: StarTopic?
        get() = when (this) {
            hero, tags -> StarTopic.Data(StarDataKey.categories)
            followers -> StarTopic.Data(StarDataKey.socials)
            intro, words -> StarTopic.Data(StarDataKey.about)
            rate -> StarTopic.Data(StarDataKey.rate)
            audience -> StarTopic.Data(StarDataKey.insight)
            seal -> StarTopic.Verify
            // แบรนด์ + ผลงานยืนยัน = หลักฐานจากระบบ ปลดล็อกเมื่อทำงานผ่าน Sale Here จบแล้วอย่างน้อย 1 งาน (ผู้ใช้ 23 ก.ย. 2569)
            brand, verified -> StarTopic.Work
            // ติดต่อ · รูปผลงาน ผูกหัวข้อด้วย (ผู้ใช้ 19 ต.ค. 2569: เปิดการ์ดถามแค่ 3 ข้อ ที่เหลือล็อกจนกว่าจะกรอก) = iOS
            // Android ยังไม่มี StarDataKey.contact (Star Profile ฝั่งนี้ยังไม่ได้ port ช่องทางติดต่อ) — ติดต่อจึงยังไม่ล็อก ต่างจาก iOS
            photo, showcase -> StarTopic.Data(StarDataKey.media)
            text, contact -> null
            availability -> StarTopic.Data(StarDataKey.availability)
            body -> StarTopic.Data(StarDataKey.body)
        }

    val trayGroup: TrayGroup
        get() = when (this) {
            hero -> TrayGroup.profile
            followers -> TrayGroup.channels
            tags -> TrayGroup.niche
            intro, words -> TrayGroup.intro
            rate -> TrayGroup.rate
            audience -> TrayGroup.audience
            seal -> TrayGroup.verify
            photo, showcase, brand, verified -> TrayGroup.work
            contact -> TrayGroup.contact
            text -> TrayGroup.decor
            availability -> TrayGroup.schedule
            body -> TrayGroup.body
        }

    /** ส่วนของตู้ (เกี่ยวกับฉัน · รับงาน · ผลงาน) — ทั้งหมวดเท่ากัน */
    val group: WidgetGroup
        get() = when (this) {
            hero, seal, intro, text, followers, audience, tags, body, words -> WidgetGroup.about
            rate, availability, contact -> WidgetGroup.booking
            brand, verified, photo, showcase -> WidgetGroup.work
        }

    /** ชั้นสิทธิ์ตั้งต้นของหมวด — ใบที่ต่างจากเพื่อนใส่ `widget.tier` ทับ */
    val tier: WidgetTier
        get() = when (this) {
            followers, audience, rate -> WidgetTier.connected
            brand, verified, seal -> WidgetTier.verified
            else -> WidgetTier.personal
        }

    /** ใบในหมวดนี้ยังล็อกอยู่ไหม — ตรารับรองล็อกจนกว่าการยืนยันตัวตนจะผ่าน · ที่เหลือ = หัวข้อ Star Profile ยังไม่กรอก */
    val missing: Boolean
        get() = if (this == seal) !(VerifiedFacts.labForce || StarFlow.shared.isVerified)
            else topic?.let { !it.filled } ?: false

    companion object {
        fun from(raw: String?): WidgetFamily? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * หมวดในตู้ widget = หัวข้อของ Star Profile (ผู้ใช้ 23 ก.ย. 2569: "cat ต้องตรงกับ Star Profile แล้ว scroll เอาแทน")
 * ชิปเลื่อนแนวนอนแทนแท็บสามแท็บ · ลำดับ = ลำดับที่การ์ดเล่าเรื่อง
 * สามหมวดท้ายไม่ผูกกับ Star Profile: ผลงาน (จาก Portfolio) · ติดต่อ (จากบัญชี) · ข้อความ (ของตกแต่ง)
 */
enum class TrayGroup {
    profile, channels, niche, intro, body, rate, schedule, audience, verify, work, contact, decor;

    val raw: String get() = name
    val id: String get() = raw

    val label: String
        get() = when (this) {
            profile -> "โปรไฟล์"
            channels -> "ช่องทาง"
            niche -> "สายที่ใช่"
            intro -> "แนะนำตัว"
            rate -> "เรทรับงาน"
            body -> "สัดส่วน"
            schedule -> "วันเวลา·พื้นที่"
            audience -> "ข้อมูลผู้ติดตาม"
            verify -> "ยืนยันตัวตน"
            work -> "ผลงาน"
            contact -> "ติดต่อ"
            decor -> "ข้อความ"
        }

    val topic: StarTopic?
        get() = when (this) {
            profile, niche -> StarTopic.Data(StarDataKey.categories)
            channels -> StarTopic.Data(StarDataKey.socials)
            intro -> StarTopic.Data(StarDataKey.about)
            rate -> StarTopic.Data(StarDataKey.rate)
            audience -> StarTopic.Data(StarDataKey.insight)
            body -> StarTopic.Data(StarDataKey.body)
            schedule -> StarTopic.Data(StarDataKey.availability)
            verify -> StarTopic.Verify
            work -> StarTopic.Data(StarDataKey.media)
            contact, decor -> null
        }

    companion object {
        fun from(raw: String?): TrayGroup? = entries.firstOrNull { it.raw == raw }
    }
}

/** หัวข้อ Star Profile ที่ widget ผูกอยู่ — ช่องข้อมูล หรือ ยืนยันตัวตน */
sealed class StarTopic {
    data class Data(val key: StarDataKey) : StarTopic()
    data object Verify : StarTopic()
    /** เคยทำงานผ่าน Sale Here จบแล้ว — กรอกเองไม่ได้ ต้องไปรับงาน */
    data object Work : StarTopic()

    val label: String
        get() = when (this) {
            is Data -> key.label
            Verify -> "ยืนยันตัวตน"
            Work -> "ผลงานกับ Sale Here"
        }

    /** คำบนปุ่มของใบที่ยังว่าง */
    val action: String
        get() = when (this) {
            is Data -> "กรอก${key.label}"
            Verify -> "ยืนยันตัวตน"
            Work -> "ทำงานกับ Sale Here ก่อน"
        }

    /** คำบอกที่หัวหมวด */
    val missingLine: String
        get() = when (this) {
            is Data -> "ยังไม่มี${key.label}"
            Verify -> "ยังไม่ได้ยืนยันตัวตน"
            Work -> "ปลดล็อกเมื่อทำงานผ่าน Sale Here จบ 1 งาน"
        }

    /** ปลดล็อกด้วยการกรอกได้ไหม (ผลงานกับ Sale Here ต้องไปรับงาน ไม่มี wizard) */
    val fillable: Boolean get() = this != Work

    /** ขั้นของ wizard ที่ต้องเปิดเพื่อกรอกหัวข้อนี้ */
    val step: WizStep
        get() = when (this) {
            is Data -> WizStep.from(key.raw) ?: WizStep.about
            Verify -> WizStep.kyc
            Work -> WizStep.about
        }

    /** กรอกหัวข้อนี้แล้วหรือยัง (ดูจาก state ของ flow ใหม่ — ตัวเดียวกับ Star Profile) */
    val filled: Boolean
        get() = when (this) {
            is Data -> StarFlow.shared.has(key)
            Verify -> StarFlow.shared.verify != VerifyStatus.none
            Work -> StarFlow.shared.reviewed
        }
}

// MARK: - วัสดุของสำรับสติกเกอร์

/**
 * กระดาษเทป หรือ กระจกชมพู — เดิมคำนวณจากมุมของธีม ตอนนี้เป็นส่วนหนึ่งของชนิด
 * (ดู `WidgetKind.popSkin` · หน้าตาของแต่ละวัสดุอยู่ใน `PopWidgets`)
 */
enum class PopSkin {
    paper, glass;

    val raw: String get() = name

    val label: String
        get() = when (this) {
            paper -> "กระดาษเทป"
            glass -> "กระจกชมพู"
        }

    companion object {
        fun from(raw: String?): PopSkin? = entries.firstOrNull { it.raw == raw }
    }
}

// MARK: - Kind

/**
 * ชนิดของ widget = ชื่อไฟล์ผัง `shared/WidgetSpecs/<kind>.json` (= `struct WidgetKind` ของ iOS)
 *
 * **แอปไม่รู้จักชื่อ widget สักตัว** — ทุกนิสัย (ชื่อในตู้ · ไอคอน · ขนาด · พื้นผิว · ถาด · ป้าย · ท่าเข้า)
 * อ่านจากบล็อก `widget` ของไฟล์ผัง · ค่าที่ไม่ใส่ใช้ค่าของหมวด (`WidgetFamily`) หรือกติกากลางข้างล่าง
 * เพิ่มไฟล์ใหม่ = ขึ้นตู้ทันที · ลบไฟล์ = หายจากตู้เฉย ๆ
 *
 * ข้อยกเว้นเดียวคือ **ชั้นข้อความ** (`textLayer`) — ตัวอักษรที่พิมพ์ลงการ์ดแบบ IG ไม่ใช่ widget จึงไม่มีไฟล์ผัง
 * คีย์ในไฟล์การ์ดยังเป็น `textBlock` ตามเดิม การ์ดเก่าจึงเปิดได้
 */
class WidgetKind private constructor(
    /** คีย์ที่บันทึกลงการ์ด = ชื่อไฟล์ผัง */
    val name: String,
) {
    val raw: String get() = name
    val id: String get() = name

    val isTextLayer: Boolean get() = name == TEXT_LAYER_KEY

    /** นิสัยของชนิดนี้ — บล็อก `widget` ของไฟล์ผัง (ชั้นข้อความใช้ `TEXT_LAYER`) */
    val meta: WidgetSpec.Widget
        get() = if (isTextLayer) TEXT_LAYER else SpecCatalog.widgetMeta(name) ?: WidgetSpec.Widget(title = name)

    override fun equals(other: Any?): Boolean = other is WidgetKind && other.name == name
    override fun hashCode(): Int = name.hashCode()
    override fun toString(): String = name

    val title: String get() = meta.title
    val symbol: String get() = meta.symbol ?: "square.fill"

    /** ขนาดตั้งต้น — `widget.size` ไม่ใส่ = ขนาดออกแบบของผัง */
    val defaultSize: Size
        get() {
            val s = meta.size ?: SpecCatalog.spec(named = name)?.design ?: return Size(366f, 224f)
            return Size(s.w.toFloat(), s.h.toFloat())
        }

    val aspect: Float
        get() {
            val s = defaultSize
            return s.height / maxOf(s.width, 1f)
        }

    fun height(forWidth: Float): Float = maxOf(1f, (forWidth * aspect).roundToInt().toFloat())
    fun size(forWidth: Float): Size = Size(forWidth, height(forWidth))

    /** หมวด — `widget.category` */
    val family: WidgetFamily get() = WidgetFamily.from(meta.category) ?: WidgetFamily.text
    /** ส่วนของตู้ — ค่าของหมวด */
    val group: WidgetGroup get() = family.group
    /** ชั้นสิทธิ์ — ค่าของหมวด · ใบที่ต่างจากเพื่อนใส่ `widget.tier` ทับ */
    val tier: WidgetTier get() = meta.tier?.let { t -> WidgetTier.entries.firstOrNull { it.name == t } } ?: family.tier

    /** วาดพื้นของตัวเอง — chrome ไม่ครอบแผ่น (`widget.ownSurface`) */
    val drawsOwnSurface: Boolean get() = meta.ownSurface ?: false
    /** วาดเส้นขอบของตัวเอง — chrome ไม่วาดเส้นซ้ำ (`widget.ownBorder`) */
    val drawsOwnBorder: Boolean get() = meta.ownBorder ?: false
    val usesSurfaceChoice: Boolean get() = surfaceOptions.size > 1
    val usesTextStyle: Boolean get() = isTextLayer
    val usesPhoto: Boolean get() = meta.photo ?: false
    val isFullBleed: Boolean get() = meta.fullBleed ?: false
    val canResize: Boolean get() = meta.resize ?: true
    val keepsDesignAspect: Boolean get() = meta.keepAspect ?: false

    /** พื้นผิวที่ใบนี้ให้เลือก (`widget.surfaces`) — ไม่ใส่: วาดพื้นเอง = ไม่มี · ไม่วาดเอง = กระจก/เข้ม/ไม่มีพื้น */
    val surfaceOptions: List<WidgetSurface>
        get() = meta.surfaces?.mapNotNull { r -> WidgetSurface.entries.firstOrNull { it.name == r } }
            ?: if (drawsOwnSurface) emptyList() else listOf(WidgetSurface.glass, WidgetSurface.dim, WidgetSurface.clear)

    /** พื้นผิวตั้งต้น = ตัวเลือกแรกของถาด (ไม่มีตัวเลือก = กระจก) */
    val defaultSurface: WidgetSurface get() = surfaceOptions.firstOrNull() ?: WidgetSurface.glass

    /** ชื่อตัวเลือกพื้นผิวบนถาด — `widget.surfaceNames` ทับชื่อกลาง */
    fun surfaceName(s: WidgetSurface): String = meta.surfaceNames?.get(s.name) ?: s.displayName

    /** ตัวเลือกในถาดของใบนี้ (`widget.controls`) */
    val controls: List<KitControl> get() = meta.controls ?: emptyList()

    /** เส้นขอบตั้งต้น — `widget.border` · ไม่ใส่ = มีเมื่อ chrome ครอบแผ่นให้ */
    val defaultBorder: Boolean get() = meta.border ?: !drawsOwnSurface

    /** วัสดุแผ่นสติกเกอร์ (`widget.skin`) */
    val popSkin: PopSkin? get() = PopSkin.from(meta.skin)

    /** ชิ้นที่ Sale Here วางให้ทุกการ์ด (`widget.pinned`) */
    val isPinnedKind: Boolean get() = meta.pinned ?: false

    /**
     * ผังของใบนี้วาดตรา Sale Here STAR ของตัวเอง (ไอคอน `embossedLockup`) — มีตลอด ไม่มีปุ่มปิด (19 ต.ค. 2569)
     * การ์ดที่มีใบแบบนี้ไม่ปั๊มตรามุมการ์ดซ้ำ (= `carriesEmboss` ของ iOS)
     */
    val carriesEmboss: Boolean get() {
        val spec = SpecCatalog.spec(this) ?: return false
        fun has(n: SpecNode): Boolean =
            n.icon == "embossedLockup" || n.children.orEmpty().any { has(it) } || (n.each?.let { has(it) } ?: false)
        return has(spec.root) || spec.variants.orEmpty().any { has(it.root) }
    }

    companion object {
        /** คีย์ของชั้นข้อความในไฟล์การ์ด — คงชื่อเดิม การ์ดเก่าจึงเปิดได้ */
        const val TEXT_LAYER_KEY = "textBlock"

        /** นิสัยของชั้นข้อความ (ไม่ใช่ widget จึงไม่มีไฟล์ผัง) — ชุดเดียวกับ `TextBlock.layer` ของ iOS */
        val TEXT_LAYER = WidgetSpec.Widget(
            title = "ข้อความ", category = "text", symbol = "textformat.size",
            size = SpecSize(366.0, 117.0), ownSurface = true, resize = false, motion = "light",
        )

        /** ชั้นข้อความของการ์ด */
        val textLayer: WidgetKind = WidgetKind(TEXT_LAYER_KEY)

        /** ทุกชนิดจากไฟล์ผัง เรียงตาม `widget.order` แล้วตามชื่อ — คิดครั้งเดียวต่อชุดผัง (ถาดเรียกทุกเฟรมตอนลาก/ยืด) */
        val entries: List<WidgetKind>
            get() {
                sortedCache?.let { if (it.first == SpecCatalog.generation) return it.second }
                val kinds = SpecCatalog.widgetKinds.mapNotNull { from(it) }
                    .sortedWith(compareBy<WidgetKind>({ it.meta.order ?: Int.MAX_VALUE }, { it.name }))
                sortedCache = SpecCatalog.generation to kinds
                return kinds
            }
        private var sortedCache: Pair<Int, List<WidgetKind>>? = null

        /** ชนิดจากไฟล์ผังที่ลงทะเบียนไว้ (หมวดต้องเป็นหมวดที่แอปรู้จัก) — ไม่รู้จัก = null */
        fun from(raw: String?): WidgetKind? {
            if (raw == null) return null
            if (raw == TEXT_LAYER_KEY) return textLayer
            val m = SpecCatalog.widgetMeta(raw) ?: return null
            WidgetFamily.from(m.category) ?: return null
            return WidgetKind(raw)
        }

        fun valueOf(raw: String): WidgetKind = from(raw) ?: throw IllegalArgumentException("No WidgetKind $raw")

        /**
         * อ่านชนิดจากไฟล์ — ชื่อเก่าที่ถอดแล้วตกไปที่ใบที่ประกาศ `widget.replaces`
         * ไฟล์เก่าของสำรับสติกเกอร์เขียนแค่ `popHero` — ลองต่อท้ายด้วยวัสดุตามธีมของไฟล์นั้น (`corner == .soft` = กระดาษ)
         */
        fun decode(raw: String, legacyPopSkin: PopSkin = PopSkin.glass, kitLook: String? = null): WidgetKind? {
            from(raw)?.let { return it }
            // ชุดห้าสไตล์ก่อน 19 ต.ค. 2569: ชนิดเดียวต่อหัวข้อ + `kit.style` ในชิ้น → ชนิดใหม่ที่ `widget.kit.look` ตรงกัน
            SpecCatalog.replacement(raw, kitLook)?.let { r -> from(r)?.let { return it } }
            val suffix = if (legacyPopSkin == PopSkin.paper) "Paper" else "Glass"
            return from(raw + suffix)
        }
    }
}

// MARK: - ความลึกของ widget ในสำรับ (= `extension WidgetKind` ใน Components/Motion.swift)

/**
 * ความลึกของ widget ในสำรับ — `widget.motion` (`deep` · `mid` · `light` · `anchored`)
 * กติกา: **ตัวที่มีท่าเป็นของตัวเองข้างในต้องได้ `anchored`** เพราะกรอบกับข้างในเล่นพร้อมกัน
 */
val WidgetKind.entranceStyle: EntranceStyle
    get() = when (meta.motion) {
        "deep" -> EntranceStyle.deep
        "light" -> EntranceStyle.light
        "anchored" -> EntranceStyle.anchored
        else -> EntranceStyle.mid
    }

// MARK: - พื้นผิวของชิ้นที่กำลังวาด (ส่งลงทาง CompositionLocal — = `EnvironmentValues` ของ iOS)

/** พื้นผิวที่ผู้ใช้เลือกให้ชิ้นนี้ — widget ที่วาดแผ่นเองอ่านค่านี้แทนที่จะให้ `WidgetChrome` ครอบ (= `\.widgetSurface`) */
val LocalWidgetSurface = compositionLocalOf { WidgetSurface.glass }

/** ลายบนแผ่นของชิ้นนี้ (= `\.widgetPattern`) */
val LocalWidgetPattern = compositionLocalOf { PlatePattern.plain }


/** เส้นขอบรอบชิ้น (= `\.widgetBorder`) */
val LocalWidgetBorder = compositionLocalOf { false }


/**
 * วัสดุที่ชนิดของชิ้นสั่งมา — ชิ้นส่วนร่วมของสำรับสติกเกอร์อยู่ลึกหลายชั้น
 * `null` แปลว่าไม่ได้วาดจากชนิดใดชนิดหนึ่ง (= `\.popSkin`)
 */
val LocalPopSkin = compositionLocalOf<PopSkin?> { null }

// MARK: - Plate pattern

/** ลายบนแผ่นทึบของ widget — เรียบ · ลายทาง · ข้าวหลามตัด */
enum class PlatePattern {
    plain, stripe, diamond;

    val raw: String get() = name
    val id: String get() = raw

    /** ชื่อไทยบนถาด (= `name` ของ Swift — `Enum.name` ของ Kotlin ถูกจองไว้ จึงเป็น `displayName` ตามแบบ `CardInk`) */
    val displayName: String
        get() = when (this) {
            plain -> "เรียบ"
            stripe -> "ลายทาง"
            diamond -> "ข้าวหลามตัด"
        }

    companion object {
        fun from(raw: String?): PlatePattern? = entries.firstOrNull { it.raw == raw }
    }
}

// MARK: - Surface

/**
 * พื้นผิวของ widget — ผู้ใช้เลือกทับค่าตั้งต้นของชนิดได้ทุกตัว
 * ของเดิมมี `จาง` กับ `โปร่ง` ด้วย — ทั้งคู่ถูกยุบมาเป็นกระจก (ดู `decode`) การ์ดเก่าจึงเปิดแล้วได้พื้นครบทุกชิ้นทันที
 */
enum class WidgetSurface {
    /** liquid glass */
    glass,
    /** แผ่นเข้มทึบ */
    dim,
    /**
     * **ไม่มีพื้นเลย** — เนื้อหานั่งบนการ์ดตรง ๆ ไม่มีแผ่น ไม่มีกระดาษ ไม่มีเงา
     * ตัวที่เลือกได้อยู่ที่ `WidgetKind.surfaceOptions` — ไม่ใช่ทุกใบที่ถอดพื้นแล้วยังอ่านออก
     */
    clear,
    /**
     * **กระจกของ chrome บนใบที่วาดวัสดุเอง** — กระดาษ/แผ่นพิมพ์ของมันถูกถอดออก
     * แล้วเอาเนื้อหาไปวางบนแผ่นกระจกใบเดียวกับที่ widget ตัวอื่นทั้งการ์ดใช้อยู่
     * ตอนวาด chrome ครอบกระจกให้ ส่วน widget ได้รับค่า `clear` ลงไป (ดู `WidgetChrome`)
     */
    pane;

    val raw: String get() = name
    val id: String get() = raw

    /** ชื่อไทยบนถาด (= `name` ของ Swift — `Enum.name` ของ Kotlin ถูกจองไว้ จึงเป็น `displayName` ตามแบบ `CardInk`) */
    val displayName: String
        get() = when (this) {
            glass -> "กระจก"
            dim -> "เข้ม"
            clear -> "ไม่มีพื้น"
            pane -> "กระจก"
        }

    companion object {
        fun from(raw: String?): WidgetSurface? = entries.firstOrNull { it.raw == raw }

        /** อ่านค่าจากไฟล์ — ชื่อที่เลิกใช้แล้ว (`faint`/`plain`) ตกมาเป็นกระจก ไม่ใช่ค่าว่าง */
        fun decode(raw: String): WidgetSurface = from(raw) ?: glass
    }
}

// MARK: - Instance

/**
 * ชิ้น widget หนึ่งชิ้นบนหน้า — พิกัดคือ **หน่วย pt บนพื้นที่ออกแบบ** อ้างมุมบนซ้ายของหน้า
 * เป็นพิกัดที่ผู้ใช้ *ขอ* ไม่ใช่พิกัดที่ได้จริง — `PageLayout.solve` เป็นคนตัดสินตอนวาด
 * ลำดับใน `CardPage.items` คือลำดับ "ใครได้ที่ก่อน" เวลาสองตัวขอที่เดียวกัน
 */
data class WidgetInstance(
    /** ส่งเข้ามาได้เฉพาะตอนกู้จากไฟล์ — ข้อความกับรูปของก้อนผูกกับ id นี้ (ดู `Profile.note`, `PhotoStore.perWidget`) */
    val id: UUID,
    var kind: WidgetKind,
    var x: Float,
    var y: Float,
    var w: Float,
    var h: Float,
    /** พื้นผิว — ตั้งต้นตามบุคลิกของชนิด (typography โปร่ง · แผ่นข้อมูลกระจก) */
    var surface: WidgetSurface,
    /** เส้นขอบรอบ widget — แยกจากพื้นผิว เพราะบางทีอยากได้กรอบโดยไม่เอาพื้น */
    var border: Boolean,
    /**
     * **ค่าที่ผู้ใช้เลือกในถาด** — คีย์ = `opt` ของ `widget.controls` · ค่าตั้งต้นไม่เก็บ (= `options` ของ iOS · 19 ต.ค. 2569)
     */
    var options: Map<String, String> = emptyMap(),
    /** หน้าตาตัวอักษร — ฟอนต์ · สี · ขนาด · การจัดวาง (อยู่ที่ชิ้น ไม่ใช่ที่ตระกูล — มันคือ *หน้าตา* ไม่ใช่ *เนื้อหา*) */
    var textStyle: WidgetTextStyle = WidgetTextStyle(),
) {
    /** ลายบนแผ่น — `options["pattern"]` */
    val pattern: PlatePattern get() = PlatePattern.from(options["pattern"]) ?: PlatePattern.plain

    /**
     * ชิ้นที่ Sale Here วางให้และ **ตรึงไว้กับก้นหน้า** — เป็นของชนิด (`widget.pinned`) ไม่ใช่ค่าที่เก็บในชิ้น
     * `y` ที่ถือไว้ไม่ถูกใช้: ตำแหน่งคิดจากก้นหน้าตอนวาดทุกครั้ง (ดู `PageLayout.pinnedFrame`)
     */
    val pinned: Boolean get() = kind.isPinnedKind

    /** หน้าตา + ตัวเลือกของชุดห้าสไตล์ — อ่านจาก `options` (`fill` · `corner` · ตัวเลือกเนื้อหา) + หน้าตาของชนิด */
    val kit: KitConfig
        get() = KitConfig(
            style = kind.kitStyle,
            fill = KitFill.entries.firstOrNull { it.name == options["fill"] } ?: KitFill.solid,
            corner = KitCorner.entries.firstOrNull { it.name == options["corner"] } ?: KitCorner.round,
            opts = options,
        )

    /** กรอบที่ตัวนี้ *ขอ* — ยังไม่ผ่านการรูดเข้าหน้าและการดันไม่ให้ทับกัน */
    val rect: Rect get() = Rect(x, y, x + w, y + h)

    /** สำเนาที่ย้าย/ยืดกรอบตาม `r` (= `rect` setter ของ Swift) */
    fun withRect(r: Rect): WidgetInstance = copy(x = r.left, y = r.top, w = r.width, h = r.height)

    /**
     * ย่อ/ขยาย **ทั้งชิ้นตามสัดส่วนที่เป็นอยู่** — หมุดมุมใช้ตัวนี้
     * ใช้สัดส่วนปัจจุบันของชิ้น ไม่ใช่สัดส่วนของชนิด
     */
    fun scale(toWidth: Float): WidgetInstance {
        val ratio = h / maxOf(w, 1f)
        return copy(w = toWidth, h = maxOf(1f, (toWidth * ratio).roundToInt().toFloat()))
    }

    /** คืนความสูงให้ตรงสัดส่วนที่ออกแบบไว้ — ใช้ตอนสลับแบบ (แบบใหม่มีผังของตัวเอง) */
    fun resetAspect(): WidgetInstance = copy(h = kind.height(w))

    /** สเกลของชิ้นเทียบกับผังที่ออกแบบไว้ — 1 = ขนาดจริง */
    val scale: Float get() = w / maxOf(kind.defaultSize.width, 1f)

    companion object {
        /**
         * = `init(_ kind:x:y:w:h:id:)` ของ Swift
         * ไม่ระบุ `h` = ได้ความสูงตาม **สัดส่วนที่ออกแบบไว้** ของความกว้างนั้น ไม่ใช่ความสูงตั้งต้นดิบ ๆ
         * (ผังในเทมเพลตจึงเขียนแค่ x/y/w แล้วได้ชิ้นที่สัดส่วนถูกต้องเสมอ — ยืดทีหลังได้ตามใจ)
         */
        fun make(
            kind: WidgetKind,
            x: Float = PageLayout.margin,
            y: Float = PageLayout.margin,
            w: Float? = null,
            h: Float? = null,
            id: UUID = UUID.randomUUID(),
        ): WidgetInstance {
            val width = w ?: kind.defaultSize.width
            return WidgetInstance(
                id = id,
                kind = kind,
                x = x,
                y = y,
                w = width,
                h = h ?: kind.height(width),
                surface = kind.defaultSurface,
                border = kind.defaultBorder,
            )
        }
    }
}

// MARK: - Catalog entry

/** รายการใน Widget Gallery — "ตู้รางวัล" */
class CatalogEntry(
    val kind: WidgetKind,
    val unlocked: Boolean = true,
    /** เงื่อนไขที่ต้องทำเพื่อปลดล็อก — null เมื่อปลดล็อกแล้ว */
    val requirement: String? = null,
) {
    val id: String = kind.raw + (if (unlocked) "" else "-locked")
}
