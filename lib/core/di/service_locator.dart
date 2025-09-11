// lib/core/di/service_locator.dart
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/auth_repository.dart';
import '../../features/auth/provider/auth_state_provider.dart';

// GetIt 인스턴스 생성
final GetIt serviceLocator = GetIt.instance;

// 앱 실행 시 필요한 의존성들을 등록하는 함수
void setupServiceLocator() {
  // 1. 외부 라이브러리 등록
  // Dio
  serviceLocator.registerLazySingleton<Dio>(() => Dio());
  // FlutterSecureStorage
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // 2. 직접 만든 클라이언트 클래스 등록
  // DioClient (Dio와 FlutterSecureStorage에 의존)
  serviceLocator.registerLazySingleton<DioClient>(
        () => DioClient(
      dio: serviceLocator<Dio>(),
      storage: serviceLocator<FlutterSecureStorage>(),
    ),
  );

  // 3. Repository 등록 (이 부분을 추가!)
  serviceLocator.registerLazySingleton<AuthRepository>(
        () => AuthRepository(dioClient: serviceLocator<DioClient>()),
  );

  // 4. Provider 등록 (추가)
  // 이 부분은 AuthStateNotifier가 다른 서비스에 의존하지 않으므로 직접 등록합니다.
  // Riverpod Provider는 UI 레이어에서 주로 사용되므로, 여기서는 인스턴스만 등록합니다.
  serviceLocator.registerLazySingleton<AuthStateNotifier>(
          () => AuthStateNotifier(serviceLocator<FlutterSecureStorage>()));

  // 3. Repository 등록 (향후 추가될 부분)
  // 예: serviceLocator.registerLazySingleton<AuthRepository>(() => AuthRepository(dioClient: serviceLocator<DioClient>()));
}