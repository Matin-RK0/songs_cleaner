package com.example.songs_cleaner

import android.accessibilityservice.AccessibilityService
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent

/** Performs locks requested by the player gesture or its inactivity timer; reads no window content. */
class ScreenLockAccessibilityService : AccessibilityService() {
    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) = Unit

    override fun onInterrupt() = Unit

    override fun onUnbind(intent: Intent?): Boolean {
        if (instance === this) instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        if (instance === this) instance = null
        super.onDestroy()
    }

    companion object {
        private var instance: ScreenLockAccessibilityService? = null
        private val handler = Handler(Looper.getMainLooper())
        private const val CONNECTION_TIMEOUT_MS = 1500L
        private const val CONNECTION_RETRY_MS = 100L

        fun lockScreen(context: Context): String {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return "unsupported"
            val service = instance ?: return if (isEnabled(context)) "unavailable" else "permissionRequired"
            return if (service.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)) "locked" else "failed"
        }

        /** Cold starts (including Routines) may precede Android binding this service. */
        fun lockScreenWhenReady(
            context: Context,
            canLock: () -> Boolean = { true },
            onResult: (String) -> Unit,
        ) {
            val appContext = context.applicationContext
            val deadline = SystemClock.uptimeMillis() + CONNECTION_TIMEOUT_MS
            val attempt = object : Runnable {
                override fun run() {
                    if (!canLock()) {
                        onResult("failed")
                        return
                    }
                    val status = lockScreen(appContext)
                    if (status == "unavailable" && SystemClock.uptimeMillis() < deadline) {
                        handler.postDelayed(this, CONNECTION_RETRY_MS)
                    } else {
                        // A disconnected, enabled service is not a missing permission.
                        onResult(if (status == "unavailable") "failed" else status)
                    }
                }
            }
            handler.post(attempt)
        }

        private fun isEnabled(context: Context): Boolean {
            val expected = ComponentName(context, ScreenLockAccessibilityService::class.java)
            val enabledServices = Settings.Secure.getString(
                context.contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
            ).orEmpty()
            return enabledServices.split(':').any {
                ComponentName.unflattenFromString(it) == expected
            }
        }
    }
}
