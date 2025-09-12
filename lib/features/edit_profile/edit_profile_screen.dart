import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mypage/mypage_view_model.dart';
import 'edit_profile_view_model.dart';


class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameController = TextEditingController();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // ViewModel의 상태 변화를 감지하여 스낵바를 띄웁니다.
    ref.listen(editProfileViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.successMessage!)));
        // 성공 시, 마이페이지 정보를 새로고침하여 변경사항을 반영합니다.
        ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(editProfileViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 닉네임 변경 섹션
            Text('닉네임 변경', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '새 닉네임', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: state.isNicknameLoading ? null : () {
                ref.read(editProfileViewModelProvider.notifier)
                    .changeNickname(nicknameController.text.trim());
              },
              child: state.isNicknameLoading
                  ? const CircularProgressIndicator()
                  : const Text('닉네임 변경하기'),
            ),

            const Divider(height: 48),

            // 비밀번호 변경 섹션
            Text('비밀번호 변경', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 확인', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: state.isPasswordLoading ? null : () {
                ref.read(editProfileViewModelProvider.notifier).changePassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                  confirmPassword: confirmPasswordController.text,
                );
              },
              child: state.isPasswordLoading
                  ? const CircularProgressIndicator()
                  : const Text('비밀번호 변경하기'),
            ),
          ],
        ),
      ),
    );
  }
}
