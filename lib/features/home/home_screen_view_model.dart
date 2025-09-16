
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dailyMission_response.dart';
import '../../data/models/myPage_response.dart';
import '../../data/models/weekly_status_dto.dart';
import '../../data/repositories/member_repository.dart';

// 홈 화면의 상태를 정의하는 클래스
class HomeState {
  final bool isLoading;                 // 데이터 로딩 여부
  final DailyMissionResponse? dailyMission; // 오늘의 미션 데이터 (없을 경우 null)
  final String? error;                  // 에러 메시지

  HomeState({
    this.isLoading = true, // 처음에는 항상 로딩 상태로 시작
    this.dailyMission,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    DailyMissionResponse? dailyMission,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      dailyMission: dailyMission ?? this.dailyMission,
      error: error,
    );
  }
}

// 상태(HomeState)와 로직을 관리하는 ViewModel
class HomeViewModel extends StateNotifier<HomeState> {
  final MissionRepository _missionRepository;

  HomeViewModel(this._missionRepository) : super(HomeState());

  /// 오늘의 미션 데이터를 서버에서 불러옵니다.
  Future<void> fetchTodayMission() async {
    // 이미 로딩 중이면 중복 호출 방지
    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final mission = await _missionRepository.getTodayMission();
      state = state.copyWith(isLoading: false, dailyMission: mission);
    } catch (e) {
      // ✨ 수정된 부분: 에러의 종류를 확인합니다.
      if (e is DioException && e.message == '인터넷 연결을 확인해주세요.') {
        // DioClient에서 보낸 인터넷 연결 에러일 경우, 그 메시지를 그대로 사용합니다.
        state = state.copyWith(isLoading: false, error: e.message);
      } else {
        // 그 외 다른 종류의 에러일 경우, 일반적인 메시지를 보여줍니다.
        state = state.copyWith(isLoading: false, error: '미션을 불러오는 데 실패했어요.');
      }
    }
  }
}

// HomeViewModel의 인스턴스를 UI에 제공하는 Provider
final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return HomeViewModel(missionRepository);
});


// ✨ 마이페이지 정보를 홈 화면에서 사용하기 위한 새로운 Provider를 추가합니다.
final myPageInfoProvider = FutureProvider.autoDispose<MyPageResponse>((ref) {
  // MemberRepository를 가져옵니다.
  final memberRepository = ref.watch(memberRepositoryProvider);
  // 마이페이지 정보를 조회하는 API를 호출하고 결과를 반환합니다.
  return memberRepository.getMyPageInfo();
});

// ✨ 주간 미션 현황 데이터를 WeeklyMissionStatusResponse로 제공하는 Provider
final weeklyStatusProvider = FutureProvider.autoDispose<WeeklyMissionStatusResponse>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return missionRepository.getWeeklyStatus();
});
