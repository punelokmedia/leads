package com.leadssell.user_app

import android.os.Bundle
import android.content.pm.ApplicationInfo
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
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
