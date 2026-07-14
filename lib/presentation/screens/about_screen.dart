import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../service/update_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/update_dialog.dart';
import 'licenses_screen.dart';
import 'contributors_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '1.0.0';
            final build = snapshot.data?.buildNumber ?? '1';
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _PageHeader(
                  title: 'About',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withAlpha(14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const BrandLogo(
                              size: 104,
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Version $version ($build)',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _InfoRow(
                        icon: Icons.music_note_rounded,
                        title: 'YouTube Music Streamer',
                        body:
                            'Stream audio from public YouTube playlists, single videos, and mixes.',
                      ),
                      const SizedBox(height: 14),
                      const _InfoRow(
                        icon: Icons.cloud_off_rounded,
                        title: 'Offline-first playback',
                        body:
                            'Downloaded tracks play from local cache before using the network.',
                      ),
                      const SizedBox(height: 14),
                      const _InfoRow(
                        icon: Icons.shield_outlined,
                        title: 'Personal use',
                        body:
                            'For personal, educational use only. Not affiliated with YouTube.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ActionTile(
                  icon: Icons.article_rounded,
                  title: 'Open source licenses',
                  subtitle: 'Flutter, plugins, and package notices',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LicensesScreen()),
                  ),
                ),
                const SizedBox(height: 18),
                _ActionTile(
                  icon: Icons.people_rounded,
                  title: 'Contributors',
                  subtitle: 'Meet the creators behind the app',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContributorsScreen()),
                  ),
                ),
                const SizedBox(height: 18),
                const _UpdateChecker(),
                const SizedBox(height: 18),
                const _ChangelogSection(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UpdateChecker extends StatefulWidget {
  const _UpdateChecker();

  @override
  State<_UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<_UpdateChecker> {
  UpdateInfo? _info;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!mounted) return;
    setState(() => _checking = true);
    final info = await UpdateService.checkForUpdate();
    if (mounted) {
      setState(() {
        _info = info;
        _checking = false;
      });
    }
  }

  Future<void> _download() async {
    final info = _info;
    if (info != null) {
      await downloadAndInstallUpdate(context, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.system_update_alt_rounded, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'App update',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              if (_checking)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Check for updates',
                  onPressed: _check,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_checking)
            const Text(
              'Checking GitHub for updates…',
              style: TextStyle(color: Colors.white54),
            )
          else if (info != null && info.available)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'v${info.latestVersion}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A newer version is available '
                        '(you have ${info.currentVersion}).',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _download,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download update'),
                  ),
                ),
              ],
            )
          else
            const Text(
              'You are on the latest version.',
              style: TextStyle(color: Colors.white54),
            ),
        ],
      ),
    );
  }
}

class _ChangelogSection extends StatelessWidget {
  const _ChangelogSection();

  static const _items = [
    (
      '1.5.3',
      'Fix: downloaded songs no longer fail with a "source error" — playback now loads the locally downloaded file directly. Fix: the Now Playing screen now fits small screens without overflowing. Theme: adopted the flowos color scheme with a pure-black background. Home redesign: decluttered Browse into Apple Music Top 100, YouTube Ghana Top 100, Suggested for you, Recent plays, and Your Library, with tabs New, Trending, Podcast, Favorites.',
    ),
    (
      '1.5.2',
      'In-app updates: the About screen now checks GitHub for a newer release and can download the APK and launch the system installer directly; a startup prompt offers the same when a new version is available. Offline screen now uses the app icon as artwork for tracks without a thumbnail. The home "Recent plays" section now populates from your recently played tracks. In-app changelog shows up to 5 entries.',
    ),
    (
      '1.5.1',
      'Adopted the Offline (Downloads) screen and download method from ytmusix-flowos: a full-screen Offline view with a play/shuffle header, favourites, per-track delete and clear-all. Adopted flowos\' Settings page with a new Auto DJ screen — choose how the queue continues when it ends (Off, Library Shuffle, Similar Songs, Same Artist, Same Genre, Smart Mix) with a configurable continuation count and top-up threshold; it is now wired into playback so the queue extends automatically. Fixed a bug where the device back gesture at the root stopped playback — the app now moves to the background instead, keeping audio alive.',
    ),
    (
      '1.5.0',
      'Auto-download every track you play for offline listening (live streams are skipped). Playlists now auto-download in full when played. The "Downloaded" section is renamed to "Offline" and the download action now reads "Download offline". Added an audio/video switch on the player so you can watch the music video, plus an in-player audio quality selector and a quality badge (default quality raised to High). Added a "YouTube Music Top 100 Ghana" chart shelf. In-app changelog now shows only the 3 most recent updates.',
    ),
    (
      '1.4.3',
      'Added a YouTube link parser with switch-based URL type detection for videos, playlists, shorts, and music links. Single video and shorts links now play audio immediately instead of opening a playlist view. Added channel link detection with clear unsupported feedback. Fixed DatabaseException on fresh installs by bumping the DB to version 8 with an idempotent migration.',
    ),
    (
      '1.4.2',
      'Fixed the bottom layout overflow on the Now Playing FAB, corrected the repeat and shuffle controls on the Now Playing screen, and resolved seekbar duration filling issues.',
    ),
    (
      '1.4.1',
      'Fixed background audio playback and track auto-play progression on Android devices, and introduced a toggleable 7-second crossfade feature on the Now Playing screen.',
    ),
    (
      '1.4.0',
      'Added favorite collection support (playlists and albums), resolved layout overflow bugs, and optimized the Now Playing FAB with dynamic sizing.',
    ),
    (
      '1.3.0',
      'Added floating player controls with play/pause and progress seekbar border to FAB, removed mini-player layout, optimized audio quality settings defaults, added geo-restrictions bypass, resolved playlist duration mapping, fixed search playlist navigation, and adjusted artist page layouts.',
    ),
    (
      '1.2.0',
      'Added Apple Music chart shelves with scoped Top 100 songs, album detail playback, recommendation autoplay, cached chart/search lookups, a custom video player, and refreshed About details.',
    ),
    (
      '1.1.0',
      'Improved playlist browsing, downloads, favourites, queue tools, and playback controls.',
    ),
    (
      '1.0.0',
      'Initial Android release for streaming public YouTube playlists, videos, and mixes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Changelog',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._items.take(5).toList().indexed.map((entry) {
            final index = entry.$1;
            final item = entry.$2;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _items.take(5).length - 1 ? 0 : 14,
              ),
              child: _ChangelogItem(version: item.$1, body: item.$2),
            );
          }),
        ],
      ),
    );
  }
}

class _ChangelogItem extends StatelessWidget {
  final String version;
  final String body;

  const _ChangelogItem({required this.version, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            version,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            body,
            style: const TextStyle(color: Colors.white54, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _PageHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF191919),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: onBack,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoRow({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: Colors.white54, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF171717),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(14)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
