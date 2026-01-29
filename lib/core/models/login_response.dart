class LoginResponse {
  final String token;
  final String accountId;
  final String status;

  LoginResponse({required this.token, required this.accountId, required this.status});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      accountId: json['accountId'],
      status: json['status'],
    );
  }
}
