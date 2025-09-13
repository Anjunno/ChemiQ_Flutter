import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'change_password_view_model.dart';

class ChangePasswordScreen extends ConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    ref.listen(changePasswordViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        showChemiQToast(next.successMessage!, type: ToastType.success);
        context.pop(); // 성공 시 이전 화면으로 돌아가기
      }
      if (next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    final state = ref.watch(changePasswordViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 확인', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: '비밀번호 변경하기',
              isLoading: state.isLoading,
              onPressed: () {
                ref.read(changePasswordViewModelProvider.notifier).changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
