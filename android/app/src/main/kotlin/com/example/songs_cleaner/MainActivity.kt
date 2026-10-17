package com.example.songs_cleaner

import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.os.Bundle
import android.provider.MediaStore
import android.provider.Settings
import android.media.RingtoneManager
import androidx.core.content.FileProvider
import java.io.File
import android.net.Uri
import java.io.IOException
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        LockScreenController.onActivityCreated(this)
        // A cold start triggered by LockScreenController carries the extra that
        // asks Dart to open the lock-screen player route.
        LockScreenController.onNewIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        LockScreenController.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        LockScreenController.attach(
            this,
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                LOCK_SCREEN_CHANNEL,
            ).apply {
                setMethodCallHandler(LockScreenController::handleMethodCall)
            },
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            TAG_EDITOR_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSongTags" -> {
                    val songId = call.argument<Int>("songId")
                    if (songId == null) {
                        result.error("INVALID_ID", "Song id is required", null)
                        return@setMethodCallHandler
                    }
                    val values = ContentValues().apply {
                        put(MediaStore.Audio.Media.TITLE, call.argument<String>("title") ?: "")
                        put(MediaStore.Audio.Media.ARTIST, call.argument<String>("artist") ?: "")
                        put(MediaStore.Audio.Media.ALBUM, call.argument<String>("album") ?: "")
                        put("genre", call.argument<String>("genre") ?: "")
                        put(MediaStore.Audio.Media.COMPOSER, call.argument<String>("composer") ?: "")
                        put(MediaStore.Audio.Media.TRACK, call.argument<Int>("trackNumber") ?: 0)
                    }
                    val uri = ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        songId.toLong(),
                    )
                    result.success(contentResolver.update(uri, values, null, null) > 0)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILE_TRANSFER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveJson" -> {
                    pendingFileResult = result
                    pendingFileContent = call.argument<String>("content")
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        type = "application/json"
                        putExtra(Intent.EXTRA_TITLE, call.argument<String>("fileName") ?: "playlists.json")
                    }
                    startActivityForResult(intent, SAVE_FILE_REQUEST)
                }
                "openJson" -> {
                    pendingFileResult = result
                    startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            type = "application/json"
                            addCategory(Intent.CATEGORY_OPENABLE)
                        },
                        OPEN_FILE_REQUEST,
                    )
                }
                "shareJsonFile" -> {
                    val exportDirectory = File(cacheDir, "playlist_exports").apply { mkdirs() }
                    val exportFile = File(exportDirectory, "songs_cleaner_playlists.json")
                    exportFile.writeText(call.argument<String>("content") ?: "", Charsets.UTF_8)
                    val fileUri = FileProvider.getUriForFile(
                        this,
                        "$packageName.fileprovider",
                        exportFile,
                    )
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "application/json"
                        putExtra(Intent.EXTRA_SUBJECT, call.argument<String>("title") ?: "Playlists")
                        putExtra(Intent.EXTRA_STREAM, fileUri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(shareIntent, "Share playlists"))
                    result.success(true)
                }
                "shareSong" -> {
                    val songId = call.argument<Int>("songId")
                    if (songId == null) {
                        result.error("INVALID_ID", "Song id is required", null)
                        return@setMethodCallHandler
                    }
                    val songUri = ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        songId.toLong(),
                    )
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "audio/*"
                        putExtra(Intent.EXTRA_STREAM, songUri)
                        putExtra(Intent.EXTRA_TITLE, call.argument<String>("title") ?: "Song")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    startActivity(Intent.createChooser(shareIntent, "Share song"))
                    result.success(true)
                }
                "setAsRingtone" -> {
                    val songId = call.argument<Int>("songId")
                    if (songId == null) {
                        result.error("INVALID_ID", "Song id is required", null)
                        return@setMethodCallHandler
                    }
                    if (!Settings.System.canWrite(this)) {
                        startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
                            data = Uri.parse("package:$packageName")
                        })
                        result.error("WRITE_SETTINGS_REQUIRED", "System settings permission is required", null)
                        return@setMethodCallHandler
                    }
                    val songUri = ContentUris.withAppendedId(
                        MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                        songId.toLong(),
                    )
                    val values = ContentValues().apply {
                        put(MediaStore.Audio.Media.IS_RINGTONE, 1)
                        put(MediaStore.Audio.Media.TITLE, call.argument<String>("title") ?: "Song")
                    }
                    if (contentResolver.update(songUri, values, null, null) <= 0) {
                        result.error("RINGTONE_FAILED", "Song could not be updated", null)
                        return@setMethodCallHandler
                    }
                    RingtoneManager.setActualDefaultRingtoneUri(
                        this,
                        RingtoneManager.TYPE_RINGTONE,
                        songUri,
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOW_PLAYING_WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "update") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            getSharedPreferences(NowPlayingWidgetProvider.PREFS, MODE_PRIVATE)
                .edit()
                .putString(NowPlayingWidgetProvider.TITLE, call.argument<String>("title"))
                .putString(NowPlayingWidgetProvider.ARTIST, call.argument<String>("artist"))
                .putInt(NowPlayingWidgetProvider.SONG_ID, call.argument<Int>("songId") ?: -1)
                .apply()
            NowPlayingWidgetProvider.updateAll(this)
            result.success(null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        val result = pendingFileResult ?: return
        pendingFileResult = null
        if (resultCode != RESULT_OK || data?.data == null) {
            pendingFileContent = null
            result.success(if (requestCode == SAVE_FILE_REQUEST) false else null)
            return
        }
        try {
            if (requestCode == SAVE_FILE_REQUEST) {
                contentResolver.openOutputStream(data.data!!)?.use { output ->
                    output.write((pendingFileContent ?: "").toByteArray(Charsets.UTF_8))
                } ?: throw IOException("Unable to open output")
                result.success(true)
            } else if (requestCode == OPEN_FILE_REQUEST) {
                val content = contentResolver.openInputStream(data.data!!)?.use {
                    it.readBytes().toString(Charsets.UTF_8)
                } ?: throw IOException("Unable to open input")
                result.success(content)
            }
        } catch (error: IOException) {
            result.error("FILE_TRANSFER_FAILED", error.message, null)
        } finally {
            pendingFileContent = null
        }
    }

    override fun onDestroy() {
        LockScreenController.detach(this)
        super.onDestroy()
    }

    private companion object {
        const val LOCK_SCREEN_CHANNEL =
            "com.example.songs_cleaner/lock_screen"
        const val TAG_EDITOR_CHANNEL =
            "com.example.songs_cleaner/tag_editor"
        const val FILE_TRANSFER_CHANNEL =
            "com.example.songs_cleaner/file_transfer"
        const val SAVE_FILE_REQUEST = 4101
        const val OPEN_FILE_REQUEST = 4102
        const val NOW_PLAYING_WIDGET_CHANNEL =
            "com.example.songs_cleaner/now_playing_widget"
    }

    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingFileContent: String? = null
}
