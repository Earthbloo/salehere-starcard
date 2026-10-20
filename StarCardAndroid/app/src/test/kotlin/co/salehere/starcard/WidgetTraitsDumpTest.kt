package co.salehere.starcard

import co.salehere.starcard.layout.PageLayout
import co.salehere.starcard.model.SpecCatalog
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.isKit
import co.salehere.starcard.theme.stampFacts
import co.salehere.starcard.theme.stampOverlay
import org.junit.Test
import java.io.File

// นิสัยทุกชนิด (ตู้ · ถาด · พื้นผิว · ป้าย) เป็น JSON — เทียบกับ iOS `-exportBaseline` traits.json
// รัน: ./gradlew :app:testDebugUnitTest --tests '*WidgetTraitsDumpTest*' (env TRAITS_OUT=<file>)
class WidgetTraitsDumpTest {
    private fun repoRoot(): File {
        var dir: File? = File(System.getProperty("user.dir")).absoluteFile
        while (dir != null) {
            if (File(dir, "shared/WidgetSpecs").isDirectory) return dir
            dir = dir.parentFile
        }
        error("repo root not found")
    }

    private fun q(s: String) = "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

    @Test
    fun dumpTraits() {
        val out = System.getenv("TRAITS_OUT") ?: return
        val dir = System.getenv("SPECS_DIR")?.let { File(it) } ?: File(repoRoot(), "shared/WidgetSpecs")
        dir.listFiles { f -> f.extension == "json" }!!.forEach { SpecCatalog.load(it.readText()) }
        val kinds = WidgetKind.entries.toMutableList()
        WidgetKind.from("textBlock")?.let { if (it !in kinds) kinds.add(it) }
        val sb = StringBuilder("{\n")
        for (k in kinds) {
            val names = WidgetSurface.entries.joinToString(",") { "${q(it.name)}:${q(k.surfaceName(it))}" }
            val ov = k.stampOverlay?.let { ",\"stampAt\":[${q(it.first.name)},${it.second},${it.third}]" } ?: ""
            sb.append("${q(k.raw)}:{\"title\":${q(k.title)},\"symbol\":${q(k.symbol)},\"size\":[${k.defaultSize.width},${k.defaultSize.height}]," +
                "\"family\":${q(k.family.raw)},\"trayGroup\":${q(k.family.trayGroup.raw)},\"group\":${q(k.group.raw)},\"tier\":${q(k.tier.name)}," +
                "\"ownSurface\":${k.drawsOwnSurface},\"surfaces\":[${k.surfaceOptions.joinToString(",") { q(it.name) }}],\"surfaceNames\":{$names}," +
                "\"defaultSurface\":${q(k.defaultSurface.name)},\"border\":${k.defaultBorder},\"controls\":[${k.controls.mapNotNull { it.opt }.joinToString(",") { q(it) }}]," +
                "\"photo\":${k.usesPhoto},\"keepAspect\":${k.keepsDesignAspect},\"fullBleed\":${k.isFullBleed}," +
                "\"resize\":${k.canResize},\"kit\":${k.isKit},\"pop\":${k.popSkin != null}," +
                "\"skin\":${q(k.popSkin?.name ?: "-")},\"stamp\":${q(k.stampFacts?.name ?: "-")}$ov," +
                "\"minSize\":[${PageLayout.minSize(k).width},${PageLayout.minSize(k).height}]},\n")
        }
        sb.append("\"_order\":[${WidgetKind.entries.joinToString(",") { q(it.raw) }}]\n}\n")
        File(out).writeText(sb.toString())
    }
}
