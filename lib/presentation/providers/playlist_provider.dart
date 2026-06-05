import 'dart:convert';
import 'dart:io';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/playlist_sort_mode.dart';
import '../../domain/entities/search_result_models.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/playlist_repository.dart';

class PlaylistProvider extends ChangeNotifier {
  final PlaylistRepository _repository;

  PlaylistProvider(this._repository);

  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  bool _isLoading = false;
  String? _error;
  PlaylistSortMode _sortMode = PlaylistSortMode.dateAdded;
  Set<String> _favoriteIds = {};
  List<Track> _favoriteTracks = [];
  List<Playlist> _favoriteCollections = [];
  Set<String> _favoriteCollectionIds = {};
  final Map<String, List<Track>> _homeFeeds = {};
  final Set<String> _loadingHomeFeeds = {};
  final Map<String, List<Track>> _silentSearchCache = {};

  static const _silentSearchCachePrefix = 'silent_search_cache_v1';
  static const _silentSearchCacheMaxAge = Duration(days: 7);
  static const _searchHistoryKey = 'search_history_v1';
  static const _maxSearchHistory = 20;

  List<String> _searchHistory = [];
  CategorizedSearchResults? _categorizedResults;
  bool _isCategorizedSearching = false;

  PlaylistSortMode get sortMode => _sortMode;
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  CategorizedSearchResults? get categorizedResults => _categorizedResults;
  bool get isCategorizedSearching => _isCategorizedSearching;
  List<Track> get favoriteTracks => _favoriteTracks;
  List<Playlist> get favoriteCollections => _favoriteCollections;
  Set<String> get favoriteCollectionIds => _favoriteCollectionIds;

  List<Playlist> get playlists {
    final sorted = List<Playlist>.from(_playlists);
    switch (_sortMode) {
      case PlaylistSortMode.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case PlaylistSortMode.trackCount:
        sorted.sort((a, b) => b.videoCount.compareTo(a.videoCount));
        break;
      case PlaylistSortMode.dateAdded:
        break;
    }
    return sorted;
  }

  void setSortMode(PlaylistSortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  Playlist? get currentPlaylist => _currentPlaylist;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Track> homeFeed(String key) => _homeFeeds[key] ?? const [];
  bool isHomeFeedLoading(String key) => _loadingHomeFeeds.contains(key);

  Future<Playlist?> fetchPlaylist(String input) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cleanId = _extractPlaylistId(input);
      if (cleanId.isEmpty) {
        _error = 'Could not extract a playlist ID from that URL';
        return null;
      }
      _currentPlaylist = await _repository.getPlaylist(cleanId);
      await _reloadSilently();
      return _currentPlaylist;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> fetchFromUrl(String input) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentPlaylist = await _repository.getFromUrl(input);
      await _reloadSilently();
      return _currentPlaylist;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSilently() async {
    try {
      _playlists = await _repository.getSavedPlaylists();
    } catch (e) {
      dev.log(
        'Failed to reload playlists silently: $e',
        name: 'PlaylistProvider',
      );
    }
  }

  Future<void> loadSavedPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _playlists = await _repository.getSavedPlaylists();
    } catch (e) {
      _error = 'Failed to load saved playlists';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCachedPlaylist(String playlistId) async {
    try {
      final cached = await _repository.getCachedPlaylist(playlistId);
      if (cached != null) {
        _currentPlaylist = cached;
        notifyListeners();
      }
    } catch (e) {
      dev.log(
        'Failed to load cached playlist $playlistId: $e',
        name: 'PlaylistProvider',
      );
    }
  }

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String trackId) => _favoriteIds.contains(trackId);

  Future<void> loadFavoriteTracks() async {
    try {
      _favoriteTracks = await _repository.getFavoriteTracks();
      _favoriteIds = _favoriteTracks.map((t) => t.id).toSet();
      notifyListeners();
    } catch (e) {
      dev.log('Failed to load favorite tracks: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> loadFavoriteIds() async {
    await loadFavoriteTracks();
  }

  Future<void> toggleFavorite(Track track) async {
    final wasFavorite = _favoriteIds.contains(track.id);
    if (wasFavorite) {
      _favoriteIds.remove(track.id);
      _favoriteTracks.removeWhere((t) => t.id == track.id);
    } else {
      _favoriteIds.add(track.id);
      _favoriteTracks.insert(0, track);
    }
    notifyListeners();
    try {
      await _repository.toggleFavorite(track);
    } catch (e) {
      if (wasFavorite) {
        _favoriteIds.add(track.id);
        _favoriteTracks.insert(0, track);
      } else {
        _favoriteIds.remove(track.id);
        _favoriteTracks.removeWhere((t) => t.id == track.id);
      }
      notifyListeners();
    }
  }

  bool isCollectionFavorite(String collectionId) => _favoriteCollectionIds.contains(collectionId);

  Future<void> loadFavoriteCollections() async {
    try {
      _favoriteCollections = await _repository.getFavoriteCollections();
      _favoriteCollectionIds = _favoriteCollections.map((c) => c.id).toSet();
      notifyListeners();
    } catch (e) {
      dev.log('Failed to load favorite collections: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> toggleFavoriteCollection(Playlist playlist, String type) async {
    final wasFavorite = _favoriteCollectionIds.contains(playlist.id);
    final updatedPlaylist = Playlist(
      id: playlist.id,
      title: playlist.title,
      description: playlist.description,
      thumbnailUrl: playlist.thumbnailUrl,
      author: playlist.author,
      videoCount: playlist.videoCount,
      tracks: playlist.tracks,
      type: type,
    );

    if (wasFavorite) {
      _favoriteCollectionIds.remove(playlist.id);
      _favoriteCollections.removeWhere((c) => c.id == playlist.id);
    } else {
      _favoriteCollectionIds.add(playlist.id);
      _favoriteCollections.insert(0, updatedPlaylist);
    }
    notifyListeners();

    try {
      await _repository.toggleFavoriteCollection(playlist, type);
    } catch (e) {
      if (wasFavorite) {
        _favoriteCollectionIds.add(playlist.id);
        _favoriteCollections.insert(0, updatedPlaylist);
      } else {
        _favoriteCollectionIds.remove(playlist.id);
        _favoriteCollections.removeWhere((c) => c.id == playlist.id);
      }
      notifyListeners();
      dev.log('Failed to toggle favorite collection: $e', name: 'PlaylistProvider');
    }
  }

  Future<Playlist?> getFavoritesPlaylist() async {
    try {
      final tracks = await _repository.getFavoriteTracks();
      if (tracks.isEmpty) return null;
      return Playlist(
        id: '__favorites__',
        title: 'Favorites',
        thumbnailUrl: tracks.first.thumbnailUrl,
        videoCount: tracks.length,
        tracks: tracks,
      );
    } catch (e) {
      dev.log('Failed to get favorites playlist: $e', name: 'PlaylistProvider');
      return null;
    }
  }

  Future<List<Track>?> getCachedTracks(String playlistId) async {
    try {
      return _repository.getCachedTracks(playlistId);
    } catch (e) {
      dev.log(
        'Failed to get cached tracks for $playlistId: $e',
        name: 'PlaylistProvider',
      );
      return null;
    }
  }

  Future<void> saveSingleTrack(Track track) async {
    final playlist = Playlist(
      id: track.id,
      title: track.title,
      author: track.author,
      thumbnailUrl: track.thumbnailUrl,
      videoCount: 1,
      tracks: [track],
    );
    await _repository.savePlaylist(playlist);
    await _reloadSilently();
    notifyListeners();
  }

  Future<void> renamePlaylist(String id, String newTitle) async {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;
    try {
      await _repository.updatePlaylistTitle(id, newTitle);
      _playlists[index] = Playlist(
        id: _playlists[index].id,
        title: newTitle,
        description: _playlists[index].description,
        thumbnailUrl: _playlists[index].thumbnailUrl,
        author: _playlists[index].author,
        videoCount: _playlists[index].videoCount,
        tracks: _playlists[index].tracks,
      );
      if (_currentPlaylist?.id == id) {
        _currentPlaylist = Playlist(
          id: _currentPlaylist!.id,
          title: newTitle,
          description: _currentPlaylist!.description,
          thumbnailUrl: _currentPlaylist!.thumbnailUrl,
          author: _currentPlaylist!.author,
          videoCount: _currentPlaylist!.videoCount,
          tracks: _currentPlaylist!.tracks,
        );
      }
      notifyListeners();
    } catch (e) {
      dev.log('Failed to rename playlist $id: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    if (_currentPlaylist?.id == playlistId) {
      _currentPlaylist = Playlist(
        id: _currentPlaylist!.id,
        title: _currentPlaylist!.title,
        description: _currentPlaylist!.description,
        thumbnailUrl: _currentPlaylist!.thumbnailUrl,
        author: _currentPlaylist!.author,
        videoCount: _currentPlaylist!.videoCount - 1,
        tracks: _currentPlaylist!.tracks.where((t) => t.id != trackId).toList(),
      );
      notifyListeners();
    }
    try {
      await _repository.removeTrack(playlistId, trackId);
    } catch (e) {
      dev.log(
        'Failed to remove track $trackId from $playlistId: $e',
        name: 'PlaylistProvider',
      );
    }
  }

  Future<void> reorderTracks(
    String playlistId,
    List<String> trackIdsInOrder,
  ) async {
    try {
      await _repository.reorderTracks(playlistId, trackIdsInOrder);
    } catch (e) {
      dev.log(
        'Failed to reorder tracks in $playlistId: $e',
        name: 'PlaylistProvider',
      );
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _repository.deletePlaylist(playlistId);
    _playlists.removeWhere((p) => p.id == playlistId);
    if (_currentPlaylist?.id == playlistId) {
      _currentPlaylist = null;
    }
    notifyListeners();
  }

  String _extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      final id = uri.queryParameters['list'];
      if (id != null && id.isNotEmpty) return id;
    }
    return trimmed;
  }

  Future<String> exportPlaylists(String format) async {
    final playlists = await _repository.getSavedPlaylists();
    final data = <Map<String, dynamic>>[];
    for (final p in playlists) {
      final tracks = await _repository.getCachedTracks(p.id);
      data.add({
        'id': p.id,
        'title': p.title,
        'author': p.author,
        'thumbnailUrl': p.thumbnailUrl,
        'videoCount': p.videoCount,
        'tracks': tracks
            .map(
              (t) => {
                'id': t.id,
                'title': t.title,
                'author': t.author,
                'durationSeconds': t.duration.inSeconds,
                'thumbnailUrl': t.thumbnailUrl,
              },
            )
            .toList(),
      });
    }
    final export = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'playlists': data,
    };

    String content;
    String ext;
    switch (format) {
      case 'xml':
        ext = 'xml';
        content = _toXml(export);
        break;
      case 'md':
        ext = 'md';
        content = _toMarkdown(playlists);
        break;
      default:
        ext = 'json';
        content = const JsonEncoder.withIndent('  ').convert(export);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/ytmusix_export.$ext');
    await file.writeAsString(content);
    return file.path;
  }

  Future<int> importPlaylists(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final trimmed = content.trim();
    int count = 0;

    if (trimmed.startsWith('{')) {
      final json = jsonDecode(trimmed) as Map<String, dynamic>;
      final playlists = json['playlists'] as List<dynamic>;
      for (final p in playlists) {
        final id = p['id'] as String;
        final url = 'https://www.youtube.com/playlist?list=$id';
        try {
          await fetchFromUrl(url);
          count++;
        } catch (e) {
          dev.log('Import failed for $id: $e', name: 'PlaylistProvider');
        }
      }
    } else if (trimmed.startsWith('<')) {
      final idRegex = RegExp(r'<id>([^<]+)</id>');
      for (final match in idRegex.allMatches(trimmed)) {
        final id = match.group(1)!;
        try {
          await fetchFromUrl('https://www.youtube.com/playlist?list=$id');
          count++;
        } catch (e) {
          dev.log('Import failed for $id: $e', name: 'PlaylistProvider');
        }
      }
    } else {
      final urlRegex = RegExp(r'https?://[^\s\)\]]+');
      for (final match in urlRegex.allMatches(trimmed)) {
        try {
          await fetchFromUrl(match.group(0)!);
          count++;
        } catch (e) {
          dev.log('Import failed: $e', name: 'PlaylistProvider');
        }
      }
    }
    return count;
  }

  String _toXml(Map<String, dynamic> data) {
    final buf = StringBuffer('<?xml version="1.0" encoding="UTF-8"?>\n');
    buf.writeln(
      '<ytmusix version="${data['version']}" exportedAt="${data['exportedAt']}">',
    );
    for (final p in data['playlists'] as List<dynamic>) {
      buf.writeln('  <playlist>');
      buf.writeln('    <id>${p['id']}</id>');
      buf.writeln('    <title>${_xmlEscape(p['title'])}</title>');
      buf.writeln('    <author>${_xmlEscape(p['author'] ?? '')}</author>');
      buf.writeln('    <videoCount>${p['videoCount']}</videoCount>');
      final tracks = p['tracks'] as List<dynamic>?;
      if (tracks != null && tracks.isNotEmpty) {
        buf.writeln('    <tracks>');
        for (final t in tracks) {
          buf.writeln('      <track>');
          buf.writeln('        <id>${t['id']}</id>');
          buf.writeln('        <title>${_xmlEscape(t['title'])}</title>');
          buf.writeln('      </track>');
        }
        buf.writeln('    </tracks>');
      }
      buf.writeln('  </playlist>');
    }
    buf.writeln('</ytmusix>');
    return buf.toString();
  }

  String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  String _toMarkdown(List<Playlist> playlists) {
    final buf = StringBuffer('# YTMusix Canary Export\n\n');
    buf.writeln('Exported on ${DateTime.now().toLocal()}\n');
    for (final p in playlists) {
      buf.writeln(
        '- [${p.title}](${"https://www.youtube.com/playlist?list=${p.id}"})',
      );
    }
    return buf.toString();
  }

  Future<List<Track>> search(String query) async {
    try {
      return await _repository.search(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<CategorizedSearchResults> searchSilently(String query) async {
    final key = _normalizeSilentSearchKey(query);
    if (key.isEmpty) return const CategorizedSearchResults();

    final cached = _silentSearchCache[key];
    if (cached != null) {
      return _toCategorizedResults(cached);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_silentSearchCachePrefix:$key');
      if (stored != null) {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        final savedAt = DateTime.tryParse(decoded['savedAt'] as String? ?? '');
        final isFresh = savedAt != null &&
            DateTime.now().difference(savedAt) < _silentSearchCacheMaxAge;
        if (isFresh) {
          final tracks = (decoded['tracks'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(Track.fromJson)
              .toList();
          _silentSearchCache[key] = tracks;
          return _toCategorizedResults(tracks);
        }
      }
    } catch (e) {
      dev.log(
        'Failed to read silent search cache: $e',
        name: 'PlaylistProvider',
      );
    }

    final results = await _repository.search(query);
    _silentSearchCache[key] = results;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_silentSearchCachePrefix:$key',
        jsonEncode({
          'savedAt': DateTime.now().toIso8601String(),
          'tracks': results.map((t) => t.toJson()).toList(),
        }),
      );
    } catch (e) {
      dev.log(
        'Failed to persist silent search cache: $e',
        name: 'PlaylistProvider',
      );
    }

    return _toCategorizedResults(results);
  }

  String _normalizeSilentSearchKey(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  CategorizedSearchResults _toCategorizedResults(List<Track> tracks) {
    return CategorizedSearchResults(
      songs: tracks,
      videos: tracks,
      albums: const [],
      artists: const [],
      playlists: const [],
    );
  }

  Future<void> loadHomeFeed(String key, {bool force = false}) async {
    if (!force && _homeFeeds.containsKey(key)) return;
    if (_loadingHomeFeeds.contains(key)) return;

    _loadingHomeFeeds.add(key);
    _error = null;
    notifyListeners();

    try {
      final query = switch (key) {
        'new' => 'new Ghana music releases 2026 official audio',
        'trend' => 'trending Ghana music 2026 official audio',
        'podcasts' => 'Ghana podcasts latest episodes',
        _ => key,
      };
      final raw = await _repository.search(query);
      final seen = <String>{};
      final unique = <Track>[
        for (final track in raw)
          if (seen.add(track.id)) track,
      ];
      _homeFeeds[key] = key == 'podcasts'
          ? unique.take(18).toList()
          : rankHomeFeedTracks(unique, 18);
    } catch (e) {
      _error = e.toString();
      _homeFeeds[key] = const [];
    } finally {
      _loadingHomeFeeds.remove(key);
      notifyListeners();
    }
  }

  /// Rank home-feed tracks so that official tracks and music videos are
  /// surfaced above DJ mixes, long-form sets, and other low-priority
  /// content. The original order is used as a stable tie-breaker so the
  /// YouTube relevance ranking is still respected among tracks that score
  /// equally.
  @visibleForTesting
  static List<Track> rankHomeFeedTracks(List<Track> input, int limit) {
    final indexed = input.indexed.toList();
    indexed.sort((a, b) {
      final byScore = _scoreTrack(b.$2).compareTo(_scoreTrack(a.$2));
      if (byScore != 0) return byScore;
      return a.$1.compareTo(b.$1);
    });
    return indexed.take(limit).map((e) => e.$2).toList();
  }

  static int _scoreTrack(Track track) {
    final title = track.title.toLowerCase();
    final author = (track.author ?? '').toLowerCase();
    final durationSeconds = track.duration.inSeconds;
    var score = 0;

    if (_matchesAny(title, _officialKeywords)) {
      score += 12;
    }
    if (_matchesAny(title, const ['music video', 'm/v'])) {
      score += 6;
    }
    if (_matchesAny(title, const ['lyric', 'lyrics', 'lyric video'])) {
      score += 4;
    }
    if (_matchesAny(author, _trustedAuthorKeywords)) {
      score += 5;
    }
    if (_matchesAny(title, _mixKeywords)) {
      score -= 20;
    }
    if (_matchesAny(author, _mixAuthorKeywords)) {
      score -= 15;
    }
    if (durationSeconds > 0) {
      if (durationSeconds > 12 * 60) {
        score -= 10;
      } else if (durationSeconds < 60) {
        score -= 6;
      } else if (durationSeconds <= 6 * 60) {
        score += 3;
      }
    }
    return score;
  }

  static bool _matchesAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle)) return true;
    }
    return false;
  }

  static const _officialKeywords = [
    'official',
    'official audio',
    'official video',
    'official music',
  ];

  static const _mixKeywords = [
    'dj mix',
    'mixtape',
    'mix tape',
    'nonstop',
    'non-stop',
    'non stop',
    'megamix',
    'mega mix',
    'club mix',
    'party mix',
    'blend',
    'mashup',
    'mash up',
    'best of',
    'all time',
    'full ep',
    'full album',
  ];

  static const _mixAuthorKeywords = [
    'dj ',
    ' dj',
    'mixtape',
    'mixes',
    'radio',
  ];

  static const _trustedAuthorKeywords = [
    'vevo',
    'records',
    'music',
    'official',
    'entertainment',
    'productions',
  ];

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
      notifyListeners();
    } catch (e) {
      dev.log('Failed to load search history: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > _maxSearchHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxSearchHistory);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      dev.log('Failed to save search history: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> removeSearchHistory(String query) async {
    _searchHistory.remove(query);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      dev.log('Failed to remove search history: $e', name: 'PlaylistProvider');
    }
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
    } catch (e) {
      dev.log('Failed to clear search history: $e', name: 'PlaylistProvider');
    }
  }

  Future<CategorizedSearchResults> searchAll(String query) async {
    _isCategorizedSearching = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _repository.searchAll(query);
      _categorizedResults = results;
      return results;
    } catch (e) {
      _error = e.toString();
      return const CategorizedSearchResults();
    } finally {
      _isCategorizedSearching = false;
      notifyListeners();
    }
  }

  void clearCategorizedResults() {
    _categorizedResults = null;
    notifyListeners();
  }

  Future<AlbumDetailResult> getAlbum(String playlistId) async {
    return _repository.getAlbum(playlistId);
  }

  Future<ArtistDetailResult> getArtist(String artistId) async {
    return _repository.getArtist(artistId);
  }
}
