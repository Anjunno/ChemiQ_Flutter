import 'package:chemiq/data/models/submission_detail_dto.dart';

// GET /timeline/today API의 전체 응답을 담는 DTO입니다.
class DailyMissionResponse {
  final int dailyMissionId;
  final String missionTitle;
  final DateTime missionDate;
  final SubmissionDetailDto? mySubmission;       // 내 제출물 (아직 제출 안했으면 null)
  final SubmissionDetailDto? partnerSubmission;  // 파트너 제출물 (아직 제출 안했으면 null)

  DailyMissionResponse({
    required this.dailyMissionId,
    required this.missionTitle,
    required this.missionDate,
    this.mySubmission,
    this.partnerSubmission,
  });

  factory DailyMissionResponse.fromJson(Map<String, dynamic> json) {
    return DailyMissionResponse(
      dailyMissionId: json['dailyMissionId'] as int,
      missionTitle: json['missionTitle'] as String,
      missionDate: DateTime.parse(json['missionDate'] as String),
      // 'mySubmission' 필드가 null이 아닐 경우에만 객체로 변환합니다.
      mySubmission: json['mySubmission'] != null
          ? SubmissionDetailDto.fromJson(json['mySubmission'])
          : null,
      // 'partnerSubmission' 필드가 null이 아닐 경우에만 객체로 변환합니다.
      partnerSubmission: json['partnerSubmission'] != null
          ? SubmissionDetailDto.fromJson(json['partnerSubmission'])
          : null,
    );
  }
}
