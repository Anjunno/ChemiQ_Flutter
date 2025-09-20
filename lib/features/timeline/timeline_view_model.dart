
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dailyMission_response.dart';
import '../../data/models/myPage_response.dart';
import '../../data/repositories/member_repository.dart';
import '../auth/provider/auth_state_provider.dart';

// ✨ 상태 클래스가 DailyMissionResponse를 사용하도록 수정합니다.
class TimelineState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<DailyMissionResponse> missions;
  final int page;
  final bool canLoadMore;

  TimelineState({
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.missions = const [],
    this.page = 0,
    this.canLoadMore = true,
  });

  TimelineState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<DailyMissionResponse>? missions,
    int? page,
    bool? canLoadMore,
  }) {
    return TimelineState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      missions: missions ?? this.missions,
      page: page ?? this.page,
      canLoadMore: canLoadMore ?? this.canLoadMore,
    );
  }
}

// ViewModel
class TimelineViewModel extends StateNotifier<TimelineState> {
  final MissionRepository _missionRepository;

  TimelineViewModel(this._missionRepository) : super(TimelineState()) {
    fetchInitialTimeline();
  }

  /// ✨ API 호출 결과 타입이 DailyMissionResponse 목록을 받도록 수정합니다.
  Future<void> fetchInitialTimeline() async {
    state = state.copyWith(isLoading: true, page: 0, canLoadMore: true, missions: []);
    try {
      final newMissions = await _missionRepository.getTimeline(page: 0);
      state = state.copyWith(isLoading: false, missions: newMissions, page: 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.canLoadMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final newMissions = await _missionRepository.getTimeline(page: state.page);
      if (newMissions.isEmpty) {
        state = state.copyWith(isLoadingMore: false, canLoadMore: false);
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          missions: [...state.missions, ...newMissions],
          page: state.page + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

// Provider
final timelineViewModelProvider =
StateNotifierProvider.autoDispose<TimelineViewModel, TimelineState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return TimelineViewModel(missionRepository);
});

final timelineMyPageProvider = FutureProvider.autoDispose<MyPageResponse>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState == AuthState.authenticated) {
    final memberRepository = ref.watch(memberRepositoryProvider);
    return memberRepository.getMyPageInfo();
  } else {
    throw Exception('Not authenticated');
  }
});
