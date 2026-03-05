class Album {
  final String id;
  final String name;
  final String date;
  final List<AlbumPoster> posters;

  Album({
    required this.id,
    required this.name,
    required this.date,
    required this.posters,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      posters: (json['poster'] as List<dynamic>? ?? [])
          .map((p) => AlbumPoster.fromJson(p))
          .toList(),
    );
  }
}

class AlbumPoster {
  final String id;
  final String poster;
  final String? videoThumb;
  final String date;

  AlbumPoster({
    required this.id,
    required this.poster,
    this.videoThumb,
    required this.date,
  });

  factory AlbumPoster.fromJson(Map<String, dynamic> json) {
    return AlbumPoster(
      id: json['id']?.toString() ?? '',
      poster: json['poster']?.toString() ?? '',
      videoThumb: json['videoThumb']?.toString(),
      date: json['date']?.toString() ?? '',
    );
  }
}
