package com.discipline.discipline_guardian

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.LinearLayout
import android.widget.TextView

class InterceptPromptActivity : Activity() {
	private var hasForwarded = false

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
			setShowWhenLocked(true)
			setTurnScreenOn(true)
		}
		window.addFlags(
			WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
				WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
				WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
		)
		window.decorView.systemUiVisibility =
			View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
				View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
				View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
				View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
				View.SYSTEM_UI_FLAG_FULLSCREEN or
				View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY

		val appName = intent.getStringExtra(EXTRA_APP_NAME) ?: "目标应用"
		val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

		val root = FrameLayout(this).apply {
			setBackgroundColor(Color.parseColor("#CC0F1115"))
		}

		val content = LinearLayout(this).apply {
			orientation = LinearLayout.VERTICAL
			gravity = Gravity.CENTER
			setPadding(48, 48, 48, 48)
		}

		val spinner = ProgressBar(this).apply {
			isIndeterminate = true
		}

		val title = TextView(this).apply {
			text = "正在打开验证页面"
			textSize = 20f
			setTextColor(Color.WHITE)
			gravity = Gravity.CENTER
			setPadding(0, 20, 0, 10)
		}

		val desc = TextView(this).apply {
			text = "$appName 已达到使用限制"
			textSize = 14f
			setTextColor(Color.parseColor("#CCFFFFFF"))
			gravity = Gravity.CENTER
		}

		content.addView(spinner)
		content.addView(
			title,
			LinearLayout.LayoutParams(
				LinearLayout.LayoutParams.WRAP_CONTENT,
				LinearLayout.LayoutParams.WRAP_CONTENT,
			),
		)
		content.addView(
			desc,
			LinearLayout.LayoutParams(
				LinearLayout.LayoutParams.WRAP_CONTENT,
				LinearLayout.LayoutParams.WRAP_CONTENT,
			),
		)
		root.addView(
			content,
			FrameLayout.LayoutParams(
				FrameLayout.LayoutParams.MATCH_PARENT,
				FrameLayout.LayoutParams.MATCH_PARENT,
			),
		)

		setContentView(root)
		window.decorView.post {
			forwardToGuardian(packageName)
		}
	}

	private fun forwardToGuardian(packageName: String) {
		if (hasForwarded) {
			return
		}
		hasForwarded = true
		val launchIntent = Intent(this, MainActivity::class.java).apply {
			addFlags(
				Intent.FLAG_ACTIVITY_NEW_TASK or
					Intent.FLAG_ACTIVITY_CLEAR_TOP or
					Intent.FLAG_ACTIVITY_SINGLE_TOP or
					Intent.FLAG_ACTIVITY_NO_ANIMATION,
			)
			putExtra(MainActivity.EXTRA_PROMPT_PACKAGE, packageName)
		}
		startActivity(launchIntent)
		finish()
	}

	@Deprecated("Deprecated in Java")
	override fun onBackPressed() {
		// Keep fallback prompt non-dismissible while forwarding.
	}

	companion object {
		const val EXTRA_PACKAGE_NAME = "extra_package_name"
		const val EXTRA_APP_NAME = "extra_app_name"
	}
}
