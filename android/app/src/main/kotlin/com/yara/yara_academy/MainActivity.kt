package com.yara.yara_academy

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // High-importance channel so push notifications pop down as a heads-up banner.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel("yara_high", "إشعارات أكاديمية يارا", NotificationManager.IMPORTANCE_HIGH)
            ch.description = "الرسائل والاشتراكات وتذكير الحصص"
            ch.enableVibration(true)
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }
}
