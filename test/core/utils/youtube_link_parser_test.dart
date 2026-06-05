import 'package:flutter_test/flutter_test.dart';
import 'package:ytmusix/core/utils/youtube_link_parser.dart';

void main() {
  group('YoutubeLinkParser.parse', () {
    test('classifies plain watch URL as video', () {
      final result = YoutubeLinkParser.parse(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(result.type, YoutubeLinkType.video);
      expect(result.videoId, 'dQw4w9WgXcQ');
    });

    test('classifies shorts URL as shorts', () {
      final result = YoutubeLinkParser.parse(
        'https://www.youtube.com/shorts/abc12345678',
      );
      expect(result.type, YoutubeLinkType.shorts);
      expect(result.videoId, 'abc12345678');
    });

    test('classifies youtu.be short URL as video', () {
      final result = YoutubeLinkParser.parse(
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(result.type, YoutubeLinkType.video);
      expect(result.videoId, 'dQw4w9WgXcQ');
    });

    test('classifies live URL as live with video id', () {
      final result = YoutubeLinkParser.parse(
        'https://www.youtube.com/live/jNQXAC9IVRw',
      );
      expect(result.type, YoutubeLinkType.live);
      expect(result.videoId, 'jNQXAC9IVRw');
    });

    test('classifies live URL with /live/<id> and extra params as live', () {
      final result = YoutubeLinkParser.parse(
        'https://www.youtube.com/live/jNQXAC9IVRw?t=42s',
      );
      expect(result.type, YoutubeLinkType.live);
      expect(result.videoId, 'jNQXAC9IVRw');
    });

    test('classifies playlist URL as playlist', () {
      final result = YoutubeLinkParser.parse(
        'https://www.youtube.com/playlist?list=PLrAXtmRdnEQy6nuLMHjMZOz59Oq8B9bAk',
      );
      expect(result.type, YoutubeLinkType.playlist);
      expect(result.playlistId, 'PLrAXtmRdnEQy6nuLMHjMZOz59Oq8B9bAk');
    });

    test('classifies channel /@handle URL as channel', () {
      final result = YoutubeLinkParser.parse('https://www.youtube.com/@mkbhd');
      expect(result.type, YoutubeLinkType.channel);
    });

    test('falls back to youtube_url_processor for nocookie watch URLs', () {
      // The primary parser only matches youtube.com / youtu.be / m.youtube.com
      // / music.youtube.com. youtube-nocookie.com is routed through the
      // youtube_url_processor fallback.
      final result = YoutubeLinkParser.parse(
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
      );
      // Fallback should classify as a video with the embedded id.
      expect(result.type, isNot(YoutubeLinkType.unknown));
      expect(result.videoId, 'dQw4w9WgXcQ');
    });

    test('returns unknown for an unrecognised URL', () {
      final result = YoutubeLinkParser.parse('https://example.com/not-a-link');
      expect(result.type, YoutubeLinkType.unknown);
      expect(result.videoId, isNull);
      expect(result.playlistId, isNull);
    });
  });
}
