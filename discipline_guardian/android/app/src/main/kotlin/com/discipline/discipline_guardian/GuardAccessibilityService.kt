package com.discipline.discipline_guardian

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent
import java.util.Collections

class GuardAccessibilityService : AccessibilityService() {
	companion object {
		const val PREF_FILE = "guardian_interception_rules"
		const val PREF_BLOCKED_PACKAGES = "blocked_packages"
		const val PREF_ENABLED = "interception_enabled"
		private const val PENDING_PROMPT_DEBOUNCE_MS = 1200L
		private const val PROMPT_AFTER_HOME_DELAY_MS = 380L
		private const val SHOWN_PROMPT_DEBOUNCE_MS = 900L

		private val blockedPackages = Collections.synchronizedSet(mutableSetOf<String>())
		private val promptStateLock = Any()
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

		fun loadPersistedRules(context: Context) {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			val persistedBlocked = prefs.getStringSet(PREF_BLOCKED_PACKAGES, emptySet()) ?: emptySet()
			blockedPackages.clear()
			blockedPackages.addAll(persistedBlocked)
			interceptionEnabled = prefs.getBoolean(PREF_ENABLED, false)
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

	override fun onAccessibilityEvent(event: AccessibilityEvent?) {
		if (blockedPackages.isEmpty()) {
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

		val packageName = event.packageName?.toString()?.trim()
		if (packageName.isNullOrEmpty() || packageName == this.packageName) {
			return
		}

		val previousPackage = lastForegroundPackage
		lastForegroundPackage = packageName
		if (!interceptionEnabled) {
			return
		}

		if (blockedPackages.contains(packageName)) {
			val now = System.currentTimeMillis()
			val isForegroundTransition =
				previousPackage == null || !previousPackage.equals(packageName, ignoreCase = true)
			if (!isForegroundTransition) {
				return
			}
			if (shouldSkipRecentlyShownPrompt(packageName, now)) {
				return
			}
			if (!reservePrompt(packageName, now)) {
				return
			}
			lastInterceptedPackage = packageName
			// Reset foreground cache after interception so re-entering the same
			// blocked app from task switcher is still treated as a fresh transition.
			lastForegroundPackage = null
			performGlobalAction(GLOBAL_ACTION_HOME)
			promptHandler.removeCallbacksAndMessages(null)
			promptHandler.postDelayed(
				{ showInterceptPrompt(packageName) },
				PROMPT_AFTER_HOME_DELAY_MS,
			)
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
		promptHandler.removeCallbacksAndMessages(null)
		super.onDestroy()
	}

	private fun showInterceptPrompt(packageName: String) {
		val now = System.currentTimeMillis()
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
				val appName = try {
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
				clearReservedPrompt(packageName)
			}
		}
		if (!launched) {
			clearReservedPrompt(packageName)
			return
		}
		markPromptShown(packageName, now)
	}
}
