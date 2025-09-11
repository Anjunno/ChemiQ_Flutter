// 서버에 보낼 Refresh Token을 담는 DTO
class ReissueRequest {
  final String refreshToken;

  ReissueRequest({required this.refreshToken});

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'refreshToken': refreshToken,
    };
  }
}
