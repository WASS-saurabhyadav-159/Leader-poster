import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/shared_components.dart';
import '../../../core/strings.dart';
import 'auth_screen.dart';
import 'auth_text_field.dart';
import 'otp.dart';


class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService();

  void getOtp(BuildContext context) async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    try {
      final response = await _apiService.post("auth/user/forgotPass", {"email": email});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response["message"] ?? "OTP sent successfully")),
      );
      Navigator.of(context).pushReplacement(
        SharedComponents.routeOf(OtpScreen(email: email)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0, left: 32.0, right: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            "assets/app_icon.png",
            height: 117.0,
            width: 117.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            forgotPasswordText,
            style: TextStyle(
              color: SharedColors.hintColor,
              fontWeight: FontWeight.w400,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 16.0),
          AuthTextField("EMAIL ID", iconName: "assets/phone.png", controller: _emailController),
          const SizedBox(height: 40.0),
          AuthScreenButton("Get OTP", () => getOtp(context)),
        ],
      ),
    );
  }
}