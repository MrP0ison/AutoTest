package com.tencent.autotest.flutter_auto_test

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.tencent.autotest/accessibility"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityServiceEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "startAccessibilityService" -> {
                        // 无障碍服务由用户在设置中手动开启
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "execShellCommand" -> {
                        val command = call.argument<String>("command")
                        val output = execShell(command ?: "")
                        result.success(output)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledApps())
                    }
                    else -> result.notImplemented()
                }
            }

        // 将 MethodChannel 传递给 AccessibilityService
        AutoTestAccessibilityService.methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.tencent.autotest/accessibility_service"
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabledServices?.contains(packageName) ?: false
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun execShell(command: String): String {
        return try {
            val process = Runtime.getRuntime().exec(command)
            process.inputStream.bufferedReader().readText()
        } catch (e: Exception) {
            "ERROR: ${e.message}"
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val packages = pm.getInstalledPackages(0)
        return packages.map { pkg ->
            mapOf(
                "packageName" to (pkg.packageName ?: ""),
                "appName" to (pm.getApplicationLabel(pm.getApplicationInfo(pkg.packageName, 0)).toString())
            )
        }.filter { it["packageName"]?.isNotEmpty() == true }
    }
}
