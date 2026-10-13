package com.example.songs_cleaner

import android.content.Context
import android.content.Intent
import android.view.KeyEvent

/**
 * Bootstraps the UI for a cold Routine command. Playback starts only after
 * Flutter has initialized the existing AudioService handler.
 */
class LockScreenMediaButtonReceiver : android.content.BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyEvent = intent.getParcelableExtra<KeyEvent>(Intent.EXTRA_KEY_EVENT)
        val opensPlayer = keyEvent != null &&
            keyEvent.action == KeyEvent.ACTION_DOWN &&
            (keyEvent.keyCode == KeyEvent.KEYCODE_MEDIA_PLAY ||
                keyEvent.keyCode == KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)

        if (opensPlayer) {
            LockScreenController.showFromMediaButton(context)
            return
        }

        // Samsung sends play/pause with a KeyEvent. Other media commands are
        // intentionally ignored here; an already-running MediaSession handles
        // them directly without bootstrapping a second path.
    }
}
