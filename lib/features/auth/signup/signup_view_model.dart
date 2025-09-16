import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/auth_repository.dart';

// 비밀번호 규칙의 각 항목 상태
class PasswordRequirement {
  final String text;
  final bool met;
  const PasswordRequirement(this.text, this.met);
}

// 회원가입 화면의 모든 상태를 관리하는 클래스
class SignUpState {
  // 입력값
  final String memberId;
  final String password;
  final String confirmPassword;
  final String nickname;

  // 유효성 검사 결과
  final bool isIdValid;
  final List<PasswordRequirement> passwordRequirements;
  final bool isPasswordValid;
  final bool doPasswordsMatch;
  final bool isNicknameValid;

  // API 요청 상태
  final bool isLoading;
  final bool signUpSuccess;
  final String? errorMessage;

  // 모든 조건이 충족되었는지 확인하는 getter
  bool get isFormValid => isIdValid && isPasswordValid && doPasswordsMatch && isNicknameValid;

  SignUpState({
    this.memberId = '',
    this.password = '',
    this.confirmPassword = '',
    this.nickname = '',
    this.isIdValid = false,
    this.passwordRequirements = const [
      PasswordRequirement("8~16자 입력", false),
      PasswordRequirement("영문 포함", false),
      PasswordRequirement("숫자 포함", false),
      PasswordRequirement("특수문자 포함", false),
    ],
    this.isPasswordValid = false,
    this.doPasswordsMatch = false,
    this.isNicknameValid = false,
    this.isLoading = false,
    this.signUpSuccess = false,
    this.errorMessage,
  });

  SignUpState copyWith({
    String? memberId, String? password, String? confirmPassword, String? nickname,
    bool? isIdValid, List<PasswordRequirement>? passwordRequirements, bool? isPasswordValid,
    bool? doPasswordsMatch, bool? isNicknameValid, bool? isLoading,
    bool? signUpSuccess, String? errorMessage,
  }) {
    return SignUpState(
      memberId: memberId ?? this.memberId,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      nickname: nickname ?? this.nickname,
      isIdValid: isIdValid ?? this.isIdValid,
      passwordRequirements: passwordRequirements ?? this.passwordRequirements,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      doPasswordsMatch: doPasswordsMatch ?? this.doPasswordsMatch,
      isNicknameValid: isNicknameValid ?? this.isNicknameValid,
      isLoading: isLoading ?? this.isLoading,
      signUpSuccess: signUpSuccess ?? this.signUpSuccess,
      errorMessage: errorMessage,
    );
  }
}

// ViewModel
class SignUpViewModel extends StateNotifier<SignUpState> {
  final AuthRepository _authRepository;

  SignUpViewModel(this._authRepository) : super(SignUpState());

  // 아이디 유효성 검사
  void validateId(String memberId) {
    final isValid = memberId.length >= 5 && memberId.length <= 12 && !memberId.contains(' ');
    state = state.copyWith(memberId: memberId, isIdValid: isValid);
  }

  // 비밀번호 유효성 검사 (규칙 체크리스트)
  void validatePassword(String password) {
    final requirements = [
      PasswordRequirement("8~16자 입력", password.length >= 8 && password.length <= 16),
      PasswordRequirement("영문 포함", RegExp(r'[a-zA-Z]').hasMatch(password)),
      PasswordRequirement("숫자 포함", RegExp(r'[0-9]').hasMatch(password)),
      PasswordRequirement("특수문자 포함", RegExp(r'[\W_]').hasMatch(password)),
    ];
    final isPasswordValid = requirements.every((req) => req.met);
    state = state.copyWith(
      password: password,
      passwordRequirements: requirements,
      isPasswordValid: isPasswordValid,
    );
    // 비밀번호가 바뀌면, 확인 필드도 다시 검사
    validateConfirmPassword(state.confirmPassword);
  }

  // 비밀번호 확인 유효성 검사
  void validateConfirmPassword(String confirmPassword) {
    final doPasswordsMatch = state.password.isNotEmpty && state.password == confirmPassword;
    state = state.copyWith(confirmPassword: confirmPassword, doPasswordsMatch: doPasswordsMatch);
  }

  // 닉네임 유효성 검사
  void validateNickname(String nickname) {
    final isValid = nickname.length >= 2 && nickname.length <= 6 && !nickname.contains(' ');
    state = state.copyWith(nickname: nickname, isNicknameValid: isValid);
  }

  // 최종 회원가입 요청
  Future<void> signUp() async {
    if (!state.isFormValid || state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authRepository.signUp(
        memberId: state.memberId,
        password: state.password,
        nickname: state.nickname,
      );
      state = state.copyWith(isLoading: false, signUpSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

// Provider
final signUpViewModelProvider =
StateNotifierProvider.autoDispose<SignUpViewModel, SignUpState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignUpViewModel(authRepository);
});

