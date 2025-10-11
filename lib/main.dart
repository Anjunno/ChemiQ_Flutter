// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/date_symbol_data_local.dart';
// import 'styles/app_theme.dart';
// import 'routes/app_router.dart';
// import 'core/di/service_locator.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//
//   await initializeDateFormatting();
//   final container = ProviderContainer();
//   setupServiceLocator(container);
//
//
//
//   runApp(
//     UncontrolledProviderScope(
//       container: container,
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});
//
//
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final router = ref.watch(routerProvider);
//
//     return ScreenUtilInit(
//       designSize: const Size(390, 844),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       builder: (context, child) {
//         return MaterialApp.router(
//           title: 'ChemiQ',
//           theme: AppTheme.lightTheme,
//           routerConfig: router,
//           // ro
//           // navigatorKey: navigatorKey,
//           debugShowCheckedModeBanner: false,
//         );
//       },
//     );
//   }
// }
//

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'styles/app_theme.dart';
import 'routes/app_router.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger.dart'; //

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ dotenv 로딩
  await dotenv.load(fileName: ".env");

  // ✅ 날짜 초기화
  await initializeDateFormatting();

  // ✅ Riverpod ProviderContainer 생성
  final container = ProviderContainer();

  // ✅ 서비스 로케이터 초기화
  setupServiceLocator(container);

  // ✅ Flutter 프레임워크 에러 처리
  FlutterError.onError = (details) {
    if (kReleaseMode) {
      // 배포 모드에서는 crash reporting 연동 가능
      logError('FlutterError: ${details.exceptionAsString()}');
    } else {
      // 개발 모드에서는 콘솔 출력
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // ✅ runZonedGuarded로 비동기 에러 처리
  runZonedGuarded(
        () {
      logInfo('앱 시작!');
      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const MyApp(),
        ),
      );
    },
        (error, stackTrace) {
      logError('Uncaught Dart Error: $error\n$stackTrace');
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'ChemiQ',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          key: navigatorKey,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
