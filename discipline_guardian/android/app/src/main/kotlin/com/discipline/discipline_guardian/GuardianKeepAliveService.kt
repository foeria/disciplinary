package com.discipline.discipline_guardian

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

class GuardianKeepAliveService : Service() {
	companion object {
		private const val PREF_FILE = "guardian_keep_alive"
		private const val PREF_ENABLED = "keep_alive_enabled"
		private const val CHANNEL_ID = "guardian_keep_alive"
		private const val CHANNEL_NAME = "自律守护后台保活"
		private const val NOTIFICATION_ID = 10021
		private const val RESTART_REQUEST_CODE = 10022
		private const val TAG = "GuardianKeepAlive"
		const val ACTION_START = "com.discipline.discipline_guardian.action.START_KEEP_ALIVE"
		const val ACTION_STOP = "com.discipline.discipline_guardian.action.STOP_KEEP_ALIVE"
		const val ACTION_RESTART = "com.discipline.discipline_guardian.action.RESTART_KEEP_ALIVE"

		@Volatile
		private var serviceRunning = false

		fun isEnabled(context: Context): Boolean {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			return prefs.getBoolean(PREF_ENABLED, true)
		}

		fun setEnabled(context: Context, enabled: Boolean) {
			val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
			prefs.edit().putBoolean(PREF_ENABLED, enabled).apply()
		}

		fun isRunning(): Boolean = serviceRunning

		fun ensureRunningIfEnabled(context: Context) {
			if (isEnabled(context)) {
				start(context)
			}
		}

		fun start(context: Context) {
			try {
				val intent = Intent(context, GuardianKeepAliveService::class.java).apply {
					action = ACTION_START
				}
				ContextCompat.startForegroundService(context, intent)
			} catch (exception: Exception) {
				Log.w(TAG, "Failed to start keep-alive service", exception)
			}
		}

		fun stop(context: Context) {
			context.stopService(Intent(context, GuardianKeepAliveService::class.java))
		}
	}

	override fun onCreate() {
		super.onCreate()
		serviceRunning = true
		createNotificationChannel()
		runCatching {
			startForegroundCompat(buildNotification())
		}.onFailure { exception ->
			Log.w(TAG, "Failed to enter foreground mode", exception)
			serviceRunning = false
			stopSelf()
		}
	}

	override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
		if (!isEnabled(applicationContext) || intent?.action == ACTION_STOP) {
			serviceRunning = false
			stopForegroundCompat()
			stopSelf()
			return START_NOT_STICKY
		}

		GuardAccessibilityService.loadPersistedRules(applicationContext)
		runCatching {
			startForegroundCompat(buildNotification())
		}.onFailure { exception ->
			Log.w(TAG, "Failed to refresh foreground notification", exception)
			serviceRunning = false
			stopSelf()
			return START_NOT_STICKY
		}
		return START_STICKY
	}

	override fun onTaskRemoved(rootIntent: Intent?) {
		if (isEnabled(applicationContext)) {
			scheduleRestart()
		}
		super.onTaskRemoved(rootIntent)
	}

	override fun onDestroy() {
		serviceRunning = false
		if (isEnabled(applicationContext)) {
			scheduleRestart()
		}
		super.onDestroy()
	}

	override fun onBind(intent: Intent?): IBinder? = null

	private fun buildNotification(): Notification {
		val tapIntent = Intent(this, MainActivity::class.java).apply {
			addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
		}
		val pendingIntent = PendingIntent.getActivity(
			this,
			0,
			tapIntent,
			PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
		)

		return NotificationCompat.Builder(this, CHANNEL_ID)
			.setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
			.setContentTitle("自律守护者正在后台保护")
			.setContentText("拦截引擎与规则同步保持运行中")
			.setContentIntent(pendingIntent)
			.setOngoing(true)
			.setOnlyAlertOnce(true)
			.setShowWhen(false)
			.setPriority(NotificationCompat.PRIORITY_LOW)
			.build()
	}

	private fun createNotificationChannel() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
			return
		}

		val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
		val channel = NotificationChannel(
			CHANNEL_ID,
			CHANNEL_NAME,
			NotificationManager.IMPORTANCE_LOW,
		).apply {
			description = "用于保持自律守护拦截引擎尽量稳定运行"
			setShowBadge(false)
		}
		manager.createNotificationChannel(channel)
	}

	private fun scheduleRestart() {
		val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
		val restartIntent = Intent(this, GuardianKeepAliveReceiver::class.java).apply {
			action = ACTION_RESTART
		}
		val pendingIntent = PendingIntent.getBroadcast(
			this,
			RESTART_REQUEST_CODE,
			restartIntent,
			PendingIntent.FLAG_UPDATE_CURRENT or pendingIntentImmutableFlag(),
		)
		val triggerAtMillis = System.currentTimeMillis() + 1500L
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			alarmManager.setAndAllowWhileIdle(
				AlarmManager.RTC_WAKEUP,
				triggerAtMillis,
				pendingIntent,
			)
		} else {
			alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
		}
	}

	private fun pendingIntentImmutableFlag(): Int {
		return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
			PendingIntent.FLAG_IMMUTABLE
		} else {
			0
		}
	}

	private fun stopForegroundCompat() {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
			stopForeground(STOP_FOREGROUND_REMOVE)
		} else {
			@Suppress("DEPRECATION")
			stopForeground(true)
		}
	}

	private fun startForegroundCompat(notification: Notification) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			ServiceCompat.startForeground(
				this,
				NOTIFICATION_ID,
				notification,
				ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
			)
			return
		}
		startForeground(NOTIFICATION_ID, notification)
	}
}
