
import 'package:chemiq/data/models/home_partner_info_dto.dart';
import 'package:chemiq/data/models/weekly_status_dto.dart';

import 'dailyMission_response.dart';

// 홈 화면에 필요한 모든 정보를 한 번에 담는 최적화된 DTO
class HomeSummaryDto {
  final HomePartnerInfoDto? partnerInfo;
  final WeeklyMissionStatusResponse? weeklyStatus;
  final DailyMissionResponse? dailyMission;

  HomeSummaryDto({
    this.partnerInfo,
    this.weeklyStatus,
    this.dailyMission,
  });

  factory HomeSummaryDto.fromJson(Map<String, dynamic> json) {
    return HomeSummaryDto(
      partnerInfo: json['partnerInfo'] != null
          ? HomePartnerInfoDto.fromJson(json['partnerInfo'])
          : null,
      weeklyStatus: json['weeklyStatus'] != null
          ? WeeklyMissionStatusResponse.fromJson(json['weeklyStatus'])
          : null,
      dailyMission: json['dailyMission'] != null
          ? DailyMissionResponse.fromJson(json['dailyMission'])
          : null,
    );
  }
}

