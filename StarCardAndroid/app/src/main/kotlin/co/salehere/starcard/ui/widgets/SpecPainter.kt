package co.salehere.starcard.ui.widgets

import android.graphics.BlurMaskFilter
import android.os.Build
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.State
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.BlurEffect
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.ColorMatrix
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.addOutline
import androidx.compose.ui.graphics.asAndroidPath
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.drawscope.translate
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.layer.drawLayer
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.LineBreak
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.LocalContentColor
import androidx.compose.foundation.text.TextAutoSize
import co.salehere.starcard.components.redacted
import co.salehere.starcard.layout.AndroidSpecMeasurer
import co.salehere.starcard.layout.FSize
import co.salehere.starcard.layout.SpecBox
import co.salehere.starcard.layout.SpecFont
import co.salehere.starcard.layout.SpecItem
import co.salehere.starcard.layout.SpecSolver
import co.salehere.starcard.layout.weightOf
import co.salehere.starcard.model.AndroidSpecData
import co.salehere.starcard.model.KitLook
import co.salehere.starcard.model.LocalKitConfig
import co.salehere.starcard.model.looking
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.LocalSpecDataOverride
import co.salehere.starcard.model.LocalWidgetBorder
import co.salehere.starcard.model.LocalWidgetSurface
import co.salehere.starcard.model.PopSkin
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.SpecNode
import co.salehere.starcard.model.SpecShadow
import co.salehere.starcard.model.SpecType
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.WidgetKind
import co.salehere.starcard.model.WidgetSpec
import co.salehere.starcard.model.WidgetSurface
import co.salehere.starcard.model.kitHex
import co.salehere.starcard.model.photoSlot
import co.salehere.starcard.model.WidgetPhoto
import co.salehere.starcard.theme.CardFont
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.theme.InkStyle
import co.salehere.starcard.theme.LocalCardInk
import co.salehere.starcard.theme.LocalSaleHereStamped
import co.salehere.starcard.theme.LocalScrapTone
import co.salehere.starcard.theme.PlatePatternLayer
import co.salehere.starcard.theme.LocalWidgetTextStyle
import co.salehere.starcard.theme.WidgetTextStyle
import co.salehere.starcard.theme.grey
import co.salehere.starcard.theme.onLightSurface
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.ui.LocalCardAccent
import co.salehere.starcard.ui.LocalGhostData
import co.salehere.starcard.ui.LocalSampleData
import co.salehere.starcard.ui.LocalWidgetRenderScale
import co.salehere.starcard.ui.LocalWidgetID
import co.salehere.starcard.ui.editor.EditableText
import co.salehere.starcard.ui.editor.TextSlotStyle
import co.salehere.starcard.ui.editor.editableSlot
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

// MARK: - ตัววาดผัง (Android) (= Views/Widgets/SpecPainter.swift)
//
// รู้จักของไม่กี่อย่าง — กล่องมุมมน · เส้น · ไล่สี · ข้อความ · รูป · ไอคอน — และ **ไม่ตัดสินใจอะไร**
// ตำแหน่ง/ขนาด/ขนาดตัวอักษร/จำนวนบรรทัด มาจาก `SpecSolver` ทั้งหมด (WIDGET-SPEC.md §5–6)
// ทุกตัวเลขเป็นหน่วยออกแบบ = dp (แอปตรึง fontScale = 1 · chrome ย่อ/ขยายทั้งก้อนด้วย graphicsLayer)
//
// ข้อความวาด **บรรทัดที่ตัววัดตัดไว้แล้ว** (`AndroidSpecMeasurer.displayLines`) ไม่ปล่อยให้ Compose ตัดบรรทัดเอง —
// สิ่งที่ตัวคำนวณวัดกับสิ่งที่ตาเห็นจึงเป็นบรรทัดชุดเดียวกันเสมอ

@Composable
fun SpecPainter(spec: WidgetSpec, kind: WidgetKind, theme: CardTheme, size: Size, modifier: Modifier = Modifier) {
    val ink = LocalCardInk.current
    val accent = LocalCardAccent.current
    val wid = LocalWidgetID.current
    val sample = LocalSampleData.current
    // ค่าของชิ้น + หน้าตาของชนิด (`widget.kit.look`)
    val kit = LocalKitConfig.current.looking(kind)
    val border = LocalWidgetBorder.current
    val surface = LocalWidgetSurface.current
    val stamped = LocalSaleHereStamped.current
    val scrapTone = LocalScrapTone.current
    val photos = LocalPhotoStore.current
    val measurer = remember { AndroidSpecMeasurer() }

    val look = remember(kit, border, ink, theme) { KitLook(kit.resolved(theme), border = border, cardDark = !ink.isLight) }
    // สีของชุดห้าสไตล์/สแครปบุ๊ก/การ์ด ที่ผังอ้างเป็น token (`kit.ink` · `scrap.paper` · `rawAccent`) — คิดจากธีม+ค่าของชิ้น
    val extraTokens: Map<String, Color> = remember(look, ink, theme, scrapTone, surface, kind) {
        val t = scrapTone
        val ed = Ed.skin(surface, Ed.paper, ink, theme)
        val skin = kind.popSkin ?: PopSkin.glass
        mapOf(
            "kit.fill" to Color.kitHex(look.fillHex), "kit.border" to look.borderColor, "kit.ink" to look.ink, "kit.mut" to look.mut,
            "kit.accent" to look.accent, "kit.title" to look.title, "kit.block" to look.blockFill,
            "scrap.paper" to t.paper, "scrap.ink" to t.ink, "scrap.soft" to t.soft, "scrap.accent" to t.accent, "scrap.strong" to t.strong,
            "scrap.paperAccent" to t.paperAccent, "scrap.paperStrong" to t.paperStrong, "scrap.band" to t.band, "scrap.mid" to t.mid,
            "scrap.blush" to t.blush, "scrap.shade" to t.shade, "scrap.speck" to t.speck,
            "rawAccent" to theme.rawAccent, "rawAccentSoft" to theme.rawAccentSoft,
            // แผ่นเข้มของสำรับโปสเตอร์ + ครีมบนแผ่น (`PosterPlate` — คู่สีใช้สีเข้ม/อ่อนของคู่)
            "plate" to PosterPlate.plate(theme), "plateInk" to PosterPlate.cream(theme),
            // สีเน้นของธีมที่ปรับให้นั่งบน **กระดาษสว่างที่ใบวาดเอง**
            "accentPaper" to theme.rawAccent.onLightSurface(),
            // หมึกของสำรับบรรณาธิการตามพื้นผิวที่เลือก (`Ed.skin`)
            "ed.sheet" to ed.sheet, "ed.ink" to ed.ink, "ed.inkSoft" to ed.inkSoft, "ed.ghost" to ed.ghost, "ed.marker" to ed.marker, "ed.red" to ed.red,
            // สำรับสติกเกอร์ — ถ่านคงที่บนกล่องขาว · พื้นกล่องตามพื้นผิว
            "pop.ink" to Pop.ink, "pop.inkSoft" to Pop.inkSoft, "pop.rule" to Pop.rule, "pop.paper" to Pop.paper,
            "pop.sheet" to Pop.sheetFill(surface, skin, theme), "pop.shadow" to Pop.sheetShadow(surface, skin, theme),
        )
    }

    // กล่องรากคือ **ที่ที่ได้จริง** (chrome หักระยะขอบในออกแล้ว) ไม่ใช่ `size` ที่ส่งมาซึ่งเป็นกรอบเต็มก่อนหักขอบ
    BoxWithConstraints(modifier.fillMaxSize(), contentAlignment = Alignment.TopStart) {
        val w = max(1.0, maxWidth.value.toDouble())
        val h = max(1.0, maxHeight.value.toDouble())
        val cutout = photos != null && cutoutPlane(photos, 1, wid) is CutoutPlane.Subject
        val override = LocalSpecDataOverride.current
        val renderScale = LocalWidgetRenderScale.current
        val data = override ?: remember(sample, wid, ink.isLight, kit, border, surface, theme, stamped, cutout, look) {
            AndroidSpecData(
                sample = sample, widget = wid, inkLight = ink.isLight, kit = kit, border = border,
                surface = surface, duo = theme.activeDuo != null, stamped = stamped, cutout = cutout, kitDark = look.dark,
            )
        }
        // `derivedStateOf` ตามการอ่าน state ของ `Profile` ข้างใน solver — ข้อความเปลี่ยนแล้วคำนวณใหม่เอง
        val solved: State<Pair<List<SpecBox>, Double>> = remember(spec, w, h, data, renderScale) {
            derivedStateOf {
                val s = SpecSolver(spec, FSize(w, h), data, measurer, renderScale)
                s.solve() to s.scale
            }
        }
        val (boxes, k) = solved.value
        val tree = remember(boxes) { SpecTree(boxes) }
        val ctx = PaintContext(ink, accent, theme, extraTokens, wid, measurer)
        // ผังวางใน `box / k` แล้วย่อทั้งก้อนด้วย `k` (= `.frame(box / k).scaleEffect(k, anchor: .topLeading)`)
        Box(Modifier.size(w.dp, h.dp), contentAlignment = Alignment.TopStart) {
            Box(
                Modifier
                    .wrapContentSize(Alignment.TopStart, unbounded = true)
                    .requiredSize((w / k).dp, (h / k).dp)
                    .graphicsLayer {
                        scaleX = k.toFloat(); scaleY = k.toFloat()
                        transformOrigin = TransformOrigin(0f, 0f)
                    },
                contentAlignment = Alignment.TopStart,
            ) {
                tree.root?.let { ctx.Node(it, tree, Modifier) }
            }
        }
    }
}

/** ของที่ทุก primitive ต้องใช้ร่วมกัน — ส่งเป็นก้อนเดียวแทนอ่าน Local ซ้ำทุกโหนด */
private class PaintContext(
    val ink: InkStyle,
    val accent: Color,
    val theme: CardTheme,
    val extra: Map<String, Color>,
    val wid: java.util.UUID?,
    val measurer: AndroidSpecMeasurer,
) {
    // MARK: ต้นไม้ — วาดซ้อนตามโครงสร้าง (clip · opacity · rotate ใช้กับทั้งกิ่ง)

    /** กล่องของโหนดหนึ่ง + ลูกทั้งหมดซ้อนข้างใน (พิกัดลูกสัมพัทธ์กับแม่) */
    @Composable
    fun Node(b: SpecBox, t: SpecTree, modifier: Modifier) {
        val n = b.node
        val kids = t.children[b.id] ?: emptyList()
        val f = b.frame
        val shape = SpecShapes.make(n.shape, corner(n, f.width, f.height))
        val rot = rotation(n, b.item)
        val alpha = (n.opacity ?: 1.0).toFloat()
        var m = modifier.size(f.width.dp, f.height.dp)
        if (rot != 0.0 || alpha != 1f) m = m.graphicsLayer { rotationZ = rot.toFloat(); this.alpha = alpha }
        if (n.clip == true) m = m.clip(shape)
        Box(m, contentAlignment = Alignment.TopStart) {
            Paint(b)
            for (c in kids) {
                Node(c, t, Modifier.offset((c.frame.minX - f.minX).dp, (c.frame.minY - f.minY).dp))
            }
        }
    }

    /** มุมของกล่อง ณ ขนาดจริง — `circle` = ครึ่งด้านสั้น (วงกลม/แคปซูล) */
    private fun corner(n: SpecNode, w: Double, h: Double): Float =
        (if (n.circle == true) min(w, h) / 2 else n.radius ?: 0.0).toFloat()

    private fun rotation(n: SpecNode, item: SpecItem?): Double {
        val c = n.rotateCycle
        if (c != null && c.isNotEmpty() && item != null) return c[item.i % c.size]
        return n.rotate ?: 0.0
    }

    // MARK: primitive

    @Composable
    private fun Paint(b: SpecBox) {
        val n = b.node
        when (n.type) {
            SpecType.col, SpecType.row, SpecType.stack, SpecType.chips, SpecType.spacer ->
                Background(n, b.item, b.frame.width, b.frame.height, null)
            SpecType.rect, SpecType.line ->
                Background(n, b.item, b.frame.width, b.frame.height, if (n.type == SpecType.line) "ink@0.12" else null)
            SpecType.text -> TextNode(b)
            SpecType.image -> ImageNode(b)
            SpecType.icon -> IconNode(b)
        }
    }

    /** ลายแผ่นของถาด + พื้น · ไล่สี · ลาย · เส้นขอบ · เงา ของกล่องหนึ่งใบ — ไม่มีค่าไหนตั้ง = ไม่วาดอะไร */
    @Composable
    private fun Background(n: SpecNode, item: SpecItem?, w: Double, h: Double, defaultFill: String?) {
        val shape = SpecShapes.make(n.shape, corner(n, w, h))
        val pp = n.platePattern
        if (pp != null) {
            // ลายแผ่นของถาด (ลายทาง · ข้าวหลามตัด) — ไม่เลือก = `.plain` ไม่วาดอะไร
            PlatePatternLayerSpec(color(pp, item), shape)
        }
        val cycle = n.fillCycle
        val fill = (if (cycle != null && cycle.isNotEmpty() && item != null) cycle[item.i % cycle.size] else null)
            ?: n.fill ?: defaultFill
        val g = n.gradient
        val s = n.stroke
        val pat = n.pattern
        if (fill == null && g == null && s == null && pat == null) return
        val fillColor = fill?.let { color(it, item) }
        val gFrom = g?.let { color(it.from, item) }
        val gTo = g?.let { color(it.to, item) }
        val strokeColor = s?.let { color(it.color, item) }
        val shadowColor = n.shadow?.let { color(it.color, item) }
        // SwiftUI สร้างเงาจาก **เนื้อที่วาดจริง** (compositingGroup) — พื้นใส 7% + เส้น 30% ได้เงาจางตามนั้น
        // ไม่ใช่รูปทรงทึบเต็มสีเงา · ความเข้มของพื้น = อัลฟาของสีพื้น (ไล่สี = เฉลี่ยสองปลาย) · ลาย = ทึบ
        val fillAlpha = when {
            pat != null -> 1f
            gFrom != null && gTo != null -> (gFrom.alpha + gTo.alpha) / 2
            fillColor != null -> fillColor.alpha
            else -> 0f
        }
        Box(
            Modifier
                .fillMaxSize()
                .specShapeShadow(n.shadow, shadowColor, shape, fillAlpha, s?.width?.toFloat() ?: 0f, strokeColor?.alpha ?: 0f)
                .drawWithCache {
                    val outline = shape.createOutline(size, layoutDirection, this)
                    val path = Path().apply { addOutline(outline) }
                    val brush: Brush? = if (g != null && gFrom != null && gTo != null) {
                        // angle 0 = ซ้าย→ขวา · 90 = บน→ล่าง (สูตร UnitPoint เดียวกับ iOS)
                        val a = g.angle * PI / 180
                        val dx = cos(a).toFloat(); val dy = sin(a).toFloat()
                        Brush.linearGradient(
                            listOf(gFrom, gTo),
                            start = Offset(size.width * (0.5f - dx / 2), size.height * (0.5f - dy / 2)),
                            end = Offset(size.width * (0.5f + dx / 2), size.height * (0.5f + dy / 2)),
                        )
                    } else null
                    onDrawBehind {
                        if (brush != null) drawPath(path, brush)
                        else if (fillColor != null) drawPath(path, fillColor)
                    }
                },
        ) {
            if (pat != null) {
                SpecPatternView(
                    pattern = pat, color = color(pat.color, item), color2 = color(pat.color2 ?: pat.color, item),
                    modifier = Modifier.fillMaxSize().clip(shape),
                )
            }
            if (s != null && strokeColor != null) {
                InnerStroke(shape, strokeColor, s.width.toFloat(), s.dash)
            }
        }
    }

    /** ลายแผ่นของถาด ตัดตามรูปร่างของกล่อง (= `PlatePatternLayer(sheet:).clipShape(shape)`) */
    @Composable
    private fun PlatePatternLayerSpec(sheet: Color, shape: Shape) {
        Box(Modifier.fillMaxSize().clip(shape)) { PlatePatternLayer(sheet = sheet) }
    }

    /** เส้นขอบด้านใน — ไม่มี dash: วาดหนา 2× แล้ว clip (= iOS) · มี dash: หนาตามจริงแล้ว clip */
    @Composable
    private fun InnerStroke(shape: Shape, color: Color, width: Float, dash: List<Double>?) {
        Box(
            Modifier.fillMaxSize().drawWithCache {
                val outline = shape.createOutline(size, layoutDirection, this)
                val path = Path().apply { addOutline(outline) }
                val d = density
                val style = if (dash != null) {
                    Stroke(width = width * d, pathEffect = PathEffect.dashPathEffect(dash.map { it.toFloat() * d }.toFloatArray()))
                } else Stroke(width = width * 2 * d)
                onDrawBehind { clipPath(path) { drawPath(path, color, style = style) } }
            },
        )
    }

    @Composable
    private fun TextNode(b: SpecBox) {
        val n = b.node
        val r = b.text ?: return
        val align: TextAlign = when (n.textAlign) { "center" -> TextAlign.Center; "right" -> TextAlign.End; else -> TextAlign.Start }
        val frameAlign: Alignment = when (n.textAlign) { "center" -> Alignment.TopCenter; "right" -> Alignment.TopEnd; else -> Alignment.TopStart }
        val face = CardFont.from(n.face) ?: CardFont.noto
        val weight = weightOf(n.weight ?: 400)
        val col = color(n.color ?: "ink", b.item)
        // ข้อความบน widget = ข้อมูลของหมวดล้วน — แตะไม่ได้ ไม่มีการพิมพ์/ปรับขนาด/สี/ฟอนต์ (หน้าตาตามผัง + ธีม)
        val tracking = (n.tracking ?: 0.0).toFloat()
        val kerning = (n.kerning ?: 0.0).toFloat()
        val lineSpacing = lineSpacing(n, r.size)
        val shadowColor = n.shadow?.let { color(it.color, b.item) }
        // ฟอนต์ที่ตัวคำนวณใช้วัด — บรรทัดที่วาดตัดด้วยฟอนต์นี้
        val measureFont = SpecFont(
            face = face.raw, size = r.size, weight = n.weight ?: 400,
            tracking = n.tracking ?: 0.0, kerning = n.kerning ?: 0.0, italic = n.italic ?: false, lineHeight = n.lineHeight ?: 1.0,
        )
        val shownString = if (n.textCase == "upper") r.string.uppercase(java.util.Locale.ROOT) else r.string
        val lines = measurer.displayLines(shownString, measureFont, b.frame.width, max(1, r.lines))
        val shown = lines.joinToString("\n")
        Box(Modifier.fillMaxSize().specGlow(n.shadow, shadowColor), contentAlignment = frameAlign) {
            if (n.mixHead == true && r.string.trim().contains(' ')) {
                MixedHead(n, r.string, r.size, face, weight, col, align)
            } else {
                Text(
                    shown, style = plainStyle(face, r.size, weight, tracking + kerning, n.italic == true, lineSpacing, measureFont),
                    color = col, textAlign = align, maxLines = lines.size, softWrap = false, overflow = TextOverflow.Visible,
                )
            }
        }
    }

    private fun plainStyle(face: CardFont, size: Double, weight: FontWeight, spacing: Float, italic: Boolean, lineSpacing: Float, f: SpecFont): TextStyle {
        var ts = face.font(size.toFloat(), weight)
        if (spacing != 0f) ts = ts.copy(letterSpacing = spacing.sp)
        if (italic) ts = ts.copy(fontStyle = FontStyle.Italic)
        // ความสูงบรรทัดเท่าที่ตัววัดคิด (+ ระยะเพิ่มของ `lineHeight`) — ไม่ปล่อยให้ Compose ใช้ของตัวเอง
        val one = measurer.lineHeight(f.copy(lineHeight = 1.0)).toFloat()
        ts = ts.copy(lineHeight = (one + lineSpacing).sp, lineBreak = LineBreak.Simple)
        return ts
    }

    /**
     * พาดหัวสองเสียงของสำรับโปสเตอร์ (`mixHead`): คำแรกตามฟอนต์ของโหนด · ที่เหลือ noto บางเอียง ×1.04
     * ย่อพร้อมกันทั้งก้อนได้ถึงครึ่งหนึ่ง (= `.minimumScaleFactor(0.5)` ของ iOS)
     */
    @Composable
    private fun MixedHead(n: SpecNode, s: String, size: Double, face: CardFont, weight: FontWeight, col: Color,
                          align: TextAlign) {
        val parts = s.trim().split(Regex(" +"), limit = 2)
        val head = face.font(size.toFloat(), weight)
        val tail = CardFont.noto.font((size * 1.04).toFloat(), FontWeight.Light)
        val text = buildAnnotatedString {
            withStyle(SpanStyle(fontFamily = head.fontFamily, fontWeight = head.fontWeight, fontSize = head.fontSize,
                letterSpacing = (n.kerning ?: 0.0).toFloat().sp)) { append(parts[0]) }
            withStyle(SpanStyle(fontFamily = tail.fontFamily, fontWeight = FontWeight.Light, fontSize = tail.fontSize,
                fontStyle = FontStyle.Italic)) { append(" " + parts[1]) }
        }
        Text(
            text, color = col, textAlign = align, maxLines = 1, softWrap = false, overflow = TextOverflow.Ellipsis,
            style = head.copy(lineBreak = LineBreak.Simple),
            autoSize = TextAutoSize.StepBased(minFontSize = (size * 0.5).sp, maxFontSize = size.sp, stepSize = 0.5.sp),
        )
    }

    /** ระยะบรรทัดเพิ่ม = ความสูงบรรทัดของฟอนต์ × (lineHeight − 1) (= iOS `lineSpacing`) */
    private fun lineSpacing(n: SpecNode, size: Double): Float {
        val lh = n.lineHeight ?: return 0f
        if (lh == 1.0) return 0f
        val one = measurer.lineHeight(SpecFont(face = n.face ?: "body", size = size, weight = n.weight ?: 400))
        return (one * (lh - 1)).toFloat()
    }

    @Composable
    private fun ImageNode(b: SpecBox) {
        val n = b.node
        val f = b.frame
        val shape = SpecShapes.make(n.shape, corner(n, f.width, f.height))
        val item = b.item
        val ref = n.photoRef
        val slot = (if (ref != null) (if (ref.startsWith("$")) item?.value(ref.drop(1))?.toIntOrNull() else ref.toIntOrNull()) else null)
            ?: n.photo ?: item?.value("photo")?.toIntOrNull() ?: 0
        // `src`: รูปจาก asset ของแอป (`"$cover"` = ปกผลงาน) — ว่าง = ช่องรูปของชิ้นตามเดิม
        val src = n.src?.let { if (it.startsWith("$")) (item?.value(it.drop(1)) ?: "") else it } ?: ""
        val s = n.stroke
        val shadowColor = n.shadow?.let { color(it.color) }
        val asset = if (src.isNotEmpty() && !src.startsWith("http")) drawableIdOf(src) else 0
        Box(
            Modifier
                .fillMaxSize()
                .specGlow(n.shadow, shadowColor)
                .photoSlot(slot)
                .clip(shape)
                .let { m ->
                    if (n.mono == true) m.graphicsLayer { colorFilter = ColorFilter.colorMatrix(ColorMatrix().apply { setToSaturation(0f) }) } else m
                },
        ) {
            val scale = if (n.fit == "contain") ContentScale.Fit else ContentScale.Crop
            when {
                asset != 0 -> Image(painterResource(asset), contentDescription = null, contentScale = scale, modifier = Modifier.fillMaxSize())
                src.startsWith("http") -> RemoteLogo(src, Modifier.fillMaxSize())
                n.fit == "contain" -> SpecPhotoContain(slot)
                else -> WidgetPhoto(slot, Modifier.fillMaxSize())
            }
            if (s != null) InnerStroke(shape, color(s.color), s.width.toFloat(), null)
        }
    }

    /** drawable ตามชื่อ asset ของ iOS (ขีดกลาง → ขีดล่าง · ตัวเล็ก) · 0 = ไม่มี */
    @Composable
    private fun drawableIdOf(name: String): Int {
        val ctx = LocalContext.current
        val key = name.replace('-', '_').lowercase()
        return remember(key) { ctx.resources.getIdentifier(key, "drawable", ctx.packageName) }
    }

    /** รูปแบบ contain (= `.aspectRatio(contentMode: .fit)`) — ลำดับรูปเดียวกับ `WidgetPhoto` · ไม่มีรูปในเครื่องตกไปรูประบบแบบ cover */
    @Composable
    private fun SpecPhotoContain(index: Int) {
        val store = LocalPhotoStore.current
        val bmp = store?.let { st -> (wid?.let { st.uiImage(index, it) } ?: st.library(index)) }
            ?: ImageCache.shared.cached(PhotoLib.url(index))
        if (bmp != null) {
            Image(bmp.asImageBitmap(), contentDescription = null, contentScale = ContentScale.Fit, modifier = Modifier.fillMaxSize())
        } else {
            WidgetPhoto(index, Modifier.fillMaxSize())
        }
    }

    @Composable
    private fun IconNode(b: SpecBox) {
        val n = b.node
        val raw = n.icon ?: ""
        val name = if (raw.startsWith("$")) (b.item?.value(raw.drop(1)) ?: "") else raw
        val tint = n.tint?.let { color(it, b.item) }
        val f = b.frame
        Box(Modifier.size(f.width.dp, f.height.dp).clip(RoundedCornerShape(corner(n, f.width, f.height).dp))) {
            SpecIcon(
                name = name, box = Size(f.width.toFloat(), f.height.toFloat()), tint = tint, text = n.text, size = n.size?.toFloat(),
                ink = ink, accent = accent,
                handle = (LocalSpecDataOverride.current as? co.salehere.starcard.layout.ReplayData)?.texts?.get("handle" to null),
            )
        }
    }

    // MARK: สี

    fun color(token: String): Color = SpecColor.resolve(token, ink, accent, theme, extra)

    /** token ที่อ้างฟิลด์ของรายการ (`$tint` · `$tint@0.3`) — แทนค่าแล้วค่อยแปลง */
    fun color(token: String, item: SpecItem?): Color {
        if (!token.startsWith("$") || item == null) return color(token)
        var name = token.drop(1); var alpha = ""
        val at = name.indexOf('@')
        if (at >= 0) { alpha = name.substring(at); name = name.substring(0, at) }
        return color(item.value(name) + alpha)
    }
}

/** อ้างช่องของโปรไฟล์จากสตริงในผัง — `name` · `categories#2` · `note#1` (= `SlotRef` ของ iOS) */
data class SlotRef(val field: ProfileField, val index: Int?) {
    companion object {
        fun parse(s: String): SlotRef? {
            val parts = s.split("#", limit = 2)
            val f = ProfileField.from(parts[0]) ?: return null
            return SlotRef(f, if (parts.size > 1) parts[1].toIntOrNull() else null)
        }
    }
}

object SpecColor {
    /** token → สี · `ink` `ink@0.45` · `accent` · `paper` · `line` · `fill` · `ghost` · `white` · `black` · `#RRGGBB[AA]` */
    fun resolve(token: String, ink: InkStyle, accent: Color, theme: CardTheme, extra: Map<String, Color> = emptyMap()): Color {
        var name = token
        var alpha: Double? = null
        val at = token.lastIndexOf('@')
        if (at >= 0) { name = token.substring(0, at); alpha = token.substring(at + 1).toDoubleOrNull() }
        extra[name]?.let { c -> return alpha?.let { c.opacity(it) } ?: c }
        val base: Color = when (name) {
            "ink" -> return ink.text(alpha ?: 1.0)          // ความทึบของหมึกผ่านตัวยันความอ่านออก
            "line" -> return ink.line(alpha ?: 0.12)
            "fill" -> return ink.fill(alpha ?: 0.14)
            "ghost" -> return ink.ghost(alpha ?: 0.5)
            "accent" -> accent
            "accentSoft" -> theme.accentSoft
            "paper" -> if (ink.isLight) Color.White else grey(0.08)
            "white" -> Color.White
            "black" -> Color.Black
            "clear" -> return Color.Transparent
            else -> if (name.startsWith("#")) specHex(name) else Color.Transparent
        }
        return alpha?.let { base.opacity(it) } ?: base
    }

    /** `#RRGGBB` หรือ `#RRGGBBAA` (= `Color(hex:)` ของ iOS) */
    fun specHex(hex: String): Color {
        var h = hex.trim('#')
        if (h.length == 6) h += "FF"
        val v = h.toLongOrNull(16) ?: 0L
        return Color(
            red = ((v shr 24) and 0xFF) / 255f, green = ((v shr 16) and 0xFF) / 255f,
            blue = ((v shr 8) and 0xFF) / 255f, alpha = (v and 0xFF) / 255f,
        )
    }
}

/** ต้นไม้จากรายการกล่องแบน — ลูกของ `r/0` คือ `r/0/<n>` และ `r/0/c<n>` */
class SpecTree(boxes: List<SpecBox>) {
    val root: SpecBox? = boxes.firstOrNull { it.id == "r" }
    val children: Map<String, List<SpecBox>>
    init {
        val map = LinkedHashMap<String, MutableList<SpecBox>>()
        for (b in boxes) {
            if (b.id == "r") continue
            val cut = b.id.lastIndexOf('/')
            if (cut < 0) continue
            map.getOrPut(b.id.substring(0, cut)) { ArrayList() }.add(b)
        }
        children = map
    }
}

// MARK: - เงา (sigma → blur)

/**
 * เงาของรูปทรง (พื้น/กล่อง) — เบลอ (BlurMaskFilter) ใต้เนื้อหา · ทุก API · sigma → radius ของ Skia: `sigma = 0.57735·radius + 0.5`
 * เข้มตามเนื้อที่วาดจริงแบบ SwiftUI: ตัวพื้นได้อัลฟาเงา × อัลฟาพื้น · ขอบได้อัลฟาเงา × อัลฟาเส้น
 */
private fun Modifier.specShapeShadow(
    shadow: SpecShadow?, color: Color?, shape: Shape,
    fillAlpha: Float = 1f, strokeWidth: Float = 0f, strokeAlpha: Float = 0f,
): Modifier {
    if (shadow == null || color == null || color.alpha <= 0f) return this
    if (fillAlpha <= 0f && (strokeWidth <= 0f || strokeAlpha <= 0f)) return this
    return drawWithCache {
        val d = density
        val sigma = shadow.sigma.toFloat() * d
        val radius = max(0.5f, (sigma - 0.5f) / 0.57735f)
        val outline = shape.createOutline(size, layoutDirection, this)
        val path = Path().apply { addOutline(outline) }
        fun paintOf(alpha: Float) = android.graphics.Paint().apply {
            isAntiAlias = true
            this.color = color.copy(alpha = color.alpha * alpha.coerceIn(0f, 1f)).toArgb()
            maskFilter = BlurMaskFilter(radius, BlurMaskFilter.Blur.NORMAL)
        }
        val fillPaint = if (fillAlpha > 0f) paintOf(fillAlpha) else null
        // เส้นขอบด้านใน (iOS วาดหนา 2× แล้ว clip = แถบกว้าง `width` ชิดขอบด้านใน)
        val ring = if (strokeWidth > 0f && strokeAlpha > fillAlpha) paintOf(strokeAlpha - fillAlpha).apply {
            style = android.graphics.Paint.Style.STROKE; this.strokeWidth = strokeWidth * d
        } else null
        val dx = shadow.x.toFloat() * d; val dy = shadow.y.toFloat() * d
        onDrawBehind {
            translate(dx, dy) {
                drawIntoCanvas {
                    val p = path.asAndroidPath()
                    fillPaint?.let { fp -> it.nativeCanvas.drawPath(p, fp) }
                    ring?.let { rp -> it.nativeCanvas.drawPath(p, rp) }
                }
            }
        }
    }
}

/**
 * เรืองแสงของตัวอักษร/รูป — สำเนาของเนื้อหาที่เบลอ (sigma) และย้อมสี วาดใต้ของจริง
 * ต้องใช้ RenderEffect (API 31+) · เครื่องเก่ากว่าไม่มีเงา (ยอมให้ต่าง — WIDGET-SPEC.md §6)
 */
private fun Modifier.specGlow(shadow: SpecShadow?, color: Color?): Modifier {
    if (shadow == null || color == null || color.alpha <= 0f || Build.VERSION.SDK_INT < 31) return this
    return drawWithCache {
        val d = density
        val sigma = shadow.sigma.toFloat() * d
        val pad = (sigma * 3).toInt() + 2
        val layer = obtainGraphicsLayer()
        layer.renderEffect = BlurEffect(sigma, sigma, TileMode.Decal)
        layer.colorFilter = ColorFilter.tint(color)
        val dx = shadow.x.toFloat() * d; val dy = shadow.y.toFloat() * d
        onDrawWithContent {
            // บันทึกใหญ่กว่าเนื้อหาด้านละ `pad` ไม่ให้ขอบเบลอถูกตัด
            layer.record(size = IntSize(size.width.toInt() + pad * 2, size.height.toInt() + pad * 2)) {
                translate(pad.toFloat(), pad.toFloat()) { this@onDrawWithContent.drawContent() }
            }
            translate(dx - pad, dy - pad) { drawLayer(layer) }
            drawContent()
        }
    }
}
