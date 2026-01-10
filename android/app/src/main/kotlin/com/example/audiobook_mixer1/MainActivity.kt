package com.example.audiobook_mixer1

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.example.booktune/battery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBatteryOptimizationExempted" -> {
                    val isExempted = checkBatteryOptimizationExemption()
                    result.success(isExempted)
                }
                "requestBatteryOptimizationExemption" -> {
                    val granted = requestBatteryOptimizationExemption()
                    result.success(granted)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * Vérifie si l'app est exemptée des optimisations de batterie
     */
    private fun checkBatteryOptimizationExemption(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            // Sur les versions antérieures, considérer comme exempté
            true
        }
    }

    /**
     * Demande à l'utilisateur d'exempter l'app des optimisations de batterie
     */
    private fun requestBatteryOptimizationExemption(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        } else {
            // Sur les versions antérieures, pas nécessaire
            true
        }
    }
}
