package com.example.songs_cleaner

import android.content.Intent
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LockScreenController.onActivityCreated(this)
        // A cold start triggered by LockScreenController carries the extra that
        // asks Dart to open the lock-screen player route.
        LockScreenController.onNewIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        LockScreenController.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LockScreenController.attach(
            this,
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                LOCK_SCREEN_CHANNEL,
            ).apply {
                setMethodCallHandler(LockScreenController::handleMethodCall)
            },
        )
    }

    override fun onDestroy() {
        LockScreenController.detach(this)
        super.onDestroy()
    }

    private companion object {
        const val LOCK_SCREEN_CHANNEL =
            "com.example.songs_cleaner/lock_screen"
    }
}
