package com.example.moji_todo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class TimerService : Service() {
    companion object {
        const val CHANNEL_ID = "timer_channel_id"
        const val NOTIFICATION_ID = 1
        const val ACTION_PAUSE = "com.example.moji_todo.PAUSE"
        const val ACTION_RESUME = "com.example.moji_todo.RESUME"
        const val ACTION_STOP = "com.example.moji_todo.STOP"

        var timerSeconds: Int = 0
        var isRunning: Boolean = false
        var isPaused: Boolean = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}")
        when (intent?.action) {
            "START", "UPDATE" -> {
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds > 0) { // Chỉ cập nhật nếu timerSeconds hợp lệ
                    Companion.timerSeconds = newSeconds
                }
                Companion.isRunning = intent.getBooleanExtra("isRunning", false)
                Companion.isPaused = intent.getBooleanExtra("isPaused", false)
                Log.d("TimerService", "START/UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                updateNotification()
                sendTimerUpdateBroadcast()
            }
            ACTION_PAUSE -> {
                Log.d("TimerService", "PAUSE action received")
                if (Companion.isRunning && !Companion.isPaused) {
                    Companion.isPaused = true
                    updateNotification()
                    sendTimerUpdateBroadcast()
                } else {
                    Log.w("TimerService", "Cannot pause: isRunning=$isRunning, isPaused=$isPaused")
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (Companion.isRunning && Companion.isPaused) {
                    Companion.isPaused = false
                    updateNotification()
                    sendTimerUpdateBroadcast()
                } else {
                    Log.w("TimerService", "Cannot resume: isRunning=$isRunning, isPaused=$isPaused")
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                Companion.isRunning = false
                Companion.isPaused = false
                Companion.timerSeconds = 0
                stopForeground(true)
                stopSelf()
                sendTimerUpdateBroadcast()
            }
        }
        return START_NOT_STICKY
    }

    private fun sendTimerUpdateBroadcast() {
        val intent = Intent("com.example.moji_todo.TIMER_UPDATE")
        intent.putExtra("timerSeconds", Companion.timerSeconds)
        intent.putExtra("isRunning", Companion.isRunning)
        intent.putExtra("isPaused", Companion.isPaused)
        Log.d("TimerService", "Sending broadcast: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
        sendBroadcast(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for Pomodoro timer"
                setSound(null, null) // Tắt âm thanh mặc định của thông báo
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Pomodoro Timer")
        .setContentText(getTimeDisplay())
        .setSmallIcon(android.R.drawable.ic_notification_overlay)
        .setOngoing(Companion.isRunning)
        .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        .setContentIntent(createContentIntent())
        .setOnlyAlertOnce(true) // Chỉ phát âm thanh một lần khi thông báo được tạo
        .setSound(null) // Tắt âm thanh thông báo
        .addAction(createAction("Pause", ACTION_PAUSE))
        .addAction(createAction("Resume", ACTION_RESUME))
        .addAction(createAction("Stop", ACTION_STOP))
        .build()

    private fun updateNotification() {
        if (!Companion.isRunning && !Companion.isPaused) return
        val notification = createNotification()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun getTimeDisplay(): String {
        val minutes = (Companion.timerSeconds / 60).toString().padStart(2, '0')
        val seconds = (Companion.timerSeconds % 60).toString().padStart(2, '0')
        return "Time remaining: $minutes:$seconds (${if (Companion.isRunning) if (Companion.isPaused) "Paused" else "Running" else "Stopped"})"
    }

    private fun createContentIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            action = "com.example.moji_todo.NOTIFICATION_ACTION"
        }
        return PendingIntent.getActivity(
            this,
            0,
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun createAction(title: String, action: String): NotificationCompat.Action {
        val intent = Intent(this, TimerService::class.java).apply {
            this.action = action
        }
        val pendingIntent = PendingIntent.getService(
            this,
            action.hashCode(),
            intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Action.Builder(0, title, pendingIntent).build()
    }

    override fun onDestroy() {
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}