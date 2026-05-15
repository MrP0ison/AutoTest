package com.tencent.autotest.flutter_auto_test

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.regex.Pattern

class MainActivity : FlutterActivity() {

    companion object {
        const val ACCESSIBILITY_CHANNEL = "com.tencent.autotest/accessibility"
        const val PERFORMANCE_CHANNEL = "com.tencent.autotest/performance"
        const val FILE_CHANNEL = "com.tencent.autotest/file"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityServiceEnabled" -> result.success(isAccessibilityServiceEnabled())
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "launchUrl" -> {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                startActivity(intent)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("LAUNCH_FAILED", e.message, null)
                            }
                        } else {
                            result.error("INVALID", "URL is null", null)
                        }
                    }
                    "getInstalledApps" -> {
                        val apps = getInstalledApps()
                        result.success(apps)
                    }
                    "performClick" -> {
                        val x = call.argument<Double>("x")?.toInt() ?: 0
                        val y = call.argument<Double>("y")?.toInt() ?: 0
                        val svc = AutoTestAccessibilityService.instance
                        val ok = if (svc != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            svc.performClick(x, y)
                        } else {
                            svc?.performClickOnNode() ?: false
                        }
                        result.success(ok)
                    }
                    "performLongClick" -> {
                        val x = call.argument<Double>("x")?.toInt() ?: 0
                        val y = call.argument<Double>("y")?.toInt() ?: 0
                        val durationMs = call.argument<Double>("durationMs")?.toLong() ?: 800L
                        val svc = AutoTestAccessibilityService.instance
                        val ok = if (svc != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            svc.performLongClick(x, y, durationMs)
                        } else {
                            false
                        }
                        result.success(ok)
                    }
                    "performSwipe" -> {
                        val x1 = call.argument<Double>("x1")?.toInt() ?: 0
                        val y1 = call.argument<Double>("y1")?.toInt() ?: 0
                        val x2 = call.argument<Double>("x2")?.toInt() ?: 0
                        val y2 = call.argument<Double>("y2")?.toInt() ?: 0
                        val svc = AutoTestAccessibilityService.instance
                        val ok = if (svc != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            svc.performSwipe(x1, y1, x2, y2)
                        } else {
                            false
                        }
                        result.success(ok)
                    }
                    "performInput" -> {
                        val text = call.argument<String>("text") ?: ""
                        val svc = AutoTestAccessibilityService.instance
                        val ok = svc?.performInput(text) ?: false
                        result.success(ok)
                    }
                    "performBack" -> {
                        val svc = AutoTestAccessibilityService.instance
                        val ok = svc?.performBack() ?: false
                        result.success(ok)
                    }
                    "startRecording" -> {
                        AutoTestAccessibilityService.instance?.startRecording()
                        result.success(true)
                    }
                    "stopRecording" -> {
                        val events = AutoTestAccessibilityService.instance?.stopRecording()
                        result.success(events)
                    }
                    "getUiTree" -> {
                        val maxDepth = call.argument<Int>("maxDepth") ?: 10
                        val tree = AutoTestAccessibilityService.instance?.getUiTree(maxDepth)
                        result.success(tree)
                    }
                    // 悬浮窗控制
                    "showFloatingWindow" -> {
                        AutoTestAccessibilityService.instance?.showFloatingWindow()
                        result.success(true)
                    }
                    "hideFloatingWindow" -> {
                        AutoTestAccessibilityService.instance?.hideFloatingWindow()
                        result.success(true)
                    }
                    "isFloatingWindowShowing" -> {
                        result.success(AutoTestAccessibilityService.isFloatingShowing)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERFORMANCE_CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getCpuUsage" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(getCpuUsage(pkg))
                        }
                        "getMemoryPss" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(getMemoryPss(pkg))
                        }
                        "getFps" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(getFps(pkg))
                        }
                        "getPowerMw" -> result.success(getPowerMw())
                        "getBatteryCurrentMa" -> result.success(getBatteryCurrentMa())
                        "getBatteryDischargeMah" -> result.success(getBatteryDischargeMah())
                        "getNetworkStats" -> {
                            val uid = call.argument<String>("uid") ?: ""
                            result.success(getNetworkStats(uid))
                        }
                        "getNetworkType" -> result.success(getNetworkType())
                        "getUidForPackage" -> {
                            val pkg = call.argument<String>("package") ?: ""
                            result.success(getUidForPackage(pkg))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        if (path.isEmpty()) {
                            result.error("INVALID", "Path is empty", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = File(path)
                            val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                android.net.Uri.parse("content://$packageName.fileprovider/$path")
                            } else {
                                android.net.Uri.fromFile(file)
                            }
                            val intent = Intent(Intent.ACTION_VIEW)
                            val mimeType = when {
                                path.endsWith(".pdf") -> "application/pdf"
                                path.endsWith(".xlsx") -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                                path.endsWith(".xls") -> "application/vnd.ms-excel"
                                path.endsWith(".csv") -> "text/csv"
                                path.endsWith(".json") -> "application/json"
                                path.endsWith(".html") -> "text/html"
                                path.endsWith(".txt") -> "text/plain"
                                else -> "*/*"
                            }
                            intent.setDataAndType(android.net.Uri.fromFile(file), mimeType)
                            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val am = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val services = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
        return services?.contains(packageName) == true
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, String>>()
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)
        for (app in packages) {
            val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (isSystem) continue
            val label = pm.getApplicationLabel(app).toString()
            apps.add(mapOf("appName" to label, "packageName" to app.packageName))
        }
        return apps.sortedBy { it["appName"] }
    }

    private fun getCpuUsage(pkg: String): Double? {
        return try {
            val proc = Runtime.getRuntime().exec(arrayOf("dumpsys", "cpuinfo"))
            val output = proc.inputStream.bufferedReader().use { it.readText() }
            val quoted = Pattern.quote(pkg)
            val regex = Regex("$quoted\\s+(\\d+\\.?\\d*)%?")
            val match = regex.find(output)
            match?.groupValues?.getOrNull(1)?.toDoubleOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun getMemoryPss(pkg: String): Int? {
        return try {
            val proc = Runtime.getRuntime().exec(arrayOf("dumpsys", "meminfo", pkg))
            val output = proc.inputStream.bufferedReader().use { it.readText() }
            val regex = Regex("TOTAL\\s+(\\d+)")
            val match = regex.find(output)
            match?.groupValues?.getOrNull(1)?.toIntOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun getFps(pkg: String): Double? {
        return try {
            val proc = Runtime.getRuntime().exec(arrayOf("dumpsys", "gfxinfo", pkg))
            val output = proc.inputStream.bufferedReader().use { it.readText() }
            val regex = Regex("Total\\s+frames\\s+rendered:\\s*(\\d+)")
            val match = regex.find(output)
            match?.groupValues?.getOrNull(1)?.toDoubleOrNull()
        } catch (e: Exception) {
            null
        }
    }

    private fun getBatteryCurrentMa(): Double? {
        return try {
            val file = File("/sys/class/power_supply/battery/current_now")
            if (file.exists()) {
                val uA = file.readText().trim().toLongOrNull()
                if (uA != null) (uA / 1000.0) else null
            } else {
                val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
                val ma = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
                (ma / 1000.0)
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getPowerMw(): Double? {
        return try {
            val voltageUvFile = File("/sys/class/power_supply/battery/voltage_now")
            val currentUaFile = File("/sys/class/power_supply/battery/current_now")
            if (voltageUvFile.exists() && currentUaFile.exists()) {
                val voltageUv = voltageUvFile.readText().trim().toDoubleOrNull()
                val currentUa = currentUaFile.readText().trim().toDoubleOrNull()
                if (voltageUv != null && currentUa != null) {
                    (voltageUv * currentUa) / 1000000.0
                } else null
            } else null
        } catch (e: Exception) {
            null
        }
    }

    private fun getBatteryDischargeMah(): Int? {
        return try {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val counter = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
            (counter / 1000)
        } catch (e: Exception) {
            null
        }
    }

    private fun getNetworkStats(uidStr: String): Map<String, Int?> {
        if (uidStr.isEmpty()) return mapOf("sent" to null, "recv" to null)
        return try {
            val uid = uidStr.toIntOrNull() ?: return mapOf("sent" to null, "recv" to null)
            val sndFile = File("/proc/uid_stat/$uid/tcp_snd")
            val rcvFile = File("/proc/uid_stat/$uid/tcp_rcv")
            val sndBytes = if (sndFile.exists()) sndFile.readText().trim().toLongOrNull() else null
            val rcvBytes = if (rcvFile.exists()) rcvFile.readText().trim().toLongOrNull() else null
            mapOf(
                "sent" to (sndBytes?.div(1024))?.toInt(),
                "recv" to (rcvBytes?.div(1024))?.toInt()
            )
        } catch (e: Exception) {
            mapOf("sent" to null, "recv" to null)
        }
    }

    private fun getNetworkType(): String {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val network = cm.activeNetwork
                val caps = cm.getNetworkCapabilities(network)
                when {
                    caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true -> "WiFi"
                    caps?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) == true -> "Mobile"
                    else -> "None"
                }
            } else {
                @Suppress("DEPRECATION")
                val info = cm.activeNetworkInfo
                when (info?.type) {
                    ConnectivityManager.TYPE_WIFI -> "WiFi"
                    ConnectivityManager.TYPE_MOBILE -> "Mobile"
                    else -> "None"
                }
            }
        } catch (e: Exception) {
            "Unknown"
        }
    }

    private fun getUidForPackage(pkg: String): String? {
        return try {
            val pm = packageManager
            val uid = pm.getPackageUid(pkg, 0)
            uid.toString()
        } catch (e: Exception) {
            null
        }
    }
}
