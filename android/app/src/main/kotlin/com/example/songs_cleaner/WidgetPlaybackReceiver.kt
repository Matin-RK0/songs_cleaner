package com.example.songs_cleaner

import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import com.ryanheise.audioservice.AudioServicePlugin
import com.ryanheise.audioservice.MediaButtonReceiver
import com.ryanheise.audioservice.PlaybackNotificationPlugin
import io.flutter.plugin.common.MethodChannel

/** Explicitly targets our MediaBrowserService, including after process death. */
class WidgetPlaybackReceiver : MediaButtonReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyCode = when (intent.action) {
            NowPlayingWidgetProvider.ACTION_PREVIOUS -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            NowPlayingWidgetProvider.ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            NowPlayingWidgetProvider.ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> return
        }
        // Warm the same engine AudioService uses. Its native handler queues
        // media commands until AudioService.init has finished on the Dart side.
        val engine = AudioServicePlugin.getFlutterEngine(context)
        if (!engine.plugins.has(PlaybackNotificationPlugin::class.java)) {
            engine.plugins.add(PlaybackNotificationPlugin())
        }
        if (!engine.plugins.has(NowPlayingWidgetPlugin::class.java)) {
            NowPlayingWidgetPlugin.register(engine)
            LockScreenController.attachEngine(
                context,
                MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.songs_cleaner/lock_screen").apply {
                    setMethodCallHandler(LockScreenController::handleMethodCall)
                },
            )
        }
        // AndroidX binds the app's MediaBrowserService and sends this event
        // only once connected; unlike AudioManager it can bootstrap a cold app.
        super.onReceive(context, Intent(Intent.ACTION_MEDIA_BUTTON).apply {
            putExtra(Intent.EXTRA_KEY_EVENT, KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        })
    }
}
