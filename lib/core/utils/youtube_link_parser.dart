import 'package:youtube_url_processor/youtube_url_processor.dart' as yup;

enum YoutubeLinkType {
  video,
  playlist,
  shorts,
  live,
  musicVideo,
  channel,
  unknown,
}

class YoutubeLinkResult {
  final YoutubeLinkType type;
  final String? videoId;
  final String? playlistId;

  const YoutubeLinkResult({
    required this.type,
    this.videoId,
    this.playlistId,
  });
}

class YoutubeLinkParser {
  static String? extractVideoId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.isNotEmpty) {
      if (uri.queryParameters.containsKey('v')) {
        final id = uri.queryParameters['v'];
        if (id != null && id.length == 11) return id;
      }
    }
    final patterns = [
      RegExp(r'(?:youtube\.com/watch\?.*v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com/shorts/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com/live/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:m\.youtube\.com/watch\?.*v=)([a-zA-Z0-9_-]{11})'),
      RegExp(r'(?:youtube\.com/embed/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      final id = uri.queryParameters['list'];
      if (id != null && id.isNotEmpty) return id;
    }
    final patterns = [
      RegExp(r'(?:list=)([a-zA-Z0-9_-]+)'),
      RegExp(r'^([a-zA-Z0-9_-]{13,})$'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static YoutubeLinkResult parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const YoutubeLinkResult(type: YoutubeLinkType.unknown);
    }

    final videoId = extractVideoId(trimmed);
    final playlistId = extractPlaylistId(trimmed);

    final host = Uri.tryParse(trimmed)?.host ?? '';
    final path = Uri.tryParse(trimmed)?.path ?? '';

    if (host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('m.youtube.com') ||
        host.contains('music.youtube.com')) {
      return _classifyYouTube(host, path, videoId, playlistId, trimmed);
    }

    final nonHost = _classifyNonYouTube(videoId, playlistId, trimmed);
    if (nonHost.type != YoutubeLinkType.unknown) {
      return nonHost;
    }

    // Fall back to youtube_url_processor for inputs the primary extractor
    // can't classify. Catches live channel URLs, channel/@handle, nocookie,
    // clip links, and other variants.
    return _YoutubeUrlProcessorFallback.tryParse(trimmed) ??
        const YoutubeLinkResult(type: YoutubeLinkType.unknown);
  }

  static YoutubeLinkResult _classifyYouTube(
    String host,
    String path,
    String? videoId,
    String? playlistId,
    String input,
  ) {
    if (host.contains('music.youtube.com')) {
      if (playlistId != null) {
        return YoutubeLinkResult(
          type: YoutubeLinkType.playlist,
          videoId: videoId,
          playlistId: playlistId,
        );
      }
      if (videoId != null) {
        return YoutubeLinkResult(
          type: YoutubeLinkType.musicVideo,
          videoId: videoId,
        );
      }
    }

    if (path.startsWith('/shorts/')) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.shorts,
        videoId: videoId,
        playlistId: playlistId,
      );
    }

    if (path.startsWith('/live/') || path == '/live') {
      return YoutubeLinkResult(
        type: YoutubeLinkType.live,
        videoId: videoId,
        playlistId: playlistId,
      );
    }

    if (path.startsWith('/channel/') || path.startsWith('/@')) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.channel,
        videoId: videoId,
        playlistId: playlistId,
      );
    }

    if (path.startsWith('/playlist')) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.playlist,
        videoId: videoId,
        playlistId: playlistId,
      );
    }

    if (path.startsWith('/watch') || host.contains('youtu.be')) {
      if (playlistId != null && videoId != null) {
        return YoutubeLinkResult(
          type: YoutubeLinkType.playlist,
          videoId: videoId,
          playlistId: playlistId,
        );
      }
      if (videoId != null) {
        return YoutubeLinkResult(
          type: YoutubeLinkType.video,
          videoId: videoId,
        );
      }
    }

    if (videoId != null) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.video,
        videoId: videoId,
        playlistId: playlistId,
      );
    }

    if (playlistId != null) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.playlist,
        playlistId: playlistId,
      );
    }

    return const YoutubeLinkResult(type: YoutubeLinkType.unknown);
  }

  static YoutubeLinkResult _classifyNonYouTube(
    String? videoId,
    String? playlistId,
    String input,
  ) {
    if (playlistId != null && videoId != null) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.playlist,
        videoId: videoId,
        playlistId: playlistId,
      );
    }
    if (playlistId != null) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.playlist,
        playlistId: playlistId,
      );
    }
    if (videoId != null) {
      return YoutubeLinkResult(
        type: YoutubeLinkType.video,
        videoId: videoId,
      );
    }
    return const YoutubeLinkResult(type: YoutubeLinkType.unknown);
  }
}

/// Second-stage parser that delegates to the `youtube_url_processor`
/// package. The primary parser above stays self-contained and fast; the
/// fallback only runs when the primary cannot classify the input.
class _YoutubeUrlProcessorFallback {
  static const _extractor = yup.YouTubeUrlExtractor();

  static YoutubeLinkResult? tryParse(String input) {
    try {
      final result = _extractor.extract(input);
      if (!result.isSuccess) return null;
      final entity = result.value;
      if (entity == null) return null;

      switch (entity.type) {
        case yup.YouTubeContentType.video:
          final v = entity.video;
          if (v == null || v.videoId.isEmpty) return null;
          return YoutubeLinkResult(
            type: v.isShort
                ? YoutubeLinkType.shorts
                : YoutubeLinkType.video,
            videoId: v.videoId,
            playlistId: v.playlistId,
          );
        case yup.YouTubeContentType.short:
          final v = entity.video;
          if (v == null || v.videoId.isEmpty) return null;
          return YoutubeLinkResult(
            type: YoutubeLinkType.shorts,
            videoId: v.videoId,
            playlistId: v.playlistId,
          );
        case yup.YouTubeContentType.live:
          final v = entity.video;
          if (v == null || v.videoId.isEmpty) return null;
          return YoutubeLinkResult(
            type: YoutubeLinkType.live,
            videoId: v.videoId,
            playlistId: v.playlistId,
          );
        case yup.YouTubeContentType.clip:
          final v = entity.video;
          if (v == null || v.videoId.isEmpty) return null;
          return YoutubeLinkResult(
            type: YoutubeLinkType.video,
            videoId: v.videoId,
            playlistId: v.playlistId,
          );
        case yup.YouTubeContentType.playlist:
          final p = entity.playlist;
          if (p == null || p.playlistId.isEmpty) return null;
          return YoutubeLinkResult(
            type: YoutubeLinkType.playlist,
            videoId: entity.video?.videoId,
            playlistId: p.playlistId,
          );
        case yup.YouTubeContentType.channel:
          return const YoutubeLinkResult(type: YoutubeLinkType.channel);
        case yup.YouTubeContentType.unknown:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
