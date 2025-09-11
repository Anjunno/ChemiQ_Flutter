// 서버로부터 받을 새로운 Refresh Token을 담는 DTO
class ReissueResponse {
  final String newRefreshToken;

  ReissueResponse({required this.newRefreshToken});

  // JSON을 객체로 변환
  factory ReissueResponse.fromJson(Map<String, dynamic> json) {
    return ReissueResponse(
      newRefreshToken: json['newRefreshToken'] as String,
    );
  }
}
