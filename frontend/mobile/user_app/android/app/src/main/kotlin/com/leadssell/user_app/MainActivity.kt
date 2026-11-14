package com.leadssell.user_app

import android.os.Bundle
import android.content.Intent
import android.net.Uri
import android.content.pm.ApplicationInfo
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nextlead/contact")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val uri = Uri.parse(call.argument<String>("url") ?: "")
                val action = when {
                    uri.scheme == "tel" -> Intent.ACTION_DIAL
                    uri.scheme == "sms" -> Intent.ACTION_SENDTO
                    uri.scheme == "https" && uri.host == "wa.me" -> Intent.ACTION_VIEW
                    else -> null
                }
                if (action == null) {
                    result.error("INVALID_URL", "Unsupported contact action", null)
                } else {
                    try {
                        startActivity(Intent(action, uri))
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("UNAVAILABLE", "No app can open this contact action", null)
                    }
                }
            }
    }

    // Keep Flutter in the normal Android view hierarchy; avoids a blank
    // SurfaceView on the development emulator during launch transitions.
    override fun getRenderMode(): RenderMode =
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            RenderMode.texture
        } else {
            RenderMode.surface
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WebView.setWebContentsDebuggingEnabled(false)
    }
}
