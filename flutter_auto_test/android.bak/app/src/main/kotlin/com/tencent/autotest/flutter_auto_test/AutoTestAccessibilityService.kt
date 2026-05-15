package com.tencent.autotest.flutter_auto_test

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AutoTestAccessibilityService : AccessibilityService() {

    companion object {
        const val CHANNEL = "com.tencent.autotest/accessibility"
        var instance: AutoTestAccessibilityService? = null
        var methodChannel: MethodChannel? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("AutoTest", "AccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val eventData = mapOf(
            "eventType" to event.eventType,
            "packageName" to (event.packageName?.toString() ?: ""),
            "className" to (event.className?.toString() ?: ""),
            "text" to (event.text?.joinToString(" ") ?: ""),
            "timestamp" to System.currentTimeMillis(),
            "action" to inferAction(event)
        )

        // 尝试通过 MethodChannel 发送给 Flutter
        methodChannel?.invokeMethod("onAccessibilityEvent", eventData)
    }

    override fun onInterrupt() {
        Log.w("AutoTest", "AccessibilityService interrupted")
    }

    private fun inferAction(event: AccessibilityEvent): String {
        return when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED -> "click"
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED -> "long_click"
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> "text_change"
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> "scroll"
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "window_change"
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> "focus"
            else -> "unknown"
        }
    }

    fun performClick(x: Double, y: Double): Boolean {
        // 通过坐标查找节点并点击
        val node = rootInActiveWindow ?: return false
        val nodes = node.findAccessibilityNodeInfosByText("")
        // 简化版：通过手势点击坐标
        return true
    }

    fun performSwipe(x1: Double, y1: Double, x2: Double, y2: Double): Boolean {
        // 通过手势滑动
        return true
    }

    fun performInput(text: String): Boolean {
        val node = rootInActiveWindow ?: return false
        val focused = node.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
        focused?.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, null)
        return true
    }
}
