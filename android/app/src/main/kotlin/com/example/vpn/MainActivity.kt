package com.example.vpn

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val vpnChannel = "com.example.vpn/vpn"
    private var methodChannel: MethodChannel? = null
    private val vpnStatusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "VPN_STATUS") {
                val connected = intent.getBooleanExtra("connected", false)
                val message = intent.getStringExtra("message") ?: ""

                methodChannel?.invokeMethod("vpnStatus", mapOf(
                    "connected" to connected,
                    "message" to message
                ))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, vpnChannel)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "prepareVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_PREPARE_REQUEST)
                        result.success(false) // Permission needed
                    } else {
                        result.success(true) // Permission already granted
                    }
                }
                "connectVpn" -> {
                    val serverConfig = call.argument<String>("serverConfig")
                    val serverHost = call.argument<String>("serverHost")
                    val serverPort = call.argument<Int>("serverPort") ?: 1194
                    val username = call.argument<String>("username") ?: "vpn"
                    val password = call.argument<String>("password") ?: "vpn"

                    if (serverConfig != null && serverHost != null) {
                        val intent = Intent(this, com.example.vpn.VpnService::class.java)
                        intent.action = "CONNECT"
                        intent.putExtra("serverConfig", serverConfig)
                        intent.putExtra("serverHost", serverHost)
                        intent.putExtra("serverPort", serverPort)
                        intent.putExtra("username", username)
                        intent.putExtra("password", password)

                        startService(intent)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing server configuration", null)
                    }
                }
                "disconnectVpn" -> {
                    val intent = Intent(this, com.example.vpn.VpnService::class.java)
                    intent.action = "DISCONNECT"
                    startService(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Register broadcast receiver
        val filter = IntentFilter("VPN_STATUS")
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(vpnStatusReceiver, filter, RECEIVER_EXPORTED)
        } else {
            registerReceiver(vpnStatusReceiver, filter)
        }
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(vpnStatusReceiver)
        instance = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == VPN_PREPARE_REQUEST) {
            if (resultCode == RESULT_OK) {
                methodChannel?.invokeMethod("vpnPermissionGranted", true)
            } else {
                methodChannel?.invokeMethod("vpnPermissionGranted", false)
            }
        }
    }

    companion object {
        private const val VPN_PREPARE_REQUEST = 100
        private var instance: MainActivity? = null

        fun invokeMethod(method: String, arguments: Any?) {
            instance?.methodChannel?.invokeMethod(method, arguments)
        }
    }
}
