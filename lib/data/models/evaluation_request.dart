// 파트너의 제출물 평가 시 서버에 보낼 점수와 코멘트를 담는 DTO입니다.
class EvaluationRequest {
  final double score;
  final String comment;

  EvaluationRequest({
    required this.score,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'comment': comment,
    };
  }
}
