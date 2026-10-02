package co.salehere.starcard.ui.editor

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.input.pointer.PointerEvent
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.unit.dp
import kotlin.math.min

/** แตะของ UIKit ยอมให้นิ้วขยับได้ราว 45pt ก่อนไม่นับเป็นแตะ */
private const val CatcherTapSlop = 45f

/** เกณฑ์เริ่มแพนของ `UIPanGestureRecognizer` (~10pt) — ใช้ค่าที่เล็กกว่าระหว่างนี้กับ touch slop ของเครื่อง */
private const val CatcherPanSlop = 10f

/** ที่จำ `LayoutCoordinates` ของตัวรับ — แปลงนิ้วเป็นพิกัดราก (= พิกัดหน้าต่างของ UIKit) */
private class CatcherCoords {
    var coords: LayoutCoordinates? = null
}

/**
 * ตัวรับ "กดค้างแล้วลาก" (= Views/Editor/PressDragCatcher.swift — iOS เขียนด้วย UIKit recognizer)
 *
 * ก่อนครบเวลากดค้าง ตัวนี้ **ไม่แย่งนิ้ว** — ชั้นที่เลื่อนได้ (หน้า/สำรับ) ยังปัดได้ตามปกติ
 * ครบเวลาแล้วจึงถือนิ้วไว้เองจนยก (กินทุก move ไม่ให้ชั้นบนเลื่อนซ้อน)
 *
 * หน่วย: **ทุกค่าเป็น dp (= pt ของ iOS)**
 * - `onTap` / `onPress`: พิกัดภายในตัวรับ (ภายใน widget หลังผ่าน `graphicsLayer` ของการ์ดแล้ว = หน่วยออกแบบ)
 * - `onChanged`: ระยะลากในพิกัดราก (= พิกัดหน้าต่าง) นับจากจุดที่เริ่มลาก — ผู้เรียกหารสเกลของการ์ดเอง
 *
 * - immediate: **ลากได้ทันที ไม่ต้องกดค้าง** — ใช้กับชิ้นที่เลือกอยู่แล้ว (อ่านค่าตอนนิ้วลง ใช้ตลอดทั้งท่า)
 * - allowableMovement: ระยะที่นิ้วขยับได้ก่อนครบเวลาโดยยังไม่ยกเลิก — 10pt ของ UIKit แคบไปสำหรับนิ้วจริง
 * - onTap: แตะสั้น ๆ พร้อมจุดที่แตะ — ชั้นการ์ดใช้ตัดสินว่านิ้วโดนช่องข้อความหรือโดนตัว widget
 * - onPress: จุดที่นิ้วแตะ · null เมื่อยกนิ้ว — ใช้คำนวณการเอียง 3 มิติ
 *
 * เป็นแผ่นใสเต็มกรอบ (`fillMaxSize`) — ถ้าวางใน `Box` ที่สูงตามเนื้อหา ส่ง `Modifier.matchParentSize()` มาด้วย
 */
@Composable
fun PressDragCatcher(
    minimumDuration: Double = 0.25,
    immediate: Boolean = false,
    allowableMovement: Float = 32f,
    onBegan: () -> Unit,
    onChanged: (Size) -> Unit,
    onEnded: () -> Unit,
    onTap: (Offset) -> Unit,
    onPress: (Offset?) -> Unit = {},
    modifier: Modifier = Modifier,
) {
    val duration by rememberUpdatedState(minimumDuration)
    val panMode by rememberUpdatedState(immediate)
    val allowance by rememberUpdatedState(allowableMovement)
    val cbBegan by rememberUpdatedState(onBegan)
    val cbChanged by rememberUpdatedState(onChanged)
    val cbEnded by rememberUpdatedState(onEnded)
    val cbTap by rememberUpdatedState(onTap)
    val cbPress by rememberUpdatedState(onPress)
    val ref = remember { CatcherCoords() }

    Box(
        modifier
            .fillMaxSize()
            .onGloballyPositioned { ref.coords = it }
            .pointerInput(Unit) {
                awaitEachGesture {
                    val down = awaitFirstDown(requireUnconsumed = false)
                    val pid = down.id
                    val start = down.position
                    // ชิ้นที่เลือกอยู่ลากด้วยแพน ชิ้นอื่นลากด้วยกดค้าง — ทีละแบบ ไม่งั้นสองตัวขับการลากซ้อนกัน
                    val usePan = panMode
                    val deadline = down.uptimeMillis + (duration * 1000.0).toLong().coerceAtLeast(0L)
                    val allowPx = allowance.dp.toPx()
                    val tapSlopPx = CatcherTapSlop.dp.toPx()
                    val panSlopPx = min(viewConfiguration.touchSlop, CatcherPanSlop.dp.toPx())

                    fun pt(o: Offset): Offset = Offset(o.x / density, o.y / density)
                    // อ้างอิงพิกัดราก เพราะ widget ใต้นิ้วเลื่อนตามการลาก (และ auto-scroll)
                    fun root(o: Offset): Offset = ref.coords?.takeIf { it.isAttached }?.localToRoot(o) ?: o

                    var tapAlive = true
                    var pressAlive = !usePan
                    var panAlive = usePan
                    var dragging = false
                    var origin = Offset.Zero
                    var last = start
                    var lastTime = down.uptimeMillis

                    cbPress(pt(start))
                    try {
                        // ก่อนเริ่มลาก — รอครบเวลากดค้าง / แพนพ้นเกณฑ์ / ยกนิ้ว (= แตะ)
                        while (!dragging) {
                            val ev: PointerEvent? = if (pressAlive) {
                                val left = deadline - lastTime
                                if (left <= 0L) null else withTimeoutOrNull(left) { awaitPointerEvent() }
                            } else {
                                awaitPointerEvent()
                            }
                            if (ev == null) {
                                // ครบเวลากดค้าง — เริ่มนับระยะจากจุดนี้
                                dragging = true
                                origin = root(last)
                                cbBegan()
                                break
                            }
                            val ch = ev.changes.firstOrNull { it.id == pid }
                            if (ch == null || !ch.pressed) {
                                // ยกนิ้วก่อนเริ่มลาก = แตะ (นิ้วที่เคยลากแล้วไม่มีทางมาถึงตรงนี้)
                                if (ch != null && tapAlive) {
                                    ch.consume()
                                    cbTap(pt(ch.position))
                                }
                                return@awaitEachGesture
                            }
                            last = ch.position
                            lastTime = ch.uptimeMillis
                            cbPress(pt(ch.position))
                            val moved = (ch.position - start).getDistance()
                            if (moved > tapSlopPx) tapAlive = false
                            if (pressAlive && moved > allowPx) pressAlive = false
                            if (panAlive && moved > panSlopPx) {
                                // เริ่มนับระยะจากจุดที่แพนติด ไม่ใช่จุดที่นิ้วแตะ — ชิ้นยกขึ้นตรงที่ ไม่กระโดด
                                ch.consume()
                                dragging = true
                                origin = root(ch.position)
                                cbBegan()
                                break
                            }
                            // ชั้นที่เลื่อนได้เอานิ้วนี้ไปแล้ว (ปัดหน้า) = ไม่ใช่กดค้าง ไม่ใช่แตะ
                            val fin = awaitPointerEvent(PointerEventPass.Final)
                            if (fin.changes.any { it.id == pid && it.isConsumed }) {
                                tapAlive = false
                                pressAlive = false
                                panAlive = false
                            }
                        }

                        // ลากอยู่ — ถือนิ้วไว้เองจนยก
                        while (true) {
                            val ev = awaitPointerEvent()
                            val ch = ev.changes.firstOrNull { it.id == pid } ?: break
                            ch.consume()
                            if (!ch.pressed) break
                            cbPress(pt(ch.position))
                            val t = root(ch.position) - origin
                            cbChanged(Size(t.x / density, t.y / density))
                        }
                        dragging = false
                        cbEnded()
                    } finally {
                        // ถูกถอดกลางท่า (= recognizer ถูกยกเลิก) ก็ต้องจบการลากให้ผู้เรียก
                        if (dragging) cbEnded()
                        cbPress(null)
                    }
                }
            },
    )
}
