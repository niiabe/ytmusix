import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../service/apk_installer.dart';
import '../../service/update_service.dart';

const String _dismissedUpdateKey = 'dismissed_update_version';

/// Checks GitHub for a newer release and, if found and not previously
/// dismissed for this version, shows a dialog offering to download & install.
Future<void> checkAndShowUpdateDialog(BuildContext context) async {
  final info = await UpdateService.checkForUpdate();
  if (!info.available || info.latestVersion == null || !context.mounted) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString(_dismissedUpdateKey) == info.latestVersion) return;
  if (!context.mounted) return;

  final proceed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update_alt_rounded, size: 22),
          SizedBox(width: 10),
          Text('Update available'),
        ],
      ),
      content: Text(
        'Version ${info.latestVersion} is available on GitHub '
        '(you have ${info.currentVersion}). Download and install it now?',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await prefs.setString(_dismissedUpdateKey, info.latestVersion!);
            if (ctx.mounted) Navigator.pop(ctx, false);
          },
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Download'),
        ),
      ],
    ),
  );
  if (proceed == true && context.mounted) {
    await downloadAndInstallUpdate(context, info);
  }
}

/// Downloads the update APK and launches the system installer with progress UI.
Future<void> downloadAndInstallUpdate(BuildContext context, UpdateInfo info) async {
  final url = info.downloadUrl;
  if (url.isEmpty || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateDownloadDialog(url: url),
  );
}

class _UpdateDownloadDialog extends StatefulWidget {
  final String url;

  const _UpdateDownloadDialog({required this.url});

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  int _received = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final path = await ApkInstaller.downloadApk(
        widget.url,
        onProgress: (received, total) => setState(() {
          _received = received;
          _total = total;
        }),
      );
      if (!mounted) return;
      try {
        await ApkInstaller.install(path);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) setState(() => _error = 'Install failed: $e');
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = _total > 0 ? _received / _total : null;
    return AlertDialog(
      title: const Text('Downloading update…'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            )
          else ...[
            LinearProgressIndicator(value: pct),
            const SizedBox(height: 12),
            Text(
              _total > 0
                  ? '${(_received / 1048576).toStringAsFixed(1)} MB / '
                      '${(_total / 1048576).toStringAsFixed(1)} MB'
                  : 'Starting download…',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ],
      ),
      actions: _error != null
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ]
          : null,
    );
  }
}
