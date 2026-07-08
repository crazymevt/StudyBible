package io.github.crazymevt.studybible

import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONException
import org.json.JSONObject

// Shared plumbing for the three home-screen widgets. The Flutter side writes
// one JSON string per widget into the home_widget plugin's SharedPreferences
// (keys and shapes defined in lib/app/widget_sync_providers.dart and
// lib/domain/home_widgets/widget_payload.dart); these renderers only read.

/** Parses the JSON payload stored under [key], or null when absent/corrupt. */
fun widgetJson(widgetData: SharedPreferences, key: String): JSONObject? {
    val raw = widgetData.getString(key, null) ?: return null
    return try {
        JSONObject(raw)
    } catch (e: JSONException) {
        null
    }
}

/** [JSONObject.optString] that treats a missing/empty value as null. */
fun JSONObject.stringOrNull(name: String): String? =
    optString(name).takeIf { it.isNotEmpty() }

/**
 * A tap target that opens the app, carrying [uri] back to Dart through the
 * home_widget click plumbing (parsed by parseWidgetDeepLink). A null [uri]
 * just opens the app. Distinct URIs yield distinct PendingIntents (the intent
 * data differs), so per-row links don't overwrite each other.
 */
fun launchIntent(context: Context, uri: String?): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        uri?.let(Uri::parse),
    )
