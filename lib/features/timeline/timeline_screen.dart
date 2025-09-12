
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/dailyMission_response.dart';
import 'timeline_view_model.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 스크롤 컨트롤러에 리스너를 추가하여, 스크롤이 맨 아래에 도달했는지 감지합니다.
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
          _scrollController.position.maxScrollExtent - 200) { // 맨 아래 근처에 도달하면
        // 다음 페이지를 로드합니다.
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
    final state = ref.watch(timelineViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('타임라인')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TimelineState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.missions.isEmpty) {
      return Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)));
    }
    if (state.missions.isEmpty) {
      return const Center(child: Text('아직 기록이 없어요.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(timelineViewModelProvider.notifier).fetchInitialTimeline(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.missions.length + (state.canLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 마지막 아이템이고, 더 불러올 페이지가 있다면 로딩 인디케이터를 보여줍니다.
          if (index == state.missions.length) {
            return state.isLoadingMore
                ? const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ))
                : const SizedBox.shrink(); // 로딩중이 아니면 아무것도 안보여줌
          }
          final mission = state.missions[index];
          return _buildTimelineItem(mission, context);
        },
      ),
    );
  }

  /// 각 날짜별 미션 기록을 카드 형태로 그리는 위젯입니다.
  Widget _buildTimelineItem(DailyMissionResponse mission, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('yyyy년 MM월 dd일').format(mission.missionDate),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(mission.missionTitle, style: Theme.of(context).textTheme.titleLarge),
          const Divider(height: 24),

          if (mission.mySubmission != null)
            InkWell(
              onTap: () => context.go('/mission_detail', extra: mission.mySubmission!),
              child: _buildSubmissionPreview('나의 기록', mission.mySubmission!, context),
            ),

          if (mission.mySubmission != null && mission.partnerSubmission != null)
            const SizedBox(height: 16),

          if (mission.partnerSubmission != null)
            InkWell(
              onTap: () => context.go('/mission_detail', extra: mission.partnerSubmission!),
              child: _buildSubmissionPreview('파트너의 기록', mission.partnerSubmission!, context),
            ),

          if (mission.mySubmission == null && mission.partnerSubmission == null)
            const Center(child: Text('이 날은 미션을 제출하지 않았어요.', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  /// 제출된 사진과 글, 평가를 보여주는 위젯입니다.
  Widget _buildSubmissionPreview(String title, SubmissionDetailDto submission, BuildContext context) {
    // '나의 기록' 카드에는 파트너가 남긴 평가를, '파트너의 기록' 카드에는 내가 남긴 평가를 보여줍니다.
    final scoreToShow = (title == '나의 기록') ? submission.score /* 파트너가 나에게 준 점수. 현재 API에서는 제공되지 않음 */ : submission.score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (scoreToShow != null) _buildStarRating(scoreToShow),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            submission.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 200,
            loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Text(submission.content),
      ],
    );
  }

  /// 점수를 받아 별점 아이콘 목록을 만들어주는 위젯입니다.
  Widget _buildStarRating(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index >= score) {
          icon = Icons.star_border_rounded; // 빈 별
        } else if (index > score - 1 && index < score) {
          icon = Icons.star_half_rounded; // 반쪽 별
        } else {
          icon = Icons.star_rounded; // 꽉 찬 별
        }
        return Icon(icon, color: Colors.amber, size: 20);
      }),
    );
  }
}

