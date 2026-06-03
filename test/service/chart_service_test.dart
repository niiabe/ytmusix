import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ytmusix/domain/entities/chart_item.dart';
import 'package:ytmusix/service/chart_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads Apple Ghana songs and caches them for 24 hours', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 6, 3, 9);
    var requestCount = 0;
    final service = ChartService(
      now: () => now,
      client: MockClient((request) async {
        requestCount++;
        return http.Response(_applePayload('Song $requestCount'), 200);
      }),
    );

    final first = await service.getRecommendedSongs();
    now = now.add(const Duration(hours: 23));
    final cached = await service.getRecommendedSongs();
    now = now.add(const Duration(hours: 2));
    final refreshed = await service.getRecommendedSongs();

    expect(first.single.title, 'Song 1');
    expect(cached.single.title, 'Song 1');
    expect(refreshed.single.title, 'Song 2');
    expect(requestCount, 2);
  });

  test('loads Apple Ghana albums and caches them for 3 days', () async {
    SharedPreferences.setMockInitialValues({});
    var now = DateTime(2026, 6, 3, 9);
    var requestCount = 0;
    final service = ChartService(
      now: () => now,
      client: MockClient((request) async {
        requestCount++;
        return http.Response(_applePayload('Album $requestCount'), 200);
      }),
    );

    final first = await service.getHotAlbums();
    now = now.add(const Duration(days: 2, hours: 23));
    final cached = await service.getHotAlbums();
    now = now.add(const Duration(hours: 2));
    final refreshed = await service.getHotAlbums();

    expect(first.single.title, 'Album 1');
    expect(cached.single.title, 'Album 1');
    expect(refreshed.single.title, 'Album 2');
    expect(requestCount, 2);
  });

  test('parses Billboard 200 album rows', () {
    final items = ChartService.parseBillboard200('''
      <ul class="o-chart-results-list-row //" data-detail-target="1">
        <h3 id="title-of-a-story" class="c-title">MUSIC</h3>
        <span class="c-label a-no-trucate">
          <a href="/artist/playboi-carti/">Playboi Carti</a>
        </span>
        <img data-lazy-src="https://charts-static.billboard.com/img/album.jpg">
      </ul>
    ''');

    expect(items, hasLength(1));
    expect(items.single.rank, 1);
    expect(items.single.title, 'MUSIC');
    expect(items.single.artist, 'Playboi Carti');
    expect(items.single.kind, ChartItemKind.album);
    expect(items.single.sourceName, 'US Billboard 200');
  });

  test('loads Apple album songs for hot album playback', () async {
    final service = ChartService(
      client: MockClient((request) async {
        expect(request.url.host, 'itunes.apple.com');
        expect(request.url.queryParameters['id'], '456');
        return http.Response(_appleLookupPayload(), 200);
      }),
    );

    const album = ChartItem(
      id: '456',
      title: 'Album Title',
      artist: 'Album Artist',
      sourceName: 'Apple Music Ghana Hot Albums',
      sourceUrl: 'https://music.apple.com/gh/album/456',
      rank: 1,
      kind: ChartItemKind.album,
    );

    final songs = await service.getAppleAlbumSongs(album);

    expect(songs, hasLength(2));
    expect(songs.first.title, 'First Song');
    expect(songs.first.artist, 'Album Artist');
    expect(songs.first.kind, ChartItemKind.song);
    expect(songs.first.artworkUrl, contains('1000x1000bb'));
  });
}

String _applePayload(String title) {
  return '''
  {
    "feed": {
      "results": [
        {
          "artistName": "Black Sherif",
          "id": "123",
          "name": "$title",
          "artworkUrl100": "https://example.com/100x100bb.jpg",
          "url": "https://music.apple.com/gh/album/song/123"
        }
      ]
    }
  }
  ''';
}

String _appleLookupPayload() {
  return '''
  {
    "resultCount": 3,
    "results": [
      {
        "wrapperType": "collection",
        "collectionId": 456,
        "collectionName": "Album Title"
      },
      {
        "wrapperType": "track",
        "trackId": 1,
        "trackName": "First Song",
        "artistName": "Album Artist",
        "artworkUrl100": "https://example.com/100x100bb.jpg",
        "trackViewUrl": "https://music.apple.com/gh/song/1"
      },
      {
        "wrapperType": "track",
        "trackId": 2,
        "trackName": "Second Song",
        "artistName": "Album Artist",
        "artworkUrl100": "https://example.com/100x100bb.jpg",
        "trackViewUrl": "https://music.apple.com/gh/song/2"
      }
    ]
  }
  ''';
}
