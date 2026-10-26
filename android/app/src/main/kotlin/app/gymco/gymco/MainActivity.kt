package app.gymco.gymco

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

// A fragment activity, so Health Connect can show its permission screen.
//
// Google Assistant and the app's own shortcuts open Gymco with a link like
// app.gymco.gymco://assistant/water?ml=250 (res/xml/shortcuts.xml). Each one
// is kept in an inbox here, which the app takes over the gymco/siri channel
// when it runs and carries out (lib/state/siri.dart), as it does for Siri.
class MainActivity : FlutterFragmentActivity() {
    private val inbox by lazy { getSharedPreferences("gymco_assistant", MODE_PRIVATE) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gymco/siri").setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> {
                    val raw = inbox.getString("queue", null)
                    inbox.edit().remove("queue").apply()
                    result.success(raw)
                }
                // Opens a wearable's own app so it syncs (lib/data/watch_apps.dart).
                "openApp" -> {
                    val launch = call.argument<String>("package")?.let { packageManager.getLaunchIntentForPackage(it) }
                    if (launch == null) {
                        result.success(false)
                    } else {
                        startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(true)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keep(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        keep(intent)
    }

    private fun keep(intent: Intent?) {
        if (intent == null) return
        val uri = intent.data ?: return
        if (uri.scheme != "app.gymco.gymco" || uri.host != "assistant") return
        val action = actionFor(uri) ?: return
        val list = try {
            JSONArray(inbox.getString("queue", "[]"))
        } catch (e: Exception) {
            JSONArray()
        }
        list.put(action)
        inbox.edit().putString("queue", list.toString()).apply()
        // Handled: don't let the link be read again on a restart.
        intent.data = null
    }

    private fun actionFor(uri: Uri): JSONObject? {
        // "Open app feature" passes the words said; match them to what Gymco does.
        val what = when (val path = uri.lastPathSegment) {
            "open" -> (uri.getQueryParameter("feature") ?: "").lowercase()
            else -> path ?: return null
        }
        return when {
            "water" in what || "drink" in what ->
                JSONObject().put("a", "water").put("ml", uri.getQueryParameter("ml")?.toIntOrNull() ?: 250)
            "workout" in what || "train" in what || "exercise" in what -> JSONObject().put("a", "workout")
            "food" in what || "meal" in what || "eat" in what ->
                JSONObject().put("a", "food").put("text", uri.getQueryParameter("text") ?: "")
            "weigh" in what || "weight" in what -> JSONObject().put("a", "open").put("to", "/progress")
            "calorie" in what || "today" in what || "left" in what -> JSONObject().put("a", "open").put("to", "/today")
            else -> JSONObject().put("a", "open").put("to", "/today")
        }
    }
}
