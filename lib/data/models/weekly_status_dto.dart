// 서버에서 오는 DailyMissionStatus enum
enum DailyMissionStatus {
  ASSIGNED,      // 할당됨 (미션 진행 중)
  COMPLETED,     // 양쪽 모두 제출 및 평가까지 완료함
  FAILED,        // 하루가 지나도록 완료하지 못함
  NOT_ASSIGNED   // 미션이 할당되지 않음
}

// 각 요일별 미션 상태를 담는 DTO
class MissionStatusDto {
  final int? dailyMissionId;
  final String? missionTitle;
  final DailyMissionStatus status;

  MissionStatusDto({
    this.dailyMissionId,
    this.missionTitle,
    required this.status,
  });

  factory MissionStatusDto.fromJson(Map<String, dynamic> json) {
    return MissionStatusDto(
      dailyMissionId: json['dailyMissionId'],
      missionTitle: json['missionTitle'],
      status: _parseStatus(json['status']),
    );
  }

  static DailyMissionStatus _parseStatus(String status) {
    switch (status) {
      case 'ASSIGNED':
        return DailyMissionStatus.ASSIGNED;
      case 'COMPLETED':
        return DailyMissionStatus.COMPLETED;
      case 'FAILED':
        return DailyMissionStatus.FAILED;
      default:
        return DailyMissionStatus.NOT_ASSIGNED;
    }
  }
}

// 주간 미션 현황 전체 응답을 담는 DTO
class WeeklyMissionStatusResponse {
  // Key: "MONDAY", "TUESDAY" ... , Value: MissionStatusDto
  final Map<String, MissionStatusDto> weeklyStatus;

  WeeklyMissionStatusResponse({required this.weeklyStatus});

  factory WeeklyMissionStatusResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> weeklyStatusMap = json['weeklyStatus'];
    return WeeklyMissionStatusResponse(
      weeklyStatus: weeklyStatusMap.map(
            (key, value) => MapEntry(key, MissionStatusDto.fromJson(value)),
      ),
    );
  }
}

