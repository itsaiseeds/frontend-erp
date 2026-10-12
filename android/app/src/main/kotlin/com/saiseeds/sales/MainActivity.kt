package com.saiseeds.sales

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "saiseeds/pdf_download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val filename = call.argument<String>("filename")
                val bytes = call.argument<ByteArray>("bytes")

                if (filename.isNullOrBlank() || bytes == null) {
                    result.error(
                        "BAD_ARGS",
                        "A filename and the file bytes are required.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                // Android 10+ writes into the shared Downloads collection
                // with no storage permission. Older systems cannot reach
                // that folder without a runtime grant, so they report
                // UNSUPPORTED and the caller falls back to the share sheet.
                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                    result.error(
                        "UNSUPPORTED",
                        "Direct download requires Android 10 or newer.",
                        null,
                    )
                    return@setMethodCallHandler
                }

                try {
                    saveToDownloads(filename, bytes)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SAVE_FAILED", e.message, e.toString())
                }
            }
    }

    /// Writes straight into the public Downloads collection. MediaStore
    /// renames on collision ("name (1).pdf"), so no dedup is needed here.
    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveToDownloads(filename: String, bytes: ByteArray) {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, filename)
            put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val resolver = contentResolver
        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create a Downloads entry.")

        try {
            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw IllegalStateException("Could not open the Downloads stream.")
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }

        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
    }
}
