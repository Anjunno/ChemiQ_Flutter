// 타임라인에 표시될 개별 제출물 하나의 핵심 정보를 담는 DTO입니다.
class TimelineItemDto {
  final int submissionId;
  final String missionTitle;
  final String submitterNickname;
  final String? submitterProfileImageUrl;
  final String imageUrl;
  final String content;
  final DateTime createdAt;
  final double? score; // ✨ 파트너가 남긴 별점만 남깁니다.

  TimelineItemDto({
    required this.submissionId,
    required this.missionTitle,
    required this.submitterNickname,
    this.submitterProfileImageUrl,
    required this.imageUrl,
    required this.content,
    required this.createdAt,
    this.score, // ✨
  });

  factory TimelineItemDto.fromJson(Map<String, dynamic> json) {
    return TimelineItemDto(
      submissionId: json['submissionId'],
      missionTitle: json['missionTitle'],
      submitterNickname: json['submitterNickname'],
      submitterProfileImageUrl: json['submitterProfileImageUrl'],
      imageUrl: json['imageUrl'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      score: (json['score'] as num?)?.toDouble(), // ✨
    );
  }
}

