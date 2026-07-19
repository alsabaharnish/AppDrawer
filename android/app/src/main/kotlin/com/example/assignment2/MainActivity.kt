// ===========================================================================
// CSE 489 — Assignment 2 : Android platform side (Kotlin)
// Package matches this project's applicationId (com.example.assignment2).
// If you ever rename the app package, update the line below AND the folder
// path android/app/src/main/kotlin/... to match, or the app won't launch.
// ===========================================================================
package com.example.assignment2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        // Channel names — MUST match main.dart character-for-character.
        private const val METHOD_CHANNEL = "cse489.assignment2/methods"
        private const val CUSTOM_EVENT_CHANNEL = "cse489.assignment2/custom_broadcast"
        private const val BATTERY_EVENT_CHANNEL = "cse489.assignment2/battery_broadcast"

        // The custom Intent action our BroadcastReceiver listens for.
        private const val CUSTOM_ACTION = "cse489.assignment2.CUSTOM_BROADCAST"
        private const val EXTRA_MESSAGE = "message"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // -------------------------------------------------------------------
        // MethodChannel — Dart asks Android to SEND a genuine broadcast.
        // sendBroadcast() hands the Intent to the Android OS; the OS then
        // delivers it to every matching registered receiver (including ours).
        // -------------------------------------------------------------------
        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendCustomBroadcast" -> {
                    val message = call.argument<String>(EXTRA_MESSAGE) ?: ""
                    val intent = Intent(CUSTOM_ACTION).apply {
                        putExtra(EXTRA_MESSAGE, message)
                        // Target our own package: required for reliable
                        // delivery on Android 8+ (implicit broadcast limits).
                        setPackage(packageName)
                    }
                    sendBroadcast(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // -------------------------------------------------------------------
        // EventChannel #1 — the CUSTOM BroadcastReceiver.
        // onListen()  → Dart subscribed → registerReceiver()   (real receiver)
        // onCancel()  → Dart unsubscribed → unregisterReceiver() (no leaks)
        // -------------------------------------------------------------------
        EventChannel(messenger, CUSTOM_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            if (intent?.action == CUSTOM_ACTION) {
                                events?.success(
                                    intent.getStringExtra(EXTRA_MESSAGE) ?: ""
                                )
                            }
                        }
                    }
                    val filter = IntentFilter(CUSTOM_ACTION)
                    // Android 13 (API 33)+ requires an export flag for
                    // context-registered receivers of custom actions.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
                    } else {
                        @Suppress("UnspecifiedRegisterReceiverFlag")
                        registerReceiver(receiver, filter)
                    }
                }

                override fun onCancel(args: Any?) {
                    receiver?.let { unregisterReceiver(it) }
                    receiver = null
                }
            }
        )

        // -------------------------------------------------------------------
        // EventChannel #2 — the SYSTEM battery receiver.
        // ACTION_BATTERY_CHANGED is a sticky broadcast: the moment we register,
        // Android re-delivers the most recent battery Intent, so the UI gets a
        // value immediately, then live updates whenever the system broadcasts.
        // (System-protected broadcasts don't need the export flag.)
        // -------------------------------------------------------------------
        EventChannel(messenger, BATTERY_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(args: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            sendBatteryLevel(intent, events)
                        }
                    }
                    val stickyIntent = registerReceiver(
                        receiver,
                        IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                    )
                    // ACTION_BATTERY_CHANGED is a sticky broadcast. Send the
                    // initial value immediately so the UI doesn't have to wait
                    // for the next battery level change.
                    sendBatteryLevel(stickyIntent, events)
                }

                private fun sendBatteryLevel(intent: Intent?, events: EventChannel.EventSink?) {
                    if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                        if (level >= 0 && scale > 0) {
                            events?.success(level * 100 / scale)
                        }
                    }
                }

                override fun onCancel(args: Any?) {
                    receiver?.let { unregisterReceiver(it) }
                    receiver = null
                }
            }
        )
    }
}
