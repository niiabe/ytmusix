import 'package:flutter_test/flutter_test.dart';
import 'package:ytmusix/domain/entities/video.dart';
import 'package:ytmusix/presentation/providers/playlist_provider.dart';

Track _track({
  required String id,
  required String title,
  String? author,
  Duration duration = const Duration(minutes: 3),
}) {
  return Track(
    id: id,
    title: title,
    author: author,
    duration: duration,
    index: 0,
  );
}

void main() {
  group('PlaylistProvider.rankHomeFeedTracks', () {
    test('puts official tracks above a DJ mix', () {
      final input = [
        _track(
          id: 'a',
          title: 'Best of Afrobeats DJ Mix 2026',
          author: 'DJ Mensah',
          duration: const Duration(minutes: 90),
        ),
        _track(
          id: 'b',
          title: 'Burna Boy - City Boys (Official Music Video)',
          author: 'Burna Boy',
          duration: const Duration(minutes: 3),
        ),
      ];

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked.first.id, 'b');
      expect(ranked.last.id, 'a');
    });

    test('penalises mixes, megamixes, and nonstop sets', () {
      final input = [
        _track(
          id: 'mix1',
          title: 'Ghana Hits Nonstop DJ Mix',
          author: 'DJ Kweku',
        ),
        _track(
          id: 'mix2',
          title: 'Afrobeats MegaMix 2026',
          author: 'DJ Sam',
        ),
        _track(
          id: 'mix3',
          title: 'Gospel Mixtape Vol 4',
          author: 'GospelHub',
        ),
        _track(
          id: 'official',
          title: 'Sarkodie - Country Side (Official Audio)',
          author: 'Sarkodie',
        ),
      ];

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked.first.id, 'official');
    });

    test('boosts VEVO / Records authors', () {
      final input = [
        _track(
          id: 'unknown',
          title: 'Some Random Track',
          author: 'unknown channel',
        ),
        _track(
          id: 'vevo',
          title: 'Wizkid - Essence',
          author: 'WizkidVEVO',
        ),
      ];

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked.first.id, 'vevo');
    });

    test('penalises very long tracks (likely full sets)', () {
      final input = [
        _track(
          id: 'long',
          title: 'Album Full Ep',
          author: 'Indie Artist',
          duration: const Duration(minutes: 60),
        ),
        _track(
          id: 'short',
          title: 'Indie Artist - Single',
          author: 'Indie Artist',
          duration: const Duration(minutes: 3, seconds: 30),
        ),
      ];

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked.first.id, 'short');
    });

    test('respects the limit', () {
      final input = List.generate(
        20,
        (i) => _track(
          id: 'track_$i',
          title: 'Track $i (Official Audio)',
          author: 'Artist',
        ),
      );

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked, hasLength(5));
    });

    test('preserves original order as a stable tie-breaker', () {
      final input = [
        _track(
          id: 'a',
          title: 'Track A (Official Audio)',
          author: 'Artist',
        ),
        _track(
          id: 'b',
          title: 'Track B (Official Audio)',
          author: 'Artist',
        ),
        _track(
          id: 'c',
          title: 'Track C (Official Audio)',
          author: 'Artist',
        ),
      ];

      final ranked = PlaylistProvider.rankHomeFeedTracks(input, 5);

      expect(ranked.map((t) => t.id).toList(), ['a', 'b', 'c']);
    });
  });
}
