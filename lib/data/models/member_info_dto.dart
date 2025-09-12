// 마이페이지 API 응답 중, 사용자(나 또는 파트너)의 정보를 담는 DTO입니다.
class MemberInfoDto {
  final String memberId;
  final String nickname;
  final DateTime created;
  final String? profileImageUrl;

  MemberInfoDto({
    required this.memberId,
    required this.nickname,
    required this.created,
    this.profileImageUrl,
  });

  factory MemberInfoDto.fromJson(Map<String, dynamic> json) {
    return MemberInfoDto(
      memberId: json['memberId'] as String,
      nickname: json['nickname'] as String,
      created: DateTime.parse(json['created'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
