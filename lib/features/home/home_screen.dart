import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/ui/widgets/showConfirmation_dialog.dart';
import '../../data/models/myPage_response.dart';
import 'home_screen_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    ref.read(homeViewModelProvider.notifier).fetchTodayMission();
    ref.invalidate(myPageInfoProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final missionState = ref.watch(homeViewModelProvider);
    final myPageState = ref.watch(myPageInfoProvider);

    ref.listen<AsyncValue<MyPageResponse>>(myPageInfoProvider, (previous, next) {
      final wasLoading = previous == null || previous.isLoading;
      if (wasLoading && next.hasValue && next.value?.partnerInfo == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showActionDialog(
              context: context,
              title: '파트너를 연결해주세요',
              content: 'ChemiQ의 모든 기능을 사용하려면\n파트너 연결이 필요해요.\n지금 바로 파트너를 찾아볼까요?',
              actionText: '연결하러 가기',
              onAction: () => context.push('/partner_linking'),
            );
          }
        });
      }
    });

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: myPageState.when(
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
        data: (myPageInfo) {
          if (missionState.isLoading && myPageInfo == null) {
            return _buildLoadingShimmer();
          }
          if (missionState.error != null) {
            return Center(child: Text(missionState.error!));
          }
          return _buildBody(missionState, myPageInfo);
        },
      ),
    );
  }

  Widget _buildBody(HomeState missionState, MyPageResponse? myPageInfo) {
    final mission = missionState.dailyMission;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          if (myPageInfo != null) _buildPartnerInfoCard(myPageInfo),
          const SizedBox(height: 20),
          _buildTodayMissionCard(mission, context),
          const SizedBox(height: 20),
          // ✨ '오늘의 팁' 대신 '오늘의 진행 상황' 카드를 표시합니다.
          if (mission != null) _buildProgressCard(missionState),
        ],
      ),
    );
  }

  Widget _buildPartnerInfoCard(MyPageResponse myPageInfo) {
    // 파트너 정보가 있을 때만 이 카드를 보여줍니다.
    if (myPageInfo.partnerInfo == null) {
      return const SizedBox.shrink(); // 파트너 없으면 아무것도 안보여줌
    }
    return Card(
      // elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: myPageInfo.partnerInfo!.profileImageUrl != null
                  ? CachedNetworkImageProvider(myPageInfo.partnerInfo!.profileImageUrl!)
                  : null,
              child: myPageInfo.partnerInfo!.profileImageUrl == null ? const Icon(Icons.person, size: 28) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: myPageInfo.partnerInfo!.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '님과'),
                      ],
                    ),
                  ),
                  Text(
                    '함께하는 중',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _buildInfoItem(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.red.shade200,
              value: '${myPageInfo.partnershipInfo?.streakCount ?? 0}일',
              label: '스트릭',
            ),
            const SizedBox(width: 20),
            _buildInfoItem(
              icon: Icons.star_rounded,
              iconColor: Colors.green.shade200,
              value: '${myPageInfo.partnershipInfo?.chemiScore.toInt() ?? 0}%',
              label: '케미 지수',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMissionCard(dynamic mission, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_outlined, size: 32, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                '오늘의 퀘스트',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                mission?.missionTitle ?? '파트너를 연결하고 퀘스트를 받아보세요!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (mission != null && mission.mySubmission == null)
                ElevatedButton(
                  onPressed: () {
                    context.push(
                      '/mission_submission/${mission.dailyMissionId}',
                      extra: mission.missionTitle,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('퀘스트 인증하기'),
                )
              else if (mission != null && mission.mySubmission != null)
                OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('제출 완료'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ '오늘의 진행 상황'을 보여주는 새로운 카드 위젯
  Widget _buildProgressCard(HomeState missionState) {
    if (missionState.dailyMission == null) return const SizedBox.shrink();

    final mission = missionState.dailyMission!;
    final bool iSubmitted = mission.mySubmission != null;
    final bool partnerSubmitted = mission.partnerSubmission != null;
    final bool iEvaluated = partnerSubmitted && mission.partnerSubmission!.score != null;
    final bool partnerEvaluated = iSubmitted && mission.mySubmission!.score != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘의 진행 상황', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold,)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildProgressItem(icon: Icons.photo_camera_outlined, label: '내가 제출', isDone: iSubmitted)),
                const SizedBox(width: 12),
                Expanded(child: _buildProgressItem(icon: Icons.photo_camera_outlined, label: '파트너 제출', isDone: partnerSubmitted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildProgressItem(icon: Icons.rate_review_outlined, label: '내가 평가', isDone: iEvaluated)),
                const SizedBox(width: 12),
                Expanded(child: _buildProgressItem(icon: Icons.rate_review_outlined, label: '파트너 평가', isDone: partnerEvaluated)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✨ 진행 상황의 각 항목을 보여주는 위젯
  Widget _buildProgressItem({required IconData icon, required String label, required bool isDone}) {
    final color = isDone ? Theme.of(context).colorScheme.secondary : Colors.grey.shade400;
    return Row(
      children: [
        Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDone ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: const SizedBox(height: 70)),
          const SizedBox(height: 20),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), child: const SizedBox(height: 250)),
          const SizedBox(height: 20),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: const SizedBox(height: 90)),
        ],
      ),
    );
  }
}

