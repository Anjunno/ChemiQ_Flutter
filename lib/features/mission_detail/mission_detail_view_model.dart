import 'package:chemiq/data/models/evaluation_detail_dto.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 미션 상세 화면의 상태를 관리하는 클래스
class MissionDetailState {
  final SubmissionDetailDto submission;      // 표시할 제출물 정보
  final bool isLoading;                      // 평가 정보 로딩 여부
  final EvaluationDetailDto? evaluation;     // 불러온 파트너의 평가
  final String? error;

  MissionDetailState({
    required this.submission,
    this.isLoading = true,
    this.evaluation,
    this.error,
  });

  MissionDetailState copyWith({
    bool? isLoading,
    EvaluationDetailDto? evaluation,
    String? error,
  }) {
    return MissionDetailState(
      submission: this.submission,
      isLoading: isLoading ?? this.isLoading,
      evaluation: evaluation, // null로 초기화될 수 있도록 ?? 제거
      error: error,
    );
  }
}

// ViewModel
class MissionDetailViewModel extends StateNotifier<MissionDetailState> {
  final MissionRepository _missionRepository;

  MissionDetailViewModel(
      this._missionRepository,
      SubmissionDetailDto initialSubmission,
      ) : super(MissionDetailState(submission: initialSubmission)) {
    fetchEvaluation(); // ViewModel 생성 시 바로 평가 정보 로드
  }

  /// 서버에서 파트너의 평가 정보를 불러옵니다.
  Future<void> fetchEvaluation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final evaluation = await _missionRepository.getEvaluationForSubmission(state.submission.submissionId);
      state = state.copyWith(isLoading: false, evaluation: evaluation);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider (family를 사용하여 어떤 제출물에 대한 ViewModel인지 구분)
final missionDetailViewModelProvider = StateNotifierProvider.family
    .autoDispose<MissionDetailViewModel, MissionDetailState, SubmissionDetailDto>(
        (ref, submission) {
      final missionRepository = ref.watch(missionRepositoryProvider);
      return MissionDetailViewModel(missionRepository, submission);
    });

