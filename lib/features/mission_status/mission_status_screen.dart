import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:chemiq/data/models/member_info_dto.dart';

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '오늘 할당된 퀘스트가 없어요. 😌',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '파트너와 함께한 즐거운 추억들은 타임라인에서 확인하실 수 있어요.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final mission = state.dailyMission!;

    final bool iSubmitted = mission.mySubmission != null;
    final bool partnerSubmitted = mission.partnerSubmission != null;
    final int submissionCount = (iSubmitted ? 1 : 0) + (partnerSubmitted ? 1 : 0);
    final bool isSubmissionStageComplete = submissionCount == 2;

    final bool iEvaluated = partnerSubmitted && mission.partnerSubmission!.score != null;
    final bool partnerEvaluated = iSubmitted && mission.mySubmission!.score != null;
    final int evaluationCount = (iEvaluated ? 1 : 0) + (partnerEvaluated ? 1 : 0);
    final bool isEvaluationStageComplete = evaluationCount == 2;

    final bool isMissionComplete = isSubmissionStageComplete && isEvaluationStageComplete;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMissionHeader(
            context,
            mission: mission,
            isMissionComplete: isMissionComplete,
            isSubmissionStageComplete: isSubmissionStageComplete,
            isEvaluationStageComplete: isEvaluationStageComplete,
            submissionCount: submissionCount,
            evaluationCount: evaluationCount,
          ),

          const SizedBox(height: 24),

          _buildSubmissionCard(
            context: context,
            isMe: true,
            // title: '내 기록',
            // subtitle: '나의 미션 수행 결과',
            submitterInfo: myPageInfo.myInfo,
            submission: mission.mySubmission,
            mission: mission,
            myPageInfo: myPageInfo,
          ),

          const SizedBox(height: 24),

          if (myPageInfo.partnerInfo != null)
            _buildSubmissionCard(
              context: context,
              isMe: false,
              // title: '파트너 기록',
              // subtitle: '파트너의 미션 수행 결과',
              submitterInfo: myPageInfo.partnerInfo!,
              submission: mission.partnerSubmission,
              mission: mission,
              myPageInfo: myPageInfo,
            ),
        ],
      ),
    );
  }

  // ✨ 상단 정보 블록 UI 개선
  Widget _buildMissionHeader(
      BuildContext context, {
        required dynamic mission,
        required bool isMissionComplete,
        required bool isSubmissionStageComplete,
        required bool isEvaluationStageComplete,
        required int submissionCount,
        required int evaluationCount,
      }) {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('M월 d일').format(mission.missionDate),
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                mission.missionTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ✨ 아이콘 기반의 간결한 진행률 표시
              Row(
                children: [
                  _buildProgressItem(
                    icon: Icons.photo_camera_outlined,
                    isComplete: isSubmissionStageComplete,
                    progressText: "$submissionCount/2",
                  ),
                  const SizedBox(width: 16),
                  _buildProgressItem(
                    icon: Icons.rate_review_outlined,
                    isComplete: isEvaluationStageComplete,
                    progressText: "$evaluationCount/2",
                  ),
                  const Spacer(),
                  if (isMissionComplete)
                    // const SizedBox(width: 16),
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
                          Text('퀘스트 완료!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ 아이콘 기반의 진행률 아이템
  Widget _buildProgressItem(
      {required IconData icon, required bool isComplete, required String progressText}) {
    final theme = Theme.of(context);
    final color = isComplete ? theme.colorScheme.secondary : Colors.grey.shade500;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          progressText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ✨ 수정된 카드 위젯
  Widget _buildSubmissionCard({
    required BuildContext context,
    // required String title,
    // required String subtitle,
    required bool isMe,
    required MemberInfoDto submitterInfo,
    required SubmissionDetailDto? submission,
    required dynamic mission,
    required MyPageResponse myPageInfo,
  }) {
    final String title = isMe ? '내 기록' : '파트너 기록';
    final String subtitle = isMe ? '나의 퀘스트 수행 결과' : '파트너의 퀘스트 수행 결과';
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: submitterInfo.profileImageUrl != null
                      ? CachedNetworkImageProvider(submitterInfo.profileImageUrl!)
                      : null,
                  child: submitterInfo.profileImageUrl == null ? const Icon(Icons.person, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (submission != null)
              _buildSubmittedContent(context, submission, isMe, mission, myPageInfo)
            else
              _buildEmptySubmission(context, isMe, mission),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedContent(BuildContext context, SubmissionDetailDto submission, bool isMe, dynamic mission, MyPageResponse myPageInfo) {
    final double? scoreToShow = submission.score;
    VoidCallback onTapAction;
    final submitterInfo = isMe ? myPageInfo.myInfo : myPageInfo.partnerInfo!;

    if (isMe) {
      onTapAction = () => context.push('/mission_detail', extra: {'submission': submission, 'submitterInfo': submitterInfo, 'missionTitle': mission.missionTitle});
    } else {
      onTapAction = submission.score == null
          ? () => context.push('/evaluation/${submission.submissionId}', extra: submission)
          : () => context.push('/mission_detail', extra: {'submission': submission, 'submitterInfo': submitterInfo, 'missionTitle': mission.missionTitle});
    }

    return InkWell(
      onTap: onTapAction,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✨ Stack을 사용하여 이미지 위에 별점을 오버레이합니다.
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: submission.imageUrl,
                imageBuilder: (context, imageProvider) => AspectRatio(
                  aspectRatio: 4/3,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                ),
                placeholder: (context, url) => AspectRatio(aspectRatio: 4/3, child: Container(color: Colors.grey.shade200)),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              // 파트너가 남긴 평가 점수를 우측 상단에 표시
              if (scoreToShow != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _buildStarRating(scoreToShow),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(submission.content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildEmptySubmission(BuildContext context, bool isMe, dynamic mission) {
    return AspectRatio(
      aspectRatio: 16 / 11,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isMe ? Icons.add_photo_alternate_outlined : Icons.hourglass_empty, color: Colors.grey.shade400, size: 40),
              const SizedBox(height: 12),
              Text(isMe ? '퀘스트를 인증해주세요' : '파트너를 기다리는 중', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              isMe
                  // ? ElevatedButton(onPressed: () => context.push('/mission_submission/${mission.dailyMissionId}', extra: mission.missionTitle), child: const Text('미션 인증하기'))
                  ? ElevatedButton(
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
                  : OutlinedButton(onPressed: null, child: const Text('대기 중')),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ 새로운 별점 위젯
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
        return Icon(icon, color: Colors.white, size: 16); // 배경이 어두우므로 흰색 별 사용
      }),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildShimmerCard(),
          const SizedBox(height: 24),
          _buildShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 16, color: Colors.white),
                const SizedBox(height: 4),
                Container(width: 120, height: 12, color: Colors.white),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: AspectRatio(aspectRatio: 4/3, child: Container(color: Colors.white)),
        )
      ],
    );
  }
}

