package co.salehere.starcard.model

import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf

// MARK: - ลิงก์ที่เปิดแอปมา (= ClipInvocation.swift)

/** แอปหลักกับ App Clip ของ iOS แชร์ไบนารีคนละก้อน — Android ไม่มี clip จึงเป็น `false` เสมอ */
object AppRuntime {
    const val isClip: Boolean = false
}

/** URL ที่เปิดแอปมา — จาก `Intent.data` (deep link / QR) · ในซิม iOS ใช้ `_XCAppClipURL` ยัดเข้ามาแทน QR จริง */
class ClipInvocation {
    /** slug จาก URL ที่เปิดมา — null = แอปเปิดปกติ ใช้ชื่อผู้ใช้ปัจจุบันของโปรไฟล์แทน */
    private var urlSlug: String? by mutableStateOf(null)
    var url: String? by mutableStateOf(null)

    /** ท้ายลิงก์ประจำตัว — **ตามชื่อผู้ใช้ที่แก้ล่าสุดเสมอ** ไม่ใช่ค่าที่จำไว้ตอนเปิดแอป */
    val slug: String get() = urlSlug ?: Profile.me.handle

    fun consume(uri: Uri) {
        url = uri.toString()
        slug(from = uri)?.let { urlSlug = it }
    }

    fun consume(url: String) {
        val u = runCatching { Uri.parse(url) }.getOrNull() ?: return
        consume(u)
    }

    /** iOS ยัด URL ผ่าน env ตอน Run คลิปในซิม — Android รับผ่าน `Intent.data` ใน `MainActivity` แทน จึงไม่ต้องทำอะไร */
    fun consumeLaunchURL() {}

    /** ลิงก์การ์ดที่เอาไปแปะ Line / ไบโอได้ — ใช้ URL ที่เปิดมา ถ้าไม่มีก็ประกอบจาก slug · โดเมนเดียวกับแอปหลัก */
    val shareURL: String get() = url ?: "https://$host/star/$slug"

    /** โฮสต์ + พาธ อ่านง่ายในแถวคัดลอก ไม่มี https:// */
    val shareURLDisplay: String get() {
        val u = runCatching { Uri.parse(shareURL) }.getOrNull()
        val h = u?.host ?: host
        val p = u?.path?.let { if (it == "/" || it.isEmpty()) "" else it } ?: ""
        return h + p
    }

    companion object {
        /** โดเมนเดียวกับแอปหลัก — ที่อยู่คือลายเซ็นที่ถูกที่สุด (คนรู้ว่าเป็นของใครตั้งแต่เห็นลิงก์ในไบโอ) */
        const val host = "salehere.co.th"

        /**
         * `https://salehere.co.th/star/nira.beauty` → `nira.beauty`
         * รับลิงก์โปรไฟล์เดิมของแอปหลักด้วย: `/user/nira.beauty/creator-profile-info`
         */
        fun slug(from: Uri): String? {
            val parts = from.pathSegments.filter { it.isNotEmpty() && it != "/" }
            if (parts.size >= 2 && (parts[0] == "star" || parts[0] == "user")) return parts[1]
            if (parts.size == 1 && parts[0] != "star") return parts[0]
            return null
        }
    }
}

/** `@Environment(ClipInvocation.self)` — ค่าตั้งต้นคือ instance เปล่า (แอปเปิดปกติ) */
val LocalClipInvocation = staticCompositionLocalOf { ClipInvocation() }
