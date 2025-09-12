// 서버에 보낼 Refresh Token을 담는 DTO
class LogoutRequest {
  final String refreshToken;

  LogoutRequest({required this.refreshToken});

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}
