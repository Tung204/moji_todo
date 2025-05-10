package com.example.moji_todo

import android.app.Notification
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
        var isServiceRunning = false // Biến để theo dõi trạng thái service
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        isServiceRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}")
        when (intent?.action) {
            ACTION_START, ACTION_UPDATE -> {
                val timerSeconds = intent.getIntExtra("timerSeconds", 0)
                val isRunning = intent.getBooleanExtra("isRunning", false)
                val isPaused = intent.getBooleanExtra("isPaused", false)
                Log.d("TimerService", "START/UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                Companion.timerSeconds = timerSeconds
                Companion.isRunning = isRunning
                Companion.isPaused = isPaused
                updateNotification()
                sendTimerUpdateBroadcast()
                // Lưu trạng thái vào SharedPreferences
                val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                prefs.edit().apply {
                    putInt("timerSeconds", timerSeconds)
                    putBoolean("isRunning", isRunning)
                    putBoolean("isPaused", isPaused)
                    apply()
                }
            }
            ACTION_PAUSE -> {
                Log.d("TimerService", "PAUSE action received")
                if (Companion.isRunning && !Companion.isPaused) {
                    Companion.isRunning = false
                    Companion.isPaused = true
                    updateNotification()
                    sendTimerUpdateBroadcast()
                    // Lưu trạng thái vào SharedPreferences
                    val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                    prefs.edit().apply {
                        putInt("timerSeconds", Companion.timerSeconds)
                        putBoolean("isRunning", false)
                        putBoolean("isPaused", true)
                        apply()
                    }
                } else {
                    Log.w("TimerService", "Cannot pause: isRunning=$isRunning, isPaused=$isPaused")
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (Companion.isPaused) {
                    Companion.isRunning = true
                    Companion.isPaused = false
                    updateNotification()
                    sendTimerUpdateBroadcast()
                    // Lưu trạng thái vào SharedPreferences
                    val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                    prefs.edit().apply {
                        putInt("timerSeconds", Companion.timerSeconds)
                        putBoolean("isRunning", true)
                        putBoolean("isPaused", false)
                        apply()
                    }
                } else {
                    Log.w("TimerService", "Cannot resume: isRunning=$isRunning, isPaused=$isPaused")
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                Companion.isRunning = false
                Companion.isPaused = false
                Companion.timerSeconds = 0
                // Đặt isServiceRunning về false trước khi lưu trạng thái
                isServiceRunning = false
                // Lưu trạng thái vào SharedPreferences
                val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                prefs.edit().apply {
                    putInt("timerSeconds", 0)
                    putBoolean("isRunning", false)
                    putBoolean("isPaused", false)
                    apply()
                }
                // Gửi broadcast TIMER_STOPPED
                val stopIntent = Intent("com.example.moji_todo.TIMER_STOPPED").apply {
                    putExtra("timerSeconds", 0)
                    putExtra("isRunning", false)
                    putExtra("isPaused", false)
                }
                sendBroadcast(stopIntent)
                sendTimerUpdateBroadcast()
                stopForeground(true)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun sendTimerUpdateBroadcast() {
        val intent = Intent("com.example.moji_todo.TIMER_UPDATE").apply {
            putExtra("timerSeconds", timerSeconds)
            putExtra("isRunning", isRunning)
            putExtra("isPaused", isPaused)
        }
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

    private fun createNotification(): Notification {
        // Create an explicit intent for the MainActivity
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )

        // Create pause/resume action
        val actionText = if (isPaused) "Resume" else "Pause"
        val actionIntent = Intent(this, MainActivity::class.java).apply {
            action = if (isPaused) ACTION_RESUME else ACTION_PAUSE
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val actionPendingIntent = PendingIntent.getActivity(
            this,
            0,
            actionIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create stop action
        val stopIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_STOP
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val stopPendingIntent = PendingIntent.getActivity(
            this,
            0,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Format time
        val minutes = timerSeconds / 60
        val seconds = timerSeconds % 60
        val timeString = String.format("%02d:%02d", minutes, seconds)
        val statusText = if (isPaused) "Paused" else "Running"

        // Build notification
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Timer $statusText")
            .setContentText("Time remaining: $timeString")
            .setContentIntent(pendingIntent)
            .addAction(0, actionText, actionPendingIntent)
            .addAction(0, "Stop", stopPendingIntent)
            .setOngoing(true)
            .build()
    }

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
        val intent = Intent(this, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 
            action.hashCode(), 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Action.Builder(0, title, pendingIntent).build()
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceRunning = false
        // Lưu trạng thái vào SharedPreferences khi service dừng
        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
        prefs.edit().apply {
            putInt("timerSeconds", timerSeconds)
            putBoolean("isRunning", isRunning)
            putBoolean("isPaused", isPaused)
            apply()
        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
}
