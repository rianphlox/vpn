package com.cloud.pira

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class AppListMethodChannel(private val context: Context) : MethodCallHandler {
    companion object {
        const val CHANNEL = "com.cloud.pira/app_list"

        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(AppListMethodChannel(context))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getInstalledApps" -> {
                // Run the operation in a background thread to avoid blocking the UI
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val packageManager = context.packageManager
                        val installedApps = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
                        
                        val appList = mutableListOf<Map<String, Any>>()
                        
                        for (appInfo in installedApps) {
                            // Skip system apps if they don't have a launcher
                            if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0) {
                                val launchIntent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                                if (launchIntent == null) {
                                    continue
                                }
                            }
                            
                            val appName = packageManager.getApplicationLabel(appInfo).toString()
                            val packageName = appInfo.packageName
                            
                            appList.add(mapOf(
                                "name" to appName,
                                "packageName" to packageName,
                                "isSystemApp" to ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0)
                            ))
                        }
                        
                        // Sort by app name
                        val sortedAppList = appList.sortedBy { (it["name"] as? String)?.lowercase() ?: "" }
                        
                        // Return result on the main thread
                        withContext(Dispatchers.Main) {
                            result.success(sortedAppList)
                        }
                    } catch (e: Exception) {
                        // Return error on the main thread
                        withContext(Dispatchers.Main) {
                            result.error("APP_LIST_ERROR", "Failed to get installed apps", e.message)
                        }
                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}