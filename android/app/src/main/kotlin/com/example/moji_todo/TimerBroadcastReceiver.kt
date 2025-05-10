package com.example.moji_todo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel

class TimerBroadcastReceiver : BroadcastReceiver() {
    private var methodChannel: MethodChannel? = null

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            "com.example.moji_todo.TIMER_UPDATE" -> {
                val timerSeconds = intent.getIntExtra("timerSeconds", 0)
                val isRunning = intent.getBooleanExtra("isRunning", false)
                val isPaused = intent.getBooleanExtra("isPaused", false)
                Log.d("TimerBroadcastReceiver", "TIMER_UPDATE: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                methodChannel?.invokeMethod("updateTimer", mapOf(
                    "timerSeconds" to timerSeconds,
                    "isRunning" to isRunning,
                    "isPaused" to isPaused
                ))
            }
            "com.example.moji_todo.TIMER_STOPPED" -> {
                Log.d("TimerBroadcastReceiver", "TIMER_STOPPED received")
                methodChannel?.invokeMethod("stopTimer", mapOf(
                    "timerSeconds" to 0,
                    "isRunning" to false,
                    "isPaused" to false
                ))
            }
        }
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
}