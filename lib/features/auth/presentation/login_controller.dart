import 'package:flutter/material.dart';
import '../../../core/network/local_storage.dart';
import '../data/auth_repository.dart';
import '../../../core/models/login_response.dart';
// Import the local storage helper

class LoginController {
  final AuthRepository _authRepository = AuthRepository();

  Future<bool> login(BuildContext context, String email, String password) async {
    try {
      LoginResponse response = await _authRepository.login(email, password);
      print("Login Success: ${response.token}");

      if (response.status == "ACTIVE") {
        await saveToken(response.token); // Save the token to local storage
        Navigator.pushReplacementNamed(context, '/dashboard');
        return true; // Indicate successful login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account is not active")),
        );
        return false; // Indicate failed login due to inactive account
      }
    } catch (e) {
      print("Login Failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
      return false; // Indicate failed login due to an error
    }
  }
}