package com.tencent.autotest.flutter_auto_test

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Bundle
import androidx.annotation.RequiresApi

class AutoTestAccessibilityService : AccessibilityService() {

    companion object {
        const val CHANNEL = "com.tencent.autotest/accessibility_service"
        var instance: AutoTestAccessibilityService? = null
        val recordedEvents = mutableListOf<Map<String, Any?>>()
        var isRecording = false
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d("AutoTest", "AccessibilityService connected")
        val info = android.accessibilityservice.AccessibilityServiceInfo()
        info.eventTypes = AccessibilityEvent.TYPE_VIEW_CLICKED or
                AccessibilityEvent.TYPE_VIEW_LONG_CLICKED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_FOCUSED
        info.feedbackType = android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.packageNames = null
        info.notificationTimeout = 50
        this.serviceInfo = info
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val pkg = event.packageName?.toString() ?: ""
        val cls = event.className?.toString() ?: ""
        val text = event.text?.joinToString(" ") ?: ""
        val eventType = event.eventType
        val action = when (eventType) {
            AccessibilityEvent.TYPE_VIEW_CLICKED -> "click"
            AccessibilityEvent.TYPE_VIEW_LONG_CLICKED -> "long_click"
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> "text_change"
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> "scroll"
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "window_change"
            AccessibilityEvent.TYPE_VIEW_FOCUSED -> "focus"
            else -> "unknown"
        }
        val eventData = mapOf(
            "action" to action,
            "packageName" to pkg,
            "className" to cls,
            "text" to text,
            "timestamp" to System.currentTimeMillis()
        )
        if (isRecording) {
            recordedEvents.add(eventData)
        }
        Log.d("AutoTest", "Event: $action @ $pkg")
    }

    override fun onInterrupt() {
        Log.w("AutoTest", "AccessibilityService interrupted")
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun performClick(x: Int, y: Int): Boolean {
        val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 50))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun performLongClick(x: Int, y: Int, durationMs: Long): Boolean {
        val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, durationMs))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    @RequiresApi(Build.VERSION_CODES.N)
    fun performSwipe(x1: Int, y1: Int, x2: Int, y2: Int): Boolean {
        val path = Path().apply {
            moveTo(x1.toFloat(), y1.toFloat())
            lineTo(x2.toFloat(), y2.toFloat())
        }
        val gesture = GestureDescription.Builder()
            .addStroke(GestureDescription.StrokeDescription(path, 0, 300))
            .build()
        return dispatchGesture(gesture, null, null)
    }

    fun performInput(text: String): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        try {
            val focusNode = findFocusableNode(rootNode) ?: return false
            val bundle = Bundle()
            bundle.putString(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            return focusNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, bundle)
        } catch (e: Exception) {
            Log.e("AutoTest", "performInput failed: ${e.message}")
            return false
        } finally {
            rootNode.recycle()
        }
    }

    fun performBack(): Boolean {
        return performGlobalAction(GLOBAL_ACTION_BACK)
    }

    fun performClickOnNode(text: String? = null, id: String? = null): Boolean {
        val rootNode = rootInActiveWindow ?: return false
        try {
            val nodes = mutableListOf<AccessibilityNodeInfo>()
            if (text != null) {
                nodes.addAll(rootNode.findAccessibilityNodeInfosByText(text))
            }
            if (id != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                nodes.addAll(rootNode.findAccessibilityNodeInfosByViewId(id))
            }
            for (node in nodes) {
                if (node.isClickable) {
                    return node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
            }
            for (node in nodes) {
                var parent = node.parent
                while (parent != null) {
                    if (parent.isClickable) {
                        return parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                    }
                    parent = parent.parent
                }
            }
        } catch (e: Exception) {
            Log.e("AutoTest", "performClickOnNode failed: ${e.message}")
        } finally {
            rootNode.recycle()
        }
        return false
    }

    private fun findFocusableNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isFocused || node.isEditable) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findFocusableNode(child)
            if (result != null) return result
        }
        return null
    }

    fun startRecording() {
        recordedEvents.clear()
        isRecording = true
        Log.d("AutoTest", "Recording started")
    }

    fun stopRecording(): List<Map<String, Any?>> {
        isRecording = false
        Log.d("AutoTest", "Recording stopped, ${recordedEvents.size} events")
        return recordedEvents.toList()
    }
}
