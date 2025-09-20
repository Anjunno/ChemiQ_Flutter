
import 'package:chemiq/data/models/partnership_sent_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/partnership_repository.dart';

import '../../core/ui/chemiq_toast.dart';
import '../../data/models/partner_receive_response.dart';
import '../auth/provider/home_screen_data_provider.dart';
import '../auth/provider/partner_state_provider.dart';
import '../home/home_screen_view_model.dart';
import '../mission_status/mission_status_view_model.dart';
import '../mypage/mypage_view_model.dart';
import '../timeline/timeline_view_model.dart';

// PartnerLinkingState 클래스는 수정사항이 없습니다.
class PartnerLinkingState {
  final bool isRequesting;
  final String? requestError;
  final bool requestSuccess;
  final bool areListsLoading;
  final String? listError;
  final List<PartnershipSentResponse> sentRequests;
  final List<PartnershipReceiveResponse> receivedRequests;

  PartnerLinkingState({
    this.isRequesting = false,
    this.requestError,
    this.requestSuccess = false,
    this.areListsLoading = true,
    this.listError,
    this.sentRequests = const [],
    this.receivedRequests = const [],
  });

  PartnerLinkingState copyWith({
    bool? isRequesting, String? requestError, bool? requestSuccess,
    bool? areListsLoading, String? listError,
    List<PartnershipSentResponse>? sentRequests,
    List<PartnershipReceiveResponse>? receivedRequests,
  }) {
    return PartnerLinkingState(
      isRequesting: isRequesting ?? this.isRequesting,
      requestError: requestError,
      requestSuccess: requestSuccess ?? this.requestSuccess,
      areListsLoading: areListsLoading ?? this.areListsLoading,
      listError: listError,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedRequests: receivedRequests ?? this.receivedRequests,
    );
  }
}

// ViewModel
class PartnerLinkingViewModel extends StateNotifier<PartnerLinkingState> {
  final PartnershipRepository _repository;
  final Ref _ref;

  PartnerLinkingViewModel(this._repository, this._ref) : super(PartnerLinkingState());

  Future<void> fetchRequests() async {
    state = state.copyWith(areListsLoading: true, listError: null);
    try {
      final results = await Future.wait([
        _repository.getSentRequests(),
        _repository.getReceivedRequests(),
      ]);
      state = state.copyWith(
        areListsLoading: false,
        sentRequests: results[0] as List<PartnershipSentResponse>,
        receivedRequests: results[1] as List<PartnershipReceiveResponse>,
      );
    } catch (e) {
      state = state.copyWith(areListsLoading: false, listError: '요청 목록을 불러오는 데 실패했어요.');
    }
  }

  Future<void> requestPartnership(String partnerId) async {
    if (state.isRequesting) return;
    state = state.copyWith(isRequesting: true, requestError: null, requestSuccess: false);
    try {
      await _repository.requestPartnership(partnerId: partnerId);
      state = state.copyWith(isRequesting: false, requestSuccess: true);
      await fetchRequests();
    } catch (e) {
      state = state.copyWith(isRequesting: false, requestError: e.toString());
    }
  }

  // ✨ 요청 수락 로직 수정
  Future<void> accept(int id) async {
    await _handleAction(() => _repository.acceptRequest(id));
    showChemiQToast("파트너를 수락했습니다.", type: ToastType.success);

    // ★★★ 중요: 파트너 관계가 생성되었으므로, 관련된 모든 데이터 Provider를 갱신합니다.
    _ref.invalidate(partnerStateProvider); // 1. 라우터가 반응하도록
    _ref.invalidate(homeSummaryProvider);   // 2. 홈 화면 데이터가 갱신되도록

    // ✨ 3. 다른 탭의 데이터 Provider들도 무효화하여, 다음에 해당 탭으로 이동했을 때
    //    최신 정보를 다시 불러오도록 합니다.
    _ref.invalidate(missionStatusViewModelProvider);
    _ref.invalidate(timelineViewModelProvider);
    // _ref.invalidate(myPageViewModelProvider);
  }


  Future<void> reject(int id) async {
    await _handleAction(() => _repository.rejectRequest(id));
  }

  Future<void> cancel(int id) async {
    await _handleAction(() => _repository.cancelRequest(id));
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      await action();
      await fetchRequests();
    } catch (e) {
      print("요청 처리 실패: $e");
    }
  }
}

// Provider
final partnerLinkingViewModelProvider =
StateNotifierProvider.autoDispose<PartnerLinkingViewModel, PartnerLinkingState>((ref) {
  final repository = ref.watch(partnershipRepositoryProvider);
  return PartnerLinkingViewModel(repository, ref);
});

