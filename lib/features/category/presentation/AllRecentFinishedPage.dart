// features/category/presentation/AllRecentFinishedPage.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../config/colors.dart';
import '../../auth/data/RecentFinishedPoster.dart';
import 'edit_banner_screen.dart';

class AllRecentFinishedPage extends StatelessWidget {
  final List<RecentFinishedPoster> recentFinishedList;

  const AllRecentFinishedPage({
    super.key,
    required this.recentFinishedList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Finished"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: recentFinishedList.isEmpty
          ? const Center(child: Text("No recent finished posters"))
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 0.85,
        ),
        itemCount: recentFinishedList.length,
        itemBuilder: (context, index) {
          final item = recentFinishedList[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SocialMediaDetailsPage(
                    assetPath: item.poster,
                    categoryId: item.categoryId,
                    initialPosition: item.position,
                    posterId: item.id,
                    topDefNum: item.topDefNum,
                    selfDefNum: item.selfDefNum,
                    bottomDefNum: item.bottomDefNum,
                  ),
                ),
              );
            },
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  // Image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageThumbnail(item),
                  ),
                  // Date label inside poster at bottom-left
                  // Positioned(
                  //   bottom: 0,
                  //   left: 0,
                  //   child: Container(
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 6,
                  //       vertical: 4,
                  //     ),
                  //     decoration: const BoxDecoration(
                  //       color: Colors.blue,
                  //       borderRadius: BorderRadius.only(
                  //         topRight: Radius.circular(6),
                  //         bottomLeft: Radius.circular(6),
                  //       ),
                  //     ),
                  //     // child: Text(
                  //     //   _formatDate(item.date),
                  //     //   style: const TextStyle(
                  //     //     color: Colors.white,
                  //     //     fontWeight: FontWeight.bold,
                  //     //     fontSize: 10,
                  //     //   ),
                  //     // ),
                  //   ),
                  // ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageThumbnail(RecentFinishedPoster item) {
    return CachedNetworkImage(
      imageUrl: item.poster,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey.shade300,
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.error),
      ),
    );
  }

  /// Format date similar to RecentFinishedSection
  // String _formatDate(String rawDate) {
  //   try {
  //     if (RegExp(r'^\d{1,2}\s+[A-Za-z]+$').hasMatch(rawDate.trim())) {
  //       final parts = rawDate.trim().split(' ');
  //       if (parts.length == 2) {
  //         final day = parts[0];
  //         final month = parts[1];
  //         String abbreviatedMonth = month.length > 3 ? month.substring(0, 3) : month;
  //         return '$day $abbreviatedMonth';
  //       }
  //     }
  //
  //     if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
  //       final parsed = DateTime.parse(rawDate);
  //       return DateFormat("d MMM").format(parsed);
  //     }
  //
  //     try {
  //       final parsed = DateFormat("d MMMM yyyy").parse(rawDate);
  //       return DateFormat("d MMM").format(parsed);
  //     } catch (_) {}
  //
  //     try {
  //       final parsed = DateFormat("MMMM d, yyyy").parse(rawDate);
  //       return DateFormat("d MMM").format(parsed);
  //     } catch (_) {}
  //
  //     return rawDate;
  //   } catch (e) {
  //     return rawDate;
  //   }
  // }
}