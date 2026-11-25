package com.example.songs_cleaner

import android.content.Context
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

internal class SystemPaletteChannel(context: Context, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.example.songs_cleaner/system_palette")

    init {
        channel.setMethodCallHandler { call, result ->
            when {
                call.method != "getPalette" -> result.notImplemented()
                Build.VERSION.SDK_INT < Build.VERSION_CODES.S -> result.success(null)
                else -> result.success(mapOf(
                    "light" to SystemColorRoles.read(context, false),
                    "dark" to SystemColorRoles.read(context, true),
                ))
            }
        }
    }

    fun configurationChanged() { channel.invokeMethod("paletteChanged", null) }
}
