package com.discipline.discipline_guardian

import android.app.AppOpsManager
import android.content.Intent
import android.content.pm.PackageManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import java.util.Calendar
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	companion object {
		const val EXTRA_PROMPT_PACKAGE = "extra_prompt_package"
		private const val REQUEST_POST_NOTIFICATIONS = 2001
		@Volatile
		private var pendingPromptPackage: String? = null

		private fun savePendingPromptPackage(intent: Intent?) {
			val packageName = intent?.getStringExtra(EXTRA_PROMPT_PACKAGE)?.trim()
			if (!packageName.isNullOrBlank()) {
				pendingPromptPackage = packageName
			}
		}

		private fun consumePendingPromptPackage(): String? {
			val value = pendingPromptPackage
			pendingPromptPackage = null
			return value
		}
	}

	private val deviceAppsChannel = "discipline_guardian/device_apps"
	private val usageStatsChannel = "discipline_guardian/usage_stats"
	private val systemPermissionsChannel = "discipline_guardian/system_permissions"
	private val interceptionChannel = "discipline_guardian/interception"
	private var interceptionMethodChannel: MethodChannel? = null
	private var pendingNotificationPermissionResult: MethodChannel.Result? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		savePendingPromptPackage(intent)
		GuardAccessibilityService.loadPersistedRules(applicationContext)
		GuardianKeepAliveService.ensureRunningIfEnabled(applicationContext)
		notifyPendingPromptPackage()
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		savePendingPromptPackage(intent)
		notifyPendingPromptPackage()
	}

	override fun onResume() {
		super.onResume()
		notifyPendingPromptPackage()
	}

	override fun onRequestPermissionsResult(
		requestCode: Int,
		permissions: Array<out String>,
		grantResults: IntArray,
	) {
		super.onRequestPermissionsResult(requestCode, permissions, grantResults)
		if (requestCode != REQUEST_POST_NOTIFICATIONS) {
			return
		}

		val granted = grantResults.isNotEmpty() &&
			grantResults[0] == PackageManager.PERMISSION_GRANTED
		pendingNotificationPermissionResult?.success(granted)
		pendingNotificationPermissionResult = null
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deviceAppsChannel)
			.setMethodCallHandler { call, result ->
				if (call.method != "getInstalledApps") {
					result.notImplemented()
					return@setMethodCallHandler
				}

				try {
					val intent = Intent(Intent.ACTION_MAIN, null)
					intent.addCategory(Intent.CATEGORY_LAUNCHER)

					val launcherApps = packageManager.queryIntentActivities(intent, 0)
					val apps = launcherApps
						.distinctBy { it.activityInfo.packageName }
						.map {
							mapOf(
								"appName" to it.loadLabel(packageManager).toString(),
								"packageName" to it.activityInfo.packageName
							)
						}
						.sortedBy { it["appName"]?.lowercase() ?: "" }

					result.success(apps)
				} catch (e: Exception) {
					result.error("LOAD_APPS_FAILED", e.message, null)
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageStatsChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"hasPermission" -> result.success(hasUsageStatsPermission())
					"openPermissionSettings" -> {
						openUsageAccessSettings()
						result.success(true)
					}
					"getTodayUsageMinutes" -> {
						if (!hasUsageStatsPermission()) {
							result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
							return@setMethodCallHandler
						}

						try {
							val packageNames = call.argument<List<String>>("packageNames")
								?.map { it.trim() }
								?.filter { it.isNotEmpty() }
								?: emptyList()

							val usageMinutes = getTodayUsageMinutes(packageNames)
							result.success(usageMinutes)
						} catch (e: Exception) {
							result.error("USAGE_QUERY_FAILED", e.message, null)
						}
					}
					"getRecentForegroundApp" -> {
						if (!hasUsageStatsPermission()) {
							result.error("PERMISSION_DENIED", "Usage stats permission not granted", null)
							return@setMethodCallHandler
						}

						try {
							result.success(getRecentForegroundAppPackage())
						} catch (e: Exception) {
							result.error("FOREGROUND_APP_QUERY_FAILED", e.message, null)
						}
					}
					else -> result.notImplemented()
				}
			}

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, systemPermissionsChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"canDrawOverlays" -> result.success(canDrawOverlays())
					"areNotificationsEnabled" -> result.success(areNotificationsEnabled())
					"canRequestNotificationPermission" ->
						result.success(canRequestNotificationPermission())
					"requestNotificationPermission" -> {
						requestNotificationPermission(result)
					}
					"openOverlaySettings" -> {
						openOverlaySettings()
						result.success(true)
					}
					"openNotificationSettings" -> {
						openNotificationSettings()
						result.success(true)
					}
					"isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
					"isIgnoringBatteryOptimizations" ->
						result.success(isIgnoringBatteryOptimizations())
					"openAccessibilitySettings" -> {
						openAccessibilitySettings()
						result.success(true)
					}
					"openBatteryOptimizationSettings" -> {
						openBatteryOptimizationSettings()
						result.success(true)
					}
					"isKeepAliveEnabled" ->
						result.success(GuardianKeepAliveService.isEnabled(applicationContext))
					"isKeepAliveRunning" ->
						result.success(GuardianKeepAliveService.isRunning())
					"setKeepAliveEnabled" -> {
						val enabled = call.argument<Boolean>("enabled") ?: true
						GuardianKeepAliveService.setEnabled(applicationContext, enabled)
						if (enabled) {
							GuardianKeepAliveService.start(applicationContext)
						} else {
							GuardianKeepAliveService.stop(applicationContext)
						}
						result.success(true)
					}
					"startKeepAliveService" -> {
						GuardianKeepAliveService.setEnabled(applicationContext, true)
						GuardianKeepAliveService.start(applicationContext)
						result.success(true)
					}
					"stopKeepAliveService" -> {
						GuardianKeepAliveService.setEnabled(applicationContext, false)
						GuardianKeepAliveService.stop(applicationContext)
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}

		interceptionMethodChannel =
			MethodChannel(flutterEngine.dartExecutor.binaryMessenger, interceptionChannel)
		interceptionMethodChannel?.setMethodCallHandler { call, result ->
				when (call.method) {
					"setBlockedPackages" -> {
						val packages = call.argument<List<String>>("packages") ?: emptyList()
						GuardAccessibilityService.updateBlockedPackages(packages)
						GuardAccessibilityService.persistBlockedPackages(applicationContext, packages)
						result.success(true)
					}
					"setInterceptionEnabled" -> {
						val enabled = call.argument<Boolean>("enabled") ?: false
						GuardAccessibilityService.setInterceptionEnabled(enabled)
						GuardAccessibilityService.persistInterceptionEnabled(applicationContext, enabled)
						result.success(true)
					}
					"getLastAccessibilityForegroundApp" -> {
						result.success(GuardAccessibilityService.getLastForegroundPackage())
					}
					"getLastInterceptedPackage" -> {
						result.success(GuardAccessibilityService.getLastInterceptedPackage())
					}
					"consumeLastInterceptedPackage" -> {
						result.success(GuardAccessibilityService.consumeLastInterceptedPackage())
					}
					"getInterceptionStatus" -> {
						result.success(
							mapOf(
								"enabled" to GuardAccessibilityService.isInterceptionEnabled(),
								"blockedPackageCount" to GuardAccessibilityService.getBlockedPackageCount(),
								"lastForegroundPackage" to GuardAccessibilityService.getLastForegroundPackage(),
								"lastInterceptedPackage" to GuardAccessibilityService.getLastInterceptedPackage(),
							),
						)
					}
					"consumePromptPackage" -> {
						result.success(consumePendingPromptPackage())
					}
					"resetPromptState" -> {
						val targetPackage = call.argument<String>("packageName")
						GuardAccessibilityService.resetPromptState(targetPackage)
						result.success(true)
					}
					"launchAppByPackage" -> {
						val targetPackage = call.argument<String>("packageName")?.trim().orEmpty()
						if (targetPackage.isEmpty()) {
							result.success(false)
							return@setMethodCallHandler
						}
						result.success(launchAppByPackage(targetPackage))
					}
					"openHomeScreen" -> {
						result.success(openHomeScreen())
					}
					"moveGuardianToBackground" -> {
						result.success(moveTaskToBack(true))
					}
					else -> result.notImplemented()
				}
			}
		notifyPendingPromptPackage()
	}

	private fun hasUsageStatsPermission(): Boolean {
		val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
		val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			appOps.unsafeCheckOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				Process.myUid(),
				packageName,
			)
		} else {
			appOps.checkOpNoThrow(
				AppOpsManager.OPSTR_GET_USAGE_STATS,
				Process.myUid(),
				packageName,
			)
		}

		return mode == AppOpsManager.MODE_ALLOWED
	}

	private fun openUsageAccessSettings() {
		val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		startActivity(intent)
	}

	private fun getTodayUsageMinutes(packageNames: List<String>): Map<String, Int> {
		if (packageNames.isEmpty()) {
			return emptyMap()
		}

		val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
		val endTime = System.currentTimeMillis()
		val startCalendar = Calendar.getInstance().apply {
			set(Calendar.HOUR_OF_DAY, 0)
			set(Calendar.MINUTE, 0)
			set(Calendar.SECOND, 0)
			set(Calendar.MILLISECOND, 0)
		}
		val startTime = startCalendar.timeInMillis

		val targetPackages = packageNames.toSet()
		val usageMsByPackage = mutableMapOf<String, Long>()

		// 1) Prefer aggregate query when available.
		val aggregateMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
		aggregateMap.forEach { (pkg, stats) ->
			if (targetPackages.contains(pkg)) {
				val current = usageMsByPackage[pkg] ?: 0L
				usageMsByPackage[pkg] = maxOf(current, stats.totalTimeInForeground)
			}
		}

		// 2) Fallback: daily stats list (some ROMs return sparse aggregate maps).
		val usageStatsList = usageStatsManager.queryUsageStats(
			UsageStatsManager.INTERVAL_DAILY,
			startTime,
			endTime,
		)
		usageStatsList?.forEach { stats ->
			val pkg = stats.packageName
			if (targetPackages.contains(pkg)) {
				val current = usageMsByPackage[pkg] ?: 0L
				usageMsByPackage[pkg] = maxOf(current, stats.totalTimeInForeground)
			}
		}

		// 3) Fallback: reconstruct rough usage from foreground/background events.
		val activeStarts = mutableMapOf<String, Long>()
		val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
		val event = UsageEvents.Event()
		while (usageEvents.hasNextEvent()) {
			usageEvents.getNextEvent(event)
			val pkg = event.packageName ?: continue
			if (!targetPackages.contains(pkg)) {
				continue
			}
			when (event.eventType) {
				UsageEvents.Event.MOVE_TO_FOREGROUND,
				UsageEvents.Event.ACTIVITY_RESUMED -> {
					activeStarts[pkg] = event.timeStamp
				}
				UsageEvents.Event.MOVE_TO_BACKGROUND,
				UsageEvents.Event.ACTIVITY_PAUSED,
				UsageEvents.Event.ACTIVITY_STOPPED -> {
					val startedAt = activeStarts.remove(pkg)
					if (startedAt != null && event.timeStamp >= startedAt) {
						val delta = event.timeStamp - startedAt
						usageMsByPackage[pkg] = (usageMsByPackage[pkg] ?: 0L) + delta
					}
				}
			}
		}

		// Close open foreground windows at end time.
		activeStarts.forEach { (pkg, startedAt) ->
			if (endTime >= startedAt) {
				val delta = endTime - startedAt
				usageMsByPackage[pkg] = (usageMsByPackage[pkg] ?: 0L) + delta
			}
		}

		return packageNames.associateWith { packageName ->
			val usedMs = usageMsByPackage[packageName] ?: 0L
			(usedMs / 60000L).toInt()
		}
	}

	private fun getRecentForegroundAppPackage(): String? {
		val usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
		val endTime = System.currentTimeMillis()
		val startTime = endTime - 10 * 60 * 1000L

		val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
		val event = UsageEvents.Event()
		var recentPackage: String? = null

		while (usageEvents.hasNextEvent()) {
			usageEvents.getNextEvent(event)
			if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
				val packageName = event.packageName
				if (!packageName.isNullOrBlank() && packageName != this.packageName) {
					recentPackage = packageName
				}
			}
		}

		return recentPackage
	}

	private fun launchAppByPackage(targetPackage: String): Boolean {
		return try {
			val launchIntent = packageManager.getLaunchIntentForPackage(targetPackage) ?: return false
			launchIntent.action = Intent.ACTION_MAIN
			launchIntent.addCategory(Intent.CATEGORY_LAUNCHER)
			launchIntent.addFlags(
				Intent.FLAG_ACTIVITY_NEW_TASK or
					Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED or
					Intent.FLAG_ACTIVITY_SINGLE_TOP,
			)
			startActivity(launchIntent)
			true
		} catch (_: Exception) {
			false
		}
	}

	private fun openHomeScreen(): Boolean {
		return try {
			val homeIntent = Intent(Intent.ACTION_MAIN).apply {
				addCategory(Intent.CATEGORY_HOME)
				addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
			}
			startActivity(homeIntent)
			true
		} catch (_: Exception) {
			false
		}
	}

	private fun canDrawOverlays(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return true
		}
		return Settings.canDrawOverlays(this)
	}

	private fun openOverlaySettings() {
		val appSpecificIntent = Intent(
			Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
			Uri.parse("package:$packageName"),
		).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		val genericIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		val appDetailsIntent = Intent(
			Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
			Uri.fromParts("package", packageName, null),
		).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		when {
			appSpecificIntent.resolveActivity(packageManager) != null -> startActivity(appSpecificIntent)
			genericIntent.resolveActivity(packageManager) != null -> startActivity(genericIntent)
			else -> startActivity(appDetailsIntent)
		}
	}

	private fun areNotificationsEnabled(): Boolean {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
			checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
		} else {
			androidx.core.app.NotificationManagerCompat.from(this).areNotificationsEnabled()
		}
	}

	private fun canRequestNotificationPermission(): Boolean {
		return Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
	}

	private fun requestNotificationPermission(result: MethodChannel.Result) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
			result.success(areNotificationsEnabled())
			return
		}

		if (areNotificationsEnabled()) {
			result.success(true)
			return
		}

		if (pendingNotificationPermissionResult != null) {
			result.error("REQUEST_IN_PROGRESS", "Notification permission request already in progress", null)
			return
		}

		pendingNotificationPermissionResult = result
		requestPermissions(
			arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
			REQUEST_POST_NOTIFICATIONS,
		)
	}

	private fun openNotificationSettings() {
		val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
			Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
				putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
			}
		} else {
			Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
				data = Uri.fromParts("package", packageName, null)
			}
		}

		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		startActivity(intent)
	}

	private fun isIgnoringBatteryOptimizations(): Boolean {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return true
		}
		val powerManager = getSystemService(POWER_SERVICE) as PowerManager
		return powerManager.isIgnoringBatteryOptimizations(packageName)
	}

	private fun openBatteryOptimizationSettings() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
			return
		}

		val requestIntent = Intent(
			Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
			Uri.parse("package:$packageName"),
		).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		val listIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		val appDetailsIntent = Intent(
			Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
			Uri.fromParts("package", packageName, null),
		).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}

		when {
			requestIntent.resolveActivity(packageManager) != null -> startActivity(requestIntent)
			listIntent.resolveActivity(packageManager) != null -> startActivity(listIntent)
			else -> startActivity(appDetailsIntent)
		}
	}

	private fun isAccessibilityEnabled(): Boolean {
		val expected = "$packageName/${GuardAccessibilityService::class.java.name}"
		val enabledServices = Settings.Secure.getString(
			contentResolver,
			Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
		)

		if (enabledServices.isNullOrBlank()) {
			return false
		}

		return enabledServices
			.split(':')
			.any { it.equals(expected, ignoreCase = true) }
	}

	private fun openAccessibilitySettings() {
		val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
		}
		startActivity(intent)
	}

	private fun notifyPendingPromptPackage() {
		val packageName = pendingPromptPackage ?: return
		interceptionMethodChannel?.invokeMethod("promptPackagePending", packageName)
	}
}
