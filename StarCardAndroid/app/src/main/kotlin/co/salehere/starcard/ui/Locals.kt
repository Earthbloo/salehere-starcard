package co.salehere.starcard.ui

import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import java.util.UUID

// MARK: - `EnvironmentValues` ของ SwiftUI → CompositionLocal
//
// กติกา: Local ที่ค่าเป็นชนิดของโมเดล/ธีม ประกาศไว้ **ข้างชนิดนั้น** (เช่น `LocalCardInk` ใน theme/Ink.kt ·
// `LocalWidgetSurface` ใน model/WidgetModel.kt · `LocalPageScrub` ใน components/Motion.kt ·
// `LocalPhotoStore` ใน model/PhotoStore.kt) — ไฟล์นี้เก็บเฉพาะ Local ที่ค่าเป็นชนิดพื้นฐาน

/** id ของ widget ที่กำลังวาดอยู่ — ให้รูป/ข้อความข้างในรู้ว่าตัวเองสังกัด widget ไหน (= `\.widgetID`) */
val LocalWidgetID = compositionLocalOf<UUID?> { null }

/** สีเน้นของการ์ด — ส่งลงมาให้ชิ้นส่วนเล็ก ๆ ใช้โดยไม่ต้องรับ theme (= `\.cardAccent`) */
val LocalCardAccent = compositionLocalOf { Color.White }

/** เปิดเฉพาะ widget ที่อยู่บนแคนวาสในโหมดแต่ง — พรีวิวในตู้และรูปที่เรนเดอร์ไม่มีเส้นประ (= `\.textEditMode`) */
val LocalTextEditMode = compositionLocalOf { false }

/** มุมเอียง (องศา) ของแผ่นที่ครอบข้อความอยู่ — เส้นประต้องเอียงตาม (= `\.slotTilt`) */
val LocalSlotTilt = compositionLocalOf { 0.0 }

/** โหมด "ไม่มีข้อมูล" ของพรีวิวในตู้ widget — ค่าของผู้ใช้กลายเป็นแท่งว่าง (= `\.ghostData`) */
val LocalGhostData = compositionLocalOf { false }

/** ตู้ widget: วาดด้วยข้อมูลตัวอย่างแม้ยังไม่กรอก (= `\.sampleData`) */
val LocalSampleData = compositionLocalOf { false }

/** พรีวิวย่อส่วนสั่งหยุดของที่วิ่งตามเวลา (= `\.previewStatic`) */
val LocalPreviewStatic = compositionLocalOf { false }

/** ความกว้างเนื้อหาของหน้า (หน่วยออกแบบ) — ก้อนข้อความใช้จำกัดความกว้าง (= `\.pageContentWidth`) */
val LocalPageContentWidth = compositionLocalOf { 366f }

/** ก้อนข้อความนี้กำลังถูกพิมพ์บนการ์ดอยู่ — ตัวอักษรต้องหลบให้ช่องพิมพ์ (= `\.canvasTyping`) */
val LocalCanvasTyping = compositionLocalOf { false }

/** `openURL` ของ SwiftUI — ชั้นการ์ดใส่ตัวเปิดลิงก์ให้ (Intent.ACTION_VIEW) */
val LocalOpenURL = staticCompositionLocalOf<(String) -> Unit> { {} }

/** `dismiss` ของ SwiftUI — ปิดชีต/หน้าที่กำลังเปิดอยู่ */
val LocalDismiss = staticCompositionLocalOf<() -> Unit> { {} }
