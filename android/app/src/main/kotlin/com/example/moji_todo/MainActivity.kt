package com.example.moji_todo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.content.ComponentName
import android.accessibilityservice.AccessibilityServiceInfo
import android.util.Log
import android.view.accessibility.AccessibilityManager
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import android.Manifest
import androidx.core.app.ActivityCompat

class MainActivity : FlutterActivity() {
    private val PERMISSION_CHANNEL = "com.example.moji_todo/permissions"
    private val SERVICE_CHANNEL = "com.example.moji_todo/app_block_service"
    private val NOTIFICATION_CHANNEL = "com.example.moji_todo/notification"
    private val EVENT_CHANNEL = "com.example.moji_todo/timer_events"
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private val timerBroadcastReceiver = TimerBroadcastReceiver()
    private val REQUEST_NOTIFICATION_PERMISSION = 1001
    private val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = 1002

    companion object {
        var timerEvents: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityPermissionEnabled" -> {
                    val isEnabled = isAccessibilityServiceEnabled()
                    Log.d("MainActivity", "isAccessibilityPermissionEnabled: $isEnabled")
                    result.success(isEnabled)
                }
                "requestAccessibilityPermission" -> {
                    Log.d("MainActivity", "Requesting accessibility permission")
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "openAppSettings" -> {
                    val uri = call.arguments<Map<String, Any>>()?.get("uri") as String?
                    if (uri != null) {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse(uri)
                        }
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                "checkIgnoreBatteryOptimizations" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(packageName)
                    result.success(isIgnoringBatteryOptimizations)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivityForResult(intent, REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBlockedApps" -> {
                    val apps = call.argument<List<String>>("apps")
                    Log.d("MainActivity", "setBlockedApps called with apps: $apps")
                    if (apps != null) {
                        AppBlockService.setBlockedApps(apps.toSet())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Blocked apps list is null", null)
                    }
                }
                "setAppBlockingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    Log.d("MainActivity", "setAppBlockingEnabled called with enabled: $enabled")
                    AppBlockService.setAppBlockingEnabled(enabled)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    try {
                        val arguments = call.arguments as? Map<*, *> ?: mapOf<String, Any>()
                        val action = arguments["action"] as? String ?: ""
                        val timerSeconds = (arguments["timerSeconds"] as? Number)?.toInt() ?: 0
                        val isRunning = arguments["isRunning"] as? Boolean ?: false
                        val isPaused = arguments["isPaused"] as? Boolean ?: false

                        Log.d("MainActivity", "startTimerService: action=$action, timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")

                        val intent = Intent(this, TimerService::class.java).apply {
                            this.action = action
                            putExtra("timerSeconds", timerSeconds)
                            putExtra("isRunning", isRunning)
                            putExtra("isPaused", isPaused)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                        prefs.edit().apply {
                            if (timerSeconds > 0) putInt("timerSeconds", timerSeconds)
                            putBoolean("isRunning", isRunning)
                            putBoolean("isPaused", isPaused)
                            apply()
                        }
                        Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in startTimerService: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "getTimerState" -> {
                    val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                    val state = mapOf(
                        "timerSeconds" to prefs.getInt("timerSeconds", 25 * 60),
                        "isRunning" to prefs.getBoolean("isRunning", false),
                        "isPaused" to prefs.getBoolean("isPaused", false)
                    )
                    Log.d("MainActivity", "getTimerState: $state")
                    result.success(state)
                }
                "com.example.moji_todo.PAUSE" -> {
                    try {
                        Log.d("MainActivity", "Handling PAUSE action from Flutter")
                        val intent = Intent(this, TimerService::class.java).apply {
                            action = TimerService.ACTION_PAUSE
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                        val currentSeconds = prefs.getInt("timerSeconds", 25 * 60)
                        prefs.edit().apply {
                            putInt("timerSeconds", currentSeconds)
                            putBoolean("isRunning", false)
                            putBoolean("isPaused", true)
                            apply()
                        }
                        Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$currentSeconds, isRunning=false, isPaused=true")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in PAUSE action: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "com.example.moji_todo.RESUME" -> {
                    try {
                        Log.d("MainActivity", "Handling RESUME action from Flutter")
                        val intent = Intent(this, TimerService::class.java).apply {
                            action = TimerService.ACTION_RESUME
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                        val currentSeconds = prefs.getInt("timerSeconds", 25 * 60)
                        prefs.edit().apply {
                            putInt("timerSeconds", currentSeconds)
                            putBoolean("isRunning", true)
                            putBoolean("isPaused", false)
                            apply()
                        }
                        Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$currentSeconds, isRunning=true, isPaused=false")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in RESUME action: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "com.example.moji_todo.STOP" -> {
                    try {
                        Log.d("MainActivity", "Handling STOP action from Flutter")
                        val intent = Intent(this, TimerService::class.java).apply {
                            action = TimerService.ACTION_STOP
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }

                        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
                        prefs.edit().apply {
                            putInt("timerSeconds", 25 * 60)
                            putBoolean("isRunning", false)
                            putBoolean("isPaused", false)
                            apply()
                        }
                        Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=1500, isRunning=false, isPaused=false")

                        result.success(null)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error in STOP action: ${e.message}")
                        result.error("ERROR", e.message, null)
                    }
                }
                "checkNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val hasPermission = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        Log.d("MainActivity", "checkNotificationPermission: $hasPermission")
                        result.success(hasPermission)
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                timerEvents = events
                Log.d("MainActivity", "EventChannel listener started")
            }

            override fun onCancel(arguments: Any?) {
                timerEvents = null
                Log.d("MainActivity", "EventChannel listener cancelled")
            }
        })

        handleNotificationIntent(intent)
        timerBroadcastReceiver.setMethodChannel(MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL))
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(packageName)
            methodChannel?.invokeMethod("ignoreBatteryOptimizationsResult", isIgnoringBatteryOptimizations)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_NOTIFICATION_PERMISSION) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            methodChannel?.invokeMethod("notificationPermissionResult", granted)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        Log.d("MainActivity", "Handling intent with action: ${intent?.action}")
        val prefs = getSharedPreferences("FlutterSharedPref", MODE_PRIVATE)
        if (intent?.action == TimerService.ACTION_PAUSE) {
            Log.d("MainActivity", "Pausing timer from notification")
            val timerSeconds = intent.getIntExtra("timerSeconds", prefs.getInt("timerSeconds", 25 * 60))
            methodChannel?.invokeMethod("pause", null)
            prefs.edit().apply {
                putInt("timerSeconds", timerSeconds)
                putBoolean("isRunning", false)
                putBoolean("isPaused", true)
                apply()
            }
            Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$timerSeconds, isRunning=false, isPaused=true")
        } else if (intent?.action == TimerService.ACTION_RESUME) {
            Log.d("MainActivity", "Resuming timer from notification")
            val timerSeconds = prefs.getInt("timerSeconds", 25 * 60)
            methodChannel?.invokeMethod("resume", null)
            prefs.edit().apply {
                putInt("timerSeconds", timerSeconds)
                putBoolean("isRunning", true)
                putBoolean("isPaused", false)
                apply()
            }
            Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$timerSeconds, isRunning=true, isPaused=false")
        } else if (intent?.action == TimerService.ACTION_STOP || intent?.action == "com.example.moji_todo.TIMER_STOPPED") {
            Log.d("MainActivity", "Stopping timer from notification or broadcast")
            methodChannel?.invokeMethod("stop", null)
            NotificationManagerCompat.from(this).cancel(TimerService.NOTIFICATION_ID)
            prefs.edit().apply {
                putInt("timerSeconds", 25 * 60)
                putBoolean("isRunning", false)
                putBoolean("isPaused", false)
                apply()
            }
            Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=1500, isRunning=false, isPaused=false")
        } else if (intent?.action == "com.example.moji_todo.NOTIFICATION_ACTION") {
            when (intent.getStringExtra("action")) {
                "pause" -> {
                    Log.d("MainActivity", "Pausing timer from notification action")
                    val timerSeconds = intent.getIntExtra("timerSeconds", prefs.getInt("timerSeconds", 25 * 60))
                    methodChannel?.invokeMethod("pause", null)
                    prefs.edit().apply {
                        putInt("timerSeconds", timerSeconds)
                        putBoolean("isRunning", false)
                        putBoolean("isPaused", true)
                        apply()
                    }
                    Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$timerSeconds, isRunning=false, isPaused=true")
                }
                "resume" -> {
                    Log.d("MainActivity", "Resuming timer from notification action")
                    val timerSeconds = prefs.getInt("timerSeconds", 25 * 60)
                    methodChannel?.invokeMethod("resume", null)
                    prefs.edit().apply {
                        putInt("timerSeconds", timerSeconds)
                        putBoolean("isRunning", true)
                        putBoolean("isPaused", false)
                        apply()
                    }
                    Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=$timerSeconds, isRunning=true, isPaused=false")
                }
                "stop" -> {
                    Log.d("MainActivity", "Stopping timer from notification action")
                    methodChannel?.invokeMethod("stop", null)
                    NotificationManagerCompat.from(this).cancel(TimerService.NOTIFICATION_ID)
                    prefs.edit().apply {
                        putInt("timerSeconds", 25 * 60)
                        putBoolean("isRunning", false)
                        putBoolean("isPaused", false)
                        apply()
                    }
                    Log.d("MainActivity", "Saved SharedPreferences: timerSeconds=1500, isRunning=false, isPaused=false")
                }
            }
        } else {
            val payload = intent?.extras?.getString("flutter_notification_payload")
            if (payload != null) {
                when (payload) {
                    "START_BREAK" -> methodChannel?.invokeMethod("startBreak", null)
                    "START_WORK" -> methodChannel?.invokeMethod("startWork", null)
                }
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val expectedComponentName = ComponentName(this, AppBlockService::class.java)
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
        val isEnabled = enabledServices.any { service ->
            service.resolveInfo.serviceInfo.packageName == expectedComponentName.packageName
        }
        return isEnabled
    }
}