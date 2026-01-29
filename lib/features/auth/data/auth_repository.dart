import '../../../core/network/api_constants.dart';
import '../../../core/network/api_service.dart';

import '../../../core/models/login_response.dart';


class AuthRepository {
  final ApiService _apiService = ApiService();

  Future<LoginResponse> login(String email, String password) async {
    final data = {"email": email, "password": password};

    try {
      final response = await _apiService.post(ApiConstants.loginEndpoint, data);
      return LoginResponse.fromJson(response);
    } catch (e) {
      print("Login API Error: $e");
      throw Exception("Login failed");
    }
  }
}
