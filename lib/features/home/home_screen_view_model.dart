
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dailyMission_response.dart';

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
      state = state.copyWith(isLoading: false, error: '미션을 불러오는 데 실패했어요.');
    }
  }
}

// HomeViewModel의 인스턴스를 UI에 제공하는 Provider
final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return HomeViewModel(missionRepository);
});

