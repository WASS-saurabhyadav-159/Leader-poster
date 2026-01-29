import 'package:flutter/material.dart';
import '../../../config/colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/strings.dart';
import 'auth_screen.dart';
import 'auth_text_field.dart';
import 'login.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;

  const NewPasswordScreen({super.key, required this.email});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> submitPassword() async {
    if (_passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      showErrorDialog("Fields cannot be empty");
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      showErrorDialog("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService().resetPassword(widget.email, _passwordController.text);

      if (response["reset"] == true) {
        showConfirmationDialog("Password reset successfully");
      } else {
        showErrorDialog(response["message"] ?? "Something went wrong");
      }
    } catch (e) {
      showErrorDialog("Failed to reset password. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> showConfirmationDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                navigateToLoginScreen();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void navigateToLoginScreen() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to Login
          (route) => false, // Clear all previous screens
    );
  }

  Future<void> showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 80.0, left: 32.0, right: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              "assets/splash.png",
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
            AuthTextField("Enter new password", obscureText: true, controller: _passwordController),
            const SizedBox(height: 16.0),
            AuthTextField("Re-enter password", obscureText: true, controller: _confirmPasswordController),
            const SizedBox(height: 40.0),
            _isLoading
                ? const CircularProgressIndicator()
                : AuthScreenButton("SUBMIT", submitPassword),
          ],
        ),
      ),
    );
  }
}
