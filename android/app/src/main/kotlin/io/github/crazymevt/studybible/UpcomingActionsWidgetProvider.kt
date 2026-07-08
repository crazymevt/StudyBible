package io.github.crazymevt.studybible

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * "Upcoming Actions": the next few open action items with a due time,
 * soonest first. Five fixed row slots instead of a RemoteViews ListView —
 * the payload is capped at five, and this keeps the widget a plain layout
 * with no RemoteViewsService machinery.
 */
class UpcomingActionsWidgetProvider : HomeWidgetProvider() {
    private data class RowIds(val row: Int, val title: Int, val subtitle: Int)

    private val rows = listOf(
        RowIds(R.id.action_row_0, R.id.action_title_0, R.id.action_due_0),
        RowIds(R.id.action_row_1, R.id.action_title_1, R.id.action_due_1),
        RowIds(R.id.action_row_2, R.id.action_title_2, R.id.action_due_2),
        RowIds(R.id.action_row_3, R.id.action_title_3, R.id.action_due_3),
        RowIds(R.id.action_row_4, R.id.action_title_4, R.id.action_due_4),
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val payload = widgetJson(widgetData, "actions_json")
        val items = payload?.optJSONArray("items")
        val count = items?.length() ?: 0
        val now = System.currentTimeMillis()

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_upcoming_actions)

            views.setViewVisibility(
                R.id.actions_empty,
                if (count == 0) View.VISIBLE else View.GONE,
            )

            rows.forEachIndexed { i, ids ->
                if (items != null && i < count) {
                    val item = items.getJSONObject(i)
                    // Recompute against the clock at render time; the payload's
                    // baked `overdue` flag is only the fallback for old data.
                    val overdue =
                        if (item.has("dueAt")) now >= item.getLong("dueAt")
                        else item.optBoolean("overdue")
                    views.setViewVisibility(ids.row, View.VISIBLE)
                    views.setTextViewText(ids.title, item.optString("title"))
                    views.setTextViewText(ids.subtitle, item.optString("dueLabel"))
                    views.setTextColor(
                        ids.subtitle,
                        ContextCompat.getColor(
                            context,
                            if (overdue) R.color.widget_overdue else R.color.widget_subtitle,
                        ),
                    )
                } else {
                    views.setViewVisibility(ids.row, View.GONE)
                }
            }

            // The whole widget opens the actions tab; per-item editors are a
            // possible later refinement (plan: "open decisions").
            views.setOnClickPendingIntent(
                R.id.actions_root,
                launchIntent(context, payload?.stringOrNull("uri") ?: "studybible://actions"),
            )

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
