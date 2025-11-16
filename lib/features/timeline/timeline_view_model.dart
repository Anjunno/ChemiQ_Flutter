import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dailyMission_response.dart';
import '../../data/models/myPage_response.dart';
import '../../data/repositories/member_repository.dart';
import '../auth/provider/auth_state_provider.dart';

// 페이지 크기(size=10)를 사용.
const int _pageSize = 10;

// 상태 클래스가 DailyMissionResponse를 사용하도록 수정.
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

  /// ✨ 제출 기록이 있는 페이지를 찾을 때까지 다음 페이지를 로드합니다.
  Future<void> fetchInitialTimeline() async {
    state = state.copyWith(isLoading: true, page: 0, canLoadMore: true, missions: []);

    int currentPage = 0;
    List<DailyMissionResponse> foundMissions = [];
    bool isLastPage = false;

    // 제출 기록이 있는 페이지를 찾거나, 마지막 페이지에 도달할 때까지 반복
    while (foundMissions.isEmpty && !isLastPage) {
      print('DEBUG: Attempting to fetch initial page: $currentPage');

      try {
        final newMissions = await _missionRepository.getTimeline(page: currentPage);

        if (newMissions.isEmpty) {
          isLastPage = true;
          print('DEBUG: API returned empty list for page $currentPage. Setting last page.');
          break;
        }

        //  나와 파트너 모두 제출하지 않은 미션은 필터링합니다.
        final filteredMissions = newMissions.where(
              (mission) => mission.mySubmission != null || mission.partnerSubmission != null,
        ).toList();

        print('DEBUG: Page $currentPage fetched ${newMissions.length} items. Filtered to ${filteredMissions.length} items.'); // ❗ 디버깅 로그

        if (filteredMissions.isNotEmpty) {
          // 제출 기록이 있는 미션을 찾았으면 루프 종료
          foundMissions = filteredMissions;
          isLastPage = newMissions.length < _pageSize; //페이지 크기 10으로 수정
          currentPage++; // 다음 로드를 위해 페이지 번호 증가
          print('DEBUG: Found content on page ${currentPage - 1}. Next page to fetch is $currentPage.');
          break;
        }

        // 현재 페이지에는 유의미한 제출물이 없었으므로 다음 페이지를 로드합니다.
        print('DEBUG: Page $currentPage was empty after filtering. Moving to next page.');
        currentPage++;

      } catch (e) {
        print('DEBUG: Error during initial timeline fetch on page $currentPage: $e');
        state = state.copyWith(isLoading: false, error: e.toString());
        return;
      }
    }

    // 상태 업데이트
    final finalCanLoadMore = !isLastPage;

    state = state.copyWith(
      isLoading: false,
      missions: foundMissions,
      page: currentPage, // 다음 페이지 번호
      canLoadMore: finalCanLoadMore,
    );
    print('DEBUG: Initial fetch completed. Total missions: ${foundMissions.length}, Can load more: $finalCanLoadMore');
  }

  // loadMore에서도 제출 기록이 있는 페이지를 찾을 때까지 로드를 반복.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.canLoadMore) return;
    state = state.copyWith(isLoadingMore: true);

    int currentPage = state.page;
    List<DailyMissionResponse> newContent = [];
    bool foundContent = false;
    bool newIsLastPage = !state.canLoadMore;

    while (!foundContent && !newIsLastPage) {
      print('DEBUG: Attempting to load more page: $currentPage');

      try {
        final newMissions = await _missionRepository.getTimeline(page: currentPage);

        if (newMissions.isEmpty) {
          newIsLastPage = true;
          print('DEBUG: API returned empty list for page $currentPage. Setting last page to true.');
          break; // 더 이상 데이터 없음
        }

        // 나와 파트너 모두 제출하지 않은 미션은 필터링합니다.
        final filteredNewMissions = newMissions.where(
              (mission) => mission.mySubmission != null || mission.partnerSubmission != null,
        ).toList();

        print('DEBUG: Load more page $currentPage fetched ${newMissions.length} items. Filtered to ${filteredNewMissions.length} items.'); // ❗ 디버깅 로그

        if (filteredNewMissions.isNotEmpty) {
          newContent = filteredNewMissions;
          foundContent = true;
          newIsLastPage = newMissions.length < _pageSize;
        }

        currentPage++; // 다음 페이지 요청을 위해 페이지 번호 증가

      } catch (e) {
        print('DEBUG: Error during load more on page $currentPage: $e');
        state = state.copyWith(isLoadingMore: false, error: e.toString());
        return;
      }
    }

    // 상태 업데이트
    if (newContent.isNotEmpty) {
      state = state.copyWith(
        isLoadingMore: false,
        missions: [...state.missions, ...newContent],
        page: currentPage,
        canLoadMore: !newIsLastPage,
      );
      print('DEBUG: Load more successful. Added ${newContent.length} missions. Next page: $currentPage, Can load more: ${!newIsLastPage}');
    } else {
      // 새로운 내용이 없으면 (끝까지 찾았지만 발견 못함)
      state = state.copyWith(isLoadingMore: false, canLoadMore: false);
      print('DEBUG: Load more finished. No new missions found.');
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