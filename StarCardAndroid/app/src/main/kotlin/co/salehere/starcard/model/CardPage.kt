package co.salehere.starcard.model

import java.util.UUID

/**
 * หนึ่งหน้ากระดาษ A4 ในพอร์ตโฟลิโอ
 *
 * พอร์ตจริงไม่เคยจบในหน้าเดียว — หน้าแรกขายตัวตน หน้าถัดไปคือผลงาน แล้วปิดด้วยราคา/ติดต่อ
 * เก็บ items แยกต่อหน้า ไม่ใช่ลิสต์เดียวแล้วให้ระบบตัดหน้าเอง เพราะผู้ใช้ต้องคุมได้ว่าอะไรอยู่หน้าไหน
 *
 * ตำแหน่งอยู่ที่ตัว widget เอง · ลำดับใน `items` ใช้ตัดสินว่าใครได้ที่ก่อนเมื่อสองตัวชนกัน
 * ของทับกันไม่ได้ — `PageLayout.solve` ดันตัวที่มาทีหลังลงจนมีที่ว่าง
 */
data class CardPage(
    val items: List<WidgetInstance> = emptyList(),
    val id: UUID = UUID.randomUUID(),
)
