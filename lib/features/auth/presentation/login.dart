import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:poster/features/auth/presentation/regidtration.dart';

import '../../../constants/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';
import '../../../core/shared_components.dart';
import 'Otpscreenlogin.dart';
import 'auth_screen.dart';
import 'auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final Connectivity _connectivity = Connectivity();
  String? _mobileError;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _mobileController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void showNoInternetPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 80, color: Colors.red),
                const SizedBox(height: 15),
                const Text(
                  "NO INTERNET CONNECTION",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Please check your internet connection and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("OK",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void getOtp(BuildContext context) async {
    String mobile = _mobileController.text.trim();
    if (mobile.isEmpty || mobile.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(mobile)) {
      setState(() {
        _mobileError = "Enter a valid mobile number";
      });
      _scrollToError();
      return;
    }

    final hasInternet = await _checkInternetConnection();
    if (!hasInternet) {
      showNoInternetPopup(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _mobileError = null;
    });

    try {
      final String masterAppId = await getAppMasterId();
      final response = await ApiService().sendOtp(mobile, masterAppId);

      // Debug print to see actual response structure
      debugPrint("OTP API Response: $response");

      // Check if response contains success message
      final String message = response["message"]?.toString().toLowerCase() ?? "";

      if (message.contains("otp") && message.contains("sent")) {
        // Success case - OTP sent successfully
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        // Navigate to OTP screen after a small delay to ensure state is updated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreenLogin(mobile: mobile),
            ),
          );
        });
      }
      else if (message.contains("deactive") || message.contains("inactive") || message.contains("not active")) {
        // Account deactivated case
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _mobileError = "Your account is deactivated. Please contact admin.";
        });
        _scrollToError();
      }
      else if (message.contains("not found") || message.contains("no user") || message.contains("register")) {
        // Account not found case
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _mobileError = "Account not found. Please register first!";
        });
        _scrollToError();
      }
      else {
        // Other error cases
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _mobileError = response["message"]?.toString() ?? "An error occurred. Please try again.";
        });
        _scrollToError();
      }

    } catch (e) {
      debugPrint("OTP Send Error: $e");

      if (!mounted) return;
      setState(() {
        _isLoading = false;

        // More specific error handling based on exception type
        if (e.toString().contains("deactive") || e.toString().contains("inactive")) {
          _mobileError = "Your account is deactivated. Please contact admin.";
        } else if (e.toString().contains("not found") || e.toString().contains("404")) {
          _mobileError = "Account not found. Please register first!";
        } else {
          _mobileError = "Network error. Please check your connection and try again.";
        }
      });
      _scrollToError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Top Purple Curved Background
          Container(
            height: 320,
            decoration: const BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60.0),
                child: Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              children: [
                // Main White Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular App Logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage("assets/app_icon.png"),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mobile Number Field
                      AuthTextField(
                        "Enter your mobile number",
                        iconName: "assets/phone.png",
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),

                      if (_mobileError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                          child: Text(
                            _mobileError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Get OTP Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => getOtp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          )
                              : const Text(
                            "Get OTP",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Create Account Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => RegistrationScreen()),
                          );
                        },
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}