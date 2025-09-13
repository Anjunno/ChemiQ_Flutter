import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../mypage/mypage_view_model.dart';
import 'edit_profile_view_model.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 마이페이지 정보를 가져와 현재 닉네임과 프로필 사진을 표시합니다.
    final myPageState = ref.watch(myPageViewModelProvider);
    final myInfo = myPageState.myPageInfo?.myInfo;

    final state = ref.watch(editProfileViewModelProvider);
    final viewModel = ref.read(editProfileViewModelProvider.notifier);

    final nicknameController = TextEditingController(text: myInfo?.nickname);

    ref.listen(editProfileViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        showChemiQToast(next.successMessage!, type: ToastType.success);
        // 성공 시, 마이페이지 정보를 새로고침하여 변경사항을 반영합니다.
        ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo();
        context.pop();
      }
      if (next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          // '저장' 버튼
          TextButton(
            onPressed: state.isNicknameLoading ? null : () {
              viewModel.changeNickname(nicknameController.text.trim());
            },
            child: const Text('저장'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 프로필 사진 변경
            GestureDetector(
              onTap: () => ref.read(myPageViewModelProvider.notifier).updateProfileImage(),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: myInfo?.profileImageUrl != null
                        ? CachedNetworkImageProvider(myInfo!.profileImageUrl!)
                        : null,
                    child: myInfo?.profileImageUrl == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '프로필 사진을 변경하려면 카메라 아이콘을 눌러주세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 닉네임 변경
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: nicknameController,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '닉네임을 입력하세요',
                      ),
                      onChanged: (text) => viewModel.validateNickname(text),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('2~10자 이내로 입력해주세요', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                        if (state.isNicknameValid)
                          const Row(
                            children: [
                              Icon(Icons.check, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text('사용 가능', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 프로필 안내
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('프로필 안내', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // ✨ _buildInfoRow를 호출할 때 context를 전달합니다.
            _buildInfoRow(context, Icons.photo_library_outlined, '프로필 사진', '파트너에게 보여질 대표 사진이에요'),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.person_outline, '닉네임', '미션과 타임라인에서 사용되는 이름이에요'),
          ],
        ),
      ),
    );
  }

  // ✨ _buildInfoRow 메서드가 BuildContext를 파라미터로 받도록 수정합니다.
  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            // 이제 context에 정상적으로 접근할 수 있습니다.
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        )
      ],
    );
  }
}

