package ch.pocketpillar.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity is required by local_auth (biometric dialog).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Anti-capture: blocks screenshots and the multitasking thumbnail (financial data).
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // In-house OCR plugin (ML Kit on-device) — see OcrPlugin.kt.
        OcrPlugin.register(flutterEngine.dartExecutor.binaryMessenger, this)
    }
}
