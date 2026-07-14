import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Checks GitHub for a newer release and exposes the download location.
class UpdateService {
  static const String _repoOwner = 'niiabe';
  static const String _repoName = 'ytmusix';
  static const String _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<UpdateInfo> checkForUpdate() async {
    final current = await PackageInfo.fromPlatform();
    try {
      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return UpdateInfo(available: false, currentVersion: current.version);
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = ((data['tag_name'] as String?) ?? '')
          .replaceAll(RegExp(r'^v'), '');
      final releaseUrl = data['html_url'] as String?;
      String? apkUrl;
      final assets = data['assets'] as List?;
      if (assets != null) {
        for (final asset in assets) {
          final name = ((asset['name'] as String?) ?? '').toLowerCase();
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }
      return UpdateInfo(
        available: _isNewer(tag, current.version),
        latestVersion: tag,
        releaseUrl: releaseUrl,
        apkUrl: apkUrl,
        currentVersion: current.version,
      );
    } catch (_) {
      return UpdateInfo(available: false, currentVersion: current.version);
    }
  }

  static bool _isNewer(String latest, String current) {
    if (latest.isEmpty) return false;
    final l = latest.split('+').first.split('.');
    final c = current.split('+').first.split('.');
    for (var i = 0; i < 3; i++) {
      final lv = int.tryParse(l.length > i ? l[i] : '0') ?? 0;
      final cv = int.tryParse(c.length > i ? c[i] : '0') ?? 0;
      if (lv != cv) return lv > cv;
    }
    return false;
  }
}

class UpdateInfo {
  final bool available;
  final String? latestVersion;
  final String? releaseUrl;
  final String? apkUrl;
  final String? currentVersion;

  const UpdateInfo({
    required this.available,
    this.latestVersion,
    this.releaseUrl,
    this.apkUrl,
    this.currentVersion,
  });

  String get downloadUrl => apkUrl ?? releaseUrl ?? '';
}
