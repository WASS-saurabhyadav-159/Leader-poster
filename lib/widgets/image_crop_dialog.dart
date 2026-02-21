import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../config/colors.dart';

class ImageCropDialog extends StatefulWidget {
  final File imageFile;

  const ImageCropDialog({Key? key, required this.imageFile}) : super(key: key);

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _imageKey = GlobalKey();
  double _scale = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<File?> _cropImage() async {
    try {
      RenderRepaintBoundary boundary =
          _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/cropped_$timestamp.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: SharedColors.primary,
        title: Text('Crop Image', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final croppedFile = await _cropImage();
              Navigator.pop(context, croppedFile);
            },
            child: Text(
              'DONE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Image with zoom/pan
                Center(
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 0.5,
                    maxScale: 5.0,
                    onInteractionUpdate: (details) {
                      setState(() {
                        _scale = _controller.value.getMaxScaleOnAxis();
                      });
                    },
                    child: RepaintBoundary(
                      key: _imageKey,
                      child: Image.file(
                        widget.imageFile,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Crop frame overlay
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          // Corner indicators
                          Positioned(
                            top: -1,
                            left: -1,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: SharedColors.primary, width: 4),
                                  left: BorderSide(color: SharedColors.primary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: SharedColors.primary, width: 4),
                                  right: BorderSide(color: SharedColors.primary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            left: -1,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: SharedColors.primary, width: 4),
                                  left: BorderSide(color: SharedColors.primary, width: 4),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -1,
                            right: -1,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: SharedColors.primary, width: 4),
                                  right: BorderSide(color: SharedColors.primary, width: 4),
                                ),
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
          // Bottom controls
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[900],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.zoom_out, color: Colors.white70),
                    SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _scale.clamp(0.5, 5.0),
                        min: 0.5,
                        max: 5.0,
                        activeColor: SharedColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _scale = value;
                            _controller.value = Matrix4.identity()..scale(value);
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.zoom_in, color: Colors.white70),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Pinch to zoom • Drag to position',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
