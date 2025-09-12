// 닉네임 변경 시 서버에 보낼 새로운 닉네임을 담는 DTO입니다.
class NicknameChangeRequest {
  final String nickname;

  NicknameChangeRequest({required this.nickname});

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
    };
  }
}
