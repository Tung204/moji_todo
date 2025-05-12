package com.example.moji_todo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import android.util.Log

class TimerBroadcastReceiver : BroadcastReceiver() {
    private var methodChannel: MethodChannel? = null

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.moji_todo.TIMER_UPDATE") {
            val timerSeconds = intent.getIntExtra("timerSeconds", 0)
            val isRunning = intent.getBooleanExtra("isRunning", false)
            val isPaused = intent.getBooleanExtra("isPaused", false)

            Log.d("TimerBroadcastReceiver", "onReceive: action=${intent.action}")

            val data = mapOf(
                "timerSeconds" to timerSeconds,
                "isRunning" to isRunning,
                "isPaused" to isPaused
            )
            MainActivity.timerEvents?.success(data)

            Log.d("TimerBroadcastReceiver", "Sending timer update to Flutter: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
        }
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
}