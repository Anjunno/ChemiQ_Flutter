import 'package:chemiq/data/models/weekly_status_dto.dart';

import 'dailyMission_response.dart';
import 'myPage_response.dart';

// 홈 화면에 필요한 모든 데이터를 한 번에 담는 클래스
class HomeScreenData {
  final MyPageResponse? myPageInfo;
  final DailyMissionResponse? dailyMission;
  final WeeklyMissionStatusResponse? weeklyStatus;

  HomeScreenData({
    this.myPageInfo,
    this.dailyMission,
    this.weeklyStatus,
  });
}
