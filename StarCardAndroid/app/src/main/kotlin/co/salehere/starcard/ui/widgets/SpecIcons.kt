package co.salehere.starcard.ui.widgets

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.VerifiedBadge
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.SocialProfile
import co.salehere.starcard.theme.EmbossedLockup
import co.salehere.starcard.theme.BylineTone
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.SaleHereByline
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.Provenance
import co.salehere.starcard.theme.ProvenanceTag
import co.salehere.starcard.theme.SHIcon
import co.salehere.starcard.theme.StarLockup
import co.salehere.starcard.theme.StarSeal
import co.salehere.starcard.theme.VerifiedFacts
import co.salehere.starcard.theme.grey
import kotlin.math.min

// MARK: - ไอคอนของผัง (= `SpecPainter.icon(_:)` ใน Views/Widgets/SpecPainter.swift · รายชื่อตาม WIDGET-SPEC.md §6)
//
// ตัววาดผังส่งชื่อ icon (แทนค่า `$field` แล้ว) + กรอบ + สี tint ที่แปลงแล้ว — ที่นี่เลือกชิ้นที่มีอยู่แล้วของแอป
// ชื่อที่ไม่รู้จักพยายามหา drawable ชื่อเดียวกัน (ขีดกลาง → ขีดล่าง) · ไม่เจอ = ว่าง
//
// ค่าสีตั้งต้นเมื่อผังไม่ส่ง tint: `ink` = `ink.text(1)` · `accent` = สีเน้นของการ์ด (ส่งมาทาง `accent`; ไม่ส่ง = หมึก)

@Composable
fun SpecIcon(
    name: String,
    box: Size,
    tint: Color?,
    text: String?,
    size: Float?,
    ink: InkStyle,
    accent: Color? = null,
    modifier: Modifier = Modifier,
    /** handle ที่ QR ชี้ไป — ตัวส่งออกเทียบภาพส่งค่าที่ iOS ใช้ (null = ของโปรไฟล์บนเครื่อง) */
    handle: String? = null,
    /** token → สี บนพื้นตั้งต้นของใบ (`palette.color(token, null)`) — สีตั้งต้นของไอคอนที่ผังไม่ส่ง `tint` (= iOS `color("ink")`) · null = หมึกการ์ด */
    color: ((String) -> Color)? = null,
) {
    val c = { t: String, a: Double -> color?.invoke(if (a == 1.0) t else "$t@$a") ?: ink.text(a) }
    val inkColor = c("ink", 1.0)
    val accentColor = color?.invoke("accent") ?: accent ?: inkColor
    val m = min(box.width, box.height)
    val punch = if (ink.isLight) Color.White else grey(0.10)
    Box(modifier.size(box.width.dp, box.height.dp), contentAlignment = Alignment.Center) {
        when (name) {
            "qr" -> QRCode(
                text = "https://salehere.co.th/star/${handle ?: Profile.me.handle}",
                tint = tint ?: inkColor,
                modifier = Modifier.fillMaxSize().aspectRatio(1f),
            )
            "provenance", "provenance:profile" -> ProvenanceTag(Provenance.profile)
            "provenance:socials" -> ProvenanceTag(Profile.me.creator.socials.provenance)
            "provenance:photo" -> ProvenanceTag(Profile.me.creator.socials.provenance, onPhoto = true)
            "provenance:screenshot" -> ProvenanceTag(Provenance.Screenshot("12 ก.ย."))
            // ป้าย "Verified by Sale Here" ของโค้ดเดิม (`SaleHereByline`) — ขนาดตัวอักษร = สูงกล่อง × 0.45 · หมึกตั้งต้น ink@0.9
            "byline", "byline:dark", "byline:light" -> SaleHereByline(
                tint = tint ?: c("ink", 0.9), size = kotlin.math.max(6f, box.height * 0.45f),
                tone = when (name) { "byline:dark" -> BylineTone.dark; "byline:light" -> BylineTone.light; else -> BylineTone.ink },
                modifier = Modifier.wrapContentSize(unbounded = true),
            )
            "verifiedBadge" -> VerifiedBadge()
            "verifiedSeal" -> VerifiedSeal(radius = m / 2, punch = punch, tint = tint ?: inkColor, compact = false)
            "guilloche" -> Guilloche(color = tint ?: c("ink", 0.2))
            "ringText" -> RingText(
                text = text ?: "",
                radius = m / 2 - (size ?: 7f),
                size = size ?: 7f,
                color = tint ?: inkColor,
            )
            "washi" -> WashiTape(width = box.width, height = box.height, tint = tint ?: Color.White)
            "binderClip" -> BinderClip(width = box.width)
            "paperClip" -> PaperClipView(color = tint ?: c("ink", 0.6), lineWidth = 1.6f)
            "barcode" -> ScrapBarcode(color = tint ?: inkColor)
            "bow" -> ScrapBow(width = box.width)
            "spark" -> ScrapSpark(size = m, color = tint ?: Color.White)
            "windowDots" -> ScrapWindowDots()
            "embossedLockup" -> EmbossedLockup(height = box.height, light = ink.isLight, foil = false, tint = tint ?: c("ink", 0.8))
            "starLockup" -> StarLockup(height = box.height, tint = tint ?: accentColor)
            "starSeal" -> StarSeal(size = m, tint = tint ?: accentColor, punch = punch)
            "saleHereStar" -> FitIcon(SHIcon.star, tint ?: inkColor)
            else -> when {
                name.startsWith("url:") -> RemoteLogo(name.removePrefix("url:"), Modifier.fillMaxSize())
                name.startsWith("http") -> RemoteLogo(name, Modifier.fillMaxSize())
                name.startsWith("ph:") -> {
                    // asset ของแอปก่อน (ph_<name>) · ไม่มีก็ชุด Phosphor เต็ม (ชื่อ kebab-case ตรงกับ `Ph.raw`)
                    val short = name.removePrefix("ph:")
                    val res = drawableId("ph_" + short.replace('-', '_'))
                    val ph = Ph.from(short.removeSuffix("-fill"))
                    if (res != 0) {
                        FitIcon(res, tint ?: inkColor)
                    } else if (ph != null) {
                        PIcon(ph, size = m, weight = if (short.endsWith("-fill")) PhWeight.fill else PhWeight.bold, tint = tint ?: inkColor)
                    }
                }
                name.startsWith("sh:") -> {
                    val res = shIconNamed(name.removePrefix("sh:"))
                    if (res != 0) FitIcon(res, tint)
                }
                name.isNotEmpty() -> {
                    // ชื่อ asset ตรง ๆ (เช่นโลโก้ช่องจากรายการ `socials` ฟิลด์ `icon`)
                    val res = shIconNamed(name)
                    if (res != 0) FitIcon(res, tint)
                }
                else -> Unit
            }
        }
    }
}

/** รูปเต็มกรอบแบบ fit (= `Image(...).resizable().scaledToFit()`) · tint = null → คงสีต้นฉบับ (`BrandIcon`) · มี tint → ย้อม (`SymbolIcon`) */
@Composable
private fun FitIcon(res: Int, tint: Color?) {
    Image(
        painter = painterResource(res),
        contentDescription = null,
        contentScale = ContentScale.Fit,
        colorFilter = tint?.let { ColorFilter.tint(it) },
        modifier = Modifier.fillMaxSize(),
    )
}

/** id ของ drawable ตามชื่อ (0 = ไม่มี) — ชื่อ asset ของ iOS ใช้ขีดกลาง, Android ใช้ขีดล่าง */
@Composable
private fun drawableId(name: String): Int {
    val ctx = LocalContext.current
    val key = name.replace('-', '_').lowercase()
    if (key.isEmpty()) return 0
    return ctx.resources.getIdentifier(key, "drawable", ctx.packageName)
}

/** ชื่อสั้นในผัง → resource id (= `SHIcon.named`) · ชื่ออื่นลองหา drawable ชื่อนั้นตรง ๆ · 0 = ไม่มี */
@Composable
internal fun shIconNamed(short: String): Int = when (short) {
    "instagram" -> SHIcon.instagram
    "tiktok" -> SHIcon.tiktok
    "youtube" -> SHIcon.youtube
    "facebook" -> SHIcon.facebook
    "x" -> SHIcon.x
    "lemon8" -> SHIcon.lemon8
    "line" -> SHIcon.line
    "sealCheck" -> SHIcon.sealCheck
    "verifiedPill" -> SHIcon.verifiedPill
    "star" -> SHIcon.star
    "wordmark" -> SHIcon.wordmark
    "watermark" -> SHIcon.watermark
    "qr" -> SHIcon.qr
    else -> drawableId(short)
}

/**
 * ป้ายที่มาของ widget ผู้ติดตาม (= `[SocialProfile].provenance` ใน SocialWidgets.swift) — ทุกช่องยืนยันแล้วถึงจะได้ป้ายเขียว
 * มีช่องที่กรอกเองปนอยู่แม้ช่องเดียว ป้ายต้องบอกว่า "รอตรวจสอบ"
 */
