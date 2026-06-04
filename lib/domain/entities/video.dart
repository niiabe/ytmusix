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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'thumbnailUrl': thumbnailUrl,
        'durationSeconds': duration.inSeconds,
        'author': author,
        'index': index,
        'albumId': albumId,
        'artistId': artistId,
      };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        duration: Duration(seconds: (json['durationSeconds'] as num?)?.toInt() ?? 0),
        author: json['author'] as String?,
        index: (json['index'] as num?)?.toInt() ?? 0,
        albumId: json['albumId'] as String?,
        artistId: json['artistId'] as String?,
      );
}
