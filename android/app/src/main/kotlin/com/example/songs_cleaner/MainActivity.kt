package com.example.songs_cleaner

import android.content.Intent
import android.os.Bundle
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    // Set when the user closes the app from the media notification so the
    // destroy handler does not re-arm the routine playback service.
    private var closingApp = false

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ROUTINE_PLAYBACK_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "arm" -> {
                    try {
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, RoutinePlaybackService::class.java),
                        )
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("routine_playback_start_failed", null, null)
                    }
                }
                "disarm" -> {
                    stopService(Intent(this, RoutinePlaybackService::class.java))
                    result.success(null)
                }
                "handoff" -> {
                    // Returns the live native position (and stops native
                    // playback) so Flutter resumes the exact spot instead of
                    // starting a second, overlapping stream.
                    result.success(RoutinePlaybackService.instance?.handoff())
                }
                "closeApp" -> {
                    closingApp = true
                    stopService(Intent(this, RoutinePlaybackService::class.java))
                    result.success(null)
                    finishAndRemoveTask()
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        LockScreenController.detach(this)
        if (!isChangingConfigurations && !closingApp) {
            try {
                ContextCompat.startForegroundService(
                    this,
                    Intent(this, RoutinePlaybackService::class.java),
                )
            } catch (_: IllegalStateException) {
                // Android can reject starts after an explicit Force stop.
            }
        }
        super.onDestroy()
    }

    private companion object {
        const val ROUTINE_PLAYBACK_CHANNEL =
            "com.example.songs_cleaner/routine_playback"
        const val LOCK_SCREEN_CHANNEL =
            "com.example.songs_cleaner/lock_screen"
    }
}
