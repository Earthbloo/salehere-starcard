package co.salehere.starcard.ui.widgets

import androidx.compose.ui.graphics.Color
import co.salehere.starcard.model.PopSkin
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.opacity

/**
 * สีของสำรับสติกเกอร์ (= `enum Pop` ใน Views/Widgets/PopWidgets.swift) — ผังอ้างเป็น token `pop.*`
 *
 * สำรับนี้ต่างจากที่อื่นตรง **ตัวหนังสือเป็นถ่านคงที่** (ฉลากบนกล่องขาวไม่พลิกตามการ์ด)
 */
object Pop {
    /** ถ่านอมม่วง — ดำสนิทบนกล่องขาวชมพูอ่านแข็งเกินไป */
    val ink = Color(red = 0.11f, green = 0.10f, blue = 0.13f)
    val inkSoft = Color(red = 0.40f, green = 0.37f, blue = 0.43f)
    val paper = Color.White
    /** เส้นคั่นบนกระดาษ */
    val rule = Color(red = 0.84f, green = 0.82f, blue = 0.85f)

    /** สีชมพูของแผ่น — สีเน้นดิบของธีม (วางบนกล่องขาวของตัวเอง) */
    fun pink(t: CardTheme): Color = t.rawAccent

    /** พื้นของแผ่นตามพื้นผิว — กระจก ~62% (สกินกระจก) / 90% (สกินกระดาษ) · อย่างอื่นทึบ */
    fun sheetFill(s: WidgetSurface, skin: PopSkin, theme: CardTheme): Color = when (s) {
        WidgetSurface.glass -> paper.opacity(if (skin == PopSkin.glass) 0.62 else 0.9)
        else -> paper
    }

    fun sheetShadow(s: WidgetSurface, skin: PopSkin, theme: CardTheme): Color =
        if (skin == PopSkin.glass) pink(theme).opacity(0.35) else Color.Black.opacity(0.22)
}
