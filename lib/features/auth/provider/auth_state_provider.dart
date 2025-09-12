import 'package:chemiq/data/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chemiq/core/di/service_locator.dart';

enum AuthState {
  unknown,
  unauthenticated,
  authenticated,
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final AuthRepository _authRepository;

  AuthStateNotifier(this._storage, this._authRepository) : super(AuthState.unknown) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      state = AuthState.authenticated;
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _storage.deleteAll();
    state = AuthState.unauthenticated;
    print('클라이언트/서버 로그아웃이 모두 완료되었습니다.');
  }

  Future<void> test() async {
    await _authRepository.test();
  }
}



/// (✨ 오류가 발생한 바로 이 부분입니다)
final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  // 재료 1: FlutterSecureStorage
  final storage = serviceLocator<FlutterSecureStorage>();

  // 재료 2: AuthRepository
  final authRepository = ref.watch(authRepositoryProvider);

  // 이제 두 재료를 모두 넣어서 AuthStateNotifier를 만듭니다.
  return AuthStateNotifier(storage, authRepository);
});

