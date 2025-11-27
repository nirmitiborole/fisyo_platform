package com.example.goniometer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Manually add the plugin to the engine's list of plugins
        flutterEngine.getPlugins().add(MotionDetectorPlugin())
    }
}
