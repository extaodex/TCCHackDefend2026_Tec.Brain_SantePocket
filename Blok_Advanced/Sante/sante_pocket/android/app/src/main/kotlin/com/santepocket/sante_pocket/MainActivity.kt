package com.santepocket.sante_pocket

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.santepocket.sante_pocket/hotspot"
    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableHotspot" -> {
                    enableHotspot(result)
                }
                "disableHotspot" -> {
                    disableHotspot()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun enableHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                    super.onStarted(reservation)
                    hotspotReservation = reservation
                    val config = reservation.wifiConfiguration
                    val map = mapOf(
                        "ssid" to (config?.SSID ?: "Unknown"),
                        "password" to (config?.preSharedKey ?: "")
                    )
                    result.success(map)
                }

                override fun onFailed(reason: Int) {
                    super.onFailed(reason)
                    result.error("HOTSPOT_FAILED", "Failed to start hotspot: $reason", null)
                }

                override fun onStopped() {
                    super.onStopped()
                    hotspotReservation = null
                }
            }, Handler(Looper.getMainLooper()))
        } else {
            result.error("UNSUPPORTED", "Android version too old", null)
        }
    }

    private fun disableHotspot() {
        hotspotReservation?.close()
        hotspotReservation = null
    }
}
