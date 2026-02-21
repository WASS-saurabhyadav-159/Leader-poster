import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:poster/features/dashboard/presentation/profile.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';
import '../../../core/utils/error_handler.dart';
import '../../../notifications/presentation/notification_screen.dart';
import '../../../screens/subscription_screen.dart';
import '../../auth/presentation/login.dart';
import '../home/presentation/home.dart';
import 'SecretScreen.dart';
import 'downloads.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isNotificationClicked = false;

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  final Logger logger = Logger(); // Initialize logger
  final ApiService apiService = ApiService(); // <-- create an instance

  final List<GlobalKey<RefreshIndicatorState>> _refreshIndicatorKeys = [
    GlobalKey<RefreshIndicatorState>(),
    GlobalKey<RefreshIndicatorState>(),
    GlobalKey<RefreshIndicatorState>(),
  ];

  final List<Widget> _screens = [
    const HomeScreen(),
    FileSelectionScreen(),
    ProfileScreen(),
  ];

  List<Widget> get _refreshableScreens => [
    RefreshIndicator(
      key: _refreshIndicatorKeys[0],
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() {});
      },
      child: _screens[0],
    ),
    RefreshIndicator(
      key: _refreshIndicatorKeys[1],
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() {});
      },
      child: _screens[1],
    ),
    RefreshIndicator(
      key: _refreshIndicatorKeys[2],
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() {});
      },
      child: _screens[2],
    ),
  ];

  final List<Map<String, String>> _navIcons = [
    {'selected': 'assets/home_selected.png', 'unselected': 'assets/home.png'},
    {'selected': 'assets/downloads_selected.png', 'unselected': 'assets/folder.png'},
    {'selected': 'assets/profile_selected.png', 'unselected': 'assets/profile.png'},
  ];

  final String _notificationIcon = 'assets/alarm.png';
  final String _notificationIconClicked = 'assets/notification_selected.png';
  final String _searchIcon = 'assets/search.png';

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _checkAccountStatusOnLaunch(); // <-- call profile check on launch
    });
  }



  Future<void> _checkAccountStatusOnLaunch() async {
    try {
      final profile = await apiService.getProfile();
      final status = profile['status'] ?? 'UNKNOWN';

      final prefs = await SharedPreferences.getInstance();

      if (status == 'DEACTIVE') {
        // Save deactivated status
        await prefs.setBool('account_deactivated', true);
        logger.i("Account status: DEACTIVE saved to SharedPreferences");

        if (mounted) {
          _showDeactivatedPopup();
        }
      } else if (status == 'ACTIVE') {
        // Save active status as false for deactivated flag
        await prefs.setBool('account_deactivated', false);
        logger.i("Account status: ACTIVE saved to SharedPreferences");
        // No popup needed
      } else {
        // Optional: handle UNKNOWN or other statuses if needed
        await prefs.setBool('account_deactivated', false);
        logger.i("Account status: UNKNOWN or Other saved as false");
      }
    } catch (e, stacktrace) {
      logger.e("Error checking account status", error: e, stackTrace: stacktrace);
    }
  }

// To read later in login or elsewhere

// Move logout and navigation to OK button
  void _showDeactivatedPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Deactivated'),
        content: const Text('Your account is deactivated. Please connect with the admin.'),
        actions: [
          TextButton(
            onPressed: () async {
              await logout(); // remove token here
              Navigator.of(context).pop(); // close popup
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                    (Route<dynamic> route) => false,
              );
            },

            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    bool? exit = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildExitConfirmation(),
    );
    return exit ?? false;
  }

  Widget _buildExitConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Exit Alert", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Are you sure you want to exit?", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Yes"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("No"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // const double _appBarIconSize = 20;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: SharedColors.dialogBorderColor,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              leadingWidth: 130,
              leading: Padding(
                padding: const EdgeInsets.only(left: 12, top: 5, bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Text(
                            'Buy Premium 👑',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Free',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),



              /// 🔹 CENTER APP ICON
              title: Image.asset(
                'assets/app_icon.png',
                height: 60,
              ),

              /// 🔹 RIGHT SIDE ICONS
              actions: [
                /// 🔍 SEARCH
                IconButton(
                  iconSize: 70,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => SecretScreen()),
                    );
                  },
                  icon: Image.asset(
                    _searchIcon,
                    width: 30,
                    height: 30,
                    color: SharedColors.primary,
                  ),
                ),

                /// 🔔 NOTIFICATION
                IconButton(
                  iconSize: 30,
                  onPressed: () {
                    setState(() => _isNotificationClicked = true);
                    Navigator.of(context)
                        .push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    )
                        .then((_) =>
                        setState(() => _isNotificationClicked = false));
                  },
                  icon: Image.asset(
                    _isNotificationClicked
                        ? _notificationIconClicked
                        : _notificationIcon,
                    width: 30,
                    height: 30,
                  ),
                ),

                const SizedBox(width: 8),
              ],
            ),



            body: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: _refreshableScreens,
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: SharedColors.buttonTextColor,
              elevation: 8,
              items: [
                _buildBottomNavItem(0, "Home"),
                _buildBottomNavItem(1, "Downloads"),
                _buildBottomNavItem(2, "Profile"),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: SharedColors.primary,
              unselectedItemColor: Colors.black,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              onTap: (value) {
                if (_selectedIndex == value) {
                  _refreshIndicatorKeys[value].currentState?.show();
                }
                setState(() => _selectedIndex = value);
              },
            ),
          ),
          Positioned(
            right: 16,
            bottom: 80,
            child: SlideTransition(
              position: _offsetAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: GestureDetector(
                  onTap: () async {
                    final Uri whatsapp = Uri.parse("https://wa.me/918125262928");
                    try {
                      if (!await launchUrl(
                        whatsapp,
                        mode: LaunchMode.externalApplication,
                      )) {
                        debugPrint("❌ Could not open WhatsApp");
                      }
                    } catch (e) {
                      debugPrint("⚠️ Error launching WhatsApp: $e");
                    }
                  },
                  child: Image.asset(
                    'assets/images/whatsapp.png',
                    width: 45,
                    height: 45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(int index, String label) {
    final isSelected = _selectedIndex == index;
    final iconPath = isSelected ? _navIcons[index]['selected']! : _navIcons[index]['unselected']!;
    return BottomNavigationBarItem(
      icon: Image.asset(
        iconPath,
        width: 24,
        height: 24,
        color: isSelected ? SharedColors.primary : Colors.grey,
      ),
      label: label,
    );
  }
}
