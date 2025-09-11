import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chemiq/core/di/service_locator.dart';

// 인증 상태를 나타내는 Enum
enum AuthState {
  unknown, // 확인되지 않음 (앱 시작 초기 상태)
  unauthenticated, // 로그아웃됨
  authenticated, // 로그인됨
}

// 인증 상태를 관리하는 Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;

  AuthStateNotifier(this._storage) : super(AuthState.unknown) {
    checkAuthStatus();
  }

  // 앱 시작 시 토큰 유무를 확인하여 초기 상태 결정
  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  // 로그아웃 처리
  Future<void> logout() async {
    await _storage.deleteAll(); // 모든 토큰 삭제
    state = AuthState.unauthenticated; // 상태를 로그아웃으로 변경
    print('모든 토큰 삭제 및 로그아웃 처리 완료.');
  }
}

// AuthStateNotifier를 제공하는 Provider
final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  // get_it을 통해 FlutterSecureStorage 인스턴스를 가져옴
  return AuthStateNotifier(serviceLocator<FlutterSecureStorage>());
});