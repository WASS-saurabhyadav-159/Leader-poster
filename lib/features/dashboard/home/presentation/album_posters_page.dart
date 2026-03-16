import 'package:flutter/material.dart';
import '../../../../core/models/language.dart';
import '../../../../core/network/api_service.dart';
import '../../../category/domain/category.dart';
import '../../../category/presentation/edit_banner_screen.dart';
import 'VideoEditorPage.dart';

class AlbumPostersPage extends StatefulWidget {
  final PosterGroup album;
  final String categoryId;
  final String albumId;

  const AlbumPostersPage({
    super.key,
    required this.album,
    required this.categoryId,
    required this.albumId,
  });

  @override
  State<AlbumPostersPage> createState() => _AlbumPostersPageState();
}

class _AlbumPostersPageState extends State<AlbumPostersPage> {
  final ApiService _apiService = ApiService();
  String? selectedLanguageId;
  List<Language> availableLanguages = [];
  List<Poster> posters = [];
  bool isLoadingLanguages = true;
  bool isLoadingPosters = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableLanguages();
  }

  Future<void> _loadAvailableLanguages() async {
    try {
      final response = await _apiService.fetchPostersByAlbum(
        albumId: widget.albumId,
        languageId: null,
      );
      
      final Set<String> languageIds = {};
      for (var json in response) {
        if (json['languageId'] != null) {
          languageIds.add(json['languageId'].toString());
        }
      }

      final allLanguages = await _apiService.fetchLanguages(limit: 100, offset: 0);
      final languages = allLanguages.map((json) => Language.fromJson(json)).toList();
      
      setState(() {
        availableLanguages = languages.where((lang) => languageIds.contains(lang.id)).toList();
        if (availableLanguages.isNotEmpty) {
          selectedLanguageId = availableLanguages[0].id;
        }
        isLoadingLanguages = false;
      });
      
      _loadPosters();
    } catch (e) {
      setState(() {
        isLoadingLanguages = false;
      });
    }
  }

  Future<void> _loadPosters() async {
    setState(() => isLoadingPosters = true);
    try {
      final response = await _apiService.fetchPostersByAlbum(
        albumId: widget.albumId,
        languageId: selectedLanguageId,
      );
      setState(() {
        posters = response.map((json) => _parsePoster(json)).toList();
        isLoadingPosters = false;
      });
    } catch (e) {
      setState(() {
        posters = widget.album.posters;
        isLoadingPosters = false;
      });
    }
  }

  Poster _parsePoster(Map<String, dynamic> data) {
    bool isVideo = (data["poster"]?.toString().toLowerCase().endsWith('.mp4') ?? false) ||
        (data["poster"]?.toString().toLowerCase().endsWith('.mov') ?? false);

    return Poster(
      id: data["id"]?.toString() ?? "",
      posterUrl: data["poster"]?.toString() ?? "",
      isVideo: isVideo,
      videoThumb: data["videoThumb"]?.toString(),
      date: data["date"]?.toString(),
      position: data["position"]?.toString(),
      topDefNum: data["topDefNum"] as int?,
      selfDefNum: data["selfDefNum"] as int?,
      bottomDefNum: data["bottomDefNum"] as int?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.album.albumName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [

          if (availableLanguages.isNotEmpty) _buildLanguageList(),

          /// 🔵 POSTER GRID
          Expanded(
            child: isLoadingPosters
                ? const Center(child: CircularProgressIndicator())
                : posters.isEmpty
                    ? const Center(child: Text("No posters available"))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6.0,
                          mainAxisSpacing: 6.0,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: posters.length,
                        itemBuilder: (context, index) {
                          final poster = posters[index];
                          return GestureDetector(
                            onTap: () => _handlePosterTap(context, poster),
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
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// ==============================
  /// 🔹 LANGUAGE LIST
  /// ==============================
  Widget _buildLanguageList() {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: availableLanguages.length,
        itemBuilder: (context, index) {
          final lang = availableLanguages[index];
          final isSelected = selectedLanguageId == lang.id;

          return GestureDetector(
            onTap: () {
              setState(() => selectedLanguageId = lang.id);
              _loadPosters();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.red : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.red : Colors.grey.shade400,
                  width: 1.2,
                ),
              ),
              child: Center(
                child: Text(
                  lang.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ==============================
  /// 🔹 HANDLE TAP
  /// ==============================
  void _handlePosterTap(BuildContext context, Poster poster) {
    if (poster.isVideo) {
      // Navigator.push(
      //   context,
      //   // MaterialPageRoute(
      //   //   builder: (_) => VideoEditorPage(videoUrl: poster.posterUrl),
      //   // ),
      // );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SocialMediaDetailsPage(
            assetPath: poster.posterUrl,
            categoryId: widget.categoryId,
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

  /// ==============================
  /// 🔹 VIDEO THUMB
  /// ==============================
  Widget _buildVideoThumbnail(Poster poster) {
    return Container(
      color: Colors.grey[300],
      child: poster.videoThumb != null
          ? Image.network(
        poster.videoThumb!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.play_circle_fill,
              color: Colors.white, size: 40),
        ),
      )
          : const Center(
        child:
        Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
      ),
    );
  }

  /// ==============================
  /// 🔹 IMAGE THUMB
  /// ==============================
  Widget _buildImageThumbnail(Poster poster) {
    return Image.network(
      poster.posterUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}