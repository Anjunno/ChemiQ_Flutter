// 마이페이지 API 응답 중, 파트너십 관련 정보(스트릭, 케미지수 등)를 담는 DTO입니다.
class PartnershipInfoDto {
  final int streakCount;
  final double chemiScore;
  final DateTime acceptedAt;
  final int totalCompletedMissions;
  final int weeklyCompletedMissions;

  PartnershipInfoDto({
    required this.streakCount,
    required this.chemiScore,
    required this.acceptedAt,
    required this.totalCompletedMissions,
    required this.weeklyCompletedMissions,
  });

  factory PartnershipInfoDto.fromJson(Map<String, dynamic> json) {
    return PartnershipInfoDto(
      streakCount: json['streakCount'] as int,
      chemiScore: (json['chemiScore'] as num).toDouble(),
      acceptedAt: DateTime.parse(json['acceptedAt'] as String),
      totalCompletedMissions: json['totalCompletedMissions'] as int,
      weeklyCompletedMissions: json['weeklyCompletedMissions'] as int
    );
  }
}
