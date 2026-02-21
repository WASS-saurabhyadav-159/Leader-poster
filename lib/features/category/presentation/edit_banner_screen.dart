// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:lottie/lottie.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:path/path.dart' as path;
// import 'package:photo_manager/photo_manager.dart';
// import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:dio/dio.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../../../config/colors.dart';
// import '../../../core/models/FooterImage.dart';
// import '../../../core/models/ProtocolImage.dart';
// import '../../../core/models/SelfImage.dart';
// import '../../../core/network/api_service.dart';
//
// class SocialMediaDetailsPage extends StatefulWidget {
//   final String assetPath;
//   final String categoryId;
//   final String posterId;
//   const SocialMediaDetailsPage({
//     super.key,
//     required this.assetPath,
//     required this.categoryId,
//     required this.posterId,
//   });
//
//   @override
//   _SocialMediaDetailsPageState createState() => _SocialMediaDetailsPageState();
// }
//
// class _SocialMediaDetailsPageState extends State<SocialMediaDetailsPage> {
//   static const int _maxVisibleUploads = 4;
//   File? _selectedImage;
//   File? _topBannerImage;
//   File? _generatedImage;
//   String _name = " ";
//   String _designation = " ";
//   final ImagePicker _picker = ImagePicker();
//   final GlobalKey _globalKey = GlobalKey();
//   Color? _nameContainerColor;
//   Color _nameTextColor = Colors.white;
//   Color _designationTextColor = Colors.white;
//   Color? _dividerColor;
//   bool _isLoading = true;
//   String? _adminTopBannerUrl;
//   String? _adminBottomImageUrl;
//   String? _adminName;
//   String? _adminDesignation;
//   bool _isGenerating = false;
//   double _generationProgress = 0.0;
//   String? _selectedApiImageUrl;
//   String? _selectedProtocolImageUrl;
//   String? _selectedPosition = 'right'; // Default to right position
//   int _positionVersion = 0;
//   void _updatePosition(String position) {
//     setState(() {
//       _selectedPosition = position.trim().toLowerCase();
//       _positionVersion++;
//     });
//   }
//   List<ProtocolImage> _protocolImages = [];
//   List<FooterImage> _footerImages = [];
//   File? _selectedLocalImage;
//   String? _selectedFooterImageUrl;
//   TextStyle _nameTextStyle = const TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.bold,
//     color: Colors.white,
//     letterSpacing: 0.2,
//     fontFamily: 'Ramabhadra',
//   );
//   TextStyle _designationTextStyle = const TextStyle(
//     fontSize: 13,
//     color: Colors.white,
//     fontFamily: 'Ramabhadra',
//   );
//   final List<String> _defaultImagePaths = [];
//   List<File> _uploadedImages = [];
//   List<SelfImage> _apiSelfImages = [];
//   String? _selectedAssetImage;
//   File? _selectedUploadedImage;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserProfile();
//     _loadApiSelfImages();
//     _loadProtocolImages();
//     _loadFooterImages();
//   }
//
//   Future<void> _loadFooterImages() async {
//     try {
//       final images = await ApiService().fetchFooterImages();
//       setState(() {
//         _footerImages = images;
//       });
//     } catch (e) {
//       // Handle error (show snackbar, etc.)
//     }
//   }
//
//   Future<void> _loadProtocolImages() async {
//     try {
//       final images = await ApiService().fetchProtocolImages();
//       setState(() {
//         _protocolImages = images;
//       });
//     } catch (e) {
//       // Optionally handle error
//       print('Error loading protocol images: $e');
//     }
//   }
//
//   Future<void> _loadApiSelfImages() async {
//     try {
//       final images = await ApiService().fetchSelfImages();
//       setState(() {
//         _apiSelfImages = images;
//       });
//     } catch (e) {
//       // Optionally handle error
//     }
//   }
//
//   Future<void> _fetchUserProfile() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token');
//
//       if (token == null) {
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       final dio = Dio();
//       final response = await dio.get(
//         'https://poliposter.drpauls.in:5920/api/v1/account/user/profile',
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );
//
//       if (response.statusCode == 200) {
//         final data = response.data;
//         final userDetail = data['userDetail'];
//
//         setState(() {
//           _adminTopBannerUrl = userDetail['top'];
//           _adminBottomImageUrl = userDetail['profile'];
//           _adminName = userDetail['adminAssignName'];
//           _adminDesignation = userDetail['designation'];
//           _selectedFooterImageUrl= userDetail["bottom"];
//
//           if (_adminName != null && _adminName!.isNotEmpty) {
//             _name = _adminName!;
//           }
//           if (_adminDesignation != null && _adminDesignation!.isNotEmpty) {
//             _designation = _adminDesignation!;
//           }
//
//           _isLoading = false;
//         });
//       } else {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _increaseCount() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token')?.trim();
//
//       if (token == null || token.isEmpty) {
//         print('❌ Authentication token missing or empty');
//         return;
//       }
//
//       if (widget.categoryId.isEmpty || widget.posterId.isEmpty) {
//         print('❌ Missing required IDs - Category: ${widget.categoryId}, Poster: ${widget.posterId}');
//         return;
//       }
//
//       final dio = Dio(BaseOptions(
//         baseUrl: 'https://poliposter.drpauls.in:5920/api/v1/',
//         connectTimeout: const Duration(seconds: 5),
//         receiveTimeout: const Duration(seconds: 5),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       ));
//
//       dio.interceptors.add(LogInterceptor(
//         request: true,
//         requestHeader: true,
//         requestBody: true,
//         responseHeader: true,
//         responseBody: true,
//       ));
//
//       print('📤 Making POST request to increase count');
//       print('   Category ID: ${widget.categoryId}');
//       print('   Poster ID: ${widget.posterId}');
//       print('   Token prefix: ${token.substring(0, 8)}...');
//
//       final response = await dio.post(
//         'category/increase-count',
//         queryParameters: {
//           'categoryId': widget.categoryId,
//           'posterId': widget.posterId,
//         },
//       );
//
//       if (response.statusCode == 200) {
//         print('✅ Count increased successfully! Response: ${response.data}');
//       } else {
//         print('⚠️ Unexpected response: ${response.statusCode}');
//         print('   Response data: ${response.data}');
//       }
//     } on DioException catch (e) {
//       print('🔥 Dio Error: ${e.type}');
//       print('   Message: ${e.message}');
//
//       if (e.response != null) {
//         print('   Status: ${e.response?.statusCode}');
//         print('   Data: ${e.response?.data}');
//         print('   Headers: ${e.response?.headers}');
//       }
//     } catch (e) {
//       print('💥 Unexpected error: $e');
//     }
//   }
//
//   Future<void> _generateImageWithLoader() async {
//     setState(() {
//       _isGenerating = true;
//       _generationProgress = 0.0;
//     });
//
//     const totalSteps = 10;
//     for (int i = 1; i <= totalSteps; i++) {
//       await Future.delayed(const Duration(milliseconds: 200));
//       setState(() {
//         _generationProgress = i / totalSteps;
//       });
//     }
//
//     await _increaseCount();
//     await _captureAndSaveImage();
//
//     setState(() {
//       _isGenerating = false;
//     });
//     if (_generatedImage != null) {
//       _showGeneratedImagePopup(_generatedImage!);
//       _showDownloadSuccessPopup();
//     }
//   }
//
//   Future<void> _pickBottomImage() async {
//     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _uploadedImages.add(File(pickedFile.path));
//         _selectedUploadedImage = File(pickedFile.path);
//         _selectedAssetImage = null;
//         _selectedApiImageUrl = null;
//         _updatePosition('right'); // Use the normalization logic
//         // Remove _imageContainerKey = GlobalKey(); if not used elsewhere
//       });
//     }
//   }
//
//
//   Future<void> _pickTopBanner() async {
//     final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _topBannerImage = File(pickedFile.path);
//         _selectedProtocolImageUrl = null;
//       });
//     }
//   }
//
//   Future<void> _pickFooterImage() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedLocalImage = File(pickedFile.path);
//         _selectedFooterImageUrl = null;
//       });
//     }
//   }
//
//   Future<bool> _requestStoragePermission() async {
//     if (Platform.isAndroid) {
//       final storageGranted = await Permission.storage.isGranted;
//       final photosGranted = await Permission.photos.isGranted;
//       final manageStorageGranted = await Permission.manageExternalStorage.isGranted;
//
//       if (storageGranted || photosGranted || manageStorageGranted) {
//         return true;
//       }
//
//       final statuses = await [
//         Permission.storage,
//         Permission.photos,
//         if (await Permission.manageExternalStorage.isRestricted)
//           Permission.manageExternalStorage,
//       ].request();
//
//       if (statuses.values.any((status) => status.isGranted)) {
//         return true;
//       }
//
//       bool? shouldOpenSettings = await showDialog<bool>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Permission Required'),
//           content: const Text('We need storage permissions to save your generated images.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context, false),
//               child: const Text('Deny'),
//             ),
//             TextButton(
//               onPressed: () => Navigator.pop(context, true),
//               child: const Text('Allow'),
//             ),
//           ],
//         ),
//       );
//
//       if (shouldOpenSettings == true) {
//         await openAppSettings();
//       }
//       return false;
//     }
//     return true;
//   }
//
//   Future<void> _captureAndSaveImage() async {
//     final hasPermission = await _requestStoragePermission();
//     if (!hasPermission) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Cannot save image without storage permissions')),
//       );
//       return;
//     }
//
//     try {
//       RenderRepaintBoundary boundary = _globalKey.currentContext!
//           .findRenderObject() as RenderRepaintBoundary;
//
//       final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
//       Uint8List pngBytes = byteData!.buffer.asUint8List();
//
//       final result = await PhotoManager.editor.saveImage(
//         pngBytes,
//         title: "polyposter_${DateTime.now().millisecondsSinceEpoch}",
//         filename: "polyposter_${DateTime.now().millisecondsSinceEpoch}.png",
//       );
//
//       Directory? downloadsDirectory = Platform.isAndroid
//           ? Directory('/storage/emulated/0/Download')
//           : await getApplicationDocumentsDirectory();
//
//       String fileName = 'polyposter_${DateTime.now().millisecondsSinceEpoch}.png';
//       File file = File(path.join(downloadsDirectory!.path, fileName));
//       await file.writeAsBytes(pngBytes);
//
//       if (result != null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("")),
//         );
//       }
//
//       setState(() => _generatedImage = file);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error saving image: ${e.toString()}')),
//       );
//     }
//   }
//
//   Future<Uint8List> _resizeImage(Uint8List imageBytes, int targetWidth, int targetHeight) async {
//     final image = await decodeImageFromList(imageBytes);
//     final recorder = PictureRecorder();
//     final canvas = Canvas(recorder, Rect.fromPoints(
//         Offset(0, 0), Offset(targetWidth.toDouble(), targetHeight.toDouble())));
//     final paint = Paint();
//
//     double aspectRatio = image.width / image.height;
//     double newWidth, newHeight;
//
//     if (aspectRatio > 1) {
//       newWidth = targetWidth.toDouble();
//       newHeight = targetWidth / aspectRatio;
//     } else {
//       newHeight = targetHeight.toDouble();
//       newWidth = targetHeight * aspectRatio;
//     }
//
//     canvas.drawImageRect(
//       image,
//       Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
//       Rect.fromLTWH(0, 0, newWidth, newHeight),
//       paint,
//     );
//
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(newWidth.toInt(), newHeight.toInt());
//     ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
//     return byteData!.buffer.asUint8List();
//   }
//
//   void _editText(String title, String currentValue, Function(String) onSave) {
//     TextEditingController controller = TextEditingController(text: currentValue);
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text("Edit $title"),
//           content: TextField(
//             controller: controller,
//             decoration: InputDecoration(hintText: "Enter $title"),
//           ),
//           actions: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: const Text("Cancel"),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     setState(() {
//                       onSave(controller.text);
//                     });
//                     Navigator.of(context).pop();
//                   },
//                   child: const Text("Save"),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _selectTextSize() async {
//     final double? selectedSize = await showDialog<double>(
//       context: context,
//       builder: (BuildContext context) {
//         double currentSize = _nameTextStyle.fontSize ?? 16.0;
//         return AlertDialog(
//           title: const Text('Select Text Size'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Slider(
//                     value: currentSize,
//                     min: 10.0,
//                     max: 30.0,
//                     divisions: 20,
//                     label: currentSize.round().toString(),
//                     onChanged: (double value) {
//                       setState(() {
//                         currentSize = value;
//                       });
//                     },
//                   ),
//                   Text('Current size: ${currentSize.round()}'),
//                 ],
//               );
//             },
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Apply'),
//               onPressed: () {
//                 Navigator.of(context).pop(currentSize);
//               },
//             ),
//           ],
//         );
//       },
//     );
//
//     if (selectedSize != null) {
//       setState(() {
//         _nameTextStyle = _nameTextStyle.copyWith(fontSize: selectedSize);
//         _designationTextStyle = _designationTextStyle.copyWith(fontSize: selectedSize * 0.85);
//       });
//     }
//   }
//
//   Future<void> _selectTextColorAndStyle() async {
//     Color tempNameColor = _nameTextColor;
//     Color tempDesignationColor = _designationTextColor;
//     FontWeight tempNameWeight = _nameTextStyle.fontWeight ?? FontWeight.bold;
//     FontWeight tempDesignationWeight = _designationTextStyle.fontWeight ?? FontWeight.normal;
//     FontStyle tempNameStyle = _nameTextStyle.fontStyle ?? FontStyle.normal;
//     FontStyle tempDesignationStyle = _designationTextStyle.fontStyle ?? FontStyle.normal;
//     Color tempDividerColor = _dividerColor ?? Colors.transparent;
//     Color tempContainerColor = _nameContainerColor ?? Colors.white;
//
//     final result = await showDialog<Map<String, dynamic>>(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: const Text('Text & Container Color & Style'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   ListTile(
//                     title: const Text('Container Color', style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: ColorPicker(
//                       pickerColor: tempContainerColor,
//                       onColorChanged: (color) => setState(() => tempContainerColor = color),
//                       pickerAreaHeightPercent: 0.3,
//                     ),
//                   ),
//                   const Divider(),
//                   ListTile(
//                     title: const Text('Name Color', style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: ColorPicker(
//                       pickerColor: tempNameColor,
//                       onColorChanged: (color) => setState(() => tempNameColor = color),
//                       pickerAreaHeightPercent: 0.3,
//                     ),
//                   ),
//                   ListTile(
//                     title: const Text('Designation Color', style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: ColorPicker(
//                       pickerColor: tempDesignationColor,
//                       onColorChanged: (color) => setState(() => tempDesignationColor = color),
//                       pickerAreaHeightPercent: 0.3,
//                     ),
//                   ),
//                   const Divider(),
//                   const Text('Text Styles', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ListTile(
//                     title: const Text('Name Style'),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text('Bold'),
//                         Checkbox(
//                           value: tempNameWeight == FontWeight.bold,
//                           onChanged: (value) => setState(() {
//                             tempNameWeight = value! ? FontWeight.bold : FontWeight.normal;
//                           }),
//                         ),
//                         const SizedBox(width: 20),
//                         const Text('Italic'),
//                         Checkbox(
//                           value: tempNameStyle == FontStyle.italic,
//                           onChanged: (value) => setState(() {
//                             tempNameStyle = value! ? FontStyle.italic : FontStyle.normal;
//                           }),
//                         ),
//                       ],
//                     ),
//                   ),
//                   ListTile(
//                     title: const Text('Designation Style'),
//                     trailing: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Text('Bold'),
//                         Checkbox(
//                           value: tempDesignationWeight == FontWeight.bold,
//                           onChanged: (value) => setState(() {
//                             tempDesignationWeight = value! ? FontWeight.bold : FontWeight.normal;
//                           }),
//                         ),
//                         const SizedBox(width: 20),
//                         const Text('Italic'),
//                         Checkbox(
//                           value: tempDesignationStyle == FontStyle.italic,
//                           onChanged: (value) => setState(() {
//                             tempDesignationStyle = value! ? FontStyle.italic : FontStyle.normal;
//                           }),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Divider(),
//                   ListTile(
//                     title: const Text('Divider Color', style: TextStyle(fontWeight: FontWeight.bold)),
//                     subtitle: ColorPicker(
//                       pickerColor: tempDividerColor,
//                       onColorChanged: (color) => setState(() => tempDividerColor = color),
//                       pickerAreaHeightPercent: 0.3,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(context, {
//                   'nameColor': tempNameColor,
//                   'designationColor': tempDesignationColor,
//                   'nameWeight': tempNameWeight,
//                   'designationWeight': tempDesignationWeight,
//                   'nameStyle': tempNameStyle,
//                   'designationStyle': tempDesignationStyle,
//                   'dividerColor': tempDividerColor,
//                   'containerColor': tempContainerColor,
//                 }),
//                 child: const Text('APPLY', style: TextStyle(color: Colors.green)),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//
//     if (result != null && mounted) {
//       setState(() {
//         _nameTextStyle = _nameTextStyle.copyWith(
//           color: result['nameColor'],
//           fontWeight: result['nameWeight'],
//           fontStyle: result['nameStyle'],
//         );
//         _designationTextStyle = _designationTextStyle.copyWith(
//           color: result['designationColor'],
//           fontWeight: result['designationWeight'],
//           fontStyle: result['designationStyle'],
//         );
//         _dividerColor = result['dividerColor'];
//         _nameTextColor = result['nameColor'];
//         _designationTextColor = result['designationColor'];
//         _nameContainerColor = result['containerColor'];
//       });
//     }
//   }
//
//   Future<void> _shareImage(String platform) async {
//     if (_generatedImage == null) return;
//
//     final text = 'Check out my design created with PolyPoster!';
//
//     if (platform == 'other') {
//       await Share.shareXFiles(
//         [XFile(_generatedImage!.path)],
//         text: text,
//       );
//       return;
//     }
//
//     await Share.shareXFiles(
//       [XFile(_generatedImage!.path)],
//       text: text,
//       subject: 'My PolyPoster Design',
//     );
//   }
//
//   Widget _buildApiImageBox(SelfImage image) {
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedUploadedImage = null;
//           _selectedAssetImage = null;
//           _selectedApiImageUrl = image.imageUrl;
//           _updatePosition(image.position);
//         });
//       },
//       child: Container(
//         width: 60,
//         height: 60,
//         margin: const EdgeInsets.only(right: 8),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: (_selectedApiImageUrl == image.imageUrl)
//                 ? Colors.purple.shade900
//                 : Colors.grey.shade300,
//             width: 2,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(6),
//           child: Stack(
//             children: [
//               image.imageUrl != null
//                   ? Image.network(image.imageUrl!, fit: BoxFit.cover, width: 60, height: 60)
//                   : Container(color: Colors.grey),
//               // The label widget has been removed here.
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageUploadButton() {
//     return GestureDetector(
//       onTap: _pickBottomImage,
//       child: Container(
//         width: 60,
//         height: 60,
//         decoration: BoxDecoration(
//           color: Colors.purple.shade900,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: const Icon(
//           Icons.add,
//           size: 30,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageRow() {
//     const int maxVisibleImages = 4;
//     const double imageBoxSize = 60.0;
//     const double boxSpacing = 8.0;
//     final List<SelfImage> scrollableImages = _apiSelfImages;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Your Image',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Expanded(
//               child: SizedBox(
//                 height: imageBoxSize,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: scrollableImages.length > maxVisibleImages
//                       ? scrollableImages.length
//                       : maxVisibleImages,
//                   separatorBuilder: (context, index) => SizedBox(width: boxSpacing),
//                   itemBuilder: (context, index) {
//                     if (index < scrollableImages.length) {
//                       return _buildApiImageBox(scrollableImages[index]);
//                     } else {
//                       return Container(
//                         width: imageBoxSize,
//                         height: imageBoxSize,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[200],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ),
//             SizedBox(width: boxSpacing),
//             SizedBox(
//               width: imageBoxSize,
//               height: imageBoxSize,
//               child: _buildImageUploadButton(),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget buildProtocolRow({
//     required List<ProtocolImage> protocolImages,
//     required void Function() onAdd,
//     required void Function(int index) onSelect,
//     int maxVisible = 4,
//   }) {
//     const double boxWidth = 200.0;
//     const double boxHeight = 90.0;
//     const double boxSpacing = 8.0;
//
//     final firstFourImages = protocolImages.take(maxVisible).toList();
//     final remainingImages = protocolImages.skip(maxVisible).toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "PROTOCOL",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//         ),
//         const SizedBox(height: 8),
//
//         SizedBox(
//           height: boxHeight,
//           child: Row(
//             children: [
//               Expanded(
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: [
//                     Row(
//                       children: List.generate(firstFourImages.length, (index) {
//                         return GestureDetector(
//                           onTap: () => onSelect(index),
//                           child: Container(
//                             width: boxWidth,
//                             height: boxHeight,
//                             margin: EdgeInsets.only(right: boxSpacing),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(
//                                 color: _selectedProtocolImageUrl == firstFourImages[index].imageUrl
//                                     ? Colors.purple.shade900
//                                     : Colors.transparent,
//                                 width: 2,
//                               ),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   Image.network(
//                                     firstFourImages[index].imageUrl,
//                                     fit: BoxFit.contain,
//                                     width: boxWidth,
//                                     height: boxHeight,
//                                     loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//                                       if (loadingProgress == null) return child;
//                                       return Center(
//                                         child: CircularProgressIndicator(
//                                           value: loadingProgress.expectedTotalBytes != null
//                                               ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                                               : null,
//                                         ),
//                                       );
//                                     },
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return Icon(Icons.broken_image, color: Colors.grey);
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//
//                     if (remainingImages.isNotEmpty)
//                       Row(
//                         children: List.generate(remainingImages.length, (index) {
//                           final globalIndex = maxVisible + index;
//                           return GestureDetector(
//                             onTap: () => onSelect(globalIndex),
//                             child: Container(
//                               width: boxWidth,
//                               height: boxHeight,
//                               margin: EdgeInsets.only(right: boxSpacing),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: _selectedProtocolImageUrl == remainingImages[index].imageUrl
//                                       ? Colors.purple.shade900
//                                       : Colors.transparent,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Stack(
//                                   alignment: Alignment.center,
//                                   children: [
//                                     Image.network(
//                                       remainingImages[index].imageUrl,
//                                       fit: BoxFit.cover,
//                                       width: boxWidth,
//                                       height: boxHeight,
//                                       loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
//                                         if (loadingProgress == null) return child;
//                                         return Center(
//                                           child: CircularProgressIndicator(
//                                             value: loadingProgress.expectedTotalBytes != null
//                                                 ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                                                 : null,
//                                           ),
//                                         );
//                                       },
//                                       errorBuilder: (context, error, stackTrace) {
//                                         return Icon(Icons.broken_image, color: Colors.grey);
//                                       },
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         }),
//                       ),
//
//                     if (firstFourImages.length < maxVisible)
//                       ...List.generate(maxVisible - firstFourImages.length, (index) {
//                         return Container(
//                           width: boxWidth,
//                           height: boxHeight,
//                           margin: EdgeInsets.only(right: boxSpacing),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         );
//                       }),
//                   ],
//                 ),
//               ),
//
//               GestureDetector(
//                 onTap: onAdd,
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.purple.shade900,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[400]!),
//                   ),
//                   child: const Icon(Icons.add, color: Colors.white, size: 20),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget buildFooterRow({
//     required List<FooterImage> footerImages,
//     required void Function() onAdd,
//     required void Function(int index) onSelect,
//     required String? selectedFooterImageUrl,
//   }) {
//     const double boxWidth = 200.0;
//     const double boxHeight = 90.0;
//     const double boxSpacing = 8.0;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Footer Image",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//         ),
//         const SizedBox(height: 8),
//         SizedBox(
//           height: boxHeight,
//           child: Row(
//             children: [
//               Expanded(
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: [
//                     Row(
//                       children: footerImages.isEmpty
//                           ? [
//                         Container(
//                           width: boxWidth,
//                           height: boxHeight,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[300],
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         )
//                       ]
//                           : List.generate(
//                         footerImages.length,
//                             (index) {
//                           final isSelected = selectedFooterImageUrl == footerImages[index].imageUrl;
//
//                           return GestureDetector(
//                             onTap: () => onSelect(index),
//                             child: Container(
//                               width: boxWidth,
//                               height: boxHeight,
//                               margin: EdgeInsets.only(
//                                   right: index < footerImages.length - 1
//                                       ? boxSpacing
//                                       : 0),
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[300],
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: isSelected
//                                       ? Colors.purple.shade900
//                                       : Colors.transparent,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.network(
//                                   footerImages[index].imageUrl,
//                                   fit: BoxFit.contain,
//                                   width: boxWidth,
//                                   height: boxHeight,
//                                   loadingBuilder: (context, child, progress) {
//                                     if (progress == null) return child;
//                                     return Center(
//                                       child: CircularProgressIndicator(
//                                         value: progress.expectedTotalBytes != null
//                                             ? progress.cumulativeBytesLoaded /
//                                             progress.expectedTotalBytes!
//                                             : null,
//                                       ),
//                                     );
//                                   },
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return Icon(Icons.broken_image, color: Colors.grey);
//                                   },
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(width: boxSpacing),
//               GestureDetector(
//                 onTap: onAdd,
//                 child: Container(
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     color: Colors.purple.shade900,
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: Colors.grey[400]!),
//                   ),
//                   child: const Icon(Icons.add, color: Colors.white, size: 20),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildShareButton(String imageName, String label, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.grey.shade200,
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(10),
//               child: Image.asset(
//                 'assets/images/$imageName.png',
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(label, style: const TextStyle(fontSize: 12)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildResponsiveButton(String text, VoidCallback onPressed) {
//     return ConstrainedBox(
//       constraints: const BoxConstraints(minWidth: 120), // Minimum width to maintain design
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.purple.shade900,
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//           minimumSize: const Size(120, 48), // Maintain minimum touch target
//         ),
//         onPressed: onPressed,
//         child: Text(
//           text,
//           style: const TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: SharedColors.primary,
//         title: const Text("Social Media Details", style: TextStyle(fontSize: 16, color: Colors.white)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               RepaintBoundary(
//                 key: _globalKey,
//                 child: Container(
//                   color: Colors.transparent,
//                   child: Stack(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.only(top: 0),
//                         child: LayoutBuilder(
//                           builder: (context, constraints) {
//                             return ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: Image.network(
//                                 widget.assetPath,
//                                 width: constraints.maxWidth,
//                                 fit: BoxFit.contain,
//                                 loadingBuilder: (context, child, loadingProgress) {
//                                   if (loadingProgress == null) return child;
//                                   return const Center(child: CircularProgressIndicator());
//                                 },
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return const Center(
//                                     child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
//                                   );
//                                 },
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       Positioned(
//                         top: 0,
//                         left: 1,
//                         right: 0,
//                         child: Container(
//                           height: 100,
//                           decoration: BoxDecoration(
//                             // borderRadius: BorderRadius.circular(8),
//                             color: Colors.transparent,
//                           ),
//                           child: ClipRRect(
//                             // borderRadius: BorderRadius.circular(8),
//                             child: OverflowBox(
//                               maxHeight: 100,
//                               child: _topBannerImage != null
//                                   ? Image.file(
//                                 _topBannerImage!,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                                 fit: BoxFit.cover,
//                                 alignment: Alignment.topCenter,
//                               )
//                                   : _selectedProtocolImageUrl != null
//                                   ? Image.network(
//                                 _selectedProtocolImageUrl!,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                                 fit: BoxFit.cover,
//                                 alignment: Alignment.topCenter,
//                               )
//                                   : (_adminTopBannerUrl != null && _adminTopBannerUrl!.isNotEmpty)
//                                   ? Image.network(
//                                 _adminTopBannerUrl!,
//                                 width: double.infinity,
//                                 height: double.infinity,
//                                 fit: BoxFit.cover,
//                                 alignment: Alignment.topCenter,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Image.asset(
//                                     'assets/protocalimage.png',
//                                     width: double.infinity,
//                                     height: double.infinity,
//                                     fit: BoxFit.cover,
//                                   );
//                                 },
//                               )
//                                   : Image.asset(
//                                 'assets/protocalimage.png',
//                                 width: double.infinity,
//                                 height: double.infinity,
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       Positioned(
//                         bottom: 50,
//                         right: _selectedPosition == 'right' ? 1 : null,
//                         left: _selectedPosition == 'left' ? 1 : null,
//                         child: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 300),
//                           transitionBuilder: (Widget child, Animation<double> animation) {
//                             return ScaleTransition(scale: animation, child: child);
//                           },
//                           child: Container(
//                             key: ValueKey<String>('${_selectedApiImageUrl}_${_selectedUploadedImage?.path}_$_selectedPosition'),
//                             width: 110,
//                             height: 150,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               boxShadow: [
//                                 // BoxShadow(
//                                 //   color: Colors.transparent,
//                                 //   blurRadius: 4,
//                                 //   offset: Offset(0, 2),
//                                 // ),
//                               ],
//                             ),
//                             child: Builder(
//                               builder: (context) {
//                                 if (_selectedUploadedImage != null) {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.file(
//                                       _selectedUploadedImage!,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   );
//                                 } else if (_selectedApiImageUrl != null) {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.network(
//                                       _selectedApiImageUrl!,
//                                       fit: BoxFit.cover,
//                                       loadingBuilder: (context, child, progress) {
//                                         if (progress == null) return child;
//                                         return Center(
//                                           child: CircularProgressIndicator(
//                                             value: progress.expectedTotalBytes != null
//                                                 ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
//                                                 : null,
//                                           ),
//                                         );
//                                       },
//                                       errorBuilder: (context, error, stackTrace) {
//                                         return Image.asset(
//                                           'assets/leaderimage.png',
//                                           fit: BoxFit.cover,
//                                         );
//                                       },
//                                     ),
//                                   );
//                                 } else if (_selectedAssetImage != null) {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.asset(
//                                       _selectedAssetImage!,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   );
//                                 } else if (_adminBottomImageUrl != null && _adminBottomImageUrl!.isNotEmpty) {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.network(
//                                       _adminBottomImageUrl!,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (context, error, stackTrace) {
//                                         return Image.asset(
//                                           'assets/leaderimage.png',
//                                           fit: BoxFit.cover,
//                                         );
//                                       },
//                                     ),
//                                   );
//                                 } else {
//                                   return ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.asset(
//                                       'assets/leaderimage.png',
//                                       fit: BoxFit.cover,
//                                     ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         left: 0,
//                         right: 0,
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 14,
//                             horizontal: 10,
//                           ),
//                           height: 50,
//                           decoration: BoxDecoration(
//                             color: _nameContainerColor ?? Colors.transparent,
//                             // borderRadius: BorderRadius.circular(11),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.transparent.withOpacity(0.1),
//                                 spreadRadius: 5,
//                                 blurRadius: 7,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                             image: _selectedLocalImage != null
//                                 ? DecorationImage(
//                               image: FileImage(_selectedLocalImage!),
//                               fit: BoxFit.cover,
//                             )
//                                 : _selectedFooterImageUrl != null
//                                 ? DecorationImage(
//                               image: NetworkImage(_selectedFooterImageUrl!),
//                               fit: BoxFit.cover,
//                             )
//                                 : const DecorationImage(
//                               image: AssetImage('assets/background.png'),
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                           child: LayoutBuilder(
//                             builder: (context, constraints) {
//                               double calculateFontSize(
//                                   String text,
//                                   double maxWidth,
//                                   double baseSize,
//                                   String fontFamily,
//                                   ) {
//                                 if (text.isEmpty || text == " " || text == " ") {
//                                   return baseSize;
//                                 }
//
//                                 final textLength = text.length;
//                                 double fontSize = baseSize;
//
//                                 if (textLength > 30) {
//                                   fontSize = baseSize * 0.8;
//                                 }
//                                 if (textLength > 50) {
//                                   fontSize = baseSize * 0.7;
//                                 }
//
//                                 final textPainter = TextPainter(
//                                   text: TextSpan(
//                                     text: text,
//                                     style: TextStyle(
//                                       fontSize: fontSize,
//                                       fontFamily: fontFamily,
//                                     ),
//                                   ),
//                                   maxLines: 2,
//                                   textDirection: TextDirection.ltr,
//                                 )..layout(maxWidth: maxWidth);
//
//                                 if (textPainter.didExceedMaxLines) {
//                                   fontSize = fontSize * 0.9;
//                                 }
//
//                                 return fontSize;
//                               }
//
//                               final name = _name.isEmpty ? " " : _name;
//                               final designation = _designation.isEmpty ? " " : _designation;
//
//                               double nameFontSize = calculateFontSize(
//                                 name,
//                                 constraints.maxWidth / 2 - 20,
//                                 _nameTextStyle.fontSize ?? 16,
//                                 'Ramabhadra',
//                               );
//
//                               double designationFontSize = calculateFontSize(
//                                 designation,
//                                 constraints.maxWidth / 2 - 20,
//                                 _designationTextStyle.fontSize ?? 14,
//                                 'Ramabhadra',
//                               );
//
//                               return Center(
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   crossAxisAlignment: CrossAxisAlignment.center,
//                                   children: [
//                                     Expanded(
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           _editText("Name", _name, (value) {
//                                             setState(() => _name = value);
//                                           });
//                                         },
//                                         child: Container(
//                                           alignment: Alignment.center,
//                                           child: Text(
//                                             name,
//                                             textAlign: TextAlign.center,
//                                             style: _nameTextStyle.copyWith(
//                                               color: _name.isEmpty ? Colors.grey : _nameTextColor,
//                                               fontSize: nameFontSize,
//                                               fontFamily: 'Ramabhadra',
//                                               fontWeight: _name.isEmpty ? FontWeight.normal : _nameTextStyle.fontWeight,
//                                             ),
//                                             maxLines: 2,
//                                             overflow: TextOverflow.visible,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     Container(
//                                       width: 2,
//                                       height: 40,
//                                       color: _dividerColor ?? Colors.transparent,
//                                       margin: const EdgeInsets.symmetric(horizontal: 8),
//                                     ),
//                                     Expanded(
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           _editText("Designation", _designation, (value) {
//                                             setState(() => _designation = value);
//                                           });
//                                         },
//                                         child: Container(
//                                           alignment: Alignment.center,
//                                           child: Text(
//                                             designation,
//                                             textAlign: TextAlign.center,
//                                             style: _designationTextStyle.copyWith(
//                                               color: _designation.isEmpty ? Colors.grey : _designationTextColor,
//                                               fontSize: designationFontSize,
//                                               fontFamily: 'Ramabhadra',
//                                               fontWeight: _designation.isEmpty ? FontWeight.normal : _designationTextStyle.fontWeight,
//                                             ),
//                                             maxLines: 2,
//                                             overflow: TextOverflow.visible,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               _buildImageRow(),
//               const SizedBox(height: 20),
//               const SizedBox(height: 20),
//               buildProtocolRow(
//                 protocolImages: _protocolImages,
//                 onAdd: _pickTopBanner,
//                 onSelect: (index) {
//                   setState(() {
//                     _selectedProtocolImageUrl = _protocolImages[index].imageUrl;
//                     _topBannerImage = null;
//                   });
//                 },
//               ),
//               const SizedBox(height: 20),
//               buildFooterRow(
//                 footerImages: _footerImages,
//                 onAdd: _pickFooterImage,
//                 onSelect: (index) {
//                   setState(() {
//                     _selectedFooterImageUrl = _footerImages[index].imageUrl;
//                     _selectedLocalImage = null;
//                   });
//                 },
//                 selectedFooterImageUrl: _selectedFooterImageUrl,
//               ),
//               Container(
//                 margin: const EdgeInsets.only(top: 12),
//                 child: LayoutBuilder(
//                   builder: (context, constraints) {
//                     return SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: ConstrainedBox(
//                         constraints: BoxConstraints(minWidth: constraints.maxWidth),
//                         child: Row(
//                           children: [
//                             _buildResponsiveButton(
//                               "Edit Name",
//                                   () => _editText("Name", _name, (value) => _name = value),
//                             ),
//                             const SizedBox(width: 10),
//                             _buildResponsiveButton(
//                               "Edit Designation",
//                                   () => _editText("Designation", _designation, (value) => _designation = value),
//                             ),
//                             const SizedBox(width: 10),
//                             _buildResponsiveButton("Text Size", _selectTextSize),
//                             const SizedBox(width: 10),
//                             _buildResponsiveButton("Text Color & Style", _selectTextColorAndStyle),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.purple.shade900,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   ),
//                   onPressed: _isGenerating ? null : _generateImageWithLoader,
//                   child: _isGenerating
//                       ? Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(
//                         value: _generationProgress,
//                         backgroundColor: Colors.white.withOpacity(0.3),
//                         valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                       const SizedBox(width: 10),
//                       Text(
//                         '${(_generationProgress * 100).toStringAsFixed(0)}%',
//                         style: const TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//                     ],
//                   )
//                       : const Text("Generate", style: TextStyle(fontSize: 16, color: Colors.white)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (_generatedImage != null) ...[
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey.shade300),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Image.file(
//                     _generatedImage!,
//                     width: double.infinity,
//                     fit: BoxFit.contain,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Share your design:",
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildShareButton("whatsapp", "WhatsApp", () => _shareImage('whatsapp')),
//                     _buildShareButton("instagram", "Instagram", () => _shareImage('instagram')),
//                     _buildShareButton("facebook", "Facebook", () => _shareImage('facebook')),
//                     _buildShareButton("linkedin", "LinkedIn", () => _shareImage('linkedin')),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showGeneratedImagePopup(File imageFile) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Image with rounded corners & shadow
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 8,
//                         offset: Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Image.file(
//                       imageFile,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // Share buttons with modern design
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildShareButton("whatsapp", "WhatsApp", () => _shareImage('whatsapp')),
//                     _buildShareButton("instagram", "Instagram", () => _shareImage('instagram')),
//                     _buildShareButton("facebook", "Facebook", () => _shareImage('facebook')),
//                     _buildShareButton("linkedin", "LinkedIn", () => _shareImage('linkedin')),
//                   ],
//                 ),
//
//                 const SizedBox(height: 16),
//                 // Modern close button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple.shade900,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: const Text(
//                       'Close',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//   void _showDownloadSuccessPopup() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Lottie.asset(
//                   'assets/lottie/success.json',
//                   width: 220,
//                   height: 220,
//                   repeat: true, // 👈 keep playing until OK is pressed
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "4K HD image saved to gallery and downloads!",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.purple,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.purple.shade900,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: const Text(
//                       'OK',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//
// }



import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/colors.dart';
import '../../../core/models/FooterImage.dart';
import '../../../core/models/ProtocolImage.dart';
import '../../../core/models/SelfImage.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/background_removal_service.dart';
import '../../../widgets/image_crop_dialog.dart';

// Update the constructor of SocialMediaDetailsPage
class SocialMediaDetailsPage extends StatefulWidget {
  final String assetPath;
  final String categoryId;
  final String posterId;
  final String initialPosition;
  final int? topDefNum;
  final int? selfDefNum;
  final int? bottomDefNum;

  const SocialMediaDetailsPage({
    Key? key,
    required this.assetPath,
    required this.categoryId,
    required this.posterId,
    required this.initialPosition,
    this.topDefNum,
    this.selfDefNum,
    this.bottomDefNum,
  }) : super(key: key);

  @override
  _SocialMediaDetailsPageState createState() => _SocialMediaDetailsPageState();
}

class _SocialMediaDetailsPageState extends State<SocialMediaDetailsPage> {
  static const int _maxVisibleUploads = 4;
  late int topNum;
  late int selfNum;
  late int bottomNum;

  File? _selectedImage;
  File? _topBannerImage;
  File? _generatedImage;
  String _name = " ";
  String _designation = " ";
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _globalKey = GlobalKey();
  Color? _nameContainerColor;
  Color _nameTextColor = Colors.white;
  Color _designationTextColor = Colors.white;
  Color? _dividerColor;
  bool _isLoading = true;
  String? _adminTopBannerUrl;
  String? _adminBottomImageUrl;
  String? _adminName;
  String? _adminDesignation;
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _selectedApiImageUrl;
  String? _selectedProtocolImageUrl;
  String? _selectedPosition = 'right'; // Default to right position
  int _positionVersion = 0;
  // Add these variables to your state class
  SelfImage? _selectedSelfImage;
  Set<String> _selectedSelfImageUrls = Set<String>();

  void _updatePosition(String position) {
    setState(() {
      _selectedPosition = position.trim().toLowerCase();
      _positionVersion++;
    });
  }

  List<ProtocolImage> _protocolImages = [];
  List<FooterImage> _footerImages = [];
  File? _selectedLocalImage;
  String? _selectedFooterImageUrl;
  TextStyle _nameTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.2,
    fontFamily: 'Ramabhadra',
  );
  TextStyle _designationTextStyle = const TextStyle(
    fontSize: 13,
    color: Colors.white,
    fontFamily: 'Ramabhadra',
  );
  final List<String> _defaultImagePaths = [];
  List<File> _uploadedImages = [];
  List<SelfImage> _apiSelfImages = [];
  String? _selectedAssetImage;
  File? _selectedUploadedImage;
  List<SelfImage> _filteredSelfImages = [];


  @override
  void initState() {
    super.initState();

    // Initialize with proper fallback values
    topNum = widget.topDefNum ?? 1; // Default to 1 if null
    selfNum = widget.selfDefNum ?? 1; // Default to 1 if null
    bottomNum = widget.bottomDefNum ?? 1; // Default to 1 if null

    print('Received initialPosition: ${widget.initialPosition}');
    print('Received topDefNum: $topNum');
    print('Received selfDefNum: $selfNum');
    print('Received bottomDefNum: $bottomNum');

    _fetchUserProfile();
    _loadApiSelfImages();
    _loadProtocolImages();
    _loadFooterImages();
  }




  Future<void> _loadFooterImages() async {
    try {
      final images = await ApiService().fetchFooterImages();
      setState(() {
        _footerImages = images;

        if (images.isEmpty) {
          _selectedFooterImageUrl = null;
          print('No footer images available');
          return;
        }

        // Filter based on defNum value
        if (bottomNum > 0) {
          try {
            // Find image with exact defNum match
            final matchingImage = images.firstWhere(
                  (image) => image.defNum == bottomNum,
            );
            _selectedFooterImageUrl = matchingImage.imageUrl;
            print('Selected footer image with defNum: $bottomNum');
          } catch (e) {
            // If no exact match found, use first image as fallback
            print('No footer image found with defNum $bottomNum, using first image');
            _selectedFooterImageUrl = images[0].imageUrl;
          }
        } else {
          // Use first image if no specific bottomNum requested
          _selectedFooterImageUrl = images[0].imageUrl;
          print('Using first footer image (no specific defNum requested)');
        }
      });
    } catch (e) {
      print('Error loading footer images: $e');
      setState(() {
        _selectedFooterImageUrl = null;
      });
    }
  }

  Future<void> _loadProtocolImages() async {
    try {
      final images = await ApiService().fetchProtocolImages();
      setState(() {
        _protocolImages = images;

        if (images.isEmpty) {
          _selectedProtocolImageUrl = null;
          return;
        }

        // Filter based on defNum value
        if (widget.topDefNum != null && widget.topDefNum! > 0) {
          try {
            // Find image with exact defNum match
            final matchingImage = images.firstWhere(
                  (image) => image.defNum == widget.topDefNum,
            );
            _selectedProtocolImageUrl = matchingImage.imageUrl;
          } catch (e) {
            // If no exact match found, use first image as fallback
            print('No image found with defNum ${widget.topDefNum}, using first image');
            _selectedProtocolImageUrl = images[0].imageUrl;
          }
        } else {
          // Use first image if no specific defNum requested
          _selectedProtocolImageUrl = images[0].imageUrl;
        }
      });
    } catch (e) {
      print('Error loading protocol images: $e');
      setState(() {
        _selectedProtocolImageUrl = null;
      });
    }
  }


  Future<void> _loadApiSelfImages() async {
    try {
      final images = await ApiService().fetchSelfImages();

      // Filter images based on initialPosition
      List<SelfImage> filteredImages = [];
      if (widget.initialPosition.isNotEmpty) {
        final position = widget.initialPosition.toLowerCase().trim();

        // Only filter if position is specifically 'right' or 'left'
        if (position == 'right' || position == 'left') {
          filteredImages = images.where((image) =>
          image.position.toLowerCase().trim() == position).toList();
        } else {
          // If position is defined but not 'right' or 'left', show no images
          filteredImages = [];
        }
      } else {
        // If no initialPosition defined, show all images (work as usual)
        filteredImages = images;
      }

      setState(() {
        _apiSelfImages = images;
        _filteredSelfImages = filteredImages;

        // Reset selection if no filtered images
        if (filteredImages.isEmpty) {
          _selectedSelfImage = null;
          _selectedApiImageUrl = null;
          _selectedSelfImageUrls.clear();
          return;
        }

        // Filter based on defNum value
        if (widget.selfDefNum != null && widget.selfDefNum! > 0) {
          // Find image with matching defNum or fallback to first image
          final matchingImage = filteredImages.firstWhere(
                (image) => image.defNum == widget.selfDefNum,
            orElse: () => filteredImages[0], // Fallback to first image
          );

          // Additional position check
          if (widget.initialPosition.isEmpty ||
              matchingImage.position.toLowerCase().trim() ==
                  widget.initialPosition.toLowerCase().trim()) {
            _selectedSelfImage = matchingImage;
            _selectedApiImageUrl = matchingImage.imageUrl;
            _selectedSelfImageUrls.add(matchingImage.imageUrl);
            _updatePosition(matchingImage.position);
          } else {
            _selectedSelfImage = null;
            _selectedApiImageUrl = null;
            _selectedSelfImageUrls.clear();
          }
        } else {
          // Use first image if no specific selfDefNum requested
          _selectedSelfImage = filteredImages[0];
          _selectedApiImageUrl = filteredImages[0].imageUrl;
          _selectedSelfImageUrls.add(filteredImages[0].imageUrl);
          _updatePosition(filteredImages[0].position);
        }
      });
    } catch (e) {
      print('Error loading self images: $e');
      setState(() {
        _selectedSelfImage = null;
        _selectedApiImageUrl = null;
        _selectedSelfImageUrls.clear();
        _filteredSelfImages = [];
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        'https://apiserverdata.leaderposter.com/api/v1/account/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userDetail = data['userDetail'];

        setState(() {
          _adminTopBannerUrl = userDetail['top'];
          _adminBottomImageUrl = userDetail['profile'];
          _adminName = userDetail['adminAssignName'];
          _adminDesignation = userDetail['designation'];

          // Only use admin footer image if bottomDefNum is not specified (0 or negative)
          if (widget.bottomDefNum == null || widget.bottomDefNum! <= 0) {
            _selectedFooterImageUrl = userDetail["bottom"];
          }

          if (_adminName != null && _adminName!.isNotEmpty) {
            _name = _adminName!;
          }
          if (_adminDesignation != null && _adminDesignation!.isNotEmpty) {
            _designation = _adminDesignation!;
          }

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _increaseCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token')?.trim();

      if (token == null || token.isEmpty) {
        print('❌ Authentication token missing or empty');
        return;
      }

      if (widget.categoryId.isEmpty || widget.posterId.isEmpty) {
        print('❌ Missing required IDs - Category: ${widget.categoryId}, Poster: ${widget.posterId}');
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: 'https://apiserverdata.leaderposter.com/api/v1/',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ));

      dio.interceptors.add(LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
      ));

      print('📤 Making POST request to increase count');
      print('   Category ID: ${widget.categoryId}');
      print('   Poster ID: ${widget.posterId}');
      print('   Token prefix: ${token.substring(0, 8)}...');

      final response = await dio.post(
        'category/increase-count',
        queryParameters: {
          'categoryId': widget.categoryId,
          'posterId': widget.posterId,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Count increased successfully! Response: ${response.data}');
      } else {
        print('⚠️ Unexpected response: ${response.statusCode}');
        print('   Response data: ${response.data}');
      }
    } on DioException catch (e) {
      print('🔥 Dio Error: ${e.type}');
      print('   Message: ${e.message}');

      if (e.response != null) {
        print('   Status: ${e.response?.statusCode}');
        print('   Data: ${e.response?.data}');
        print('   Headers: ${e.response?.headers}');
      }
    } catch (e) {
      print('💥 Unexpected error: $e');
    }
  }

  Future<void> _generateImageWithLoader() async {
    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
    });

    const totalSteps = 10;
    for (int i = 1; i <= totalSteps; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _generationProgress = i / totalSteps;
      });
    }

    await _increaseCount();
    await _captureAndSaveImage();

    setState(() {
      _isGenerating = false;
    });
    if (_generatedImage != null) {
      _showGeneratedImagePopup(_generatedImage!);
      _showDownloadSuccessPopup();
    }
  }

  // Update the image upload method to clear selections
  // Also update the existing _pickBottomImage method to maintain consistency
  Future<void> _pickBottomImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _uploadedImages.add(File(pickedFile.path));
        _selectedUploadedImage = File(pickedFile.path);
        _selectedAssetImage = null;
        _selectedApiImageUrl = null;
        _selectedSelfImageUrls.clear();
        _selectedSelfImage = null;
        _updatePosition('right');
      });
    }
  }

// Remove the upload button method since it's no longer needed
// Delete or comment out the _buildImageUploadButton() method


  // Future<void> _pickTopBanner() async {
  //   final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  //   if (pickedFile != null) {
  //     setState(() {
  //       _topBannerImage = File(pickedFile.path);
  //       _selectedProtocolImageUrl = null;
  //     });
  //   }
  // }

  Future<void> _pickFooterImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedLocalImage = File(pickedFile.path);
        _selectedFooterImageUrl = null;
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
            content: const Text('We need photos permission to save your generated images to gallery.'),
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

  Future<void> _captureAndSaveImage({bool shareToWhatsApp = false}) async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save image without storage permissions')),
      );
      return;
    }

    try {
      // Get the widget's render boundary
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      // Calculate optimal pixel ratio based on device screen size
      final pixelRatio = MediaQuery.of(context).devicePixelRatio * 6;
      debugPrint('Using pixel ratio: $pixelRatio');

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      debugPrint('Original image dimensions: ${image.width}x${image.height}');

      // Convert to PNG bytes
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to gallery
      final galleryResult = await PhotoManager.editor.saveImage(
        pngBytes,
        title: "leaderposter_${DateTime.now().millisecondsSinceEpoch}",
        filename: "leaderposter_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      // Save to downloads directory
      Directory? downloadsDirectory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      String fileName = 'leaderposter_${DateTime.now().millisecondsSinceEpoch}.png';
      File file = File(path.join(downloadsDirectory!.path, fileName));
      await file.writeAsBytes(pngBytes);

      // Update state with generated image
      setState(() => _generatedImage = file);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(galleryResult != null
              ? 'Image saved to gallery and downloads'
              : 'Image saved to downloads only'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _shareImageToWhatsApp(file),
          ),
        ),
      );

      // Optionally share directly to WhatsApp
      if (shareToWhatsApp) {
        await _shareImageToWhatsApp(file);
      }

    } catch (e, stackTrace) {
      debugPrint('Error capturing image: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving image: ${e.toString()}')),
      );
    }
  }

  Future<void> _shareImageToWhatsApp(File imageFile) async {
    try {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        // text: 'Check out this PolyPoster!',
        // subject: 'PolyPoster Image',
        sharePositionOrigin: Rect.fromPoints(
          Offset.zero,
          Offset(MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height / 2),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: ${e.toString()}')),
      );
    }
  }

  Future<Uint8List> _resizeImage(Uint8List imageBytes, int targetWidth, int targetHeight) async {
    final image = await decodeImageFromList(imageBytes);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromPoints(
        Offset(0, 0), Offset(targetWidth.toDouble(), targetHeight.toDouble())));
    final paint = Paint();

    double aspectRatio = image.width / image.height;
    double newWidth, newHeight;

    if (aspectRatio > 1) {
      newWidth = targetWidth.toDouble();
      newHeight = targetWidth / aspectRatio;
    } else {
      newHeight = targetHeight.toDouble();
      newWidth = targetHeight * aspectRatio;
    }

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth, newHeight),
      paint,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(newWidth.toInt(), newHeight.toInt());
    ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

  Future<void> _selectTextSize() async {
    final double? selectedSize = await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        double currentSize = _nameTextStyle.fontSize ?? 16.0;
        return AlertDialog(
          title: const Text('Select Text Size'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: currentSize,
                    min: 10.0,
                    max: 30.0,
                    divisions: 20,
                    label: currentSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        currentSize = value;
                      });
                    },
                  ),
                  Text('Current size: ${currentSize.round()}'),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                Navigator.of(context).pop(currentSize);
              },
            ),
          ],
        );
      },
    );

    if (selectedSize != null) {
      setState(() {
        _nameTextStyle = _nameTextStyle.copyWith(fontSize: selectedSize);
        _designationTextStyle = _designationTextStyle.copyWith(fontSize: selectedSize * 0.85);
      });
    }
  }

  Future<void> _selectTextColorAndStyle() async {
    Color tempNameColor = _nameTextColor;
    Color tempDesignationColor = _designationTextColor;
    FontWeight tempNameWeight = _nameTextStyle.fontWeight ?? FontWeight.bold;
    FontWeight tempDesignationWeight = _designationTextStyle.fontWeight ?? FontWeight.normal;
    FontStyle tempNameStyle = _nameTextStyle.fontStyle ?? FontStyle.normal;
    FontStyle tempDesignationStyle = _designationTextStyle.fontStyle ?? FontStyle.normal;
    Color tempDividerColor = _dividerColor ?? Colors.transparent;
    Color tempContainerColor = _nameContainerColor ?? Colors.white;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Text & Container Color & Style'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Container Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: ColorPicker(
                      pickerColor: tempContainerColor,
                      onColorChanged: (color) => setState(() => tempContainerColor = color),
                      pickerAreaHeightPercent: 0.3,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Name Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: ColorPicker(
                      pickerColor: tempNameColor,
                      onColorChanged: (color) => setState(() => tempNameColor = color),
                      pickerAreaHeightPercent: 0.3,
                    ),
                  ),
                  ListTile(
                    title: const Text('Designation Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: ColorPicker(
                      pickerColor: tempDesignationColor,
                      onColorChanged: (color) => setState(() => tempDesignationColor = color),
                      pickerAreaHeightPercent: 0.3,
                    ),
                  ),
                  const Divider(),
                  const Text('Text Styles', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    title: const Text('Name Style'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Bold'),
                        Checkbox(
                          value: tempNameWeight == FontWeight.bold,
                          onChanged: (value) => setState(() {
                            tempNameWeight = value! ? FontWeight.bold : FontWeight.normal;
                          }),
                        ),
                        const SizedBox(width: 20),
                        const Text('Italic'),
                        Checkbox(
                          value: tempNameStyle == FontStyle.italic,
                          onChanged: (value) => setState(() {
                            tempNameStyle = value! ? FontStyle.italic : FontStyle.normal;
                          }),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Designation Style'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Bold'),
                        Checkbox(
                          value: tempDesignationWeight == FontWeight.bold,
                          onChanged: (value) => setState(() {
                            tempDesignationWeight = value! ? FontWeight.bold : FontWeight.normal;
                          }),
                        ),
                        const SizedBox(width: 20),
                        const Text('Italic'),
                        Checkbox(
                          value: tempDesignationStyle == FontStyle.italic,
                          onChanged: (value) => setState(() {
                            tempDesignationStyle = value! ? FontStyle.italic : FontStyle.normal;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Divider Color', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: ColorPicker(
                      pickerColor: tempDividerColor,
                      onColorChanged: (color) => setState(() => tempDividerColor = color),
                      pickerAreaHeightPercent: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'nameColor': tempNameColor,
                  'designationColor': tempDesignationColor,
                  'nameWeight': tempNameWeight,
                  'designationWeight': tempDesignationWeight,
                  'nameStyle': tempNameStyle,
                  'designationStyle': tempDesignationStyle,
                  'dividerColor': tempDividerColor,
                  'containerColor': tempContainerColor,
                }),
                child: const Text('APPLY', style: TextStyle(color: Colors.green)),
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _nameTextStyle = _nameTextStyle.copyWith(
          color: result['nameColor'],
          fontWeight: result['nameWeight'],
          fontStyle: result['nameStyle'],
        );
        _designationTextStyle = _designationTextStyle.copyWith(
          color: result['designationColor'],
          fontWeight: result['designationWeight'],
          fontStyle: result['designationStyle'],
        );
        _dividerColor = result['dividerColor'];
        _nameTextColor = result['nameColor'];
        _designationTextColor = result['designationColor'];
        _nameContainerColor = result['containerColor'];
      });
    }
  }

  Future<void> _shareImage(String platform) async {
    if (_generatedImage == null) return;

    final text = ' ';

    if (platform == 'other') {
      await Share.shareXFiles(
        [XFile(_generatedImage!.path)],
        text: text,
      );
      return;
    }

    await Share.shareXFiles(
      [XFile(_generatedImage!.path)],
      text: text,
      subject: 'My leaderposter Design',
    );
  }

  Widget _buildApiImageBox(SelfImage image) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUploadedImage = null;
          _selectedAssetImage = null;
          _selectedApiImageUrl = image.imageUrl;
          _updatePosition(image.position);
        });
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (_selectedApiImageUrl == image.imageUrl)
                ? SharedColors.primaryDark
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              image.imageUrl != null
                  ? Image.network(image.imageUrl!, fit: BoxFit.cover, width: 60, height: 60)
                  : Container(color: Colors.grey),
              // The label widget has been removed here.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadButton() {
    return GestureDetector(
      onTap: _pickBottomImage,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: SharedColors.primaryDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }

  // Add this to your state class to track selected images
  // Set<String> _selectedImages = Set<String>();
// Update the _buildImageRow method
  Widget _buildImageRow() {
    const double imageBoxSize = 60.0;
    const double boxSpacing = 8.0;
    
    // Combine backend images first, then uploaded images
    final List<dynamic> allImages = [
      ..._filteredSelfImages,
      ..._uploadedImages,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: imageBoxSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allImages.length + 1, // +1 for the plus icon
            separatorBuilder: (context, index) => SizedBox(width: boxSpacing),
            itemBuilder: (context, index) {
              // Last item is the plus icon
              if (index == allImages.length) {
                return _buildPlusIcon();
              }

              final item = allImages[index];
              final isBackendImage = item is SelfImage;
              final isSelected = isBackendImage
                  ? _selectedSelfImageUrls.contains(item.imageUrl)
                  : _selectedUploadedImage?.path == (item as File).path;

              return GestureDetector(
                onTap: () {
                  if (isBackendImage) {
                    final image = item as SelfImage;
                    if (isSelected) {
                      setState(() {
                        _selectedSelfImageUrls.remove(image.imageUrl);
                        _selectedSelfImage = null;
                        _selectedApiImageUrl = null;
                      });
                    } else {
                      setState(() {
                        _selectedSelfImageUrls.clear();
                        _selectedSelfImageUrls.add(image.imageUrl);
                        _selectedSelfImage = image;
                        _selectedApiImageUrl = image.imageUrl;
                        _selectedUploadedImage = null;
                        _selectedAssetImage = null;
                        _updatePosition(image.position);
                      });
                    }
                  } else {
                    final file = item as File;
                    if (isSelected) {
                      setState(() {
                        _selectedUploadedImage = null;
                      });
                    } else {
                      setState(() {
                        _selectedUploadedImage = file;
                        _selectedAssetImage = null;
                        _selectedApiImageUrl = null;
                        _selectedSelfImageUrls.clear();
                        _selectedSelfImage = null;
                        _updatePosition('right');
                      });
                    }
                  }
                },
                child: Container(
                  width: imageBoxSize,
                  height: imageBoxSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? SharedColors.primaryDark
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        // Image display
                        if (isBackendImage)
                          Image.network(
                            (item as SelfImage).imageUrl,
                            fit: BoxFit.cover,
                            width: imageBoxSize,
                            height: imageBoxSize,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey,
                                child: Icon(Icons.broken_image, color: Colors.white),
                              );
                            },
                          )
                        else
                          Image.file(
                            item as File,
                            fit: BoxFit.cover,
                            width: imageBoxSize,
                            height: imageBoxSize,
                          ),
                        
                        // Selection checkmark
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: SharedColors.primaryDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        
                        // Delete icon for uploaded images only
                        if (!isBackendImage)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  final file = item as File;
                                  _uploadedImages.remove(file);
                                  if (_selectedUploadedImage?.path == file.path) {
                                    _selectedUploadedImage = null;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

// Add this method to build the plus icon
  Widget _buildPlusIcon() {
    return GestureDetector(
      onTap: _pickAndAddImage,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }


// Update the image picker method to handle adding to the list
  Future<void> _pickAndAddImage() async {
    // Show info dialog first
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Upload Image',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Please upload images with a plain background for better results.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'మంచి ఫలితాల కోసం ప్లేన్ బ్యాక్‌గ్రౌండ్ ఉన్న ఫోటోలను అప్లోడ్ చేయండి.',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SharedColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );


    // If user cancelled, return early
    if (shouldProceed != true) return;

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Show attractive loading dialog
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

      // Remove background
      final processedImage = await BackgroundRemovalService.removeBackground(File(pickedFile.path));

      // Close loading dialog
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

      // Open crop dialog
      final croppedFile = await showDialog<File?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImageCropDialog(imageFile: imageToUse),
      );

      // Add to list if user confirmed crop
      if (croppedFile != null) {
        setState(() {
          _uploadedImages.add(croppedFile);
          _selectedUploadedImage = croppedFile;
          _selectedAssetImage = null;
          _selectedApiImageUrl = null;
          _selectedSelfImageUrls.clear();
          _selectedSelfImage = null;
          _updatePosition('right');
        });
      }
    }
  }



// Remove the old _buildImageUploadButton method since we're replacing it with the plus icon
// Delete or comment out: Widget _buildImageUploadButton() { ... }
  Widget buildProtocolRow({
    required List<ProtocolImage> protocolImages,
    // required void Function() onAdd,
    required void Function(int index) onSelect,
    int maxVisible = 0,
  }) {
    const double boxWidth = 200.0;
    const double boxHeight = 50.0;
    const double boxSpacing = 8.0;

    final visibleImages = maxVisible > 0
        ? protocolImages.take(maxVisible).toList()
        : protocolImages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Protocol",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: boxHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...List.generate(visibleImages.length, (index) {
                final image = visibleImages[index];
                final isSelected =
                    _selectedProtocolImageUrl == image.imageUrl;

                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      onSelect(-1);
                    } else {
                      onSelect(index);
                    }
                  },
                  child: Container(
                    width: boxWidth,
                    height: boxHeight,
                    margin: EdgeInsets.only(right: boxSpacing),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? SharedColors.primaryDark
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            image.imageUrl,
                            fit: BoxFit.contain,
                            width: boxWidth,
                            height: boxHeight,
                            loadingBuilder: (BuildContext context, Widget child,
                                ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                      null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, color: Colors.grey);
                            },
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: SharedColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Add button at the end
              // GestureDetector(
              //   onTap: onAdd,
              //   child: Container(
              //     width: 60,
              //     height: 60,
              //     decoration: BoxDecoration(
              //       color: Colors.grey,
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.grey[400]!),
              //     ),
              //     child: const Icon(Icons.add, color: Colors.white, size: 20),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }


// Update your onSelect handler to handle deselection:

  Widget buildFooterRow({
    required List<FooterImage> footerImages,
    // required void Function() onAdd,
    required void Function(int index) onSelect,
    required String? selectedFooterImageUrl,
  }) {
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
        SizedBox(
          height: boxHeight,
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Row(
                      children: footerImages.isEmpty
                          ? [
                        Container(
                          width: boxWidth,
                          height: boxHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        )
                      ]
                          : List.generate(
                        footerImages.length,
                            (index) {
                          final isSelected = selectedFooterImageUrl == footerImages[index].imageUrl;

                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                onSelect(-1); // Deselect if already selected
                              } else {
                                onSelect(index);
                              }
                            },
                            child: Container(
                              width: boxWidth,
                              height: boxHeight,
                              margin: EdgeInsets.only(
                                right: index < footerImages.length - 1 ? boxSpacing : 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? SharedColors.primaryDark
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),

                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      footerImages[index].imageUrl,
                                      fit: BoxFit.contain,
                                      width: boxWidth,
                                      height: boxHeight,
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: progress.expectedTotalBytes != null
                                                ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.broken_image, color: Colors.grey);
                                      },
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: SharedColors.primaryDark,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: boxSpacing),
              // GestureDetector(
              //   // onTap: onAdd,
              //   child: Container(
              //     width: 60,
              //     height: 60,
              //     decoration: BoxDecoration(
              //       color: Colors.grey,
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(color: Colors.grey[400]!),
              //     ),
              //     child: const Icon(Icons.add, color: Colors.white, size: 20),
              //   ),
              // ),
            ],
          ),
        ),
      ],
    );
  }

// Update your onSelect handler to handle deselection:


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
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildResponsiveButton(String text, VoidCallback onPressed) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150), // Minimum width to maintain design
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: SharedColors.primaryDark,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(120, 48), // Maintain minimum touch target
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: SharedColors.primary,
        title: const Text("Social Media Details",
            style: TextStyle(fontSize: 16, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: FutureBuilder<ui.Image>(
                  future: _loadImageDimensions(widget.assetPath),
                  builder: (context, snapshot) {
                    final double maxWidth = MediaQuery
                        .of(context)
                        .size
                        .width - 40;
                    final double defaultAspectRatio = 5 / 5.6;
                    double canvasHeight = maxWidth / defaultAspectRatio;

                    if (snapshot.hasData) {
                      final image = snapshot.data!;
                      final imageAspectRatio = image.width / image.height;
                      canvasHeight = maxWidth / imageAspectRatio;
                    }

                    final double protocolHeight = canvasHeight * 0.50;
                    final double profileImgHeight = canvasHeight * 0.40;
                    final double profileImgWidth = profileImgHeight * 0.9;
                    final double footerHeight = canvasHeight * 0.10;

                    return Container(
                      width: maxWidth,
                      height: canvasHeight,
                      color: Colors.transparent,
                      child: Stack(
                        children: [
                          // Background Image
                          Container(
                            padding: const EdgeInsets.only(top: 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(0),
                              child: Image.network(
                                widget.assetPath,
                                width: maxWidth,
                                height: canvasHeight,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child,
                                    loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.broken_image, size: 50,
                                        color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Protocol / Top Banner
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: protocolHeight,
                            child: OverflowBox(
                              maxHeight: protocolHeight,
                              child: _topBannerImage != null
                                  ? Image.file(
                                _topBannerImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                              )
                                  : _selectedProtocolImageUrl != null
                                  ? Image.network(
                                _selectedProtocolImageUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                              )
                                  : (_adminTopBannerUrl != null &&
                                  _adminTopBannerUrl!.isNotEmpty)
                                  ? Image.network(
                                _adminTopBannerUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container();
                                },
                              )
                                  : Container(),
                            ),
                          ),

                          // Profile Image
                          Positioned(
                            bottom: footerHeight + 0,
                            right: _selectedPosition == 'right' ? 0 : null,
                            left: _selectedPosition == 'left' ? 0 : null,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (Widget child,
                                  Animation<double> animation) {
                                return ScaleTransition(
                                    scale: animation, child: child);
                              },
                              child: Container(
                                key: ValueKey<String>(
                                  '${_selectedApiImageUrl}_${_selectedUploadedImage
                                      ?.path}_$_selectedPosition',
                                ),
                                width: profileImgWidth,
                                height: profileImgHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    if (_selectedUploadedImage != null) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedUploadedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    } else if (_selectedApiImageUrl != null) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(0),
                                        child: Image.network(
                                          _selectedApiImageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              progress) {
                                            if (progress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value: progress
                                                    .expectedTotalBytes != null
                                                    ? progress
                                                    .cumulativeBytesLoaded /
                                                    progress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container();
                                          },
                                        ),
                                      );
                                    } else if (_adminBottomImageUrl != null &&
                                        _adminBottomImageUrl!.isNotEmpty) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          _adminBottomImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error,
                                              stackTrace) {
                                            return Container();
                                          },
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                          // Footer Container - UPDATED
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              height: footerHeight,
                              decoration: BoxDecoration(
                                color: _nameContainerColor ??
                                    Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(0),
                                  bottomRight: Radius.circular(0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.transparent,
                                    spreadRadius: 5,
                                    blurRadius: 7,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                                image: _selectedLocalImage != null
                                    ? DecorationImage(
                                  image: FileImage(_selectedLocalImage!),
                                  fit: BoxFit.fill,
                                  // Changed to fill to eliminate spaces
                                  alignment: Alignment.bottomCenter,
                                )
                                    : _selectedFooterImageUrl != null
                                    ? DecorationImage(
                                  image: NetworkImage(_selectedFooterImageUrl!),
                                  fit: BoxFit.fill,
                                  // Changed to fill to eliminate spaces
                                  alignment: Alignment.bottomCenter,
                                )
                                    : const DecorationImage(
                                  image: AssetImage('assets/background.png'),
                                  fit: BoxFit.fill,
                                  // Changed to fill to eliminate spaces
                                  alignment: Alignment.bottomCenter,
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double calculateFontSize(String text,
                                      double maxWidth, double baseSize,
                                      String fontFamily) {
                                    if (text
                                        .trim()
                                        .isEmpty) return baseSize;
                                    final textLength = text.length;
                                    double fontSize = baseSize;
                                    if (textLength > 30)
                                      fontSize = baseSize * 0.8;
                                    if (textLength > 50)
                                      fontSize = baseSize * 0.7;
                                    final textPainter = TextPainter(
                                      text: TextSpan(text: text,
                                          style: TextStyle(fontSize: fontSize,
                                              fontFamily: fontFamily)),
                                      maxLines: 2,
                                      textDirection: TextDirection.ltr,
                                    )
                                      ..layout(maxWidth: maxWidth);
                                    if (textPainter.didExceedMaxLines)
                                      fontSize *= 0.9;
                                    return fontSize;
                                  }

                                  final double halfWidth = (constraints
                                      .maxWidth / 2) - 20;
                                  final nameFontSize = calculateFontSize(
                                      _name, halfWidth,
                                      _nameTextStyle.fontSize ?? 16,
                                      'Ramabhadra');
                                  final designationFontSize = calculateFontSize(
                                      _designation, halfWidth,
                                      _designationTextStyle.fontSize ?? 14,
                                      'Ramabhadra');

                                  final nameToShow = _name.isEmpty
                                      ? " "
                                      : _name;
                                  final designationToShow = _designation.isEmpty
                                      ? " "
                                      : _designation;

                                  return Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .center,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _editText(
                                                    "Name", _name, (val) =>
                                                    setState(() => _name = val)),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                nameToShow,
                                                textAlign: TextAlign.center,
                                                style: _nameTextStyle.copyWith(
                                                  color: _name.isEmpty ? Colors
                                                      .grey : _nameTextColor,
                                                  fontSize: nameFontSize,
                                                  fontFamily: 'Ramabhadra',
                                                  fontWeight: _name.isEmpty
                                                      ? FontWeight.normal
                                                      : _nameTextStyle
                                                      .fontWeight,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 2,
                                          height: footerHeight * 0.7,
                                          color: _dividerColor ??
                                              Colors.transparent,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _editText(
                                                    "Designation", _designation, (
                                                    val) =>
                                                    setState(() =>
                                                    _designation = val)),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: Text(
                                                designationToShow,
                                                textAlign: TextAlign.center,
                                                style: _designationTextStyle
                                                    .copyWith(
                                                  color: _designation.isEmpty
                                                      ? Colors.grey
                                                      : _designationTextColor,
                                                  fontSize: designationFontSize,
                                                  fontFamily: 'Ramabhadra',
                                                  fontWeight: _designation
                                                      .isEmpty
                                                      ? FontWeight.normal
                                                      : _designationTextStyle
                                                      .fontWeight,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 0),
              _buildImageRow(),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              buildProtocolRow(
                protocolImages: _protocolImages,
                // onAdd: _pickTopBanner,
                onSelect: (index) {
                  setState(() {
                    if (index == -1) {
                      _selectedProtocolImageUrl = null;
                    } else {
                      _selectedProtocolImageUrl =
                          _protocolImages[index].imageUrl;
                    }
                    _topBannerImage = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              buildFooterRow(
                footerImages: _footerImages,
                // onAdd: _pickFooterImage,
                onSelect: (index) {
                  setState(() {
                    if (index == -1) {
                      _selectedFooterImageUrl = null;
                    } else {
                      _selectedFooterImageUrl = _footerImages[index].imageUrl;
                    }
                    _selectedLocalImage = null;
                  });
                },
                selectedFooterImageUrl: _selectedFooterImageUrl,
              ),
              // Container(
              //   margin: const EdgeInsets.only(top: 12),
              //   child: LayoutBuilder(
              //     builder: (context, constraints) {
              //       return SingleChildScrollView(
              //         scrollDirection: Axis.horizontal,
              //         child: ConstrainedBox(
              //           constraints: BoxConstraints(minWidth: constraints
              //               .maxWidth),
              //           child: Row(
              //             children: [
              //               _buildResponsiveButton(
              //                 "Edit Name",
              //                     () => _editText("Name", _name, (value) => _name = value),
              //               ),
              //               const SizedBox(width: 10),
              //               _buildResponsiveButton(
              //                 "Edit Designation",
              //                     () => _editText("Designation", _designation, (value) => _designation = value),
              //               ),
              //               const SizedBox(width: 10),
              //               _buildResponsiveButton("Text Size", _selectTextSize),
              //               const SizedBox(width: 10),
              //               _buildResponsiveButton("Text Color & Style", _selectTextColorAndStyle),
              //             ],
              //           ),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SharedColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isGenerating ? null : _generateImageWithLoader,
                  child: _isGenerating
                      ? const Text("Your image is generating...",
                      style: TextStyle(fontSize: 16, color: Colors.white))
                      : const Text("Generate",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              if (_generatedImage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(
                    _generatedImage!,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Share your design:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton(
                        "whatsapp", "WhatsApp", () => _shareImage('whatsapp')),
                    _buildShareButton("instagram", "Instagram", () =>
                        _shareImage('instagram')),
                    _buildShareButton(
                        "facebook", "Facebook", () => _shareImage('facebook')),
                    _buildShareButton("x", "X", () => _shareImage('x')),
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

  void _showGeneratedImagePopup(File imageFile) {
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
                // Image with rounded corners & shadow
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Share buttons with modern design
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton("whatsapp", "WhatsApp", () => _shareImage('whatsapp')),
                    _buildShareButton("instagram", "Instagram", () => _shareImage('instagram')),
                    _buildShareButton("facebook", "Facebook", () => _shareImage('facebook')),
                    _buildShareButton("x", "X", () => _shareImage('x')),

                  ],
                ),

                const SizedBox(height: 16),
                // Modern close button
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
                      'Close',
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
                  repeat: true, // 👈 keep playing until OK is pressed
                ),
                const SizedBox(height: 12),
                const Text(
                  "4K HD image saved to gallery and downloads!",
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
  Future<ui.Image> _loadImageDimensions(String imageUrl) async {
    final completer = Completer<ui.Image>();
    final imageStream = NetworkImage(imageUrl).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((ImageInfo info, bool _) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    });
    imageStream.addListener(listener);
    return completer.future.whenComplete(() => imageStream.removeListener(listener));
  }

}
