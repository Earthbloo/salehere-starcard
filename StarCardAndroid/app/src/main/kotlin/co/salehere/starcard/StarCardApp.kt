package co.salehere.starcard

import android.app.Application
import co.salehere.starcard.model.SpecCatalog

/// Application — holds the process-wide singletons' context (UserDefaults → SharedPreferences, Documents → filesDir).
class StarCardApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AppContext.install(this)
        loadWidgetSpecs()
        // การ์ดเริ่มต้น (= `shared/starter-cards.json` ไฟล์เดียวกับ iOS)
        runCatching { assets.open("starter-cards.json").bufferedReader().use { it.readText() } }
            .onSuccess { co.salehere.starcard.model.Mock.loadStarters(it) }
    }

    /// โหลดผังวิดเจ็ตทุกใบจาก assets/WidgetSpecs (= โฟลเดอร์กลาง shared/WidgetSpecs ชุดเดียวกับ iOS) เข้า `SpecCatalog`
    private fun loadWidgetSpecs() {
        val names = runCatching { assets.list("WidgetSpecs")?.toList() }.getOrNull() ?: emptyList()
        for (name in names) {
            if (!name.endsWith(".json")) continue
            runCatching {
                val text = assets.open("WidgetSpecs/$name").bufferedReader().use { it.readText() }
                SpecCatalog.register(SpecCatalog.fromJson(text))
            }.onFailure { android.util.Log.w("StarCard", "spec $name: ${it.message}") }
        }
    }
}

/// Process-wide context for the singleton stores (`Profile.me`, `StarFlow.shared`, `CardLibrary.shared`, `PhotoStore`).
/// iOS used `UserDefaults.standard` / `FileManager.documentDirectory` — Android needs a Context for both.
object AppContext {
    lateinit var app: Application
        private set
    fun install(a: Application) { app = a }
    val prefs get() = app.getSharedPreferences("starcard", android.content.Context.MODE_PRIVATE)
    val filesDir get() = app.filesDir
}
