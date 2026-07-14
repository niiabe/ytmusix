import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads an APK to the app's external cache and launches the system
/// package installer to perform an in-app update.
class ApkInstaller {
  static const MethodChannel _channel = MethodChannel('ytmusix/install');
  static const String _apkName = 'ytmusix_update.apk';

  /// Downloads [url] to the external cache directory, reporting progress in
  /// bytes via [onProgress]. Returns the local file path.
  static Future<String> downloadApk(
    String url, {
    required void Function(int received, int total) onProgress,
  }) async {
    final dirs = await getExternalCacheDirectories();
    final dir = dirs?.first;
    if (dir == null) throw Exception('No cache directory available');
    final file = File('${dir.path}/$_apkName');
    if (await file.exists()) await file.delete();

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Download failed (HTTP ${response.statusCode})');
      }
      final total = response.contentLength ?? 0;
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
    return file.path;
  }

  /// Launches the Android package installer for the APK at [filePath].
  static Future<void> install(String filePath) async {
    await _channel.invokeMethod<void>('install', filePath);
  }
}
