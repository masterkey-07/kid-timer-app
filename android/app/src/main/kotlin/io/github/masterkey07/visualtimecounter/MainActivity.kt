package io.github.masterkey07.visualtimecounter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SystemSettingsChannel(applicationContext).register(flutterEngine.dartExecutor.binaryMessenger)
    }
}
