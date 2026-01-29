import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../config/colors.dart';
import '../../../core/models/TodaySpecial.dart';
import '../../category/presentation/edit_banner_screen.dart';

class AllTodaySpecialPage extends StatelessWidget {
  final List<TodaySpecial> todaySpecialList;

  const AllTodaySpecialPage({
    super.key,
    required this.todaySpecialList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Special"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: todaySpecialList.isEmpty
          ? const Center(child: Text("No special items for today"))
          : GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 0.85,
        ),
        itemCount: todaySpecialList.length,
        itemBuilder: (context, index) {
          final item = todaySpecialList[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SocialMediaDetailsPage(
                    assetPath: item.poster,
                    categoryId: "",
                    initialPosition: item.position ?? "RIGHT",
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


                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageThumbnail(TodaySpecial item) {
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
}