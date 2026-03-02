package com.example.gestionarebunuri

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.gestionare_bunuri_mobile/file_handler"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveAndOpenFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")

                    if (filePath == null || fileName == null || mimeType == null) {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedUri = saveToDownloads(filePath, fileName, mimeType)
                        if (savedUri != null) {
                            openFile(savedUri, mimeType)
                            result.success("OK")
                        } else {
                            result.error("SAVE_ERROR", "Nu s-a putut salva fișierul", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "saveToDownloads" -> {
                    val filePath = call.argument<String>("filePath")
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")

                    if (filePath == null || fileName == null || mimeType == null) {
                        result.error("INVALID_ARGS", "Missing arguments", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val savedUri = saveToDownloads(filePath, fileName, mimeType)
                        if (savedUri != null) {
                            result.success(savedUri.toString())
                        } else {
                            result.error("SAVE_ERROR", "Nu s-a putut salva fișierul", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToDownloads(filePath: String, fileName: String, mimeType: String): Uri? {
        val sourceFile = File(filePath)
        if (!sourceFile.exists()) return null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
            }

            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: return null

            resolver.openOutputStream(uri)?.use { outputStream ->
                FileInputStream(sourceFile).use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            return uri
        } else {
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val destFile = File(downloadsDir, fileName)
            sourceFile.copyTo(destFile, overwrite = true)
            return Uri.fromFile(destFile)
        }
    }

    private fun openFile(uri: Uri, mimeType: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            // No app to handle the file
        }
    }
}

