package com.example.vaultly

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "vaultly/share_intent"
    private val eventChannelName = "vaultly/share_intent_stream"
    private val widgetMethodChannelName = "vaultly/widget_action"
    private val widgetEventChannelName = "vaultly/widget_action_stream"
    private var initialShare: Map<String, String?>? = null
    private var pendingShare: Map<String, String?>? = null
    private var eventSink: EventChannel.EventSink? = null
    private var initialWidgetAction: String? = null
    private var pendingWidgetAction: String? = null
    private var widgetEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialShare = parseShareIntent(intent)
        initialWidgetAction = parseWidgetAction(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialShare" -> result.success(initialShare)
                    "resetInitialShare" -> {
                        initialShare = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetMethodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialWidgetAction" -> result.success(initialWidgetAction)
                    "resetInitialWidgetAction" -> {
                        initialWidgetAction = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    pendingShare?.let {
                        eventSink?.success(it)
                        pendingShare = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, widgetEventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    widgetEventSink = events
                    pendingWidgetAction?.let {
                        widgetEventSink?.success(it)
                        pendingWidgetAction = null
                    }
                }

                override fun onCancel(arguments: Any?) {
                    widgetEventSink = null
                }
            })
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        parseWidgetAction(intent)?.let { action ->
            if (widgetEventSink == null) {
                pendingWidgetAction = action
            } else {
                widgetEventSink?.success(action)
            }
            return
        }
        parseShareIntent(intent)?.let { payload ->
            if (eventSink == null) {
                pendingShare = payload
            } else {
                eventSink?.success(payload)
            }
        }
    }

    private fun parseShareIntent(intent: Intent?): Map<String, String?>? {
        if (intent == null) return null
        if (parseWidgetAction(intent) != null) return null
        val action = intent.action ?: return null
        if (action != Intent.ACTION_SEND &&
            action != Intent.ACTION_SEND_MULTIPLE &&
            action != Intent.ACTION_VIEW
        ) {
            return null
        }

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?: intent.getStringExtra(Intent.EXTRA_TITLE)
            ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
            ?: intent.dataString
            ?: firstClipText(intent)
            ?: firstStreamUri(intent)?.toString()
            ?: return null

        val mimeType = intent.type.orEmpty()
        val typeHint = when {
            mimeType.startsWith("video/") -> "video"
            mimeType.startsWith("image/") -> "image"
            mimeType.contains("pdf") || text.endsWith(".pdf", ignoreCase = true) -> "pdf"
            text.startsWith("http://") || text.startsWith("https://") -> "link"
            else -> "text"
        }

        val filePath = firstStreamUri(intent)?.toString()
        return mapOf(
            "text" to text,
            "filePath" to filePath,
            "typeHint" to typeHint,
        )
    }

    private fun parseWidgetAction(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val data = intent.data ?: return null
        if (data.scheme != "vaultly" || data.host != "quick") return null
        return data.getQueryParameter("action")
    }

    private fun firstStreamUri(intent: Intent): Uri? {
        return if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.firstOrNull()
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun firstClipText(intent: Intent): String? {
        val clipData = intent.clipData ?: return null
        if (clipData.itemCount == 0) return null
        val item = clipData.getItemAt(0)
        return item.text?.toString() ?: item.uri?.toString() ?: item.intent?.dataString
    }
}
