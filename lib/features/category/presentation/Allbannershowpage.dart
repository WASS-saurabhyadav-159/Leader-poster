import 'package:flutter/material.dart';
import '../../dashboard/home/presentation/VideoEditorPage.dart';
import '../domain/category.dart';
import 'edit_banner_screen.dart';
import '../../../config/colors.dart';

class AllPosterPage extends StatelessWidget {
  final Category category;
  final bool isVideoCollection;

  const AllPosterPage({
    super.key,
    required this.category,
    this.isVideoCollection = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${category.name} ${isVideoCollection ? "Videos" : "Posters"}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 0.85,
        ),
        itemCount: category.posters.length,
        itemBuilder: (context, index) {
          final poster = category.posters[index];

          return GestureDetector(
            onTap: () {
              if (poster.isVideo) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoEditorPage(videoUrl: poster.posterUrl),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SocialMediaDetailsPage(
                      assetPath: poster.posterUrl,
                      categoryId: category.id,
                      initialPosition: poster.position ?? "RIGHT", // default to RIGHT if null
                      posterId: poster.id,
                      topDefNum: poster.topDefNum,
                      selfDefNum: poster.selfDefNum,
                      bottomDefNum: poster.bottomDefNum,
                    ),
                  ),
                );
              }
            },
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: poster.isVideo
                        ? _buildVideoThumbnail(poster)
                        : _buildImageThumbnail(poster),
                  ),
                  if (poster.isVideo)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  // if (poster.specialDay != null)
                  //   Positioned(
                  //     bottom: 0,
                  //     left: 0,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 6,
                  //         vertical: 2,
                  //       ),
                  //       decoration: const BoxDecoration(
                  //         color: Colors.red,
                  //         borderRadius: BorderRadius.only(
                  //           topRight: Radius.circular(6),
                  //           bottomLeft: Radius.circular(6),
                  //         ),
                  //       ),
                  //       child: Text(
                  //         "${poster.specialDay!.month.substring(0, 3)} ${poster.specialDay!.day}",
                  //         style: const TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 10,
                  //           fontWeight: FontWeight.bold,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoThumbnail(Poster poster) {
    return Container(
      color: Colors.grey[300],
      child: Stack(
        children: [
          // Show video thumbnail if available
          if (poster.videoThumb != null)
            Image.network(
              poster.videoThumb!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildVideoPlaceholder();
              },
            )
          else
            _buildVideoPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return const Center(
      child: Icon(
        Icons.play_circle_fill,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildImageThumbnail(Poster poster) {
    return Image.network(
      poster.posterUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}