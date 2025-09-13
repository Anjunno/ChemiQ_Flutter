import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:chemiq/features/auth/login/login_screen.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:chemiq/features/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/provider/partner_state_provider.dart';
import '../features/change_password/change_password_screen.dart';
import '../features/edit_profile/edit_profile_screen.dart';
import '../features/evaluation/evaluation_screen.dart';
import '../features/mainShell.dart';
import '../features/mission_detail/mission_detail_screen.dart';
import '../features/mission_submission/mission_submission_screen.dart';
import '../features/partner_linking/partner_linking_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final partnerState = ref.watch(partnerStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      if (authState == AuthState.unknown || partnerState.isLoading) return null;

      final loggedIn = authState == AuthState.authenticated;
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      // 로그아웃 상태일 때, 인증 관련 경로가 아니면 로그인 페이지로 보냅니다.
      if (!loggedIn) return isAuthRoute ? null : '/login';

      // ✨ 수정된 부분:
      // 로그인 상태이지만 인증 관련 경로에 있으려 하면, 메인 화면으로 보냅니다.
      // 파트너 유무에 따른 강제 리다이렉트 로직을 제거했습니다.
      if (isAuthRoute) return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/partner_linking', builder: (context, state) => const PartnerLinkingScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainShell(),
      ),
      GoRoute(
        path: '/mission_submission/:dailyMissionId',
        builder: (context, state) {
          final dailyMissionId = int.parse(state.pathParameters['dailyMissionId']!);
          final missionTitle = state.extra as String? ?? '미션 제출';
          return MissionSubmissionScreen(dailyMissionId: dailyMissionId, missionTitle: missionTitle);
        },
      ),
      GoRoute(
        path: '/evaluation/:submissionId',
        builder: (context, state) {
          final submissionId = int.parse(state.pathParameters['submissionId']!);
          final partnerSubmission = state.extra as SubmissionDetailDto;
          return EvaluationScreen(submissionId: submissionId, partnerSubmission: partnerSubmission);
        },
      ),
      GoRoute(path: '/change_password', builder: (context, state) => const ChangePasswordScreen()),
      GoRoute(path: '/edit_profile', builder: (context, state) => const EditProfileScreen()),
      GoRoute(
        path: '/mission_detail',
        builder: (context, state) {
          final submission = state.extra as SubmissionDetailDto;
          return MissionDetailScreen(submission: submission);
        },
      )
    ],
  );
});

