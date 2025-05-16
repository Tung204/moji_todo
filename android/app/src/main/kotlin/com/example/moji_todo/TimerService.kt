package com.example.moji_todo

import android.app.Service
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

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
        const val ACTION_PAUSE = "com.example.moji_todo.PAUSE"
        const val ACTION_RESUME = "com.example.moji_todo.RESUME"
        const val ACTION_STOP = "com.example.moji_todo.STOP"
        const val ACTION_OPEN_APP = "com.example.moji_todo.OPEN_APP"
        const val TIMER_NOTIFICATION_ID = 100
    }

    private var timerSeconds: Int = 0
    private var isRunning: Boolean = false
    private var isPaused: Boolean = false
    private var isCountingUp: Boolean = false
    private var isServiceRunning: Boolean = false
    private var hasEnded: Boolean = false
    private var isWorkSession: Boolean = true
    private var hasSentEndNotification: Boolean = false
    private lateinit var timerStrategy: TimerStrategy
    private val handler = Handler(Looper.getMainLooper())
    private var timerRunnable: Runnable? = null
    private val timerStateFlow = MutableStateFlow(TimerState(0, false, false, false))
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
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
                updateNotification(state.timerSeconds, state.isRunning, state.isPaused)
                Log.d("TimerService", "StateFlow emitted: $state")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("TimerService", "Received intent: ${intent?.action}")
        when (intent?.action) {
            "START" -> {
                if (isServiceRunning) {
                    Log.d("TimerService", "Service already running, ignoring START")
                    return START_NOT_STICKY
                }
                stopTimer()
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds >= 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                isCountingUp = intent.getBooleanExtra("isCountingUp", false)
                isWorkSession = true
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                hasEnded = false
                hasSentEndNotification = false
                Log.d("TimerService", "START: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp")

                if (isRunning && !isPaused) {
                    startTimer()
                } else {
                    stopTimer()
                }

                if (!isServiceRunning) {
                    startForegroundService()
                    isServiceRunning = true
                }
                updateTimerState()
            }
            "UPDATE" -> {
                val newSeconds = intent.getIntExtra("timerSeconds", 0)
                if (newSeconds >= 0) timerSeconds = newSeconds
                isRunning = intent.getBooleanExtra("isRunning", false)
                isPaused = intent.getBooleanExtra("isPaused", false)
                isCountingUp = intent.getBooleanExtra("isCountingUp", false)
                val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                isWorkSession = prefs.getBoolean("isWorkSession", true)
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                hasEnded = false
                hasSentEndNotification = false
                Log.d("TimerService", "UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession")

                if (isRunning && !isPaused) {
                    startTimer()
                } else {
                    stopTimer()
                }
                updateTimerState()
            }
            ACTION_PAUSE -> {
                Log.d("TimerService", "PAUSE action received")
                if (isRunning && !isPaused) {
                    isPaused = true
                    stopTimer()
                    updateTimerState()
                }
            }
            ACTION_RESUME -> {
                Log.d("TimerService", "RESUME action received")
                if (isRunning && isPaused) {
                    isPaused = false
                    isRunning = true
                    startTimer()
                    updateTimerState()
                }
            }
            ACTION_STOP -> {
                Log.d("TimerService", "STOP action received")
                isRunning = false
                isPaused = false
                timerSeconds = if (isCountingUp) 0 else 25 * 60
                timerStrategy = if (isCountingUp) CountUpStrategy() else CountDownStrategy()
                hasEnded = false
                hasSentEndNotification = false
                stopTimer()
                isServiceRunning = false
                updateTimerState()
                NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
                stopSelf()
            }
            ACTION_OPEN_APP -> {
                Log.d("TimerService", "OPEN_APP action received")
            }
        }
        return START_NOT_STICKY
    }

    private fun startForegroundService() {
        try {
            val notification = NotificationCompat.Builder(this, "timer_channel_id")
                .setContentTitle("Pomodoro Timer")
                .setContentText("Starting...")
                .setSmallIcon(android.R.drawable.ic_notification_overlay)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOngoing(true)
                .build()
            startForeground(TIMER_NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e("TimerService", "Failed to start foreground service: ${e.message}")
            stopSelf()
        }
    }

    private fun updateNotification(seconds: Int, isRunning: Boolean, isPaused: Boolean) {
        try {
            val minutes = (seconds / 60).toString().padStart(2, '0')
            val secondsStr = (seconds % 60).toString().padStart(2, '0')
            val notification = NotificationCompat.Builder(this, "timer_channel_id")
                .setContentTitle("Pomodoro Timer")
                .setContentText("Time: $minutes:$secondsStr (${isRunning ? isPaused ? "Paused" : "Running" : "Stopped"})")
                .setSmallIcon(android.R.drawable.ic_notification_overlay)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setOngoing(isRunning && !isPaused)
                .addAction(
                    if (isRunning && !isPaused) R.drawable.ic_pause else R.drawable.ic_play,
                    if (isRunning && !isPaused) "Pause" else "Resume",
                    Intent(this, TimerService::class.java).apply {
                        action = if (isRunning && !isPaused) ACTION_PAUSE else ACTION_RESUME
                    }.let { intent ->
                        android.app.PendingIntent.getService(
                            this, 0, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )
                    }
                )
                .addAction(
                    R.drawable.ic_stop,
                    "Stop",
                    Intent(this, TimerService::class.java).apply {
                        action = ACTION_STOP
                    }.let { intent ->
                        android.app.PendingIntent.getService(
                            this, 1, intent, android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )
                    }
                )
                .build()
            NotificationManagerCompat.from(this).notify(TIMER_NOTIFICATION_ID, notification)
            Log.d("TimerService", "Timer notification updated")
        } catch (e: Exception) {
            Log.e("TimerService", "Failed to update notification: ${e.message}")
        }
    }

    private fun startTimer() {
        stopTimer()
        timerRunnable = object : Runnable {
            override fun run() {
                if (isRunning && !isPaused) {
                    timerSeconds = timerStrategy.tick(timerSeconds)
                    if (!isCountingUp && timerSeconds == 0 && !hasEnded && !hasSentEndNotification) {
                        hasEnded = true
                        isRunning = false
                        stopTimer()
                        showEndSessionNotification()
                        updateTimerState()
                        Log.d("TimerService", "Timer stopped due to completion")
                    } else if (!hasEnded) {
                        updateTimerState()
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
            putBoolean("isWorkSession", isWorkSession)
            putBoolean("isServiceRunning", isServiceRunning)
            apply()
        }
        Log.d("TimerService", "Updated state: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused, isCountingUp=$isCountingUp, isWorkSession=$isWorkSession")
    }

    private fun showEndSessionNotification() {
        if (!hasSentEndNotification) {
            val intent = Intent("com.example.moji_todo.SHOW_END_SESSION").apply {
                putExtra("isWorkSession", isWorkSession)
            }
            sendBroadcast(intent)
            hasSentEndNotification = true
            Log.d("TimerService", "Sent SHOW_END_SESSION broadcast: isWorkSession=$isWorkSession")
        } else {
            Log.d("TimerService", "End session notification already sent, ignoring")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopTimer()
        isServiceRunning = false
        hasSentEndNotification = false
        coroutineScope.cancel()
        NotificationManagerCompat.from(this).cancel(TIMER_NOTIFICATION_ID)
        Log.d("TimerService", "Service destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}