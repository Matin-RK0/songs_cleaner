package com.example.songs_cleaner

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

/** Combines event ordering with the device-wide (including multi-SIM) call snapshot. */
internal class PhoneCallState {
    private var reportedBusy = false

    fun report(busy: Boolean) {
        reportedBusy = busy
    }

    fun blocksPlayer(permissionGranted: Boolean, inCall: Boolean?): Boolean =
        !permissionGranted || inCall == null || inCall || reportedBusy
}

/**
 * Official phone-state events, not audio modes or microphone/ringer detection.
 * https://developer.android.com/reference/android/telephony/TelephonyManager#ACTION_PHONE_STATE_CHANGED
 * https://developer.android.com/reference/android/telecom/TelecomManager#isInCall()
 * Kept on the application context for the same process lifetime as playback.
 */
internal class PhoneCallGuard(context: Context, onCallStarted: () -> Unit) {
    private val app = context.applicationContext
    private val state = PhoneCallState()
    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
            when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
                TelephonyManager.EXTRA_STATE_RINGING,
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    // The event can arrive before Telecom's snapshot is updated.
                    state.report(true)
                    onCallStarted()
                }
                TelephonyManager.EXTRA_STATE_IDLE -> state.report(false)
            }
            // No automatic presentation on IDLE: leave the dialer in control.
        }
    }

    init {
        // PHONE_STATE is a protected system broadcast. Telephony can send it
        // from a privileged UID other than system; NOT_EXPORTED drops it on
        // some devices. Keep it separate from the screen-event receiver.
        ContextCompat.registerReceiver(
            app,
            receiver,
            IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED),
            ContextCompat.RECEIVER_EXPORTED,
        )
    }

    fun hasPermission(): Boolean = ContextCompat.checkSelfPermission(
        app, Manifest.permission.READ_PHONE_STATE,
    ) == PackageManager.PERMISSION_GRANTED

    fun blocksPlayer(): Boolean {
        val granted = hasPermission()
        val inCall = if (granted) {
            try {
                (app.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)?.isInCall
            } catch (_: SecurityException) {
                // Permission may be revoked between checking and querying it.
                null
            } catch (_: UnsupportedOperationException) {
                null
            }
        } else null
        return state.blocksPlayer(granted, inCall)
    }

    /** Bring the existing system call UI forward; never place or answer a call. */
    fun showSystemCallScreen() {
        if (!hasPermission()) return
        try {
            (app.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager)
                ?.showInCallScreen(false)
        } catch (_: SecurityException) {
            // Permission was revoked; the player's window has already yielded.
        } catch (_: UnsupportedOperationException) {
            // Devices without Telecom may not provide an in-call UI.
        }
    }
}
