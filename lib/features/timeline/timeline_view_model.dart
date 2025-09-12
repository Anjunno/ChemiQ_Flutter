
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dailyMission_response.dart';

class TimelineState {
  final bool isLoading;         // 초기 로딩 여부
  final bool isLoadingMore;     // 추가 로딩 여부
  final String? error;          // 에러 메시지
  final List<DailyMissionResponse> missions; // 불러온 미션 목록
  final int page;               // 현재 페이지 번호
  final bool canLoadMore;       // 더 불러올 페이지가 있는지 여부

  TimelineState({
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.missions = const [],
    this.page = 0,
    this.canLoadMore = true,
  });

  TimelineState copyWith({
    bool? isLoading, bool? isLoadingMore, String? error,
    List<DailyMissionResponse>? missions, int? page, bool? canLoadMore,
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

class TimelineViewModel extends StateNotifier<TimelineState> {
  final MissionRepository _missionRepository;

  TimelineViewModel(this._missionRepository) : super(TimelineState()) {
    fetchInitialTimeline(); // ViewModel이 생성되자마자 첫 페이지 로드
  }

  /// 첫 페이지의 타임라인 데이터를 불러옵니다.
  Future<void> fetchInitialTimeline() async {
    state = state.copyWith(isLoading: true, page: 0, canLoadMore: true);
    try {
      final newMissions = await _missionRepository.getTimeline(page: 0);
      state = state.copyWith(isLoading: false, missions: newMissions, page: 1);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 다음 페이지의 타임라인 데이터를 불러와 기존 목록에 추가합니다.
  Future<void> loadMore() async {
    // 이미 로딩 중이거나 더 이상 불러올 페이지가 없으면 실행하지 않음
    if (state.isLoadingMore || !state.canLoadMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final newMissions = await _missionRepository.getTimeline(page: state.page);
      if (newMissions.isEmpty) {
        // 새로 불러온 목록이 비어있으면, 더 이상 페이지가 없는 것으로 간주
        state = state.copyWith(isLoadingMore: false, canLoadMore: false);
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          missions: [...state.missions, ...newMissions], // 기존 목록에 새 목록 추가
          page: state.page + 1,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final timelineViewModelProvider =
StateNotifierProvider<TimelineViewModel, TimelineState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return TimelineViewModel(missionRepository);
});
