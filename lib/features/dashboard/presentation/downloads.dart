import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/network/local_storage.dart';
import '../../../core/utils/error_handler.dart';
import '../../category/presentation/edit_banner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FileSelectionScreen(),
    );
  }
}

class FileSelectionScreen extends StatefulWidget {
  @override
  _FileSelectionScreenState createState() => _FileSelectionScreenState();
}

class _FileSelectionScreenState extends State<FileSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
//   int? selectedIndex;
//   List<Map<String, dynamic>> banners = []; // Changed to store full poster data
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchBanners();
//   }
//
//   Future<void> fetchBanners() async {
//     print('Downloads - fetchBanners called');
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       String? token = await getToken();
//       if (token == null) {
//         print('Downloads - No token found');
//         setState(() => isLoading = false);
//         showErrorPopup(context, "User token not found.", fetchBanners);
//         return;
//       }
//
//       print('Downloads - Making API call');
//       Dio dio = Dio(BaseOptions(headers: {'Authorization': 'Bearer $token'}));
//       final response = await dio.get(
//         "https://apiserverdata.leaderposter.com/api/v1/poster/search",
//         queryParameters: {"limit": 10, "offset": 0},
//       );
//
//       print('Downloads - API call successful');
//       List<dynamic> results = response.data["result"];
//       setState(() {
//         banners = results.map((poster) => {
//           "posterUrl": poster["poster"].toString(),
//           "id": poster["id"].toString(),
//           "categoryId": poster["categoryId"]?.toString() ?? "",
//           "position": poster["position"]?.toString() ?? "RIGHT",
//           "topDefNum": poster["topDefNum"],
//           "selfDefNum": poster["selfDefNum"],
//           "bottomDefNum": poster["bottomDefNum"],
//         }).toList();
//         isLoading = false;
//       });
//
//       if (banners.isEmpty) {
//         print('Downloads - No banners available');
//         showErrorPopup(context, "No banners available.", fetchBanners);
//       }
//     } on DioException catch (e) {
//       print('Downloads - DioException caught');
//       setState(() => isLoading = false);
//
//       // If it's a 401 error, just show empty state without popup
//       if (e.response?.statusCode == 401) {
//         print('Downloads - 401 error, showing empty state');
//         setState(() {
//           banners = [];
//         });
//         return;
//       }
//
//       final errorMsg = await ErrorHandler.getErrorMessage(e);
//       print('Downloads - Error message: $errorMsg');
//       showErrorPopup(context, errorMsg, fetchBanners);
//     } catch (e) {
//       print('Downloads - General exception: $e');
//       setState(() => isLoading = false);
//       showErrorPopup(context, "An error occurred. Please try again.", fetchBanners);
//     }
//   }
//
//   // Helper method to safely parse integers from dynamic values
//   int? _parseIntSafely(dynamic value) {
//     if (value == null) return null;
//     if (value is int) return value;
//     if (value is String) return int.tryParse(value);
//     return null;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: isLoading
//             ? CircularProgressIndicator()
//             : Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: GridView.builder(
//             itemCount: banners.length,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               crossAxisSpacing: 10,
//               mainAxisSpacing: 10,
//               childAspectRatio: 1,
//             ),
//             itemBuilder: (context, index) {
//               bool isSelected = selectedIndex == index;
//               final poster = banners[index];
//
//               return GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedIndex = index;
//                   });
//
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => SocialMediaDetailsPage(
//                         assetPath: poster["posterUrl"],
//                         categoryId: poster["categoryId"],
//                         posterId: poster["id"],
//                         // Add the missing fields here
//                         initialPosition: poster["position"] ?? "RIGHT",
//                         topDefNum: _parseIntSafely(poster["topDefNum"]),
//                         selfDefNum: _parseIntSafely(poster["selfDefNum"]),
//                         bottomDefNum: _parseIntSafely(poster["bottomDefNum"]),
//                       ),
//                     ),
//                   );
//                 },
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 5,
//                         spreadRadius: 2,
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.network(
//                       poster["posterUrl"],
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) =>
//                           Icon(Icons.broken_image, size: 50, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// void showErrorPopup(BuildContext context, String message, VoidCallback onRetry) {
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         backgroundColor: Colors.white,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Error Icon
//               Image.asset(
//                 'assets/images/error_icon.png', // Replace with your local asset
//                 height: 80,
//                 width: 80,
//                 color: Colors.red, // Ensure it's red as per your design
//               ),
//               SizedBox(height: 15),
//
//               // Main Message
//               Text(
//                 "PLEASE TRY AGAIN",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black,
//                   letterSpacing: 1.0,
//                 ),
//               ),
//               SizedBox(height: 10),
//
//               // Subtext Message
//               Text(
//                 message,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.black54),
//               ),
//               SizedBox(height: 25),
//
//               // Try Again Button
//               SizedBox(
//                 width: double.infinity, // Full width button
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop(); // Close popup
//                     onRetry(); // Retry fetching data
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                     padding: EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontSize: 16)),
//                 ),
//               ),
//               SizedBox(height: 15),
//             ],
//           ),
//         ),
//       );
//     },
//   );
}