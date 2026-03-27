package com.discipline.discipline_guardian

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import java.util.Calendar

object UsageStatsSupport {
	fun queryTodayUsageMillis(
		context: Context,
		packageNames: Collection<String>,
	): Map<String, Long> {
		if (packageNames.isEmpty()) {
			return emptyMap()
		}

		val targetPackages = packageNames
			.map { it.trim() }
			.filter { it.isNotEmpty() }
			.toSet()
		if (targetPackages.isEmpty()) {
			return emptyMap()
		}

		val usageStatsManager =
			context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
		val endTime = System.currentTimeMillis()
		val startCalendar = Calendar.getInstance().apply {
			set(Calendar.HOUR_OF_DAY, 0)
			set(Calendar.MINUTE, 0)
			set(Calendar.SECOND, 0)
			set(Calendar.MILLISECOND, 0)
		}
		val startTime = startCalendar.timeInMillis
		val usageMsByPackage = mutableMapOf<String, Long>()

		val aggregateMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
		aggregateMap.forEach { (pkg, stats) ->
			if (targetPackages.contains(pkg)) {
				val current = usageMsByPackage[pkg] ?: 0L
				usageMsByPackage[pkg] = maxOf(current, stats.totalTimeInForeground)
			}
		}

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

		activeStarts.forEach { (pkg, startedAt) ->
			if (endTime >= startedAt) {
				val delta = endTime - startedAt
				usageMsByPackage[pkg] = (usageMsByPackage[pkg] ?: 0L) + delta
			}
		}

		return targetPackages.associateWith { packageName ->
			usageMsByPackage[packageName] ?: 0L
		}
	}

	fun getRecentForegroundAppPackage(
		context: Context,
		excludedPackage: String? = null,
	): String? {
		val usageStatsManager =
			context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
		val endTime = System.currentTimeMillis()
		val startTime = endTime - 10 * 60 * 1000L
		val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
		val event = UsageEvents.Event()
		var recentPackage: String? = null

		while (usageEvents.hasNextEvent()) {
			usageEvents.getNextEvent(event)
			if (event.eventType != UsageEvents.Event.MOVE_TO_FOREGROUND) {
				continue
			}

			val packageName = event.packageName
			if (
				packageName.isNullOrBlank() ||
				(excludedPackage != null && packageName == excludedPackage)
			) {
				continue
			}
			recentPackage = packageName
		}

		return recentPackage
	}
}
