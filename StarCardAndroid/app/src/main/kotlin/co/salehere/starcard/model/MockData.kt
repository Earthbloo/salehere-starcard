package co.salehere.starcard.model

import androidx.compose.ui.graphics.Color
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.rgb
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

// MARK: - Domain (โครงตาม API เดิม — ยังไม่ต่อ backend) (= MockData.swift)
//
// โมเดลชุดนี้ถูกขยายให้ครอบสเปกข้อมูล 5 หมวดที่แบรนด์ใช้ตัดสินใจจ้างจริง
// กติกาข้อเดียวที่คุมทั้งไฟล์: **ฟิลด์ต้องผูกกับ "คำถามที่แบรนด์ถาม" ไม่ใช่ "ช่องที่กรอกได้"**

/**
 * ตัวเข้ารหัส JSON เป็นสตริง `raw` — สำหรับ enum ของ Swift ที่พอร์ตเป็น sealed class
 * (ตัวที่มี `name` ของตัวเอง ซึ่งชนกับ `Enum.name` ของ Kotlin: `SocialType` · `ContentFormat` · `StarSocial` · `StarFormat` · `WizStep`)
 */
internal open class RawSerializer<T : Any>(
    name: String,
    private val decode: (String) -> T?,
    private val encode: (T) -> String,
) : KSerializer<T> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(name, PrimitiveKind.STRING)
    override fun serialize(encoder: Encoder, value: T) = encoder.encodeString(encode(value))
    override fun deserialize(decoder: Decoder): T {
        val s = decoder.decodeString()
        return decode(s) ?: throw SerializationException("unknown ${descriptor.serialName}: $s")
    }
}

internal object SocialTypeSerializer : RawSerializer<SocialType>("SocialType", { SocialType.from(it) }, { it.raw })

/** ช่องทางโซเชียล — สองตัวท้ายมาจากฟอร์มสมัคร ไม่มี API ให้ดึงยอด (ดู `SocialType.fetch` ใน Intake.kt) */
@Serializable(with = SocialTypeSerializer::class)
sealed class SocialType(val raw: String) {
    object instagram : SocialType("instagram")
    object tiktok : SocialType("tiktok")
    object youtube : SocialType("youtube")
    object facebook : SocialType("facebook")
    object lemon8 : SocialType("lemon8")
    object x : SocialType("x")

    val id: String get() = raw
    val ordinal: Int get() = entries.indexOf(this)

    val name: String get() = when (this) {
        instagram -> "Instagram"
        tiktok -> "TikTok"
        youtube -> "YouTube"
        facebook -> "Facebook"
        lemon8 -> "Lemon8"
        x -> "X (Twitter)"
    }

    /** โลโก้แบรนด์ของจริง ยกมาจาก asset ของแอปหลัก */
    val icon: Int get() = when (this) {
        instagram -> SHIcon.instagram
        tiktok -> SHIcon.tiktok
        youtube -> SHIcon.youtube
        facebook -> SHIcon.facebook
        lemon8 -> SHIcon.lemon8
        x -> SHIcon.x
    }

    val tint: Color get() = when (this) {
        instagram -> rgb(0.91, 0.36, 0.62)
        tiktok -> rgb(0.20, 0.94, 0.92)
        youtube -> rgb(1.00, 0.32, 0.30)
        facebook -> rgb(0.36, 0.56, 0.98)
        lemon8 -> rgb(1.00, 0.84, 0.25)
        x -> rgb(0.85, 0.85, 0.88)
    }

    /** หน้าโปรไฟล์ที่เดาได้จาก handle — ตัวสำรองเมื่อยังไม่ได้เก็บลิงก์เต็มไว้ */
    fun profileURL(handle: String): String? {
        val h = if (handle.startsWith("@")) handle.drop(1) else handle
        if (h.isEmpty()) return null
        return when (this) {
            instagram -> Web.url("www.instagram.com/$h/")
            tiktok -> Web.url("www.tiktok.com/@$h")
            youtube -> Web.url("www.youtube.com/@$h")
            facebook -> Web.url("www.facebook.com/$h")
            lemon8 -> Web.url("www.lemon8-app.com/@$h")
            x -> Web.url("x.com/$h")
        }
    }

    override fun toString(): String = raw

    companion object {
        val entries: List<SocialType> by lazy { listOf(instagram, tiktok, youtube, facebook, lemon8, x) }
        fun from(raw: String?): SocialType? = entries.firstOrNull { it.raw == raw }
    }
}

/**
 * ตัวแปลงสตริงลิงก์ให้เป็น URL ที่เปิดได้จริง
 * ข้อมูลลิงก์ในระบบเขียนกันมาสองแบบ — เต็ม (`https://…`) กับย่อ (`tiktok.com/@x/7412`)
 * จุดเดียวที่เติม scheme ให้ทั้งแอปจึงอยู่ที่นี่ ไม่ใช่กระจายอยู่ตาม widget
 */
object Web {
    fun url(raw: String): String? {
        val s = raw.trim()
        if (s.isEmpty()) return null
        // `URL(string:)` ของ iOS ปฏิเสธช่องว่างกลางสตริง — ทำเหมือนกันเพื่อไม่ส่งลิงก์พังไปให้ตัวเปิด
        if (s.any { it.isWhitespace() }) return null
        return if (s.contains("://")) s else "https://$s"
    }
}

/**
 * ค่าเฉลี่ยต่อคลิปแบบแยกชนิด — สเปก 2.2 Engagement Metrics Breakdown
 * **ต้องมาจาก OAuth เท่านั้น** ถ้าเปิดให้กรอกมือ ตัวเลขชุดนี้จะกลายเป็นคำโฆษณา
 */
data class EngageMix(
    val likes: Int,
    val comments: Int,
    val shares: Int,
    /** ยอดบันทึก — ตัวที่สัมพันธ์กับ intent ซื้อมากที่สุดในสายบิวตี้/ไลฟ์สไตล์ */
    val saves: Int,
)

data class SocialProfile(
    val type: SocialType,
    val handle: String,
    val followerCount: Int,
    val avgEngagementCount: Int,
    val avgViewCount: Int,
    /** เวลาที่ระบบ sync ยอดล่าสุด — ตัวที่ทำให้การ์ด "ไม่มีวันเก่า" */
    val syncedAgo: String,
    /** สเปก 2.2 — ค่าเฉลี่ยย่อยต่อคลิป */
    val mix: EngageMix,
    /** สเปก 2.2 Post Frequency — คลิปต่อสัปดาห์ */
    val postsPerWeek: Double,
    /** สเปก 2.2 Average Engagement Rate รายช่อง */
    val engagementRate: Double,
    /** สเปก 2.1 — ลิงก์ตรงไปหน้าโปรไฟล์ของช่องนั้น · ว่างเมื่อไหร่จะประกอบจาก handle ให้แทน */
    val profileUrl: String = "",
    /** ยอดนี้มาจากไหน — ของ mock คือเชื่อมบัญชีแล้วทั้งหมด · ของจากฟอร์มอาจเป็น "กรอกเอง" */
    val source: FollowerSource = FollowerSource.connected,
) {
    val id: String get() = type.raw

    /** ปลายทางที่ widget เอาไปผูกกับพื้นที่กด */
    val profileURL: String? get() = Web.url(profileUrl) ?: type.profileURL(handle)
}

data class RateItem(
    val label: String,
    /** ราคาที่ครีเอเตอร์ตั้งเอง */
    val price: Int,
    val unit: String,
    val format: ContentFormat,
    /** ช่องที่งานชิ้นนี้ลง — ใช้หายอดผู้ติดตามที่ถูกต้องมาคิดราคาตลาด */
    val platform: SocialType,
    /** คีย์รูปแบบตามแพลตฟอร์ม (จากฟอร์ม) — ว่าง = รายการตัวอย่างที่ยังใช้รูปแบบกลาง */
    val key: String = "",
) {
    /** คงที่ต่อ "ช่องในตาราง" (แพลตฟอร์ม×รูปแบบ) — ไม่ใช่ UUID สุ่ม */
    val id: String get() = platform.raw + "." + (if (key.isEmpty()) format.raw else key)
}

// MARK: - เรตตลาด

/**
 * คิด "ราคาที่ตลาดจ่าย" จากยอดผู้ติดตามและยอดวิวจริง — สูตรที่ **เปิดให้ตรวจได้**
 * ฐาน = max(ยอดผู้ติดตาม × เรตต่อคน, ยอดวิวเฉลี่ย × เรตต่อวิว) · ราคา = max(ค่าแรงขั้นต่ำ, ฐาน × ตัวคูณชนิดงาน × ตัวคูณคุณภาพผู้ชม)
 * ตัวเลขทั้งชุดอยู่ในที่เดียว — วันที่ตลาดขยับ แก้ตารางนี้ตารางเดียวจบ
 */
object Pricing {
    /** เรตต่อผู้ติดตามหนึ่งคน (บาท) สำหรับคลิปสั้นหนึ่งชิ้น */
    fun perFollower(n: Int): Double = when {
        n < 10_000 -> 0.35   // นาโน — เข้าถึงลึก คิดหัวละแพงสุด
        n < 50_000 -> 0.25   // ไมโคร
        n < 100_000 -> 0.18
        n < 500_000 -> 0.13  // แมโคร
        else -> 0.10         // เมกะ — ขายปริมาณ คิดหัวละถูกสุด
    }

    /** ตัวคูณตามชนิดงาน — เทียบกับคลิปสั้น = 1.0 */
    fun factor(f: ContentFormat): Double = when (f) {
        ContentFormat.shortVideo -> 1.0
        ContentFormat.longVideo -> 1.8    // ถ่ายนาน ตัดนาน แต่อยู่ในฟีดได้นานกว่า
        ContentFormat.photo -> 0.6
        ContentFormat.seeding -> 0.35     // สตอรี่/แชร์ — หายไปใน 24 ชม.
    }

    /** ตัวคูณคุณภาพผู้ชม — ฐานตลาดอยู่ที่ ER 4% */
    fun quality(er: Double): Double = min(1.35, max(0.85, 1 + (er - 4.0) / 20))

    /** เรตต่อ "วิว" หนึ่งครั้ง (บาท) — เส้นทางที่สองของราคา · ตลาดจ่ายค่า **สายตา** ไม่ใช่ค่าจำนวนคนกดตาม */
    fun perView(n: Int): Double = when {
        n < 50_000 -> 0.28    // ช่องเล็กที่วิวพุ่ง — คนดูตั้งใจดู คิดต่อวิวแพงสุด
        n < 200_000 -> 0.20
        n < 1_000_000 -> 0.14
        else -> 0.10
    }

    /** ค่าแรงผลิตขั้นต่ำต่อชิ้น — พื้นที่ราคาชนไม่ผ่าน */
    fun floorPrice(f: ContentFormat): Int = (3_000 * factor(f) / 500).roundToInt() * 500

    /** ราคาที่ตลาดจ่าย — ปัดเป็นหลักห้าร้อย · คิดสองทางแล้วเอาทางที่สูงกว่า */
    fun suggested(followers: Int, views: Int, format: ContentFormat, er: Double): Int {
        val byFollower = followers.toDouble() * perFollower(followers)
        val byView = views.toDouble() * perView(views)
        val raw = max(byFollower, byView) * factor(format) * quality(er)
        return max(floorPrice(format), (raw / 500).roundToInt() * 500)
    }
}

/** สเปก 5.1 — แพ็กเกจจ้างงานหนึ่งชุด · "ดีลที่ปิดได้ทั้งก้อน" ต่างจาก `RateItem` ที่เป็นราคาต่อชิ้น */
data class RatePackage(
    val name: String,
    val price: Int,
    /** Deliverable Checklist — สิ่งที่จะได้รับ */
    val deliverables: List<String>,
    /** Turnaround Time (วัน) */
    val turnaroundDays: Int,
    /** Free Revisions Limit */
    val freeRevisions: Int,
    /** แพ็กที่อยากให้เด่นในเมนู */
    val featured: Boolean = false,
) {
    val id: String get() = name
}

/** สเปก 5.2 — สิทธิ์และเงื่อนไขเพิ่มเติม · สี่บรรทัดที่แบรนด์ต้องเมลกลับมาถามทุกครั้ง */
data class WorkTermsInfo(
    /** Ad Boosting Rate — "+30%" หรือ "฿8,000" */
    val adBoost: String,
    /** Commercial Rights Duration */
    val commercialRights: String,
    /** Exclusivity Fee & Terms */
    val exclusivity: String,
    /** Fast-Track Delivery Fee */
    val rush: String,
) {
    companion object
}

/** สเปก 5.3 — สถานะการรับงานปัจจุบัน */
enum class BookingState(val raw: String) {
    available("available"), busy("busy"), fullyBooked("fullyBooked");

    val label: String get() = when (this) {
        available -> "ว่างรับงาน"
        busy -> "คิวแน่น"
        fullyBooked -> "คิวเต็มแล้ว"
    }

    /** สีสถานะ — คงที่ ไม่ผูกกับพาเลตต์ เพราะ "เขียว = ว่าง" เป็นภาษาสากลที่ห้ามเปลี่ยนตามธีม */
    val tint: Color get() = when (this) {
        available -> rgb(0.36, 0.92, 0.66)
        busy -> rgb(1.00, 0.78, 0.35)
        fullyBooked -> rgb(1.00, 0.45, 0.50)
    }

    companion object {
        fun from(raw: String?): BookingState? = entries.firstOrNull { it.raw == raw }
    }
}

/** สเปก 1.3 — ช่องทางติดต่อ · สี่ฟิลด์นี้ถูกอ่านพร้อมกันเสมอ จึงเป็น "นามบัตรใบเดียว" ไม่ใช่สี่ widget */
data class ContactInfo(
    val name: String,
    val role: String,
    val phone: String,
    val email: String,
    val lineId: String,
    /** Average Response Time — **ต้องคำนวณจากอินบ็อกซ์จริง** ไม่ใช่ให้กรอก */
    val responseTime: String,
)

/** สเปก 2.3 — ประชากรผู้ติดตาม */
data class AudienceInsight(
    /** Gender Ratio (หญิง · ชาย · อื่น ๆ) รวมกันได้ 100 */
    val female: Double,
    val male: Double,
    val other: Double,
    /** Age Distribution — เรียงตามอายุเสมอ ไม่เรียงตามขนาด */
    val ages: List<AgeBand>,
    /** Top Locations พร้อมสัดส่วน */
    val places: List<PlaceShare>,
    /** การเข้าถึงของช่วงเวลาเดียวกัน (**mock** — รอ OAuth Insights จริง) */
    val reach: Reach = Reach.none,
) {
    data class Reach(
        val platform: SocialType,
        /** ช่วงเวลาที่นับ เช่น "30 วัน" */
        val window: String,
        /** Accounts Reached */
        val accounts: Int,
        /** เทียบช่วงก่อนหน้า (%) */
        val delta: Double,
        /** สัดส่วนคนที่ยังไม่ได้ติดตาม — "คนใหม่" ที่แบรนด์อยากได้ */
        val newShare: Double,
    ) {
        companion object {
            val none = Reach(platform = SocialType.instagram, window = "", accounts = 0, delta = 0.0, newShare = 0.0)
        }
    }

    data class AgeBand(val label: String, val share: Double) {
        val id: String get() = label
    }

    data class PlaceShare(val name: String, val share: Double) {
        val id: String get() = name
    }

    companion object
}

/** สเปก 4.2 — ผลงานสร้างยอดขาย · **หมวดที่คู่แข่งลอกไม่ได้** */
data class SalesRecord(
    /** โค้ดส่วนลดประจำตัว */
    val code: String,
    /** Promo Code Redemptions */
    val redemptions: Int,
    /** Outbound Link Clicks */
    val clicks: Int,
    /** Sales Generated Volume (บาท) */
    val volume: Int,
    /** Top Converting Category */
    val topCategory: String,
    /** จำนวนแคมเปญที่ข้อมูลชุดนี้มาจาก */
    val campaigns: Int,
)

/** สเปก 4.3 — คำรีวิวจากผู้ว่าจ้าง · `workRef` ชี้กลับไปยังงานจริงในระบบได้ รีวิวที่อ้างอิงงานไม่ได้ ห้ามขึ้นการ์ด */
data class ClientReview(
    val reviewer: String,
    val role: String,
    val brand: String,
    /** 1.0–5.0 */
    val rating: Double,
    val text: String,
    /** Reference Work ID — ตรงกับ `VerifiedWork.ep` */
    val workRef: String,
) {
    val id: String get() = workRef
}

internal object ContentFormatSerializer : RawSerializer<ContentFormat>("ContentFormat", { ContentFormat.from(it) }, { it.raw })

/** ประเภทคอนเทนต์ที่รับทำ — ชุดเดียวกับตัวเลือกในหน้าตั้งค่าโปรไฟล์ */
@Serializable(with = ContentFormatSerializer::class)
sealed class ContentFormat(val raw: String) {
    object photo : ContentFormat("photo")
    object shortVideo : ContentFormat("shortVideo")
    object longVideo : ContentFormat("longVideo")
    object seeding : ContentFormat("seeding")

    val id: String get() = raw
    val ordinal: Int get() = entries.indexOf(this)

    val name: String get() = when (this) {
        photo -> "Photo"
        shortVideo -> "Short Video"
        longVideo -> "Long Video"
        seeding -> "Seeding"
    }

    val detail: String get() = when (this) {
        photo -> "ภาพนิ่งพร้อมแคปชั่นรีวิว"
        shortVideo -> "คลิปสั้นพร้อมแคปชั่น"
        longVideo -> "คลิปยาวพร้อมแคปชั่น"
        seeding -> "ข้อความ/รูปเพื่อแชร์รีวิว"
    }

    /** ชื่อ SF Symbol — วาดด้วย `SFSymbol(icon)` */
    val icon: String get() = when (this) {
        photo -> "photo.fill"
        shortVideo -> "play.rectangle.fill"
        longVideo -> "video.fill"
        seeding -> "arrowshape.turn.up.right.fill"
    }

    /** สีประจำประเภท — ยกโทนมาจากหน้าเลือกในโปรไฟล์ ให้ผู้ใช้จำสีได้ตรงกัน */
    val tint: Color get() = when (this) {
        photo -> rgb(0.58, 0.35, 0.95)
        shortVideo -> rgb(0.93, 0.24, 0.60)
        longVideo -> rgb(0.16, 0.55, 0.96)
        seeding -> rgb(0.98, 0.58, 0.18)
    }

    override fun toString(): String = raw

    companion object {
        val entries: List<ContentFormat> by lazy { listOf(photo, shortVideo, longVideo, seeding) }
        fun from(raw: String?): ContentFormat? = entries.firstOrNull { it.raw == raw }
    }
}

/** เวลาที่สะดวกรับงาน — เก็บเป็นดัชนี ให้ตรงกับตัวเลือกวัน/ช่วงเวลาในโปรไฟล์ */
data class WorkTime(
    /** 0 = อาทิตย์ … 6 = เสาร์ */
    val days: Set<Int>,
    /** ดัชนีของ `slotNames` */
    val slots: Set<Int>,
) {
    /** สรุปวันแบบสั้น — "ทุกวัน" · "จ–ศ" · หรือจำนวนวัน */
    val daySummary: String get() {
        if (isEveryDay) return "ทุกวัน"
        val sorted = days.sorted()
        // ต่อเนื่องกันถึงเขียนเป็นช่วงได้ ไม่งั้นบอกจำนวนวันแทน
        val continuous = sorted.size > 1 && sorted.last() - sorted.first() == sorted.size - 1
        if (!continuous) return "${days.size} วัน"
        return "${dayNames[sorted.first()]}–${dayNames[sorted.last()]}"
    }

    val isEveryDay: Boolean get() = days.size == dayNames.size
    val isAnyTime: Boolean get() = slots.size == slotNames.size

    companion object {
        val dayNames = listOf("อา", "จ", "อ", "พ", "พฤ", "ศ", "ส")
        val slotNames = listOf("09.00–12.00", "12.00–14.00", "14.00–17.00", "17.00 เป็นต้นไป")
        /** ชื่อย่อสำหรับแถบไทม์ไลน์ — ชื่อเต็มยาวเกินกว่าจะวางสี่ช่วงในแถวเดียว */
        val slotShort = listOf("09–12", "12–14", "14–17", "17 น.+")
    }
}

/** แบรนด์ที่เคยร่วมงาน — logo เป็น Mock URL (optional เพราะไม่ใช่ทุกแบรนด์ที่มีโลโก้ในระบบ) */
data class Brand(
    val name: String,
    val logo: String?,
    /** สเปก 4.1 Brand Industry Tag — เพิ่มเป็นฟิลด์ ไม่ใช่ widget แยก */
    val industry: String = "Beauty",
) {
    val id: String get() = name

    /** ตัวย่อสำหรับแบรนด์ที่ยังไม่มีโลโก้ */
    val monogram: String get() {
        val parts = name.split(" ").filter { it.isNotEmpty() }
        if (parts.size >= 2) return (parts[0].take(1) + parts[1].take(1)).uppercase()
        return name.take(2).uppercase()
    }
}

/**
 * ผลงานหนึ่งชิ้นที่ระบบยืนยันตัวเลขให้ — ไม่ใช่รูปที่ creator เลือกมาเอง
 * สี่สัญญาณที่ทุก widget ชั้นหลักฐานต้องบอกให้ครบ: โพสอะไร · ตอนไหน · ของแบรนด์ไหน · ได้ผลแค่ไหน
 */
data class VerifiedWork(
    val brand: String,
    /** รหัสตอน — ทำหน้าที่เป็นซีเรียลของผลงาน ปลอมไม่ได้เพราะระบบออกให้ */
    val ep: String,
    val campaign: String,
    /** ลงที่ไหน — แบรนด์ถามข้อนี้ก่อนถามยอดวิวเสมอ */
    val platform: SocialType,
    /** ฟอร์แมตของโพสต์ ("คลิปยาว" · "Reel" · "Short") */
    val format: String,
    val views: Int,
    val engagementRate: Double,
    val photo: Int,
    /** สเปก 3.1 Direct Post URL — ลิงก์ตรงไปยังโพสต์จริง */
    val postUrl: String = "",
    /** สเปก 3.2 Deep-dive Performance */
    val saves: Int = 0,
    val shares: Int = 0,
    /** ยอดไลก์/คอมเมนต์ของโพสต์นั้น — คู่กับแชร์คือสามตัวที่คนอ่านการ์ดคุ้นจากใต้โพสต์ */
    val likes: Int = 0,
    val comments: Int = 0,
    /** สเปก 3.2 Viral Tag — null เมื่อยังไม่ถึงเกณฑ์ */
    val viralTag: String? = null,
    /** สเปก 3.2 Concept Breakdown */
    val concept: String = "",
) {
    val id: UUID = UUID.randomUUID()

    /** ปลายทางที่ widget เอาไปผูกกับพื้นที่กด — null เมื่อผลงานชิ้นนั้นยังไม่มีลิงก์ */
    val postURL: String? get() = Web.url(postUrl)
}

/** ชั้นหลักฐาน — ข้อมูลที่แพลตฟอร์มออกให้ ผู้ใช้แก้ไม่ได้ */
data class TrackRecord(
    val delivered: Int,
    val accepted: Int,
    val brandCount: Int,
    val brands: List<Brand>,
    val avgEngagementRate: Double,
    val works: List<VerifiedWork>,
    /** สเปก 4.2 — ผลลัพธ์ยอดขายรวมทุกแคมเปญ */
    val sales: SalesRecord,
    /** สเปก 4.3 — คำรีวิวจากผู้ว่าจ้าง */
    val reviews: List<ClientReview>,
) {
    val completionRate: Double get() = if (accepted == 0) 0.0 else delivered.toDouble() / accepted.toDouble()

    /** คะแนนเฉลี่ยจากรีวิวทั้งหมด */
    val avgRating: Double get() {
        if (reviews.isEmpty()) return 0.0
        return reviews.sumOf { it.rating } / reviews.size.toDouble()
    }

    companion object
}

/** สัดส่วนผู้ติดตามรายช่อง (= tuple `(social:, share:)` ของ `CreatorProfile.platformShare`) */
data class PlatformShare(val social: SocialProfile, val share: Double)

data class CreatorProfile(
    val name: String,
    val handle: String,
    val tagline: String,
    val location: String,
    val about: String,
    /** สเปก 1.1 Verified Status — เป็น "ตราที่ติดมากับชื่อ" ไม่ใช่ widget แยก */
    val verified: Boolean,
    val categories: List<String>,
    /** หมวดหมู่ทางการของแพลตฟอร์มที่ครีเอเตอร์เลือกไว้ — ต่างจาก `categories` ที่พิมพ์เอง */
    val interests: List<String>,
    /** สเปก 1.2 Content Style Tags — "เล่ายังไง" ต่างจาก `categories` ที่บอก "เรื่องอะไร" */
    val styleTags: List<String>,
    /** ประเภทคอนเทนต์ที่ถนัด */
    val formats: List<ContentFormat>,
    val workTime: WorkTime,
    val socials: List<SocialProfile>,
    val rates: List<RateItem>,
    val packages: List<RatePackage>,
    val terms: WorkTermsInfo,
    val contact: ContactInfo,
    val audience: AudienceInsight,
    val track: TrackRecord,
    val availability: String,
    val bookingState: BookingState,
) {
    // MARK: ค่าที่คำนวณให้ widget ใช้ร่วมกัน — ห้าม widget คำนวณเอง ไม่งั้นตัวเลขจะไม่ตรงกันข้ามใบ

    val totalFollowers: Int get() = socials.sumOf { it.followerCount }

    /** ยอดวิวเฉลี่ยถ่วงน้ำหนักตามขนาดช่อง — ค่าเฉลี่ยธรรมดาทำให้ช่องเล็กดึงเลขลงเกินจริง */
    val avgViews: Int get() {
        val total = totalFollowers
        if (total <= 0) return 0
        val sum = socials.sumOf { it.avgViewCount.toDouble() * it.followerCount.toDouble() }
        return (sum / total.toDouble()).toInt()
    }

    val postsPerWeek: Double get() = socials.sumOf { it.postsPerWeek }

    /** ราคาต่ำสุดในเรตการ์ด — ใช้กับ widget "เริ่มต้นที่" */
    val startingPrice: Int get() = rates.minOfOrNull { it.price } ?: 0

    /** สัดส่วนผู้ติดตามรายช่อง เรียงจากมากไปน้อย */
    val platformShare: List<PlatformShare> get() {
        val total = max(1, totalFollowers).toDouble()
        return socials
            .sortedByDescending { it.followerCount }
            .map { PlatformShare(it, it.followerCount.toDouble() / total) }
    }

    /** ค่าเฉลี่ยย่อยต่อคลิปรวมทุกช่อง */
    val mix: EngageMix get() {
        val n = max(1, socials.size)
        return EngageMix(
            likes = socials.sumOf { it.mix.likes } / n,
            comments = socials.sumOf { it.mix.comments } / n,
            shares = socials.sumOf { it.mix.shares } / n,
            saves = socials.sumOf { it.mix.saves } / n,
        )
    }

    /** ราคาที่ตลาดจ่ายสำหรับรายการนี้ — คิดจากยอดผู้ติดตามของ **ช่องที่งานชิ้นนี้ลง** */
    fun marketRate(r: RateItem): Int {
        val s = socials.firstOrNull { it.type == r.platform } ?: return r.price
        return Pricing.suggested(followers = s.followerCount, views = s.avgViewCount, format = r.format, er = s.engagementRate)
    }

    /** ราคาเริ่มต้นของประเภทคอนเทนต์นั้น — null เมื่อไม่รับทำ */
    fun price(f: ContentFormat): Int? {
        if (!formats.contains(f)) return null
        return rates.filter { it.format == f }.minOfOrNull { it.price }
    }

    companion object
}

// MARK: - Mock

object Mock {
    val creator = CreatorProfile(
        name = "นิรา ภัทรวดี",
        handle = "nira.beauty",
        tagline = "Beauty & Skincare Creator",
        location = "กรุงเทพมหานคร",
        about = "รีวิวสกินแคร์และเมคอัพแบบตรงไปตรงมา เน้นผิวแพ้ง่าย ถ่ายเองตัดเองทุกคลิป",
        verified = true,
        // สายงานชุดเดียวกับเทมเพลต STAR CARD_1/_2 — แต่ละหมวดมีไอคอนประจำ (ดู `Pop.nicheIcon`)
        categories = listOf("บิวตี้", "ไลฟ์สไตล์", "ออกกำลังกาย", "คาเฟ่"),
        interests = listOf("ความงามและสุขภาพ", "แฟชั่นและช้อปปิ้ง", "แม่และเด็ก", "ท่องเที่ยว"),
        styleTags = listOf("อ้างอิงวิจัย", "รีวิวยาว 30 วัน", "How-to", "ก่อน–หลัง", "โทนใส สว่าง"),
        formats = listOf(ContentFormat.photo, ContentFormat.shortVideo, ContentFormat.seeding),
        // รับ จ–ส · เว้นช่วงพักเที่ยง — ตั้งใจไม่ให้เต็มทุกช่อง จะได้เห็นว่า widget อ่านค่าจริง
        workTime = WorkTime(days = setOf(1, 2, 3, 4, 5, 6), slots = setOf(0, 2, 3)),
        socials = listOf(
            SocialProfile(type = SocialType.instagram, handle = "@nira.beauty", followerCount = 184_000,
                avgEngagementCount = 8_600, avgViewCount = 92_000, syncedAgo = "2 ชม.",
                mix = EngageMix(likes = 6_400, comments = 480, shares = 910, saves = 2_180),
                postsPerWeek = 1.5, engagementRate = 4.7,
                profileUrl = "https://www.instagram.com/jenaissante/"),
            SocialProfile(type = SocialType.tiktok, handle = "@nirabeauty", followerCount = 320_500,
                avgEngagementCount = 26_100, avgViewCount = 128_000, syncedAgo = "2 ชม.",
                mix = EngageMix(likes = 18_400, comments = 1_210, shares = 3_860, saves = 6_530),
                postsPerWeek = 2.5, engagementRate = 8.1,
                profileUrl = "https://www.tiktok.com/@le_sserafim"),
            SocialProfile(type = SocialType.youtube, handle = "@niraskin", followerCount = 41_200,
                avgEngagementCount = 1_900, avgViewCount = 22_400, syncedAgo = "5 ชม.",
                mix = EngageMix(likes = 1_420, comments = 260, shares = 140, saves = 380),
                postsPerWeek = 0.5, engagementRate = 4.6,
                profileUrl = "https://www.youtube.com/@happyhittergolf"),
        ),
        rates = listOf(
            RateItem(label = "TikTok Video", price = 35_000, unit = "คลิป", format = ContentFormat.shortVideo, platform = SocialType.tiktok),
            RateItem(label = "IG Reel", price = 25_000, unit = "คลิป", format = ContentFormat.shortVideo, platform = SocialType.instagram),
            RateItem(label = "IG Story x3", price = 12_000, unit = "ชุด", format = ContentFormat.seeding, platform = SocialType.instagram),
            RateItem(label = "รีวิวลงบล็อก", price = 18_000, unit = "ชิ้น", format = ContentFormat.photo, platform = SocialType.instagram),
        ),
        packages = listOf(
            RatePackage(name = "Launch Set",
                price = 58_000,
                deliverables = listOf("TikTok Video ×1", "IG Reel ×1", "IG Story ×3"),
                turnaroundDays = 7, freeRevisions = 2, featured = true),
            RatePackage(name = "Single Clip",
                price = 35_000,
                deliverables = listOf("TikTok Video ×1", "แคปชั่นพร้อมโพสต์"),
                turnaroundDays = 5, freeRevisions = 1),
            RatePackage(name = "Long Review",
                price = 92_000,
                deliverables = listOf("รีวิวยาว 30 วัน", "คลิปสรุป ×2", "อัลบั้มก่อน–หลัง"),
                turnaroundDays = 35, freeRevisions = 2),
        ),
        terms = WorkTermsInfo(
            adBoost = "+30%",
            commercialRights = "6 เดือน",
            exclusivity = "฿15,000 / 3 เดือน",
            rush = "+20% (ส่งใน 3 วัน)",
        ),
        contact = ContactInfo(
            name = "นิรา ภัทรวดี",
            role = "ติดต่อโดยตรง · ไม่ผ่านผู้จัดการ",
            phone = "081-234-5678",
            email = "nira@beautyworks.co",
            lineId = "@nirabeauty",
            responseTime = "ภายใน 3 ชม.",
        ),
        audience = AudienceInsight(
            female = 78.0, male = 20.0, other = 2.0,
            ages = listOf(
                AudienceInsight.AgeBand(label = "18–24", share = 27.0),
                AudienceInsight.AgeBand(label = "25–34", share = 41.0),
                AudienceInsight.AgeBand(label = "35–44", share = 22.0),
                AudienceInsight.AgeBand(label = "45+", share = 10.0),
            ),
            places = listOf(
                AudienceInsight.PlaceShare(name = "กรุงเทพฯ", share = 34.0),
                AudienceInsight.PlaceShare(name = "ชลบุรี", share = 9.0),
                AudienceInsight.PlaceShare(name = "เชียงใหม่", share = 7.0),
                AudienceInsight.PlaceShare(name = "ขอนแก่น", share = 5.0),
            ),
            reach = AudienceInsight.Reach(platform = SocialType.instagram, window = "30 วัน",
                accounts = 184_200, delta = 14.4, newShare = 93.4),
        ),
        track = TrackRecord(
            delivered = 24, accepted = 24, brandCount = 6,
            brands = listOf(
                Brand(name = "Sivanna Colors", logo = "https://img.salehere.co.th/p/300x0/2025/05/07/fe0pah3cmv3g.jpg", industry = "Cosmetics"),
                Brand(name = "Scotch", logo = "https://img.salehere.co.th/p/300x0/2023/12/06/yy7womguuk9w.jpg", industry = "Supplement"),
                Brand(name = "BioActive+", logo = "https://img.salehere.co.th/p/300x0/2019/12/20/oosmvnoxfb8m.jpg", industry = "Supplement"),
                Brand(name = "Cathy Doll", logo = "https://cathydoll.me/cdn/shop/files/New_CD_LOGO_2018.png?v=1669460778&width=600", industry = "Skincare"),
                Brand(name = "Srichand", logo = "https://srichand.co.th/wp-content/uploads/2025/12/square-big-logo.jpg", industry = "Cosmetics"),
                Brand(name = "Mistine", logo = "https://www.mistine.co.th/pic/logo.png", industry = "Cosmetics"),
            ),
            avgEngagementRate = 6.4,
            works = listOf(
                // photo index 0/4/5 → วนรูปผลงานคนละรูป (1–3 สงวนไว้เป็นรูปโปรไฟล์)
                // ชื่อแบรนด์ต้องตรงกับรายการ `brands` เป๊ะ ๆ — widget ใช้ชื่อนี้ไปหาโลโก้มาแสดง
                VerifiedWork(brand = "Sivanna Colors", ep = "EP.1335", campaign = "Ballet Dream",
                    platform = SocialType.tiktok, format = "คลิปยาว", views = 1_240_000, engagementRate = 6.8, photo = 0,
                    postUrl = "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                    saves = 42_600, shares = 18_900, likes = 84_200, comments = 1_930, viralTag = "1M+ Views",
                    concept = "เปิดด้วยผิวจริงวันแพ้ ไม่รีทัช แล้วค่อยเข้าสินค้าในวินาทีที่ 8"),
                VerifiedWork(brand = "Cathy Doll", ep = "EP.1206", campaign = "Glow Serum Launch",
                    platform = SocialType.instagram, format = "Reel", views = 820_000, engagementRate = 7.4, photo = 4,
                    postUrl = "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                    saves = 31_200, shares = 9_400, likes = 52_600, comments = 1_240, viralTag = "High Conversion",
                    concept = "ถ่ายก่อน–หลัง 14 วันในแสงเดียวกันทุกเฟรม ตัดสลับให้เห็นผลในคลิปเดียว"),
                VerifiedWork(brand = "Srichand", ep = "EP.1189", campaign = "Oil Control Challenge",
                    platform = SocialType.youtube, format = "Short", views = 615_000, engagementRate = 5.9, photo = 5,
                    postUrl = "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                    saves = 18_700, shares = 6_100, likes = 31_800, comments = 760, viralTag = null,
                    concept = "ทดสอบคุมมันกลางแดด 8 ชม. ถ่ายทุกชั่วโมงด้วยกล้องตัวเดิม"),
                // สองชิ้นนี้เติมเข้ามาให้ครบห้า — ใบที่วางผลงานเป็น "กอง" ออกแบบผังไว้ห้าช่อง
                VerifiedWork(brand = "Mistine", ep = "EP.1142", campaign = "Sunscreen Everyday",
                    platform = SocialType.tiktok, format = "คลิปสั้น", views = 486_000, engagementRate = 6.2, photo = 6,
                    postUrl = "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                    saves = 14_300, shares = 5_400, likes = 27_900, comments = 640, viralTag = null,
                    concept = "ทากันแดดซ้ำระหว่างวันจริงในออฟฟิศ ไม่จัดฉาก ถ่ายด้วยมือถือ"),
                VerifiedWork(brand = "Scotch", ep = "EP.1098", campaign = "Collagen 30 Days",
                    platform = SocialType.instagram, format = "Reel", views = 352_000, engagementRate = 8.1, photo = 7,
                    postUrl = "https://salehere.co.th/review/374da1f0df0a4adab668431cc5f4206a",
                    saves = 21_500, shares = 4_200, likes = 24_100, comments = 1_080, viralTag = "High Save Rate",
                    concept = "ไดอารี่ 30 วัน ถ่ายหน้าเปล่าเวลาเดิมทุกเช้า ตัดรวมเป็นคลิปเดียว"),
            ),
            sales = SalesRecord(
                code = "NIRA10",
                redemptions = 1_842,
                clicks = 24_600,
                volume = 2_140_000,
                topCategory = "เซรั่มบำรุงผิวหน้า",
                campaigns = 8,
            ),
            reviews = listOf(
                ClientReview(reviewer = "แคทรียา ส.", role = "Brand Manager", brand = "Cathy Doll",
                    rating = 5.0,
                    text = "ส่งงานก่อนเดดไลน์ทุกชิ้น สคริปต์เข้าใจสินค้าจริงไม่ต้องแก้เลย คลิปเดียวทำยอดพรีออเดอร์หมดล็อตใน 2 วัน",
                    workRef = "EP.1206"),
                ClientReview(reviewer = "ธนวัฒน์ ก.", role = "Marketing Lead", brand = "Sivanna Colors",
                    rating = 5.0,
                    text = "กล้าพูดข้อเสียสินค้าตรง ๆ ซึ่งกลับทำให้คอมเมนต์เชื่อมากกว่าทุกคลิปที่เคยจ้างมา",
                    workRef = "EP.1335"),
                ClientReview(reviewer = "พิมพ์ชนก ว.", role = "Founder", brand = "Srichand",
                    rating = 4.5,
                    text = "ทำการบ้านมาดีมาก ถามข้อมูลส่วนผสมละเอียดกว่าทีมเราเองอีก",
                    workRef = "EP.1189"),
            ),
        ),
        availability = "ว่างรับงาน ก.ย. – ต.ค.",
        bookingState = BookingState.available,
    )

    /**
     * การ์ดเริ่มต้น — พอร์ต 3 หน้า: ตัวตน · ขนาดและผู้ชม · ราคาและติดต่อ
     * หน่วยพิกัด = **pt บนพื้นที่ออกแบบกว้าง 402** · `y` คือขอบบนของตัวนั้น
     * ผังบอกแค่ `x`, `y`, `w` — **ความสูงมาจากสัดส่วนของชนิด** (ดู `WidgetKind.aspect`)
     */
    val starterPages: List<CardPage> by lazy {
        listOf(
            CardPage(listOf(
                WidgetInstance.make(WidgetKind.artTypeOver, x = 18f, y = 18f, w = 366f),
                WidgetInstance.make(WidgetKind.typeMarquee, x = 18f, y = 426f, w = 366f),
                WidgetInstance.make(WidgetKind.artFilmstrip, x = 18f, y = 513f, w = 366f),
            )),
            CardPage(listOf(
                WidgetInstance.make(WidgetKind.proofWork, x = 18f, y = 36f, w = 366f),
                WidgetInstance.make(WidgetKind.statGiant, x = 18f, y = 387f, w = 366f),
            )),
            CardPage(listOf(
                WidgetInstance.make(WidgetKind.rateTags, x = 18f, y = 18f, w = 366f),
                WidgetInstance.make(WidgetKind.contactCard, x = 18f, y = 310f, w = 366f),
                WidgetInstance.make(WidgetKind.socialTiles, x = 18f, y = 495f, w = 366f),
            )),
        )
    }

    /**
     * การ์ดเริ่มต้นแบบสตอรี่ — หน้าเดียว 540×960 (= 1080×1920 px)
     * สตอรี่มีแคนวาสกว้างกว่าพอร์ต 34% — ผังของสตอรี่จึงเป็นของตัวเอง:
     * ฮีโร่คู่กับเฟรมสตอรี่แนวตั้ง แล้วไล่ตัวเลข/ราคา/ช่องทางเป็นสองคอลัมน์
     */
    val storyPage: CardPage by lazy {
        CardPage(listOf(
            WidgetInstance.make(WidgetKind.artTypeOver, x = 18f, y = 18f, w = 360f),
            WidgetInstance.make(WidgetKind.galleryStory, x = 392f, y = 18f, w = 130f),
            WidgetInstance.make(WidgetKind.typeMarquee, x = 18f, y = 425f, w = 504f),
            WidgetInstance.make(WidgetKind.statGiant, x = 18f, y = 534f, w = 245f),
            WidgetInstance.make(WidgetKind.rateTags, x = 277f, y = 534f, w = 245f),
            WidgetInstance.make(WidgetKind.proofBrandRail, x = 18f, y = 718f, w = 245f),
            WidgetInstance.make(WidgetKind.socialTiles, x = 277f, y = 718f, w = 245f),
            WidgetInstance.make(WidgetKind.contactBar, x = 18f, y = 842f, w = 504f),
        ))
    }

    /**
     * ตู้รางวัล — ทุก widget ที่เพิ่มได้
     * ตอนนี้ชั้นหลักฐานปลดล็อกชั่วคราว (กติกา "ส่งงาน 3 ชิ้น" ถูกพักไว้) · `lockedTeasers` ยังอยู่เพื่อเอาล็อกกลับมาได้
     */
    val catalog: List<CatalogEntry>
        get() = WidgetKind.entries.map { CatalogEntry(kind = it) }

    /** widget ที่ยังปลดล็อกไม่ได้ — ตอนนี้ว่าง เพราะพักเงื่อนไขส่งงานไว้ก่อน */
    val lockedTeasers: List<CatalogEntry>
        get() = emptyList()
}

// MARK: - Debug

/** สวิตช์สำหรับตอนพัฒนา — ตอนนี้ชั้นหลักฐานปลดล็อกอยู่แล้ว (กติกาส่งงาน 3 ชิ้นถูกพัก) · เก็บคีย์ไว้เพื่อเอาล็อกกลับมา */
object DebugFlags {
    const val unlockVerifiedKey = "debug.unlockVerifiedWidgets"

    var unlockVerified: Boolean
        get() = AppContext.prefs.getBoolean(unlockVerifiedKey, false)
        set(value) { AppContext.prefs.edit().putBoolean(unlockVerifiedKey, value).apply() }
}
