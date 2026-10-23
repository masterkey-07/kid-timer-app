package io.github.masterkey07.visualtimecounter

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Opens the system settings screens the alarm notices point to (research R15).
 * Every method answers whether the screen was opened.
 */
class SystemSettingsChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openExactAlarm" -> result.success(openExactAlarm())
            "openNotifications" -> result.success(openNotifications())
            "openBatteryOptimization" -> result.success(openBatteryOptimization())
            else -> result.notImplemented()
        }
    }

    private fun openExactAlarm(): Boolean {
        // The exact alarm setting only exists from Android 12 (S) on.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        return start(
            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                .setData(Uri.parse("package:${context.packageName}"))
        )
    }

    private fun openNotifications(): Boolean = start(
        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
    )

    // The settings list, not the direct request: the direct request needs the
    // REQUEST_IGNORE_BATTERY_OPTIMIZATIONS permission, which Play restricts.
    private fun openBatteryOptimization(): Boolean =
        start(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))

    private fun start(intent: Intent): Boolean = try {
        context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (error: ActivityNotFoundException) {
        false
    }

    private companion object {
        const val CHANNEL = "vtc/system_settings"
    }
}
