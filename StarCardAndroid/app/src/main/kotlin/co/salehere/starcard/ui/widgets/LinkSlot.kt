package co.salehere.starcard.ui.widgets

import android.net.Uri
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.composed
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.LinkSlotRect
import co.salehere.starcard.ui.editor.LocalSlotRegistry
import co.salehere.starcard.ui.editor.SlotMemo

// MARK: - ปลายทางของชิ้นส่วนหนึ่งใน widget — "กดตรงนี้แล้วออกไปที่ไหน" (= Views/Widgets/LinkSlot.swift)
//
// เนื้อหาข้างใน widget ไม่รับทัช ตัวรับทัชจริงคือชั้นการ์ด — ชิ้นจึงต้อง **ประกาศกรอบขึ้นไป**
// ให้ชั้นการ์ดรู้ว่าพิกัดไหนผูกกับ URL ไหน แล้วชั้นการ์ดเป็นคนตัดสินตอนนิ้วแตะ
// กลไกเดียวกับ `photoSlot` และ `editableSlot` (ดู PORTING §6) · กรอบเก็บเป็นหน่วยออกแบบของหน้า

/**
 * ประกาศว่ากรอบนี้กดแล้วไป `url` · ส่ง null เมื่อชิ้นนั้นยังไม่มีปลายทาง (ก็แค่ไม่มีลิงก์)
 *
 * ติดไว้ที่ **กรอบนอกสุดของชิ้นหนึ่งชิ้น** ไม่ใช่ที่ตัวอักษรข้างใน — พื้นที่กดต้องเท่าที่ตาเห็นว่าเป็นของชิ้นนั้น
 * - slop: เผื่อขอบรอบกรอบ (หน่วยออกแบบ) — ตราเล็ก ๆ ข้างชื่อแตะตรง ๆ ไม่โดน (= `verifySlot` เผื่อ 8pt)
 */
fun Modifier.linkSlot(url: String?, slop: Float = 0f): Modifier = composed {
    val reg = LocalSlotRegistry.current
    val id = LocalWidgetID.current
    if (url == null || reg == null || id == null) return@composed Modifier
    val memo = remember { SlotMemo<LinkSlotRect>() }
    DisposableEffect(reg, id, url) {
        onDispose {
            memo.value?.let { reg.links[id]?.remove(it) }
            memo.value = null
        }
    }
    Modifier.onGloballyPositioned { c ->
        var r = reg.toPage(c.boundsInRoot())
        if (slop > 0f) r = r.inflate(slop)
        val slot = LinkSlotRect(url, r)
        val prev = memo.value
        // กรอบเดิมของชิ้นนี้ที่ขยับไปแล้วต้องหายไป — ไม่งั้นทะเบียนสะสมกรอบเก่าไว้ทุกครั้งที่ผังขยับ
        if (prev != null && prev != slot) reg.links[id]?.remove(prev)
        reg.reportLink(id, slot)
        memo.value = slot
    }
}

// MARK: - ช่องข้อความที่มีปลายทางในตัว

/**
 * ช่องที่ "ค่าของมันคือทางติดต่อ" — กดแล้วต้องไปถึงตัวคนได้ทันที ไม่ต้องก็อปไปวางเอง
 * ประกาศที่นี่ที่เดียวแล้ว `EditableText` ติดลิงก์ให้เอง · ชื่อ = โทรหาเจ้าของการ์ด
 */
val ProfileField.contactURL: String?
    get() {
        val me = Profile.me
        return when (this) {
            ProfileField.phone, ProfileField.personName, ProfileField.contactName -> Contact.tel(me.phone)
            ProfileField.email -> Contact.mail(me.email)
            ProfileField.lineId -> Contact.line(me.lineId)
            else -> null
        }
    }

object Contact {
    fun tel(raw: String): String? {
        val digits = raw.filter { it.isDigit() || it == '+' }
        return if (digits.isEmpty()) null else "tel:$digits"
    }

    fun mail(raw: String): String? {
        val s = raw.trim()
        return if (s.contains("@")) "mailto:$s" else null
    }

    /**
     * ไลน์ไอดีขึ้นต้น @ = บัญชีทางการ (`/R/ti/p/@id`) · ไอดีส่วนตัวต้องมี ~ นำหน้า
     * ลิงก์ line.me เป็น universal link — มีแอป LINE ก็เด้งเข้าแอปตรงหน้าเพิ่มเพื่อน
     */
    fun line(raw: String): String? {
        val s = raw.trim()
        if (s.isEmpty()) return null
        val path = if (s.startsWith("@")) s else "~$s"
        val enc = Uri.encode(path, "@~") ?: path
        return "https://line.me/R/ti/p/$enc"
    }
}
