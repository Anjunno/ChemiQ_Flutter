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


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'styles/app_theme.dart';
import 'routes/app_router.dart';
import 'core/di/service_locator.dart';

// ★★★★★ 1. Navigator를 위한 GlobalKey를 생성합니다. ★★★★★
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await initializeDateFormatting();
  final container = ProviderContainer();
  setupServiceLocator(container);



  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
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
          // ★★★★★ 2. MaterialApp.router에 key를 할당합니다. ★★★★★
          key: navigatorKey,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
