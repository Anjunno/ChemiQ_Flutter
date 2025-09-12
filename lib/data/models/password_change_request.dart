// 비밀번호 변경 시 서버에 보낼 현재 비밀번호와 새 비밀번호를 담는 DTO입니다.
class PasswordChangeRequest {
  final String password;
  final String newPassword;

  PasswordChangeRequest({
    required this.password,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'newPassword': newPassword,
    };
  }
}
