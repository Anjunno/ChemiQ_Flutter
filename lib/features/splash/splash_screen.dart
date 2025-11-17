import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // 앱 기본 배경색 사용
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/chemiQQ_noback_splash.png',
              width: 150.w, // 화면 비율에 맞게 크기 조정
              height: 150.h,
            ),
            SizedBox(height: 40.h),
            // 로딩 인디케이터
            const CircularProgressIndicator(),
            SizedBox(height: 20.h),
            Text(
              'ChemiQ를 불러오는 중입니다...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}