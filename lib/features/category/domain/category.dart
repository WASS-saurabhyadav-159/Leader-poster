class Category {
  final String id;
  final String name;
  final List<Poster> posters;
  final String? date; // Added date field
  final DateTime? createdAt; // Added createdAt field
  final DateTime? updatedAt; // Added updatedAt field

  Category({
    required this.id,
    required this.name,
    required this.posters,
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
      date: json['date']?.toString(), // Parse date from API
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Optional: Add toJson method if needed for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'posters': posters.map((poster) => poster.toJson()).toList(),
      'date': date,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
      videoThumb: json['video_thumb']?.toString(),
      isVideo: json['is_video'] == true || (json['type']?.toString() == 'video'),
      date: json['date']?.toString(),
      position: json['position']?.toString(),
      topDefNum: _parseInt(json['top_def_num']),
      selfDefNum: _parseInt(json['self_def_num']),
      bottomDefNum: _parseInt(json['bottom_def_num']),
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