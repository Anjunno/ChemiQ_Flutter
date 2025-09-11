// lib/features/auth/login/login_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/auth_repository.dart';

// 1. 로그인 화면의 상태를 나타내는 클래스
class LoginState {
  final bool isLoading;
  final String? error;
  final bool loginSuccess;

  LoginState({
    this.isLoading = false,
    this.error,
    this.loginSuccess = false,
  });

  LoginState copyWith({bool? isLoading, String? error, bool? loginSuccess}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      loginSuccess: loginSuccess ?? this.loginSuccess,
    );
  }
}

// 2. 상태와 로직을 관리하는 ViewModel (StateNotifier)
class LoginViewModel extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository) : super(LoginState());

  Future<void> login(String memberId, String password) async {
    // 이미 로딩 중이면 다시 호출하지 않음
    if (state.isLoading) return;

    // 로딩 시작
    state = state.copyWith(isLoading: true, error: null, loginSuccess: false);

    try {
      await _authRepository.login(memberId: memberId, password: password);
      // 성공 시
      state = state.copyWith(isLoading: false, loginSuccess: true);
    } catch (e) {
      // 실패 시
      state = state.copyWith(isLoading: false, error: '아이디 또는 비밀번호를 확인해주세요.');
    }
  }
}

// 3. ViewModel을 UI에 제공하는 Provider
final loginViewModelProvider =
StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginViewModel(authRepository);
});