package com.example.songs_cleaner

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.provider.MediaStore
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.File
import java.util.concurrent.Executors

/**
 * Plays the persisted session without a Flutter engine.
 *
 * Android routes Bluetooth and Samsung Modes and Routines media commands here
 * through [ColdStartMediaButtonReceiver] even after the app process was killed,
 * so the routine works while the app is closed. The player always resumes the
 * exact persisted position and publishes metadata plus transport controls, so
 * Samsung/Bluetooth treat it as a real, controllable media session.
 *
 * While the Flutter UI is alive it owns the media session; once the UI opens,
 * [handoff] stops this native source and returns its live position so the
 * Flutter player adopts playback seamlessly instead of playing a second stream.
 */
class RoutinePlaybackService : Service() {
    private lateinit var mediaSession: MediaSessionCompat
    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var loading = false
    private var player: MediaPlayer? = null
    private var resumePoint: ResumePoint? = null
    private var prepared = false

    /** Set once Flutter takes over so an in-flight native load cannot start. */
    private var handedOff = false

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        mediaSession = MediaSessionCompat(this, "routine-playback").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                    MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS,
            )
            setCallback(
                object : MediaSessionCompat.Callback() {
                    override fun onPlay() = startPlayback()
                    override fun onPause() = pausePlayback()
                    override fun onStop() = stopPlayback()
                    override fun onSeekTo(pos: Long) = seekTo(pos)
                },
            )
            isActive = true
        }
        try {
            startForeground(NOTIFICATION_ID, createNotification(playing = false))
        } catch (_: Exception) {
            // Android 12+ can reject background foreground-service starts.
            stopSelf()
            return
        }
        publishPlaybackState(playing = false)
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_PLAY -> startPlayback()
            ACTION_PAUSE -> pausePlayback()
            ACTION_STOP -> stopPlayback()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        instance = null
        worker.shutdownNow()
        releasePlayer()
        mediaSession.release()
        super.onDestroy()
    }

    // ---------------------------------------------------------------------------
    // Playback
    // ---------------------------------------------------------------------------

    private fun startPlayback() {
        val current = player
        if (current != null && prepared) {
            try {
                if (!current.isPlaying) {
                    current.start()
                    publishPlaybackState(playing = true)
                }
            } catch (_: IllegalStateException) {
                releasePlayer()
            }
            return
        }
        if (loading) return
        loading = true
        worker.execute {
            val point = readResumePoint()
            Log.i(LOG_TAG, "Resume point resolved: ${point != null}")
            mainHandler.post {
                loading = false
                if (handedOff) return@post
                if (point != null) {
                    prepareAndPlay(point)
                } else {
                    publishPlaybackState(playing = false)
                }
            }
        }
    }

    private fun prepareAndPlay(point: ResumePoint) {
        resumePoint = point
        try {
            player = MediaPlayer().apply {
                setWakeMode(this@RoutinePlaybackService, PowerManager.PARTIAL_WAKE_LOCK)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                setDataSource(point.path)
                setOnPreparedListener { mediaPlayer ->
                    if (handedOff) {
                        mediaPlayer.release()
                        return@setOnPreparedListener
                    }
                    prepared = true
                    val start = point.positionMs
                    if (start > 0 && (mediaPlayer.duration <= 0 || start < mediaPlayer.duration)) {
                        mediaPlayer.seekTo(start)
                    }
                    mediaPlayer.start()
                    Log.i(LOG_TAG, "Native playback started at $start ms")
                    publishPlaybackState(playing = true)
                }
                setOnCompletionListener {
                    releasePlayer()
                    publishPlaybackState(playing = false)
                }
                setOnErrorListener { _, what, extra ->
                    Log.e(LOG_TAG, "Native player error what=$what extra=$extra")
                    releasePlayer()
                    publishPlaybackState(playing = false)
                    true
                }
                prepareAsync()
            }
        } catch (error: Exception) {
            Log.e(LOG_TAG, "Native player preparation failed", error)
            releasePlayer()
            publishPlaybackState(playing = false)
        }
    }

    private fun pausePlayback() {
        try {
            player?.pause()
        } catch (_: IllegalStateException) {
            releasePlayer()
        }
        publishPlaybackState(playing = false)
    }

    private fun stopPlayback() {
        releasePlayer()
        publishPlaybackState(playing = false)
        stopSelf()
    }

    private fun seekTo(positionMs: Long) {
        if (!prepared) return
        try {
            player?.seekTo(positionMs.toInt())
            publishPlaybackState(playing = player?.isPlaying == true)
        } catch (_: IllegalStateException) {
            releasePlayer()
        }
    }

    private fun releasePlayer() {
        prepared = false
        player?.release()
        player = null
    }

    private fun currentPosition(): Long {
        if (!prepared) return PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN
        return try {
            player?.currentPosition?.toLong()
                ?: PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN
        } catch (_: IllegalStateException) {
            PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN
        }
    }

    /**
     * Returns the live position and stops native playback so Flutter can adopt
     * the session. Returns null when this service was not actively playing.
     */
    fun handoff(): Map<String, Any>? {
        val current = player
        if (current == null && !loading) {
            // Merely armed: leave the session in place for the next routine.
            return null
        }
        handedOff = true
        val point = resumePoint
        val playing = current != null && point != null && try {
            prepared && current.isPlaying
        } catch (_: IllegalStateException) {
            false
        }
        val info = if (playing && current != null && point != null) {
            val position = try {
                current.currentPosition
            } catch (_: IllegalStateException) {
                0
            }
            mapOf<String, Any>("path" to point.path, "positionMs" to position)
        } else {
            null
        }
        releasePlayer()
        publishPlaybackState(playing = false)
        stopForegroundCompat()
        stopSelf()
        return info
    }

    private fun publishPlaybackState(playing: Boolean) {
        val point = resumePoint
        if (point != null) {
            mediaSession.setMetadata(
                MediaMetadataCompat.Builder()
                    .putString(MediaMetadataCompat.METADATA_KEY_TITLE, point.title)
                    .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, point.artist)
                    .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, point.album)
                    .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, point.durationMs)
                    .build(),
            )
        }
        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setActions(
                    PlaybackStateCompat.ACTION_PLAY or
                        PlaybackStateCompat.ACTION_PLAY_PAUSE or
                        PlaybackStateCompat.ACTION_PAUSE or
                        PlaybackStateCompat.ACTION_STOP or
                        PlaybackStateCompat.ACTION_SEEK_TO,
                )
                .setState(
                    if (playing) PlaybackStateCompat.STATE_PLAYING
                    else PlaybackStateCompat.STATE_PAUSED,
                    currentPosition(),
                    1f,
                )
                .build(),
        )
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, createNotification(playing))
    }

    // ---------------------------------------------------------------------------
    // Session resolution
    // ---------------------------------------------------------------------------

    private fun readResumePoint(): ResumePoint? {
        val raw = getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)
            .getString(FLUTTER_PLAYBACK_SESSION_KEY, null)
        if (raw != null) {
            try {
                val session = JSONObject(raw)
                val currentId = session.optInt("currentSongId", -1)
                val positionMs = session.optInt("positionMs", 0)
                val tracks = session.optJSONArray("tracks")
                if (tracks != null) {
                    for (index in 0 until tracks.length()) {
                        val track = tracks.optJSONObject(index) ?: continue
                        if (track.optInt("id", -1) != currentId) continue
                        val path = track.optString("path")
                        if (path.isNotBlank() && File(path).isFile) {
                            return ResumePoint(
                                path = path,
                                positionMs = positionMs.coerceAtLeast(0),
                                title = track.optString("title"),
                                artist = track.optString("artist"),
                                album = track.optString("album"),
                                durationMs = track.optLong("durationMs", 0L),
                            )
                        }
                    }
                }
            } catch (error: Exception) {
                Log.w(LOG_TAG, "Failed to read persisted session", error)
            }
        }
        return newestTrackPoint()
    }

    private fun newestTrackPoint(): ResumePoint? {
        val cursor = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            arrayOf(
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
            ),
            null,
            null,
            "${MediaStore.Audio.Media.DATE_ADDED} DESC",
        ) ?: return null
        cursor.use {
            while (it.moveToNext()) {
                val path = it.getString(0) ?: continue
                if (!File(path).isFile) continue
                return ResumePoint(
                    path = path,
                    positionMs = 0,
                    title = it.getString(1) ?: "",
                    artist = it.getString(2) ?: "",
                    album = it.getString(3) ?: "",
                    durationMs = it.getLong(4),
                )
            }
        }
        return null
    }

    // ---------------------------------------------------------------------------
    // Notification
    // ---------------------------------------------------------------------------

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                applicationInfo.loadLabel(packageManager),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    private fun createNotification(playing: Boolean): Notification {
        val contentIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PENDING_INTENT_FLAGS,
        )
        val toggleIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, RoutinePlaybackService::class.java).setAction(
                if (playing) ACTION_PAUSE else ACTION_START_PLAY,
            ),
            PENDING_INTENT_FLAGS,
        )
        val point = resumePoint
        val title = point?.title?.takeIf { it.isNotBlank() }
            ?: applicationInfo.loadLabel(packageManager).toString()
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notif_applogo)
            .setContentTitle(title)
            .setContentIntent(contentIntent)
            .setOngoing(playing)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(
                if (playing) android.R.drawable.ic_media_pause
                else android.R.drawable.ic_media_play,
                getString(
                    if (playing) R.string.routine_playback_pause
                    else R.string.routine_playback_play,
                ),
                toggleIntent,
            )
            .setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0),
            )
        point?.artist?.takeIf { it.isNotBlank() }?.let(builder::setContentText)
        return builder.build()
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    private data class ResumePoint(
        val path: String,
        val positionMs: Int,
        val title: String,
        val artist: String,
        val album: String,
        val durationMs: Long,
    )

    companion object {
        private const val CHANNEL_ID = "com.example.songs_cleaner.routine-playback"
        const val ACTION_START_PLAY =
            "com.example.songs_cleaner.action.START_ROUTINE_PLAYBACK"
        const val ACTION_PAUSE =
            "com.example.songs_cleaner.action.PAUSE_ROUTINE_PLAYBACK"
        const val ACTION_STOP =
            "com.example.songs_cleaner.action.STOP_ROUTINE_PLAYBACK"
        private const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
        private const val FLUTTER_PLAYBACK_SESSION_KEY =
            "flutter.playback.session.snapshot.v2"
        private const val NOTIFICATION_ID = 811
        private const val LOG_TAG = "RoutinePlayback"
        private const val PENDING_INTENT_FLAGS =
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

        /** Live instance so MainActivity can hand playback back to Flutter. */
        @Volatile
        var instance: RoutinePlaybackService? = null
            private set
    }
}
