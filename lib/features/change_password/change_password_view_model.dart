import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 비밀번호 규칙의 각 항목 상태
class PasswordRequirement {
  final String text;
  final bool met;
  const PasswordRequirement(this.text, this.met);
}

// 비밀번호 변경 화면의 모든 상태를 관리하는 클래스
class ChangePasswordState {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  final bool isNewPasswordValid;
  final List<PasswordRequirement> passwordRequirements;
  final bool doPasswordsMatch;

  final bool isCurrentPasswordVisible;
  final bool isNewPasswordVisible;
  final bool isConfirmPasswordVisible;

  final bool isLoading;
  final bool changeSuccess;
  final String? successMessage;
  final String? errorMessage;

  // ✨ 최대 글자 수 제한을 상태에 추가
  final int passwordMaxLength = 16;

  bool get isFormValid =>
      currentPassword.isNotEmpty && isNewPasswordValid && doPasswordsMatch;

  ChangePasswordState({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.isNewPasswordValid = false,
    this.passwordRequirements = const [
      PasswordRequirement("8~16자 입력", false),
      PasswordRequirement("영문 포함", false),
      PasswordRequirement("숫자 포함", false),
      PasswordRequirement("특수문자 포함", false),
    ],
    this.doPasswordsMatch = false,
    this.isCurrentPasswordVisible = false,
    this.isNewPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
    this.isLoading = false,
    this.changeSuccess = false,
    this.successMessage,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    String? currentPassword, String? newPassword, String? confirmPassword,
    bool? isNewPasswordValid, List<PasswordRequirement>? passwordRequirements,
    bool? doPasswordsMatch, bool? isCurrentPasswordVisible, bool? isNewPasswordVisible,
    bool? isConfirmPasswordVisible, bool? isLoading, bool? changeSuccess,
    String? successMessage, String? errorMessage,
  }) {
    return ChangePasswordState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isNewPasswordValid: isNewPasswordValid ?? this.isNewPasswordValid,
      passwordRequirements: passwordRequirements ?? this.passwordRequirements,
      doPasswordsMatch: doPasswordsMatch ?? this.doPasswordsMatch,
      isCurrentPasswordVisible: isCurrentPasswordVisible ?? this.isCurrentPasswordVisible,
      isNewPasswordVisible: isNewPasswordVisible ?? this.isNewPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
      isLoading: isLoading ?? this.isLoading,
      changeSuccess: changeSuccess ?? this.changeSuccess,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

// ViewModel
class ChangePasswordViewModel extends StateNotifier<ChangePasswordState> {
  final MemberRepository _memberRepository;

  ChangePasswordViewModel(this._memberRepository) : super(ChangePasswordState());

  // 현재 비밀번호 입력값 업데이트
  void onCurrentPasswordChanged(String password) {
    state = state.copyWith(currentPassword: password);
  }

  // 새 비밀번호 유효성 검사
  void validateNewPassword(String password) {
    final requirements = [
      PasswordRequirement("8~16자 입력", password.length >= 8 && password.length <= 12),
      PasswordRequirement("영문 포함", RegExp(r'[a-zA-Z]').hasMatch(password)),
      PasswordRequirement("숫자 포함", RegExp(r'[0-9]').hasMatch(password)),
      PasswordRequirement("특수문자 포함", RegExp(r'[\W_]').hasMatch(password)),
    ];
    final isPasswordValid = requirements.every((req) => req.met);
    state = state.copyWith(
      newPassword: password,
      passwordRequirements: requirements,
      isNewPasswordValid: isPasswordValid,
    );
    validateConfirmPassword(state.confirmPassword);
  }

  // 새 비밀번호 확인 유효성 검사
  void validateConfirmPassword(String confirmPassword) {
    final doPasswordsMatch = state.newPassword.isNotEmpty && state.newPassword == confirmPassword;
    state = state.copyWith(confirmPassword: confirmPassword, doPasswordsMatch: doPasswordsMatch);
  }

  // 최종 비밀번호 변경 요청
  Future<void> changePassword() async {
    if (!state.isFormValid || state.isLoading) return;
    state = state.copyWith(isLoading: true, successMessage: null, errorMessage: null);
    try {
      await _memberRepository.changePassword(
        currentPassword: state.currentPassword,
        newPassword: state.newPassword,
      );
      state = state.copyWith(isLoading: false, changeSuccess: true, successMessage: '비밀번호가 성공적으로 변경되었어요.');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // 비밀번호 보이기/숨기기 상태를 토글하는 메서드들
  void toggleCurrentPasswordVisibility() {
    state = state.copyWith(isCurrentPasswordVisible: !state.isCurrentPasswordVisible);
  }
  void toggleNewPasswordVisibility() {
    state = state.copyWith(isNewPasswordVisible: !state.isNewPasswordVisible);
  }
  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible);
  }
}

// Provider
final changePasswordViewModelProvider =
StateNotifierProvider.autoDispose<ChangePasswordViewModel, ChangePasswordState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return ChangePasswordViewModel(memberRepository);
});

