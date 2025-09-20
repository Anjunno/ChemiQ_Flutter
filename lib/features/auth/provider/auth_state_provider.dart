import 'package:chemiq/data/repositories/auth_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';


import '../../../core/di/service_locator.dart';

// 인증 상태를 나타내는 Enum
enum AuthState {
  unknown,
  unauthenticated,
  authenticated,
}

// 인증 상태를 관리하는 Notifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final AuthRepository _authRepository;
  // ✨ MemberRepository를 더 이상 사용하지 않으므로 제거합니다.

  AuthStateNotifier(this._storage, this._authRepository) : super(AuthState.unknown) {
    checkAuthStatus();
  }

  /// 앱 시작 시 토큰의 실제 유효성을 서버에 확인하는 최종 로직
  // Future<void> checkAuthStatus() async {
  //   final token = await _storage.read(key: 'accessToken');
  //   if (token != null) {
  //     try {
  //       await _authRepository.validateToken();
  //       state = AuthState.authenticated;
  //       print("자동 로그인 유효성 검사 성공");
  //     } catch (e) {
  //       print("자동 로그인 실패 (토큰 만료): $e");
  //       await logout();
  //     }
  //   } else {
  //     state = AuthState.unauthenticated;
  //   }
  // }

  // Future<void> logout({BuildContext? context}) async {
  //   print('🔴 [AuthStateNotifier] logout() 시작');
  //   print('🔴 [AuthStateNotifier] 현재 상태: $state');
  //
  //   try {
  //     await _authRepository.logout();
  //     print('🔴 [AuthStateNotifier] 서버 로그아웃 완료');
  //   } catch (e) {
  //     print("🔴 [AuthStateNotifier] 서버 로그아웃 요청 실패: $e");
  //   } finally {
  //     await _storage.deleteAll();
  //     print('🔴 [AuthStateNotifier] 로컬 토큰 삭제 완료');
  //
  //     state = AuthState.unauthenticated;
  //     print('🔴 [AuthStateNotifier] 상태 변경 완료: $state');
  //
  //     // BuildContext가 있으면 즉시 로그인 페이지로 이동
  //     if (context != null) {
  //       print('🔄 강제 로그인 페이지 이동');
  //       context.go('/login');
  //     }
  //   }
  // }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      try {
        // 이 API 호출이 실패하면 DioException이 발생합니다.
        await _authRepository.validateToken();
        // 성공한 경우에만 인증 상태로 변경합니다.
        state = AuthState.authenticated;
        print("✅ 자동 로그인 유효성 검사 성공");
      } catch (e) {
        // DioClient 인터셉터가 알아서 로그아웃 처리를 진행할 것입니다.
        // 여기서 우리는 아무것도 할 필요가 없습니다.
        // 이 catch 블록의 유일한 목적은 DioException이 앱 전체로 퍼져나가
        // Unhandled Exception이 되는 것을 막는 것입니다.
        print("✋ 자동 로그인 실패. DioClient가 강제 로그아웃을 처리합니다.");
      }
    } else {
      state = AuthState.unauthenticated;
    }
  }

  Future<void> logout({BuildContext? context}) async {
    // ★★★★★ 최종 수정된 부분 ★★★★★
    // 이미 로그아웃 상태라면, 중복 실행을 방지합니다.
    if (state == AuthState.unauthenticated) return;
    // ★★★★★ 여기까지 ★★★★★

    print('🔴 [AuthStateNotifier] logout() 시작');
    print('🔴 [AuthStateNotifier] 현재 상태: $state');

    try {
      await _authRepository.logout();
      print('🔴 [AuthStateNotifier] 서버 로그아웃 완료');
    } catch (e) {
      print("🔴 [AuthStateNotifier] 서버 로그아웃 요청 실패: $e");
    } finally {
      await _storage.deleteAll();
      print('🔴 [AuthStateNotifier] 로컬 토큰 삭제 완료');

      state = AuthState.unauthenticated;
      print('🔴 [AuthStateNotifier] 상태 변경 완료: $state');

      if (context != null) {
        print('🔄 강제 로그인 페이지 이동');
        context.go('/login');
      }
    }
  }


  Future<void> logout2() async {
    print('🔴 [AuthStateNotifier] logout2() 시작');
    print('🔴 [AuthStateNotifier] 현재 상태: $state');
    // state = AuthState.authenticated;
    // print('🔴 [AuthStateNotifier] 현재 상태: $state');


    try {
      // await _authRepository.logout();
      state = AuthState.unauthenticated;
      print('🔴 [AuthStateNotifier] 현재 상태: $state');
      print('🔴 [AuthStateNotifier] 서버 로그아웃 완료');
    } catch (e) {
      print("🔴 [AuthStateNotifier] 서버 로그아웃 요청 실패: $e");
    } finally {
      await _storage.deleteAll();
      print('🔴 [AuthStateNotifier] 로컬 토큰 삭제 완료');

      state = AuthState.unauthenticated;
      print('🔴 [AuthStateNotifier] 상태 변경 완료: $state');
      }
    }
  }


// ✨ AuthStateNotifier 생성 시 MemberRepository 주입 코드를 제거합니다.
final authStateProvider =
StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final storage = serviceLocator<FlutterSecureStorage>();
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(storage, authRepository);
});

