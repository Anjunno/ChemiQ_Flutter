import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models/myPage_response.dart';
import '../home/home_screen_view_model.dart';

class MissionStatusScreen extends ConsumerStatefulWidget {
  const MissionStatusScreen({super.key});

  @override
  ConsumerState<MissionStatusScreen> createState() => _MissionStatusScreenState();
}

class _MissionStatusScreenState extends ConsumerState<MissionStatusScreen> with AutomaticKeepAliveClientMixin {
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

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: myPageState.when(
        loading: () => _buildLoadingShimmer(),
        error: (err, stack) => Center(child: Text('오류: $err')),
        data: (myPageInfo) {
          if (missionState.isLoading) return _buildLoadingShimmer();
          if (missionState.error != null) return Center(child: Text(missionState.error!));
          return _buildBody(missionState, myPageInfo);
        },
      ),
    );
  }

  Widget _buildBody(HomeState state, MyPageResponse myPageInfo) {
    if (state.dailyMission == null) {
      return const Center(child: Text('오늘 할당된 미션이 없어요. 😌'));
    }

    final mission = state.dailyMission!;

    // --- 미션 진행 상태 계산 ---
    final bool iSubmitted = mission.mySubmission != null;
    final bool partnerSubmitted = mission.partnerSubmission != null;
    final int submissionCount = (iSubmitted ? 1 : 0) + (partnerSubmitted ? 1 : 0);
    final bool isSubmissionStageComplete = submissionCount == 2;

    // ✨ 평가 점수 로직을 정확하게 수정합니다.
    final bool iEvaluated = partnerSubmitted && mission.partnerSubmission!.score != null;
    final bool partnerEvaluated = iSubmitted && mission.mySubmission!.score != null;
    final int evaluationCount = (iEvaluated ? 1 : 0) + (partnerEvaluated ? 1 : 0);
    final bool isEvaluationStageComplete = evaluationCount == 2;

    final bool isMissionComplete = isSubmissionStageComplete && isEvaluationStageComplete;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      // ✨ 바깥쪽 Card를 제거하고 Column으로 구조를 변경합니다.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 미션 제목 ---
          Row(
            children: [
              Text(
                DateFormat('M월 d일').format(mission.missionDate),
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (isMissionComplete)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '미션 완료!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.missionTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // --- 체크리스트 ---
          _buildCompletionChecklist(isSubmissionStageComplete, isEvaluationStageComplete, submissionCount, evaluationCount),
          const SizedBox(height: 24),

          // --- 나의 기록 ---
          _buildSubmissionCard(
            context: context,
            title: '나의 기록',
            submitterInfo: myPageInfo.myInfo,
            submission: mission.mySubmission,
            mission: mission,
          ),

          const SizedBox(height: 24),

          // --- 파트너 기록 ---
          if (myPageInfo.partnerInfo != null)
            _buildSubmissionCard(
              context: context,
              title: '파트너의 기록',
              submitterInfo: myPageInfo.partnerInfo!,
              submission: mission.partnerSubmission,
              mission: mission,
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionChecklist(bool isSubmissionStageComplete, bool isEvaluationStageComplete, int submissionCount, int evaluationCount) {
    return Row(
      children: [
        Expanded(child: _buildChecklistItemCard("미션 제출", isSubmissionStageComplete, "($submissionCount/2)")),
        const SizedBox(width: 12),
        Expanded(child: _buildChecklistItemCard("기록 평가", isEvaluationStageComplete, "($evaluationCount/2)")),
      ],
    );
  }

  // ✨ 체크리스트 카드의 두께(padding)를 조절합니다.
  Widget _buildChecklistItemCard(String title, bool isChecked, String progressText) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isChecked ? colorScheme.secondary.withOpacity(0.5) : Colors.grey.shade300),
      ),
      color: isChecked ? colorScheme.secondary.withOpacity(0.1) : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0), // 두께 조절
        child: Row(
          children: [
            Icon(
              isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: isChecked ? colorScheme.secondary : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isChecked ? colorScheme.secondary : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            Text(
              progressText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isChecked ? colorScheme.secondary : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecordHeader(String title, String? imageUrl) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
          child: imageUrl == null ? const Icon(Icons.person, size: 14) : null,
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildSubmissionCard({
    required BuildContext context,
    required String title,
    required dynamic submitterInfo,
    required SubmissionDetailDto? submission,
    required dynamic mission,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildRecordHeader(title, submitterInfo.profileImageUrl),
        ),
        const SizedBox(height: 12),
        if (submission != null)
          _buildSubmittedContent(context, submission, title == '나의 기록')
        else
          _buildEmptySubmission(context, title == '나의 기록', mission),
      ],
    );
  }

  Widget _buildSubmittedContent(BuildContext context, SubmissionDetailDto submission, bool isMe) {
    final double? scoreToShow = isMe ? submission.score : submission.score;
    VoidCallback onTapAction;
    if (isMe) {
      onTapAction = () => context.push('/mission_detail', extra: submission);
    } else {
      onTapAction = submission.score == null
          ? () => context.push('/evaluation/${submission.submissionId}', extra: submission)
          : () => context.push('/mission_detail', extra: submission);
    }

    return InkWell(
      onTap: onTapAction,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: submission.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              placeholder: (context, url) => Container(color: Colors.grey.shade200),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (scoreToShow != null) ...[
                    _buildStarRating(scoreToShow),
                    const SizedBox(height: 8),
                  ],
                  Text(submission.content, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySubmission(BuildContext context, bool isMe, dynamic mission) {
    return AspectRatio(
      aspectRatio: 16/11,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isMe ? Icons.add_photo_alternate_outlined : Icons.hourglass_empty, color: Colors.grey.shade400, size: 40),
              const SizedBox(height: 12),
              Text(isMe ? '미션을 인증해주세요' : '파트너를 기다리는 중', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              isMe
                  ? ElevatedButton(onPressed: () => context.push('/mission_submission/${mission.dailyMissionId}', extra: mission.missionTitle), child: const Text('미션 인증하기'))
                  : OutlinedButton(onPressed: null, child: const Text('대기 중')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index >= score) {
          icon = Icons.star_border_rounded;
        } else if (index > score - 1 && index < score) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_rounded;
        }
        return Icon(icon, color: Colors.amber, size: 20);
      }),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: const SizedBox(height: 120),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const SizedBox(height: 350),
            ),
          ],
        ),
      ),
    );
  }
}

