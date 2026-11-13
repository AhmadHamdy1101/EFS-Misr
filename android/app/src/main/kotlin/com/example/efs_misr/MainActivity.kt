package com.example.efs_misr

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createPushChannel()
    }

    // Channel used by pushes from the send-push edge function
    // (android.notification.channel_id). Creating it again is a no-op.
    private fun createPushChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "efs_notifications",
            "Tickets and tracking",
            NotificationManager.IMPORTANCE_HIGH,
        )
        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }
}
