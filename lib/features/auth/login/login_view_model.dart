// lib/features/auth/login/login_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chemiq/data/repositories/auth_repository.dart';

import '../provider/auth_state_provider.dart';

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
  final AuthStateNotifier _authStateNotifier; // 전역 인증 상태 관리자를 제어하기 위해 추가

  // 생성자에서 AuthStateNotifier를 주입받도록 수정
  LoginViewModel(this._authRepository, this._authStateNotifier) : super(LoginState());

  Future<void> login(String memberId, String password) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.login(memberId: memberId, password: password);

      // ★★★ 핵심 수정사항 ★★★
      // 로그인 성공 후, 전역 인증 상태 관리자에게 상태를 다시 확인하라고 알려줍니다.
      // 이 호출로 인해 AuthStateProvider의 상태가 'authenticated'로 변경됩니다.
      await _authStateNotifier.checkAuthStatus();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '아이디 또는 비밀번호를 확인해주세요.');
    }
  }
}

// 3. ViewModel을 UI에 제공하는 Provider
final loginViewModelProvider =
StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  // 전역 AuthStateNotifier를 읽어와서 LoginViewModel에 주입합니다.
  final authStateNotifier = ref.read(authStateProvider.notifier);
  return LoginViewModel(authRepository, authStateNotifier);
});