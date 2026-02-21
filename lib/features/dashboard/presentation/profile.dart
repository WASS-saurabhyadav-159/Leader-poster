import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';
import '../../../screens/SubscriptionHistoryPage.dart';
import '../../auth/presentation/login.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/error_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'PageContentScreen .dart';
import 'SuggestionPage.dart';
import 'editprofilenamepage.dart' hide SharedColors;

final Logger logger = Logger(); // Initialize the logger

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileWithRetry();
  }

  Future<Map<String, dynamic>?> _fetchProfile() async {
    try {
      return await ApiService().getProfile();
    } catch (e) {
      logger.e("Profile fetch error: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchProfileWithRetry() async {
    try {
      final result = await _fetchProfile();
      return result;
    } catch (e) {
      logger.e("[ProfileScreen] Error in _fetchProfileWithRetry: $e");
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        final errorMessage = await ErrorHandler.getErrorMessage(e);
        showErrorPopup(context, errorMessage, () {
          setState(() {
            _profileFuture = _fetchProfileWithRetry();
          });
        });
      }
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _uploadProfileImage(_selectedImage!);
    }
  }

  Future<bool> _uploadProfileImage(File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: "profile.jpg"),
      });

      Response response = await Dio().put(
        "https://apiserverdata.leaderposter.com/api/v1/user-details/profileImage",
        data: formData,
        options: Options(headers: {
          "Content-Type": "multipart/form-data",
          "Authorization": "Bearer ${await getToken()}"
        }),
      );

      if (response.statusCode == 200) {
        logger.i("Profile image uploaded successfully: ${response.data}");
        setState(() {
          _profileFuture = _fetchProfileWithRetry();
        });
        return true;
      } else {
        logger.e("Failed to upload profile image: ${response.statusCode} - ${response.data}");
        return false;
      }
    } catch (e) {
      logger.e("Upload error: $e");
      if (mounted) {
        final errorMsg = await ErrorHandler.getErrorMessage(e);
        showErrorPopup(context, errorMsg, () {
          _uploadProfileImage(imageFile);
        });
      }
      return false;
    }
  }

  void showErrorPopup(BuildContext context, String message, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Image.asset(
                  'assets/images/error_icon.png', // Replace with your local asset
                  height: 80,
                  width: 80,
                  color: Colors.red, // Ensure it's red as per your design
                ),
                SizedBox(height: 15),

                // Main Message
                Text(
                  "PLEASE TRY AGAIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 10),

                // Subtext Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                SizedBox(height: 25),

                // Try Again Button
                SizedBox(
                  width: double.infinity, // Full width button
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close popup
                      onRetry(); // Retry fetching data
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // Remove token
    logger.i("Token removed on logout");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || snapshot.data == null) {
              return const Center(child: Text("Failed to load profile"));
            }

            var profile = snapshot.data!;
            var userDetail = profile["userDetail"] ?? {};
            String name = userDetail["name"] ?? "User ";
            String mobile = userDetail["mobileNumber"] ?? "N/A";
            String userId = userDetail["userId"] ?? "N/A";
            String profilePic = userDetail["profile"] ?? "";

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements at the top
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _selectedImage != null
                                  ? FileImage(_selectedImage!)
                                  : (profilePic.isNotEmpty ? NetworkImage(profilePic) as ImageProvider : null),
                              child: (_selectedImage == null && profilePic.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.white, size: 26)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text("#$userId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(mobile, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          // Align the edit and verified icons in a column at the right corner
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space them vertically
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                                  );

                                  // Refresh profile data if update was successful (result is true)
                                  if (result == true) {
                                    setState(() {
                                      _profileFuture = _fetchProfileWithRetry();
                                    });
                                  }
                                },
                                child: const Icon(Icons.edit, size: 18),
                              ),
                              const SizedBox(height: 8), // Space between icons
                              const Icon(Icons.verified, color: Colors.green, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //       child: Container(
                //         padding: const EdgeInsets.all(12),
                //         decoration: BoxDecoration(
                //           color: SharedColors.selectTheTotalProfile,
                //           borderRadius: BorderRadius.circular(8),
                //           border: Border.all(color: Colors.grey.shade300),
                //         ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text(
                //         "Total profile",
                //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                //       ),
                //       const SizedBox(height: 8),
                //       Row(
                //         mainAxisAlignment: MainAxisAlignment.start,
                //         children: [
                //           _buildProfileBox(),
                //           const SizedBox(width: 8),
                //           _buildProfileBox(),
                //           const SizedBox(width: 8),
                //           _buildProfileBox(),
                //           const SizedBox(width: 8),
                //           _buildAddProfileBox(),
                //         ],
                //       ),
                //     ],
                //   ),
                //   ),
                // ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 10),
                    decoration: BoxDecoration(
                      color: SharedColors.selectTheTotalProfile,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      children: [
                        _buildSettingTile(
                          "Privacy Policy",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PageContentScreen(pageId: 1),
                            ),
                          ),
                        ),
                        _buildSettingTile(
                          "Terms and Conditions",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PageContentScreen(pageId: 2),
                            ),
                          ),
                        ),
                        _buildSettingTile("Delete my account", onTap: () => _showDeleteDialog(context)),
                        _buildSettingTile(
                          "About app",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PageContentScreen(pageId: 4),
                            ),
                          ),
                        ),

                        _buildSettingTile(
                          "Suggestion",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SuggestionPage(),
                            ),
                          ),

                        ),

                        _buildSettingTile(
                          "Subscription History",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SubscriptionHistoryPage(),
                            ),
                          ),

                        ),
                        _buildSettingTile(
                          "Rate Us",
                          onTap: () => _rateApp(),
                        ),
                        _buildSettingTile(
                          "Share App",
                          onTap: () => _shareApp(),
                        ),
                        _buildSettingTile(
                          "Help and Support",
                          onTap: () => _openWhatsApp(),
                        ),
                        // _buildSettingTile(
                        //   "Version",
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const PageContentScreen(pageId: 0),
                        //     ),
                        //   ),
                        // ),
                        // _buildSettingTile(
                        //   "How to use app",
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const PageContentScreen(pageId: 5),
                        //     ),
                        //   ),
                        // ),
                        // _buildSettingTile(
                        //   "FAQ",
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const PageContentScreen(pageId: 6),
                        //     ),
                        //   ),
                        // ),
                        // _buildSettingTile(
                        //   "Help",
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const PageContentScreen(pageId: 7),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Dismissible(
                    key: const Key("logout"),
                    direction: DismissDirection.startToEnd,
                    onDismissed: (_) => _logout(context),
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 16),
                      child: const Icon(Icons.logout, color: Colors.white),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: const Icon(Icons.logout, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 8),
                          const Text("Swipe right to logout ", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileBox() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildAddProfileBox() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add, color: Colors.black),
    );
  }

  Widget _buildSettingTile(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Account"),
          content: const Text("Are you sure you want to delete your account? It will be deleted in the next 30 days."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Your account will be deleted in the next 30 days."),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text("Yes"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
    )) {
      debugPrint("Could not launch $url");
    }
  }

  Future<void> _rateApp() async {
    const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.leaderposter.poster';
    final Uri uri = Uri.parse(playStoreUrl);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      logger.e("Could not launch Play Store");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open Play Store")),
        );
      }
    }
  }

  Future<void> _shareApp() async {
    const String appLink = 'https://play.google.com/store/apps/details?id=com.leaderposter.poster';
    const String shareText = 'Check out this amazing app: $appLink';
    
    try {
      await Share.share(shareText);
    } catch (e) {
      logger.e("Could not share app: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not share app")),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    const String phoneNumber = '918125262928';
    const String message = 'Hi, I need help with the app';
    final Uri uri = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      logger.e("Could not open WhatsApp");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp")),
        );
      }
    }
  }
}

