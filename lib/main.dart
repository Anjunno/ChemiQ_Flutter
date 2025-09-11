import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'styles/app_theme.dart';
import 'routes/app_router.dart';
import 'core/di/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  setupServiceLocator();
  // ProviderScope로 앱의 최상단을 감싸서 Riverpod를 활성화합니다.
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// 1. StatelessWidget을 ConsumerWidget으로 변경합니다.
// ConsumerWidget은 Riverpod의 Provider를 구독(watch)할 수 있는 능력을 가집니다.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // 2. build 메서드에 WidgetRef ref 파라미터를 추가합니다.
  // 'ref'는 Provider에 접근할 수 있게 해주는 마법 같은 객체입니다.
  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // 3. ref.watch를 사용해 Provider로 만든 라우터('routerProvider')를 가져옵니다.
    // .watch를 사용하면 Provider의 상태가 바뀔 때마다 이 위젯도 자동으로 다시 빌드됩니다.
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'ChemiQ',
          theme: AppTheme.lightTheme,
          // 4. Provider로부터 가져온 router 인스턴스를 여기에 연결합니다.
          routerConfig: router,
          debugShowCheckedModeBanner: false, // 개발 중 보이는 오른쪽 위 디버그 배너를 제거합니다.
        );
      },
    );
  }
}

