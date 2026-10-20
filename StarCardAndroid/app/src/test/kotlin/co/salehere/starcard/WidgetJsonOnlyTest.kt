package co.salehere.starcard

import co.salehere.starcard.model.SpecCatalog
import co.salehere.starcard.model.WidgetFamily
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.WidgetTier
import co.salehere.starcard.model.isKit
import co.salehere.starcard.theme.stampFacts
import co.salehere.starcard.theme.stampOverlay
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

// widget ใหม่จาก JSON อย่างเดียว (ใช้ทุกคีย์ของบล็อก `widget`) ต้องขึ้นตู้และได้นิสัยครบโดยไม่แตะโค้ด ·
// ลบไฟล์ผังของใบไหน ใบนั้นต้องหายจากตู้เฉย ๆ (WIDGET-CATEGORY-PLAN.md ข้อ 9 "JSON only จริง")
class WidgetJsonOnlyTest {
    private fun repoRoot(): File {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            if (File(dir, "shared/WidgetSpecs").isDirectory) return dir
            dir = dir.parentFile
        }
        error("repo root not found")
    }

    private val probe = """
        {"kind": "zzProbeWidget", "design": {"w": 200, "h": 100},
         "widget": {"title": "ทดสอบ", "category": "followers", "symbol": "star", "size": {"w": 180, "h": 90}, "order": 1,
           "tier": "personal", "ownSurface": true, "ownBorder": true, "surfaces": ["pane", "glass"],
           "surfaceNames": {"glass": "มีพื้น"}, "border": true, "photo": true,
           "keepAspect": true, "fullBleed": true, "resize": false,
           "kit": {"look": "cream"}, "controls": [{"type": "checks", "label": "ช่อง", "opt": "hide", "items": "shownSocials", "minItems": 2}],
           "skin": "paper", "stamp": "followers", "stampAt": {"tone": "dark", "top": 3, "trailing": 4},
           "motion": "anchored", "pinned": true, "replaces": ["zzOldProbe"]},
         "root": {"type": "col", "children": []}}
    """.trimIndent()

    @Test
    fun jsonOnlyWidget() {
        File(repoRoot(), "shared/WidgetSpecs").listFiles { f -> f.extension == "json" }!!.forEach { SpecCatalog.load(it.readText()) }
        val before = WidgetKind.entries.size
        SpecCatalog.load(probe)
        val k = WidgetKind.from("zzProbeWidget")!!
        assertEquals(before + 1, WidgetKind.entries.size)
        assertEquals(WidgetFamily.followers, k.family)
        assertEquals("ทดสอบ", k.title)
        assertEquals(180f, k.defaultSize.width)
        assertEquals(WidgetTier.personal, k.tier)
        assertTrue(k.drawsOwnSurface && k.drawsOwnBorder && k.defaultBorder)
        assertEquals(listOf(WidgetSurface.pane, WidgetSurface.glass), k.surfaceOptions)
        assertEquals(WidgetSurface.pane, k.defaultSurface)
        assertEquals("มีพื้น", k.surfaceName(WidgetSurface.glass))
        assertTrue(k.usesPhoto && k.keepsDesignAspect && k.isFullBleed)
        assertTrue(!k.canResize && k.isKit && k.isPinnedKind)
        assertEquals(1, k.controls.size)
        assertEquals("followers", k.stampFacts?.name)
        assertEquals(3f, k.stampOverlay?.second)
        assertEquals(k, WidgetKind.decode("zzOldProbe"))

        // ลบไฟล์ผัง = หายจากตู้ ไม่พัง
        SpecCatalog.replace(File(repoRoot(), "shared/WidgetSpecs").listFiles { f -> f.extension == "json" }!!.map { it.readText() })
        assertNull(WidgetKind.from("zzProbeWidget"))
        assertEquals(before, WidgetKind.entries.size)
    }
}
