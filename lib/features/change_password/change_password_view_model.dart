import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 비밀번호 변경 화면의 상태
class ChangePasswordState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  ChangePasswordState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

// 비밀번호 변경 로직을 관리하는 ViewModel
class ChangePasswordViewModel extends StateNotifier<ChangePasswordState> {
  final MemberRepository _memberRepository;

  ChangePasswordViewModel(this._memberRepository) : super(ChangePasswordState());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      state = state.copyWith(errorMessage: '새 비밀번호가 일치하지 않아요.');
      return;
    }
    state = state.copyWith(isLoading: true, successMessage: null, errorMessage: null);
    try {
      await _memberRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, successMessage: '비밀번호가 성공적으로 변경되었어요.');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Provider
final changePasswordViewModelProvider =
StateNotifierProvider.autoDispose<ChangePasswordViewModel, ChangePasswordState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return ChangePasswordViewModel(memberRepository);
});
