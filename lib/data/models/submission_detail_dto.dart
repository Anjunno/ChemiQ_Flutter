// 미션 제출물의 상세 정보를 담는 DTO(데이터 전송 객체)입니다.
class SubmissionDetailDto {
  final int submissionId;
  final String imageUrl;
  final String content;
  final DateTime createdAt;
  final double? score; //내가 이 제출물에 남긴 평가 점수 (nullable)

  SubmissionDetailDto({
    required this.submissionId,
    required this.imageUrl,
    required this.content,
    required this.createdAt,
    this.score,
  });

  factory SubmissionDetailDto.fromJson(Map<String, dynamic> json) {
    return SubmissionDetailDto(
      submissionId: json['submissionId'] as int,
      imageUrl: json['imageUrl'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      score: (json['score'] as num?)?.toDouble(),
    );
  }
}

