package com.santayo.san_tayo

import android.os.Build
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private var keepHomeBar = false

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "san_tayo/home_bar")
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "show" -> {
            keepHomeBar = true
            applyHomeBar()
            result.success(null)
          }
          "hide" -> {
            keepHomeBar = false
            applyHomeBar()
            result.success(null)
          }
          else -> result.notImplemented()
        }
      }
  }

  override fun onPostResume() {
    super.onPostResume()
    applyHomeBar()
  }

  // Search keeps the home bar up. Every other screen hides it until a swipe.
  private fun applyHomeBar() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
      return
    }

    val controller = window.insetsController ?: return
    if (keepHomeBar) {
      controller.systemBarsBehavior = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        WindowInsetsController.BEHAVIOR_DEFAULT
      } else {
        @Suppress("DEPRECATION")
        WindowInsetsController.BEHAVIOR_SHOW_BARS_BY_TOUCH
      }
      controller.show(WindowInsets.Type.navigationBars())
      return
    }

    controller.hide(WindowInsets.Type.navigationBars())
    controller.systemBarsBehavior =
      WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
  }
}
