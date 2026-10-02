package co.salehere.starcard.ui.profile

import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.Uri
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.MediaController
import android.widget.VideoView
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.autofill.ContentType
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.dropShadow
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Outline
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.painter.BitmapPainter
import androidx.compose.ui.graphics.shadow.Shadow
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.ClipInvocation
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.Portfolio
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.ProfileField
import co.salehere.starcard.model.TextSlotID
import co.salehere.starcard.model.decodeBitmap
import co.salehere.starcard.model.fitted
import co.salehere.starcard.theme.Ph
import co.salehere.starcard.theme.PhWeight
import co.salehere.starcard.theme.PIcon
import co.salehere.starcard.theme.SHFont
import co.salehere.starcard.theme.opacity
import co.salehere.starcard.theme.sh
import co.salehere.starcard.ui.Haptics
import co.salehere.starcard.ui.dockPress
import co.salehere.starcard.ui.pkRowPress
import co.salehere.starcard.ui.tap
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File
import java.util.Locale
import java.util.UUID
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

// MARK: - แก้ไขโปรไฟล์ (= ProfileEditor.swift)
//
// ช่องชุดเดียวกับหน้า "แก้ไขโปรไฟล์" ของแอป Sale Here เดิม — รูปโปรไฟล์ · ชื่อผู้ใช้ · ลิงก์โปรไฟล์ ·
// About Me · รูปโปรไฟล์ครีเอเตอร์ 3 ช่อง · รูปผลงาน · วิดีโอผลงาน
// ไม่อยู่ใน wizard — ลำดับขั้นของ wizard เป็นของทีม MKT และช่องพวกนี้ไม่มีในฟอร์มนั้น
// ทุกอย่างบันทึกทันที: ข้อความลง `Profile.me` · รูปวงกลมลง `PhotoStore` · ผลงานลง `Portfolio`

private sealed class Removal {
    data class Creator(val i: Int) : Removal()
    data class Work(val id: UUID) : Removal()
    data class Video(val id: UUID) : Removal()
}

private class SheetAction(val label: String, val destructive: Boolean = false, val run: () -> Unit)

@Composable
fun ProfileEditor(onClose: () -> Unit, modifier: Modifier = Modifier) {
    val photos = LocalPhotoStore.current
    val p = Profile.me
    val folio = Portfolio.shared
    val focus = rememberPKFocus()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    val hasCamera = remember { context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY) }
    val keyboardUp = keyboardVisible()

    var avatarMenu by remember { mutableStateOf(false) }
    /** ช่องที่กำลังโหลดรูปเข้า — "avatar" · "c0"…"c2" · "w<uuid>" — ขึ้นวงหมุนทับช่องนั้น */
    var busy by remember { mutableStateOf(setOf<String>()) }
    var importingWorks by remember { mutableIntStateOf(0) }
    /** ข้อความผิดพลาดล่างจอ — หายเองในไม่กี่วินาที */
    var toast by remember { mutableStateOf<String?>(null) }
    /** ช่องที่กำลังเลือกรูปให้ — ต้องแยกจากตัวเปิดตัวเลือก เพราะตัวเลือกปิดตัวเองก่อนรูปที่เลือกจะมาถึง */
    var creatorTarget by remember { mutableIntStateOf(0) }
    /** รูปผลงานที่กำลังเลือกรูปใหม่มาแทน */
    var workTarget by remember { mutableStateOf<UUID?>(null) }
    var importingVideos by remember { mutableIntStateOf(0) }
    var playing by remember { mutableStateOf<Portfolio.Video?>(null) }
    var pendingDelete by remember { mutableStateOf<Removal?>(null) }

    fun fail(message: String) {
        Haptics.impact(Haptics.Style.heavy)
        toast = message
    }

    fun load(uri: Uri?, key: String, done: (Bitmap) -> Unit) {
        if (uri == null) return
        busy = busy + key
        scope.launch {
            val img = decodeBitmap(uri)
            busy = busy - key
            if (img == null) {
                fail("โหลดรูปไม่สำเร็จ ลองเลือกใหม่อีกครั้ง")
                return@launch
            }
            done(img)
            Haptics.medium()
        }
    }

    fun addWorks(uris: List<Uri>) {
        val left = max(0, Portfolio.workMax - folio.works.size - importingWorks)
        val items = uris.take(left)
        if (items.isEmpty()) return
        importingWorks = items.size
        scope.launch {
            var failed = 0
            // ทีละรูป — ใบที่โหลดเสร็จขึ้นก่อน ไม่ต้องรอทั้งชุด
            for (u in items) {
                val img = decodeBitmap(u)
                if (img != null) folio.addWorks(listOf(img)) else failed += 1
                importingWorks -= 1
            }
            importingWorks = 0
            if (failed > 0) fail("โหลดรูปไม่สำเร็จ $failed รูป ลองเลือกใหม่อีกครั้ง") else Haptics.medium()
        }
    }

    fun addVideos(uris: List<Uri>) {
        val left = max(0, Portfolio.videoMax - folio.videos.size - importingVideos)
        val items = uris.take(left)
        if (items.isEmpty()) return
        importingVideos = items.size
        scope.launch {
            var tooBig = 0
            var failed = 0
            for (u in items) {
                when (folio.addVideo(u)) {
                    Portfolio.VideoResult.added -> Unit
                    Portfolio.VideoResult.tooBig -> tooBig += 1
                    Portfolio.VideoResult.failed -> failed += 1
                }
                importingVideos -= 1
            }
            importingVideos = 0
            if (tooBig > 0) fail("วิดีโอใหญ่เกิน ${Portfolio.videoMaxMB} MB — ตัดให้สั้นลงแล้วลองใหม่")
            else if (failed > 0) fail("โหลดวิดีโอไม่สำเร็จ ลองเลือกใหม่อีกครั้ง")
            else Haptics.medium()
        }
    }

    fun remove() {
        val r = pendingDelete ?: return
        Haptics.medium()
        when (r) {
            is Removal.Creator -> folio.clearCreator(at = r.i)
            is Removal.Work -> folio.removeWork(r.id)
            is Removal.Video -> folio.removeVideo(r.id)
        }
        pendingDelete = null
    }

    val imageOnly = PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
    val videoOnly = PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.VideoOnly)

    val avatarLibrary = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        load(uri, "avatar") { photos?.setProfile(it.fitted(1200f)) }
    }
    // กล้องของระบบ — ครอปจัตุรัสกลางภาพ เพราะรูปจากกล้องไม่ได้จัดเฟรมมาสำหรับวงกลม
    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { img ->
        if (img != null) {
            photos?.setProfile(squareCrop(img).fitted(1200f))
            Haptics.medium()
        }
    }
    val creatorPick = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        val i = creatorTarget
        load(uri, "c$i") { folio.setCreator(it, at = i) }
    }
    val workReplace = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        val id = workTarget ?: return@rememberLauncherForActivityResult
        load(uri, "w$id") { folio.replaceWork(id, with = it) }
    }
    val workOne = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri -> addWorks(listOfNotNull(uri)) }
    val workMany = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(Portfolio.workMax)) { uris -> addWorks(uris) }
    val videoOne = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri -> addVideos(listOfNotNull(uri)) }
    val videoMany = rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(Portfolio.videoMax)) { uris -> addVideos(uris) }

    LaunchedEffect(toast) {
        if (toast == null) return@LaunchedEffect
        delay(3000)
        toast = null
    }
    val lastToast = remember { arrayOf("") }
    toast?.let { lastToast[0] = it }
    val lastDelete = remember { arrayOfNulls<Removal>(1) }
    pendingDelete?.let { lastDelete[0] = it }
    val lastPlaying = remember { arrayOfNulls<Portfolio.Video>(1) }
    playing?.let { lastPlaying[0] = it }

    BackHandler(enabled = playing != null) { playing = null }

    Box(modifier.fillMaxSize()) {
        Column(Modifier.fillMaxSize().statusBarsPadding()) {
            PKHeader(title = "แก้ไขโปรไฟล์", leftSymbol = Ph.x, leftLabel = "ปิด", onLeft = onClose)
            Box(Modifier.weight(1f).fillMaxWidth().imePadding()) {
                Column(
                    Modifier
                        .fillMaxSize()
                        .verticalScroll(rememberScrollState())
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 60.dp),
                    verticalArrangement = Arrangement.spacedBy(14.dp),
                ) {
                    // MARK: รูปโปรไฟล์ — รูปเดียวกับบัตร STAR ในหน้าก่อน
                    Box(Modifier.fillMaxWidth().padding(top = 6.dp, bottom = 4.dp), contentAlignment = Alignment.Center) {
                        Box(
                            Modifier
                                .dockPress {
                                    Haptics.light()
                                    avatarMenu = true
                                }
                                .semantics { contentDescription = "เปลี่ยนรูปโปรไฟล์" },
                        ) {
                            Box(
                                Modifier
                                    .size(108.dp)
                                    .dropShadow(CircleShape, Shadow(radius = 14.dp, color = Color.Black.opacity(0.12), offset = DpOffset(0.dp, 6.dp)))
                                    .clip(CircleShape),
                            ) {
                                if (photos != null) photos.avatar(Modifier.matchParentSize())
                                else Box(Modifier.matchParentSize().background(PK.fieldFill))
                                if ("avatar" in busy) LoadingVeil(Modifier.matchParentSize())
                                Box(Modifier.matchParentSize().border(3.dp, Color.White, CircleShape))
                            }
                            Box(
                                Modifier
                                    .align(Alignment.BottomEnd)
                                    .offset(2.dp, 2.dp)
                                    .size(34.dp)
                                    .background(PK.ink, CircleShape)
                                    .border(2.5.dp, Color.White, CircleShape),
                                contentAlignment = Alignment.Center,
                            ) {
                                PIcon(Ph.camera, size = 16f, weight = PhWeight.fill, tint = PK.onInk)
                            }
                        }
                    }

                    // MARK: ข้อความ
                    PKPanel {
                        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                            val nameID = TextSlotID(ProfileField.personName)
                            PKField(
                                label = "ชื่อผู้ใช้", text = p.raw(nameID), onTextChange = { p.set(nameID, it) },
                                placeholder = "ชื่อที่แสดงบนการ์ด", contentType = ContentType.PersonFullName,
                                limit = ProfileField.personName.limit, id = "name", focus = focus,
                                onCommit = { p.commit(nameID) },
                            )
                            // ลิงก์ใช้ได้แค่ a–z 0–9 . _ — กรองตั้งแต่ตอนพิมพ์ ไม่ปล่อยให้พิมพ์ผิดแล้วค่อยด่า
                            val handleID = TextSlotID(ProfileField.handle)
                            PKField(
                                label = "ลิงก์โปรไฟล์", text = p.raw(handleID),
                                onTextChange = { v ->
                                    val clean = v.lowercase().filter { c -> c == '.' || c == '_' || (c.code < 128 && c.isLetterOrDigit()) }
                                    p.set(handleID, clean)
                                },
                                placeholder = "yourname", autocap = KeyboardCapitalization.None, noCorrect = true,
                                limit = ProfileField.handle.limit, leading = "${ClipInvocation.host}/star/",
                                id = "handle", focus = focus, onCommit = { p.commit(handleID) },
                            )
                            val aboutID = TextSlotID(ProfileField.about)
                            PKField(
                                label = "About Me", text = p.raw(aboutID), onTextChange = { p.set(aboutID, it) },
                                placeholder = "แนะนำตัวสั้น ๆ ให้แบรนด์รู้จัก", paragraph = true,
                                limit = ProfileField.about.limit, id = "about", focus = focus,
                                onCommit = { p.commit(aboutID) },
                            )
                        }
                    }

                    // MARK: รูปโปรไฟล์ครีเอเตอร์ — 3 ช่องคงที่
                    PKPanel(
                        title = "รูปโปรไฟล์ครีเอเตอร์",
                        trailing = { CountLabel(folio.creatorImages.size, Portfolio.creatorSlots) },
                    ) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            for (i in 0 until Portfolio.creatorSlots) {
                                val img = folio.creators.getOrNull(i)
                                Box(Modifier.weight(1f)) {
                                    if (img != null) {
                                        MediaTile(
                                            image = img, loading = "c$i" in busy,
                                            onTap = {
                                                creatorTarget = i
                                                creatorPick.launch(imageOnly)
                                            },
                                            onRemove = { pendingDelete = Removal.Creator(i) },
                                        )
                                    } else {
                                        Box(
                                            Modifier.dockPress {
                                                Haptics.light()
                                                creatorTarget = i
                                                creatorPick.launch(imageOnly)
                                            },
                                        ) {
                                            AddTile(label = "รูปที่ ${i + 1}")
                                            if ("c$i" in busy) LoadingVeil(Modifier.matchParentSize().clip(PK.shape(16f)))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // MARK: รูปผลงาน
                    val worksLeft = Portfolio.workMax - folio.works.size - importingWorks
                    PKPanel(title = "รูปผลงาน", trailing = { CountLabel(folio.works.size, Portfolio.workMax) }) {
                        val nW = folio.works.size
                        val nP = max(0, importingWorks)
                        Grid3(nW + nP + (if (worksLeft > 0) 1 else 0)) { i ->
                            when {
                                i < nW -> {
                                    val w = folio.works[i]
                                    key(w.id) {
                                        MediaTile(
                                            image = w.image, loading = "w${w.id}" in busy,
                                            onTap = {
                                                workTarget = w.id
                                                workReplace.launch(imageOnly)
                                            },
                                            onRemove = { pendingDelete = Removal.Work(w.id) },
                                        )
                                    }
                                }
                                i < nW + nP -> PendingTile()
                                else -> AddTile(
                                    label = "เพิ่มรูป",
                                    modifier = Modifier.dockPress {
                                        if (worksLeft <= 1) workOne.launch(imageOnly) else workMany.launch(imageOnly)
                                    },
                                )
                            }
                        }
                    }

                    // MARK: วิดีโอผลงาน
                    val videosLeft = Portfolio.videoMax - folio.videos.size - importingVideos
                    PKPanel(
                        title = "วิดีโอผลงาน",
                        subtitle = "ไฟล์ละไม่เกิน ${Portfolio.videoMaxMB} MB",
                        trailing = { CountLabel(folio.videos.size, Portfolio.videoMax) },
                    ) {
                        val nV = folio.videos.size
                        val nP = max(0, importingVideos)
                        Grid3(nV + nP + (if (videosLeft > 0) 1 else 0)) { i ->
                            when {
                                i < nV -> {
                                    val v = folio.videos[i]
                                    key(v.id) {
                                        MediaTile(
                                            image = v.thumb, duration = v.duration,
                                            onTap = { playing = v },
                                            onRemove = { pendingDelete = Removal.Video(v.id) },
                                        )
                                    }
                                }
                                i < nV + nP -> PendingTile()
                                else -> AddTile(
                                    label = "เพิ่มวิดีโอ",
                                    modifier = Modifier.dockPress {
                                        if (videosLeft <= 1) videoOne.launch(videoOnly) else videoMany.launch(videoOnly)
                                    },
                                )
                            }
                        }
                    }
                }
                // แป้นพิมพ์ไม่มีปุ่มปิดของตัวเองทุกแบบ — ให้ "เสร็จ" เหนือคีย์บอร์ด
                if (keyboardUp) PKKeyboardDone(onDone = { focus.clear() }, modifier = Modifier.align(Alignment.BottomCenter))
            }
        }

        // ข้อความผิดพลาดล่างจอ
        AnimatedVisibility(
            visible = toast != null,
            modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(bottom = 24.dp),
            enter = slideInVertically(Motion.settle.spec()) { it } + fadeIn(Motion.settle.spec()),
            exit = slideOutVertically(Motion.settle.spec()) { it } + fadeOut(Motion.settle.spec()),
        ) {
            Row(
                Modifier.background(PK.ink, CircleShape).padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                PIcon(Ph.warningCircle, size = 16f, weight = PhWeight.fill, tint = PK.red)
                Text(lastToast[0], style = sh(13.5f, SHFont.semibold), color = PK.onInk)
            }
        }

        // รูปโปรไฟล์: ถ่ายรูป / เลือกจากคลังรูป
        EditorSheet(
            visible = avatarMenu,
            title = null,
            actions = buildList {
                if (hasCamera) add(SheetAction("ถ่ายรูป") { camera.launch(null) })
                add(SheetAction("เลือกจากคลังรูป") { avatarLibrary.launch(imageOnly) })
            },
            onDismiss = { avatarMenu = false },
        )
        EditorSheet(
            visible = pendingDelete != null,
            title = if (lastDelete[0] is Removal.Video) "ลบวิดีโอนี้?" else "ลบรูปนี้?",
            actions = listOf(SheetAction("ลบ", destructive = true) { remove() }),
            onDismiss = { pendingDelete = null },
        )

        // เล่นวิดีโอผลงานเต็มจอ
        AnimatedVisibility(
            visible = playing != null,
            enter = slideInVertically(Motion.page.spec()) { it },
            exit = slideOutVertically(Motion.page.spec()) { it },
        ) {
            val v = lastPlaying[0]
            if (v != null) VideoSheet(url = v.file) { playing = null }
        }
    }
}

@Composable
private fun CountLabel(n: Int, max: Int) {
    Text("$n/$max", style = sh(12f, SHFont.bold).copy(fontFeatureSettings = "tnum"), color = PK.hint)
}

/** ตาราง 3 คอลัมน์ ช่องกว้างเท่ากัน — แถวสุดท้ายที่ไม่เต็มเว้นที่ว่างไว้ทางขวา */
@Composable
private fun Grid3(count: Int, cell: @Composable (Int) -> Unit) {
    Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        (0 until count).chunked(3).forEach { row ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                row.forEach { i -> Box(Modifier.weight(1f)) { cell(i) } }
                repeat(3 - row.size) { Spacer(Modifier.weight(1f)) }
            }
        }
    }
}

/** ชีตตัวเลือกล่างจอ (= `confirmationDialog`) — ปุ่ม "ยกเลิก" แยกก้อนเหมือน iOS */
@Composable
private fun EditorSheet(visible: Boolean, title: String?, actions: List<SheetAction>, onDismiss: () -> Unit) {
    BackHandler(enabled = visible, onBack = onDismiss)
    Box(Modifier.fillMaxSize()) {
        AnimatedVisibility(visible = visible, enter = fadeIn(Motion.snap.spec()), exit = fadeOut(Motion.snap.spec())) {
            Box(
                Modifier
                    .fillMaxSize()
                    .background(Color.Black.opacity(0.28))
                    .pointerInput(Unit) { detectTapGestures { onDismiss() } },
            )
        }
        AnimatedVisibility(
            visible = visible,
            modifier = Modifier.align(Alignment.BottomCenter),
            enter = slideInVertically(Motion.settle.spec()) { it },
            exit = slideOutVertically(Motion.settle.spec()) { it },
        ) {
            val shape = PK.shape(14f)
            Column(
                Modifier.fillMaxWidth().navigationBarsPadding().padding(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Column(Modifier.fillMaxWidth().clip(shape).background(Color.White.opacity(0.97))) {
                    if (title != null) {
                        Text(
                            title, style = sh(13f, SHFont.semibold), color = PK.muted, textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth().padding(14.dp),
                        )
                        Box(Modifier.fillMaxWidth().height(0.5.dp).background(PK.line))
                    }
                    actions.forEachIndexed { i, a ->
                        if (i > 0) Box(Modifier.fillMaxWidth().height(0.5.dp).background(PK.line))
                        Box(
                            Modifier.fillMaxWidth().height(56.dp).pkRowPress {
                                a.run()
                                onDismiss()
                            },
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                a.label, style = sh(17f, if (a.destructive) SHFont.semibold else SHFont.regular),
                                color = if (a.destructive) PK.red else PK.ink,
                            )
                        }
                    }
                }
                Box(
                    Modifier.fillMaxWidth().height(56.dp).clip(shape).background(Color.White).pkRowPress { onDismiss() },
                    contentAlignment = Alignment.Center,
                ) {
                    Text("ยกเลิก", style = sh(17f, SHFont.bold), color = PK.ink)
                }
            }
        }
    }
}

/** ครอปจัตุรัสกลางภาพ (= `allowsEditing` ของกล้อง iOS) */
private fun squareCrop(b: Bitmap): Bitmap {
    val side = min(b.width, b.height)
    if (side <= 0 || b.width == b.height) return b
    return Bitmap.createBitmap(b, (b.width - side) / 2, (b.height - side) / 2, side, side)
}

// MARK: - ช่องรูป/วิดีโอ

/**
 * รูปหนึ่งช่อง — แตะ = เปลี่ยน (วิดีโอ = เล่น) · ✕ มุมขวาบน = ลบ
 * `ratio` กว้าง/สูง — หน้าแก้ไขโปรไฟล์ 3:4 · wizard รูปและผลงานใช้จัตุรัสให้สามหมวดอยู่ในจอเดียว
 */
@Composable
fun MediaTile(
    image: Bitmap,
    duration: Double? = null,
    ratio: Float = 3f / 4f,
    loading: Boolean = false,
    modifier: Modifier = Modifier,
    onTap: () -> Unit,
    onRemove: () -> Unit,
) {
    val shape = PK.shape(16f)
    val painter = remember(image) { BitmapPainter(image.asImageBitmap()) }
    Box(modifier) {
        Box(
            Modifier
                .fillMaxWidth()
                .aspectRatio(ratio)
                .dockPress {
                    Haptics.light()
                    onTap()
                }
                .clip(shape)
                .border(1.dp, PK.line2, shape),
        ) {
            Image(painter, contentDescription = null, modifier = Modifier.fillMaxSize(), contentScale = ContentScale.Crop)
            if (duration != null) {
                Box(
                    Modifier
                        .align(Alignment.Center)
                        .size(38.dp)
                        .background(Color.Black.opacity(0.38), CircleShape)
                        .border(1.dp, Color.White.opacity(0.5), CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Box(Modifier.offset(x = 1.5.dp).size(13.dp, 15.dp).background(Color.White, PlayGlyph))
                }
                Text(
                    mediaClock(duration),
                    style = sh(11f, SHFont.bold).copy(fontFeatureSettings = "tnum"),
                    color = Color.White,
                    modifier = Modifier
                        .align(Alignment.BottomStart)
                        .padding(7.dp)
                        .background(Color.Black.opacity(0.45), CircleShape)
                        .padding(horizontal = 7.dp, vertical = 3.dp),
                )
            }
            if (loading) LoadingVeil(Modifier.matchParentSize())
        }
        Box(
            Modifier
                .align(Alignment.TopEnd)
                .size(40.dp)
                .tap(onClick = onRemove)
                .semantics { contentDescription = "ลบ" },
            contentAlignment = Alignment.Center,
        ) {
            Box(
                Modifier
                    .size(24.dp)
                    .background(Color.Black.opacity(0.55), CircleShape)
                    .border(1.dp, Color.White.opacity(0.7), CircleShape),
                contentAlignment = Alignment.Center,
            ) {
                PIcon(Ph.x, size = 11f, weight = PhWeight.bold, tint = Color.White)
            }
        }
    }
}

/** เวลาของคลิป m:ss (= `MediaTile.clock`) */
fun mediaClock(s: Double): String {
    val t = s.roundToInt()
    return String.format(Locale.US, "%d:%02d", t / 60, t % 60)
}

/** ช่องที่กำลังโหลดของเข้า — ขนาดเท่าช่องจริง ของใหม่จึงขึ้นตรงที่เดิม ไม่ดันกริด */
@Composable
fun PendingTile(ratio: Float = 3f / 4f, modifier: Modifier = Modifier) {
    Box(
        modifier.fillMaxWidth().aspectRatio(ratio).background(PK.fieldFill, PK.shape(16f)),
        contentAlignment = Alignment.Center,
    ) {
        PKSpinner(tint = PK.ink)
    }
}

/** ม่านหมุนทับรูปเดิมระหว่างโหลดรูปใหม่มาแทน */
@Composable
fun LoadingVeil(modifier: Modifier = Modifier) {
    Box(modifier.background(Color.White.opacity(0.55)), contentAlignment = Alignment.Center) {
        PKSpinner(tint = PK.ink)
    }
}

/** ช่องว่างสำหรับเพิ่ม — เส้นประ ไอคอนบวก ป้ายสั้น (ผู้เรียกใส่ปุ่มกดเอง เช่น `Modifier.dockPress`) */
@Composable
fun AddTile(label: String, ratio: Float = 3f / 4f, modifier: Modifier = Modifier) {
    Box(
        modifier
            .fillMaxWidth()
            .aspectRatio(ratio)
            .background(PK.fieldFill, PK.shape(16f))
            .pkDashedBorder(width = 1.2f, color = PK.line2, radius = 16f, dash = 5f, gap = 4f),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            PIcon(Ph.plus, size = 18f, weight = PhWeight.bold, tint = PK.ink.opacity(0.7))
            Text(label, style = sh(11.5f, SHFont.semibold), color = PK.muted, maxLines = 1)
        }
    }
}

/** สามเหลี่ยมเล่น — ชุด Phosphor ในแอปไม่มี `play` และหน้าเดียวไม่คุ้มเพิ่มไอคอนสามน้ำหนัก */
object PlayGlyph : Shape {
    override fun createOutline(size: Size, layoutDirection: LayoutDirection, density: Density): Outline {
        val path = Path().apply {
            moveTo(0f, 0f)
            lineTo(size.width, size.height / 2)
            lineTo(0f, size.height)
            close()
        }
        return Outline.Generic(path)
    }
}

/** เล่นวิดีโอผลงานเต็มจอ — `VideoView` ของระบบ (ไม่มี AVPlayer) พร้อมแถบควบคุมของระบบ */
@Composable
fun VideoSheet(url: String, modifier: Modifier = Modifier, onClose: () -> Unit) {
    Box(modifier.fillMaxSize().background(Color.Black)) {
        AndroidView(
            factory = { ctx ->
                FrameLayout(ctx).apply {
                    val video = VideoView(ctx)
                    addView(
                        video,
                        FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.CENTER),
                    )
                    val controls = MediaController(ctx)
                    controls.setAnchorView(video)
                    video.setMediaController(controls)
                    video.setOnPreparedListener { video.start() }
                    video.setVideoPath(url)
                }
            },
            modifier = Modifier.fillMaxSize(),
            onRelease = { frame -> (frame.getChildAt(0) as? VideoView)?.stopPlayback() },
        )
        PKCircleButton(
            symbol = Ph.x, label = "ปิด",
            modifier = Modifier.statusBarsPadding().padding(start = 20.dp, top = 6.dp),
            action = onClose,
        )
    }
}

/** ไฟล์วิดีโอในที่เก็บ (`Portfolio.Video.file`) */
@Composable
fun VideoSheet(url: File, modifier: Modifier = Modifier, onClose: () -> Unit) {
    VideoSheet(url = url.absolutePath, modifier = modifier, onClose = onClose)
}
