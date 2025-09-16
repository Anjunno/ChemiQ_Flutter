import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EvaluationStatus { idle, loading, success, error }

class EvaluationState {
  final EvaluationStatus status;
  final String? errorMessage;
  final double score;
  final String comment;

  // ✨ 코멘트만 입력되면 버튼이 활성화되도록 수정 (점수는 0점도 가능)
  bool get isFormValid => comment.isNotEmpty;

  EvaluationState({
    this.status = EvaluationStatus.idle,
    this.errorMessage,
    this.score = 0.0, // ✨ 초기 점수를 0으로 설정하여 사용자의 선택을 유도
    this.comment = '',
  });

  EvaluationState copyWith({
    EvaluationStatus? status,
    String? errorMessage,
    double? score,
    String? comment,
  }) {
    return EvaluationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      score: score ?? this.score,
      comment: comment ?? this.comment,
    );
  }
}

// ViewModel
class EvaluationViewModel extends StateNotifier<EvaluationState> {
  final MissionRepository _missionRepository;

  EvaluationViewModel(this._missionRepository) : super(EvaluationState());

  void onScoreChanged(double newScore) {
    state = state.copyWith(score: newScore);
  }

  void onCommentChanged(String newComment) {
    state = state.copyWith(comment: newComment);
  }

  Future<void> submitEvaluation({required int submissionId}) async {
    if (!state.isFormValid || state.status == EvaluationStatus.loading) return;
    state = state.copyWith(status: EvaluationStatus.loading, errorMessage: null);
    try {
      await _missionRepository.evaluateSubmission(
        submissionId: submissionId,
        score: state.score,
        comment: state.comment,
      );
      state = state.copyWith(status: EvaluationStatus.success);
    } catch (e) {
      state = state.copyWith(status: EvaluationStatus.error, errorMessage: e.toString());
    }
  }
}

final evaluationViewModelProvider =
StateNotifierProvider.autoDispose<EvaluationViewModel, EvaluationState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return EvaluationViewModel(missionRepository);
});

