package co.salehere.starcard.model

import android.graphics.Bitmap

/**
 * ลบพื้นหลังออกจากรูปหนึ่งใบ — ยกเฉพาะ "ตัวแบบ" ขึ้นมา ที่เหลือกลายเป็นใส (= Model/PhotoLift.swift)
 *
 * iOS ใช้ `VNGenerateForegroundInstanceMaskRequest` ของ Apple Vision ซึ่ง Android ไม่มีตัวเทียบเท่าในตัว
 * (PORTING.md §8) — เก็บ API ไว้ให้ widget คอมไพล์ผ่าน แล้วคืน `null` เสมอ = "ในรูปไม่มีวัตถุที่แยกออกมาได้"
 * วันที่ต่อ ML Kit Subject Segmentation ก็แทนที่แค่ตัวนี้ ผู้เรียกไม่ต้องเปลี่ยน
 *
 * สัญญาที่ต้องรักษาเมื่อทำจริง: คืนภาพ **ขนาดเท่าเดิม** ที่พื้นหลังใส ไม่ใช่ครอปรอบตัวแบบ —
 * ทุกช่องรูปครอปแบบ fill จากภาพเต็ม ถ้าสัดส่วนเปลี่ยน ทุกช่องที่เคยเล็งไว้ (`PhotoFit`) จะเลื่อนหมด
 */
object PhotoLift {

    /** ยกตัวแบบออกจากพื้นหลัง — `null` เมื่อในรูปไม่มีวัตถุที่แยกออกมาได้ (บน Android ตอนนี้: เสมอ) */
    @Suppress("UNUSED_PARAMETER", "RedundantSuspendModifier")
    suspend fun lift(image: Bitmap): Bitmap? = null
}
