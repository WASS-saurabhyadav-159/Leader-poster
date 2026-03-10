import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
// import 'package:glassmorphism/glassmorphism.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';

import 'PageContentScreen .dart';
import 'SuggestionPage.dart';
import 'editprofilenamepage.dart' hide SharedColors;

final Logger logger = Logger();

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>?> _profileFuture;
  File? _selectedImage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // App color scheme
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color accentRed = Color(0xFFE53935);
  static const Color pureWhite = Colors.white;
  static const Color softGrey = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _profileFuture = _fetchProfileWithRetry();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile image updated successfully!"),
              backgroundColor: accentRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }

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
                Lottie.asset(
                  'assets/animations/error.json',
                  height: 100,
                  width: 100,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error_outline, size: 80, color: accentRed);
                  },
                ),
                const SizedBox(height: 15),
                Text(
                  "PLEASE TRY AGAIN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlack,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text("TRY AGAIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    logger.i("Token removed on logout");

    // Show logout animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: accentRed),
              const SizedBox(height: 16),
              Text("Logging out...", style: TextStyle(color: primaryBlack)),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pop(); // Remove dialog
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      // appBar: AppBar(
      //   title: const Text(
      //     "Profile",
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       color: Colors.white,
      //     ),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: primaryBlack,
      //   elevation: 0,
      //   flexibleSpace: Container(
      //     decoration: BoxDecoration(
      //       gradient: LinearGradient(
      //         begin: Alignment.topLeft,
      //         end: Alignment.bottomRight,
      //         colors: [primaryBlack, accentRed.withOpacity(0.7)],
      //       ),
      //     ),
      //   ),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.notifications_outlined, color: Colors.white),
      //       onPressed: () {
      //         // Navigate to notifications
      //       },
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerLoading();
              }

              if (snapshot.hasError || snapshot.data == null) {
                return _buildErrorState();
              }

              var profile = snapshot.data!;
              var userDetail = profile["userDetail"] ?? {};
              String name = userDetail["name"] ?? "User";
              String mobile = userDetail["mobileNumber"] ?? "N/A";
              String userId = userDetail["userId"] ?? "N/A";
              String profilePic = userDetail["profile"] ?? "";
              String email = userDetail["email"] ?? "No email provided";
              String membershipType = (profile["plan"] != null && profile["plan"]["packageName"] != null)
                  ? profile["plan"]["packageName"]
                  : "Free";

              return Column(
                children: [
                  // Profile Header with Glassmorphism effect
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 140,
                      borderRadius: 20,
                      blur: 20,
                      alignment: Alignment.center,
                      border: 2,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentRed.withOpacity(0.5),
                          accentRed.withOpacity(0.2),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.7),
                              Colors.white.withOpacity(0.9),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            // Profile Image with red border
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentRed,
                                        width: 3,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                          : (profilePic.isNotEmpty
                                          ? NetworkImage(profilePic) as ImageProvider
                                          : null),
                                      child: (_selectedImage == null && profilePic.isEmpty)
                                          ? Icon(Icons.person, color: accentRed, size: 40)
                                          : null,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: accentRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // User Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: accentRed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: accentRed.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          membershipType,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: accentRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EditProfilePage()),
                                );
                                if (result == true) {
                                  setState(() {
                                    _profileFuture = _fetchProfileWithRetry();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Stats Cards
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           "Total Profiles",
                  //           "12",
                  //           Icons.people_outline,
                  //         ),
                  //       ),
                  //       const SizedBox(width: 12),
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           "Downloads",
                  //           "245",
                  //           Icons.download_outlined,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  const SizedBox(height: 16),

                  // Settings Menu
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          _buildSectionHeader("ACCOUNT SETTINGS"),
                          _buildModernTile(
                            "Subscription History",
                            Icons.history,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscriptionHistoryPage(),
                              ),
                            ),
                          ),
                          _buildModernTile(
                            "Edit Profile",
                            Icons.person_outline,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => EditProfilePage()),
                              );
                              if (result == true) {
                                setState(() {
                                  _profileFuture = _fetchProfileWithRetry();
                                });
                              }
                            },
                          ),
                          const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16),

                          _buildSectionHeader("LEGAL & SUPPORT"),
                          _buildModernTile(
                            "Privacy Policy",
                            Icons.privacy_tip_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PageContentScreen(pageId: 1),
                              ),
                            ),
                          ),
                          _buildModernTile(
                            "Terms and Conditions",
                            Icons.description_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PageContentScreen(pageId: 2),
                              ),
                            ),
                          ),
                          _buildModernTile(
                            "About app",
                            Icons.info_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PageContentScreen(pageId: 4),
                              ),
                            ),
                          ),
                          const Divider(height: 16, thickness: 1, indent: 16, endIndent: 16),

                          _buildSectionHeader("FEEDBACK & MORE"),
                          _buildModernTile(
                            "Suggestion",
                            Icons.lightbulb_outline,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SuggestionPage(),
                              ),
                            ),
                          ),
                          _buildModernTile(
                            "Rate Us",
                            Icons.star_outline,
                            onTap: _rateApp,
                          ),
                          _buildModernTile(
                            "Share App",
                            Icons.share_outlined,
                            onTap: _shareApp,
                          ),
                          _buildModernTile(
                            "Help and Support",
                            Icons.support_agent_outlined,
                            onTap: _openWhatsApp,
                          ),
                          _buildModernTile(
                            "Delete my account",
                            Icons.delete_outline,
                            iconColor: accentRed,
                            textColor: accentRed,
                            onTap: () => _showDeleteDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout Button with modern design
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [accentRed, accentRed.withOpacity(0.8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentRed.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _logout(context),
                          borderRadius: BorderRadius.circular(15),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: accentRed),
          const SizedBox(height: 16),
          const Text(
            "Failed to load profile",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please check your internet connection",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _profileFuture = _fetchProfileWithRetry();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentRed, size: 24),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildModernTile(
      String title,
      IconData icon, {
        VoidCallback? onTap,
        Color? iconColor,
        Color? textColor,
      }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? accentRed).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? accentRed,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? primaryBlack,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey.shade400,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: accentRed, size: 40),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Delete Account",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Are you sure you want to delete your account? It will be deleted in the next 30 days.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Your account will be deleted in the next 30 days."),
                              backgroundColor: accentRed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
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
          SnackBar(
            content: const Text("Could not open Play Store"),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
          ),
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
          SnackBar(
            content: const Text("Could not share app"),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
          ),
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
          SnackBar(
            content: const Text("Could not open WhatsApp"),
            backgroundColor: accentRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}