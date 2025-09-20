import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../mypage/mypage_view_model.dart';
import 'edit_profile_view_model.dart';

// ✨ ConsumerWidget에서 ConsumerStatefulWidget으로 변경
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ✨ 컨트롤러를 State 내에서 선언하여 생명주기를 관리합니다.
  late final TextEditingController _nicknameController;

  @override
  void initState() {
    super.initState();
    // initState에서는 ref.watch를 사용할 수 없으므로, ref.read로 현재 닉네임 값을 한 번만 가져옵니다.
    final currentNickname = ref.read(myPageViewModelProvider).myPageInfo?.myInfo.nickname ?? '';
    _nicknameController = TextEditingController(text: currentNickname);

    // 컨트롤러에 리스너를 추가하여, 텍스트가 변경될 때마다 ViewModel의 유효성 검사 함수를 호출합니다.
    _nicknameController.addListener(() {
      ref.read(editProfileViewModelProvider.notifier).validateNickname(_nicknameController.text);
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 마이페이지 정보를 가져와 현재 프로필 사진을 표시합니다.
    final myPageState = ref.watch(myPageViewModelProvider);
    final myInfo = myPageState.myPageInfo?.myInfo;

    final state = ref.watch(editProfileViewModelProvider);
    final viewModel = ref.read(editProfileViewModelProvider.notifier);

    ref.listen(editProfileViewModelProvider, (previous, next) {
      if (next.successMessage != null) {
        showChemiQToast(next.successMessage!, type: ToastType.success);
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
          TextButton(
            onPressed: (state.isNicknameLoading || !state.isNicknameValid) ? null : () {
              viewModel.changeNickname(_nicknameController.text.trim());
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
                      controller: _nicknameController, // State에서 관리하는 컨트롤러 사용
                      maxLength: 6,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '닉네임을 입력하세요',
                        counterText: "", // 글자 수 카운터 숨기기
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('2~6자 이내로 입력해주세요', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
            _buildInfoRow(context, Icons.photo_library_outlined, '프로필 사진', '파트너에게 보여질 대표 사진이에요'),
            const SizedBox(height: 12),
            _buildInfoRow(context, Icons.person_outline, '닉네임', '퀘스트와 타임라인에서 사용되는 이름이에요'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        )
      ],
    );
  }
}

