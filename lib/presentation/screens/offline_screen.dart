import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/video.dart';
import '../providers/download_provider.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/now_playing_fab.dart';
import '../widgets/track_action_sheet.dart';
import '../widgets/track_tile.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  List<Track> _tracks = [];
  bool _loading = true;

  static const String _playlistId = '__downloads__';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<DownloadProvider>();
    final tracks = await provider.getAllDownloadedTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    }
  }

  Future<void> _play(int index) async {
    final player = context.read<PlayerProvider>();
    final settings = context.read<SettingsProvider>();
    final track = _tracks[index];
    if (player.currentTrack?.id == track.id) {
      player.togglePlayPause();
      return;
    }
    player.setQueue(_tracks, startIndex: index, playlistId: _playlistId);
    await player.playTrack(track, quality: settings.audioQuality);
  }

  Future<void> _playAll() async {
    final player = context.read<PlayerProvider>();
    final settings = context.read<SettingsProvider>();
    if (player.currentPlaylistId == _playlistId && _tracks.isNotEmpty) {
      player.togglePlayPause();
      return;
    }
    if (_tracks.isEmpty) return;
    player.setQueue(_tracks, startIndex: 0, playlistId: _playlistId);
    await player.playTrack(_tracks.first, quality: settings.audioQuality);
  }

  Future<void> _shuffleAll() async {
    final player = context.read<PlayerProvider>();
    final settings = context.read<SettingsProvider>();
    if (_tracks.isEmpty) return;
    player.setQueue(_tracks, startIndex: 0, playlistId: _playlistId);
    player.toggleShuffle();
    await player.playTrack(player.queue.first, quality: settings.audioQuality);
  }

  Future<void> _delete(Track track) async {
    final provider = context.read<DownloadProvider>();
    await provider.deleteDownloadedTrack(track.id);
    if (mounted) {
      setState(() {
        _tracks.removeWhere((t) => t.id == track.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "${track.title}" from Offline')),
      );
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all offline downloads?'),
        content: const Text(
          'Remove all downloaded files from this device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final provider = context.read<DownloadProvider>();
      await provider.deleteAllDownloadedTracks();
      setState(() => _tracks = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final isNowPlaying = player.currentTrack != null;

    return Scaffold(
      floatingActionButton: isNowPlaying
          ? NowPlayingFab(
              track: player.currentTrack!,
              isPlaying: player.isPlaying,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, player),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _tracks.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_off_rounded,
                                  size: 48,
                                  color: Colors.white38,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No offline tracks yet.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap the download icon on a playlist or '
                                  'track to save it for offline playback.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Consumer2<PlaylistProvider, PlayerProvider>(
                          builder:
                              (context, playlistProvider, playerProvider, _) {
                            final favoriteIds = playlistProvider.favoriteIds;
                            final currentTrackId =
                                playerProvider.currentTrack?.id;
                            return ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 4, 14, 24),
                              itemCount: _tracks.length,
                              itemBuilder: (context, index) {
                                final track = _tracks[index];
                                return TrackTile(
                                  track: track,
                                  isCurrent: currentTrackId == track.id,
                                  isDownloaded: true,
                                  isFavorite:
                                      favoriteIds.contains(track.id),
                                  onToggleFavorite: () =>
                                      playlistProvider.toggleFavorite(track),
                                  onDelete: () => _delete(track),
                                  onMore: () => showTrackActionSheet(
                                    context,
                                    track: track,
                                    queue: _tracks,
                                    index: index,
                                    playlistId: _playlistId,
                                  ),
                                  onTap: () => _play(index),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayerProvider playerProvider) {
    final hasTracks = _tracks.isNotEmpty;
    final isPlayingFromDownloads =
        playerProvider.currentPlaylistId == _playlistId;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Spacer(),
              if (hasTracks)
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  tooltip: 'Clear all',
                  onPressed: _clearAll,
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Offline',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_tracks.length} tracks available offline',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (hasTracks) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const CircleBorder(),
                    ),
                    icon: Icon(
                      isPlayingFromDownloads && playerProvider.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 30,
                    ),
                    onPressed: _playAll,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(10),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    onPressed: _shuffleAll,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
