package co.salehere.starcard

import android.app.Application

/// Application — holds the process-wide singletons' context (UserDefaults → SharedPreferences, Documents → filesDir).
class StarCardApp : Application() {
    override fun onCreate() {
        super.onCreate()
        AppContext.install(this)
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
