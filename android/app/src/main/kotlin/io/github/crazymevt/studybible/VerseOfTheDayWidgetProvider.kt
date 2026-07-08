package io.github.crazymevt.studybible

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar

/**
 * "Verse of the Day" card. The payload carries the whole curated list and the
 * day's verse is picked here, so the widget rolls over at midnight (via
 * updatePeriodMillis re-renders) without the app ever running.
 */
class VerseOfTheDayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val verses = widgetJson(widgetData, "votd_json")?.optJSONArray("verses")

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_verse_of_the_day)

            if (verses == null || verses.length() == 0) {
                // No payload yet (widget added before the app's first run).
                views.setTextViewText(R.id.votd_reference, context.getString(R.string.widget_votd_label))
                views.setTextViewText(R.id.votd_text, context.getString(R.string.widget_votd_empty))
                views.setOnClickPendingIntent(R.id.votd_root, launchIntent(context, null))
            } else {
                // Same formula as the in-app dashboard card: 0-based days
                // since Jan 1, modulo the list length. DAY_OF_YEAR is 1-based.
                val dayOfYear = Calendar.getInstance().get(Calendar.DAY_OF_YEAR) - 1
                val verse = verses.getJSONObject(dayOfYear % verses.length())
                views.setTextViewText(R.id.votd_reference, verse.optString("reference"))
                views.setTextViewText(R.id.votd_text, verse.optString("text"))
                views.setOnClickPendingIntent(
                    R.id.votd_root,
                    launchIntent(context, verse.stringOrNull("uri")),
                )
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
