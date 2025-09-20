import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/ui/widgets/showConfirmation_dialog.dart';
import '../../data/models/home_partner_info_dto.dart';
import '../../data/models/home_summary_dto.dart';
import '../../data/models/myPage_response.dart';
import '../../data/models/weekly_status_dto.dart';
import 'home_screen_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshData() async {
    // ✨ 새로고침 시 통합 Provider 하나만 무효화합니다.
    ref.invalidate(homeSummaryProvider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ✨ 이제 단 하나의 통합 Provider만 감시합니다.
    final homeDataState = ref.watch(homeSummaryProvider);

    ref.listen<AsyncValue<HomeSummaryDto>>(homeSummaryProvider, (previous, next) {
      if (!next.isLoading && next.hasValue && next.value?.partnerInfo == null) {
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
      child: homeDataState.when(
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => Center(child: Text('데이터를 불러오지 못했습니다.\n아래로 당겨 새로고침 해주세요.')),
        data: (data) => _buildBody(data),
      ),
    );
  }

  // ✨ weeklyStatusState의 타입을 nullable(?)로 수정합니다.
  Widget _buildBody(HomeSummaryDto data) {
    final mission = data.dailyMission;
    final partnerInfo = data.partnerInfo;
    final weeklyStatus = data.weeklyStatus;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          if (partnerInfo != null) _buildPartnerInfoCard(partnerInfo),
          const SizedBox(height: 20),
          _buildTodayMissionCard(mission, context),
          const SizedBox(height: 20),
          if (mission != null) _buildProgressCard(mission),
          const SizedBox(height: 20),
          if (weeklyStatus != null) _buildWeeklyTrackerCard(weeklyStatus),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrackerCard(WeeklyMissionStatusResponse weeklyStatus) {
    const List<String> daysOfWeek = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final Map<String, String> dayLabels = {
      'MONDAY': '월', 'TUESDAY': '화', 'WEDNESDAY': '수', 'THURSDAY': '목', 'FRIDAY': '금', 'SATURDAY': '토', 'SUNDAY': '일'
    };

    return Card(
      // elevation: 0,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이번 주 퀘스트 현황', style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold,)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: daysOfWeek.map((dayKey) {
                final statusDto = weeklyStatus.weeklyStatus[dayKey];
                return _buildDayStatus(dayLabels[dayKey]!, statusDto);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayStatus(String dayLabel, MissionStatusDto? statusDto) {
    final todayLabel = DateFormat('E', 'ko_KR').format(DateTime.now());
    final isToday = dayLabel == todayLabel;

    Color circleColor;
    IconData? icon;

    switch (statusDto?.status) {
      case DailyMissionStatus.COMPLETED:
        circleColor = Theme.of(context).colorScheme.secondary;
        icon = Icons.check;
        break;
      case DailyMissionStatus.ASSIGNED:
        circleColor = Theme.of(context).colorScheme.primary.withOpacity(0.7);
        break;
      case DailyMissionStatus.FAILED:
        circleColor = Colors.grey.shade400;
        icon = Icons.close;
        break;
      case DailyMissionStatus.NOT_ASSIGNED:
      default:
        circleColor = Colors.grey.shade200;
        break;
    }

    return Column(
      children: [
        Text(
          dayLabel,
          style: TextStyle(
            color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: circleColor,
          child: icon != null ? Icon(icon, color: Colors.white, size: 20) : null,
        ),
      ],
    );
  }

  Widget _buildPartnerInfoCard(HomePartnerInfoDto partnerInfo) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: partnerInfo.profileImageUrl != null
                  ? CachedNetworkImageProvider(partnerInfo.profileImageUrl!)
                  : null,
              child: partnerInfo.profileImageUrl == null ? const Icon(Icons.person, size: 28) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium,
                  children: [
                    TextSpan(text: partnerInfo.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '님과\n함께하는 중'),
                  ],
                ),
              ),
            ),
            _buildInfoItem(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.red.shade400,
              value: '${partnerInfo.streakCount}일',
              label: '스트릭',
            ),
            const SizedBox(width: 20),
            _buildInfoItem(
              icon: Icons.star_rounded,
              iconColor: Colors.green.shade400,
              value: '${partnerInfo.chemiScore.toStringAsFixed(1)}%',
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
                mission?.missionTitle ?? '파트너를 연결하고\n퀘스트를 받아보세요!',
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

  Widget _buildProgressCard(dynamic mission) {
    final bool iSubmitted = mission.mySubmission != null;
    final bool partnerSubmitted = mission.partnerSubmission != null;
    final bool iEvaluated = partnerSubmitted && mission.partnerSubmission!.score != null;
    final bool partnerEvaluated = iSubmitted && mission.mySubmission!.score != null;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 진행상황', style:Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold,)),
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
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          children: [
            // Shimmer for _buildPartnerInfoCard
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer for _buildTodayMissionCard
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer for _buildProgressCard
            Container(
              height: 140, // Adjusted height to better fit the content
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Shimmer for _buildWeeklyTrackerCard
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

