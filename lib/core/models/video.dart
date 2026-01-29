class Video {
  final String id;
  final String masterAppId;
  final String videoId;
  final String libraryId;
  final String iframeLink; // appLink / embed URL
  final String position;
  final String? date;
  final int downloadCount;
  final String status;
  final int? topDefNum;
  final int? selfDefNum;
  final int? bottomDefNum;
  final DateTime createdAt;

  // NEW: thumbnail URL returned by API
  final String? thumbnail;

  Video({
    required this.id,
    required this.masterAppId,
    required this.videoId,
    required this.libraryId,
    required this.iframeLink,
    required this.position,
    this.date,
    required this.downloadCount,
    required this.status,
    this.topDefNum,
    this.selfDefNum,
    this.bottomDefNum,
    required this.createdAt,
    this.thumbnail,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['videoId'] ?? '').toString();
    final masterAppId = (json['masterAppId'] ?? json['master_app_id'] ?? '').toString();
    final videoId = (json['video_id'] ?? json['videoId'] ?? '').toString();
    final libraryId = (json['app_library_id'] ?? json['appLibraryId'] ?? json['library_id'] ?? json['libraryId'] ?? '').toString();
    final iframeLink = (json['appLink'] ?? json['app_link'] ?? json['iframeLink'] ?? json['embed'] ?? '').toString();
    final position = (json['position'] ?? 'RIGHT').toString();
    final date = json['date']?.toString();
    final downloadCount = (json['downloadCount'] ?? json['download_count'] ?? 0) is int
        ? (json['downloadCount'] ?? json['download_count'] ?? 0) as int
        : int.tryParse((json['downloadCount'] ?? json['download_count'] ?? '0').toString()) ?? 0;
    final status = (json['status'] ?? 'ACTIVE').toString();

    final topDefNum = json['topDefNum'] is int ? json['topDefNum'] as int : (json['topDefNum'] == null ? null : int.tryParse(json['topDefNum'].toString()));
    final selfDefNum = json['selfDefNum'] is int ? json['selfDefNum'] as int : (json['selfDefNum'] == null ? null : int.tryParse(json['selfDefNum'].toString()));
    final bottomDefNum = json['bottomDefNum'] is int ? json['bottomDefNum'] as int : (json['bottomDefNum'] == null ? null : int.tryParse(json['bottomDefNum'].toString()));

    DateTime createdAt;
    try {
      final createdRaw = json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String();
      createdAt = DateTime.parse(createdRaw.toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    // NEW: thumbnail may come as 'thumbnail' in API
    final thumbnail = (json['thumbnail'] ?? json['thumbnailUrl'] ?? json['thumb'] ?? '').toString().trim();
    final thumbnailValue = thumbnail.isEmpty ? null : thumbnail;

    return Video(
      id: id,
      masterAppId: masterAppId,
      videoId: videoId,
      libraryId: libraryId,
      iframeLink: iframeLink,
      position: position,
      date: date,
      downloadCount: downloadCount,
      status: status,
      topDefNum: topDefNum,
      selfDefNum: selfDefNum,
      bottomDefNum: bottomDefNum,
      createdAt: createdAt,
      thumbnail: thumbnailValue,
    );
  }

  // Direct URL helper (keeps existing logic)
  String get videoUrl {
    try {
      final link = iframeLink;
      if (link.isEmpty) return link;
      if (link.toLowerCase().endsWith('.mp4') ||
          link.toLowerCase().endsWith('.m3u8') ||
          link.toLowerCase().endsWith('.mov') ||
          link.toLowerCase().endsWith('.avi') ||
          link.toLowerCase().endsWith('.mkv')) {
        return link;
      }
      if (link.contains('mediadelivery.net')) {
        try {
          final uri = Uri.parse(link);
          final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
          if (segments.length >= 2) {
            final libraryId = segments.length >= 2 ? segments[segments.length - 2] : segments.first;
            final videoId = segments.last;
            return 'https://vz-$libraryId.b-cdn.net/$videoId/playlist.m3u8';
          }
        } catch (_) {}
      }
      return link;
    } catch (e) {
      return iframeLink;
    }
  }

  bool get isDirectVideoUrl {
    final link = iframeLink.toLowerCase();
    return link.endsWith('.mp4') ||
        link.endsWith('.mov') ||
        link.endsWith('.avi') ||
        link.endsWith('.mkv') ||
        link.endsWith('.m3u8');
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
