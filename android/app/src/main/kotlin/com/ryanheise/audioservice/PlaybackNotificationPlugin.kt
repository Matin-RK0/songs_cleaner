package com.ryanheise.audioservice

import android.app.NotificationManager
import android.content.Context
import androidx.core.app.ServiceCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/** Engine-scoped so closing from the notification also works without an Activity. */
class PlaybackNotificationPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                if (call.method != "dismiss") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                // audio_service.stop() only calls stopSelf(). A bound service
                // can survive that call, so onDestroy's foreground cleanup may
                // not run. Remove foreground ownership before cancelling.
                // This package intentionally accesses audio_service's
                // package-private instance without reflection or a second service.
                AudioService.instance?.let { service ->
                    ServiceCompat.stopForeground(service, ServiceCompat.STOP_FOREGROUND_REMOVE)
                    service.stop()
                }
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                // audio_service 0.18.x playback ID; never cancel download notifications.
                manager.cancel(1124)
                result.success(null)
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    companion object {
        const val CHANNEL = "songs_cleaner/playback_notification"
    }
}
