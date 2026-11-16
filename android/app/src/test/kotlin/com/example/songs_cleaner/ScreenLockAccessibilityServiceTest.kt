package com.example.songs_cleaner

import android.accessibilityservice.AccessibilityService
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
import org.robolectric.Robolectric
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.annotation.LooperMode
import org.robolectric.shadow.api.Shadow
import org.robolectric.shadows.ShadowAccessibilityService
import org.robolectric.util.ReflectionHelpers

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], manifest = Config.NONE, shadows = [RetryableAccessibilityServiceShadow::class])
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
    fun coldStartWaitsForConnectionThenReportsDisconnectionWithoutRequestingPermission() {
        setEnabledServices(ComponentName(context, ScreenLockAccessibilityService::class.java).flattenToString())
        var result: String? = null
        ScreenLockAccessibilityService.lockScreenWhenReady(context) { result = it }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(4900))
        assertNull(result)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
        assertEquals("unavailable", result)
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

    @Test
    fun serviceConnectingAfterOriginalTimeoutStillLocks() {
        setEnabledServices(ComponentName(context, ScreenLockAccessibilityService::class.java).flattenToString())
        var result: String? = null
        ScreenLockAccessibilityService.lockScreenWhenReady(context) { result = it }
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2000))
        assertNull(result)
        val controller = Robolectric.buildService(ScreenLockAccessibilityService::class.java).create()
        try {
            ReflectionHelpers.callInstanceMethod<Any?>(controller.get(), "onServiceConnected")
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
            assertEquals("locked", result)
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun transientActionRejectionIsRetried() {
        val controller = Robolectric.buildService(ScreenLockAccessibilityService::class.java).create()
        try {
            val service = controller.get()
            ReflectionHelpers.callInstanceMethod<Any?>(service, "onServiceConnected")
            val shadow = Shadow.extract<RetryableAccessibilityServiceShadow>(service)
            shadow.acceptAction = false
            var result: String? = null
            ScreenLockAccessibilityService.lockScreenWhenReady(context) { result = it }
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(200))
            assertNull(result)
            shadow.acceptAction = true
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
            assertEquals("locked", result)
        } finally {
            controller.destroy()
        }
    }

    @Test
    fun persistentActionRejectionStopsRetrying() {
        val controller = Robolectric.buildService(ScreenLockAccessibilityService::class.java).create()
        try {
            val service = controller.get()
            ReflectionHelpers.callInstanceMethod<Any?>(service, "onServiceConnected")
            Shadow.extract<RetryableAccessibilityServiceShadow>(service).acceptAction = false
            val results = mutableListOf<String>()
            ScreenLockAccessibilityService.lockScreenWhenReady(context) { results.add(it) }
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1400))
            assertEquals(emptyList<String>(), results)
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(100))
            assertEquals(listOf("failed"), results)
            shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(5))
            assertEquals(listOf("failed"), results)
        } finally {
            controller.destroy()
        }
    }

    private fun setEnabledServices(value: String) {
        Settings.Secure.putString(context.contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, value)
    }
}

@Implements(AccessibilityService::class)
class RetryableAccessibilityServiceShadow : ShadowAccessibilityService() {
    var acceptAction = true

    @Implementation
    override fun performGlobalAction(action: Int): Boolean = acceptAction
}
