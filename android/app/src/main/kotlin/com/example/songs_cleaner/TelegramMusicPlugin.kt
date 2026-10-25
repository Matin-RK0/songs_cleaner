package com.example.songs_cleaner

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

/** Engine-owned application-context bridge; activity recreation must not leak
 * copy executors or detach a background transfer's storage channel. */
class TelegramMusicPlugin : FlutterPlugin {
    private var channel: MethodChannel? = null
    private var store: TelegramMusicStore? = null
    private var context: Context? = null
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        val musicStore = TelegramMusicStore(binding.applicationContext)
        store = musicStore
        channel = MethodChannel(binding.binaryMessenger, "com.example.songs_cleaner/telegram_music")
            .apply { setMethodCallHandler(musicStore) }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        store?.close()
        context?.let { it.stopService(Intent(it, TelegramDownloadService::class.java)) }
        channel = null
        store = null
        context = null
    }
}
