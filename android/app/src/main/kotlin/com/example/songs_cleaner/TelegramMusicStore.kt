package com.example.songs_cleaner

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/** Copies completed downloads off the UI thread into the shared music library. */
class TelegramMusicStore(private val context: Context) : MethodChannel.MethodCallHandler {
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setDownloadActivity" -> {
                try {
                    val intent = Intent(context, TelegramDownloadService::class.java)
                    if ((call.argument<Int>("active") ?: 0) <= 0) {
                        context.stopService(intent)
                    } else {
                        intent.putExtra("title", call.argument<String>("title"))
                        intent.putExtra("text", call.argument<String>("text"))
                        ContextCompat.startForegroundService(context, intent)
                    }
                    result.success(true)
                } catch (_: Exception) { result.error("DOWNLOAD_SERVICE_UNAVAILABLE", "Background transfer unavailable", null) }
            }
            "openTelegramLink" -> {
                try {
                    val link = call.argument<String>("link") ?: ""
                    val uri = Uri.parse(link)
                    if (uri.scheme != "https" || uri.host != "t.me") throw IOException("Invalid Telegram link")
                    context.startActivity(Intent(Intent.ACTION_VIEW, uri).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(true)
                } catch (_: Exception) { result.success(false) }
            }
            "requiresLegacyPermission" -> result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.Q)
            "saveAudio" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val fileName = call.argument<String>("fileName")
                if (sourcePath.isNullOrEmpty() || fileName.isNullOrEmpty()) {
                    result.error("INVALID_AUDIO", "Audio source and name are required", null)
                    return
                }
                val title = call.argument<String>("title") ?: ""
                val artist = call.argument<String>("artist") ?: ""
                val durationMs = call.argument<Number>("durationMs")?.toLong() ?: 0L
                worker.execute {
                    try {
                        val source = File(sourcePath)
                        if (!source.isFile || source.length() == 0L) throw IOException("Missing completed audio")
                        val name = safeName(fileName)
                        val mime = MimeTypeMap.getSingleton()
                            .getMimeTypeFromExtension(name.substringAfterLast('.', "").lowercase())
                            ?: "audio/mpeg"
                        val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            saveScoped(source, name, mime, title, artist, durationMs)
                        } else {
                            saveLegacy(source, name)
                        }
                        scanAndReply(path, mime, result)
                    } catch (_: Exception) {
                        main.post { result.error("SAVE_AUDIO_FAILED", "Audio could not be saved to Music/Telegram", null) }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun saveScoped(source: File, name: String, mime: String, title: String,
                           artist: String, durationMs: Long): String {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Audio.Media.DISPLAY_NAME, name)
            put(MediaStore.Audio.Media.MIME_TYPE, mime)
            put(MediaStore.Audio.Media.RELATIVE_PATH, "${Environment.DIRECTORY_MUSIC}/Telegram/")
            put(MediaStore.Audio.Media.IS_PENDING, 1)
            put(MediaStore.Audio.Media.IS_MUSIC, 1)
            if (title.isNotEmpty()) put(MediaStore.Audio.Media.TITLE, title)
            if (artist.isNotEmpty()) put(MediaStore.Audio.Media.ARTIST, artist)
            if (durationMs > 0) put(MediaStore.Audio.Media.DURATION, durationMs)
        }
        // MediaStore chooses a free filename rather than replacing existing music.
        val collection = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw IOException("Unable to create audio entry")
        try {
            val copied = resolver.openOutputStream(uri, "w")?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IOException("Unable to open audio output")
            if (copied != source.length()) throw IOException("Incomplete audio copy")
            val path = resolver.query(uri, arrayOf(MediaStore.Audio.Media.DATA), null, null, null)?.use {
                if (it.moveToFirst()) it.getString(0) else null
            } ?: throw IOException("Audio file path unavailable")
            if (!File(path).isFile) throw IOException("Audio file unavailable")
            val published = ContentValues().apply { put(MediaStore.Audio.Media.IS_PENDING, 0) }
            if (resolver.update(uri, published, null, null) <= 0) throw IOException("Unable to publish audio")
            return path
        } catch (error: Exception) {
            // Failed copies must not leave a visible corrupt file or a pending row.
            try { resolver.delete(uri, null, null) } catch (_: Exception) { }
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveLegacy(source: File, name: String): String {
        val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "Telegram")
        if (!directory.isDirectory && !directory.mkdirs()) throw IOException("Unable to create music directory")
        val dot = name.lastIndexOf('.')
        val base = if (dot > 0) name.substring(0, dot) else name
        val extension = if (dot > 0) name.substring(dot) else ""
        var destination = File(directory, name)
        var suffix = 1
        while (!destination.createNewFile()) {
            destination = File(directory, "$base (${suffix++})$extension")
        }
        try {
            val copied = source.inputStream().use { input -> destination.outputStream().use { input.copyTo(it) } }
            if (copied != source.length()) throw IOException("Incomplete audio copy")
            return destination.absolutePath
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
    }

    private fun scanAndReply(path: String, mime: String, result: MethodChannel.Result) {
        val replied = AtomicBoolean(false)
        val reply = Runnable { if (replied.compareAndSet(false, true)) result.success(path) }
        // The shared file is already published. A delayed scanner must not block
        // completion indefinitely; the device can finish indexing it afterwards.
        main.postDelayed(reply, 10_000)
        try {
            MediaScannerConnection.scanFile(context, arrayOf(path), arrayOf(mime)) { _, _ ->
                main.post { main.removeCallbacks(reply); reply.run() }
            }
        } catch (_: Exception) {
            main.post { main.removeCallbacks(reply); reply.run() }
        }
    }

    private fun safeName(value: String): String {
        val name = value.replace('\\', '/').substringAfterLast('/')
            .replace(Regex("[\\x00-\\x1f<>:\"/\\\\|?*]"), "_").trim()
        if (name.isEmpty() || name == "." || name == "..") throw IOException("Invalid audio filename")
        return name
    }

    fun close() { worker.shutdown() }
}
