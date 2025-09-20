// 홈 화면에 필요한 파트너의 핵심 정보만 담는 DTO
class HomePartnerInfoDto {
  final String nickname;
  final String? profileImageUrl;
  final int streakCount;
  final double chemiScore;

  HomePartnerInfoDto({
    required this.nickname,
    this.profileImageUrl,
    required this.streakCount,
    required this.chemiScore,
  });

  factory HomePartnerInfoDto.fromJson(Map<String, dynamic> json) {
    return HomePartnerInfoDto(
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      streakCount: json['streakCount'] as int,
      chemiScore: (json['chemiScore'] as num).toDouble(),
    );
  }
}