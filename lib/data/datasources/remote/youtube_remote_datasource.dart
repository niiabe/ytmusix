import 'dart:async';
import 'dart:developer' as dev;
import 'package:youtube_explode_dart/youtube_explode_dart.dart'
    hide Playlist, Video;
import '../../../domain/entities/search_result_models.dart';
import '../../models/playlist_model.dart';
import '../../models/video_model.dart';
import '../../../service/auth_service.dart';
import 'authenticated_client.dart';

class YoutubeRemoteDataSource {
  static const _timeout = Duration(seconds: 30);

  final AuthService _authService;
  late final YoutubeExplode _yt;

  YoutubeRemoteDataSource({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<void> init() async {
    final cookies = await _authService.getCookies();
    final inner = AuthenticatedClient(cookies: cookies);
    final ytHttp = YoutubeHttpClient(inner);
    _yt = YoutubeExplode(httpClient: ytHttp);
    // YouTube Music API integration is disabled — the standalone ytmusic
    // package is not in this project's dependencies. YouTube catalog features
    // (search, recommendations, related videos) are powered by
    // youtube_explode_dart instead.
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
            dev.log('Playlist videos fetch failed for $playlistId (attempt $attempt): $e',
                name: 'YoutubeRemoteDataSource');
            return <dynamic>[];
          }
        }();

        if (videos.isEmpty) {
          throw Exception('No videos found for playlist/mix $playlistId');
        }

        final tracks = <TrackModel>[];
        const chunkVal = 8;
        for (var i = 0; i < videos.length; i += chunkVal) {
          final chunk = videos.sublist(
            i,
            (i + chunkVal) > videos.length ? videos.length : i + chunkVal,
          );
          final chunkResults = await Future.wait(
            chunk.map((video) async {
              Duration? duration = video.duration;
              if (duration == null || duration.inSeconds == 0) {
                try {
                  final fullVideo = await _yt.videos
                      .get(video.id.value)
                      .timeout(const Duration(seconds: 3));
                  duration = fullVideo.duration;
                } catch (e) {
                  dev.log(
                    'Failed to get duration for video ${video.id.value}: $e',
                    name: 'YoutubeRemoteDataSource',
                  );
                }
              }
              return TrackModel(
                id: video.id.value,
                title: video.title,
                author: video.author,
                durationSeconds: duration?.inSeconds ?? 0,
                thumbnailUrl: _highQualityThumbnail(video.id.value),
                index: 0,
              );
            }),
          );
          tracks.addAll(chunkResults);
        }
        for (var i = 0; i < tracks.length; i++) {
          tracks[i] = TrackModel(
            id: tracks[i].id,
            title: tracks[i].title,
            author: tracks[i].author,
            durationSeconds: tracks[i].durationSeconds,
            thumbnailUrl: tracks[i].thumbnailUrl,
            index: i,
          );
        }

        final thumbnailUrl = tracks.isNotEmpty ? tracks.first.thumbnailUrl : null;

        return PlaylistModel(
          id: playlistId,
          title: title,
          author: author,
          thumbnailUrl: thumbnailUrl,
          videoCount: tracks.length,
          tracks: tracks,
        );
      } on TimeoutException {
        dev.log('Attempt $attempt timed out for playlist $playlistId',
            name: 'YoutubeRemoteDataSource');
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on Exception catch (e) {
        final msg = e.toString();
        dev.log('Playlist fetch attempt $attempt failed for $playlistId: $msg',
            name: 'YoutubeRemoteDataSource');
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
      thumbnailUrl: _highQualityThumbnail(video.id.value),
      index: 0,
    );
  }

  Future<List<TrackModel>> search(String query) async {
    try {
      final list = await _yt.search.search(query).timeout(_timeout);
      final tracks = <TrackModel>[];
      var index = 0;
      for (final video in list) {
        if (index >= 25) break;
        tracks.add(
          TrackModel(
            id: video.id.value,
            title: video.title,
            author: video.author,
            durationSeconds: video.duration?.inSeconds ?? 0,
            thumbnailUrl: _highQualityThumbnail(video.id.value),
            index: index,
          ),
        );
        index++;
      }
      return tracks;
    } catch (e) {
      dev.log(
        'Search failed for "$query": $e',
        name: 'YoutubeRemoteDataSource',
      );
      return const <TrackModel>[];
    }
  }

  /// Returns the highest-quality YouTube thumbnail URL for a given video ID.
  /// Uses maxresdefault (1280×720) which is the best YouTube offers.
  String _highQualityThumbnail(String videoId) {
    return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
  }

  String _addGeoBypassParams(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);
      queryParams['hl'] = 'en';
      queryParams['gl'] = 'US';
      queryParams['alr'] = 'yes';
      return uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      return url;
    }
  }

  Future<List<TrackModel>> getRecommendations(
    String videoId, {
    int limit = 20,
  }) async {
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
          thumbnailUrl: _highQualityThumbnail(recommendation.id.value),
          index: tracks.length,
        ),
      );
    }
    return tracks;
  }

  Future<String> getVideoUrl(
    String videoId, {
    String quality = 'low',
  }) async {
    final manifest = await _yt.videos.streams
        .getManifest(videoId)
        .timeout(_timeout);
    final hlsMuxed = manifest.hls.whereType<HlsMuxedStreamInfo>().toList();
    if (hlsMuxed.isNotEmpty) {
      final best = _selectByQuality(hlsMuxed, quality);
      return _addGeoBypassParams(best.url.toString());
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
      return _addGeoBypassParams(best.url.toString());
    }

    final mp4Muxed = manifest.muxed
        .where((stream) => stream.container == StreamContainer.mp4)
        .toList();
    if (mp4Muxed.isNotEmpty) {
      final best = _selectByQuality(mp4Muxed, quality);
      return _addGeoBypassParams(best.url.toString());
    }

    final fallbackMuxed = manifest.muxed.toList();
    if (fallbackMuxed.isEmpty) {
      throw Exception('No playable video streams available for video $videoId');
    }
    final best = _selectByQuality(fallbackMuxed, quality);
    return _addGeoBypassParams(best.url.toString());
  }

  Future<String> getAudioUrl(
    String videoId, {
    String quality = 'low',
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
          return _addGeoBypassParams(best.url.toString());
        }

        final audioStreams = manifest.audioOnly.toList();
        if (audioStreams.isEmpty) {
          throw Exception('No audio streams available for video $videoId');
        }
        var candidates = audioStreams
            .where((s) =>
                s.container == StreamContainer.mp4 ||
                s.container == StreamContainer.webM)
            .toList();
        if (candidates.isEmpty) {
          candidates = audioStreams;
        }
        final bestAudio = _selectByQuality(candidates, quality);
        return _addGeoBypassParams(bestAudio.url.toString());
      } on TimeoutException {
        attempt++;
        dev.log('Attempt $attempt timed out for video $videoId',
            name: 'YoutubeRemoteDataSource');
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on Exception catch (e) {
        attempt++;
        final msg = e.toString();
        if (attempt >= 3 || stopwatch.elapsed > const Duration(seconds: 45)) {
          dev.log('All $attempt attempts failed for video $videoId: $msg',
              name: 'YoutubeRemoteDataSource');
          rethrow;
        }
        if (msg.contains('requestLimit') || msg.contains('429')) {
          dev.log('Rate limited on attempt $attempt for video $videoId',
              name: 'YoutubeRemoteDataSource');
          await Future.delayed(Duration(seconds: 2 * attempt));
        } else {
          dev.log('Non-retryable error on attempt $attempt for video $videoId: $msg',
              name: 'YoutubeRemoteDataSource');
          rethrow;
        }
      }
    }
  }

  AudioStreamInfo _selectByQuality(List<AudioStreamInfo> streams, String quality) {
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

  Future<List<TrackModel>> getRelatedVideos(String videoId,
      {int maxResults = 20}) async {
    final video = await _yt.videos.get(videoId);
    final related = await _yt.videos.getRelatedVideos(video);
    final videos = related?.take(maxResults).toList() ?? [];
    final tracks = <TrackModel>[];
    for (var i = 0; i < videos.length; i++) {
      final video = videos[i];
      tracks.add(
        TrackModel(
          id: video.id.value,
          title: video.title,
          author: video.author,
          durationSeconds: video.duration?.inSeconds ?? 0,
          thumbnailUrl: _highQualityThumbnail(video.id.value),
          index: i,
        ),
      );
    }
    return tracks;
  }

  Future<CategorizedSearchResults> searchAll(String query) async {
    // The YouTube Music API is not wired in this build, so album / artist /
    // playlist results stay empty. We still fall back to the standard search
    // (powered by youtube_explode_dart) so the songs tab is usable.
    try {
      final songs = await search(query);
      if (songs.isEmpty) {
        return const CategorizedSearchResults();
      }
      return CategorizedSearchResults(
        songs: songs.map((m) => m.toEntity()).toList(),
      );
    } catch (e) {
      dev.log(
        'searchAll fallback failed for "$query": $e',
        name: 'YoutubeRemoteDataSource',
      );
      return const CategorizedSearchResults();
    }
  }

  Future<AlbumDetailResult> getAlbum(String albumId) async {
    // Album detail powered by the YouTube Music API is not available.
    return const AlbumDetailResult(
      id: '',
      title: 'Albums unavailable',
      artist: '',
    );
  }

  Future<ArtistDetailResult> getArtist(String artistId) async {
    // Artist detail powered by the YouTube Music API is not available.
    return const ArtistDetailResult(
      id: '',
      name: 'Artist unavailable',
    );
  }

  void dispose() {
    _yt.close();
  }
}
