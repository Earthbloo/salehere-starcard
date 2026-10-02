package co.salehere.starcard.ui

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext

/**
 * เบราว์เซอร์ในแอป — ลิงก์บนการ์ดเปิดที่นี่ ไม่เด้งออกไปแอปอื่น (= `SafariSheet`)
 *
 * iOS ใช้ `SFSafariViewController` (กด "เสร็จ" แล้วกลับมาที่หน้าเดิมทันทีในสภาพเดิม)
 * Android เปิดเบราว์เซอร์ของเครื่องด้วย `Intent.ACTION_VIEW` — กดย้อนกลับแล้วกลับมาที่การ์ดเดิม
 * ตัวชีตจึงแค่ส่งลิงก์ออกไปแล้วปิดตัวเองทันที
 * - tint: สีของปุ่มในแถบเครื่องมือ (iOS) — เบราว์เซอร์ของระบบไม่รับสี คงไว้ให้ API ตรงกัน
 * - onDismiss: ปิดชีตหลังส่งลิงก์ออกไป — null = ใช้ `LocalDismiss` ของผู้เปิด
 */
@Suppress("UNUSED_PARAMETER")
@Composable
fun SafariSheet(
    url: String,
    tint: Color,
    modifier: Modifier = Modifier,
    onDismiss: (() -> Unit)? = null,
) {
    val context = LocalContext.current
    val localDismiss = LocalDismiss.current
    val close by rememberUpdatedState(onDismiss ?: localDismiss)

    LaunchedEffect(url) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
            if (context !is android.app.Activity) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { context.startActivity(intent) }
        close()
    }
    Box(modifier.fillMaxSize())
}

/**
 * URL ที่ห่อให้ชีตแบบ `item:` ใช้ได้ — ปลายทางเปลี่ยนทุกครั้งที่กดคนละที่
 * ถ้าใช้บูลคู่กับตัวแปร URL แยก จะมีจังหวะที่ชีตขึ้นมาก่อน URL ใหม่ถูกเซ็ต แล้วเปิดหน้าเก่า
 */
data class LinkTarget(val url: String) {
    val id: String get() = url
}
