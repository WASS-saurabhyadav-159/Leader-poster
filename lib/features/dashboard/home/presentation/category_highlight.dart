import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../../config/colors.dart';
import '../../../category/domain/category.dart';
import '../../../category/presentation/Allbannershowpage.dart';
import '../../../category/presentation/edit_banner_screen.dart';
import 'VideoEditorPage.dart';

class CategoryHighlightDisplay extends StatefulWidget {
  final Category category;

  const CategoryHighlightDisplay(this.category, {super.key});

  @override
  State<CategoryHighlightDisplay> createState() => _CategoryHighlightDisplayState();
}

class _CategoryHighlightDisplayState extends State<CategoryHighlightDisplay> {
  @override
  Widget build(BuildContext context) {
    List<Poster> displayedImages = widget.category.posters.take(10).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Header with Date
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Display category date if available
                    if (widget.category.date != null || widget.category.createdAt != null)
                      _buildCategoryDate(),
                  ],
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
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
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Build category date display
  Widget _buildCategoryDate() {
    String? dateToDisplay;

    // Priority 1: Use category date
    if (widget.category.date != null) {
      dateToDisplay = _formatCategoryDate(widget.category.date!);
    }
    // Priority 2: Use createdAt date
    else if (widget.category.createdAt != null) {
      dateToDisplay = DateFormat("d MMM yyyy").format(widget.category.createdAt!);
    }

    if (dateToDisplay != null) {
      return Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 12,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            dateToDisplay,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // Format category date similar to TodaySpecialSection
  String _formatCategoryDate(String rawDate) {
    try {
      // Handle the specific case: "10 September" → "10 Sep"
      if (RegExp(r'^\d{1,2}\s+[A-Za-z]+$').hasMatch(rawDate.trim())) {
        final parts = rawDate.trim().split(' ');
        if (parts.length == 2) {
          final day = parts[0];
          final month = parts[1];

          // Convert full month name to abbreviated format (first 3 letters)
          String abbreviatedMonth = month.length > 3 ? month.substring(0, 3) : month;

          return '$day $abbreviatedMonth';
        }
      }

      // case 1: backend sends standard format `yyyy-MM-dd`
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
        final parsed = DateTime.parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      }

      // case 2: backend sends `10 September 2025`
      try {
        final parsed = DateFormat("d MMMM yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      } catch (_) {}

      // case 3: backend sends `September 10, 2025`
      try {
        final parsed = DateFormat("MMMM d, yyyy").parse(rawDate);
        return DateFormat("d MMM").format(parsed);
      } catch (_) {}

      // fallback (show as-is)
      return rawDate;
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _navigateToAllPosters() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllPosterPage(category: widget.category),
      ),
    );
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
                  border: Border.all(
                    color: SharedColors.categoryHighlightBorderColor,
                  ),
                ),
                child: poster.isVideo
                    ? _buildVideoThumbnail(poster)
                    : _buildImageThumbnail(poster),
              ),
            ),
            // Date badge for individual posters
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (poster.isVideo)
              const Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white70,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePosterTap(Poster poster) async {
    // Log all poster details before navigation
    print("══════════════════════════════════════════════════════════════");
    print("🎬 POSTER TAPPED - NAVIGATION STARTED");
    print("══════════════════════════════════════════════════════════════");
    print("📋 POSTER DETAILS:");
    print("   • ID: ${poster.id}");
    print("   • Poster URL: ${poster.posterUrl}");
    print("   • Is Video: ${poster.isVideo}");
    print("   • Position: ${poster.position}");
    print("   • TopDefNum: ${poster.topDefNum}");
    print("   • SelfDefNum: ${poster.selfDefNum}");
    print("   • BottomDefNum: ${poster.bottomDefNum}");
    print("   • Date: ${poster.date}");
    print("   • Video Thumbnail: ${poster.videoThumb}");

    if (poster.specialDay != null) {
      print("   • Special Day: ${poster.specialDay!.name}");
      print("   • Special Month: ${poster.specialDay!.month}");
      print("   • Special Day Number: ${poster.specialDay!.day}");
    } else {
      print("   • Special Day: null");
    }

    print("📋 CATEGORY DETAILS:");
    print("   • Category ID: ${widget.category.id}");
    print("   • Category Name: ${widget.category.name}");
    print("   • Category Date: ${widget.category.date}");
    print("   • Category Created At: ${widget.category.createdAt}");
    print("   • Total Posters in Category: ${widget.category.posters.length}");

    if (poster.isVideo) {
      print("🚀 NAVIGATING TO: VideoEditorPage");
      print("   • Video URL: ${poster.posterUrl ?? ""}");

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoEditorPage(
            videoUrl: poster.posterUrl ?? "",
            // Pass position information to VideoEditorPage
            // initialPosition: poster.position ?? "RIGHT",
            // topDefNum: poster.topDefNum ?? 0, // Provide default value if null
            // selfDefNum: poster.selfDefNum ?? 0, // Provide default value if null
            // bottomDefNum: poster.bottomDefNum ?? 0, // Provide default value if null
          ),
        ),
      );

      print("✅ RETURNED FROM: VideoEditorPage");
    } else {
      print("🚀 NAVIGATING TO: SocialMediaDetailsPage");
      print("📤 SENDING DATA:");
      print("   • Asset Path: ${poster.posterUrl ?? ""}");
      print("   • Category ID: ${widget.category.id}");
      print("   • Initial Position: ${poster.position ?? " "}");
      print("   • Poster ID: ${poster.id}");
      print("   • TopDefNum: ${poster.topDefNum}");
      print("   • SelfDefNum: ${poster.selfDefNum}");
      print("   • BottomDefNum: ${poster.bottomDefNum}");

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

      print("✅ RETURNED FROM: SocialMediaDetailsPage");
    }

    print("══════════════════════════════════════════════════════════════");
    print("🎬 NAVIGATION COMPLETED");
    print("══════════════════════════════════════════════════════════════");
  }

  String _getDisplayDate(Poster poster) {
    if (poster.specialDay != null) {
      try {
        // Assuming specialDay has: day (int), month (full name like "October"), and optional year (default to current)
        final int day = int.tryParse(poster.specialDay!.day ?? '') ?? 1;
        final String monthName = poster.specialDay!.month ?? '';
        final int year = DateTime.now().year;

        // Parse full month name to month number
        final int month = DateFormat('MMMM').parse(monthName).month;

        final DateTime date = DateTime(year, month, day);
        return DateFormat("d MMM").format(date); // Output like: 26 Oct
      } catch (e) {
        return "";
      }
    } else if (poster.date != null) {
      try {
        // Use the same formatting logic as category dates
        return _formatCategoryDate(poster.date!);
      } catch (e) {
        return poster.date!;
      }
    }
    return "";
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
      errorWidget: (context, url, error) {
        debugPrint("Error loading video thumbnail: $error");
        return _buildPlaceholder(isError: true);
      },
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
      errorWidget: (context, url, error) {
        debugPrint("Error loading image: $error");
        return _buildPlaceholder(isError: true);
      },
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
            : const CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.blue,
        ),
      ),
    );
  }
}