import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../config/colors.dart';
import '../../../../constants/app_colors.dart';
import '../../../../core/models/FooterImage.dart';
import '../../../../core/models/ProtocolImage.dart';
import '../../../../core/models/SelfImage.dart';
import '../../../../core/network/ImageCacheHelper.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/background_removal_service.dart';
import '../../../../widgets/image_crop_dialog.dart';

class VideoEditorPage extends StatefulWidget {
  final String videoUrl;
  final String? pageTitle;
  final String initialPosition;
  final int topDefNum;
  final int selfDefNum;
  final int bottomDefNum;

  const VideoEditorPage({
    required this.videoUrl,
    this.pageTitle = "Video Editor",
    super.key,
    this.initialPosition = "RIGHT",
    this.topDefNum = 0,
    this.selfDefNum = 0,
    this.bottomDefNum = 0,
  });

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  late VideoPlayerController _controller;
  late VideoPlayerController _generatedVideoController;
  bool _isPlaying = false;
  bool _isProcessing = false;
  bool _isDownloading = false;
  double _progressValue = 0.0;
  late Duration _videoDuration;
  File? _generatedVideoFile;
  File? _selectedImage;
  File? _topBannerImage;

  // Video dimensions
  int _videoWidth = 1920;
  int _videoHeight = 1080;
  double _videoAspectRatio = 16 / 9;

  // Protocol Images
  List<ProtocolImage> _protocolImages = [];
  String? _selectedProtocolImageUrl;
  Map<String, File> _protocolImageCache = {};
  Map<String, bool> _protocolImageLoading = {};

  // Self Images
  List<SelfImage> _apiSelfImages = [];
  String? _selectedFooterImageUrl;
  List<FooterImage> _footerImages = [];
  File? _selectedFooterImageFile;
  Map<String, File> _selfImageCache = {};
  Map<String, File> _footerImageCache = {};
  Map<String, bool> _selfImageLoading = {};
  Map<String, bool> _footerImageLoading = {};

  // Loading states
  bool _isLoadingProtocolImages = true;
  bool _isLoadingSelfImages = true;
  bool _isLoadingFooterImages = true;

  // Bottom image position
  String? _selectedPosition = 'right';
  int _positionVersion = 0;

  @override
  void initState() {
    super.initState();
    print('VideoEditorPage - Video URL from previous page: ${widget.videoUrl}');
    print('VideoEditorPage - Initial position: ${widget.initialPosition}');
    print('VideoEditorPage - topDefNum: ${widget.topDefNum}, selfDefNum: ${widget.selfDefNum}, bottomDefNum: ${widget.bottomDefNum}');

    _selectedPosition = widget.initialPosition.toLowerCase().trim();
    _initializeVideoPlayer();
    FFmpegKitConfig.init();

    // 🔥 Start pre-caching immediately
    _preloadCriticalImages();
  }

  Future<void> _preloadCriticalImages() async {
    // Pre-load common/default images while APIs are fetching
    final defaultImages = [
      'assets/protocalimage.png',
      'assets/background.png',
      'assets/leaderimage.png',
    ];
    await ImageCacheHelper.warmUpCache(defaultImages);

    // Then load all API images
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    // Start loading protocol images first (most important)
    unawaited(_loadProtocolImages());

    // Then load footer images
    unawaited(_loadFooterImages());

    // Finally load self images
    unawaited(_loadApiSelfImages());
  }

  Future<void> _loadProtocolImages() async {
    try {
      setState(() => _isLoadingProtocolImages = true);

      final images = await ApiService().fetchProtocolImages();

      if (images.isEmpty) {
        setState(() {
          _selectedProtocolImageUrl = null;
          _isLoadingProtocolImages = false;
        });
        return;
      }

      // 🔥 Pre-load all protocol images instantly
      final urls = images.map((img) => img.imageUrl).toList();
      await ImageCacheHelper.preCacheMultipleImages(urls, batchSize: 4);

      // Get all cached files instantly
      final cachedFiles = <String, File>{};
      for (var image in images) {
        final cachedFile = ImageCacheHelper.getPrecachedImage(image.imageUrl);
        if (cachedFile != null) {
          cachedFiles[image.imageUrl] = cachedFile;
        }
      }

      // Set selection and update state
      String? selectedUrl = _getSelectedProtocolUrl(images);

      setState(() {
        _protocolImages = images;
        _protocolImageCache = cachedFiles;
        _selectedProtocolImageUrl = selectedUrl;
        _isLoadingProtocolImages = false;

        // Mark all as loaded
        for (var image in images) {
          _protocolImageLoading[image.imageUrl] = false;
        }
      });

    } catch (e) {
      print('Error loading protocol images: $e');
      setState(() {
        _selectedProtocolImageUrl = null;
        _isLoadingProtocolImages = false;
      });
    }
  }

  String? _getSelectedProtocolUrl(List<ProtocolImage> images) {
    if (widget.topDefNum > 0) {
      try {
        return images.firstWhere((image) => image.defNum == widget.topDefNum).imageUrl;
      } catch (e) {
        return images[0].imageUrl;
      }
    }
    return images[0].imageUrl;
  }

  Future<void> _loadApiSelfImages() async {
    try {
      setState(() {
        _isLoadingSelfImages = true;
      });

      final images = await ApiService().fetchSelfImages();

      List<SelfImage> filteredImages = [];
      if (widget.initialPosition.isNotEmpty) {
        final position = widget.initialPosition.toLowerCase().trim();
        if (position == 'right' || position == 'left') {
          filteredImages = images.where((image) =>
          image.position.toLowerCase().trim() == position).toList();
        } else {
          filteredImages = [];
        }
      } else {
        filteredImages = images;
      }

      if (filteredImages.isEmpty) {
        setState(() {
          _selectedImage = null;
          _isLoadingSelfImages = false;
        });
        return;
      }

      // 🔥 INSTANT LOADING: Pre-load ALL filtered images in parallel
      final urls = filteredImages.map((img) => img.imageUrl).toList();
      await ImageCacheHelper.preCacheMultipleImages(urls, batchSize: 6); // Increased batch size

      // 🔥 Get ALL cached files instantly from memory
      final cachedFiles = <String, File>{};
      for (var image in filteredImages) {
        final cachedFile = ImageCacheHelper.getPrecachedImage(image.imageUrl);
        if (cachedFile != null) {
          cachedFiles[image.imageUrl] = cachedFile;
          print('✅ Self image cached instantly: ${image.imageUrl}');
        } else {
          print('❌ Self image NOT cached: ${image.imageUrl}');
        }
      }

      // 🔥 Determine selected image from cache
      File? selectedFile;
      if (widget.selfDefNum > 0) {
        try {
          final matchingImage = filteredImages.firstWhere(
                (image) => image.defNum == widget.selfDefNum,
          );
          selectedFile = cachedFiles[matchingImage.imageUrl];
          print('🎯 Selected self image by defNum: ${widget.selfDefNum}');
        } catch (e) {
          selectedFile = cachedFiles[filteredImages[0].imageUrl];
          print('⚠️ Using first self image (defNum not found)');
        }
      } else {
        selectedFile = cachedFiles[filteredImages[0].imageUrl];
        print('🎯 Using first self image (no defNum specified)');
      }

      setState(() {
        _apiSelfImages = images;
        _selfImageCache = cachedFiles;
        _selectedImage = selectedFile;
        _isLoadingSelfImages = false;

        // 🔥 Mark ALL as loaded instantly
        for (var image in filteredImages) {
          _selfImageLoading[image.imageUrl] = false;
        }

        print('🚀 Self images loaded instantly: ${cachedFiles.length}/${filteredImages.length} images');
      });

    } catch (e) {
      print('❌ Error loading self images: $e');
      setState(() {
        _selectedImage = null;
        _isLoadingSelfImages = false;
      });
    }
  }

  Future<void> _loadFooterImages() async {
    try {
      setState(() {
        _isLoadingFooterImages = true;
      });

      final images = await ApiService().fetchFooterImages();

      if (images.isEmpty) {
        setState(() {
          _selectedFooterImageUrl = null;
          _selectedFooterImageFile = null;
          _isLoadingFooterImages = false;
        });
        return;
      }

      // 🔥 Pre-load footer images
      final urls = images.map((img) => img.imageUrl).toList();
      await ImageCacheHelper.preCacheMultipleImages(urls);

      // Get cached files
      final cachedFiles = <String, File>{};
      for (var image in images) {
        final cachedFile = ImageCacheHelper.getPrecachedImage(image.imageUrl);
        if (cachedFile != null) {
          cachedFiles[image.imageUrl] = cachedFile;
        }
      }

      // Determine selected footer image
      String? selectedUrl;
      if (widget.bottomDefNum > 0) {
        try {
          final matchingImage = images.firstWhere(
                (image) => image.defNum == widget.bottomDefNum,
          );
          selectedUrl = matchingImage.imageUrl;
        } catch (e) {
          selectedUrl = images[0].imageUrl;
        }
      } else {
        selectedUrl = images[0].imageUrl;
      }

      setState(() {
        _footerImages = images;
        _footerImageCache = cachedFiles;
        _selectedFooterImageUrl = selectedUrl;
        _selectedFooterImageFile = null;
        _isLoadingFooterImages = false;

        // Mark all as loaded
        for (var image in images) {
          _footerImageLoading[image.imageUrl] = false;
        }
      });

    } catch (e) {
      print('Error loading footer images: $e');
      setState(() {
        _selectedFooterImageUrl = null;
        _selectedFooterImageFile = null;
        _isLoadingFooterImages = false;
      });
    }
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        if (_controller.value.isInitialized) {
          setState(() {
            _videoDuration = _controller.value.duration;
            _videoWidth = _controller.value.size.width.toInt();
            _videoHeight = _controller.value.size.height.toInt();
            _videoAspectRatio = _controller.value.aspectRatio;

            print('Video dimensions: ${_videoWidth}x$_videoHeight');
            print('Video aspect ratio: $_videoAspectRatio');

            _controller.play();
            _isPlaying = true;
          });
        }
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _togglePlayback() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  double _calculateVideoContainerHeight() {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    if (_controller.value.isInitialized) {
      return screenWidth / _videoAspectRatio;
    }
    return 400;
  }

  double _calculateProtocolHeight() {
    return _calculateVideoContainerHeight() * 0.25;
  }

  double _calculateFooterHeight() {
    return _calculateVideoContainerHeight() * 0.10;
  }

  double _calculateSelfImageHeight() {
    return _calculateVideoContainerHeight() * 0.40;
  }

  double _calculateSelfImageWidth() {
    return _calculateSelfImageHeight() * 0.85;
  }

  Widget _buildVideoPlayer() {
    if (!_controller.value.isInitialized) {
      return Container(
        height: _calculateVideoContainerHeight(),
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      height: _calculateVideoContainerHeight(),
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),

          if (_selectedProtocolImageUrl != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _calculateProtocolHeight(),
              child: _buildProtocolOverlay(),
            ),

          if (_selectedFooterImageUrl != null || _selectedFooterImageFile != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: _calculateFooterHeight(),
              child: _buildFooterOverlay(),
            ),

          if (_selectedImage != null)
            _buildSelfImageOverlay(),
        ],
      ),
    );
  }

  Widget _buildProtocolOverlay() {
    if (_selectedProtocolImageUrl == null) return const SizedBox();

    // 🔥 Instant access from memory cache
    final cachedImage = ImageCacheHelper.getPrecachedImage(_selectedProtocolImageUrl!);

    return Container(
      width: double.infinity,
      height: _calculateProtocolHeight(),
      child: cachedImage != null
          ? Image.file(cachedImage, fit: BoxFit.contain,)
          : _buildFallbackImage(_selectedProtocolImageUrl!),
    );
  }

  Widget _buildFooterOverlay() {
    if (_selectedFooterImageUrl == null && _selectedFooterImageFile == null) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      height: _calculateFooterHeight(),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(),
      child: _selectedFooterImageFile != null
          ? Image.file(
        _selectedFooterImageFile!,
        fit: BoxFit.fill,
        alignment: Alignment.bottomCenter,
      )
          : _selectedFooterImageUrl!.startsWith('http')
          ? CachedNetworkImage(
        imageUrl: _selectedFooterImageUrl!,
        fit: BoxFit.fill,
        alignment: Alignment.bottomCenter,
        placeholder: (context, url) =>
            Container(color: Colors.grey[300]),
        errorWidget: (context, url, error) =>
        const Icon(Icons.broken_image),
      )
          : Image.file(
        File(_selectedFooterImageUrl!),
        fit: BoxFit.fill,
        alignment: Alignment.bottomCenter,
      ),
    );
  }

  Widget _buildSelfImageOverlay() {
    if (_selectedImage == null) return const SizedBox();

    final selfImageHeight = _calculateSelfImageHeight();
    final selfImageWidth = _calculateSelfImageWidth();
    final footerHeight = _calculateFooterHeight();
    final bottomPosition = footerHeight + (selfImageHeight * 0.001);

    return Positioned(
      bottom: bottomPosition,
      right: _selectedPosition == 'right' ? 0 : null,
      left: _selectedPosition == 'left' ? 0 : null,
      child: Container(
        width: selfImageWidth,
        height: selfImageHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: _selectedImage != null
              ? Image.file(_selectedImage!, fit: BoxFit.cover)
              : Container(),
        ),
      ),
    );
  }

  Widget _buildCustomControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _togglePlayback,
          ),
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              activeColor: Colors.white,
              inactiveColor: Colors.white30,
              min: 0,
              max: duration.inSeconds.toDouble(),
              value: position.inSeconds.clamp(0, duration.inSeconds).toDouble(),
              onChanged: (value) {
                _controller.seekTo(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Widget _buildProtocolRow() {
    const double boxWidth = 200.0;
    const double boxHeight = 60.0;
    const double boxSpacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Protocol",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_isLoadingProtocolImages) ...[
                      _buildLoadingBox(boxWidth, boxHeight),
                      _buildLoadingBox(boxWidth, boxHeight),
                      _buildLoadingBox(boxWidth, boxHeight),
                    ] else ...[
                      ..._protocolImages.map((image) {
                        final isSelected = _selectedProtocolImageUrl == image.imageUrl;
                        // 🔥 Use cached image first
                        final cachedImage = ImageCacheHelper.getPrecachedImage(image.imageUrl);
                        final isLoading = _protocolImageLoading[image.imageUrl] ?? false;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProtocolImageUrl = null;
                              } else {
                                _selectedProtocolImageUrl = image.imageUrl;
                              }
                            });
                          },
                          child: Container(
                            width: boxWidth,
                            height: boxHeight,
                            margin: const EdgeInsets.only(right: boxSpacing),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? SharedColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: isLoading
                                  ? _buildLoader()
                                  : Container(
                                color: Colors.grey[300],
                                child: cachedImage != null
                                    ? Image.file(
                                  cachedImage,
                                  fit: BoxFit.fitWidth,
                                )
                                    : _buildFallbackImage(image.imageUrl),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomImageSelector() {
    final filteredImages = _apiSelfImages.where((image) =>
    image.position.toLowerCase().trim() == _selectedPosition).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_isLoadingSelfImages) ...[
                      _buildLoadingBox(60, 60),
                      _buildLoadingBox(60, 60),
                      _buildLoadingBox(60, 60),
                      _buildLoadingBox(60, 60),
                    ] else ...[
                      ...filteredImages.map((image) {
                        final isSelected = _selectedImage == _selfImageCache[image.imageUrl];
                        // 🔥 Use cached image first
                        final cachedImage = ImageCacheHelper.getPrecachedImage(image.imageUrl);
                        final isLoading = _selfImageLoading[image.imageUrl] ?? false;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedImage = null;
                              } else {
                                _selectedImage = cachedImage ?? _selfImageCache[image.imageUrl];
                                _selectedPosition = image.position.toLowerCase();
                              }
                              _positionVersion++;
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? SharedColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: isLoading
                                  ? _buildLoader()
                                  : cachedImage != null
                                  ? Image.file(
                                cachedImage,
                                fit: BoxFit.cover,
                              )
                                  : _selfImageCache[image.imageUrl] != null
                                  ? Image.file(
                                _selfImageCache[image.imageUrl]!,
                                fit: BoxFit.cover,
                              )
                                  : _buildFallbackImage(image.imageUrl),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(SharedColors.primary),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              '✨ Removing background...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  final processedImage = await BackgroundRemovalService.removeBackground(File(pickedFile.path));
                  Navigator.of(context).pop();

                  final imageToUse = processedImage ?? File(pickedFile.path);
                  
                  if (processedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Background removal failed. Using original image.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  final croppedFile = await showDialog<File?>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => ImageCropDialog(imageFile: imageToUse),
                  );

                  if (croppedFile != null) {
                    setState(() {
                      _selectedImage = croppedFile;
                    });
                  }
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterImageRow() {
    const double boxWidth = 200.0;
    const double boxHeight = 60.0;
    const double boxSpacing = 8.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Name & Designation",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_isLoadingFooterImages) ...[
                      _buildLoadingBox(boxWidth, boxHeight),
                      _buildLoadingBox(boxWidth, boxHeight),
                      _buildLoadingBox(boxWidth, boxHeight),
                    ] else ...[
                      ..._footerImages.map((image) {
                        final isSelected = _selectedFooterImageUrl == image.imageUrl;
                        // 🔥 Use cached image first
                        final cachedImage = ImageCacheHelper.getPrecachedImage(image.imageUrl);
                        final isLoading = _footerImageLoading[image.imageUrl] ?? false;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedFooterImageUrl = null;
                                _selectedFooterImageFile = null;
                              } else {
                                _selectedFooterImageUrl = image.imageUrl;
                                _selectedFooterImageFile = null;
                              }
                            });
                          },
                          child: Container(
                            width: boxWidth,
                            height: boxHeight,
                            margin: const EdgeInsets.only(right: boxSpacing),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? SharedColors.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: isLoading
                                  ? _buildLoader()
                                  : Container(
                                color: Colors.grey[300],
                                child: cachedImage != null
                                    ? Image.file(
                                  cachedImage,
                                  fit: BoxFit.contain,
                                )
                                    : _buildFallbackImage(image.imageUrl),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFallbackImage(String imageUrl) {
    return imageUrl.startsWith('http')
        ? CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain, // match the protocol overlay preview choice
      placeholder: (context, url) => _buildLoader(),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
    )
        : Image.file(
      File(imageUrl),
      fit: BoxFit.contain,
    );
  }


  Widget _buildLoadingBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildLoader(),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Container(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(SharedColors.primary),
        ),
      ),
    );
  }

  // ... (Keep all the remaining methods unchanged: _simulateVideoProcessing, _createVideoWithOverlays,
  // _loadAndResizeImage, _createCompositeOverlay, _requestStoragePermission, _saveVideoToGallery,
  // _startVideoProcessing, _shareVideo, _buildShareButton, build, _showGeneratedVideoPopup,
  // _showDownloadSuccessPopup, dispose)

  Future<File> _simulateVideoProcessing() async {
    final directory = await getApplicationDocumentsDirectory();
    File originalVideoFile;
    bool downloaded = false;

    if (widget.videoUrl.toLowerCase().contains('.m3u8')) {
      throw Exception(
          "HLS streams (.m3u8) are not supported for direct processing. "
              "Please use a direct video URL (MP4, MOV, etc.) instead.\n\n"
              "Current URL: ${widget.videoUrl}");
    }

    if (widget.videoUrl.startsWith('http')) {
      final tempVideoPath = '${directory.path}/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      originalVideoFile = File(tempVideoPath);

      try {
        final dio = Dio();
        print('Downloading remote video from: ${widget.videoUrl}');

        await dio.download(
          widget.videoUrl,
          originalVideoFile.path,
          options: Options(
            receiveTimeout: const Duration(seconds: 30),
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(1);
              print('Download progress: $progress% ($received/$total bytes)');
            }
          },
        );

        final exists = await originalVideoFile.exists();
        final size = exists ? await originalVideoFile.length() : 0;

        if (!exists || size < 1024) {
          throw Exception(
              "Downloaded file is too small ($size bytes) to be a video. "
                  "URL: ${widget.videoUrl}");
        }

        downloaded = true;
        print('Video downloaded successfully. Size: $size bytes');

      } catch (e) {
        throw Exception("Failed to download video: $e");
      }
    } else {
      originalVideoFile = File(widget.videoUrl);
      final exists = await originalVideoFile.exists();
      final size = exists ? await originalVideoFile.length() : 0;

      if (!exists) {
        throw Exception("Local video file not found: ${widget.videoUrl}");
      }

      if (size < 1024) {
        throw Exception("Local video file is too small ($size bytes). Please check the file.");
      }

      print('Using local video file: ${originalVideoFile.path} (size: $size bytes)');
    }

    try {
      final result = await _createVideoWithOverlays(originalVideoFile);
      return result;
    } finally {
      if (downloaded) {
        try {
          if (await originalVideoFile.exists()) {
            await originalVideoFile.delete();
            print('Cleaned up temporary video file');
          }
        } catch (e) {
          print('Warning: Could not delete temporary file: $e');
        }
      }
    }
  }

  Future<File> _createVideoWithOverlays(File originalVideo) async {
    final directory = await getApplicationDocumentsDirectory();
    final outputPath = '${directory.path}/final_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await Directory(directory.path).create(recursive: true);

    final overlayImage = await _createCompositeOverlay();
    if (!await overlayImage.exists()) {
      throw Exception("Overlay image not found at ${overlayImage.path}");
    }

    final inputVideoPath = originalVideo.path;
    final overlayPath = overlayImage.path;

    final inputExists = await File(inputVideoPath).exists();
    final inputLen = inputExists ? await File(inputVideoPath).length() : 0;
    final overlayExists = await File(overlayPath).exists();
    final overlayLen = overlayExists ? await File(overlayPath).length() : 0;

    print('FFmpeg input video: $inputVideoPath (exists=$inputExists, size=$inputLen)');
    print('FFmpeg overlay image: $overlayPath (exists=$overlayExists, size=$overlayLen)');

    final command = '-y -i "$inputVideoPath" -i "$overlayPath" '
        '-filter_complex "[0:v][1:v]overlay=0:0:enable=\'between(t,0,999999)\'" '
    // '-c:v libx264 -preset slow -crf 18 -c:a copy -pix_fmt yuv420p '
    // '-movflags +faststart "$outputPath"';
        '-c:v libx264 -preset slow -crf 15 -profile:v high -level 4.2 '
        '-pix_fmt yuv420p -movflags +faststart -c:a copy "$outputPath"';
    print('Executing FFmpeg command: $command');

    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogsAsString();

      print('FFmpeg return code: $returnCode');
      print('FFmpeg logs: $logs');

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(outputPath);
        final outputExists = await outputFile.exists();
        final outputSize = outputExists ? await outputFile.length() : 0;

        if (outputExists && outputSize > 0) {
          print('Video processing successful! Output: ${outputFile.path} (size: $outputSize bytes)');

          try {
            await overlayImage.delete();
          } catch (e) {
            print('Could not delete overlay file: $e');
          }

          return outputFile;
        } else {
          throw Exception('FFmpeg succeeded but output file is empty or missing. Output exists: $outputExists, size: $outputSize');
        }
      } else {
        throw Exception('FFmpeg failed with return code: $returnCode\nLogs: $logs');
      }
    } catch (e) {
      throw Exception('FFmpeg execution failed: $e');
    }
  }

  Future<img.Image?> _loadAndResizeImage(
      String? urlOrPath,
      File? file,
      int targetWidth,
      int targetHeight, {
        bool maintainAspect = true,
        bool allowUpscale = true,
        img.Interpolation interpolation = img.Interpolation.cubic,
      }) async {
    try {
      Uint8List? bytes;

      if (file != null) {
        bytes = await file.readAsBytes();
      } else if (urlOrPath != null && urlOrPath.startsWith('http')) {
        final response = await Dio().get(
          urlOrPath,
          options: Options(responseType: ResponseType.bytes),
        );
        bytes = Uint8List.fromList(response.data);
      } else if (urlOrPath != null) {
        bytes = await File(urlOrPath).readAsBytes();
      }

      if (bytes != null && bytes.isNotEmpty) {
        final originalImage = img.decodeImage(bytes);
        if (originalImage != null) {
          print('Original image size: ${originalImage.width}x${originalImage.height}');
          print('Target size: ${targetWidth}x$targetHeight');

          int finalWidth = targetWidth;
          int finalHeight = targetHeight;

          if (maintainAspect) {
            final aspect = originalImage.width / originalImage.height;

            final widthBasedHeight = (targetWidth / aspect).round();
            final heightBasedWidth = (targetHeight * aspect).round();

            if (widthBasedHeight <= targetHeight) {
              finalWidth = targetWidth;
              finalHeight = widthBasedHeight;
            } else {
              finalWidth = heightBasedWidth;
              finalHeight = targetHeight;
            }

            if (!allowUpscale) {
              finalWidth = finalWidth.clamp(1, originalImage.width);
              finalHeight = finalHeight.clamp(1, originalImage.height);
            }
          } else {
            if (!allowUpscale) {
              finalWidth = finalWidth.clamp(1, originalImage.width);
              finalHeight = finalHeight.clamp(1, originalImage.height);
            }
          }

          print('Final resized dimensions: ${finalWidth}x$finalHeight');

          final resizedImage = img.copyResize(
            originalImage,
            width: finalWidth,
            height: finalHeight,
            interpolation: interpolation,
          );

          return resizedImage;
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
    return null;
  }

  Future<File> _createCompositeOverlay() async {
    try {
      final videoWidth = _videoWidth;
      final videoHeight = _videoHeight;

      print('Creating overlay with video dimensions: ${videoWidth}x$videoHeight');

      final overlayImage = img.Image(width: videoWidth, height: videoHeight, numChannels: 4);
      img.fill(overlayImage, color: img.ColorRgba8(0, 0, 0, 0));

      final protocolHeight = (videoHeight * 0.25).toInt();
      final footerHeight = (videoHeight * 0.20).toInt();
      final selfImageHeight = (videoHeight * 0.45).toInt();
      final selfImageWidth = (selfImageHeight * 0.85).toInt();

      final selfImageBottomMargin = (videoHeight * 0).toInt();
      final sideMargin = (videoWidth * 0).toInt();

      print('Overlay dimensions - Protocol: $protocolHeight, Footer: $footerHeight, Self: ${selfImageWidth}x$selfImageHeight');

      Future<img.Image?> _loadAndResizeImage(
          String? urlOrPath,
          File? file,
          int targetWidth,
          int targetHeight, {
            bool maintainAspect = true,
            bool allowUpscale = true,
            img.Interpolation interpolation = img.Interpolation.cubic,
          }) async {
        try {
          Uint8List? bytes;

          if (file != null) {
            bytes = await file.readAsBytes();
          } else if (urlOrPath != null && urlOrPath.startsWith('http')) {
            final response = await Dio().get(
              urlOrPath,
              options: Options(responseType: ResponseType.bytes),
            );
            bytes = Uint8List.fromList(response.data);
          } else if (urlOrPath != null) {
            bytes = await File(urlOrPath).readAsBytes();
          }

          if (bytes != null && bytes.isNotEmpty) {
            final originalImage = img.decodeImage(bytes);
            if (originalImage != null) {
              print('Original image size: ${originalImage.width}x${originalImage.height}');
              print('Target size: ${targetWidth}x$targetHeight');

              int finalWidth = targetWidth;
              int finalHeight = targetHeight;

              if (maintainAspect) {
                final aspect = originalImage.width / originalImage.height;

                final widthBasedHeight = (targetWidth / aspect).round();
                final heightBasedWidth = (targetHeight * aspect).round();

                if (widthBasedHeight <= targetHeight) {
                  finalWidth = targetWidth;
                  finalHeight = widthBasedHeight;
                } else {
                  finalWidth = heightBasedWidth;
                  finalHeight = targetHeight;
                }

                if (!allowUpscale) {
                  finalWidth = finalWidth.clamp(1, originalImage.width);
                  finalHeight = finalHeight.clamp(1, originalImage.height);
                }
              } else {
                if (!allowUpscale) {
                  finalWidth = finalWidth.clamp(1, originalImage.width);
                  finalHeight = finalHeight.clamp(1, originalImage.height);
                }
              }

              print('Final resized dimensions: ${finalWidth}x$finalHeight');

              final resizedImage = img.copyResize(
                originalImage,
                width: finalWidth,
                height: finalHeight,
                interpolation: interpolation,
              );

              return resizedImage;
            }
          }
        } catch (e) {
          debugPrint('Error loading image: $e');
        }
        return null;
      }

      if (_selectedProtocolImageUrl != null) {
        try {
          final protocolImage = await _loadAndResizeImage(
            _selectedProtocolImageUrl,
            null,
            videoWidth,
            protocolHeight,
            maintainAspect: true,
            allowUpscale: true,
            interpolation: img.Interpolation.cubic,
          );

          if (protocolImage != null) {
            final dstX = ((videoWidth - protocolImage.width) / 2).round();
            final dstY = 0;
            img.compositeImage(overlayImage, protocolImage, dstX: dstX, dstY: dstY);
            print('Protocol image added: ${protocolImage.width}x${protocolImage.height} at ($dstX, $dstY)');
          }
        } catch (e) {
          debugPrint('Error processing protocol image: $e');
        }
      }

      int actualFooterHeight = 0;
      if (_selectedFooterImageUrl != null || _selectedFooterImageFile != null) {
        try {
          final footerImage = await _loadAndResizeImage(
            _selectedFooterImageUrl,
            _selectedFooterImageFile,
            videoWidth,
            footerHeight,
            maintainAspect: true,
            interpolation: img.Interpolation.cubic,
          );

          if (footerImage != null) {
            final dstX = ((videoWidth - footerImage.width) / 2).round();
            final dstY = videoHeight - footerImage.height;
            img.compositeImage(overlayImage, footerImage, dstX: dstX, dstY: dstY);
            actualFooterHeight = footerImage.height;
            print('Footer image added: ${footerImage.width}x${footerImage.height} at ($dstX, $dstY)');
          }
        } catch (e) {
          debugPrint('Error processing footer image: $e');
        }
      }

      if (_selectedImage != null) {
        try {
          final selfImage = await _loadAndResizeImage(
            null,
            _selectedImage,
            selfImageWidth,
            selfImageHeight,
            maintainAspect: true,
            allowUpscale: true,
            interpolation: img.Interpolation.cubic,
          );

          if (selfImage != null) {
            final dstX = _selectedPosition == 'left' ? sideMargin : videoWidth - selfImage.width - sideMargin;
            final effectiveFooterHeight = actualFooterHeight > 0 ? actualFooterHeight : footerHeight;
            final dstY = videoHeight - effectiveFooterHeight - selfImage.height - selfImageBottomMargin;

            img.compositeImage(overlayImage, selfImage, dstX: dstX, dstY: dstY);
            print('Self image added: ${selfImage.width}x${selfImage.height} at ($dstX, $dstY)');
            print('Position details - Footer height: $effectiveFooterHeight, Self height: ${selfImage.height}, Bottom margin: $selfImageBottomMargin');
          }
        } catch (e) {
          debugPrint('Error processing self image: $e');
        }
      }

      final tempDir = await getTemporaryDirectory();
      final overlayPath = '${tempDir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.png';
      final overlayFile = File(overlayPath);

      final pngBytes = img.encodePng(overlayImage, level: 0);
      await overlayFile.writeAsBytes(pngBytes);

      print('Final overlay created: $overlayPath (${pngBytes.length} bytes)');
      return overlayFile;
    } catch (e) {
      debugPrint('Error creating overlay: $e');
      rethrow;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final storageGranted = await Permission.storage.isGranted;
      final photosGranted = await Permission.photos.isGranted;
      final manageStorageGranted = await Permission.manageExternalStorage.isGranted;

      if (storageGranted || photosGranted || manageStorageGranted) {
        return true;
      }

      final statuses = await [
        Permission.storage,
        Permission.photos,
        if (await Permission.manageExternalStorage.isRestricted)
          Permission.manageExternalStorage,
      ].request();

      if (statuses.values.any((status) => status.isGranted)) {
        return true;
      }

      bool? shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text('We need storage permissions to save your generated videos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Deny'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  Future<void> _saveVideoToGallery(File videoFile) async {
    try {
      if (!await videoFile.exists() || await videoFile.length() == 0) {
        throw Exception("Video file is empty or doesn't exist");
      }

      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception("Storage permission not granted");
      }

      final result = await PhotoManager.editor.saveVideo(
        videoFile,
        title: "${DateTime.now().millisecondsSinceEpoch}.mp4",
      );

      if (result == null) {
        throw Exception("Failed to save to gallery");
      }

      setState(() {
        _generatedVideoFile = videoFile;
        _generatedVideoController = VideoPlayerController.file(videoFile)
          ..initialize().then((_) {
            setState(() {
              _generatedVideoController.setLooping(false);
              _generatedVideoController.pause();
            });
          })
          ..addListener(() {
            if (mounted) setState(() {});
          });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video saved to gallery successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video: ${e.toString()}')),
      );
    }
  }

  void _startVideoProcessing() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _progressValue = 0.1;
    });

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isProcessing) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_progressValue < 0.9) {
          _progressValue += 0.1;
          if (_progressValue > 0.9) _progressValue = 0.9;
        }
      });
    });

    try {
      final processedFile = await _simulateVideoProcessing();
      await _saveVideoToGallery(processedFile);

      setState(() {
        _progressValue = 1.0;
        _isProcessing = false;
      });

      _showGeneratedVideoPopup();
      _showDownloadSuccessPopup();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video processing complete!')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing video: $e')),
      );
    }
  }

  Future<void> _shareVideo(String platform) async {
    if (_generatedVideoFile == null) return;

    final text = 'Check out my video!';

    try {
      if (platform == 'other') {
        await Share.shareXFiles(
          [XFile(_generatedVideoFile!.path)],
          text: text,
        );
      } else {
        await Share.shareXFiles(
          [XFile(_generatedVideoFile!.path)],
          text: text,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing video: $e')),
      );
    }
  }

  Widget _buildShareButton(String imageName, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Image.asset(
                'assets/images/$imageName.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.share),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.pageTitle ?? "Video Editor",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: SharedColors.primary,
        elevation: 0,
        toolbarHeight: kToolbarHeight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: SharedColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildVideoPlayer(),
                    const SizedBox(height: 6),
                    _buildCustomControls(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              if (_isProcessing) ...[
                LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(SharedColors.primary),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing: ${(_progressValue * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBottomImageSelector(),
                  const SizedBox(height: 12),
                  _buildProtocolRow(),
                  const SizedBox(height: 12),
                  _buildFooterImageRow(),

                ],
              ),
              const SizedBox(height: 10),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isProcessing ? Colors.grey : SharedColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _startVideoProcessing,
                  child: Text(
                    _isProcessing ? 'Processing...' : 'Generate Video',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_generatedVideoFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AspectRatio(
                    aspectRatio: _generatedVideoController.value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        VideoPlayer(_generatedVideoController),

                        if (!_generatedVideoController.value.isPlaying)
                          Container(
                            color: Colors.black26,
                          ),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (_generatedVideoController.value.isPlaying) {
                                  _generatedVideoController.pause();
                                } else {
                                  _generatedVideoController.play();
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _generatedVideoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "Share your video:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton("whatsapp", "WhatsApp", () => _shareVideo('whatsapp')),
                    _buildShareButton("instagram", "Instagram", () => _shareVideo('instagram')),
                    _buildShareButton("facebook", "Facebook", () => _shareVideo('facebook')),
                    _buildShareButton("x", "X", () => _shareVideo('x')),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showGeneratedVideoPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: _generatedVideoController.value.aspectRatio,
                  child: VideoPlayer(_generatedVideoController),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Share your video:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton("whatsapp", "WhatsApp", () {
                      Navigator.pop(context);
                      _shareVideo('whatsapp');
                    }),
                    _buildShareButton("instagram", "Instagram", () {
                      Navigator.pop(context);
                      _shareVideo('instagram');
                    }),
                    _buildShareButton("facebook", "Facebook", () {
                      Navigator.pop(context);
                      _shareVideo('facebook');
                    }),
                    _buildShareButton("x", "X", () => _shareVideo('x')),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SharedColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDownloadSuccessPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/lottie/success.json',
                  width: 220,
                  height: 220,
                  repeat: true,
                ),
                const SizedBox(height: 12),
                const Text(
                  "4K HD video saved to gallery and downloads!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: SharedColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SharedColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      _controller.dispose();
    } catch (e) {
      // ignore
    }
    try {
      if (mounted && _generatedVideoController != null) {
        _generatedVideoController.dispose();
      }
    } catch (e) {
      // ignore
    }
    super.dispose();
  }
}
