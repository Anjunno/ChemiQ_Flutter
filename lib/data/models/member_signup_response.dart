// 회원가입 성공 시 서버로부터 받을 메시지를 담는 DTO입니다.
class MemberSignUpResponse {
  final String message;

  MemberSignUpResponse({required this.message});

  // 서버가 보낸 JSON을 이 객체로 변환합니다.
  factory MemberSignUpResponse.fromJson(Map<String, dynamic> json) {
    return MemberSignUpResponse(
      message: json['message'] as String,
    );
  }
}