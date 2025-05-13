package com.example.moji_todo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import android.util.Log

class TimerService : Service() {
    companion object {
        const val CHANNEL_ID = "timer_channel_id"
        const val NOTIFICATION_ID = 1
        const val ACTION_PAUSE = "com.example.moji_todo.PAUSE"
        const val ACTION_RESUME = "com.example.moji_todo.RESUME"
        const val ACTION_STOP = "com.example.moji_todo.STOP"
        private var isServiceRunning = false
    }

    private var timerSeconds: Int = 0
    private var isRunning: Boolean = false
    private var isPaused: Boolean = false
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("TimerService", "Service created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}")
        when (intent?.action) {
            "START" -> {
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds > 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                Log.d("TimerService", "START: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                if (isRunning && !isPaused) startTimer()
                else stopTimer()
                if (!isServiceRunning) {
                    val notification = createNotification()
                    startForeground(NOTIFICATION_ID, notification)
                    isServiceRunning = true
                } else {
                    updateNotification()
                }
                sendTimerUpdateBroadcast()
            }
            "UPDATE" -> {
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds > 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                Log.d("TimerService", "UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                if (isRunning && !isPaused) startTimer()
                else stopTimer()
                updateNotification()
                sendTimerUpdateBroadcast()
            }
            ACTION_PAUSE -> {
                Log.d("TimerService", "PAUSE action received")
                if (isRunning && !isPaused) {
                    isPaused = true
                    stopTimer()
                    updateNotification()
                    sendTimerUpdateBroadcast()
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (isRunning && isPaused) {
                    isPaused = false
                    isRunning = true // Ensure isRunning is true on resume
                    startTimer() // Restart the timer
                    updateNotification()
                    sendTimerUpdateBroadcast() // Immediate broadcast
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                isRunning = false
                isPaused = false
                timerSeconds = 0
                stopTimer()
                stopForeground(true)
                stopSelf()
                isServiceRunning = false
                sendTimerUpdateBroadcast()
            }
        }
        return START_NOT_STICKY
    }

    private fun startTimer() {
        stopTimer() // Clear any existing timer
        timerRunnable = object : Runnable {
            override fun run() {
                if (isRunning && !isPaused && timerSeconds > 0) {
                    timerSeconds--
                    updateNotification()
                    sendTimerUpdateBroadcast()
                    handler.postDelayed(this, 1000)
                } else if (timerSeconds <= 0) {
                    isRunning = false
                    sendTimerUpdateBroadcast()
                }
            }
        }
        timerRunnable?.let {
            handler.post(it)
            sendTimerUpdateBroadcast() // Immediate update on start
        }
    }

    private fun stopTimer() {
        timerRunnable?.let { handler.removeCallbacks(it) }
        timerRunnable = null
    }

    private fun sendTimerUpdateBroadcast() {
        val intent = Intent().apply {
            setComponent(ComponentName(this@TimerService, TimerBroadcastReceiver::class.java))
            action = "com.example.moji_todo.TIMER_UPDATE"
            putExtra("timerSeconds", timerSeconds)
            putExtra("isRunning", isRunning)
            putExtra("isPaused", isPaused)
        }
        sendBroadcast(intent)

        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
        prefs.edit().apply {
            putInt("timerSeconds", timerSeconds)
            putBoolean("isRunning", isRunning)
            putBoolean("isPaused", isPaused)
            apply()
        }
        Log.d("TimerService", "Broadcast sent: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Timer Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply { setSound(null, null) }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Pomodoro Timer")
        .setContentText(getTimeDisplay())
        .setSmallIcon(android.R.drawable.ic_notification_overlay)
        .setOngoing(isRunning && !isPaused)
        .setContentIntent(createContentIntent())
        .setOnlyAlertOnce(true)
        .setSound(null)
        .apply {
            if (isRunning && !isPaused) {
                addAction(createAction("Pause", ACTION_PAUSE))
                addAction(createAction("Stop", ACTION_STOP))
            } else if (isRunning && isPaused) {
                addAction(createAction("Resume", ACTION_RESUME))
                addAction(createAction("Stop", ACTION_STOP))
            }
        }
        .build()

    private fun updateNotification() {
        if (!isServiceRunning) return
        val notification = createNotification()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun getTimeDisplay(): String {
        val minutes = (timerSeconds / 60).toString().padStart(2, '0')
        val seconds = (timerSeconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) if (isPaused) "Paused" else "Running" else "Stopped"
        return "Time remaining: $minutes:$seconds ($status)"
    }

    private fun createContentIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
        return PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    private fun createAction(title: String, action: String): NotificationCompat.Action {
        val intent = Intent(this, TimerService::class.java).apply { this.action = action }
        val pendingIntent = PendingIntent.getService(
            this, action.hashCode(), intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            else PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Action.Builder(0, title, pendingIntent).build()
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTimer()
        isServiceRunning = false
    }

    override fun onBind(intent: Intent?): IBinder? = null
}