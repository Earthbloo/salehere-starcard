package co.salehere.starcard

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import co.salehere.starcard.model.ClipInvocation
import co.salehere.starcard.model.LabMode
import co.salehere.starcard.model.LocalClipInvocation
import co.salehere.starcard.ui.export.WidgetMatrix
import co.salehere.starcard.ui.export.WidgetMatrixExporter

class MainActivity : ComponentActivity() {
    /// ลิงก์ที่เปิดแอป — ทั้งตอนเปิดครั้งแรก (`intent`) และตอนแอปเปิดอยู่แล้ว (`onNewIntent`)
    private val launchUri = mutableStateOf<android.net.Uri?>(null)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // ก่อนสโตร์ใดอ่านดิสก์ — โหมดลองทำต้องสำรอง/คืนข้อมูลเดิมให้เสร็จก่อน (ดู `LabMode`)
        // extra ของ intent ที่ถูกเล่นซ้ำ (เปิดจากรายการแอปล่าสุด / กู้หน้าต่าง) ไม่นับ — ไม่งั้นปิดโหมดแล้วเปิดกลับเอง
        val fresh = savedInstanceState == null &&
            ((intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0
        LabMode.bootstrap(
            labSync = if (fresh) intent?.getStringExtra("labSync") else null,
            labServer = if (fresh) intent?.getStringExtra("labServer") else null,
        )
        enableEdgeToEdge()
        // DEBUG: วาดตารางวิดเจ็ตเป็น PNG ไว้เทียบกับ iOS (ดู `WidgetMatrixExporter`) — ไม่แตะสโตร์ ไม่เปิดแอปจริง
        if (fresh && intent?.getStringExtra("exportWidgetMatrix") != null && WidgetMatrix.enabled(this)) {
            setContent { WidgetMatrixExporter(onDone = {}) }
            return
        }
        launchUri.value = intent?.data
        setContent { AppRoot(launchUri.value) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // แอปเปิดอยู่แล้วแต่ถูกสั่งโหมดใหม่ — เขียนธงแล้วปิดแอป (มีผลตอนเปิดครั้งถัดไป)
        LabMode.bootstrap(labSync = intent.getStringExtra("labSync"), labServer = intent.getStringExtra("labServer"))
        launchUri.value = intent.data
    }
}

/**
 * รากของทุกอย่าง — ตรึง `fontScale = 1` ทั้งแอป (การ์ดคือชิ้นงานที่ส่งต่อ ขนาดตัวอักษรต้องเท่ากันทุกเครื่อง
 * ไม่ล้อการตั้งค่า accessibility ของผู้ดู — ดู PORTING.md §3) แล้วส่ง `ClipInvocation` ลงไปให้ `ContentView`
 */
@Composable
fun AppRoot(launchUri: android.net.Uri?) {
    val base = LocalDensity.current
    val invocation = androidx.compose.runtime.remember { ClipInvocation() }
    androidx.compose.runtime.LaunchedEffect(launchUri) { launchUri?.let { invocation.consume(it) } }
    CompositionLocalProvider(
        LocalDensity provides Density(base.density, fontScale = 1f),
        LocalClipInvocation provides invocation,
    ) {
        Box(Modifier.fillMaxSize().background(Color.White)) {
            ContentView()
        }
    }
}
