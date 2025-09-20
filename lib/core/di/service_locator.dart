import 'package:chemiq/core/dio/dio_client.dart';
import 'package:chemiq/data/repositories/auth_repository.dart';
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../features/auth/provider/auth_state_provider.dart';

/// 전역에서 의존성을 관리하기 위한 GetIt 인스턴스
final GetIt serviceLocator = GetIt.instance;

/// 앱 실행 시 필요한 서비스와 리포지토리를 등록하는 함수
/// [ProviderContainer]를 전달받아 Riverpod Provider와도 연동 가능
void setupServiceLocator(ProviderContainer container) {
  // ✅ 네트워크 요청을 담당할 Dio 클라이언트 등록
  serviceLocator.registerLazySingleton<Dio>(() => Dio());

  // ✅ 안전한 저장소 (토큰 저장용) 등록
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
        () => const FlutterSecureStorage(),
  );

  // ✅ Dio와 SecureStorage, ProviderContainer를 주입받는 커스텀 DioClient 등록
  serviceLocator.registerLazySingleton<DioClient>(
        () => DioClient(
      dio: serviceLocator<Dio>(),
      storage: serviceLocator<FlutterSecureStorage>(),
      container: container,
    ),
  );

  // ✅ AuthRepository 등록 (인증 관련 API 요청 처리)
  serviceLocator.registerLazySingleton<AuthRepository>(
        () => AuthRepository(dioClient: serviceLocator<DioClient>()),
  );

  // ✅ MemberRepository 등록 (회원 관련 API 요청 처리)
  serviceLocator.registerLazySingleton<MemberRepository>(
        () => MemberRepository(dioClient: serviceLocator<DioClient>()),
  );

  // ✅ AuthStateNotifier 등록
  //    - FlutterSecureStorage와 AuthRepository를 의존성으로 주입받음
  //    - AuthStateNotifier는 상태 관리 (로그인/로그아웃 등) 담당
  // ✨ 기존에는 MemberRepository도 주입했으나 제거됨
  serviceLocator.registerLazySingleton<AuthStateNotifier>(
        () => AuthStateNotifier(
      serviceLocator<FlutterSecureStorage>(),
      serviceLocator<AuthRepository>(),
    ),
  );
}
