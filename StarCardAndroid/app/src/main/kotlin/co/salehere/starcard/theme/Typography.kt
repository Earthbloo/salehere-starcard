package co.salehere.starcard.theme

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.PlatformTextStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import co.salehere.starcard.R

// MARK: - ฟอนต์และไอคอนที่ยกมาจากแอป Sale Here (= Typography.swift)
//
// # หน่วย: pt ของดีไซน์ = dp · ตัวอักษรใช้ sp แต่ **แอปตรึง fontScale = 1** ที่ราก (ดู `ContentView`)
// การ์ดคือชิ้นงานที่ส่งต่อ — ขนาดตัวอักษรต้องเท่ากันทุกเครื่อง ไม่ล้อการตั้งค่า accessibility ของผู้ดู
// ดังนั้น `sh(13f)` = 13pt บนการ์ดเสมอ เหมือน `.sh(13)` ของ iOS

object SHFont {
    /** NotoSansThai — ตัวเดียวกับที่แอปหลักใช้ รองรับสระบน-ล่างของไทย */
    val family: FontFamily = FontFamily(
        Font(R.font.notosansthai_light, FontWeight.Light),
        Font(R.font.notosansthai_regular, FontWeight.Normal),
        Font(R.font.notosansthai_medium, FontWeight.Medium),
        Font(R.font.notosansthai_semibold, FontWeight.SemiBold),
        Font(R.font.notosansthai_bold, FontWeight.Bold),
        Font(R.font.notosansthai_extrabold, FontWeight.ExtraBold),
        Font(R.font.notosansthai_black, FontWeight.Black),
    )
    /** มิตร — ฟอนต์ไทยตัวที่สองของแอป (น้ำหนักเดียว) */
    val mitr: FontFamily = FontFamily(Font(R.font.mitr_regular, FontWeight.Normal))

    /** `Font.Weight` ของ SwiftUI → `FontWeight` */
    val black = FontWeight.Black
    val heavy = FontWeight.ExtraBold
    val bold = FontWeight.Bold
    val semibold = FontWeight.SemiBold
    val medium = FontWeight.Medium
    val regular = FontWeight.Normal
    val light = FontWeight.Light
    val thin = FontWeight.ExtraLight
    val ultraLight = FontWeight.Thin
}

/** ตัวอักษรไม่เผื่อ padding บน/ล่างแบบ Android — ให้กล่องข้อความวัดเหมือน SwiftUI */
val ShPlatformStyle = PlatformTextStyle(includeFontPadding = false)
val ShLineHeightStyle = LineHeightStyle(alignment = LineHeightStyle.Alignment.Center, trim = LineHeightStyle.Trim.None)

/**
 * ฟอนต์หลักของการ์ด (= `Font.sh(size, weight)`) — ใช้เป็น `style` ของ `Text`
 * `Text("x", style = sh(13f, SHFont.bold))`
 */
fun sh(size: Float, weight: FontWeight = FontWeight.Normal, family: FontFamily = SHFont.family,
       italic: Boolean = false): TextStyle =
    TextStyle(
        fontFamily = family,
        fontWeight = weight,
        fontSize = size.sp,
        fontStyle = if (italic) FontStyle.Italic else FontStyle.Normal,
        platformStyle = ShPlatformStyle,
        lineHeightStyle = ShLineHeightStyle,
    )
fun sh(size: Int, weight: FontWeight = FontWeight.Normal): TextStyle = sh(size.toFloat(), weight)
fun sh(size: Double, weight: FontWeight = FontWeight.Normal): TextStyle = sh(size.toFloat(), weight)

/** `Font.system(size:weight:design:)` — ฟอนต์ระบบของเครื่อง (ใช้กับสัญลักษณ์/ตัวเลขที่ไม่ใช่ไทย) */
fun systemFont(size: Float, weight: FontWeight = FontWeight.Normal, serif: Boolean = false): TextStyle =
    TextStyle(
        fontFamily = if (serif) FontFamily.Serif else FontFamily.SansSerif,
        fontWeight = weight, fontSize = size.sp,
        platformStyle = ShPlatformStyle, lineHeightStyle = ShLineHeightStyle,
    )

/** `Font.statNumber(size)` / `Font.display(size, weight)` ของ Glass.swift */
fun statNumber(size: Float): TextStyle = sh(size, FontWeight.Bold)
fun display(size: Float, weight: FontWeight = FontWeight.SemiBold): TextStyle = sh(size, weight)

/** ตัวเอียงเซริฟแบบ "Didot-Italic" (= `GL.serif`) — Android ไม่มี Didot ใช้เซริฟระบบเอียงแทน */
fun serifItalic(size: Float, weight: FontWeight = FontWeight.Normal): TextStyle =
    TextStyle(fontFamily = FontFamily.Serif, fontWeight = weight, fontSize = size.sp, fontStyle = FontStyle.Italic,
              platformStyle = ShPlatformStyle, lineHeightStyle = ShLineHeightStyle)

// MARK: - ไอคอน

/** ไอคอนเวกเตอร์ที่ยกมาจากแอปหลัก — ค่าคือ resource id ของ drawable (= `SHIcon` ของ iOS ที่เป็นชื่อ asset) */
object SHIcon {
    val instagram = R.drawable.about_social_instagram
    val tiktok = R.drawable.about_social_tiktok
    val youtube = R.drawable.about_social_youtube
    val facebook = R.drawable.about_social_facebook
    val x = R.drawable.about_social_x
    val lemon8 = R.drawable.about_social_lemon8

    val sealCheck = R.drawable.ic_seal_check
    /** ป้าย "VERIFIED BY SALE HERE" ตัวจริงของแอปหลัก — คงสีต้นฉบับ ไม่ย้อม */
    val verifiedPill = R.drawable.ic_verified_sale_here
    val star = R.drawable.ic_salehere_star_outline
    val starActive = R.drawable.ic_salehere_star_outline_active
    val wordmark = R.drawable.ic_salehere_text
    val watermark = R.drawable.ic_salehere_watermark
    val qr = R.drawable.ic_salehere_qr
    val qrPlain = R.drawable.ic_qr
    val addressBook = R.drawable.ic_addressbook_outline
    val phoneCall = R.drawable.ic_phonecall_outline
    val shareLine = R.drawable.ic_share_line
    val logoRed = R.drawable.ic_salehere_logo_red42
    val bell = R.drawable.ic_bell_white24
    val chat = R.drawable.ic_chat_white24
    val hamburger = R.drawable.ic_hambergermenumobile_outline

    val arrowUpRight = R.drawable.ph_arrow_up_right
    val sparkle = R.drawable.ph_sparkle
    val starFill = R.drawable.ph_star_fill
    val check = R.drawable.ph_check
    val mapPin = R.drawable.ph_map_pin
    val heart = R.drawable.ph_heart_fill
    val users = R.drawable.ph_users_three
    val ticket = R.drawable.ph_ticket
    val share = R.drawable.ph_share_network
    val caretRight = R.drawable.ph_caret_right
    val plus = R.drawable.ph_plus
    val xmark = R.drawable.ph_x

    // รูปตัวอย่างและโลโก้แบรนด์ในสำรับ (Assets.xcassets/Photos · Brands · SaleHere)
    val photo1 = R.drawable.ph01
    val photo2 = R.drawable.ph02
    val photo3 = R.drawable.ph03
    val photo4 = R.drawable.ph04
    val cutoutSample = R.drawable.cutout_sample
    val logoBioactive = R.drawable.logo_bioactive
    val logoScotch = R.drawable.logo_scotch
    val logoSivanna = R.drawable.logo_sivanna
    val mockBadgeStar = R.drawable.mock_badge_star
    val mockCoverThymora = R.drawable.mock_cover_thymora
    val mockCoverWonder = R.drawable.mock_cover_wonder
    val mockLogoThymora = R.drawable.mock_logo_thymora
    val mockLogoWonder = R.drawable.mock_logo_wonder
}

/** ไอคอนโลโก้แบรนด์ — คงสีต้นฉบับไว้ (= `BrandIcon`) */
@Composable
fun BrandIcon(res: Int, size: Float = 14f, modifier: Modifier = Modifier) {
    Image(painterResource(res), contentDescription = null, modifier = modifier.size(size.dp))
}

/** ไอคอนสัญลักษณ์ — ย้อมสีตามธีมได้ (= `SymbolIcon`) */
@Composable
fun SymbolIcon(res: Int, size: Float = 14f, tint: Color = Color.White, modifier: Modifier = Modifier) {
    Icon(painterResource(res), contentDescription = null, tint = tint, modifier = modifier.size(size.dp))
}

/** ตราวงกลมของ SaleHere — โลโก้ขาวบนวงกลมสีแบรนด์ (= `SaleHereMark`) · สีแดงคงที่เสมอ */
object SaleHereMarkColors {
    /** แดงของแบรนด์ — ดูดมาจากไฟล์โลโก้จริง */
    val red = Color(0xFFDA3832)
}

@Composable
fun SaleHereMark(size: Float = 15f, modifier: Modifier = Modifier) {
    Box(modifier.size(size.dp).background(SaleHereMarkColors.red, CircleShape), contentAlignment = Alignment.Center) {
        SymbolIcon(SHIcon.wordmark, size = size * 0.58f, tint = Color.White)
    }
}

/** `.foregroundStyle(color)` บนคอนเทนเนอร์ — ทุก `Text`/`PIcon`/`Icon` ข้างในได้สีนี้ */
@Composable
fun Tinted(color: Color, content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalContentColor provides color, content = content)
}
