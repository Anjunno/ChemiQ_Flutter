import 'package:chemiq/features/auth/login/login_screen.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 로그인 성공 시 이동할 임시 홈 화면
class HomeScreen extends ConsumerWidget { // ConsumerWidget으로 변경
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) { // WidgetRef ref 추가
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        actions: [
          // 로그아웃 테스트를 위한 버튼
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // authStateProvider를 통해 logout 함수를 호출합니다.
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: const Center(child: Text('로그인 성공! 🎉')),
    );
  }
}

// GoRouter 설정을 일반 변수가 아닌 Riverpod Provider로 만듭니다.
final routerProvider = Provider<GoRouter>((ref) {
  // authStateProvider의 상태 변화를 실시간으로 감시합니다.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login', // 시작 경로

    // redirect: GoRouter의 강력한 기능으로, 특정 조건에 따라 경로를 재설정합니다.
    // authState가 변경될 때마다 이 로직이 다시 실행됩니다.
    redirect: (BuildContext context, GoRouterState state) {

      // 앱이 처음 시작되어 인증 상태를 확인하는 중이라면(unknown), 아무것도 하지 않습니다.
      // 이 때 스플래시 화면을 보여주면 좋습니다.
      if (authState == AuthState.unknown) {
        return null;
      }

      final loggedIn = authState == AuthState.authenticated; // 현재 로그인 되어있는가?
      final loggingIn = state.matchedLocation == '/login';   // 현재 경로가 로그인 페이지인가?

      // 1. 로그아웃 상태인데, 로그인 페이지가 아닌 다른 곳에 있으려고 한다면?
      //    -> 강제로 로그인 페이지로 보냅니다.
      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      // 2. 로그인 상태인데, 로그인 페이지로 다시 가려고 한다면? (예: 뒤로가기)
      //    -> 강제로 홈 페이지로 보냅니다.
      if (loggedIn && loggingIn) {
        return '/home';
      }

      // 그 외의 모든 경우는 그대로 둡니다.
      return null;
    },
    // 앱에서 사용될 모든 경로 목록
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});

