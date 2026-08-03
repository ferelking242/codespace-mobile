package com.codespace.mobile

import android.app.*
import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class CodespaceService : Service() {

    companion object {
        const val CHANNEL_ID   = "codespace_fg"
        const val NOTIF_ID     = 1001
        const val ACTION_START = "START"
        const val ACTION_STOP  = "STOP"
        private const val PREFS = "codespace_prefs"
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            releaseResources()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            saveRunning(false)
            return START_NOT_STICKY
        }

        val openIntent = Intent(this, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pending = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, CodespaceService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Codespace actif")
            .setContentText("Tap pour revenir à votre session")
            .setSmallIcon(android.R.drawable.ic_menu_edit)
            .setContentIntent(pending)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Arrêter", stopPending)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()

        startForeground(NOTIF_ID, notif)

        // Acquire WakeLock — keeps CPU awake so WebSocket stays alive
        val pm = getSystemService(PowerManager::class.java)
        if (wakeLock == null || wakeLock?.isHeld == false) {
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "CodespaceMobile:session_wake"
            ).apply { acquire(12 * 60 * 60 * 1000L) } // max 12h
        }

        // Acquire WifiLock — keeps WiFi radio alive (no radio sleep = no connection drop)
        if (wifiLock == null || wifiLock?.isHeld == false) {
            @Suppress("DEPRECATION")
            val wm = applicationContext.getSystemService(WIFI_SERVICE) as WifiManager
            wifiLock = wm.createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                "CodespaceMobile:session_wifi"
            ).apply { acquire() }
        }

        saveRunning(true)
        return START_STICKY
    }

    override fun onDestroy() {
        releaseResources()
        saveRunning(false)
        super.onDestroy()
    }

    private fun releaseResources() {
        try { if (wakeLock?.isHeld == true) wakeLock?.release() } catch (_: Exception) {}
        try { if (wifiLock?.isHeld == true) wifiLock?.release() } catch (_: Exception) {}
        wakeLock = null
        wifiLock = null
    }

    private fun saveRunning(running: Boolean) {
        getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean("service_was_running", running).apply()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL_ID,
                "Codespace Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps your Codespace running in background"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(ch)
        }
    }
}
