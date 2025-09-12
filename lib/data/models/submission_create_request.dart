// S3에 사진 업로드를 완료한 후, 우리 서버에 최종 보고할 때 보낼 데이터를 담는 DTO입니다.
class SubmissionCreateRequest {
  final int dailyMissionId;
  final String content;
  final String fileKey;

  SubmissionCreateRequest({
    required this.dailyMissionId,
    required this.content,
    required this.fileKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyMissionId': dailyMissionId,
      'content': content,
      'fileKey': fileKey,
    };
  }
}
