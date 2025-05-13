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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

interface TimerStrategy {
    fun tick(currentSeconds: Int): Int
    fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String
}

class CountUpStrategy : TimerStrategy {
    override fun tick(currentSeconds: Int): Int = currentSeconds + 1
    override fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String {
        val minutes = (seconds / 60).toString().padStart(2, '0')
        val secondsStr = (seconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) if (isPaused) "Paused" else "Counting Up" else "Stopped"
        return "Time: $minutes:$secondsStr ($status)"
    }
}

class CountDownStrategy : TimerStrategy {
    override fun tick(currentSeconds: Int): Int = if (currentSeconds > 0) currentSeconds - 1 else 0
    override fun getDisplayText(seconds: Int, isRunning: Boolean, isPaused: Boolean): String {
        val minutes = (seconds / 60).toString().padStart(2, '0')
        val secondsStr = (seconds % 60).toString().padStart(2, '0')
        val status = if (isRunning) if (isPaused) "Paused" else "Running" else "Stopped"
        return "Time: $minutes:$secondsStr ($status)"
    }
}

data class TimerState(
    val timerSeconds: Int,
    val isRunning: Boolean,
    val isPaused: Boolean,
    val isCountingUp: Boolean
)

class TimerService : Service() {
    companion object {
        const val CHANNEL_ID = "timer_channel_id"
        const val NOTIFICATION_ID = 1
        const val ACTION_PAUSE = "com.example.moji_todo.PAUSE"
        const val ACTION_RESUME = "com.example.moji_todo.RESUME"
        const val ACTION_STOP = "com.example.moji_todo.STOP"
    }

    private var timerSeconds: Int = 0
    private var isRunning: Boolean = false
    private var isPaused: Boolean = false
    private var isCountingUp: Boolean = false
    private var isServiceRunning: Boolean = false
    private lateinit var timerStrategy: TimerStrategy
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null
    private val timerStateFlow = MutableStateFlow(TimerState(0, false, false, false))
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        Log.d("TimerService", "Service created")
        coroutineScope.launch {
            timerStateFlow.collect { state ->
                MainActivity.timerEvents?.success(
                    mapOf(
                        "timerSeconds" to state.timerSeconds,
                        "isRunning" to state.isRunning,
                        "isPaused" to state.isPaused,
                        "isCountingUp" to state.isCountingUp
                    )
                )
                Log.d("TimerService", "StateFlow emitted: $state")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}")
        when (intent?.action) {
            "START" -> {
                stopTimer()
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds >= 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                isCountingUp = intent.getBooleanExtra("isCountingUp", false)
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                Log.d("TimerService", "START: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp")

                if (isRunning && !isPaused) {
                    startTimer()
                } else {
                    stopTimer()
                }

                if (!isServiceRunning) {
                    val notification = createNotification()
                    startForeground(NOTIFICATION_ID, notification)
                    isServiceRunning = true
                } else {
                    updateNotification()
                }
                updateTimerState()
            }
            "UPDATE" -> {
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds >= 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                isCountingUp = intent.getBooleanExtra("isCountingUp", false)
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                Log.d("TimerService", "UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp")

                if (isRunning && !isPaused) {
                    startTimer()
                } else {
                    stopTimer()
                }
                updateNotification()
                updateTimerState()
            }
            ACTION_PAUSE -> {
                Log.d("MainActivity", "Handling PAUSE action from Flutter")
                if (isRunning && !isPaused) {
                    isPaused = true
                    stopTimer()
                    updateNotification()
                    updateTimerState()
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (isRunning && isPaused) {
                    isPaused = false
                    isRunning = true
                    startTimer()
                    updateNotification()
                    updateTimerState()
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                isRunning = false
                isPaused = false
                timerSeconds = 0
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                stopTimer()
                stopForeground(true)
                isServiceRunning = false
                updateTimerState()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startTimer() {
        stopTimer()
        timerRunnable = object : Runnable {
            override fun run() {
                if (isRunning && !isPaused) {
                    timerSeconds = timerStrategy.tick(timerSeconds)
                    if (!isCountingUp && timerSeconds == 0) {
                        isRunning = false
                        stopTimer()
                        Log.d("TimerService", "Timer stopped due to completion")
                    }
                    updateNotification()
                    updateTimerState()
                    if (isRunning) {
                        handler.postDelayed(this, 1000)
                    }
                }
            }
        }
        timerRunnable?.let {
            handler.post(it)
            updateTimerState()
            Log.d("TimerService", "Timer started with timerSeconds=$timerSeconds, isCountingUp=$isCountingUp")
        }
    }

    private fun stopTimer() {
        timerRunnable?.let { handler.removeCallbacks(it) }
        timerRunnable = null
        Log.d("TimerService", "Timer stopped")
    }

    private fun updateTimerState() {
        timerStateFlow.value = TimerState(timerSeconds, isRunning, isPaused, isCountingUp)
        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
        prefs.edit().apply {
            putInt("timerSeconds", timerSeconds)
            putBoolean("isRunning", isRunning)
            putBoolean("isPaused", isPaused)
            putBoolean("isCountingUp", isCountingUp)
            apply()
        }
        Log.d("TimerService", "Updated state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp")
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
        .setContentText(timerStrategy.getDisplayText(timerSeconds, isRunning, isPaused))
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
        coroutineScope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}