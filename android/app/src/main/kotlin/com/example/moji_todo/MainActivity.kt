package com.example.moji_todo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
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
    private var methodChannel: MethodChannel? = null
    private val timerBroadcastReceiver = TimerBroadcastReceiver()
    private val REQUEST_NOTIFICATION_PERMISSION = 1001
    private val REQUEST_IGNORE_BATTERY_OPTIMIZATIONS = 1002

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
        timerBroadcastReceiver.setMethodChannel(methodChannel!!)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startTimerService" -> {
                    val action = call.arguments<Map<String, Any>>()?.get("action") as String?
                    val timerSeconds = call.arguments<Map<String, Any>>()?.get("timerSeconds") as Int?
                    val isRunning = call.arguments<Map<String, Any>>()?.get("isRunning") as Boolean?
                    val isPaused = call.arguments<Map<String, Any>>()?.get("isPaused") as Boolean?
                    Log.d("MainActivity", "startTimerService: action=$action, timerSeconds=$timerSeconds, isRunning=$isRunning, isPaused=$isPaused")
                    if (action != null) {
                        val intent = Intent(this, TimerService::class.java).apply {
                            this.action = action
                            if (timerSeconds != null) putExtra("timerSeconds", timerSeconds)
                            if (isRunning != null) putExtra("isRunning", isRunning)
                            if (isPaused != null) putExtra("isPaused", isPaused)
                        }
                        startForegroundService(intent)
                        result.success(null)
                    } else {
                        result.error("INVALID_ACTION", "Action is null", null)
                    }
                }
                "getTimerState" -> {
                    // Trả về trạng thái từ TimerService
                    val state = mapOf(
                        "timerSeconds" to TimerService.timerSeconds,
                        "isRunning" to TimerService.isRunning,
                        "isPaused" to TimerService.isPaused
                    )
                    Log.d("MainActivity", "getTimerState: $state")
                    result.success(state)
                }
                "checkNotificationPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            REQUEST_NOTIFICATION_PERMISSION
                        )
                        result.success(null)
                    } else {
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
        handleNotificationIntent(intent)
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
        setIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        if (intent?.action == "com.example.moji_todo.NOTIFICATION_ACTION") {
            when (intent.getStringExtra("action")) {
                "pause" -> {
                    methodChannel?.invokeMethod("pauseTimer", null)
                }
                "resume" -> {
                    methodChannel?.invokeMethod("resumeTimer", null)
                }
                "stop" -> {
                    methodChannel?.invokeMethod("stopTimer", null)
                    NotificationManagerCompat.from(this).cancel(TimerService.NOTIFICATION_ID)
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