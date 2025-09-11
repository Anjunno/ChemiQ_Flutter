// lib/data/models/login_response.dart

class LoginResponse {
  final String refreshToken;

  LoginResponse({
    required this.refreshToken,
  });

  // 서버에서 받은 JSON(Map<String, dynamic>)을 LoginResponse 객체로 변환하는 factory 생성자
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      refreshToken: json['refreshToken'] as String,
    );
  }
}