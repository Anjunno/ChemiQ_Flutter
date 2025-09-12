import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/auth_repository.dart';

// 회원가입 화면의 상태를 정의하는 클래스
class SignUpState {
  final bool isLoading;      // 로딩 중인지 여부
  final String? error;       // 에러 메시지
  final bool signUpSuccess;  // 회원가입 성공 여부

  SignUpState({
    this.isLoading = false,
    this.error,
    this.signUpSuccess = false,
  });

  // 상태를 쉽게 복사하고 일부 값만 변경할 수 있게 해주는 copyWith 메서드
  SignUpState copyWith({
    bool? isLoading,
    String? error,
    bool? signUpSuccess,
  }) {
    return SignUpState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // error는 null로 초기화될 수 있도록 ??를 사용하지 않음
      signUpSuccess: signUpSuccess ?? this.signUpSuccess,
    );
  }
}

// 상태(SignUpState)와 비즈니스 로직을 관리하는 ViewModel
class SignUpViewModel extends StateNotifier<SignUpState> {
  final AuthRepository _authRepository;

  SignUpViewModel(this._authRepository) : super(SignUpState());

  Future<void> signUp({
    required String memberId,
    required String password,
    required String nickname,
  }) async {
    // 이미 로딩 중이면 다시 요청하지 않도록 방어
    if (state.isLoading) return;

    // 로딩 상태 시작, 이전 에러 메시지는 초기화
    state = state.copyWith(isLoading: true, error: null, signUpSuccess: false);

    try {
      // Repository를 통해 실제 회원가입 API를 호출
      await _authRepository.signUp(
        memberId: memberId,
        password: password,
        nickname: nickname,
      );
      // 성공 시, 성공 상태로 변경
      state = state.copyWith(isLoading: false, signUpSuccess: true);
    } catch (e) {
      // 실패 시, 에러 상태로 변경하고 에러 메시지를 저장
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// SignUpViewModel의 인스턴스를 UI에 제공하는 Provider
final signUpViewModelProvider =
StateNotifierProvider.autoDispose<SignUpViewModel, SignUpState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return SignUpViewModel(authRepository);
});
