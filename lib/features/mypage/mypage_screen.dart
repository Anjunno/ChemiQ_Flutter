import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/partnership_info_dto.dart';
import 'package:chemiq/features/auth/provider/auth_state_provider.dart';
import 'package:chemiq/styles/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer package
import '../../core/ui/widgets/showConfirmation_dialog.dart';
import '../../data/models/AchievementDto.dart';
import 'mypage_view_model.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(myPageViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(myPageViewModelProvider, (previous, next) {
      if (next.profileImageError != null) {
        showChemiQToast(next.profileImageError!, type: ToastType.error);
      }
    });

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(myPageViewModelProvider.notifier).fetchMyPageInfo(),
          child: state.isLoading ? _buildLoadingShimmer() : _buildBody(state, textTheme),
        ),
        if (state.isImageUploading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // ✨ Added the new loading shimmer method
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // Profile Header Shimmer
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildShimmerCircleProfile(),
                  const SizedBox(width: 12),
                  Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  _buildShimmerCircleProfile(),
                ],
              ),
              const SizedBox(height: 16),
              Container(width: 150, height: 20, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 100, height: 12, color: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          // Stats Grid Shimmer
          Row(
            children: [
              Expanded(child: _buildShimmerStatCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildShimmerStatCard()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildShimmerStatCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildShimmerStatCard()),
            ],
          ),
          const SizedBox(height: 24),
          // Achievements Card Shimmer
          Container(
            height: 120, // Adjusted height to accommodate title and some badges
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 24),
          // Settings Menu Shimmer
          Container(
            height: 180, // Approximate height for the list
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 24),
          // Account Management Menu Shimmer
          Container(
            height: 180, // Approximate height for the list
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCircleProfile() {
    return Column(
      children: [
        const CircleAvatar(radius: 40, backgroundColor: Colors.white),
        const SizedBox(height: 8),
        Container(width: 70, height: 16, color: Colors.white),
        const SizedBox(height: 4),
        Container(width: 40, height: 12, color: Colors.white),
      ],
    );
  }

  Widget _buildShimmerStatCard() {
    return Container(
      height: 120, // Adjusted height to match the stat card's content
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildBody(MyPageState state, TextTheme textTheme) {
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.myPageInfo == null) {
      return const Center(child: Text('정보를 불러올 수 없습니다.'));
    }

    final myInfo = state.myPageInfo!.myInfo;
    final partnerInfo = state.myPageInfo!.partnerInfo;
    final partnershipInfo = state.myPageInfo!.partnershipInfo;
    final myAchievements = state.myPageInfo!.myAchievements;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        if (partnerInfo != null) ...[
          _buildProfileHeader(myInfo, partnerInfo, partnershipInfo, textTheme),
          const SizedBox(height: 24),
          _buildStatsGrid(partnershipInfo),
        ],
        const SizedBox(height: 24),
        _buildAchievementsCard(myAchievements, textTheme),
        const SizedBox(height: 24),
        _buildSettingsMenu(context, hasPartner: partnerInfo != null),
        const SizedBox(height: 24),
        _buildAccountManagementMenu(context, hasPartner: partnerInfo != null),
      ],
    );
  }

  Widget _buildStatsGrid(PartnershipInfoDto? partnershipInfo) {
    if (partnershipInfo == null) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(icon: Icons.local_fire_department_rounded, iconColor: Colors.red.shade400, backgroundColor: Colors.red.shade50, value: '${partnershipInfo.streakCount}', label: '연속 스트릭', unit: '일')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(icon: Icons.star_rounded, iconColor: Colors.green.shade400, backgroundColor: Colors.green.shade50, value: '${partnershipInfo.chemiScore.toStringAsFixed(1)}', label: '케미 지수', unit: '%')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(icon: Icons.emoji_events_rounded, iconColor: Colors.orange.shade400, backgroundColor: Colors.orange.shade50, value: '${partnershipInfo.totalCompletedMissions}', label: '총 완료 퀘스트')),
            const SizedBox(width: 16),
            Expanded(child: _buildStatCard(icon: Icons.calendar_today_rounded, iconColor: Colors.blue.shade400, backgroundColor: Colors.blue.shade50, value: '${partnershipInfo.weeklyCompletedMissions}/7', label: '이번 주 완료')),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsCard(List<AchievementDto> achievements, TextTheme textTheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('나의 도전과제', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (achievements.isEmpty)
              const Center(
                heightFactor: 3,
                child: Text('아직 달성한 도전과제가 없어요.'),
              )
            else
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: achievements.map((ach) => _buildAchievementBadge(ach)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(AchievementDto achievement) {
    return Tooltip(
      message: achievement.description,
      preferBelow: false,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary, width: 1),
      ),
      textStyle: const TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      waitDuration: const Duration(milliseconds: 300),
      showDuration: const Duration(seconds: 3),
      child: Chip(
        label: Text(
          achievement.name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        backgroundColor: AppColors.secondary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primary, width: 1),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildProfileHeader(MemberInfoDto myInfo, MemberInfoDto partnerInfo, PartnershipInfoDto? partnershipInfo, TextTheme textTheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileCircle(myInfo, '나', textTheme),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12.0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.favorite, color: Colors.pink.shade200, size: 28),
            ),
            _buildProfileCircle(partnerInfo, '파트너', textTheme),
          ],
        ),
        const SizedBox(height: 16),
        if (partnershipInfo != null)
          Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                  children: <TextSpan>[
                    const TextSpan(text: '함께한 지 '),
                    TextSpan(
                      text: '${DateTime.now().difference(partnershipInfo.acceptedAt).inDays + 1}',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const TextSpan(text: '일째'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${DateFormat('yyyy.MM.dd').format(partnershipInfo.acceptedAt)}~)',
                style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProfileCircle(MemberInfoDto info, String role, TextTheme textTheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: info.profileImageUrl != null
              ? CachedNetworkImageProvider(info.profileImageUrl!)
              : null,
          child: info.profileImageUrl == null
              ? Icon(Icons.person, size: 40, color: Colors.grey.shade400)
              : null,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textTheme.bodyLarge?.color,
            ),
            children: [
              TextSpan(text: info.nickname),
              TextSpan(
                text: '\n$role',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String label,
    String? unit,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: iconColor),
                ),
                if (unit != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: iconColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, {required bool hasPartner}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('설정', style: Theme.of(context).textTheme.titleMedium),
          ),
          _buildMenuListItem(icon: Icons.person_outline, title: '프로필 수정', subtitle: '닉네임, 프로필 사진 변경', onTap: () => context.push('/edit_profile')),
          if (!hasPartner) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildMenuListItem(icon: Icons.favorite_border, title: '파트너 연결하기', subtitle: '파트너를 찾아 연결해보세요', onTap: () => context.push('/partner_linking')),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuListItem(icon: Icons.help_outline, title: '도움말', subtitle: 'ChemiQ 사용법 및 FAQ', onTap: () {}),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuListItem(icon: Icons.info_outline, title: '앱 정보', subtitle: '버전 정보 및 이용약관', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildAccountManagementMenu(BuildContext context, {required bool hasPartner}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('계정 관리', style: Theme.of(context).textTheme.titleMedium),
          ),
          _buildMenuListItem(
            icon: Icons.lock_outline,
            title: '비밀번호 변경',
            subtitle: '현재 로그인한 계정의 비밀번호를 변경',
            onTap: () => context.push('/change_password'),
          ),
          if (hasPartner) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildMenuListItem(
              icon: Icons.person_off_outlined,
              title: '파트너 관계 해제',
              subtitle: '현재 파트너와의 연결 끊기',
              textColor: Colors.red,
              onTap: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: '정말 관계를 해제하시겠어요?',
                  content: '이 작업은 되돌릴 수 없으며,\n모든 기록이 사라집니다.',
                  confirmText: '해제하기',
                  isDestructive: true,
                );
                if (confirmed) {
                  try {
                    showChemiQToast("파트너가 해제되었습니다.", type: ToastType.success);
                    await ref.read(myPageViewModelProvider.notifier).breakUp();
                  } catch (e) {
                    if (mounted) {
                      showChemiQToast(e.toString(), type: ToastType.error);
                    }
                  }
                }
              },
            ),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          _buildMenuListItem(
            icon: Icons.logout,
            title: '로그아웃',
            subtitle: '계정에서 안전하게 로그아웃',
            textColor: Colors.red,
            onTap: () async {
              final confirmed = await showConfirmationDialog(
                context: context,
                title: '로그아웃 하시겠어요?',
                content: '언제든지 다시 로그인할 수 있어요.',
                confirmText: '로그아웃',
                isDestructive: true,
              );
              if (confirmed) {
                showChemiQToast("로그아웃되었습니다.", type: ToastType.success);
                ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListItem({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey[600]),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: Icon(Icons.chevron_right, color: textColor ?? Colors.grey),
      onTap: onTap,
    );
  }
}