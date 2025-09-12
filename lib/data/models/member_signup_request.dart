// 회원가입 시 서버에 보낼 아이디, 비밀번호, 닉네임을 담는 DTO입니다.
class MemberSignUpRequest {
  final String memberId;
  final String password;
  final String nickname;

  MemberSignUpRequest({
    required this.memberId,
    required this.password,
    required this.nickname,
  });

  // 이 객체를 서버가 이해할 수 있는 JSON 형태로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'password': password,
      'nickname': nickname,
    };
  }
}