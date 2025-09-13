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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).fetchTodayMission();
      ref.invalidate(myPageInfoProvider);
    });
  }

  Future<void> _refreshData() async {
    // 두 데이터를 동시에 새로고침합니다.
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
            // ✨ 복잡한 showDialog 대신, 새로 만든 showActionDialog를 사용합니다.
            showActionDialog(
              context: context,
              title: '파트너를 연결해주세요',
              content: 'ChemiQ의 모든 기능을 사용하려면 파트너 연결이 필요해요. 지금 바로 파트너를 찾아볼까요?',
              actionText: '연결하러 가기',
              onAction: () => context.push('/partner_linking'),
            );
          }
        });
      }
    });

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(homeViewModelProvider.notifier).fetchTodayMission();
        ref.invalidate(myPageInfoProvider);
      },
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
          _buildTodaysTipCard(context),
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
      elevation: 2,
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
                '오늘의 미션',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                mission?.missionTitle ?? '파트너를 연결하고 미션을 받아보세요!',
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
                  child: const Text('미션 인증하기'),
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

  Widget _buildTodaysTipCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.lightGreen.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('오늘의 팁', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  const SizedBox(height: 4),
                  Text(
                      '하늘 사진을 찍을 땐 황금시간대(일출/일몰)를 노려보세요! ✨',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green.shade900)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

