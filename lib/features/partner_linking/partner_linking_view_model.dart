import 'package:chemiq/data/models/partnership_sent_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/partnership_repository.dart';

import '../../../data/models/partner_receive_response.dart';
import '../auth/provider/partner_state_provider.dart';

// 파트너 연결 화면의 모든 상태를 관리하는 클래스
class PartnerLinkingState {
  // '요청 보내기' 기능 관련 상태
  final bool isRequesting;      // 요청 보내기 로딩 여부
  final String? requestError;   // 요청 보내기 실패 시 에러 메시지
  final bool requestSuccess;    // 요청 보내기 성공 여부

  // '요청 목록 조회' 기능 관련 상태
  final bool areListsLoading;   // 목록 로딩 여부
  final String? listError;      // 목록 조회 실패 시 에러 메시지
  final List<PartnershipSentResponse> sentRequests;     // 보낸 요청 목록
  final List<PartnershipReceiveResponse> receivedRequests; // 받은 요청 목록

  PartnerLinkingState({
    this.isRequesting = false,
    this.requestError,
    this.requestSuccess = false,
    this.areListsLoading = true, // 화면 첫 진입 시 바로 로딩 시작
    this.listError,
    this.sentRequests = const [],
    this.receivedRequests = const [],
  });

  // 상태 객체를 불변으로 유지하면서 특정 값만 쉽게 변경하기 위한 메서드
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

// 상태(PartnerLinkingState)와 로직을 관리하는 ViewModel
class PartnerLinkingViewModel extends StateNotifier<PartnerLinkingState> {
  final PartnershipRepository _repository;
  final Ref _ref; // 다른 Provider를 읽어오기 위한 참조

  PartnerLinkingViewModel(this._repository, this._ref) : super(PartnerLinkingState());

  /// 화면에 필요한 모든 요청 목록(보낸/받은)을 서버에서 불러옵니다.
  Future<void> fetchRequests() async {
    state = state.copyWith(areListsLoading: true, listError: null);
    try {
      // 두 API를 동시에 호출하여 더 빠르게 데이터를 가져옵니다.
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

  /// 입력받은 아이디로 파트너 요청을 보냅니다.
  Future<void> requestPartnership(String partnerId) async {
    if (state.isRequesting) return;
    state = state.copyWith(isRequesting: true, requestError: null, requestSuccess: false);
    try {
      await _repository.requestPartnership(partnerId: partnerId);
      state = state.copyWith(isRequesting: false, requestSuccess: true);
      await fetchRequests(); // 요청 성공 후 목록을 새로고침합니다.
    } catch (e) {
      state = state.copyWith(isRequesting: false, requestError: e.toString());
    }
  }

  /// 받은 요청을 수락합니다.
  Future<void> accept(int id) async {
    await _handleAction(() => _repository.acceptRequest(id));
    // ★★★ 중요: 파트너 관계가 생성되었으므로, 전역 파트너 상태를 갱신합니다.
    // 이 코드로 인해 라우터가 리다이렉션을 실행하여 홈 화면으로 이동합니다.
    _ref.invalidate(partnerStateProvider);
  }

  /// 받은 요청을 거절합니다.
  Future<void> reject(int id) async {
    await _handleAction(() => _repository.rejectRequest(id));
  }

  /// 보낸 요청을 취소합니다.
  Future<void> cancel(int id) async {
    await _handleAction(() => _repository.cancelRequest(id));
  }

  /// 수락/거절/취소와 같이 반복되는 작업의 공통 로직을 처리하는 메서드
  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      await action();
      await fetchRequests(); // 액션 성공 후 목록을 항상 새로고침합니다.
    } catch (e) {
      // 에러는 UI의 ref.listen에서 스낵바 등으로 처리하므로, 여기서는 로그만 남깁니다.
      print("요청 처리 실패: $e");
    }
  }
}

// ViewModel의 인스턴스를 UI에 제공하는 Provider
final partnerLinkingViewModelProvider =
StateNotifierProvider.autoDispose<PartnerLinkingViewModel, PartnerLinkingState>((ref) {
  final repository = ref.watch(partnershipRepositoryProvider);
  return PartnerLinkingViewModel(repository, ref);
});

