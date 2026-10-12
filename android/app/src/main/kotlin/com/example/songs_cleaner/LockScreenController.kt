package com.example.songs_cleaner

import android.app.Activity
import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Drives the "music controls on the lock screen" feature.
 *
 * When the screen turns on while the keyguard is showing and a song is actively
 * playing, this brings the live [MainActivity] forward over the keyguard so the
 * Flutter player route covers the lock screen. It relies on the
 * SYSTEM_ALERT_WINDOW permission ("Display over other apps"), which is a hard
 * background-activity-launch exemption on Android 10+, so the Activity can be
 * raised from the SCREEN_ON broadcast without a full-screen notification.
 *
 * The [MainActivity] is shared with normal use, so the lock-screen window flags
 * are applied dynamically only while the player is shown; the manifest never
 * declares `showWhenLocked` (that would leak the whole app over the keyguard).
 *
 * The receiver is registered on the application context, so it survives
 * Activity recreation for as long as the process lives (kept alive by the
 * audio_service media session during playback).
 */
object LockScreenController {
    /** Intent extra MainActivity uses to know the launch came from here. */
    const val EXTRA_SHOW_PLAYER = "com.example.songs_cleaner.LOCK_SCREEN"

    @Volatile private var activity: Activity? = null
    @Volatile private var channel: MethodChannel? = null

    /**
     * Application context kept for the whole process. Playback keeps the process
     * alive via audio_service after the Activity is destroyed, and the screen-on
     * broadcast still needs a context to check the keyguard and launch.
     */
    @Volatile private var appContext: Context? = null
    private var receiver: BroadcastReceiver? = null

    /** Mirrors the user toggle persisted on the Dart side. */
    @Volatile var enabled = false

    /** True while a track is actively playing (same rule as the Flutter UI). */
    @Volatile var playbackActive = false

    @Volatile private var dartReady = false
    @Volatile private var pendingShow = false

    /** True while the player is currently covering the keyguard. */
    @Volatile private var playerShown = false

    // -- Lifecycle --------------------------------------------------------------

    fun attach(host: Activity, methodChannel: MethodChannel) {
        activity = host
        appContext = host.applicationContext
        channel = methodChannel
        registerReceiver(host.applicationContext)
        if (playerShown) applyLockedFlags(host)
    }

    fun detach(host: Activity) {
        if (activity === host) activity = null
    }

    fun onActivityCreated(host: Activity) {
        activity = host
        if (playerShown) applyLockedFlags(host)
    }

    /** @return true when the intent requested the lock-screen player. */
    fun onNewIntent(intent: Intent): Boolean {
        if (!intent.getBooleanExtra(EXTRA_SHOW_PLAYER, false)) return false
        playerShown = true
        activity?.let(::applyLockedFlags)
        deliverShow()
        return true
    }

    // -- Screen / keyguard events ----------------------------------------------

    private fun registerReceiver(context: Context) {
        if (receiver != null) return
        val registered = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_ON -> onScreenOn()
                    Intent.ACTION_USER_PRESENT -> onUserPresent()
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        // These actions can only be registered at runtime, never in the
        // manifest, so the receiver follows the process, not the Activity.
        ContextCompat.registerReceiver(
            context,
            registered,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        receiver = registered
    }

    private fun onScreenOn() {
        if (!enabled || !playbackActive || playerShown) return
        val context = appContext ?: return
        if (!overlayGranted(context)) return
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (!keyguard.isKeyguardLocked) return
        showOverLockScreen(context)
    }

    /** SYSTEM_ALERT_WINDOW is granted at install time before Android 6. */
    private fun overlayGranted(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            Settings.canDrawOverlays(context)

    private fun showOverLockScreen(context: Context) {
        playerShown = true
        activity?.let(::applyLockedFlags)
        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT,
            )
            putExtra(EXTRA_SHOW_PLAYER, true)
        }
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            playerShown = false
            return
        }
        deliverShow()
    }

    private fun deliverShow() {
        val current = channel
        if (current == null || !dartReady) {
            pendingShow = true
            return
        }
        current.invokeMethod("showPlayer", null)
    }

    private fun onUserPresent() {
        if (!playerShown) return
        playerShown = false
        activity?.let(::clearLockedFlags)
        channel?.invokeMethod("hidePlayer", null)
    }

    /** Back pressed on the lock-screen player: retreat to the keyguard. */
    private fun dismissFromBack() {
        if (!playerShown) return
        playerShown = false
        val host = activity
        if (host != null) {
            clearLockedFlags(host)
            host.moveTaskToBack(true)
        }
    }

    private fun dismissIfShown() {
        if (!playerShown) return
        playerShown = false
        activity?.let(::clearLockedFlags)
    }

    // -- Window flags -----------------------------------------------------------

    private fun applyLockedFlags(host: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            host.setShowWhenLocked(true)
            host.setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            host.window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    private fun clearLockedFlags(host: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            host.setShowWhenLocked(false)
            host.setTurnScreenOn(false)
        } else {
            @Suppress("DEPRECATION")
            host.window.clearFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    // -- Dart channel -----------------------------------------------------------

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val context = appContext
        when (call.method) {
            "register" -> {
                dartReady = true
                val show = pendingShow
                pendingShow = false
                result.success(show)
            }
            "isSupported" -> result.success(true)
            "hasOverlayPermission" ->
                result.success(context != null && overlayGranted(context))
            "requestOverlayPermission" -> {
                if (context != null) {
                    try {
                        context.startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:${context.packageName}"),
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    } catch (_: Exception) {
                        // Some OEMs hide this screen; the caller re-checks the
                        // permission on resume either way.
                    }
                }
                result.success(null)
            }
            "setEnabled" -> {
                enabled = call.arguments == true
                if (!enabled) dismissIfShown()
                result.success(null)
            }
            "setPlaybackActive" -> {
                playbackActive = call.arguments == true
                result.success(null)
            }
            "consumePendingShow" -> {
                val show = pendingShow
                pendingShow = false
                result.success(show)
            }
            "dismiss" -> {
                dismissFromBack()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
