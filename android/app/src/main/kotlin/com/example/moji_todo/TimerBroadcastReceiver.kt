package com.example.moji_todo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class TimerBroadcastReceiver : BroadcastReceiver() {
    private var methodChannel: MethodChannel? = null

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.moji_todo.TIMER_UPDATE") {
            val timerSeconds = intent.getIntExtra("timerSeconds", 0)
            val isRunning = intent.getBooleanExtra("isRunning", false)
            val isPaused = intent.getBooleanExtra("isPaused", false)

            // Gửi trạng thái timer về Flutter qua MethodChannel
            methodChannel?.invokeMethod("updateTimer", mapOf(
                "timerSeconds" to timerSeconds,
                "isRunning" to isRunning,
                "isPaused" to isPaused
            ))
        }
    }

    fun setMethodChannel(channel: MethodChannel) {
        this.methodChannel = channel
    }
}