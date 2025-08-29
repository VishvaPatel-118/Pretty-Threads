package com.example.pretty_threads

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
  }

  override fun onResume() {
    super.onResume()
    // Ensure screenshots remain allowed when returning to foreground
    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
  }
}