package com.smartplot.ai.smartplot_ai_app

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.smartplot.ai/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareFile") {
                val filePath = call.argument<String>("filePath")
                val title = call.argument<String>("title") ?: "Floor Plan"
                if (filePath != null) {
                    try {
                        val file = File(filePath)
                        val uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            file
                        )
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "image/svg+xml"
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_SUBJECT, title)
                            putExtra(Intent.EXTRA_TEXT, "SmartPlot AI Floor Plan: $title")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(Intent.createChooser(shareIntent, "Share Floor Plan via"))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_PATH", "File path was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
