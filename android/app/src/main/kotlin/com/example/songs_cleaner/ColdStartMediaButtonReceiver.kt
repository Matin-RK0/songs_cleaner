package com.example.songs_cleaner

import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.view.KeyEvent
import androidx.core.content.ContextCompat

/** Starts native playback after Android routes a cold media-button event. */
class ColdStartMediaButtonReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyEvent = intent.mediaKeyEvent()
        if (keyEvent?.action == KeyEvent.ACTION_DOWN && keyEvent.isPlayRequest()) {
            try {
                ContextCompat.startForegroundService(
                    context,
                    Intent(context, RoutinePlaybackService::class.java).apply {
                        action = RoutinePlaybackService.ACTION_START_PLAY
                    },
                )
            } catch (_: IllegalStateException) {
                // Android rejects all component starts after Force stop.
            }
        }
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
}
