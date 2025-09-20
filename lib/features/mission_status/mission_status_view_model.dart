
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';

import '../../data/models/dailyMission_response.dart';
import '../../data/models/myPage_response.dart';

// MissionStatusState 클래스는 수정사항이 없습니다.
class MissionStatusState {
  final bool isLoading;
  final DailyMissionResponse? dailyMission;
  final String? error;
  MissionStatusState({this.isLoading = true, this.dailyMission, this.error});

  MissionStatusState copyWith({bool? isLoading, DailyMissionResponse? dailyMission, String? error}) {
    return MissionStatusState(
      isLoading: isLoading ?? this.isLoading,
      dailyMission: dailyMission,
      error: error,
    );
  }
}

class MissionStatusViewModel extends StateNotifier<MissionStatusState> {
  final MissionRepository _missionRepository;
  MissionStatusViewModel(this._missionRepository) : super(MissionStatusState());

  Future<void> fetchTodayMission() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final mission = await _missionRepository.getTodayMission();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, dailyMission: mission);
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && (e.response?.statusCode == 403 || e.response?.statusCode == 404)) {
        state = state.copyWith(isLoading: false, dailyMission: null);
      } else {
        state = state.copyWith(isLoading: false, error: '미션을 불러오는 데 실패했어요.');
      }
    }
  }
}

// ✨ ViewModel이 생성되는 즉시 fetchTodayMission()을 호출하도록 수정합니다.
final missionStatusViewModelProvider = StateNotifierProvider.autoDispose<MissionStatusViewModel, MissionStatusState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  // ViewModel 인스턴스를 만들고, 바로 fetch 메서드를 실행합니다.
  return MissionStatusViewModel(missionRepository)..fetchTodayMission();
});

// 미션 현황에 필요한 마이페이지 정보 Provider (수정사항 없음)
final missionStatusMyPageProvider = FutureProvider.autoDispose<MyPageResponse>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState == AuthState.authenticated) {
    final memberRepository = ref.watch(memberRepositoryProvider);
    return memberRepository.getMyPageInfo();
  } else {
    throw Exception('Not authenticated');
  }
});