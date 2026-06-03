enum ChartItemKind { song, album }

class ChartItem {
  final String id;
  final String title;
  final String artist;
  final String? artworkUrl;
  final String sourceName;
  final String sourceUrl;
  final int rank;
  final ChartItemKind kind;

  const ChartItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.sourceName,
    required this.sourceUrl,
    required this.rank,
    required this.kind,
    this.artworkUrl,
  });

  String get searchQuery {
    final type = kind == ChartItemKind.album ? 'album' : 'official audio';
    return '$title $artist $type';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'rank': rank,
      'kind': kind.name,
    };
  }

  factory ChartItem.fromJson(Map<String, dynamic> json) {
    return ChartItem(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      artworkUrl: json['artworkUrl'] as String?,
      sourceName: json['sourceName'] as String,
      sourceUrl: json['sourceUrl'] as String,
      rank: json['rank'] as int,
      kind: ChartItemKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => ChartItemKind.song,
      ),
    );
  }
}
