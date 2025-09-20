import 'package:intl/intl.dart';

// '/members/me/info' API 응답의 'myAchievements' 배열의 각 항목을 나타내는 DTO입니다.
class AchievementDto {
  final String name;
  final String description;
  final DateTime earnedAt;

  AchievementDto({
    required this.name,
    required this.description,
    required this.earnedAt,
  });

  factory AchievementDto.fromJson(Map<String, dynamic> json) {
    return AchievementDto(
      name: json['name'] as String,
      description: json['description'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
    );
  }
}
