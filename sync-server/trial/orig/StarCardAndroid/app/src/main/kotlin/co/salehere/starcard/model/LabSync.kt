package co.salehere.starcard.model

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import co.salehere.starcard.AppContext
import co.salehere.starcard.theme.BackdropStyle
import java.io.ByteArrayOutputStream
import java.io.File
import java.lang.ref.WeakReference
import java.net.HttpURLConnection
import java.net.URL
import java.util.IdentityHashMap
import java.util.UUID
import kotlin.coroutines.cancellation.CancellationException
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.system.exitProcess
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

// MARK: - โหมดลองทำ — การ์ดกลางบน sync-server (= Model/LabSync.swift)
//
// ทดสอบว่า "การ์ดเป็น JSON ก้อนเดียว" ใช้ได้จริงข้ามแพลตฟอร์มไหม: iOS กับ Android แก้การ์ดใบเดียวกัน
// ผ่านที่เก็บกลาง (`sync-server/`) แล้วดูว่าค่าที่อีกฝั่งเขียน พอเครื่องนี้อ่านแล้วเขียนกลับ **ค่าเปลี่ยนไหม**
// สัญญาเต็ม (รูปร่าง JSON · API · ขั้นตอน) อยู่ที่ `sync-server/README.md`
//
// เปิดโหมดครั้งแรก = สำรอง SharedPreferences + filesDir ทั้งหมดไว้ก่อน (`LabMode.bootstrap`)
// ปิดโหมดเมื่อไหร่ของเดิมถูกคืนกลับทั้งก้อน — การสลับจึงมีผลตอนเปิดแอปครั้งถัดไปเท่านั้น

object LabMode {
    /** ตัดสินครั้งเดียวตอนเปิดแอป — ระหว่างรันเปลี่ยนไม่ได้ (ดูหัวไฟล์) */
    var isOn = false
        private set

    /** Android Emulator มองเห็น Mac ที่ 10.0.2.2 (iOS Simulator ใช้ 127.0.0.1) */
    const val defaultServer = "http://10.0.2.2:8787"

    @Serializable
    private data class Flag(val enabled: Boolean = false, val server: String? = null)

    private val flagJson = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    /** ธงอยู่นอกทุกอย่างที่ถูกสำรอง (`no_backup/`) — ไม่งั้นการคืนข้อมูลจะเขียนทับธงของตัวเอง */
    private val support: File get() = AppContext.app.noBackupFilesDir
    private val flagFile: File get() = File(support, "lab-mode.json")
    val stateFile: File get() = File(support, "lab-state.json")
    private val backupDir: File get() = File(support, "lab-backup")
    /** SharedPreferences ทุกไฟล์ของแอป (= UserDefaults ทั้ง domain) */
    private val prefsDir: File get() = File(AppContext.app.applicationInfo.dataDir, "shared_prefs")
    private val filesDir: File get() = AppContext.filesDir

    private var booted = false

    private fun readFlag(): Flag =
        runCatching { flagJson.decodeFromString(Flag.serializer(), flagFile.readText()) }.getOrNull() ?: Flag()

    private fun writeFlag(f: Flag) {
        runCatching { atomicWrite(flagFile, flagJson.encodeToString(Flag.serializer(), f).toByteArray()) }
    }

    val server: String get() = readFlag().server ?: defaultServer

    /** ค่าจาก intent extra `labSync` — "on"/"off" (รับ 1/YES/true/on แบบเดียวกับ launch argument ของ iOS) */
    private fun parse(v: String): Boolean = v.lowercase() in setOf("1", "yes", "true", "on")

    /**
     * เรียกก่อนสโตร์ใด ๆ โหลดดิสก์ — `MainActivity.onCreate` ก่อน `setContent`
     *
     * intent extra `labSync on|off` ตั้งธงได้ตรง ๆ (ไว้ทดสอบอัตโนมัติ) · `labServer URL` เปลี่ยนที่อยู่
     * รอบที่สองในโปรเซสเดียวกันและขอโหมดต่างจากที่รันอยู่ = เขียนธงแล้วปิดแอป (ต้องสำรอง/คืนก่อนสโตร์อ่านดิสก์)
     */
    fun bootstrap(labSync: String? = null, labServer: String? = null) {
        if (booted) {
            val want = labSync?.let { parse(it) }
            if (labServer != null) writeFlag(readFlag().copy(server = labServer))
            if (want != null && want != isOn) request(want)
            return
        }
        booted = true
        var flag = readFlag()
        if (labSync != null) flag = flag.copy(enabled = parse(labSync))
        if (labServer != null) flag = flag.copy(server = labServer)
        writeFlag(flag)

        val hasBackup = backupDir.exists()
        if (flag.enabled && !hasBackup) makeBackup()
        if (!flag.enabled && hasBackup) {
            restoreBackup()
            stateFile.delete()
        }
        isOn = flag.enabled
    }

    /** สั่งเปิด/ปิดจากแผง Lab — แอปปิดตัวเอง แล้วโหมดใหม่มีผลตอนเปิดครั้งถัดไป */
    fun request(on: Boolean) {
        writeFlag(readFlag().copy(enabled = on))
        // รอให้สโตร์ที่หน่วงการเขียนไว้ (manifest รูป 0.4 วิ · ข้อความ · SharedPreferences.apply) ลงดิสก์ก่อน
        Handler(Looper.getMainLooper()).postDelayed({ exitProcess(0) }, 1000)
    }

    private fun makeBackup() {
        // สำเนาลงที่พักก่อนแล้วค่อยเปลี่ยนชื่อ — สำรองค้างครึ่งทางต้องไม่ถูกนับว่าเป็น backup
        val tmp = File(support, "lab-backup.tmp")
        tmp.deleteRecursively()
        tmp.mkdirs()
        val prefs = File(tmp, "shared_prefs").apply { mkdirs() }
        if (prefsDir.exists()) prefsDir.copyRecursively(prefs, overwrite = true)
        val files = File(tmp, "files").apply { mkdirs() }
        if (filesDir.exists()) filesDir.copyRecursively(files, overwrite = true)
        if (!tmp.renameTo(backupDir)) {
            tmp.copyRecursively(backupDir, overwrite = true)
            tmp.deleteRecursively()
        }
    }

    private fun restoreBackup() {
        val savedPrefs = File(backupDir, "shared_prefs")
        if (savedPrefs.exists()) {
            prefsDir.listFiles()?.forEach { it.deleteRecursively() }
            prefsDir.mkdirs()
            savedPrefs.listFiles()?.forEach { moveInto(it, prefsDir) }
        }
        val savedFiles = File(backupDir, "files")
        if (savedFiles.exists()) {
            filesDir.listFiles()?.forEach { it.deleteRecursively() }
            savedFiles.listFiles()?.forEach { moveInto(it, filesDir) }
        }
        backupDir.deleteRecursively()
    }

    private fun moveInto(f: File, dir: File) {
        val to = File(dir, f.name)
        if (!f.renameTo(to)) f.copyRecursively(to, overwrite = true)
    }

    internal fun atomicWrite(file: File, bytes: ByteArray) {
        file.parentFile?.mkdirs()
        val tmp = File(file.path + ".tmp")
        tmp.writeBytes(bytes)
        if (!tmp.renameTo(file)) {
            file.writeBytes(bytes)
            tmp.delete()
        }
    }
}

// MARK: - JSON ของการ์ด (= api/star-card/example-doc.json)

/**
 * `pages`/`theme` คือ `CardSnapshot` ตามที่แอปเขียนอยู่แล้ว · encode ด้วย `CardStore.json` ตัวเดียวกับที่คลังใช้
 * อีกฝั่งอาจไม่ส่ง photos/notes มาเลย — ขาดสองก้อนนี้ต้องไม่ทำให้ทั้งการ์ดอ่านไม่ได้
 */
@Serializable
data class LabDoc(
    val schemaVersion: Int = 1,
    val format: String = CardFormat.portfolio.raw,
    val name: String = "",
    val theme: CardSnapshot.Theme,
    val pages: List<CardSnapshot.Page>,
    val photos: Map<String, Photo> = emptyMap(),
    val notes: Map<String, String> = emptyMap(),
    val backgroundImageId: String? = null,
    val owner: Owner? = null,
) {
    @Serializable
    data class Fit(val dx: Double, val dy: Double, val zoom: Double)

    /**
     * ข้อมูลเจ้าของการ์ด — ข้อความส่วนใหญ่บนการ์ด (ชื่อ แนะนำตัว เรต…) และรูปในช่องที่ไม่ได้ใส่รูปเอง
     * โหมดลองทำคือ "คนเดียวกันสองเครื่อง" จึงต้องส่งไปด้วย ไม่งั้นสองเครื่องโชว์คนละชื่อคนละรูป
     * `intake` เก็บเป็น JSON ดิบในก้อนนี้ แล้วแปลงผ่าน `IntakeData` จริงตอนใช้/ตอนสร้าง — อ่านไม่ผ่านต้องไม่ทำให้ทั้งการ์ดอ่านไม่ได้
     */
    @Serializable
    data class Owner(
        /** `Profile` — ค่าที่พิมพ์เอง (คีย์ = ProfileField.raw) · รายการชิป · ข้อมูลฟอร์ม */
        val values: Map<String, String> = emptyMap(),
        val list: Map<String, List<String>> = emptyMap(),
        val intake: JsonElement? = null,
        /** รูปโปรไฟล์ (`PhotoStore.profile`) */
        val avatarImageId: String? = null,
        /** รูปครีเอเตอร์ 3 ช่อง (`Portfolio.creators`) — null = ช่องว่าง */
        val creatorImageIds: List<String?> = emptyList(),
        /** รูปผลงาน (`Portfolio.works`) และคลังรูป (`PhotoStore.uploaded`) ตามลำดับ */
        val workImageIds: List<String> = emptyList(),
        val libraryImageIds: List<String> = emptyList(),
    )

    @Serializable
    data class Photo(val imageId: String? = null, val fit: Fit? = null)

    companion object {
        /** คีย์ของช่องรูป `"<UUID>#<slot>"` → (widget, slot) */
        fun slotKey(key: String): Pair<UUID, Int>? {
            val parts = key.split("#", limit = 2)
            if (parts.size != 2) return null
            val id = runCatching { UUID.fromString(parts[0]) }.getOrNull() ?: return null
            val s = parts[1].toIntOrNull() ?: return null
            return id to s
        }
    }
}

// MARK: - ตัวซิงก์

class LabSync private constructor() {
    companion object {
        val shared: LabSync by lazy { LabSync() }

        private const val platform = "android"
        private val device: String get() = Build.MODEL ?: "android"
    }

    sealed class Phase {
        object idle : Phase()
        object connecting : Phase()
        object synced : Phase()
        object pushing : Phase()
        data class offline(val why: String) : Phase()
    }

    var phase: Phase by mutableStateOf(Phase.idle)
        private set
    var rev by mutableIntStateOf(0)
        private set
    /** ผลตรวจล่าสุดของเครื่องนี้ — รับ rev ของอีกฝั่งมาแล้วเขียนกลับ ค่าเพี้ยนกี่จุด · null = ยังไม่เคยรับ */
    var lastEcho: Int? by mutableStateOf(null)
        private set
    /** เพิ่มทุกครั้งที่รับการ์ดจากเครื่องอื่นมาใช้ — ห้องแต่งที่เปิดใบนี้อยู่ดูค่านี้แล้วโหลดใหม่ */
    var remoteStamp by mutableIntStateOf(0)
        private set
    /** ใบในคลังที่เป็นการ์ดกลาง */
    var cardID: String? by mutableStateOf(null)
        private set

    private var photosRef: WeakReference<PhotoStore>? = null
    private val photos: PhotoStore? get() = photosRef?.get()
    /** doc ที่ซิงก์ล่าสุด (ตามที่เครื่องนี้ encode · คีย์เรียง) — ต่างจากนี้เมื่อไหร่ = ผู้ใช้แก้ ต้องส่ง */
    private var lastJSON: String? = null
    /** รูปที่รู้ id แล้ว — จับด้วยตัวอ็อบเจกต์ (= ObjectIdentifier) และถือรูปไว้ กัน id ถูกใช้ซ้ำ */
    private val known = IdentityHashMap<Bitmap, String>()
    /** "<uuid>#<slot>" / "bg" → imageId — จำข้ามการเปิดแอป (รูปที่โหลดจากดิสก์เป็นอ็อบเจกต์ใหม่ทุกครั้ง) */
    private val slotIDs = mutableMapOf<String, String>()
    private var loop: Job? = null
    private var busy = false
    private val server: String = LabMode.server.trimEnd('/')
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    private class LabError(message: String) : Exception(message)

    // MARK: เริ่ม

    fun start(photos: PhotoStore) {
        if (!LabMode.isOn || loop != null) return
        photosRef = WeakReference(photos)
        loadState()
        loop = scope.launch {
            while (isActive) {
                tick()
                delay(1000)
            }
        }
    }

    private suspend fun tick() {
        if (busy) return
        busy = true
        try {
            if (phase == Phase.idle || phase == Phase.connecting) {
                connect(); return
            }
            cardID?.let { id -> if (CardLibrary.shared.card(id) == null) { cardID = null; rev = 0; lastJSON = null } }
            if (cardID == null) {
                connect(); return
            }

            // ดึงก่อนส่ง — มี rev ใหม่ระหว่างที่เครื่องนี้ก็แก้อยู่ = ชนกัน ของที่ server ชนะ
            val remote = fetch(known = rev)
            if (remote != null && remote.rev != rev) {
                receive(remote)
                return
            }
            val record = cardID?.let { CardLibrary.shared.card(it) } ?: return
            val doc = build(record)
            val json = encode(doc)
            if (json != lastJSON) push(doc, json)
            phase = Phase.synced
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            phase = Phase.offline(e.message ?: e.javaClass.simpleName)
        } finally {
            busy = false
        }
    }

    /** เปิดครั้งแรก: server ว่าง = ใบหลักของเครื่องนี้เป็นการ์ดกลาง · มีแล้ว = รับมาใช้ */
    private suspend fun connect() {
        phase = Phase.connecting
        val remote = fetch(known = null) ?: return
        val id = cardID
        if (remote.doc == null) {
            val first = CardLibrary.shared.displayOrder.firstOrNull() ?: return   // ยังไม่มีการ์ด — รอบหน้าลองใหม่
            CardLibrary.shared.labKeepOnly(first.id)
            cardID = first.id
            rev = 0
            val doc = build(first)
            push(doc, encode(doc))
        } else if (remote.rev == rev && id != null && CardLibrary.shared.card(id) != null && knowsAll(remote.doc)) {
            CardLibrary.shared.labKeepOnly(id)   // เปิดแอปใหม่ในโหมดเดิม — rev เท่าเดิม ไม่ต้องโหลดซ้ำ
        } else {
            receive(remote)
        }
        phase = Phase.synced
    }

    /**
     * rev เท่าเดิมแต่ doc มีก้อนที่รอบก่อนไม่รู้จัก (เช่น `owner` ที่เพิ่มทีหลัง) = รอบก่อนยังไม่ได้ใช้ก้อนนั้น
     * ต้องรับมาใช้ใหม่ ไม่งั้นรอบถัดไปจะส่งของในเครื่องขึ้นไปทับของอีกเครื่อง (ต่างจาก iOS — ดูรายงาน)
     */
    private fun knowsAll(doc: LabDoc): Boolean {
        val last = lastJSON?.let { runCatching { CardStore.json.parseToJsonElement(it).jsonObject }.getOrNull() } ?: return false
        val incoming = CardStore.json.encodeToJsonElement(LabDoc.serializer(), doc).jsonObject
        return incoming.keys.all { it in last }
    }

    // MARK: ส่ง

    private suspend fun push(doc: LabDoc, json: String) {
        phase = Phase.pushing
        val body = buildJsonObject {
            put("baseRev", rev)
            put("doc", CardStore.json.encodeToJsonElement(LabDoc.serializer(), doc))
            put("platform", platform)
            put("device", device)
        }
        val res = http("PUT", "api/card", body.toString().toByteArray(), "application/json")
        when (res.code) {
            200 -> {
                rev = CardStore.json.parseToJsonElement(res.text).jsonObject.getValue("rev").jsonPrimitive.int
                lastJSON = json
                saveState()
            }
            // อีกเครื่องเขียนก่อน — รับฉบับของเขามาใช้ (งานแก้ล่าสุดของเครื่องนี้ถูกทิ้ง)
            409 -> receive(CardStore.json.decodeFromString(Remote.serializer(), res.text))
            else -> throw LabError("server ตอบ ${res.code}")
        }
    }

    // MARK: รับ

    @Serializable
    private data class Remote(val rev: Int, val doc: LabDoc? = null, val by: By? = null) {
        @Serializable
        data class By(val platform: String? = null, val device: String? = null)
    }

    private suspend fun fetch(known: Int?): Remote? {
        val path = if (known != null) "api/card?known=$known" else "api/card"
        val res = http("GET", path)
        if (res.code == 204) return null
        if (res.code != 200) throw LabError("server ตอบ ${res.code}")
        return CardStore.json.decodeFromString(Remote.serializer(), res.text)
    }

    private suspend fun receive(remote: Remote) {
        val doc = remote.doc
        if (doc == null) {
            // server ถูกล้าง — รอบหน้าเครื่องนี้ส่งการ์ดของตัวเองขึ้นไปเป็นใบตั้งต้น
            rev = 0
            lastJSON = null
            return
        }
        apply(doc)
        rev = remote.rev
        val record = cardID?.let { CardLibrary.shared.card(it) } ?: return
        // echo = สิ่งที่เครื่องนี้จะเขียน ถ้าให้เขียนตอนนี้ — server เทียบกับ doc ของ rev นั้น
        val mine = build(record)
        lastJSON = encode(mine)
        saveState()
        lastEcho = echo(mine, remote.rev)
    }

    /** ใช้ doc จากเครื่องอื่นกับการ์ดในเครื่องนี้ — รูปที่ยังไม่มีโหลดมาก่อน */
    private suspend fun apply(doc: LabDoc) {
        val photos = photos ?: return
        // การ์ดต้องผ่านโมเดลจริงไปกลับหนึ่งรอบ — ค่าที่แอปทิ้ง/ปัดระหว่างโหลดจะได้โผล่ใน echo
        val raw = CardSnapshot(pages = doc.pages, theme = doc.theme, index = 0)
        val snap = CardStore.restore(raw)?.let { CardStore.snapshot(it.pages, it.theme, 0) } ?: raw
        cardID = CardLibrary.shared.labUpsert(
            id = cardID, name = doc.name,
            format = CardFormat.from(doc.format) ?: CardFormat.portfolio,
            snapshot = snap,
        )
        val widgets = snap.pages.flatMap { it.items }.mapNotNull { it.id?.let(::uuidOrNull) }.toSet()

        // รูปในช่อง + การจัดกรอบ
        for ((key, p) in doc.photos) {
            val (wid, slot) = LabDoc.slotKey(key) ?: continue
            val mine = "$wid#$slot"
            val imageID = p.imageId
            if (imageID != null && (slotIDs[mine] != imageID || !photos.has(slot, wid))) {
                val img = download(imageID)
                photos.set(listOf(img), from = slot, order = listOf(slot), id = wid)
                remember(img, imageID, mine)
            }
            val f = p.fit
            if (f != null) {
                photos.setFit(PhotoFit(dx = f.dx.toFloat(), dy = f.dy.toFloat(), zoom = f.zoom.toFloat()), slot, wid)
            } else {
                photos.resetFit(slot, wid)
            }
        }
        // ช่องที่อีกฝั่งไม่มีแล้ว — คืนเป็นรูประบบ/กรอบตั้งต้น
        val incoming = doc.photos.keys.mapNotNull { LabDoc.slotKey(it) }.map { "${it.first}#${it.second}" }.toSet()
        val withImage = doc.photos.mapNotNull { (k, v) ->
            if (v.imageId == null) null else LabDoc.slotKey(k)?.let { "${it.first}#${it.second}" }
        }.toSet()
        for (wid in widgets) {
            for (slot in (photos.perWidget[wid] ?: emptyMap()).keys.toList()) {
                if ("$wid#$slot" in withImage) continue
                photos.clear(slot, wid)
                slotIDs.remove("$wid#$slot")
            }
            for (slot in (photos.fits[wid] ?: emptyMap()).keys.toList()) {
                if ("$wid#$slot" !in incoming) photos.resetFit(slot, wid)
            }
        }
        // พื้นหลัง
        val bg = doc.backgroundImageId
        if (bg != null && (slotIDs["bg"] != bg || photos.background == null)) {
            val img = download(bg)
            photos.setBackground(img)
            remember(img, bg, "bg")
        }
        Profile.me.applyLabNotes(doc.notes, widgets)
        doc.owner?.let { applyOwner(it, photos) }
        remoteStamp += 1
    }

    /**
     * ข้อความและรูปของเจ้าของการ์ด — ทุกรูปอ่านกลับจากสโตร์หลังใส่ (บางสโตร์ย่อรูปเป็นอ็อบเจกต์ใหม่)
     * ไม่งั้นรอบถัดไปจะไม่รู้จักรูปนั้นแล้วอัปขึ้นไปซ้ำเป็นรูปใหม่
     */
    private suspend fun applyOwner(o: LabDoc.Owner, photos: PhotoStore) {
        // ฟอร์มที่โมเดลของเครื่องนี้อ่านไม่ออก = ไม่มีฟอร์ม (echo จะขึ้นว่า owner.intake หาย) — ไม่ใช่ทั้งการ์ดหยุดซิงก์
        val intake = o.intake?.takeIf { it !is JsonNull }?.let { raw ->
            runCatching { CardStore.json.decodeFromJsonElement(IntakeData.serializer(), raw) }
                .onFailure { Log.w("LabSync", "owner.intake อ่านไม่ได้: ${it.message}") }
                .getOrNull()
        }
        Profile.me.applyLabOwner(values = o.values, list = o.list, intake = intake)

        val avatar = o.avatarImageId
        if (avatar != null) {
            if (slotIDs["avatar"] != avatar || photos.profile == null) {
                photos.setProfile(download(avatar))
                photos.profile?.let { remember(it, avatar, "avatar") }
            }
        } else if (photos.profile != null) {
            photos.clearProfile()
            slotIDs.remove("avatar")
        }

        val folio = Portfolio.shared
        for (i in 0 until Portfolio.creatorSlots) {
            val key = "creator#$i"
            val want = o.creatorImageIds.getOrNull(i)
            if (want != null) {
                if (slotIDs[key] != want || folio.creators[i] == null) {
                    folio.setCreator(download(want), at = i)
                    folio.creators[i]?.let { remember(it, want, key) }
                }
            } else if (folio.creators[i] != null) {
                folio.clearCreator(at = i)
                slotIDs.remove(key)
            }
        }

        // รายการ — ลำดับเปลี่ยนหรือของไม่ตรง = ล้างแล้วใส่ใหม่ทั้งชุด (ง่ายกว่าไล่แก้ทีละตัว และรายการสั้น)
        if (folio.works.map { known[it.image] } != o.workImageIds) {
            val imgs = o.workImageIds.map { download(it) }
            folio.works.map { it.id }.forEach { folio.removeWork(it) }
            folio.addWorks(imgs)
            folio.works.forEachIndexed { i, w -> o.workImageIds.getOrNull(i)?.let { remember(w.image, it, "work#$i") } }
        }
        if (photos.uploaded.map { known[it] } != o.libraryImageIds) {
            val imgs = o.libraryImageIds.map { download(it) }
            photos.clear()
            photos.add(imgs)
            photos.uploaded.forEachIndexed { i, img -> o.libraryImageIds.getOrNull(i)?.let { remember(img, it, "lib#$i") } }
        }
    }

    // MARK: สร้าง doc จากสถานะในเครื่อง

    private suspend fun build(record: CardRecord): LabDoc {
        val snap = record.snapshot
        val widgets = snap.pages.flatMap { it.items }.mapNotNull { it.id?.let(::uuidOrNull) }
        val out = LinkedHashMap<String, LabDoc.Photo>()
        photos?.let { ph ->
            for (wid in widgets) {
                val own = ph.perWidget[wid] ?: emptyMap()
                val fits = ph.fits[wid] ?: emptyMap()
                for (slot in (own.keys + fits.keys).toSortedSet()) {
                    val key = "$wid#$slot"
                    val imageId = own[slot]?.let { imageID(it, key) }
                    val f = fits[slot]
                    val fit = if (f != null && !f.isIdentity) LabDoc.Fit(f.dx.toDouble(), f.dy.toDouble(), f.zoom.toDouble()) else null
                    if (imageId != null || fit != null) out[key] = LabDoc.Photo(imageId = imageId, fit = fit)
                }
            }
        }
        var bg: String? = null
        if (snap.theme.backdrop == BackdropStyle.photo.raw) {
            photos?.background?.let { bg = imageID(it, "bg") }
        }
        return LabDoc(
            format = record.formatRaw, name = record.name, theme = snap.theme, pages = snap.pages,
            photos = out, notes = Profile.me.labNotes(widgets.toSet()), backgroundImageId = bg,
            owner = buildOwner(),
        )
    }

    private suspend fun buildOwner(): LabDoc.Owner {
        val text = Profile.me.labOwner()
        val avatar = photos?.profile?.let { imageID(it, "avatar") }
        val folio = Portfolio.shared
        val creators = folio.creators.mapIndexed { i, img -> img?.let { imageID(it, "creator#$i") } }
        val works = folio.works.mapIndexed { i, w -> imageID(w.image, "work#$i") }
        val library = (photos?.uploaded ?: emptyList()).mapIndexed { i, img -> imageID(img, "lib#$i") }
        return LabDoc.Owner(
            values = text.values, list = text.list,
            intake = text.intake?.let { CardStore.json.encodeToJsonElement(IntakeData.serializer(), it) },
            avatarImageId = avatar, creatorImageIds = creators, workImageIds = works, libraryImageIds = library,
        )
    }

    /** เทียบ "แก้แล้วหรือยัง" ด้วยสตริงที่เรียงคีย์แล้ว (= `.sortedKeys` ของ iOS) — ลำดับใน map ไม่ทำให้ส่งซ้ำ */
    private fun encode(doc: LabDoc): String = sorted(CardStore.json.encodeToJsonElement(LabDoc.serializer(), doc)).toString()

    private fun sorted(e: JsonElement): JsonElement = when (e) {
        is JsonObject -> JsonObject(e.toSortedMap().mapValues { sorted(it.value) })
        is JsonArray -> JsonArray(e.map { sorted(it) })
        else -> e
    }

    private fun uuidOrNull(s: String): UUID? = runCatching { UUID.fromString(s) }.getOrNull()

    // MARK: รูป

    private fun remember(img: Bitmap, id: String, slot: String) {
        known[img] = id
        slotIDs[slot] = id
    }

    private suspend fun imageID(img: Bitmap, slot: String): String {
        known[img]?.let { slotIDs[slot] = it; return it }
        val (data, type) = withContext(Dispatchers.Default) { uploadData(img) }
        val res = http("POST", "api/images", data, type)
        if (res.code != 200) throw LabError("server ตอบ ${res.code}")
        val id = CardStore.json.parseToJsonElement(res.text).jsonObject.getValue("imageId").jsonPrimitive.content
        remember(img, id, slot)
        return id
    }

    private suspend fun download(id: String): Bitmap {
        val res = http("GET", "api/images/$id")
        if (res.code != 200) throw LabError("server ตอบ ${res.code}")
        return withContext(Dispatchers.Default) { BitmapFactory.decodeByteArray(res.body, 0, res.body.size) }
            ?: throw LabError("อ่านรูปไม่ได้")
    }

    /** ย่อด้านยาวไม่เกิน 2048 px · มีพื้นโปร่ง = PNG ที่เหลือ JPEG 0.85 (ตามแผน API จริง) */
    private fun uploadData(img: Bitmap): Pair<ByteArray, String> {
        val alpha = img.hasAlpha()
        val k = min(1f, 2048f / max(max(img.width, img.height), 1))
        val out = if (k < 1f) {
            Bitmap.createScaledBitmap(img, (img.width * k).roundToInt(), (img.height * k).roundToInt(), true)
        } else img
        val buf = ByteArrayOutputStream()
        return if (alpha) {
            out.compress(Bitmap.CompressFormat.PNG, 100, buf)
            buf.toByteArray() to "image/png"
        } else {
            out.compress(Bitmap.CompressFormat.JPEG, 85, buf)
            buf.toByteArray() to "image/jpeg"
        }
    }

    // MARK: echo

    private suspend fun echo(doc: LabDoc, rev: Int): Int {
        val body = buildJsonObject {
            put("rev", rev)
            put("doc", CardStore.json.encodeToJsonElement(LabDoc.serializer(), doc))
            put("platform", platform)
            put("device", device)
        }
        val res = http("POST", "api/echo", body.toString().toByteArray(), "application/json")
        return runCatching {
            CardStore.json.parseToJsonElement(res.text).jsonObject.getValue("diffs").jsonArray.size
        }.getOrDefault(0)
    }

    // MARK: HTTP (HttpURLConnection บน Dispatchers.IO · หมดเวลา 8 วิ เท่า iOS)

    private class Response(val code: Int, val body: ByteArray) {
        val text: String get() = body.toString(Charsets.UTF_8)
    }

    private suspend fun http(method: String, path: String, body: ByteArray? = null, type: String? = null): Response =
        withContext(Dispatchers.IO) {
            val c = URL("$server/$path").openConnection() as HttpURLConnection
            try {
                c.connectTimeout = 8000
                c.readTimeout = 8000
                c.useCaches = false
                c.requestMethod = method
                if (body != null) {
                    c.doOutput = true
                    if (type != null) c.setRequestProperty("Content-Type", type)
                    c.setFixedLengthStreamingMode(body.size)
                    c.outputStream.use { it.write(body) }
                }
                val code = c.responseCode
                val stream = if (code >= 400) c.errorStream else c.inputStream
                Response(code, stream?.use { it.readBytes() } ?: ByteArray(0))
            } finally {
                c.disconnect()
            }
        }

    // MARK: สถานะข้ามการเปิดแอป (อยู่นอกของที่ถูกสำรอง — ดู `LabMode`)

    @Serializable
    private data class State(
        val cardID: String? = null,
        val rev: Int = 0,
        val lastJSON: String? = null,
        val slotIDs: Map<String, String> = emptyMap(),
    )

    private val stateJson = Json { ignoreUnknownKeys = true; encodeDefaults = true }

    private fun loadState() {
        val s = runCatching { stateJson.decodeFromString(State.serializer(), LabMode.stateFile.readText()) }.getOrNull() ?: return
        cardID = s.cardID
        rev = s.rev
        lastJSON = s.lastJSON
        slotIDs.clear()
        slotIDs.putAll(s.slotIDs)
        // รูปที่โหลดจากดิสก์เป็นอ็อบเจกต์ใหม่ — ผูก id เดิมกลับ ไม่งั้นเปิดแอปทีไรอัปรูปซ้ำทุกใบ
        val photos = photos ?: return
        val folio = Portfolio.shared
        fun bind(img: Bitmap?, id: String) { if (img != null) known[img] = id }
        fun index(key: String, prefix: String): Int? = if (key.startsWith(prefix)) key.removePrefix(prefix).toIntOrNull() else null
        for ((key, id) in slotIDs) {
            val creator = index(key, "creator#")
            val work = index(key, "work#")
            val lib = index(key, "lib#")
            when {
                key == "bg" -> bind(photos.background, id)
                key == "avatar" -> bind(photos.profile, id)
                creator != null -> bind(folio.creators.getOrNull(creator), id)
                work != null -> bind(folio.works.getOrNull(work)?.image, id)
                lib != null -> bind(photos.uploaded.getOrNull(lib), id)
                else -> LabDoc.slotKey(key)?.let { (wid, slot) -> bind(photos.perWidget[wid]?.get(slot), id) }
            }
        }
    }

    private fun saveState() {
        val s = State(cardID = cardID, rev = rev, lastJSON = lastJSON, slotIDs = slotIDs.toMap())
        runCatching { LabMode.atomicWrite(LabMode.stateFile, stateJson.encodeToString(State.serializer(), s).toByteArray()) }
    }
}
