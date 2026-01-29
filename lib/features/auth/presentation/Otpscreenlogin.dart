import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/local_storage.dart';
import '../../../core/shared_components.dart';
import '../../dashboard/presentation/dashboard.dart';
import 'auth_screen.dart';
import 'login.dart';

class OtpScreenLogin extends StatefulWidget {
  final String mobile;

  const OtpScreenLogin({super.key, required this.mobile});

  @override
  _OtpScreenLoginState createState() => _OtpScreenLoginState();
}

class _OtpScreenLoginState extends State<OtpScreenLogin> {
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isResendDisabled = false;
  int _timerSeconds = 30;
  Timer? _timer;

  void startResendTimer() {
    setState(() {
      _isResendDisabled = true;
      _timerSeconds = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        setState(() {
          _isResendDisabled = false;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> verifyOtp(BuildContext context) async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Fluttertoast.showToast(msg: "Please enter a valid 6-digit OTP");
      return;
    }

    try {
      // Get the masterAppId from local storage
      final String masterAppId = await getAppMasterId();

      final response = await _apiService.verifyOtp(widget.mobile, otp, masterAppId);

      if (response["token"] != null && response["accountId"] != null) {
        // Save the token and accountId in local storage
        await saveToken(response["token"]);
        await saveCategoryId(response["accountId"]);

        Fluttertoast.showToast(msg: "OTP Verified Successfully");

        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to verify OTP. Try again.");
    }
  }

  Future<void> resendOtp() async {
    try {
      // Get the masterAppId from local storage
      final String masterAppId = await getAppMasterId();

      // Use the existing sendOtp method which already includes masterAppId
      final response = await _apiService.sendOtp(widget.mobile, masterAppId);

      if (response["message"] == "OTP sent succesfully") {
        Fluttertoast.showToast(msg: "OTP resent successfully");
        startResendTimer(); // Start the timer after successful resend
      } else {
        Fluttertoast.showToast(msg: "Failed to resend OTP. Please try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to resend OTP. Please try again.");
    }
  }

  @override
  void initState() {
    super.initState();
    startResendTimer(); // Start timer when screen loads
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("assets/app_icon.png", height: 117.0, width: 117.0),
                const SizedBox(height: 16.0),
                Text("OTP sent to ${widget.mobile}",
                    style: TextStyle(
                        color: SharedColors.hintColor,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.0)),
                const SizedBox(height: 16.0),
                Pinput(controller: _otpController, length: 6),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _isResendDisabled
                          ? null
                          : resendOtp, // Use the resendOtp function
                      child: Text(
                        _isResendDisabled ? "Resend in $_timerSeconds sec" : "Resend OTP",
                        style: TextStyle(
                          color: _isResendDisabled ? Colors.grey : Colors.black.withOpacity(0.99),
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthScreen()),
                        );
                      },
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                AuthScreenButton("SUBMIT", () => verifyOtp(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}