import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/dailyMission_response.dart';
import '../../data/models/myPage_response.dart';
import '../home/home_screen_view_model.dart';
import 'timeline_view_model.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
        ref.read(timelineViewModelProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(timelineViewModelProvider);
    final myPageState = ref.watch(myPageInfoProvider);

    if (state.isLoading || myPageState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.missions.isEmpty) {
      return Center(child: Text(state.error!));
    }
    if (myPageState.hasError) {
      return Center(child: Text(myPageState.error.toString()));
    }
    if (state.missions.isEmpty) {
      return const Center(child: Text('아직 기록이 없어요.'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(timelineViewModelProvider.notifier).fetchInitialTimeline();
        ref.invalidate(myPageInfoProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.missions.length + (state.canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.missions.length) {
            return state.isLoadingMore
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : const SizedBox.shrink();
          }
          final mission = state.missions[index];
          return _buildTimelineItem(mission, myPageState.value, context);
        },
      ),
    );
  }

  // ✨ 날짜/제목 헤더 디자인을 개선한 위젯
  Widget _buildTimelineItem(DailyMissionResponse mission, MyPageResponse? myPageInfo, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 새로운 날짜 및 제목 헤더 ---
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // '일'을 크게 표시
                Text(
                  DateFormat('d').format(mission.missionDate),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
                // '월, 요일'과 '미션 제목'을 세로로 배치
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM, EEEE', 'ko_KR').format(mission.missionDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.missionTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 제출물 카드 목록 ---
          if (mission.mySubmission != null && myPageInfo != null)
            _buildSubmissionCard('나의 기록', mission.mySubmission!, myPageInfo.myInfo, context),

          if (mission.mySubmission != null && mission.partnerSubmission != null)
            const SizedBox(height: 16),

          if (mission.partnerSubmission != null && myPageInfo?.partnerInfo != null)
            _buildSubmissionCard('파트너의 기록', mission.partnerSubmission!, myPageInfo!.partnerInfo!, context),

          if (mission.mySubmission == null && mission.partnerSubmission == null)
            const Center(child: Text('이 날은 미션을 제출하지 않았어요.', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // ✨ 개별 제출물을 보여주는 카드 위젯
  Widget _buildSubmissionCard(String title, SubmissionDetailDto submission, MemberInfoDto submitter, BuildContext context) {
    return InkWell(
      onTap: () => context.push('/mission_detail', extra: submission),
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
              height: 220,
              placeholder: (context, url) => Container(color: Colors.grey.shade200),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: submitter.profileImageUrl != null
                            ? CachedNetworkImageProvider(submitter.profileImageUrl!)
                            : null,
                        child: submitter.profileImageUrl == null ? const Icon(Icons.person, size: 14) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(submitter.nickname, style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      if (title == '나의 기록' && submission.score != null)
                        _buildStarRating(submission.score!)
                      else if (title == '파트너의 기록' && submission.score != null)
                        _buildStarRating(submission.score!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(submission.content),
                ],
              ),
            ),
          ],
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
}

