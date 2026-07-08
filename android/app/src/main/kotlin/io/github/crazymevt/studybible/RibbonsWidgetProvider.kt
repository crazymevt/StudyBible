package io.github.crazymevt.studybible

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Ribbons": the most recently placed return markers, each row deep-linking
 * straight to its verse in the reader. Same fixed-row-slot approach as
 * [UpcomingActionsWidgetProvider].
 */
class RibbonsWidgetProvider : HomeWidgetProvider() {
    private data class RowIds(val row: Int, val reference: Int, val label: Int)

    private val rows = listOf(
        RowIds(R.id.ribbon_row_0, R.id.ribbon_ref_0, R.id.ribbon_label_0),
        RowIds(R.id.ribbon_row_1, R.id.ribbon_ref_1, R.id.ribbon_label_1),
        RowIds(R.id.ribbon_row_2, R.id.ribbon_ref_2, R.id.ribbon_label_2),
        RowIds(R.id.ribbon_row_3, R.id.ribbon_ref_3, R.id.ribbon_label_3),
        RowIds(R.id.ribbon_row_4, R.id.ribbon_ref_4, R.id.ribbon_label_4),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = widgetJson(widgetData, "ribbons_json")?.optJSONArray("items")
        val count = items?.length() ?: 0

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_ribbons)

            views.setViewVisibility(
                R.id.ribbons_empty,
                if (count == 0) View.VISIBLE else View.GONE,
            )

            rows.forEachIndexed { i, ids ->
                if (items != null && i < count) {
                    val item = items.getJSONObject(i)
                    val label = item.optString("label")
                    views.setViewVisibility(ids.row, View.VISIBLE)
                    views.setTextViewText(ids.reference, item.optString("reference"))
                    views.setTextViewText(ids.label, label)
                    views.setViewVisibility(
                        ids.label,
                        if (label.isEmpty()) View.GONE else View.VISIBLE,
                    )
                    views.setOnClickPendingIntent(
                        ids.row,
                        launchIntent(context, item.stringOrNull("uri")),
                    )
                } else {
                    views.setViewVisibility(ids.row, View.GONE)
                }
            }

            // Taps outside the rows (header/empty state) just open the app.
            views.setOnClickPendingIntent(R.id.ribbons_root, launchIntent(context, null))

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
