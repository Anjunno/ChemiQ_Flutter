// 특정 제출물에 대한 평가 하나의 상세 정보를 담는 DTO입니다.
class EvaluationDetailDto {
  final String evaluatorNickname; // 평가를 남긴 사람의 닉네임
  final double score;
  final String comment;
  final DateTime createdAt;

  EvaluationDetailDto({
    required this.evaluatorNickname,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  factory EvaluationDetailDto.fromJson(Map<String, dynamic> json) {
    return EvaluationDetailDto(
      evaluatorNickname: json['evaluatorNickname'] as String,
      score: (json['score'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

