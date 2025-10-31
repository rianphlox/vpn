package com.qubators.qshield

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.cloud.pira.DownloadMethodChannel
import com.cloud.pira.AppListMethodChannel
import com.cloud.pira.PingMethodChannel
import com.cloud.pira.SettingsMethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cloud.pira/vpn_control"
    private var vpnControlChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Preload app list in background when app starts
        preloadAppList()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppListMethodChannel.registerWith(flutterEngine, context)
        PingMethodChannel.registerWith(flutterEngine, context)
        SettingsMethodChannel.registerWith(flutterEngine, context)
        DownloadMethodChannel.registerWith(flutterEngine, context)
        
        // Create VPN control channel
        vpnControlChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == "FROM_DISCONNECT_BTN") {
            // Send message to Flutter to disconnect VPN
            vpnControlChannel?.invokeMethod("disconnectFromNotification", null)
        }
    }
    
    private fun preloadAppList() {
        // Preload app list in background to cache it for faster access later
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // This will trigger the app list loading and caching
                val channel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, AppListMethodChannel.CHANNEL)
                channel.invokeMethod("getInstalledApps", null)
            } catch (e: Exception) {
                // Ignore errors during preload
            }
        }
    }
}