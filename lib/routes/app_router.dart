// import 'package:chemiq/data/models/submission_detail_dto.dart';
// import 'package:chemiq/features/auth/login/login_screen.dart';
// import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
// import 'package:chemiq/features/auth/signup/signup_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
//
// import '../data/models/member_info_dto.dart';
// import '../features/auth/provider/partner_state_provider.dart';
// import '../features/change_password/change_password_screen.dart';
// import '../features/edit_profile/edit_profile_screen.dart';
// import '../features/evaluation/evaluation_screen.dart';
// import '../features/mainShell.dart';
// import '../features/mission_detail/mission_detail_screen.dart';
// import '../features/mission_submission/mission_submission_screen.dart';
// import '../features/partner_linking/partner_linking_screen.dart';
// import '../features/photo_viewer_screen.dart';
//
// final routerProvider = Provider<GoRouter>((ref) {
//   final authState = ref.watch(authStateProvider);
//   // final partnerState = ref.watch(partnerStateProvider);
//
//   return GoRouter(
//     initialLocation: '/',
//     redirect: (BuildContext context, GoRouterState state) {
//       // if (authState == AuthState.unknown || partnerState.isLoading) return null;
//       if (authState == AuthState.unknown ) return null;
//
//       final loggedIn = authState == AuthState.authenticated;
//       final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
//
//       // 로그아웃 상태일 때, 인증 관련 경로가 아니면 로그인 페이지로 보냅니다.
//       if (!loggedIn) return isAuthRoute ? null : '/login';
//
//
//       // 로그인 상태이지만 인증 관련 경로에 있으려 하면, 메인 화면으로 보냅니다.
//       // 파트너 유무에 따른 강제 리다이렉트 로직을 제거했습니다.
//       if (isAuthRoute) return '/';
//
//       return null;
//     },
//     routes: [
//       GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
//       GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
//       GoRoute(path: '/partner_linking', builder: (context, state) => const PartnerLinkingScreen()),
//       GoRoute(
//         path: '/',
//         builder: (context, state) => const MainShell(),
//       ),
//       GoRoute(
//         path: '/mission_submission/:dailyMissionId',
//         builder: (context, state) {
//           final dailyMissionId = int.parse(state.pathParameters['dailyMissionId']!);
//           final missionTitle = state.extra as String? ?? '미션 제출';
//           return MissionSubmissionScreen(dailyMissionId: dailyMissionId, missionTitle: missionTitle);
//         },
//       ),
//       GoRoute(
//         path: '/evaluation/:submissionId',
//         builder: (context, state) {
//           final submissionId = int.parse(state.pathParameters['submissionId']!);
//           final partnerSubmission = state.extra as SubmissionDetailDto;
//           return EvaluationScreen(submissionId: submissionId, partnerSubmission: partnerSubmission);
//         },
//       ),
//       GoRoute(path: '/change_password', builder: (context, state) => const ChangePasswordScreen()),
//       GoRoute(path: '/edit_profile', builder: (context, state) => const EditProfileScreen()),
//       GoRoute(
//         path: '/mission_detail',
//         builder: (context, state) {
//           // ✨ extra로 전달된 Map에서 각 데이터를 추출합니다.
//           final extraData = state.extra as Map<String, dynamic>;
//           final submission = extraData['submission'] as SubmissionDetailDto;
//           final submitterInfo = extraData['submitterInfo'] as MemberInfoDto;
//           final missionTitle = extraData['missionTitle'] as String;
//
//           // ✨ 추출한 데이터를 MissionDetailScreen에 전달합니다.
//           return MissionDetailScreen(
//             submission: submission,
//             submitterInfo: submitterInfo,
//             missionTitle: missionTitle,
//           );
//         },
//       ),
//       GoRoute(
//         path: '/photo_viewer',
//         builder: (context, state) {
//           final imageUrl = state.extra as String;
//           return PhotoViewerScreen(imageUrl: imageUrl);
//         },
//       )
//     ],
//   );
// });
//
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:chemiq/features/auth/login/login_screen.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:chemiq/features/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/member_info_dto.dart';
import '../features/auth/provider/partner_state_provider.dart';
import '../features/change_password/change_password_screen.dart';
import '../features/edit_profile/edit_profile_screen.dart';
import '../features/evaluation/evaluation_screen.dart';
import '../features/mainShell.dart';
import '../features/mission_detail/mission_detail_screen.dart';
import '../features/mission_submission/mission_submission_screen.dart';
import '../features/partner_linking/partner_linking_screen.dart';
import '../features/photo_viewer_screen.dart';
import 'package:chemiq/features/splash/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // authState 변화를 감지
  final authState = ref.watch(authStateProvider);

  // 디버깅을 위한 로그
  print('🔄 Router: AuthState changed to $authState');

  return GoRouter(
    initialLocation: '/splash', // 초기 위치를 스플래시로 변경
    // refreshListenable를 사용하여 authState 변화 시 자동으로 리프레시
    refreshListenable: AuthStateRefreshListenable(ref),
    redirect: (BuildContext context, GoRouterState state) {
      print('🔄 Router redirect called');
      print('🔄 Current AuthState: $authState');
      print('🔄 Current location: ${state.matchedLocation}');

      final isSplash = state.matchedLocation == '/splash';
      final loggedIn = authState == AuthState.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // 1. AuthState가 unknown (로딩 중)일 때
      if (authState == AuthState.unknown) {
        print('🔄 AuthState is unknown. Redirecting to /splash if not already there.');
        return isSplash ? null : '/splash'; // 이미 스플래시면 대기, 아니면 스플래시로 이동
      }

      // 2. AuthState가 확정 (authenticated or unauthenticated)된 후

      // 현재 스플래시 페이지에 있으면 적절한 페이지로 리다이렉트
      if (isSplash) {
        print('🔄 Splash completed. Redirecting to ${loggedIn ? '/' : '/login'}');
        return loggedIn ? '/' : '/login';
      }

      // 로그아웃 상태일 때
      if (!loggedIn) {
        print('🔄 User is not logged in');
        // 이미 로그인/회원가입 페이지에 있으면 그대로 유지
        if (isAuthRoute) {
          print('🔄 Already on auth route, staying');
          return null;
        }
        // 다른 페이지에 있으면 로그인 페이지로 리다이렉트
        print('🔄 Redirecting to /login');
        return '/login';
      }

      // 로그인 상태일 때 (loggedIn == true)
      if (loggedIn) {
        print('🔄 User is logged in');
        // 로그인/회원가입 페이지에 있으면 메인으로 리다이렉트
        if (isAuthRoute) {
          print('🔄 On auth route while logged in, redirecting to /');
          return '/';
        }
      }

      print('🔄 No redirect needed');
      return null;
    },
    routes: [
      // 스플래시 라우트 추가
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/partner_linking',
        builder: (context, state) => const PartnerLinkingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/mission_submission/:dailyMissionId',
        builder: (context, state) {
          final dailyMissionId = int.parse(state.pathParameters['dailyMissionId']!);
          final missionTitle = state.extra as String? ?? '미션 제출';
          return MissionSubmissionScreen(
            dailyMissionId: dailyMissionId,
            missionTitle: missionTitle,
          );
        },
      ),
      GoRoute(
        path: '/evaluation/:submissionId',
        builder: (context, state) {
          final submissionId = int.parse(state.pathParameters['submissionId']!);
          final partnerSubmission = state.extra as SubmissionDetailDto;
          return EvaluationScreen(
            submissionId: submissionId,
            partnerSubmission: partnerSubmission,
          );
        },
      ),
      GoRoute(
        path: '/change_password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/edit_profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/mission_detail',
        builder: (context, state) {
          final extraData = state.extra as Map<String, dynamic>;
          final submission = extraData['submission'] as SubmissionDetailDto;
          final submitterInfo = extraData['submitterInfo'] as MemberInfoDto;
          final missionTitle = extraData['missionTitle'] as String;

          return MissionDetailScreen(
            submission: submission,
            submitterInfo: submitterInfo,
            missionTitle: missionTitle,
          );
        },
      ),
      GoRoute(
        path: '/photo_viewer',
        builder: (context, state) {
          final imageUrl = state.extra as String;
          return PhotoViewerScreen(imageUrl: imageUrl);
        },
      ),
    ],
    // 에러 처리
    errorBuilder: (context, state) {
      print('🔴 Router Error: ${state.error}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('오류가 발생했습니다'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('로그인 페이지로 이동'),
              ),
            ],
          ),
        ),
      );
    },
  );
});

// AuthState 변화를 감지하는 Listenable 클래스 (변경 없음)
class AuthStateRefreshListenable extends ChangeNotifier {
  final Ref ref;
  AuthState? _previousState;

  AuthStateRefreshListenable(this.ref) {
    // authState 변화를 구독
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      print('🔄 AuthStateRefreshListenable: $previous -> $next');

      // 상태가 실제로 변경되었을 때만 알림
      if (previous != next) {
        _previousState = next;
        notifyListeners();
      }
    });
  }
}