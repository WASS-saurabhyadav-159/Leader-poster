import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../config/colors.dart';
import '../../../category/domain/category.dart';
import '../../../category/presentation/Allbannershowpage.dart';
import '../../../category/presentation/edit_banner_screen.dart';
import 'VideoEditorPage.dart';
import 'album_posters_page.dart';
import 'all_albums_page.dart';

class CategoryHighlightDisplay extends StatefulWidget {
  final Category category;

  const CategoryHighlightDisplay(this.category, {super.key});

  @override
  State<CategoryHighlightDisplay> createState() => _CategoryHighlightDisplayState();
}

class _CategoryHighlightDisplayState extends State<CategoryHighlightDisplay> {
  @override
  Widget build(BuildContext context) {
    bool hasAlbums = widget.category.posterGroups.isNotEmpty;
    bool hasDirectPosters = widget.category.posters.isNotEmpty;

    if (!hasAlbums && !hasDirectPosters) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.category.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToAllPosters(),
                child: Container(
                  decoration: BoxDecoration(
                    color: SharedColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasAlbums)
            _buildAlbumsList()
          else
            _buildDirectPostersList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.category.posterGroups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final album = widget.category.posterGroups[index];
          return _buildAlbumItem(album);
        },
      ),
    );
  }

  Widget _buildAlbumItem(PosterGroup album) {
    final firstPoster = album.posters.isNotEmpty ? album.posters.first : null;
    final albumDate = album.albumDate.isNotEmpty ? _formatAlbumDate(album.albumDate) : '';

    return GestureDetector(
      onTap: () => _handleAlbumTap(album),
      child: SizedBox(
        width: 112,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 112,
                      width: 112,
                      child: firstPoster != null
                          ? (firstPoster.isVideo
                              ? _buildVideoThumbnail(firstPoster)
                              : _buildImageThumbnail(firstPoster))
                          : _buildPlaceholder(),
                    ),
                  ),
                  if (albumDate.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomLeft: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          albumDate,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 112,
              height: 16,
              child: Center(
                child: album.albumName.length > 10
                    ? _buildScrollingText(album.albumName)
                    : Text(
                        album.albumName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollingText(String text) {
    return _MarqueeText(text: text);
  }

  Widget _buildDirectPostersList() {
    List<Poster> displayedImages = widget.category.posters.take(10).toList();

    return SizedBox(
      height: 114,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayedImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final poster = displayedImages[index];
          return _buildPosterItem(poster);
        },
      ),
    );
  }

  String _formatAlbumDate(String rawDate) {
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
        final parsed = DateTime.parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      }
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _handleAlbumTap(PosterGroup album) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlbumPostersPage(
          album: album,
          categoryId: widget.category.id,
          albumId: album.albumId,
        ),
      ),
    );
  }

  Future<void> _navigateToAllPosters() async {
    // If category has albums, show all albums page, otherwise show all posters
    if (widget.category.posterGroups.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AllAlbumsPage(category: widget.category)),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AllPosterPage(category: widget.category)),
      );
    }
  }

  Widget _buildPosterItem(Poster poster) {
    return GestureDetector(
      onTap: () => _handlePosterTap(poster),
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: SharedColors.categoryHighlightBorderColor),
                ),
                child: poster.isVideo
                    ? _buildVideoThumbnail(poster)
                    : _buildImageThumbnail(poster),
              ),
            ),
            if (poster.specialDay != null || poster.date != null)
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    _getDisplayDate(poster),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (poster.isVideo)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 40),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePosterTap(Poster poster) async {
    if (poster.isVideo) {
      // await Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (_) => VideoEditorPage(videoUrl: poster.posterUrl ?? "")),
      // );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SocialMediaDetailsPage(
            assetPath: poster.posterUrl ?? "",
            categoryId: widget.category.id,
            initialPosition: poster.position ?? "RIGHT",
            posterId: poster.id,
            topDefNum: poster.topDefNum,
            selfDefNum: poster.selfDefNum,
            bottomDefNum: poster.bottomDefNum,
          ),
        ),
      );
    }
  }

  String _getDisplayDate(Poster poster) {
    if (poster.specialDay != null) {
      try {
        final int day = int.tryParse(poster.specialDay!.day ?? '') ?? 1;
        final String monthName = poster.specialDay!.month ?? '';
        final int year = DateTime.now().year;
        final int month = DateFormat('MMMM').parse(monthName).month;
        final DateTime date = DateTime(year, month, day);
        return DateFormat("d MMM").format(date);
      } catch (e) {
        return "";
      }
    } else if (poster.date != null) {
      return _formatDate(poster.date!);
    }
    return "";
  }

  String _formatDate(String rawDate) {
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
        final parsed = DateTime.parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      }
      if (RegExp(r'^\d{1,2}\s+[A-Za-z]+$').hasMatch(rawDate.trim())) {
        final parts = rawDate.trim().split(' ');
        if (parts.length == 2) {
          return '${parts[0]} ${parts[1].substring(0, parts[1].length > 3 ? 3 : parts[1].length)}';
        }
      }
      try {
        final parsed = DateFormat("d MMMM yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      } catch (_) {}
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  Widget _buildVideoThumbnail(Poster poster) {
    final String? thumbUrl = poster.videoThumb;
    if (thumbUrl == null || thumbUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: thumbUrl,
      height: 112,
      width: 112,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(isError: true),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheHeight: 224,
      memCacheWidth: 224,
    );
  }

  Widget _buildImageThumbnail(Poster poster) {
    final String? imageUrl = poster.posterUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholder(isError: true);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 112,
      width: 112,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildPlaceholder(isError: true),
      fadeInDuration: const Duration(milliseconds: 200),
      memCacheHeight: 224,
      memCacheWidth: 224,
    );
  }

  Widget _buildPlaceholder({bool isError = false}) {
    return Container(
      height: 112,
      width: 112,
      color: Colors.grey.shade300,
      child: Center(
        child: isError
            ? const Icon(Icons.broken_image, color: Colors.red, size: 30)
            : const CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
      ),
    );
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;

  const _MarqueeText({required this.text});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.text.length ~/ 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _startScrolling();
      }
    });
  }

  void _startScrolling() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(seconds: widget.text.length ~/ 3),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              widget.text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 20),
            Text(
              widget.text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
