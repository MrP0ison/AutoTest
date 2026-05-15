package com.tencent.autotest.flutter_auto_test

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageButton
import android.widget.TextView
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Bundle
import androidx.annotation.RequiresApi
import org.json.JSONArray
import org.json.JSONObject

class AutoTestAccessibilityService : AccessibilityService() {

    companion object {
        const val CHANNEL = "com.tencent.autotest/accessibility_service"
        var instance: AutoTestAccessibilityService? = null
        val recordedEvents = mutableListOf<Map<String, Any?>>()
        var isRecording = false
        
        // 悬浮窗相关
        var floatingWindow: View? = null
        var windowManager: WindowManager? = null
        var isFloatingShowing = false
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
        
        // 初始化 WindowManager
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        val pkg = event.packageName?.toString() ?: ""
        val cls = event.className?.toString() ?: ""
        val text = event.text?.joinToString(" ") ?: ""
        val eventType = event.eventType
        
        // 获取坐标信息
        val bounds = Rect()
        val source = event.source
        var x = 0
        var y = 0
        if (source != null) {
            source.getBoundsInScreen(bounds)
            // 计算中心点坐标
            x = bounds.centerX()
            y = bounds.centerY()
            source.recycle()
        }
        
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
            "x" to x,
            "y" to y,
            "timestamp" to System.currentTimeMillis()
        )
        
        if (isRecording) {
            recordedEvents.add(eventData)
            Log.d("AutoTest", "Recorded: $action @ $pkg | x=$x, y=$y")
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

    /// 显示悬浮窗控制面板
    fun showFloatingWindow() {
        if (isFloatingShowing) return
        
        try {
            // 创建悬浮窗布局
            floatingWindow = LayoutInflater.from(this).inflate(R.layout.floating_control_panel, null)
            
            // 设置 WindowManager 布局参数
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
                else 
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.TOP or Gravity.START
            params.x = 0
            params.y = 100
            
            // 添加悬浮窗
            windowManager?.addView(floatingWindow, params)
            isFloatingShowing = true
            
            // 设置按钮点击事件
            setupFloatingButtons(floatingWindow!!, params)
            
            Log.d("AutoTest", "Floating window shown")
        } catch (e: Exception) {
            Log.e("AutoTest", "Show floating window failed: ${e.message}")
        }
    }

    /// 隐藏悬浮窗控制面板
    fun hideFloatingWindow() {
        if (!isFloatingShowing || floatingWindow == null) return
        
        try {
            windowManager?.removeView(floatingWindow)
            floatingWindow = null
            isFloatingShowing = false
            Log.d("AutoTest", "Floating window hidden")
        } catch (e: Exception) {
            Log.e("AutoTest", "Hide floating window failed: ${e.message}")
        }
    }

    /// 设置悬浮窗按钮点击事件
    private fun setupFloatingButtons(view: View, params: WindowManager.LayoutParams) {
        val btnRecord = view.findViewById<Button>(R.id.btn_record)
        val btnPlay = view.findViewById<Button>(R.id.btn_play)
        val btnStop = view.findViewById<Button>(R.id.btn_stop)
        val btnClose = view.findViewById<Button>(R.id.btn_close)
        val btnDrag = view.findViewById<ImageButton>(R.id.btn_drag)
        
        btnRecord?.setOnClickListener {
            if (!isRecording) {
                startRecording()
                btnRecord.text = "停止录制"
                Log.d("AutoTest", "Floating: Start recording")
            } else {
                stopRecording()
                btnRecord.text = "录制"
                Log.d("AutoTest", "Floating: Stop recording")
            }
        }
        
        btnPlay?.setOnClickListener {
            Log.d("AutoTest", "Floating: Start playback")
            // 回放逻辑需要在 Flutter 端实现
        }
        
        btnStop?.setOnClickListener {
            if (isRecording) {
                stopRecording()
                btnRecord?.text = "录制"
            }
            Log.d("AutoTest", "Floating: Stop all")
        }
        
        btnClose?.setOnClickListener {
            hideFloatingWindow()
        }
        
        // 拖动功能
        btnDrag?.setOnTouchListener { _, event ->
            // 简化版：点击拖动区域可以移动悬浮窗
            Log.d("AutoTest", "Floating: Drag")
            true
        }
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

    /**
     * 获取当前UI树（JSON格式）
     * maxDepth: 最大递归深度，默认10层
     */
    fun getUiTree(maxDepth: Int = 10): String {
        val root = rootInActiveWindow ?: return "[]"
        val tree = traverseNode(root, 0, maxDepth)
        root.recycle()
        
        val array = JSONArray()
        array.put(tree)
        return array.toString(2)
    }

    /**
     * 递归遍历节点
     */
    private fun traverseNode(node: AccessibilityNodeInfo, depth: Int, maxDepth: Int): JSONObject {
        val result = JSONObject()
        
        if (depth >= maxDepth) {
            result.put("truncated", true)
            result.put("depth", depth)
            return result
        }

        // 基本信息
        result.put("className", node.className)
        result.put("text", node.text)
        result.put("contentDescription", node.contentDescription)
        result.put("isClickable", node.isClickable)
        result.put("isEditable", node.isEditable)
        result.put("isFocusable", node.isFocusable)
        result.put("isScrollable", node.isScrollable)
        result.put("isEnabled", node.isEnabled)
        result.put("viewIdResourceName", node.viewIdResourceName)
        
        // 坐标信息
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        val boundsObj = JSONObject()
        boundsObj.put("left", bounds.left)
        boundsObj.put("top", bounds.top)
        boundsObj.put("right", bounds.right)
        boundsObj.put("bottom", bounds.bottom)
        boundsObj.put("centerX", bounds.centerX())
        boundsObj.put("centerY", bounds.centerY())
        result.put("bounds", boundsObj)
        
        // 子节点（限制最多50个子节点）
        if (node.childCount > 0 && depth < maxDepth) {
            val children = JSONArray()
            val limit = minOf(node.childCount, 50)
            for (i in 0 until limit) {
                val child = node.getChild(i) ?: continue
                children.put(traverseNode(child, depth + 1, maxDepth))
                child.recycle()
            }
            result.put("children", children)
        }
        
        return result
    }
}
