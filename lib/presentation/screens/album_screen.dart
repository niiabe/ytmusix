import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/format_duration.dart';
import '../../domain/entities/search_result_models.dart';
import '../providers/player_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/track_action_sheet.dart';
import '../widgets/now_playing_fab.dart';
import 'artist_screen.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;
  final String? title;
  final String? artist;
  final String? artistId;
  final String? thumbnailUrl;

  const AlbumScreen({
    super.key,
    required this.albumId,
    this.title,
    this.artist,
    this.artistId,
    this.thumbnailUrl,
  });

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  AlbumDetailResult? _album;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await context.read<PlaylistProvider>().getAlbum(
        widget.albumId,
      );
      if (mounted) {
        setState(() {
          _album = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerWatcher = context.watch<PlayerProvider>();
    final isNowPlaying = playerWatcher.currentTrack != null;
    return Scaffold(
      floatingActionButton: isNowPlaying
          ? NowPlayingFab(
              track: playerWatcher.currentTrack!,
              isPlaying: playerWatcher.isPlaying,
            )
          : null,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        IconButton(
                          onPressed: _loadAlbum,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final album = _album!;
    final player = context.watch<PlayerProvider>();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(14)),
            ),
            child: Column(
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
                    const Text(
                      'Album',
                      style: TextStyle(fontSize: 14, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        album.thumbnailUrl ?? '',
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                          width: 112,
                          height: 112,
                          color: const Color(0xFF282828),
                          child: const Icon(Icons.album_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: album.artistId != null
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ArtistScreen(
                                          artistId: album.artistId!,
                                          name: album.artist,
                                        ),
                                      ),
                                    )
                                : null,
                            child: Text(
                              '${album.artist}${album.year != null ? ' · ${album.year}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: album.artistId != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                        icon: const Icon(Icons.play_arrow_rounded, size: 30),
                        onPressed: album.tracks.isEmpty
                            ? null
                            : () {
                                final quality = context.read<SettingsProvider>().audioQuality;
                                player.setQueue(
                                  album.tracks,
                                  startIndex: 0,
                                  playlistId: 'album_${album.id}',
                                );
                                player.playTrack(album.tracks.first, quality: quality);
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
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
                        onPressed: album.tracks.isEmpty
                            ? null
                            : () {
                                final quality = context.read<SettingsProvider>().audioQuality;
                                player.setQueue(
                                  album.tracks,
                                  startIndex: 0,
                                  playlistId: 'album_${album.id}',
                                );
                                player.toggleShuffle();
                                player.playTrack(album.tracks.first, quality: quality);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (album.tracks.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No tracks found')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = album.tracks[index];
                  final currentTrackId = player.currentTrack?.id;
                  final isCurrent = currentTrackId == track.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary.withAlpha(28)
                          : const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary.withAlpha(80)
                            : Colors.white.withAlpha(12),
                      ),
                    ),
                    child: ListTile(
                      tileColor: isCurrent
                          ? Theme.of(context).colorScheme.primary.withAlpha(28)
                          : const Color(0xFF171717),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.thumbnailUrl ?? '',
                          width: 46,
                          height: 46,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 46,
                            height: 46,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 20),
                          ),
                        ),
                      ),
                      title: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        formatDuration(track.duration),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onPressed: () => showTrackActionSheet(
                          context,
                          track: track,
                          queue: album.tracks,
                          index: index,
                          playlistId: 'album_${album.id}',
                        ),
                      ),
                      onTap: () {
                        final quality = context.read<SettingsProvider>().audioQuality;
                        player.setQueue(
                          album.tracks,
                          startIndex: index,
                          playlistId: 'album_${album.id}',
                        );
                        player.playTrack(track, quality: quality);
                      },
                    ),
                  );
                },
                childCount: album.tracks.length,
              ),
            ),
          ),
      ],
    );
  }
}
