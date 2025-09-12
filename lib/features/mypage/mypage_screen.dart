import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/partnership_info_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'mypage_view_model.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myPageViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo(),
        child: _buildBody(state, textTheme),
      ),
    );
  }

  Widget _buildBody(MyPageState state, TextTheme textTheme) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.myPageInfo == null) {
      return const Center(child: Text('정보를 불러올 수 없습니다.'));
    }

    final myInfo = state.myPageInfo!.myInfo;
    final partnerInfo = state.myPageInfo!.partnerInfo;
    final partnershipInfo = state.myPageInfo!.partnershipInfo;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildProfileCard(myInfo, state, textTheme, isMe: true),
        const SizedBox(height: 24),
        if (partnershipInfo != null)
          _buildPartnershipCard(partnershipInfo, textTheme),
        const SizedBox(height: 24),
        if (partnerInfo != null)
          _buildProfileCard(partnerInfo, state, textTheme, isMe: false),
      ],
    );
  }

  Widget _buildProfileCard(MemberInfoDto info, MyPageState state, TextTheme textTheme, {required bool isMe}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: isMe
                  ? () => ref.read(myPageViewModelProvider.notifier).changeProfileImage()
                  : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: info.profileImageUrl != null
                        ? NetworkImage(info.profileImageUrl!)
                        : null,
                    child: info.profileImageUrl == null
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade500)
                        : null,
                  ),
                  if (isMe)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300)
                        ),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.grey),
                      ),
                    ),
                  // 사진 업로드 중일 때 로딩 오버레이 표시
                  if (isMe && state.isUploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(info.nickname, style: textTheme.headlineSmall),
            Text(info.memberId, style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'ChemiQ 시작일: ${DateFormat('yyyy.MM.dd').format(info.created)}',
              style: textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            if (isMe)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {
                  // TODO: 닉네임, 비밀번호 변경 화면으로 이동
                  context.go('/edit_profile');
                  print('정보 수정');
                }, child: const Text('정보 수정')),
              ),
          ],
        ),
      ),
    );
  }

  // ✨ _buildPartnershipCard 메서드만 아래와 같이 수정합니다.
  Widget _buildPartnershipCard(PartnershipInfoDto info, TextTheme textTheme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            Text('우리 사이 케미', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '함께한 지 ${DateTime.now().difference(info.acceptedAt).inDays + 1}일째',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem('🔥', '스트릭', '${info.streakCount}일'),
                _buildInfoItem('🧪', '케미 지수', info.chemiScore.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 20),
            // ✨ 관계 해제 버튼 및 다이얼로그 로직 추가
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('정말 관계를 해제하시겠어요?'),
                      content: const Text('이 작업은 되돌릴 수 없으며, 연결이 즉시 끊어집니다.'),
                      actions: [
                        TextButton(
                          child: const Text('취소'),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        TextButton(
                          child: const Text('해제하기', style: TextStyle(color: Colors.red)),
                          onPressed: () async {
                            Navigator.of(dialogContext).pop(); // 다이얼로그 먼저 닫기
                            try {
                              // ViewModel의 breakUp 메서드 호출
                              await ref.read(myPageViewModelProvider.notifier).breakUp();
                              // 성공 시 자동으로 파트너 연결 화면으로 이동합니다.
                            } catch (e) {
                              // 실패 시 스낵바로 에러 메시지 표시
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.heart_broken_outlined, color: Colors.red.shade300),
              label: Text('관계 해제하기', style: TextStyle(color: Colors.red.shade400)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String icon, String label, String value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }
}
