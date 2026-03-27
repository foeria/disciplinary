package com.discipline.discipline_guardian

import android.accessibilityservice.AccessibilityService
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Collections
import java.util.Locale

class GuardAccessibilityService : AccessibilityService() {
	private data class UsageMonitoringRule(
		val packageName: String,
		val appName: String,
		val baseLimitMinutes: Int,
		val unlockLimitOverrideMinutes: Int?,
		val unlockLimitOverrideDate: String?,
	) {
		fun resolveEffectiveLimitMinutes(today: String): Int {
			if (
				unlockLimitOverrideMinutes != null &&
				!unlockLimitOverrideDate.isNullOrBlank() &&
				unlockLimitOverrideDate == today
			) {
				return unlockLimitOverrideMinutes
			}
			return baseLimitMinutes
		}

		fun toJson(): JSONObject {
			return JSONObject()
				.put("packageName", packageName)
				.put("appName", appName)
				.put("baseLimitMinutes", baseLimitMinutes)
				.put("unlockLimitOverrideMinutes", unlockLimitOverrideMinutes)
				.put("unlockLimitOverrideDate", unlockLimitOverrideDate)
		}
	}

	private data class MonitoringScheduleConfig(
		val enabled: Boolean,
		val workdayStart: String,
		val workdayEnd: String,
		val weekendStart: String,
		val weekendEnd: String,
	)

	companion object {
		const val PREF_FILE = "guardian_interception_rules"
		const val PREF_BLOCKED_PACKAGES = "blocked_packages"
		const val PREF_ENABLED = "interception_enabled"
		private const val PREF_USAGE_MONITORING_RULES = "usage_monitoring_rules"
		private const val PREF_USAGE_REMINDER_ENABLED = "usage_reminder_enabled"
		private const val PREF_USAGE_REMINDER_MINUTES = "usage_reminder_minutes"
		private const val PREF_USAGE_NOTIFICATIONS_ENABLED = "usage_notifications_enabled"
		private const val PREF_USAGE_SOUND_ENABLED = "usage_sound_enabled"
		private const val PREF_USAGE_SCHEDULE_ENABLED = "usage_schedule_enabled"
		private const val PREF_USAGE_WORKDAY_START = "usage_workday_start"
		private const val PREF_USAGE_WORKDAY_END = "usage_workday_end"
		private const val PREF_USAGE_WEEKEND_START = "usage_weekend_start"
		private const val PREF_USAGE_WEEKEND_END = "usage_weekend_end"
		private const val PENDING_PROMPT_DEBOUNCE_MS = 1200L
		private const val PROMPT_AFTER_HOME_DELAY_MS = 160L
		private const val PROMPT_AFTER_HOME_FALLBACK_DELAY_MS = 320L
		private const val SHOWN_PROMPT_DEBOUNCE_MS = 900L
		private const val DEFAULT_REMINDER_MINUTES = 3
		private const val USAGE_REMINDER_CHANNEL_ID = "discipline_guardian.usage_reminders"
		private const val USAGE_REMINDER_CHANNEL_NAME = "使用时限提醒"

		private val blockedPackages = Collections.synchronizedSet(mutableSetOf<String>())
		private val monitoredRulesByPackage =
			Collections.synchronizedMap(mutableMapOf<String, UsageMonitoringRule>())
		private val promptStateLock = Any()
		private val scheduleLock = Any()

		@Volatile
		private var interceptionEnabled: Boolean = false

		@Volatile
		private var lastForegroundPackage: String? = null

		@Volatile
		private var lastInterceptedPackage: String? = null

		@Volatile
		private var pendingPromptPackage: String? = null

		@Volatile
		private var pendingPromptAtMs: Long = 0L

		@Volatile
		private var lastPromptPackage: String? = null

		@Volatile
		private var lastPromptAtMs: Long = 0L

		@Volatile
		private var usageReminderEnabled: Boolean = false

		@Volatile
		private var usageReminderMinutes: Int = DEFAULT_REMINDER_MINUTES

		@Volatile
		private var usageNotificationsEnabled: Boolean = false

		@Volatile
		private var usageSoundEnabled: Boolean = true

		@Volatile
		private var monitoringSchedule = MonitoringScheduleConfig(
			enabled = false,
			workdayStart = "00:00",
			workdayEnd = "23:59",
			weekendStart = "00:00",
			weekendEnd = "23:59",
		)

		fun updateBlockedPackages(packages: List<String>) {
			blockedPackages.clear()
			blockedPackages.addAll(packages.filter { it.isNotBlank() })
		}

		fun persistBlockedPackages(context: Context, packages: List<String>) {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			prefs.edit().putStringSet(PREF_BLOCKED_PACKAGES, packages.toSet()).apply()
		}

		fun setInterceptionEnabled(enabled: Boolean) {
			interceptionEnabled = enabled
		}

		fun persistInterceptionEnabled(context: Context, enabled: Boolean) {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			prefs.edit().putBoolean(PREF_ENABLED, enabled).apply()
		}

		fun updateUsageMonitoringConfig(
			context: Context,
			rules: List<Map<String, Any?>>,
			reminderEnabled: Boolean,
			reminderMinutes: Int,
			notificationsEnabled: Boolean,
			soundEnabled: Boolean,
			scheduleEnabled: Boolean,
			workdayStart: String,
			workdayEnd: String,
			weekendStart: String,
			weekendEnd: String,
		) {
			val parsedRules = rules.mapNotNull { rawRule ->
				val packageName = (rawRule["packageName"] as? String)?.trim().orEmpty()
				if (packageName.isEmpty()) {
					return@mapNotNull null
				}

				val baseLimitMinutes = toIntValue(rawRule["baseLimitMinutes"])?.coerceAtLeast(1)
					?: return@mapNotNull null
				UsageMonitoringRule(
					packageName = packageName,
					appName = (rawRule["appName"] as? String)?.trim().orEmpty().ifBlank { packageName },
					baseLimitMinutes = baseLimitMinutes,
					unlockLimitOverrideMinutes =
						toIntValue(rawRule["unlockLimitOverrideMinutes"])?.coerceAtLeast(1),
					unlockLimitOverrideDate =
						(rawRule["unlockLimitOverrideDate"] as? String)?.trim()?.ifBlank { null },
				)
			}

			applyUsageMonitoringConfig(
				rules = parsedRules,
				reminderEnabled = reminderEnabled,
				reminderMinutes = reminderMinutes,
				notificationsEnabled = notificationsEnabled,
				soundEnabled = soundEnabled,
				scheduleEnabled = scheduleEnabled,
				workdayStart = workdayStart,
				workdayEnd = workdayEnd,
				weekendStart = weekendStart,
				weekendEnd = weekendEnd,
			)
			persistUsageMonitoringConfig(
				context = context,
				rules = parsedRules,
				reminderEnabled = reminderEnabled,
				reminderMinutes = reminderMinutes,
				notificationsEnabled = notificationsEnabled,
				soundEnabled = soundEnabled,
				scheduleEnabled = scheduleEnabled,
				workdayStart = workdayStart,
				workdayEnd = workdayEnd,
				weekendStart = weekendStart,
				weekendEnd = weekendEnd,
			)
		}

		fun loadPersistedRules(context: Context) {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			val persistedBlocked = prefs.getStringSet(PREF_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
			blockedPackages.clear()
			blockedPackages.addAll(persistedBlocked)
			interceptionEnabled = prefs.getBoolean(PREF_ENABLED, false)

			val rulesJson = prefs.getString(PREF_USAGE_MONITORING_RULES, null)
			val parsedRules = mutableListOf<UsageMonitoringRule>()
			if (!rulesJson.isNullOrBlank()) {
				runCatching {
					val jsonArray = JSONArray(rulesJson)
					for (index in 0 until jsonArray.length()) {
						val item = jsonArray.optJSONObject(index) ?: continue
						val packageName = item.optString("packageName").trim()
						if (packageName.isEmpty()) {
							continue
						}
						val baseLimitMinutes = item.optInt("baseLimitMinutes", 0)
						if (baseLimitMinutes <= 0) {
							continue
						}
						parsedRules += UsageMonitoringRule(
							packageName = packageName,
							appName = item.optString("appName").trim().ifBlank { packageName },
							baseLimitMinutes = baseLimitMinutes,
							unlockLimitOverrideMinutes =
								item.takeIf { !it.isNull("unlockLimitOverrideMinutes") }
									?.optInt("unlockLimitOverrideMinutes"),
							unlockLimitOverrideDate =
								item.takeIf { !it.isNull("unlockLimitOverrideDate") }
									?.optString("unlockLimitOverrideDate")
									?.trim()
									?.ifBlank { null },
						)
					}
				}
			}

			applyUsageMonitoringConfig(
				rules = parsedRules,
				reminderEnabled = prefs.getBoolean(PREF_USAGE_REMINDER_ENABLED, false),
				reminderMinutes = prefs.getInt(PREF_USAGE_REMINDER_MINUTES, DEFAULT_REMINDER_MINUTES),
				notificationsEnabled = prefs.getBoolean(PREF_USAGE_NOTIFICATIONS_ENABLED, false),
				soundEnabled = prefs.getBoolean(PREF_USAGE_SOUND_ENABLED, true),
				scheduleEnabled = prefs.getBoolean(PREF_USAGE_SCHEDULE_ENABLED, false),
				workdayStart = prefs.getString(PREF_USAGE_WORKDAY_START, "00:00") ?: "00:00",
				workdayEnd = prefs.getString(PREF_USAGE_WORKDAY_END, "23:59") ?: "23:59",
				weekendStart = prefs.getString(PREF_USAGE_WEEKEND_START, "00:00") ?: "00:00",
				weekendEnd = prefs.getString(PREF_USAGE_WEEKEND_END, "23:59") ?: "23:59",
			)
		}

		private fun applyUsageMonitoringConfig(
			rules: List<UsageMonitoringRule>,
			reminderEnabled: Boolean,
			reminderMinutes: Int,
			notificationsEnabled: Boolean,
			soundEnabled: Boolean,
			scheduleEnabled: Boolean,
			workdayStart: String,
			workdayEnd: String,
			weekendStart: String,
			weekendEnd: String,
		) {
			monitoredRulesByPackage.clear()
			rules.forEach { rule ->
				monitoredRulesByPackage[rule.packageName] = rule
			}
			usageReminderEnabled = reminderEnabled
			usageReminderMinutes = reminderMinutes.coerceIn(1, 60)
			usageNotificationsEnabled = notificationsEnabled
			usageSoundEnabled = soundEnabled
			synchronized(scheduleLock) {
				monitoringSchedule = MonitoringScheduleConfig(
					enabled = scheduleEnabled,
					workdayStart = workdayStart,
					workdayEnd = workdayEnd,
					weekendStart = weekendStart,
					weekendEnd = weekendEnd,
				)
			}
		}

		private fun persistUsageMonitoringConfig(
			context: Context,
			rules: List<UsageMonitoringRule>,
			reminderEnabled: Boolean,
			reminderMinutes: Int,
			notificationsEnabled: Boolean,
			soundEnabled: Boolean,
			scheduleEnabled: Boolean,
			workdayStart: String,
			workdayEnd: String,
			weekendStart: String,
			weekendEnd: String,
		) {
			val jsonArray = JSONArray()
			rules.forEach { rule -> jsonArray.put(rule.toJson()) }
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			prefs.edit()
				.putString(PREF_USAGE_MONITORING_RULES, jsonArray.toString())
				.putBoolean(PREF_USAGE_REMINDER_ENABLED, reminderEnabled)
				.putInt(PREF_USAGE_REMINDER_MINUTES, reminderMinutes.coerceIn(1, 60))
				.putBoolean(PREF_USAGE_NOTIFICATIONS_ENABLED, notificationsEnabled)
				.putBoolean(PREF_USAGE_SOUND_ENABLED, soundEnabled)
				.putBoolean(PREF_USAGE_SCHEDULE_ENABLED, scheduleEnabled)
				.putString(PREF_USAGE_WORKDAY_START, workdayStart)
				.putString(PREF_USAGE_WORKDAY_END, workdayEnd)
				.putString(PREF_USAGE_WEEKEND_START, weekendStart)
				.putString(PREF_USAGE_WEEKEND_END, weekendEnd)
				.apply()
		}

		private fun toIntValue(value: Any?): Int? {
			return when (value) {
				is Int -> value
				is Long -> value.toInt()
				is Double -> value.toInt()
				is Float -> value.toInt()
				is String -> value.toIntOrNull()
				else -> null
			}
		}

		fun getLastForegroundPackage(): String? = lastForegroundPackage

		fun getLastInterceptedPackage(): String? = lastInterceptedPackage

		fun consumeLastInterceptedPackage(): String? {
			val value = lastInterceptedPackage
			lastInterceptedPackage = null
			return value
		}

		fun getBlockedPackageCount(): Int = blockedPackages.size

		fun isInterceptionEnabled(): Boolean = interceptionEnabled

		fun resetPromptState(packageName: String?) {
			synchronized(promptStateLock) {
				val targetPackage = packageName?.trim()
				if (targetPackage.isNullOrEmpty()) {
					pendingPromptPackage = null
					pendingPromptAtMs = 0L
					lastPromptPackage = null
					lastPromptAtMs = 0L
					return
				}

				if (pendingPromptPackage?.equals(targetPackage, ignoreCase = true) == true) {
					pendingPromptPackage = null
					pendingPromptAtMs = 0L
				}
				if (lastPromptPackage?.equals(targetPackage, ignoreCase = true) == true) {
					lastPromptPackage = null
					lastPromptAtMs = 0L
				}
			}
		}

		private fun reservePrompt(packageName: String, nowMs: Long): Boolean {
			synchronized(promptStateLock) {
				val pendingPackage = pendingPromptPackage
				if (
					pendingPackage != null &&
					pendingPackage.equals(packageName, ignoreCase = true) &&
					nowMs - pendingPromptAtMs < PENDING_PROMPT_DEBOUNCE_MS
				) {
					return false
				}

				pendingPromptPackage = packageName
				pendingPromptAtMs = nowMs
				return true
			}
		}

		private fun consumeReservedPrompt(packageName: String, nowMs: Long): Boolean {
			synchronized(promptStateLock) {
				val pendingPackage = pendingPromptPackage
				if (
					pendingPackage != null &&
					!pendingPackage.equals(packageName, ignoreCase = true) &&
					nowMs - pendingPromptAtMs < PENDING_PROMPT_DEBOUNCE_MS
				) {
					return false
				}

				pendingPromptPackage = null
				return true
			}
		}

		private fun markPromptShown(packageName: String, nowMs: Long) {
			synchronized(promptStateLock) {
				lastPromptPackage = packageName
				lastPromptAtMs = nowMs
			}
		}

		private fun shouldSkipRecentlyShownPrompt(packageName: String, nowMs: Long): Boolean {
			synchronized(promptStateLock) {
				return lastPromptPackage?.equals(packageName, ignoreCase = true) == true &&
					nowMs - lastPromptAtMs < SHOWN_PROMPT_DEBOUNCE_MS
			}
		}

		private fun clearReservedPrompt(packageName: String) {
			synchronized(promptStateLock) {
				val pendingPackage = pendingPromptPackage
				if (pendingPackage != null && pendingPackage.equals(packageName, ignoreCase = true)) {
					pendingPromptPackage = null
				}
			}
		}
	}

	private val promptHandler = Handler(Looper.getMainLooper())
	private val usageMonitorHandler = Handler(Looper.getMainLooper())
	private var activeMonitoringPackage: String? = null
	private var pendingUsageReminder: Runnable? = null
	private var pendingUsageTimeout: Runnable? = null

	override fun onAccessibilityEvent(event: AccessibilityEvent?) {
		if (blockedPackages.isEmpty() && monitoredRulesByPackage.isEmpty()) {
			loadPersistedRules(applicationContext)
		}

		if (event == null) {
			return
		}
		if (
			event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
			event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
		) {
			return
		}

		val packageName = resolveForegroundPackage(event)
		if (packageName.isNullOrEmpty()) {
			return
		}

		val previousPackage = lastForegroundPackage
		val isForegroundTransition =
			previousPackage == null || !previousPackage.equals(packageName, ignoreCase = true)
		lastForegroundPackage = packageName

		if (isForegroundTransition) {
			cancelUsageMonitoringIfDifferent(packageName)
		}

		if (packageName == this.packageName) {
			if (isForegroundTransition) {
				cancelUsageMonitoring()
			}
			return
		}

		if (!interceptionEnabled) {
			return
		}

		if (blockedPackages.contains(packageName)) {
			if (!isForegroundTransition) {
				return
			}
			interceptPackage(packageName)
			return
		}

		if (isForegroundTransition) {
			scheduleUsageMonitoring(packageName)
		}
	}

	override fun onInterrupt() {
		// no-op
	}

	override fun onServiceConnected() {
		super.onServiceConnected()
		loadPersistedRules(applicationContext)
	}

	override fun onDestroy() {
		cancelUsageMonitoring()
		promptHandler.removeCallbacksAndMessages(null)
		usageMonitorHandler.removeCallbacksAndMessages(null)
		super.onDestroy()
	}

	private fun scheduleUsageMonitoring(packageName: String) {
		cancelUsageMonitoring()

		val rule = monitoredRulesByPackage[packageName] ?: return
		if (!shouldApplyUsageMonitoringNow()) {
			return
		}

		val remainingMs = computeRemainingUsageMs(packageName, rule)
		activeMonitoringPackage = packageName
		if (remainingMs <= 0L) {
			maybeInterceptForUsageLimit(packageName)
			return
		}

		val reminderWindowMs = usageReminderMinutes.coerceAtLeast(1) * 60_000L
		if (shouldShowUsageReminder()) {
			if (remainingMs <= reminderWindowMs) {
				showUsageReminderIfStillEligible(packageName)
			} else {
				val reminderRunnable = Runnable { showUsageReminderIfStillEligible(packageName) }
				pendingUsageReminder = reminderRunnable
				usageMonitorHandler.postDelayed(reminderRunnable, remainingMs - reminderWindowMs)
			}
		}

		val timeoutRunnable = Runnable { maybeInterceptForUsageLimit(packageName) }
		pendingUsageTimeout = timeoutRunnable
		usageMonitorHandler.postDelayed(timeoutRunnable, remainingMs)
	}

	private fun showUsageReminderIfStillEligible(packageName: String) {
		if (!interceptionEnabled || !isMonitoringCurrentPackage(packageName)) {
			return
		}
		if (!shouldShowUsageReminder() || !shouldApplyUsageMonitoringNow()) {
			cancelUsageReminderNotification(packageName)
			return
		}

		val rule = monitoredRulesByPackage[packageName] ?: return
		val remainingMs = computeRemainingUsageMs(packageName, rule)
		if (remainingMs <= 0L) {
			maybeInterceptForUsageLimit(packageName)
			return
		}

		val reminderWindowMs = usageReminderMinutes.coerceAtLeast(1) * 60_000L
		if (remainingMs > reminderWindowMs) {
			scheduleUsageMonitoring(packageName)
			return
		}

		val remainingMinutes = ((remainingMs + 59_999L) / 60_000L).toInt().coerceAtLeast(1)
		showUsageReminderNotification(
			packageName = packageName,
			appName = rule.appName,
			remainingMinutes = remainingMinutes,
		)
	}

	private fun maybeInterceptForUsageLimit(packageName: String) {
		if (!interceptionEnabled || !isMonitoringCurrentPackage(packageName)) {
			return
		}
		if (!shouldApplyUsageMonitoringNow()) {
			cancelUsageMonitoring()
			return
		}

		val rule = monitoredRulesByPackage[packageName] ?: return
		val remainingMs = computeRemainingUsageMs(packageName, rule)
		if (remainingMs > 0L) {
			scheduleUsageMonitoring(packageName)
			return
		}

		cancelUsageMonitoring()
		interceptPackage(packageName)
	}

	private fun interceptPackage(packageName: String) {
		val now = System.currentTimeMillis()
		if (shouldSkipRecentlyShownPrompt(packageName, now)) {
			return
		}
		if (!reservePrompt(packageName, now)) {
			return
		}

		lastInterceptedPackage = packageName
		cancelUsageReminderNotification(packageName)
		lastForegroundPackage = null
		performGlobalAction(GLOBAL_ACTION_HOME)
		promptHandler.removeCallbacksAndMessages(null)
		promptHandler.postDelayed(
			{ showInterceptPrompt(packageName, isFallbackAttempt = false) },
			PROMPT_AFTER_HOME_DELAY_MS,
		)
		promptHandler.postDelayed(
			{ showInterceptPrompt(packageName, isFallbackAttempt = true) },
			PROMPT_AFTER_HOME_FALLBACK_DELAY_MS,
		)
	}

	private fun showInterceptPrompt(packageName: String, isFallbackAttempt: Boolean) {
		val now = System.currentTimeMillis()
		if (shouldSkipRecentlyShownPrompt(packageName, now)) {
			return
		}
		if (!consumeReservedPrompt(packageName, now)) {
			return
		}

		var launched = false
		try {
			val promptIntent = Intent(this, MainActivity::class.java).apply {
				addFlags(
					Intent.FLAG_ACTIVITY_NEW_TASK or
						Intent.FLAG_ACTIVITY_SINGLE_TOP or
						Intent.FLAG_ACTIVITY_CLEAR_TOP or
						Intent.FLAG_ACTIVITY_NO_ANIMATION,
				)
				putExtra(MainActivity.EXTRA_PROMPT_PACKAGE, packageName)
			}
			startActivity(promptIntent)
			launched = true
		} catch (_: Exception) {
			try {
				val appName = monitoredRulesByPackage[packageName]?.appName ?: try {
					val appInfo = packageManager.getApplicationInfo(packageName, 0)
					packageManager.getApplicationLabel(appInfo).toString()
				} catch (_: Exception) {
					packageName
				}

				val fallbackIntent = Intent(this, InterceptPromptActivity::class.java).apply {
					addFlags(
						Intent.FLAG_ACTIVITY_NEW_TASK or
							Intent.FLAG_ACTIVITY_SINGLE_TOP or
							Intent.FLAG_ACTIVITY_CLEAR_TOP or
							Intent.FLAG_ACTIVITY_NO_ANIMATION,
					)
					putExtra(InterceptPromptActivity.EXTRA_PACKAGE_NAME, packageName)
					putExtra(InterceptPromptActivity.EXTRA_APP_NAME, appName)
				}
				startActivity(fallbackIntent)
				launched = true
			} catch (_: Exception) {
				if (!isFallbackAttempt) {
					reservePrompt(packageName, now)
					return
				}
				clearReservedPrompt(packageName)
			}
		}
		if (!launched) {
			if (!isFallbackAttempt) {
				reservePrompt(packageName, now)
				return
			}
			clearReservedPrompt(packageName)
			return
		}
		markPromptShown(packageName, now)
	}

	private fun resolveForegroundPackage(event: AccessibilityEvent): String? {
		val rawPackage = event.packageName?.toString()?.trim().orEmpty()
		if (rawPackage.isEmpty()) {
			return queryRecentForegroundPackage()
		}

		if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
			return rawPackage
		}

		if (shouldTrustWindowsChangedPackage(rawPackage)) {
			return rawPackage
		}

		return queryRecentForegroundPackage() ?: rawPackage
	}

	private fun shouldTrustWindowsChangedPackage(packageName: String): Boolean {
		if (packageName.equals(this.packageName, ignoreCase = true)) {
			return true
		}
		if (blockedPackages.contains(packageName) || monitoredRulesByPackage.containsKey(packageName)) {
			return true
		}

		val currentForegroundPackage = lastForegroundPackage
		if (
			currentForegroundPackage != null &&
			currentForegroundPackage.equals(packageName, ignoreCase = true)
		) {
			return true
		}

		val currentMonitoringPackage = activeMonitoringPackage
		return currentMonitoringPackage != null &&
			currentMonitoringPackage.equals(packageName, ignoreCase = true)
	}

	private fun queryRecentForegroundPackage(): String? {
		return UsageStatsSupport.getRecentForegroundAppPackage(
			context = applicationContext,
			excludedPackage = packageName,
		)?.trim()?.ifEmpty { null }
	}

	private fun computeRemainingUsageMs(
		packageName: String,
		rule: UsageMonitoringRule,
	): Long {
		val effectiveLimitMinutes = rule.resolveEffectiveLimitMinutes(currentDateKey())
		if (effectiveLimitMinutes <= 0) {
			return 0L
		}
		val usedMs = UsageStatsSupport.queryTodayUsageMillis(
			context = applicationContext,
			packageNames = listOf(packageName),
		)[packageName] ?: 0L
		return effectiveLimitMinutes * 60_000L - usedMs
	}

	private fun shouldShowUsageReminder(): Boolean {
		return usageReminderEnabled &&
			usageNotificationsEnabled &&
			usageReminderMinutes > 0
	}

	private fun shouldApplyUsageMonitoringNow(): Boolean {
		val schedule = synchronized(scheduleLock) { monitoringSchedule }
		if (!schedule.enabled) {
			return true
		}

		val now = Calendar.getInstance()
		val minutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
		val isWeekend = now.get(Calendar.DAY_OF_WEEK) == Calendar.SATURDAY ||
			now.get(Calendar.DAY_OF_WEEK) == Calendar.SUNDAY
		val start = timeStringToMinutes(
			if (isWeekend) schedule.weekendStart else schedule.workdayStart,
		)
		val end = timeStringToMinutes(
			if (isWeekend) schedule.weekendEnd else schedule.workdayEnd,
		)

		if (start == end) {
			return true
		}
		if (start < end) {
			return minutes in start..end
		}
		return minutes >= start || minutes <= end
	}

	private fun timeStringToMinutes(value: String): Int {
		val parts = value.split(':')
		if (parts.size != 2) {
			return 0
		}
		val hour = parts[0].toIntOrNull()?.coerceIn(0, 23) ?: 0
		val minute = parts[1].toIntOrNull()?.coerceIn(0, 59) ?: 0
		return hour * 60 + minute
	}

	private fun currentDateKey(): String {
		val now = Calendar.getInstance()
		return String.format(
			Locale.US,
			"%04d-%02d-%02d",
			now.get(Calendar.YEAR),
			now.get(Calendar.MONTH) + 1,
			now.get(Calendar.DAY_OF_MONTH),
		)
	}

	private fun isMonitoringCurrentPackage(packageName: String): Boolean {
		val activePackage = activeMonitoringPackage
		val foregroundPackage = lastForegroundPackage
		return activePackage != null &&
			activePackage.equals(packageName, ignoreCase = true) &&
			foregroundPackage != null &&
			foregroundPackage.equals(packageName, ignoreCase = true)
	}

	private fun cancelUsageMonitoringIfDifferent(packageName: String) {
		val activePackage = activeMonitoringPackage ?: return
		if (!activePackage.equals(packageName, ignoreCase = true)) {
			cancelUsageMonitoring()
		}
	}

	private fun cancelUsageMonitoring() {
		pendingUsageReminder?.let(usageMonitorHandler::removeCallbacks)
		pendingUsageTimeout?.let(usageMonitorHandler::removeCallbacks)
		pendingUsageReminder = null
		pendingUsageTimeout = null
		activeMonitoringPackage?.let(::cancelUsageReminderNotification)
		activeMonitoringPackage = null
	}

	private fun showUsageReminderNotification(
		packageName: String,
		appName: String,
		remainingMinutes: Int,
	) {
		createUsageReminderNotificationChannel()

		val notificationId = usageReminderNotificationId(packageName)
		val pendingIntent = PendingIntent.getActivity(
			this,
			notificationId,
			Intent(this, MainActivity::class.java).apply {
				addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
			},
			PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
		)

		val title = if (remainingMinutes <= 1) {
			"$appName 即将达到使用时限"
		} else {
			"$appName 还剩 $remainingMinutes 分钟"
		}
		val content = "请尽快收尾，超时后会自动触发拦截。"
		val notification = NotificationCompat.Builder(this, USAGE_REMINDER_CHANNEL_ID)
			.setSmallIcon(android.R.drawable.ic_dialog_info)
			.setContentTitle(title)
			.setContentText(content)
			.setStyle(NotificationCompat.BigTextStyle().bigText(content))
			.setContentIntent(pendingIntent)
			.setAutoCancel(true)
			.setOnlyAlertOnce(true)
			.setCategory(NotificationCompat.CATEGORY_REMINDER)
			.setPriority(NotificationCompat.PRIORITY_HIGH)
			.setSilent(!usageSoundEnabled)
			.build()

		NotificationManagerCompat.from(this).notify(notificationId, notification)
	}

	private fun createUsageReminderNotificationChannel() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
			return
		}

		val notificationManager = getSystemService(NotificationManager::class.java) ?: return
		val existingChannel = notificationManager.getNotificationChannel(USAGE_REMINDER_CHANNEL_ID)
		if (existingChannel != null) {
			return
		}

		val importance = if (usageSoundEnabled) {
			NotificationManager.IMPORTANCE_HIGH
		} else {
			NotificationManager.IMPORTANCE_DEFAULT
		}
		val channel = NotificationChannel(
			USAGE_REMINDER_CHANNEL_ID,
			USAGE_REMINDER_CHANNEL_NAME,
			importance,
		).apply {
			description = "接近使用时限时发送提醒，超时后触发拦截。"
		}
		notificationManager.createNotificationChannel(channel)
	}

	private fun cancelUsageReminderNotification(packageName: String) {
		NotificationManagerCompat.from(this).cancel(usageReminderNotificationId(packageName))
	}

	private fun usageReminderNotificationId(packageName: String): Int {
		return 520_000 + (packageName.hashCode() and 0x00FF_FFFF)
	}
}
