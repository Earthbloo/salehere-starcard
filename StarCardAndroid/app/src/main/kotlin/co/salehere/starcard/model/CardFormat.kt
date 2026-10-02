package co.salehere.starcard.model

import androidx.compose.ui.geometry.Size

/**
 * รูปแบบของการ์ด — ตัดสินว่า "กี่หน้า" และ "หน้าใหญ่เท่าไหร่"
 *
 * สองแบบนี้ต่างกันที่ **จำนวนหน้า** ไม่ใช่แค่หน้าตา — ถ้าให้สลับกลางทาง
 * ระบบต้องตัดสินใจแทนผู้ใช้ว่าของอีกสองหน้าจะไปไหน ซึ่งไม่มีคำตอบที่ถูก
 * เลือกตั้งแต่ต้นแล้วเก็บฉบับร่าง **แยกช่องกัน** (ดู `CardStore`)
 */
enum class CardFormat {
    /** พอร์ตโฟลิโอ 3 หน้า — ปัดเปลี่ยนหน้าได้ · export เป็นแถบเดียวยาว */
    portfolio,
    /** สตอรี่หน้าเดียว 9:16 — ทุกอย่างต้องจบในเฟรมเดียว เหมือนแต่ง Story */
    story;

    val raw: String get() = name
    val id: String get() = raw

    /** จำนวนหน้าที่การ์ดแบบนี้มีได้ — สตอรี่คือ 1 และเพิ่มไม่ได้ */
    val pageCount: Int
        get() = when (this) {
            portfolio -> 3
            story -> 1
        }

    /**
     * ความกว้างของพื้นที่ออกแบบ — **ตัวนี้คือสิ่งที่ทำให้ขนาด widget เป็นพิกเซลจริง**
     * ตรึงความกว้างไว้ แปลว่า "widget กว้าง 366" กว้างเท่ากันทุกเครื่องและในไฟล์ที่ export
     * * พอร์ต 402 = ความกว้างหน้าเดิมบนเครื่องอ้างอิง · สตอรี่ 540 = 1080×1920 px ที่ @2x พอดี
     */
    val designWidth: Float
        get() = when (this) {
            portfolio -> 402f
            story -> 540f
        }

    /**
     * ความสูงที่ล็อกไว้ — null = **ยืดตามจอ** เหมือนเดิม
     * สตอรี่ต้องล็อกเพราะปลายทางคือ 9:16 เป๊ะ ๆ · พอร์ตไม่มีอัตราส่วนปลายทาง มันคือ "หน้าเต็มจอ"
     */
    val designHeight: Float?
        get() = when (this) {
            portfolio -> null
            story -> 960f
        }

    /** ขนาดหน้าใน **หน่วยออกแบบ** — ความกว้างตายตัวเสมอ ความสูงตามแบบ */
    fun pageSize(box: Size): Size {
        val w = designWidth
        val h = designHeight
        if (h != null) return Size(w, h)
        if (!(box.width > 1 && box.height > 1)) return Size(w, w * 1.667f)
        // แปลงความสูงที่จอให้มา เข้าหน่วยออกแบบด้วยอัตราส่วนความกว้าง
        return Size(w, box.height * w / box.width)
    }

    /** อัตราย่อจากหน่วยออกแบบ → หน่วยจอ */
    fun fit(box: Size): Float {
        val d = pageSize(box)
        if (!(d.width > 1 && d.height > 1 && box.width > 1 && box.height > 1)) return 1f
        return minOf(box.width / d.width, box.height / d.height)
    }

    val title: String
        get() = when (this) {
            portfolio -> "พอร์ตโฟลิโอ"
            story -> "สตอรี่"
        }

    val subtitle: String
        get() = when (this) {
            portfolio -> "3 หน้า · เต็มจอ"
            story -> "หน้าเดียว · 1080×1920"
        }

    val blurb: String
        get() = when (this) {
            portfolio -> "ใส่ได้ครบทั้งตัวตน สถิติ ผลงาน และราคา · แชร์เป็นแถบเดียวยาว"
            story -> "จบในเฟรมเดียว ลงสตอรี่ได้เลย · แต่งเหมือนแต่ง Story"
        }

    val icon: String
        get() = when (this) {
            portfolio -> "rectangle.split.3x1"
            story -> "rectangle.portrait"
        }

    /** หน้าตั้งต้นของการ์ดแบบนี้ */
    val starterPages: List<CardPage>
        get() = when (this) {
            portfolio -> Mock.starterPages
            story -> listOf(Mock.storyPage)
        }

    companion object {
        fun from(raw: String?): CardFormat? = entries.firstOrNull { it.raw == raw }
    }
}
