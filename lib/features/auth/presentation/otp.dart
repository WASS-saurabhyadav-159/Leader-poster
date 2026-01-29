import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/shared_components.dart';
import '../../../core/strings.dart';

import 'auth_screen.dart';
import 'new_pass.dart';

class OtpScreen extends StatefulWidget {
  final String email; // Accept email as a parameter

  const OtpScreen({super.key, required this.email});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  Future<void> verifyOtp(BuildContext context) async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Fluttertoast.showToast(msg: "Please enter a valid 6-digit OTP");
      return;
    }

    try {
      final response = await _apiService.post("auth/user/verify", {
        "email": widget.email,
        "otp": otp,
      });

      if (response["message"] == "OTP Macthed.") {
        Fluttertoast.showToast(msg: "OTP Verified Successfully");
        Navigator.of(context).pushReplacement(
            await Navigator.of(context).pushReplacement(
              SharedComponents.routeOf(NewPasswordScreen(email: widget.email)),
            ),

        );
      } else {
        Fluttertoast.showToast(msg: "Invalid OTP. Please try again.");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to verify OTP. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinputTheme = PinTheme(
      height: 45,
      width: 50,
      textStyle: const TextStyle(fontSize: 20),
      decoration: BoxDecoration(
        border: Border.all(color: SharedColors.primary, width: 0.5),
        borderRadius: BorderRadius.circular(2.0),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 80.0, left: 32.0, right: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset("assets/app_icon.png", height: 117.0, width: 117.0),
          const SizedBox(height: 16.0),
          Text(
            "OTP sent to ${widget.email}",
            style: TextStyle(
              color: SharedColors.hintColor,
              fontWeight: FontWeight.w400,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 16.0),
          Pinput(
            controller: _otpController,
            length: 6,
            defaultPinTheme: pinputTheme,
          ),
          const SizedBox(height: 16.0),
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              "Resend OTP again",
              style: TextStyle(
                color: Colors.black.withOpacity(0.99),
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          AuthScreenButton("SUBMIT", () => verifyOtp(context)),
        ],
      ),
    );
  }
}
