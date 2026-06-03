class Track {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final Duration duration;
  final String? author;
  final int index;
  final String? albumId;
  final String? artistId;

  const Track({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.duration = Duration.zero,
    this.author,
    this.index = 0,
    this.albumId,
    this.artistId,
  });
}
