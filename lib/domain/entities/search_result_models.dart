import '../../domain/entities/video.dart';

class CategorizedSearchResults {
  final List<Track> songs;
  final List<Track> videos;
  final List<AlbumResult> albums;
  final List<ArtistResult> artists;
  final List<PlaylistResult> playlists;

  const CategorizedSearchResults({
    this.songs = const [],
    this.videos = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });

  bool get isEmpty =>
      songs.isEmpty &&
      videos.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      playlists.isEmpty;

  Track? get single => songs.isNotEmpty ? songs.first : null;
}

class AlbumResult {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final int? year;
  final String? thumbnailUrl;

  const AlbumResult({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    this.year,
    this.thumbnailUrl,
  });
}

class ArtistResult {
  final String id;
  final String name;
  final String? thumbnailUrl;

  const ArtistResult({
    required this.id,
    required this.name,
    this.thumbnailUrl,
  });
}

class PlaylistResult {
  final String id;
  final String title;
  final String artist;
  final String? thumbnailUrl;

  const PlaylistResult({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
  });
}

class AlbumDetailResult {
  final String id;
  final String title;
  final String artist;
  final String? artistId;
  final int? year;
  final String? thumbnailUrl;
  final List<Track> tracks;

  const AlbumDetailResult({
    required this.id,
    required this.title,
    required this.artist,
    this.artistId,
    this.year,
    this.thumbnailUrl,
    this.tracks = const [],
  });
}

class ArtistDetailResult {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final List<Track> topSongs;
  final List<AlbumResult> albums;
  final List<AlbumResult> singles;

  const ArtistDetailResult({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.topSongs = const [],
    this.albums = const [],
    this.singles = const [],
  });
}
