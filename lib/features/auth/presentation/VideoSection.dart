import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:poster/features/auth/presentation/videoall.dart';
import '../../../../config/colors.dart';
import '../../../core/models/video.dart';
import '../../../core/network/api_service.dart';
import '../../dashboard/home/presentation/VideoEditorPage.dart';
import '../../dashboard/presentation/VideoPlayerPopup.dart' hide VideoEditorPage;

class VideoSection extends StatefulWidget {
  const VideoSection({super.key});

  @override
  State<VideoSection> createState() => _VideoSectionState();
}

class _VideoSectionState extends State<VideoSection> {
  final ApiService _apiService = ApiService();
  List<Video> _videos = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _limit = 10;
  int _offset = 0;
  bool _hasVideos = false; // Track if videos exist

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final videos = await _apiService.fetchVideos(
        limit: _limit,
        offset: _offset,
      );

      setState(() {
        _videos = videos;
        _isLoading = false;
        _hasVideos = videos.isNotEmpty; // Update based on actual data
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _hasVideos = false; // On error, don't show section
      });
      debugPrint("❌ Error loading videos: $e");
    }
  }

  void _navigateToAllVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllVideosPage(videos: _videos),
      ),
    );
  }

  Future<void> _handleVideoTap(Video video) async {
    debugPrint("🎬 VIDEO TAPPED — ${video.videoId}");

    // Extract direct video URL from embed URL
    String finalVideoUrl = _extractDirectVideoUrl(video.iframeLink);
    debugPrint("🎬 Direct Video URL => $finalVideoUrl");

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoEditorPage(
          videoUrl: finalVideoUrl,
          initialPosition: video.position,
          topDefNum: video.topDefNum ?? 0,
          selfDefNum: video.selfDefNum ?? 0,
          bottomDefNum: video.bottomDefNum ?? 0,
        ),
      ),
    );
  }

  String _extractDirectVideoUrl(String iframeUrl) {
    try {
      if (iframeUrl.isEmpty) return iframeUrl;

      // If it already contains b-cdn playlist or direct m3u8 -> return as-is
      if (iframeUrl.contains('.b-cdn.net') || iframeUrl.toLowerCase().endsWith('.m3u8')) {
        return iframeUrl;
      }

      // mediadelivery -> convert to vz-<library>.b-cdn.net/<video>/playlist.m3u8
      if (iframeUrl.contains('mediadelivery.net')) {
        final uri = Uri.parse(iframeUrl);
        final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
        if (segments.length >= 2) {
          final libraryId = segments[segments.length - 2];
          final videoId = segments.last;
          return 'https://vz-$libraryId.b-cdn.net/$videoId/playlist.m3u8';
        }
      }

      return iframeUrl;
    } catch (e) {
      debugPrint("⚠️ Error extracting direct video URL: $e");
      return iframeUrl;
    }
  }

  String? _getThumbnailUrl(Video video) {
    try {
      // 1) prefer API thumbnail if provided
      if (video.thumbnail != null && video.thumbnail!.isNotEmpty) {
        return video.thumbnail;
      }

      final link = video.iframeLink;

      // 2) bunny/vz derived thumbnail
      try {
        final uri = Uri.parse(link);
        final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
        if (segments.length >= 2) {
          final possibleLib = segments.length >= 2 ? segments[segments.length - 2] : null;
          final possibleVid = segments.isNotEmpty ? segments.last : null;
          if (possibleLib != null && possibleVid != null) {
            final url = 'https://vz-$possibleLib.b-cdn.net/$possibleVid/thumbnail.jpg?time=1';
            debugPrint("🎬 Derived Thumbnail URL => $url");
            return url;
          }
        }
      } catch (_) {
        // ignore parse errors here and continue to youtube fallback
      }

      // 3) YouTube support
      if (link.contains('youtube.com') || link.contains('youtu.be')) {
        final videoId = _extractYouTubeId(link);
        if (videoId != null) {
          final url = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
          debugPrint("🎬 YouTube Thumbnail => $url");
          return url;
        }
      }

      return null;
    } catch (e) {
      debugPrint("⚠️ Thumbnail generation failed: $e");
      return null;
    }
  }

  String? _extractYouTubeId(String url) {
    try {
      if (url.contains('youtu.be/')) {
        return url.split('youtu.be/')[1].split('?').first;
      } else if (url.contains('v=')) {
        return Uri.parse(url).queryParameters['v'];
      }
    } catch (_) {}
    return null;
  }

  Widget _buildVideoThumbnail(Video video) {
    final thumbnailUrl = _getThumbnailUrl(video);

    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: SharedColors.categoryHighlightBorderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                width: 112,
                height: 112,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
                errorWidget: (context, url, error) => _thumbnailPlaceholder(),
              )
            else
              _thumbnailPlaceholder(),

            // ▶ Play icon overlay
            const Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.black54,
                child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
              ),
            ),

            // 📅 Date label
            if (video.date != null)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(0),
                    ),
                  ),
                  child: Text(
                    _formatVideoDate(video.date!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: Colors.blue.shade50,
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.blue, size: 36),
      ),
    );
  }

  String _formatVideoDate(String rawDate) {
    try {
      if (RegExp(r'^\d{1,2}\s+[A-Za-z]+\s+\d{4}$').hasMatch(rawDate.trim())) {
        final parsed = DateFormat("d MMMM yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      }
      final parsed = DateTime.parse(rawDate);
      return DateFormat("d MMM").format(parsed);
    } catch (e) {
      return rawDate;
    }
  }

  Widget _buildVideoItem(Video video) {
    return GestureDetector(
      onTap: () => _handleVideoTap(video),
      child: Container(
        width: 112,
        height: 130,
        margin: const EdgeInsets.only(right: 6),
        child: Column(
          children: [_buildVideoThumbnail(video)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If loading, show shimmer
    if (_isLoading) return _buildLoadingState();

    // If error, don't show anything
    if (_hasError) return const SizedBox.shrink();

    // If no videos available, don't show anything (empty section)
    if (!_hasVideos || _videos.isEmpty) return const SizedBox.shrink();

    // Only show section when videos are available
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Videos",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: _navigateToAllVideos,
                child: Container(
                  decoration: BoxDecoration(
                    color: SharedColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: const Text(
                    "View All",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Video List
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final video = _videos[index];
                return _buildVideoItem(video);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    // Show shimmer while loading, but will hide if no videos found
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Videos",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (_, __) => Container(
                width: 112,
                height: 112,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}