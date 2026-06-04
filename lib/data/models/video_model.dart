import '../../domain/entities/video.dart';

class TrackModel {
  final String id;
  final String title;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? author;
  final int index;
  final String? albumId;
  final String? artistId;

  TrackModel({
    required this.id,
    required this.title,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.author,
    this.index = 0,
    this.albumId,
    this.artistId,
  });

  factory TrackModel.fromMap(Map<String, dynamic> map) {
    return TrackModel(
      id: map['id'] as String,
      title: map['title'] as String,
      thumbnailUrl: map['thumbnailUrl'] as String?,
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      author: map['author'] as String?,
      index: map['idx'] as int? ?? 0,
      albumId: map['albumId'] as String?,
      artistId: map['artistId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'durationSeconds': durationSeconds,
      'author': author,
      'idx': index,
      'albumId': albumId,
      'artistId': artistId,
    };
  }

  Track toEntity() {
    return Track(
      id: id,
      title: title,
      thumbnailUrl: thumbnailUrl,
      duration: Duration(seconds: durationSeconds),
      author: author,
      index: index,
      albumId: albumId,
      artistId: artistId,
    );
  }
}
