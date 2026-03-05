import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../category/domain/category.dart';
import '../../../../config/colors.dart';
import 'album_posters_page.dart';

class AllAlbumsPage extends StatelessWidget {
  final Category category;

  const AllAlbumsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          childAspectRatio: 0.75,
        ),
        itemCount: category.posterGroups.length,
        itemBuilder: (context, index) {
          final album = category.posterGroups[index];
          return _buildAlbumCard(context, album);
        },
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, PosterGroup album) {
    final firstPoster = album.posters.isNotEmpty ? album.posters.first : null;
    final albumDate = album.albumDate.isNotEmpty ? _formatAlbumDate(album.albumDate) : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AlbumPostersPage(
              album: album,
              categoryId: category.id,
              albumId: album.albumId,
            ),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: AspectRatio(
                aspectRatio: 0.85,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: firstPoster != null
                          ? Image.network(
                              firstPoster.posterUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.folder, size: 40, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.folder, size: 40, color: Colors.grey),
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
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Text(
                            albumDate,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: Center(
                child: album.albumName.length > 10
                    ? _MarqueeText(text: album.albumName)
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
}

class _MarqueeText extends StatefulWidget {
  final String text;

  const _MarqueeText({required this.text});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 20),
            Text(
              widget.text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
