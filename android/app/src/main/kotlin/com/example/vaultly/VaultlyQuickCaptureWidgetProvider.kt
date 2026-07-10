package com.example.vaultly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class VaultlyQuickCaptureWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.vaultly_quick_capture_widget)
            bindAction(context, views, R.id.widgetClipboard, "clipboard")
            bindAction(context, views, R.id.widgetNote, "note")
            bindAction(context, views, R.id.widgetLink, "link")
            bindAction(context, views, R.id.widgetSearch, "search")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun bindAction(context: Context, views: RemoteViews, viewId: Int, action: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = Intent.ACTION_VIEW
            data = Uri.parse("vaultly://quick?action=$action")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        val requestCode = action.hashCode()
        views.setOnClickPendingIntent(
            viewId,
            PendingIntent.getActivity(context, requestCode, intent, flags)
        )
    }
}
