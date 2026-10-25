package com.example.songs_cleaner

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/** Keeps an in-progress, user-started transfer visible while the UI is backgrounded. */
class TelegramDownloadService : Service() {
    private val watchdog = Handler(Looper.getMainLooper())
    private val expired = Runnable { stopSelf() }
    private val wakeLock by lazy {
        (getSystemService(POWER_SERVICE) as PowerManager).newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK, "$packageName:TelegramDownloads").apply {
            setReferenceCounted(false)
        }
    }
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        watchdog.removeCallbacks(expired)
        watchdog.postDelayed(expired, 45_000)
        wakeLock.acquire(45_000)
        val title = intent?.getStringExtra("title") ?: applicationInfo.loadLabel(packageManager).toString()
        val text = intent?.getStringExtra("text") ?: ""
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(CHANNEL, title, NotificationManager.IMPORTANCE_LOW))
        }
        val open = Intent(this, MainActivity::class.java).apply {
            action = OPEN_DOWNLOADS
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pending = PendingIntent.getActivity(this, 6102, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_notif_applogo).setContentTitle(title).setContentText(text)
            .setContentIntent(pending).setOngoing(true).setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS).build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            } else { startForeground(NOTIFICATION, notification) }
        } catch (_: Exception) {
            // Android may reject a background restart or an exhausted dataSync
            // quota. Stop cleanly; queue metadata remains available in the app.
            stopSelf()
            return START_NOT_STICKY
        }
        // Queue metadata is restored paused after process death; never pretend a
        // headless service restart recreates the Flutter/TDLib receive isolate.
        return START_NOT_STICKY
    }

    override fun onTimeout(startId: Int, fgsType: Int) { stopSelf() }
    override fun onDestroy() {
        watchdog.removeCallbacks(expired)
        if (wakeLock.isHeld) wakeLock.release()
        if (wakeLock.isHeld) wakeLock.release()
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }
    companion object {
        const val OPEN_DOWNLOADS = "com.example.songs_cleaner.OPEN_TELEGRAM_DOWNLOADS"
        private const val CHANNEL = "telegram_music_downloads"
        private const val NOTIFICATION = 6102
    }
}
