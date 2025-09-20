import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/home_screen_data.dart';

// ✨ 홈 화면에 필요한 모든 데이터를 한 번에 비동기적으로 불러오는 통합 Provider
final homeScreenDataProvider = FutureProvider.autoDispose<HomeScreenData>((ref) async {
  // 필요한 Repository들을 가져옵니다.
  final missionRepository = ref.watch(missionRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);

  // Future.wait를 사용하여 모든 API를 동시에 호출하고, 결과가 모두 올 때까지 기다립니다.
  final results = await Future.wait([
    memberRepository.getMyPageInfo(),
    missionRepository.getTodayMission(),
    missionRepository.getWeeklyStatus(),
  ]);

  // 결과를 HomeScreenData 객체에 담아 반환합니다.
  return HomeScreenData(
    myPageInfo: results[0] as dynamic,
    dailyMission: results[1] as dynamic,
    weeklyStatus: results[2] as dynamic,
  );
});

// ✨ myPageInfoProvider와 weeklyStatusProvider는 이제 homeScreenDataProvider로 통합되었으므로,
//    이 파일이나 다른 곳에서 개별적으로 정의할 필요가 없습니다.

