package com.ytmusix.ytmusix.canary

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceFragmentActivity() {
    private val CHANNEL = "ytmusix/install"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "install") {
                    val path = call.arguments as? String
                    if (path.isNullOrEmpty()) {
                        result.error("NO_PATH", "No APK path provided", null)
                        return@setMethodCallHandler
                    }
                    try {
                        installApk(path, result)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        val file = File(path)
        if (!file.exists()) {
            result.error("FILE_MISSING", "APK file not found", null)
            return
        }
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            data = uri
            flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        startActivity(intent)
        result.success(null)
    }
}
