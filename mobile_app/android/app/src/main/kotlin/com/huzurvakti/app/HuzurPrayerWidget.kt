package com.huzurvakti.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HuzurPrayerWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.huzur_prayer_widget)
            views.setTextViewText(R.id.widget_next_prayer, widgetData.getString("nextPrayerName", "Namaz"))
            views.setTextViewText(R.id.widget_time, widgetData.getString("nextPrayerTime", "--:--"))
            views.setTextViewText(R.id.widget_remaining, "${widgetData.getString("remainingMinutes", "--")} dk kaldı")

            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("huzurvakti://widget/open")).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                1001,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
