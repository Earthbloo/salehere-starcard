package co.salehere.starcard.model

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.ui.geometry.Size
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.CardTheme
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * เทมเพลตการ์ดสำเร็จรูป — ผังทั้งใบ + ธีม ที่ประกอบเสร็จแล้วให้เลือกเป็นจุดตั้งต้น
 * ทุกใบมาจากการ์ดที่ออกแบบเสร็จจริงในแอป (ดู `DesignedTemplate`)
 */
class CardTemplate(
    val id: String,
    val format: CardFormat,
    /** ชื่อ = ตระกูล + ท่าของผัง ("สปอตไลต์ คู่คลิป") — บอกโครงสร้างตั้งแต่ชื่อ */
    val name: String,
    /** ป้ายตระกูล — กวาดตาแยก โปสเตอร์/โฟโต้การ์ด ได้ตอนปัดเร็ว ๆ */
    val vibe: String,
    /** หนึ่งประโยคบอกว่าผังนี้เล่าเรื่องต่างจากใบอื่นยังไง */
    val blurb: String,
    val theme: CardTheme,
    private val builder: () -> List<CardPage>,
) {
    /**
     * สร้างหน้าชุดใหม่ทุกครั้ง — `WidgetInstance.id` เป็นของรันไทม์
     * ถ้าเก็บหน้าไว้เป็นค่าคงที่ การ์ดสองใบที่มาจากเทมเพลตเดียวกันจะแชร์ id กัน
     */
    fun makePages(): List<CardPage> = builder()

    override fun equals(other: Any?): Boolean = other is CardTemplate && other.id == id
    override fun hashCode(): Int = id.hashCode()

    companion object {
        /**
         * ช่องว่างระหว่างหน้า (และขอบรอบแถบ) ของแถบสามหน้าในสำรับ — ทั้งหน้าเลือกสไตล์และคลัง (หน่วยออกแบบ)
         * 26 จาก 402 = 6.5% ของความกว้างหน้า — พอที่จะอ่านเป็น "คนละแผ่น" แต่ยังเห็นว่าต่อกันเป็นแถบเดียว
         */
        const val thumbGutter: Float = 26f

        /** ขนาดหน้ามาตรฐานที่ใช้ทั้งตอนออกแบบผังและตอนวาดพรีวิว */
        fun previewPageSize(format: CardFormat): Size = when (format) {
            CardFormat.portfolio -> Size(402f, 670f)
            CardFormat.story -> Size(540f, 960f)
        }

        /** ตู้เทมเพลต = การ์ดที่ออกแบบเสร็จในแอปเท่านั้น (ผังตั้งต้นที่เขียนด้วยโค้ดถูกถอดออก 18 ก.ย. 2026) */
        fun all(format: CardFormat): List<CardTemplate> = designed(format)

        /** เทมเพลตจากการ์ดที่ออกแบบจริงในแอป — ผัง · ธีม · หน้าตาตัวอักษร มาครบทุกอย่าง */
        fun designed(format: CardFormat): List<CardTemplate> =
            DesignedTemplate.all.mapNotNull { d ->
                if (d.format != format.raw) return@mapNotNull null
                val theme = CardStore.restore(d.snapshot)?.theme ?: return@mapNotNull null
                CardTemplate(
                    id = d.id,
                    format = format,
                    name = d.name,
                    vibe = "DESIGNED",
                    blurb = "การ์ดที่ออกแบบเสร็จแล้ว — ใส่รูปและข้อมูลของคุณให้อัตโนมัติ",
                    theme = theme,
                    builder = {
                        // ตอนเลือก ทุกชิ้นได้ id ใหม่ (`id = null`) — รูปเฉพาะชิ้นกับข้อความที่ผูก id เดิมจึงไม่ตามมา
                        val snap = d.snapshot.copy(
                            pages = d.snapshot.pages.map { p -> p.copy(items = p.items.map { it.copy(id = null) }) },
                        )
                        CardStore.restore(snap)?.pages ?: listOf(CardPage())
                    },
                )
            }
    }
}

// MARK: - เทมเพลตจากการ์ดที่ออกแบบจริงในแอป

/**
 * การ์ดที่ทีมแต่งเสร็จในแอป ถูกยกมาเป็นเทมเพลต — ผัง · ธีม · หน้าตาตัวอักษร มาครบทุกอย่าง
 *
 * รูปบนผนัง (`assets/designed_templates/<id>.png`) อบจากการ์ดต้นฉบับพร้อมรูปของผู้ออกแบบ — โชว์ว่าผังนี้
 * "ทำเสร็จแล้วหน้าตาเป็นแบบนี้" ไม่ใช่ช่องว่างรอเติม · ตอนเลือก ทุกชิ้นได้ id ใหม่
 */
@Serializable
data class DesignedTemplate(
    val id: String,
    val name: String,
    val format: String,
    val snapshot: CardSnapshot,
) {
    companion object {
        /** โฟลเดอร์ใน `assets/` (iOS: `Resources/DesignedTemplates/` ที่ถูกคัดลอกแบนลงรากของ bundle) */
        const val bundleFolder = "designed_templates"

        private val json = Json { ignoreUnknownKeys = true }

        val all: List<DesignedTemplate> by lazy {
            runCatching {
                AppContext.app.assets.open("$bundleFolder/designed-templates.json").use { stream ->
                    val text = stream.bufferedReader().readText()
                    json.decodeFromString(ListSerializer(serializer()), text)
                }
            }.getOrDefault(emptyList())
        }

        /** รูปตัวอย่างที่อบไว้ — null = ยังไม่มีรูป ผนังตกไปอบสดแบบเทมเพลตอื่น */
        fun preview(id: String): Bitmap? =
            runCatching {
                AppContext.app.assets.open("$bundleFolder/$id.png").use { BitmapFactory.decodeStream(it) }
            }.getOrNull()
    }
}
