import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 평가 과정의 상태를 나타내는 Enum
enum EvaluationStatus { idle, loading, success, error }

class EvaluationState {
  final EvaluationStatus status;
  final String? errorMessage;

  EvaluationState({
    this.status = EvaluationStatus.idle,
    this.errorMessage,
  });

  EvaluationState copyWith({
    EvaluationStatus? status,
    String? errorMessage,
  }) {
    return EvaluationState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class EvaluationViewModel extends StateNotifier<EvaluationState> {
  final MissionRepository _missionRepository;

  EvaluationViewModel(this._missionRepository) : super(EvaluationState());

  Future<void> submitEvaluation({
    required int submissionId,
    required double score,
    required String comment,
  }) async {
    if (state.status == EvaluationStatus.loading) return;
    state = state.copyWith(status: EvaluationStatus.loading, errorMessage: null);

    try {
      await _missionRepository.evaluateSubmission(
        submissionId: submissionId,
        score: score,
        comment: comment,
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
