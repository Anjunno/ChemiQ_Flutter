// import '../../data/models/dailyMission_response.dart';
// import '../../data/models/myPage_response.dart';
// import '../../data/models/weekly_status_dto.dart';
// import 'package:chemiq/data/repositories/member_repository.dart';
// import 'package:chemiq/data/repositories/mission_repository.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// // ✨ 1. 오늘의 미션 상태를 관리하는 StateNotifierProvider
// //    (파트너가 없을 때 에러가 나도 UI는 멈추지 않도록 설계)
// class HomeState {
//   final bool isLoading;
//   final DailyMissionResponse? dailyMission;
//   final String? error;
//   HomeState({this.isLoading = true, this.dailyMission, this.error});
//   HomeState copyWith({bool? isLoading, DailyMissionResponse? dailyMission, String? error}) {
//     return HomeState(
//       isLoading: isLoading ?? this.isLoading,
//       dailyMission: dailyMission, // null로 업데이트 될 수 있도록 ?? 제거
//       error: error,
//     );
//   }
// }
//
// class HomeViewModel extends StateNotifier<HomeState> {
//   final MissionRepository _missionRepository;
//   HomeViewModel(this._missionRepository) : super(HomeState());
//
//   Future<void> fetchTodayMission() async {
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final mission = await _missionRepository.getTodayMission();
//       state = state.copyWith(isLoading: false, dailyMission: mission);
//     } catch (e) {
//       // 파트너가 없어서 발생하는 에러는 '실패'가 아닌 '미션 없음' 상태로 간주합니다.
//       if (e is DioException && (e.response?.statusCode == 403 || e.response?.statusCode == 404)) {
//         state = state.copyWith(isLoading: false, dailyMission: null);
//       } else {
//         state = state.copyWith(isLoading: false, error: '미션을 불러오는 데 실패했어요.');
//       }
//     }
//   }
// }
//
// final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
//   final missionRepository = ref.watch(missionRepositoryProvider);
//   return HomeViewModel(missionRepository)..fetchTodayMission();
// });
//
//
// // ✨ 2. 마이페이지 정보를 불러오는 FutureProvider
// final myPageInfoProvider = FutureProvider.autoDispose<MyPageResponse>((ref) {
//   final memberRepository = ref.watch(memberRepositoryProvider);
//   return memberRepository.getMyPageInfo();
// });
//
// // ✨ 3. 주간 현황 정보를 불러오는 FutureProvider
// final weeklyStatusProvider = FutureProvider.autoDispose<WeeklyMissionStatusResponse?>((ref) {
//   final missionRepository = ref.watch(missionRepositoryProvider);
//   try {
//     // 파트너가 없으면 이 API는 실패하므로, 에러를 잡아 null을 반환합니다.
//     return missionRepository.getWeeklyStatus();
//   } catch (e) {
//     return null;
//   }
// });
//

import '../../data/models/dailyMission_response.dart';
import '../../data/models/home_summary_dto.dart';
import '../../data/models/myPage_response.dart';
import '../../data/models/weekly_status_dto.dart';
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart'; // AuthStateProvider import 추가


// ✨ 홈 화면에 필요한 모든 데이터를 단 한 번의 API 호출로 가져오는 최종 Provider
final homeSummaryProvider = FutureProvider.autoDispose<HomeSummaryDto>((ref) {
  // MemberRepository를 통해 새로운 통합 API를 호출합니다.
  final memberRepository = ref.watch(memberRepositoryProvider);
  return memberRepository.getHomeSummary();
});


//
// // ... HomeState, HomeViewModel 클래스는 그대로 둡니다 ...
// class HomeState {
//   final bool isLoading;
//   final DailyMissionResponse? dailyMission;
//   final String? error;
//   HomeState({this.isLoading = true, this.dailyMission, this.error});
//   HomeState copyWith({bool? isLoading, DailyMissionResponse? dailyMission, String? error}) {
//     return HomeState(
//       isLoading: isLoading ?? this.isLoading,
//       dailyMission: dailyMission,
//       error: error,
//     );
//   }
// }
//
// class HomeViewModel extends StateNotifier<HomeState> {
//   final MissionRepository _missionRepository;
//   HomeViewModel(this._missionRepository) : super(HomeState());
//
//   Future<void> fetchTodayMission() async {
//     if (!mounted) return;
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final mission = await _missionRepository.getTodayMission();
//       if (!mounted) return;
//       state = state.copyWith(isLoading: false, dailyMission: mission);
//     } catch (e) {
//       if (!mounted) return;
//       if (e is DioException && (e.response?.statusCode == 403 || e.response?.statusCode == 404)) {
//         state = state.copyWith(isLoading: false, dailyMission: null);
//       } else {
//         state = state.copyWith(isLoading: false, error: '미션을 불러오는 데 실패했어요.');
//       }
//     }
//   }
// }
//
// final homeViewModelProvider = StateNotifierProvider.autoDispose<HomeViewModel, HomeState>((ref) {
//   final missionRepository = ref.watch(missionRepositoryProvider);
//   return HomeViewModel(missionRepository)..fetchTodayMission();
// });
//
//
// // ✨ 2. 마이페이지 정보를 불러오는 FutureProvider (수정됨)
// final myPageInfoProvider = FutureProvider.autoDispose<MyPageResponse>((ref) {
//   // ★★★★★ 추가된 부분 ★★★★★
//   // 인증 상태를 감시합니다.
//   final authState = ref.watch(authStateProvider);
//
//   // 로그인 상태일 때만 API를 호출합니다.
//   if (authState == AuthState.authenticated) {
//     final memberRepository = ref.watch(memberRepositoryProvider);
//     return memberRepository.getMyPageInfo();
//   } else {
//     // 로그인 상태가 아니면, 에러를 발생시켜 더 이상 진행하지 않습니다.
//     // UI에서는 .when()의 error 콜백으로 이 상태를 처리할 수 있습니다.
//     throw Exception('Not authenticated');
//   }
// });
//
// // ✨ 3. 주간 현황 정보를 불러오는 FutureProvider (수정됨)
// final weeklyStatusProvider = FutureProvider.autoDispose<WeeklyMissionStatusResponse?>((ref) {
//   // ★★★★★ 추가된 부분 ★★★★★
//   // 인증 상태를 감시합니다.
//   final authState = ref.watch(authStateProvider);
//
//   // 로그인 상태일 때만 API를 호출합니다.
//   if (authState == AuthState.authenticated) {
//     final missionRepository = ref.watch(missionRepositoryProvider);
//     try {
//       return missionRepository.getWeeklyStatus();
//     } catch (e) {
//       return null;
//     }
//   } else {
//     // 로그인 상태가 아니면 null을 반환합니다.
//     return Future.value(null);
//   }
// });
//
