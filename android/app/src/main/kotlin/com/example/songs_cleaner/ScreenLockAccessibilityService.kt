package com.example.songs_cleaner

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
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

        fun lockScreen(): String {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return "unsupported"
            val service = instance ?: return "permissionRequired"
            return if (service.performGlobalAction(GLOBAL_ACTION_LOCK_SCREEN)) "locked" else "failed"
        }
    }
}
