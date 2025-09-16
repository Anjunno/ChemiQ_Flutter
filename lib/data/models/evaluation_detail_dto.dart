// 특정 제출물에 대한 평가 하나의 상세 정보를 담는 DTO입니다.
class EvaluationDetailDto {
  final String evaluatorNickname;
  final String? evaluatorProfileImageUrl;
  final double score;
  final String comment;
  final DateTime createdAt;

  EvaluationDetailDto({
    required this.evaluatorNickname,
    this.evaluatorProfileImageUrl, 
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory EvaluationDetailDto.fromJson(Map<String, dynamic> json) {
    return EvaluationDetailDto(
      evaluatorNickname: json['evaluatorNickname'] as String,
      evaluatorProfileImageUrl: json['evaluatorProfileImageUrl'] as String?,
      score: (json['score'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

