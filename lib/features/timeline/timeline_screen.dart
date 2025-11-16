import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
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
    final myPageState = ref.watch(timelineMyPageProvider);

    if (state.isLoading && state.missions.isEmpty || myPageState.isLoading) {
      return _buildLoadingShimmer(); // Call shimmer effect when loading
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
        ref.invalidate(timelineMyPageProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.missions.length + (state.canLoadMore ? 1 : 0),
        // itemCount: filteredMissions.length + (state.canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.missions.length) {
          // if (index == filteredMissions.length) {
            return state.isLoadingMore
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : const SizedBox.shrink();
          }
          final mission = state.missions[index];
          // final mission = filteredMissions[index];
          return _buildTimelineItem(mission, myPageState.value, context);
        },
      ),
    );
  }

  // Shimmer Loading Widgets
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4, // Show a few placeholder items
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Shimmer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 40, color: Colors.white, margin: const EdgeInsets.only(right: 12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 150, height: 12, color: Colors.white),
                        const SizedBox(height: 4),
                        Container(width: 200, height: 20, color: Colors.white),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Submission Card Shimmer
                _buildShimmerSubmissionCard(),
                const SizedBox(height: 16),
                _buildShimmerSubmissionCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerSubmissionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 14, backgroundColor: Colors.white),
                    const SizedBox(width: 8),
                    Container(width: 80, height: 16, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Container(width: double.infinity, height: 16, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Rest of your existing widgets...
  Widget _buildTimelineItem(DailyMissionResponse mission, MyPageResponse? myPageInfo, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  DateFormat('d').format(mission.missionDate),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 12),
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

          if (mission.mySubmission != null && myPageInfo != null)
            _buildSubmissionCard(
              '나의 기록',
              mission.mySubmission!,
              myPageInfo.myInfo,
              context,
              mission.missionTitle,
            ),

          if (mission.mySubmission != null && mission.partnerSubmission != null)
            const SizedBox(height: 16),

          if (mission.partnerSubmission != null && myPageInfo?.partnerInfo != null)
            _buildSubmissionCard(
              '파트너의 기록',
              mission.partnerSubmission!,
              myPageInfo!.partnerInfo!,
              context,
              mission.missionTitle,
            ),

          if (mission.mySubmission == null && mission.partnerSubmission == null)
            const Center(child: Text('이 날은 퀘스트를 제출하지 않았어요.', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(String title, SubmissionDetailDto submission, MemberInfoDto submitter, BuildContext context, String missionTitle) {
    return InkWell(
      onTap: () {
        context.push('/mission_detail', extra: {
          'submission': submission,
          'submitterInfo': submitter,
          'missionTitle': missionTitle,
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.08),
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
                      if (submission.score != null)
                        _buildStarRating(submission.score!)
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