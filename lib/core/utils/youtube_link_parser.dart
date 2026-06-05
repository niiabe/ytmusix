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

    return switch ((host, path, videoId, playlistId)) {
      (final h, _, _, _) when h.contains('youtube.com') ||
              h.contains('youtu.be') ||
              h.contains('m.youtube.com') ||
              h.contains('music.youtube.com') =>
        _classifyYouTube(host, path, videoId, playlistId, trimmed),
      _ => _classifyNonYouTube(videoId, playlistId, trimmed),
    };
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
