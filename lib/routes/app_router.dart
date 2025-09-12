import 'package:chemiq/features/auth/login/login_screen.dart';
import '../data/models/submission_detail_dto.dart';
import '../features/auth/provider/auth_state_provider.dart';
import '../features/auth/provider/partner_state_provider.dart';
import 'package:chemiq/features/auth/signup/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/evaluation/evaluation_screen.dart';
import '../features/home/home_screen.dart';
import '../features/mission_submission/mission_submission_screen.dart';
import '../features/mypage/mypage_screen.dart';
import '../features/partner_linking/partner_linking_screen.dart';
import '../features/timeline/timeline_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  // 1. 기존 인증 상태와 더불어, 새로운 파트너 상태도 감시합니다.
  final authState = ref.watch(authStateProvider);
  final partnerState = ref.watch(partnerStateProvider);

  return GoRouter(
    initialLocation: '/login',
    // redirect 로직이 실행될 때마다 인증 & 파트너 상태를 모두 확인합니다.
    redirect: (BuildContext context, GoRouterState state) {
      // --- 상태 확인 중일 때 (로딩) ---
      // 인증 상태를 모르거나, 파트너 정보를 아직 불러오는 중이라면 아무것도 하지 않습니다.
      // 이 때 스플래시 화면을 보여주면 사용자 경험이 향상됩니다.
      if (authState == AuthState.unknown || partnerState.isLoading) {
        return null; // '/splash' 경로로 보내는 것을 추천
      }

      final loggedIn = authState == AuthState.authenticated;
      final hasPartner = partnerState.value != null; // 파트너 정보가 null이 아니면 true

      final loggingIn = state.matchedLocation == '/login';
      final signingUp = state.matchedLocation == '/signup';
      final linkingPartner = state.matchedLocation == '/partner_linking';


      // --- 로그아웃 상태일 때의 규칙 ---
      if (!loggedIn) {
        // 로그인 페이지나 회원가입 페이지가 아닌 곳으로 가려고 하면 -> 로그인 페이지로 보냅니다.
        return (loggingIn || signingUp) ? null : '/login';
      }

      // --- 로그인 상태일 때의 규칙 ---
      if (loggedIn) {
        // 1. 파트너가 없을 때
        if (!hasPartner) {
          // 파트너 연결 페이지가 아닌 다른 곳으로 가려고 하면 -> 파트너 연결 페이지로 보냅니다.
          return linkingPartner ? null : '/partner_linking';
        }
        // 2. 파트너가 있을 때
        if (hasPartner) {
          // 로그인, 회원가입, 파트너 연결 페이지에 머무르려 한다면 -> 진짜 홈(/home)으로 보냅니다.
          if (loggingIn || signingUp || linkingPartner) {
            return '/home';
          }
        }
      }

      // 위 모든 규칙에 해당하지 않으면, 원래 가려던 곳으로 보냅니다.
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/mypage', builder: (context, state) => const MyPageScreen()),
      GoRoute(path: '/timeline', builder: (context, state) => const TimelineScreen()),
      GoRoute(path: '/partner_linking', builder: (context, state) => const PartnerLinkingScreen()),
      GoRoute(
        path: '/mission_submission/:dailyMissionId',
        builder: (context, state) {
          // 경로에서 미션 ID를 추출합니다.
          final dailyMissionId = int.parse(state.pathParameters['dailyMissionId']!);
          // extra 데이터를 통해 미션 제목을 전달받습니다.
          final missionTitle = state.extra as String? ?? '미션 제출';

          return MissionSubmissionScreen(
            dailyMissionId: dailyMissionId,
            missionTitle: missionTitle,
          );
        },
      ),

      // ✨ 새로운 평가 화면 경로를 추가합니다.
      GoRoute(
        path: '/evaluation/:submissionId',
        builder: (context, state) {
          final submissionId = int.parse(state.pathParameters['submissionId']!);
          // extra를 통해 파트너의 제출물 정보를 전달받습니다.
          final partnerSubmission = state.extra as SubmissionDetailDto;
          return EvaluationScreen(
            submissionId: submissionId,
            partnerSubmission: partnerSubmission,
          );
        },
      ),
    ],
  );
});

