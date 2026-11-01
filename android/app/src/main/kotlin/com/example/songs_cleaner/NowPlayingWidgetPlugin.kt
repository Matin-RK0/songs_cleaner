package com.example.songs_cleaner

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/** Widget storage and updates must work even when no Activity exists. */
class NowPlayingWidgetPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null
    private var pendingAction: String? = null
    private var ready = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.example.songs_cleaner/now_playing_widget").apply {
            setMethodCallHandler { call, result ->
                val prefs = context.getSharedPreferences(NowPlayingWidgetProvider.PREFS, Context.MODE_PRIVATE)
                when (call.method) {
                    "update" -> {
                        prefs.edit()
                            .putString(NowPlayingWidgetProvider.TITLE, call.argument<String>("title"))
                            .putString(NowPlayingWidgetProvider.ARTIST, call.argument<String>("artist"))
                            .putInt(NowPlayingWidgetProvider.SONG_ID, call.argument<Int>("songId") ?: -1)
                            .putBoolean(NowPlayingWidgetProvider.PLAYING, call.argument<Boolean>("playing") ?: false)
                            .apply()
                        NowPlayingWidgetProvider.updateAll(context)
                        result.success(null)
                    }
                    "setBackgroundColor" -> {
                        val color = call.argument<Number>("color")?.toInt()
                        prefs.edit().apply {
                            if (color == null) remove(NowPlayingWidgetProvider.BACKGROUND_COLOR)
                            else putInt(NowPlayingWidgetProvider.BACKGROUND_COLOR, color)
                        }.apply()
                        NowPlayingWidgetProvider.updateAll(context)
                        result.success(null)
                    }
                    "consumeAction" -> {
                        ready = true
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    fun dispatchAction(action: String) {
        if (ready) channel?.invokeMethod("widgetAction", action)
        else pendingAction = action
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        ready = false
    }

    companion object {
        fun register(engine: FlutterEngine) {
            if (engine.plugins.has(NowPlayingWidgetPlugin::class.java)) return
            val plugin = NowPlayingWidgetPlugin()
            engine.plugins.add(plugin)
            engine.addEngineLifecycleListener(object : FlutterEngine.EngineLifecycleListener {
                override fun onPreEngineRestart() { plugin.ready = false }
                override fun onEngineWillDestroy() {}
            })
        }
    }
}
