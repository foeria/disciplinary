package com.discipline.discipline_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class GuardianKeepAliveReceiver : BroadcastReceiver() {
	override fun onReceive(context: Context, intent: Intent?) {
		when (intent?.action) {
			Intent.ACTION_BOOT_COMPLETED,
			Intent.ACTION_MY_PACKAGE_REPLACED,
			GuardianKeepAliveService.ACTION_RESTART -> {
				GuardAccessibilityService.loadPersistedRules(context.applicationContext)
				GuardianKeepAliveService.ensureRunningIfEnabled(context.applicationContext)
			}
		}
	}
}
