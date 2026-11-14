package com.example.songs_cleaner

import android.content.ComponentName
import android.content.Context
import android.os.Looper
import android.provider.Settings
import java.time.Duration
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE)
@LooperMode(LooperMode.Mode.PAUSED)
class ScreenLockAccessibilityServiceTest {
    private lateinit var context: Context

    @Before
    fun setUp() {
        context = RuntimeEnvironment.getApplication()
        setEnabledServices("")
    }

    @Test
    fun disabledServiceRequiresPermission() {
        assertEquals("permissionRequired", ScreenLockAccessibilityService.lockScreen(context))
    }

    @Test
    fun enabledButDisconnectedServiceDoesNotRequirePermission() {
        val component = ComponentName(context, ScreenLockAccessibilityService::class.java)
        for (name in listOf(component.flattenToString(), component.flattenToShortString())) {
            setEnabledServices("other.package/other.package.Service:$name")
            assertEquals("unavailable", ScreenLockAccessibilityService.lockScreen(context))
        }
    }

    @Test
    fun unrelatedEnabledServiceDoesNotGrantAccess() {
        setEnabledServices("other.package/other.package.Service")
        assertEquals("permissionRequired", ScreenLockAccessibilityService.lockScreen(context))
    }

    @Test
    fun coldStartWaitsForConnectionThenFailsWithoutRequestingPermission() {
        setEnabledServices(ComponentName(context, ScreenLockAccessibilityService::class.java).flattenToString())
        var result: String? = null
        ScreenLockAccessibilityService.lockScreenWhenReady(context) { result = it }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1400))
        assertNull(result)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
        assertEquals("failed", result)
    }

    @Test
    fun permissionRevokedWhileWaitingIsDetected() {
        setEnabledServices(ComponentName(context, ScreenLockAccessibilityService::class.java).flattenToString())
        var result: String? = null
        ScreenLockAccessibilityService.lockScreenWhenReady(context) { result = it }
        shadowOf(Looper.getMainLooper()).idle()
        assertNull(result)
        setEnabledServices("")
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
        assertEquals("permissionRequired", result)
    }

    @Test
    fun incomingCallCancelsPendingLock() {
        setEnabledServices(ComponentName(context, ScreenLockAccessibilityService::class.java).flattenToString())
        var allowed = true
        var result: String? = null
        ScreenLockAccessibilityService.lockScreenWhenReady(context, canLock = { allowed }) { result = it }
        shadowOf(Looper.getMainLooper()).idle()
        assertNull(result)
        allowed = false
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
        assertEquals("failed", result)
    }

    private fun setEnabledServices(value: String) {
        Settings.Secure.putString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, value)
    }
}
