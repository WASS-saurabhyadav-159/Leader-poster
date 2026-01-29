import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../config/colors.dart';
import '../../../core/models/video.dart';
import '../../dashboard/home/presentation/VideoEditorPage.dart';

class AllVideosPage extends StatefulWidget {
  final List<Video> videos;

  const AllVideosPage({
    super.key,
    required this.videos,
  });

  @override
  State<AllVideosPage> createState() => _AllVideosPageState();
}

class _AllVideosPageState extends State<AllVideosPage> {
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

  Future<void> _handleVideoTap(Video video) async {
    final finalVideoUrl = _extractDirectVideoUrl(video.iframeLink);
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

  /// Prefer API thumbnail, else try deriving (vz b-cdn or YouTube)
  String? _getThumbnailUrl(Video video) {
    if (video.thumbnail != null && video.thumbnail!.isNotEmpty) return video.thumbnail;

    final link = video.iframeLink;
    try {
      final uri = Uri.parse(link);
      final segments = uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
      if (segments.length >= 2) {
        final possibleLib = segments.length >= 2 ? segments[segments.length - 2] : null;
        final possibleVid = segments.isNotEmpty ? segments.last : null;
        if (possibleLib != null && possibleVid != null) {
          return 'https://vz-$possibleLib.b-cdn.net/$possibleVid/thumbnail.jpg?time=1';
        }
      }
    } catch (_) {}

    if (link.contains('youtube.com') || link.contains('youtu.be')) {
      try {
        if (link.contains('youtu.be/')) return 'https://img.youtube.com/vi/${link.split('youtu.be/')[1].split('?').first}/hqdefault.jpg';
        final id = Uri.parse(link).queryParameters['v'];
        if (id != null && id.isNotEmpty) return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
      } catch (_) {}
    }

    return null;
  }

  Widget _buildVideoThumbnail(Video video) {
    final thumb = _getThumbnailUrl(video);

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: thumb != null
              ? CachedNetworkImage(
            imageUrl: thumb,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.blue.shade50,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
            ),
            errorWidget: (context, url, err) => _thumbnailPlaceholder(),
          )
              : _thumbnailPlaceholder(),
        ),

        // dim overlay so the white play button is visible on all thumbs
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.black26,
          ),
        ),

        // Play icon
        const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white70,
            size: 50,
          ),
        ),
      ],
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.videocam,
          color: Colors.blue,
          size: 60,
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Videos"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: widget.videos.isEmpty
          ? const Center(
        child: Text(
          "No videos available",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 0.85,
        ),
        itemCount: widget.videos.length,
        itemBuilder: (context, index) {
          final video = widget.videos[index];

          return GestureDetector(
            onTap: () => _handleVideoTap(video),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildVideoThumbnail(video),
              ),
            ),
          );
        },
      ),
    );
  }
}
