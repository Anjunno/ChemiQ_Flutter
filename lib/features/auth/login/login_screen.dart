import 'package:chemiq/features/auth/login/login_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ID와 비밀번호 입력을 위한 컨트롤러
    final memberIdController = TextEditingController();
    final passwordController = TextEditingController();

    // Riverpod의 상태와 뷰모델을 구독합니다.
    final loginState = ref.watch(loginViewModelProvider);
    final loginViewModel = ref.read(loginViewModelProvider.notifier);

    // 로그인 상태 변화(성공/실패)에 따른 부가 효과(스낵바, 화면이동)를 처리합니다.
    ref.listen(loginViewModelProvider, (previous, next) {
      // 에러가 발생했을 경우
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      // 로그인이 성공했을 경우
      if (next.loginSuccess) {
        // GoRouter를 사용하여 홈 화면으로 이동합니다.
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('ChemiQ 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: memberIdController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true, // 비밀번호 숨김 처리
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              // 로딩 중일 때는 버튼 비활성화
              onPressed: loginState.isLoading
                  ? null
                  : () {
                loginViewModel.login(
                  memberIdController.text.trim(), // 앞뒤 공백 제거
                  passwordController.text.trim(),
                );
              },
              child: loginState.isLoading
                  ? const SizedBox( // 로딩 중일 때 보여줄 위젯
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('로그인'), // 평상시 텍스트
            ),
          ],
        ),
      ),
    );
  }
}
