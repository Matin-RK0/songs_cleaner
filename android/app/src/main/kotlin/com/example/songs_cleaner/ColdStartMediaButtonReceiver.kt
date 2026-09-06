package com.example.songs_cleaner

import android.content.Context
import android.content.Intent
import android.view.KeyEvent
import com.ryanheise.audioservice.MediaButtonReceiver

/**
 * Saves a play request that arrives before audio_service has recreated its
 * Flutter handler after a cold start. The plugin's initial MediaSession cannot
 * dispatch that first request because its Dart callback is not registered yet.
 */
class ColdStartMediaButtonReceiver : MediaButtonReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyEvent = intent.mediaKeyEvent()
        if (keyEvent?.action == KeyEvent.ACTION_DOWN && keyEvent.isPlayRequest()) {
            context
                .getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(FLUTTER_KEY_PENDING_PLAY, true)
                .commit()
        }

        super.onReceive(context, intent)
    }

    @Suppress("DEPRECATION")
    private fun Intent.mediaKeyEvent(): KeyEvent? =
        if (action == Intent.ACTION_MEDIA_BUTTON) {
            getParcelableExtra(Intent.EXTRA_KEY_EVENT)
        } else {
            null
        }

    private fun KeyEvent.isPlayRequest(): Boolean =
        keyCode == KeyEvent.KEYCODE_MEDIA_PLAY ||
            keyCode == KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE

    private companion object {
        const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
        const val FLUTTER_KEY_PENDING_PLAY = "flutter.pendingColdStartPlay"
    }
}
