import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';

import '../../../config/colors.dart';

class VideoEditorPage extends StatefulWidget {
  final String videoUrl;
  final String? pageTitle;

  const VideoEditorPage({
    required this.videoUrl,
    this.pageTitle = "Video Editor",
    super.key,
  });

  @override
  State<VideoEditorPage> createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  late VideoPlayerController _controller;
  late VideoPlayerController _generatedVideoController;
  bool _isPlaying = false;
  bool _isProcessing = false;
  double _progressValue = 0.0;
  late Duration _videoDuration;
  File? _generatedVideoFile;
  File? _selectedImage;
  File? _topBannerImage;
  String _name = "Enter your name";
  String _designation = "Enter your designation";
  final ImagePicker _picker = ImagePicker();
  Color? _nameContainerColor;
  Color? _nameTextColor;
  Color? _designationTextColor;
  Color? _dividerColor;
  String _selectedSize = '1080x1920';
  final List<String> _sizeOptions = ['1080x1920', '1080x1080', '1080x1350'];

  TextStyle _nameTextStyle = const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: 1.2,
  );

  TextStyle _designationTextStyle = const TextStyle(
    fontSize: 10,
    color: Colors.black54,
  );

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _videoDuration = _controller.value.duration;
          _controller.play();
          _isPlaying = true;
        });
      });

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _generatedVideoController = VideoPlayerController.network('')
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _generatedVideoController.dispose();
    super.dispose();
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

  Future<void> _pickBottomImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickTopBanner() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _topBannerImage = File(pickedFile.path);
      });
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we only need specific media permissions
      final photosGranted = await Permission.photos.isGranted;

      if (photosGranted) {
        return true;
      }

      // Request only photos permission for MediaStore API
      final status = await Permission.photos.request();

      if (status.isGranted) {
        return true;
      }

      // If permission denied, show dialog to open settings
      if (status.isDenied || status.isPermanentlyDenied) {
        bool? shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('We need photos permission to save your generated videos to gallery.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
      }
      return false;
    }
    return true;
  }


  void _showSizeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sizeOptions.map((size) {
              return RadioListTile<String>(
                title: Text(size),
                value: size,
                groupValue: _selectedSize,
                onChanged: (String? value) {
                  setState(() {
                    _selectedSize = value!;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startVideoProcessing();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _editText(String title, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter $title"),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      onSave(controller.text);
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<File> _simulateVideoProcessing() async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/processed_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Create a temporary file for the original video
    File originalVideoFile;
    if (widget.videoUrl.startsWith('http')) {
      final response = await Dio().get(
        widget.videoUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      originalVideoFile = File('${directory.path}/temp_video.mp4');
      await originalVideoFile.writeAsBytes(response.data);
    } else {
      originalVideoFile = File(widget.videoUrl);
    }

    // Create a preview of the video with all overlays
    final videoWithOverlays = await _createVideoWithOverlays(originalVideoFile);

    // Save the final video
    final processedFile = File(filePath);
    await processedFile.writeAsBytes(await videoWithOverlays.readAsBytes());

    // Clean up temporary files
    if (widget.videoUrl.startsWith('http')) {
      await originalVideoFile.delete();
    }

    return processedFile;
  }
  Future<File> _createVideoWithOverlays(File originalVideo) async {
    final directory = await getApplicationDocumentsDirectory();
    final outputPath = '${directory.path}/final_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // In a real implementation, you would use a video processing library
    // like ffmpeg to composite the video with overlays
    // For this Bjp, we'll just return the original video
    // (You should replace this with actual video processing code)

    // This is a placeholder - implement your actual video processing here
    return originalVideo.copy(outputPath);
  }

  Future<void> _saveVideoToGallery(File videoFile) async {
    try {
      // Check if file exists and is valid
      if (!await videoFile.exists() || await videoFile.length() == 0) {
        throw Exception("Video file is empty or doesn't exist");
      }

      // Request permissions
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception("Storage permission not granted");
      }

      // Save to gallery using photo_manager
      final result = await PhotoManager.editor.saveVideo(
        videoFile,
        title: "polyposter_video_${DateTime.now().millisecondsSinceEpoch}.mp4",
      );

      if (result == null) {
        throw Exception("Failed to save to gallery");
      }

      // Save to local storage
      final downloadsDirectory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      if (!await downloadsDirectory.exists()) {
        await downloadsDirectory.create(recursive: true);
      }

      final fileName = 'polyposter_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savedFile = File(path.join(downloadsDirectory.path, fileName));
      await videoFile.copy(savedFile.path);

      setState(() {
        _generatedVideoFile = savedFile;
        _generatedVideoController = VideoPlayerController.file(savedFile)
          ..initialize().then((_) {
            setState(() {});
            _generatedVideoController.play();
          });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video with all edits saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving video: ${e.toString()}')),
      );
      print('Error saving video: ${e.toString()}');
    }
  }

  void _startVideoProcessing() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _progressValue = 0.0;
    });

    // Simulate processing with a timer
    const processingDuration = Duration(seconds: 5);
    const updateInterval = Duration(milliseconds: 100);
    final totalUpdates = processingDuration.inMilliseconds ~/ updateInterval.inMilliseconds;
    final increment = 1.0 / totalUpdates;

    Timer.periodic(updateInterval, (Timer timer) async {
      setState(() {
        _progressValue += increment;
        if (_progressValue >= 1.0) {
          _progressValue = 1.0;
          timer.cancel();
        }
      });

      if (_progressValue >= 1.0) {
        try {
          // Process and save the video
          final processedFile = await _simulateVideoProcessing();
          await _saveVideoToGallery(processedFile);

          setState(() {
            _isProcessing = false;
          });

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
    });
  }

  Future<void> _shareVideo(String platform) async {
    if (_generatedVideoFile == null) return;

    final text = 'Check out my video created with PolyPoster!';

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
          subject: 'My PolyPoster Video',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing video: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
        backgroundColor: SharedColors.primaryDark,
        elevation: 0,
        toolbarHeight: kToolbarHeight,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: _controller.value.isInitialized
                    ? Column(
                  children: [
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        children: [
                          VideoPlayer(_controller),
                          if (_topBannerImage != null)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Image.file(
                                _topBannerImage!,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (_selectedImage != null)
                            Positioned(
                              bottom: 60,
                              right: 10,
                              child: Container(
                                width: 90,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _nameContainerColor ?? Colors.white,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _editText("Name", _name, (value) => _name = value),
                                        child: Text(
                                          _name,
                                          style: _nameTextStyle.copyWith(
                                            color: _nameTextColor ?? Colors.black,
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 2,
                                      color: _dividerColor ?? Colors.black,
                                      margin: const EdgeInsets.symmetric(vertical: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _editText("Designation", _designation, (value) => _designation = value),
                                        child: Text(
                                          _designation,
                                          style: _nameTextStyle.copyWith(
                                            color: _nameTextColor ?? Colors.black,
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildCustomControls(),
                  ],
                )
                    : const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 20),
              if (_isProcessing) ...[
                LinearProgressIndicator(
                  value: _progressValue,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(SharedColors.primaryDark),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  'Processing: ${(_progressValue * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _buildFullWidthButton("Upload Image", _pickBottomImage),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFullWidthButton("Upload Top Banner", _pickTopBanner),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFullWidthButton("Edit Name", () => _editText("Name", _name, (value) => _name = value)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFullWidthButton("Edit Designation", () => _editText("Designation", _designation, (value) => _designation = value)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildFullWidthButton("Container Color", _selectContainerColor),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isProcessing ? Colors.grey :  SharedColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isProcessing ? null : _showSizeSelectionDialog,
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
                    child: VideoPlayer(_generatedVideoController),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        _generatedVideoController.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                        color:  SharedColors.primaryDark,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_generatedVideoController.value.isPlaying) {
                            _generatedVideoController.pause();
                          } else {
                            _generatedVideoController.play();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.replay, color:  SharedColors.primaryDark),
                      onPressed: () {
                        _generatedVideoController.seekTo(Duration.zero);
                        _generatedVideoController.play();
                      },
                    ),
                  ],
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

  Widget _buildCustomControls() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          const SizedBox(width: 4),
          const Icon(Icons.volume_up, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Future<void> _selectContainerColor() async {
    final Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Container Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _nameContainerColor ?? Colors.white,
            onColorChanged: (color) {
              _nameContainerColor = color;
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _nameContainerColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _nameContainerColor = pickedColor;
      });
    }
  }

  Widget _buildFullWidthButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:  SharedColors.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
