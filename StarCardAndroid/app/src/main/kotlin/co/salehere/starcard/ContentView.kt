package co.salehere.starcard

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import co.salehere.starcard.components.Motion
import co.salehere.starcard.model.AppRuntime
import co.salehere.starcard.model.CardFormat
import co.salehere.starcard.model.CardLibrary
import co.salehere.starcard.model.LabSync
import co.salehere.starcard.model.LocalClipInvocation
import co.salehere.starcard.model.LocalPhotoStore
import co.salehere.starcard.model.PhotoStore
import co.salehere.starcard.model.Profile
import co.salehere.starcard.model.StarDataKey
import co.salehere.starcard.model.StarFlow
import co.salehere.starcard.theme.CardTheme
import co.salehere.starcard.ui.CardGallery
import co.salehere.starcard.ui.CardScreen
import co.salehere.starcard.ui.TemplatePicker
import co.salehere.starcard.ui.profile.ProfileFlow
import co.salehere.starcard.ui.salehere.SaleHereShell
import co.salehere.starcard.ui.salehere.rememberShLast
import co.salehere.starcard.ui.salehere.shBlockTouches
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * รากของแอป — แอป Sale Here จำลอง (สองแท็บ) ครอบ Star Card ไว้ ตาม flow เดิมของแอปหลัก 22 ก.ย. 2569
 *
 * โปรไฟล์ → "โปรไฟล์ครีเอเตอร์" → Star Profile (flow ใหม่) → "แต่ง Star Card" → `StarCardSpace` (คลัง → ห้องแต่ง)
 * ลิงก์ที่เปิดแอป (`ClipInvocation`) รับไว้แล้วที่ `AppRoot` ใน MainActivity.kt
 */
@Composable
fun ContentView(modifier: Modifier = Modifier) {
    val photos = remember { PhotoStore() }
    val invocation = LocalClipInvocation.current
    LaunchedEffect(invocation) { invocation.consumeLaunchURL() }
    // โหมดลองทำ: ซิงก์การ์ดกลางกับ sync-server (ปิดโหมด = ไม่ทำอะไร)
    LaunchedEffect(photos) { LabSync.shared.start(photos) }

    CompositionLocalProvider(LocalPhotoStore provides photos) {
        Box(modifier.fillMaxSize()) {
            if (AppRuntime.isClip) {
                // คลิปเปิดการ์ดของคนอื่นจากลิงก์ — ไม่ผ่านคลังหรือหน้าเทมเพลตของเจ้าของเครื่อง
                CardScreen(viewOnly = true)
            } else {
                SaleHereShell()
            }
        }
    }
}

/**
 * เปิดพื้นที่ Star Card ที่ไหน — คลังการ์ดฝังอยู่ในหน้า Star Profile แล้ว
 * พื้นที่นี้จึงถูกเรียกเพื่อ "ทำอะไรกับใบหนึ่ง" เป็นหลัก
 *
 * `id` = ตัวตนของการเปิดครั้งนั้น ("gallery" / "edit-<ใบ>" / "create" / "preview-<ใบ>") · ใบที่เปิดอยู่ใน `cardID`
 */
sealed class StarCardIntent {
    abstract val id: String

    object Gallery : StarCardIntent() {
        override val id: String get() = "gallery"
        override fun toString(): String = id
    }

    class Edit(id: String) : StarCardIntent() {
        val cardID: String = id
        override val id: String = "edit-$id"
        override fun equals(other: Any?): Boolean = other is Edit && other.cardID == cardID
        override fun hashCode(): Int = id.hashCode()
        override fun toString(): String = id
    }

    object Create : StarCardIntent() {
        override val id: String get() = "create"
        override fun toString(): String = id
    }

    class Preview(id: String) : StarCardIntent() {
        val cardID: String = id
        override val id: String = "preview-$id"
        override fun equals(other: Any?): Boolean = other is Preview && other.cardID == cardID
        override fun hashCode(): Int = id.hashCode()
        override fun toString(): String = id
    }
}

/** ชั้นที่เห็นอยู่ในพื้นที่ Star Card — ใช้เป็นกุญแจของการจางสลับหน้า */
private sealed class SpacePane(val key: String) {
    object Entry : SpacePane("entry")
    class Edit(val cardID: String) : SpacePane("edit-$cardID") {
        override fun equals(other: Any?): Boolean = other is Edit && other.cardID == cardID
        override fun hashCode(): Int = key.hashCode()
    }
    object Picker : SpacePane("picker")
    object Gallery : SpacePane("gallery")
}

/**
 * พื้นที่ Star Card ทั้งชุด — คลังการ์ด / หน้าเทมเพลต / ห้องแต่ง / มุมมองแบรนด์
 *
 * @param onExit ปิดทั้งพื้นที่กลับไปแอป Sale Here จำลอง
 * @param onFocusTheme คลังโฟกัสใบไหน — shell เปลี่ยนสีดวงไฟตาม
 * @param onGalleryVisible คลังการ์ดกำลังเป็นหน้าที่เห็นอยู่ไหม — shell โชว์หัวร่วมเฉพาะตอนนั้น
 */
@Composable
fun StarCardSpace(
    intent: StarCardIntent = StarCardIntent.Gallery,
    onExit: () -> Unit,
    onFocusTheme: ((CardTheme) -> Unit)? = null,
    onGalleryVisible: ((Boolean) -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val flow = remember { StarFlow.shared }
    val library = CardLibrary.shared
    val scope = rememberCoroutineScope()
    val latestExit by rememberUpdatedState(onExit)
    val latestGalleryVisible by rememberUpdatedState(onGalleryVisible)
    val latestIntent by rememberUpdatedState(intent)

    /** hub "ข้อมูลของฉัน" เลิกเป็นประตูแล้ว (ผู้ใช้ 23 ก.ย. 2569: "หน้านี้ไม่ต้องมีแล้ว ใช้ Star Profile") — เข้าคลังทันที */
    var atEntry by remember { mutableStateOf(false) }
    /** การ์ดที่กำลังแต่งอยู่ — null = ยังอยู่ชั้นเลือก (คลัง/เทมเพลต) · เปิดมาแต่งใบเดียวจาก Star Profile = ตั้งไว้เลย */
    var editingCardID by remember { mutableStateOf((intent as? StarCardIntent.Edit)?.cardID) }
    /** ใบที่กำลังแต่งเพิ่งเกิดจากการแตะเทมเพลต — ออกโดยไม่แตะแก้อะไร = ทิ้งใบนั้น */
    var freshFromTemplate by remember { mutableStateOf(false) }
    /** เปิดหน้าเทมเพลตทับคลัง — จากปุ่ม + (คลังว่างไปหน้าเทมเพลตเองอยู่แล้ว) */
    var showPicker by remember { mutableStateOf(intent is StarCardIntent.Create) }
    /** แบบล่าสุดที่เลือกในหน้าเทมเพลต — จำไว้ให้สวิตช์เปิดค้างแบบเดิมรอบหน้า */
    var lastFormat by remember { mutableStateOf(CardFormat.portfolio) }
    /** ใบที่กำลังเปิดดู "แบบที่แบรนด์เห็น" ทับคลัง — null = ไม่ได้เปิด */
    var brandPreviewID by remember { mutableStateOf((intent as? StarCardIntent.Preview)?.cardID) }
    /** แตะการ์ดเข้าห้องแต่งไปแล้วในรอบนี้ — กลับมาคลังต้องเจอใบที่เพิ่งแก้ ไม่ใช่ใบที่กำลังแสดง */
    var editedHere by remember { mutableStateOf(false) }
    val openedAtGallery = intent is StarCardIntent.Gallery
    /** หน้า "ข้อมูลของฉัน" ทับทุกอย่าง */
    var showProfile by remember { mutableStateOf(false) }
    /** นับครั้งที่กลับเข้าคลังการ์ด — คลังเห็นค่านี้เปลี่ยนแล้วเล่นท่าเข้าฉากใหม่ */
    var galleryEntry by remember { mutableIntStateOf(0) }

    val galleryVisible = !atEntry && editingCardID == null && !showPicker && !library.isEmpty && brandPreviewID == null

    /**
     * การ์ดอ่านจาก `Profile.me.creator` — ถ้า Star Profile บอกว่ามีช่องทาง/เรทแล้ว แต่ข้อมูลการ์ดยังว่าง
     * widget ทุกใบจะขึ้น "ยังไม่ใส่ช่องทาง" ทั้งที่หน้าโปรไฟล์โชว์ยอดฟอลอยู่ (ผู้ใช้เจอ 23 ก.ย. 2569)
     */
    fun syncCardData() {
        val f = StarFlow.shared
        val c = Profile.me.creator
        val stale = (f.hasCard && !Profile.me.hasIntake) ||
            (f.has(StarDataKey.socials) && c.socials.isEmpty()) ||
            (f.has(StarDataKey.rate) && c.rates.isEmpty())
        if (stale) Profile.me.fillSample()
    }

    /** กลับเข้าคลังการ์ด — รอให้หน้าที่บังอยู่เลื่อนพ้นก่อน แล้วค่อยปลุกท่าเข้าฉากของคลัง */
    fun enterGallery() {
        showProfile = false
        editingCardID = null
        showPicker = false
        if (atEntry) atEntry = false
        scope.launch {
            delay(220)
            galleryEntry += 1
        }
    }

    LaunchedEffect(galleryVisible) { latestGalleryVisible?.invoke(galleryVisible) }
    // ตั้งฉากจาก Lab ระหว่างอยู่ในห้องแต่ง → เติมข้อมูลตัวอย่างให้การ์ดทันที (รอบแรก = `onAppear`)
    LaunchedEffect(flow.have) { syncCardData() }
    // ตู้ widget ขอไปดูงาน → ปิดพื้นที่การ์ดกลับแอปจำลอง (shell สลับแท็บให้)
    val jobs = flow.jobsRequested
    LaunchedEffect(jobs) { if (jobs) latestExit() }

    // ปุ่มย้อนของระบบ — ชั้นบนสุดของพื้นที่นี้ก่อน (ห้องแต่ง = ปุ่มกลับคลังของห้องแต่ง · หน้าเทมเพลต = `onBack` ของมัน)
    fun onSystemBack() {
        if (brandPreviewID != null) {
            brandPreviewID = null
        } else if (atEntry) {
            latestExit()
        } else if (editingCardID != null) {
            editingCardID = null
            showPicker = false
        } else if (showPicker || library.isEmpty) {
            if (library.isEmpty) latestExit() else showPicker = false
        } else {
            latestExit()
        }
    }
    BackHandler { onSystemBack() }

    val pane: SpacePane = when {
        atEntry -> SpacePane.Entry
        editingCardID != null -> SpacePane.Edit(editingCardID!!)
        showPicker || library.isEmpty -> SpacePane.Picker
        else -> SpacePane.Gallery
    }

    Box(modifier.fillMaxSize()) {
        AnimatedContent(
            targetState = pane,
            modifier = Modifier.fillMaxSize(),
            transitionSpec = { fadeIn(Motion.settle.spec()) togetherWith fadeOut(Motion.settle.spec()) using null },
            contentKey = { it.key },
            label = "starCardSpace",
        ) { p ->
            when (p) {
                // ประตูเข้า — hub ก่อน ปิดจากตรงนี้ = ออกจาก Star Card ทั้งชุด
                SpacePane.Entry -> ProfileFlow(onClose = onExit, onMyCards = { enterGallery() })
                is SpacePane.Edit -> {
                    // เปิดมาเพื่อแต่งใบเดียวจาก Star Profile — ออกจากห้องแต่ง = กลับไปหน้านั้นเลย ไม่แวะคลังซ้ำ
                    DisposableEffect(p.cardID) {
                        onDispose {
                            if (latestIntent is StarCardIntent.Edit && editingCardID == null) latestExit()
                        }
                    }
                    key(p.cardID) {
                        CardScreen(
                            cardID = p.cardID,
                            discardIfUntouched = freshFromTemplate,
                            onChangeFormat = {
                                editingCardID = null
                                showPicker = false
                            },
                        )
                    }
                }
                // คลังว่าง = ยังไม่มีอะไรให้ดู พาไปเริ่มจากเทมเพลตเลย (หน้านี้คือหน้าแรกของมือใหม่)
                SpacePane.Picker -> {
                    val backToGallery: () -> Unit = { showPicker = false }
                    TemplatePicker(
                        initialFormat = lastFormat,
                        onPick = { pickedFormat, picked ->
                            lastFormat = pickedFormat
                            val record = CardLibrary.shared.create(picked)
                            freshFromTemplate = true
                            editedHere = true
                            editingCardID = record.id
                        },
                        // คลังว่าง = ไม่มีคลังให้กลับ → ปิดกลับ Star Profile
                        onBack = if (CardLibrary.shared.isEmpty) onExit else backToGallery,
                    )
                }
                SpacePane.Gallery -> CardGallery(
                    onCreate = { showPicker = true },
                    onOpen = { record ->
                        freshFromTemplate = false
                        editedHere = true
                        editingCardID = record.id
                    },
                    onPreview = { record -> brandPreviewID = record.id },
                    // ป้าย "Star Profile" ในหัวคลัง = กลับหน้า Star Profile
                    onProfile = onExit,
                    entryToken = galleryEntry,
                    sharedStage = true,
                    onFocusTheme = onFocusTheme,
                    startAtLive = openedAtGallery && !editedHere,
                )
            }
        }

        // หน้าดูแบบที่แบรนด์เห็น — หน้าเดียวกับที่ลิงก์/คลิปเปิด แค่มีปุ่มปิดกลับคลัง (= fullScreenCover บนคลัง)
        AnimatedVisibility(
            visible = pane == SpacePane.Gallery && brandPreviewID != null,
            modifier = Modifier.fillMaxSize(),
            enter = slideInVertically(Motion.page.spec()) { it },
            exit = slideOutVertically(Motion.page.spec()) { it },
        ) {
            val id = rememberShLast(brandPreviewID)
            if (id != null) {
                Box(Modifier.fillMaxSize().background(Color.White).shBlockTouches()) {
                    BackHandler(enabled = brandPreviewID != null) { brandPreviewID = null }
                    key(id) {
                        CardScreen(viewOnly = true, cardID = id, onClose = { brandPreviewID = null })
                    }
                }
            }
        }
    }
}

/**
 * ท่าเข้า/ออกของหน้า Star Card ทับหน้าโปรไฟล์ (= `PageSlide`) — ไหลจากขวา 72pt พร้อมจางและขยายเข้าที่
 *
 * ระยะสั้นกับการจางทำให้ toggle สองตัวที่อยู่ตำแหน่งเดียวกันบนสองหน้าอ่านเป็น "ตัวเดียวกันเปลี่ยนสี"
 */
fun Modifier.pageSlide(progress: Float): Modifier = this.graphicsLayer {
    translationX = (1f - progress) * 72.dp.toPx()
    alpha = progress.coerceIn(0f, 1f)
    val s = 0.97f + 0.03f * progress
    scaleX = s
    scaleY = s
}
