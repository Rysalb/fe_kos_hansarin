package com.example.proyekkos

import android.media.MediaScannerConnection
import android.content.Intent
import android.os.Environment
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL_MEDIA_SCANNER = "com.example.proyekkos/media_scanner"
    private val CHANNEL_FILE_MANAGER = "com.example.proyekkos/file_manager"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_MEDIA_SCANNER).setMethodCallHandler { call, result ->
            if (call.method == "scanFile") {
                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType")
                if (path != null && mimeType != null) {
                    MediaScannerConnection.scanFile(this, arrayOf(path), arrayOf(mimeType)) { _, _ -> }
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Path or mimeType is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_FILE_MANAGER).setMethodCallHandler { call, result ->
            when (call.method) {
                "openDownloads" -> {
                    try {
                        val intent = Intent(Intent.ACTION_GET_CONTENT)
                        intent.setType("*/*")
                        intent.addCategory(Intent.CATEGORY_OPENABLE)
                        startActivity(Intent.createChooser(intent, "Open Downloads"))
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("ERROR", "Error opening Downloads", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
