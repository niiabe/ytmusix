import 'dart:async';
import 'dart:developer' as dev;
import 'package:dart_ytmusic_api/dart_ytmusic_api.dart' as ytmusic;
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    hide Playlist, Video;
import '../../models/playlist_model.dart';
import '../../models/video_model.dart';
import '../../../service/auth_service.dart';
import 'authenticated_client.dart';

class YoutubeRemoteDataSource {
  static const _timeout = Duration(seconds: 30);

  final AuthService _authService;
  late final YoutubeExplode _yt;
  late final ytmusic.YTMusic _ytMusic;

  YoutubeRemoteDataSource({AuthService? authService})
    : _authService = authService ?? AuthService();

  Future<void> init() async {
    final cookies = await _authService.getCookies();
    final inner = AuthenticatedClient(cookies: cookies);
    final ytHttp = YoutubeHttpClient(inner);
    _yt = YoutubeExplode(httpClient: ytHttp);
    _ytMusic = ytmusic.YTMusic();
    try {
      await _ytMusic
          .initialize(cookies: cookies, gl: 'GH', hl: 'en')
          .timeout(_timeout);
    } catch (e) {
      dev.log(
        'YouTube Music API initialization failed, using YouTube fallback: $e',
        name: 'YoutubeRemoteDataSource',
      );
    }
  }

  Future<PlaylistModel> getPlaylist(String playlistId) async {
    var attempt = 0;
    final stopwatch = Stopwatch()..start();

    while (true) {
      attempt++;
      try {
        final ytPlaylist = await _yt.playlists
            .get(playlistId)
            .timeout(_timeout);

        final title = ytPlaylist.title;
        final author = ytPlaylist.author;

        final videos = await () async {
          try {
            return await _yt.playlists
                .getVideos(playlistId)
                .toList()
                .timeout(_timeout);
          } catch (e) {
            dev.log(
              'Playlist videos fetch failed for $playlistId (attempt $attempt): $e',
              name: 'YoutubeRemoteDataSource',
            );
            return <dynamic>[];
          }
        }();

        if (videos.isEmpty) {
          throw Exception('No videos found for playlist/mix $playlistId');
        }

        final tracks = <TrackModel>[];
        for (var i = 0; i < videos.length; i++) {
          final video = videos[i];
          tracks.add(
            TrackModel(
              id: video.id.value,
              title: video.title,
              author: video.author,
              durationSeconds: video.duration?.inSeconds ?? 0,
              thumbnailUrl: video.thumbnails.highResUrl,
              index: i,
            ),
          );
        }

        final thumbnailUrl = tracks.isNotEmpty
            ? tracks.first.thumbnailUrl
            : null;

        return PlaylistModel(
          id: playlistId,
          title: title,
          author: author,
          thumbnailUrl: thumbnailUrl,
          videoCount: tracks.length,
          tracks: tracks,
        );
      } on TimeoutException {
        dev.log(
          'Attempt $attempt timed out for playlist $playlistId',
          name: 'YoutubeRemoteDataSource',
        );
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on Exception catch (e) {
        final msg = e.toString();
        dev.log(
          'Playlist fetch attempt $attempt failed for $playlistId: $msg',
          name: 'YoutubeRemoteDataSource',
        );
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }

  Future<TrackModel> getVideo(String videoId) async {
    final video = await _yt.videos.get(videoId);
    return TrackModel(
      id: video.id.value,
      title: video.title,
      author: video.author,
      durationSeconds: video.duration?.inSeconds ?? 0,
      thumbnailUrl: video.thumbnails.highResUrl,
      index: 0,
    );
  }

  Future<List<TrackModel>> getRecommendations(
    String videoId, {
    int limit = 20,
  }) async {
    try {
      final upNext = await _ytMusic.getUpNexts(videoId).timeout(_timeout);
      final tracks = upNext
          .where((item) => item.videoId.isNotEmpty)
          .take(limit)
          .map(_trackFromUpNext)
          .toList();
      if (tracks.isNotEmpty) return _withIndexes(tracks);
    } catch (e) {
      dev.log(
        'YouTube Music up next failed for $videoId, using related videos: $e',
        name: 'YoutubeRemoteDataSource',
      );
    }

    final video = await _yt.videos.get(videoId).timeout(_timeout);
    final related = await _yt.videos.getRelatedVideos(video).timeout(_timeout);
    if (related == null || related.isEmpty) return <TrackModel>[];

    final tracks = <TrackModel>[];
    for (final recommendation in related) {
      if (tracks.length >= limit) break;
      tracks.add(
        TrackModel(
          id: recommendation.id.value,
          title: recommendation.title,
          author: recommendation.author,
          durationSeconds: recommendation.duration?.inSeconds ?? 0,
          thumbnailUrl: recommendation.thumbnails.highResUrl,
          index: tracks.length,
        ),
      );
    }
    return tracks;
  }

  Future<String> getVideoUrl(
    String videoId, {
    String quality = 'medium',
  }) async {
    final manifest = await _yt.videos.streams
        .getManifest(videoId)
        .timeout(_timeout);
    final hlsMuxed = manifest.hls.whereType<HlsMuxedStreamInfo>().toList();
    if (hlsMuxed.isNotEmpty) {
      final best = _selectByQuality(hlsMuxed, quality);
      return best.url.toString();
    }

    final iosFriendlyMuxed = manifest.muxed
        .where(
          (stream) =>
              stream.container == StreamContainer.mp4 &&
              stream.videoCodec.toLowerCase().contains('avc') &&
              stream.audioCodec.toLowerCase().contains('mp4a'),
        )
        .toList();
    if (iosFriendlyMuxed.isNotEmpty) {
      final best = _selectByQuality(iosFriendlyMuxed, quality);
      return best.url.toString();
    }

    final mp4Muxed = manifest.muxed
        .where((stream) => stream.container == StreamContainer.mp4)
        .toList();
    if (mp4Muxed.isNotEmpty) {
      final best = _selectByQuality(mp4Muxed, quality);
      return best.url.toString();
    }

    final fallbackMuxed = manifest.muxed.toList();
    if (fallbackMuxed.isEmpty) {
      throw Exception('No playable video streams available for video $videoId');
    }
    final best = _selectByQuality(fallbackMuxed, quality);
    return best.url.toString();
  }

  Future<String> getAudioUrl(
    String videoId, {
    String quality = 'medium',
  }) async {
    var attempt = 0;
    final stopwatch = Stopwatch()..start();
    while (true) {
      try {
        final manifest = await _yt.videos.streams
            .getManifest(videoId)
            .timeout(_timeout);

        final muxed = manifest.muxed;
        if (muxed.isNotEmpty) {
          final best = _selectByQuality(muxed, quality);
          return best.url.toString();
        }

        final audioStreams = manifest.audioOnly.toList();
        if (audioStreams.isEmpty) {
          throw Exception('No audio streams available for video $videoId');
        }
        var candidates = audioStreams
            .where(
              (s) =>
                  s.container == StreamContainer.mp4 ||
                  s.container == StreamContainer.webM,
            )
            .toList();
        if (candidates.isEmpty) {
          candidates = audioStreams;
        }
        final bestAudio = _selectByQuality(candidates, quality);
        return bestAudio.url.toString();
      } on TimeoutException {
        attempt++;
        dev.log(
          'Attempt $attempt timed out for video $videoId',
          name: 'YoutubeRemoteDataSource',
        );
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on Exception catch (e) {
        attempt++;
        final msg = e.toString();
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          dev.log(
            'All $attempt attempts failed for video $videoId: $msg',
            name: 'YoutubeRemoteDataSource',
          );
          rethrow;
        }
        if (msg.contains('requestLimit') || msg.contains('429')) {
          dev.log(
            'Rate limited on attempt $attempt for video $videoId',
            name: 'YoutubeRemoteDataSource',
          );
          await Future.delayed(Duration(seconds: 2 * attempt));
        } else {
          dev.log(
            'Non-retryable error on attempt $attempt for video $videoId: $msg',
            name: 'YoutubeRemoteDataSource',
          );
          rethrow;
        }
      }
    }
  }

  AudioStreamInfo _selectByQuality(
    List<AudioStreamInfo> streams,
    String quality,
  ) {
    final sorted = List<AudioStreamInfo>.from(streams)
      ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    switch (quality) {
      case 'low':
        return sorted.first;
      case 'high':
        return sorted.last;
      case 'medium':
      default:
        return sorted[sorted.length ~/ 2];
    }
  }

  Future<List<TrackModel>> search(String query) async {
    try {
      final songs = await _ytMusic.searchSongs(query).timeout(_timeout);
      final videos = await _ytMusic.searchVideos(query).timeout(_timeout);
      final seen = <String>{};
      final tracks = <TrackModel>[];

      for (final song in songs) {
        if (song.videoId.isEmpty || !seen.add(song.videoId)) continue;
        tracks.add(_trackFromSong(song, tracks.length));
      }

      for (final video in videos) {
        if (video.videoId.isEmpty || !seen.add(video.videoId)) continue;
        tracks.add(_trackFromVideo(video, tracks.length));
      }

      if (tracks.isNotEmpty) return tracks;
    } catch (e) {
      dev.log(
        'YouTube Music search failed for "$query", using YouTube fallback: $e',
        name: 'YoutubeRemoteDataSource',
      );
    }

    final results = await _yt.search.search(query);
    final tracks = <TrackModel>[];
    for (var i = 0; i < results.length; i++) {
      final video = results[i];
      tracks.add(
        TrackModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          durationSeconds: video.duration?.inSeconds ?? 0,
          thumbnailUrl: video.thumbnails.highResUrl,
          index: i,
        ),
      );
    }
    return tracks;
  }

  List<TrackModel> _withIndexes(List<TrackModel> tracks) {
    return [
      for (var i = 0; i < tracks.length; i++)
        TrackModel(
          id: tracks[i].id,
          title: tracks[i].title,
          author: tracks[i].author,
          durationSeconds: tracks[i].durationSeconds,
          thumbnailUrl: tracks[i].thumbnailUrl,
          index: i,
        ),
    ];
  }

  TrackModel _trackFromSong(ytmusic.SongDetailed song, int index) {
    return TrackModel(
      id: song.videoId,
      title: song.name,
      author: song.artist.name,
      durationSeconds: song.duration ?? 0,
      thumbnailUrl: _bestThumbnail(song.thumbnails),
      index: index,
    );
  }

  TrackModel _trackFromVideo(ytmusic.VideoDetailed video, int index) {
    return TrackModel(
      id: video.videoId,
      title: video.name,
      author: video.artist.name,
      durationSeconds: video.duration ?? 0,
      thumbnailUrl: _bestThumbnail(video.thumbnails),
      index: index,
    );
  }

  TrackModel _trackFromUpNext(ytmusic.UpNextsDetails item) {
    return TrackModel(
      id: item.videoId,
      title: item.title,
      author: item.artists.name,
      durationSeconds: item.duration,
      thumbnailUrl: _bestThumbnail(item.thumbnails),
      index: 0,
    );
  }

  String? _bestThumbnail(List<ytmusic.ThumbnailFull> thumbnails) {
    if (thumbnails.isEmpty) return null;
    final sorted = List<ytmusic.ThumbnailFull>.from(thumbnails)
      ..sort((a, b) => (a.width * a.height).compareTo(b.width * b.height));
    return sorted.last.url;
  }

  void dispose() {
    _yt.close();
  }
}
