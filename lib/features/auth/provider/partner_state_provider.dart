import 'package:chemiq/data/models/partnership_partner_response.dart';
import 'package:chemiq/data/repositories/partnership_repository.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 파트너 정보를 비동기적으로 가져와서 상태를 관리하는 FutureProvider입니다.
/// FutureProvider는 Future의 상태(로딩, 데이터, 에러)를 자동으로 관리해줍니다.
final partnerStateProvider = FutureProvider.autoDispose<PartnershipPartnerResponse?>((ref) async {
  // 1. 먼저, 사용자의 현재 인증 상태를 감시합니다.
  final authState = ref.watch(authStateProvider);

  // 2. 사용자가 로그인된 상태(authenticated)일 때만 파트너 정보 조회를 시도합니다.
  if (authState == AuthState.authenticated) {
    // PartnershipRepository를 가져와서 getPartnerInfo() 메서드를 호출합니다.
    final partnershipRepository = ref.watch(partnershipRepositoryProvider);
    final partnerInfo = await partnershipRepository.getPartnerInfo();
    // 조회 결과를 반환합니다 (파트너 정보 객체 또는 null).
    return partnerInfo;
  }

  // 3. 사용자가 로그아웃 상태이거나, 아직 인증 상태를 확인하는 중일 때는
  //    API를 호출할 필요 없이 즉시 null을 반환합니다.
  return null;
});

