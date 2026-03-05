class Category {
  final String id;
  final String name;
  final List<Poster> posters;
  final List<PosterGroup> posterGroups;
  final String? date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.posters,
    required this.posterGroups,
    this.date,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      posters: (json['posters'] as List<dynamic>? ?? [])
          .map((posterJson) => Poster.fromJson(posterJson))
          .toList(),
      posterGroups: (json['posterGroups'] as List<dynamic>? ?? [])
          .map((groupJson) => PosterGroup.fromJson(groupJson))
          .toList(),
      date: json['date']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'posters': posters.map((poster) => poster.toJson()).toList(),
      'posterGroups': posterGroups.map((group) => group.toJson()).toList(),
      'date': date,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class PosterGroup {
  final String albumId;
  final String albumName;
  final String albumDate;
  final List<Poster> posters;

  PosterGroup({
    required this.albumId,
    required this.albumName,
    required this.albumDate,
    required this.posters,
  });

  factory PosterGroup.fromJson(Map<String, dynamic> json) {
    return PosterGroup(
      albumId: json['albumId']?.toString() ?? '',
      albumName: json['albumName']?.toString() ?? '',
      albumDate: json['albumDate']?.toString() ?? '',
      posters: (json['posters'] as List<dynamic>? ?? [])
          .map((posterJson) => Poster.fromJson(posterJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'albumId': albumId,
      'albumName': albumName,
      'albumDate': albumDate,
      'posters': posters.map((poster) => poster.toJson()).toList(),
    };
  }
}

class Poster {
  final String id;
  final String posterUrl;
  final SpecialDay? specialDay;
  final String? videoThumb;
  final bool isVideo;
  final String? date;
  final String? position;
  final int? topDefNum;
  final int? selfDefNum;
  final int? bottomDefNum;

  Poster({
    required this.id,
    required this.posterUrl,
    this.specialDay,
    this.videoThumb,
    required this.isVideo,
    this.date,
    this.position,
    this.topDefNum,
    this.selfDefNum,
    this.bottomDefNum,
  });

  factory Poster.fromJson(Map<String, dynamic> json) {
    return Poster(
      id: json['id']?.toString() ?? '',
      posterUrl: json['poster_url']?.toString() ?? json['poster']?.toString() ?? '',
      specialDay: json['special_day'] != null
          ? SpecialDay.fromJson(json['special_day'])
          : null,
      videoThumb: json['video_thumb']?.toString() ?? json['videoThumb']?.toString(),
      isVideo: json['is_video'] == true || (json['type']?.toString() == 'video') || json['videoThumb'] != null,
      date: json['date']?.toString(),
      position: json['position']?.toString(),
      topDefNum: _parseInt(json['top_def_num'] ?? json['topDefNum']),
      selfDefNum: _parseInt(json['self_def_num'] ?? json['selfDefNum']),
      bottomDefNum: _parseInt(json['bottom_def_num'] ?? json['bottomDefNum']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Optional: Add toJson method if needed for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poster_url': posterUrl,
      'special_day': specialDay?.toJson(),
      'video_thumb': videoThumb,
      'is_video': isVideo,
      'date': date,
      'position': position,
      'top_def_num': topDefNum,
      'self_def_num': selfDefNum,
      'bottom_def_num': bottomDefNum,
    };
  }
}

class SpecialDay {
  final String name;
  final String month;
  final String day;

  SpecialDay({required this.name, required this.month, required this.day});

  factory SpecialDay.fromJson(Map<String, dynamic> json) {
    return SpecialDay(
      name: json['name']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
    );
  }

  // Optional: Add toJson method if needed for API calls
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'month': month,
      'day': day,
    };
  }
}