import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/chart_item.dart';

class ChartService {
  ChartService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const recommendedSongsKey = 'apple_ghana_hot_songs';
  static const hotAlbumsKey = 'apple_ghana_hot_albums';
  static const billboardAlbumsKey = 'billboard_200_albums';

  static const _appleGhanaSongsUrl =
      'https://rss.marketingtools.apple.com/api/v2/gh/music/most-played/100/songs.json';
  static const _appleGhanaAlbumsUrl =
      'https://rss.marketingtools.apple.com/api/v2/gh/music/most-played/100/albums.json';
  static const _billboard200Url =
      'https://www.billboard.com/charts/billboard-200/';

  final http.Client _client;
  final DateTime Function() _now;

  Future<List<ChartItem>> getRecommendedSongs({bool force = false}) {
    return _getCachedChart(
      cacheKey: recommendedSongsKey,
      maxAge: const Duration(hours: 24),
      force: force,
      fetch: () => _fetchAppleChart(
        url: _appleGhanaSongsUrl,
        sourceName: 'Apple Music Ghana Hot 100',
        kind: ChartItemKind.song,
      ),
    );
  }

  Future<List<ChartItem>> getHotAlbums({bool force = false}) {
    return _getCachedChart(
      cacheKey: hotAlbumsKey,
      maxAge: const Duration(days: 3),
      force: force,
      fetch: () => _fetchAppleChart(
        url: _appleGhanaAlbumsUrl,
        sourceName: 'Apple Music Ghana Hot Albums',
        kind: ChartItemKind.album,
      ),
    );
  }

  Future<List<ChartItem>> getBillboard200({bool force = false}) {
    return _getCachedChart(
      cacheKey: billboardAlbumsKey,
      maxAge: const Duration(days: 7),
      force: force,
      fetch: _fetchBillboard200,
    );
  }

  Future<List<ChartItem>> getAppleAlbumSongs(ChartItem album) async {
    final response = await _client.get(
      Uri.parse(
        'https://itunes.apple.com/lookup?id=${album.id}&entity=song&country=gh',
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (json['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((item) => item['wrapperType'] == 'track')
        .toList();

    return results.indexed.map((entry) {
      final item = entry.$2;
      return ChartItem(
        id: (item['trackId'] ?? '${album.id}_${entry.$1}').toString(),
        title: item['trackName'] as String? ?? album.title,
        artist: item['artistName'] as String? ?? album.artist,
        artworkUrl:
            _highResolutionArtwork(item['artworkUrl100'] as String?) ??
            album.artworkUrl,
        sourceName: album.sourceName,
        sourceUrl: item['trackViewUrl'] as String? ?? album.sourceUrl,
        rank: entry.$1 + 1,
        kind: ChartItemKind.song,
      );
    }).toList();
  }

  Future<List<ChartItem>> _getCachedChart({
    required String cacheKey,
    required Duration maxAge,
    required bool force,
    required Future<List<ChartItem>> Function() fetch,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force) {
      final cached = _readCache(prefs, cacheKey, maxAge);
      if (cached != null) return cached;
    }

    final fresh = await fetch();
    await prefs.setString(
      _dataKey(cacheKey),
      jsonEncode(fresh.map((item) => item.toJson()).toList()),
    );
    await prefs.setInt(_timestampKey(cacheKey), _now().millisecondsSinceEpoch);
    return fresh;
  }

  List<ChartItem>? _readCache(
    SharedPreferences prefs,
    String cacheKey,
    Duration maxAge,
  ) {
    final timestamp = prefs.getInt(_timestampKey(cacheKey));
    final payload = prefs.getString(_dataKey(cacheKey));
    if (timestamp == null || payload == null) return null;

    final age = _now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (age > maxAge) return null;

    try {
      final decoded = jsonDecode(payload) as List<dynamic>;
      return decoded
          .map((item) => ChartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<List<ChartItem>> _fetchAppleChart({
    required String url,
    required String sourceName,
    required ChartItemKind kind,
  }) async {
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load $sourceName');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final feed = json['feed'] as Map<String, dynamic>;
    final results = feed['results'] as List<dynamic>;

    return results.indexed.map((entry) {
      final rank = entry.$1 + 1;
      final item = entry.$2 as Map<String, dynamic>;
      return ChartItem(
        id: item['id'] as String,
        title: item['name'] as String,
        artist: item['artistName'] as String,
        artworkUrl: _highResolutionArtwork(item['artworkUrl100'] as String?),
        sourceName: sourceName,
        sourceUrl: item['url'] as String,
        rank: rank,
        kind: kind,
      );
    }).toList();
  }

  Future<List<ChartItem>> _fetchBillboard200() async {
    final response = await _client.get(Uri.parse(_billboard200Url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load Billboard 200');
    }
    return parseBillboard200(response.body);
  }

  static List<ChartItem> parseBillboard200(String html) {
    final rows = html.split('o-chart-results-list-row //');
    final items = <ChartItem>[];

    for (final row in rows.skip(1)) {
      final rankMatch = RegExp(r'data-detail-target="(\d+)"').firstMatch(row);
      final titleMatch = RegExp(
        r'<h3[^>]*id="title-of-a-story"[^>]*>(.*?)</h3>',
        dotAll: true,
      ).firstMatch(row);
      final artistMatch = RegExp(
        r'<span class="[^"]*c-label a-no-trucate[^"]*"[^>]*>(.*?)</span>',
        dotAll: true,
      ).firstMatch(row);

      if (rankMatch == null || titleMatch == null || artistMatch == null) {
        continue;
      }

      final rank = int.tryParse(rankMatch.group(1)!);
      final title = _cleanHtml(titleMatch.group(1)!);
      final artist = _cleanHtml(artistMatch.group(1)!);
      if (rank == null || title.isEmpty || artist.isEmpty) continue;

      final imageMatch = RegExp(
        r'(?:data-lazy-src|src)="(https://[^"]+?(?:jpg|png|webp))"',
      ).firstMatch(row);
      items.add(
        ChartItem(
          id: 'billboard-200-$rank-${_slug(title)}',
          title: title,
          artist: artist,
          artworkUrl: imageMatch?.group(1),
          sourceName: 'US Billboard 200',
          sourceUrl: _billboard200Url,
          rank: rank,
          kind: ChartItemKind.album,
        ),
      );
      if (items.length >= 100) break;
    }

    return items;
  }

  static String _cleanHtml(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&#038;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String? _highResolutionArtwork(String? url) {
    return url?.replaceFirst('/100x100bb.', '/1000x1000bb.');
  }

  static String _dataKey(String cacheKey) => 'chart_cache_${cacheKey}_data';
  static String _timestampKey(String cacheKey) =>
      'chart_cache_${cacheKey}_timestamp';
}
