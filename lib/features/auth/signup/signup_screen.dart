import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'signup_view_model.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 각 입력 필드를 제어하기 위한 컨트롤러
    final memberIdController = TextEditingController();
    final passwordController = TextEditingController();
    final passwordConfirmController = TextEditingController();
    final nicknameController = TextEditingController();

    // ViewModel의 상태 변화를 감지하고, 성공/실패 시 부가 효과(스낵바, 화면 이동)를 처리
    ref.listen(signUpViewModelProvider, (previous, next) {
      if (next.signUpSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인 해주세요.')),
        );
        context.pop(); // 회원가입 성공 시 이전 화면(로그인)으로 돌아가기
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final signUpState = ref.watch(signUpViewModelProvider);
    final signUpViewModel = ref.read(signUpViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: memberIdController,
              decoration: const InputDecoration(labelText: '아이디', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passwordConfirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '닉네임', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: signUpState.isLoading
                  ? null
                  : () {
                if (passwordController.text != passwordConfirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
                  );
                  return;
                }
                signUpViewModel.signUp(
                  memberId: memberIdController.text.trim(),
                  password: passwordController.text.trim(),
                  nickname: nicknameController.text.trim(),
                );
              },
              child: signUpState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('가입하기'),
            ),
          ],
        ),
      ),
    );
  }
}
