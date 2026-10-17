package com.example.songs_cleaner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import android.view.KeyEvent
import android.widget.RemoteViews

class NowPlayingWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        val keyCode = when (intent.action) {
            ACTION_PREVIOUS -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            ACTION_PLAY_PAUSE -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
            ACTION_NEXT -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> null
        }
        if (keyCode != null) {
            val audioManager = context.getSystemService(AudioManager::class.java)
            val event = KeyEvent(KeyEvent.ACTION_DOWN, keyCode)
            audioManager?.dispatchMediaKeyEvent(event)
            audioManager?.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        updateAll(context, manager)
    }

    companion object {
        const val PREFS = "now_playing_widget"
        const val TITLE = "title"
        const val ARTIST = "artist"
        const val SONG_ID = "song_id"

        fun updateAll(context: Context, manager: AppWidgetManager = AppWidgetManager.getInstance(context)) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_now_playing).apply {
                setTextViewText(R.id.widget_title, prefs.getString(TITLE, "Songs Cleaner"))
                setTextViewText(R.id.widget_artist, prefs.getString(ARTIST, "No song playing"))
                val songId = prefs.getInt(SONG_ID, -1)
                val artwork = loadArtwork(context, songId)
                if (artwork != null) {
                    setImageViewBitmap(R.id.widget_artwork, artwork)
                } else {
                    setImageViewResource(R.id.widget_artwork, R.drawable.ic_notif_applogo)
                }
                val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                if (launch != null) {
                    setOnClickPendingIntent(
                        R.id.widget_title,
                        PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT),
                    )
                }
                setOnClickPendingIntent(R.id.widget_previous, actionIntent(context, ACTION_PREVIOUS))
                setOnClickPendingIntent(R.id.widget_play_pause, actionIntent(context, ACTION_PLAY_PAUSE))
                setOnClickPendingIntent(R.id.widget_next, actionIntent(context, ACTION_NEXT))
            }
            manager.updateAppWidget(ComponentName(context, NowPlayingWidgetProvider::class.java), views)
        }

        private fun loadArtwork(context: Context, songId: Int): Bitmap? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || songId < 0) return null
            return runCatching {
                val songUri = ContentUris.withAppendedId(
                    MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                    songId.toLong(),
                )
                val albumId = context.contentResolver.query(
                    songUri,
                    arrayOf(MediaStore.Audio.Media.ALBUM_ID),
                    null,
                    null,
                    null,
                )?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getLong(0) else -1L
                } ?: -1L
                if (albumId < 0) return null
                val albumArtUri = Uri.parse("content://media/external/audio/albumart/$albumId")
                context.contentResolver.loadThumbnail(albumArtUri, Size(160, 160), null)
            }.getOrNull()
        }

        private fun actionIntent(context: Context, action: String): PendingIntent {
            val intent = Intent(context, NowPlayingWidgetProvider::class.java).setAction(action)
            return PendingIntent.getBroadcast(
                context,
                action.hashCode(),
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        const val ACTION_PREVIOUS = "com.example.songs_cleaner.widget.PREVIOUS"
        const val ACTION_PLAY_PAUSE = "com.example.songs_cleaner.widget.PLAY_PAUSE"
        const val ACTION_NEXT = "com.example.songs_cleaner.widget.NEXT"
    }
}
