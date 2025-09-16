import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'mission_detail_view_model.dart';

class MissionDetailScreen extends ConsumerWidget {
  final SubmissionDetailDto submission;
  final MemberInfoDto submitterInfo;
  final String missionTitle;

  const MissionDetailScreen({
    super.key,
    required this.submission,
    required this.submitterInfo,
    required this.missionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionDetailViewModelProvider(submission));
    final viewModel = ref.read(missionDetailViewModelProvider(submission).notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchEvaluation(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderImage(context, submission, missionTitle),
              const SizedBox(height: 24),
              _buildSubmissionDetailCard(context, state, submitterInfo, submission),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context, SubmissionDetailDto submission, String missionTitle) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        // ✨ 사진을 탭하면 /photo_viewer 경로로 이동
        onTap: () {
          context.push('/photo_viewer', extra: submission.imageUrl);
        },
        child: Stack(
          children: [
            // ✨ Hero 위젯으로 감싸 부드러운 전환 애니메이션 효과를 줍니다.
            Hero(
              tag: submission.imageUrl,
              child: CachedNetworkImage(
                imageUrl: submission.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                imageBuilder: (context, imageProvider) => AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                    ),
                  ),
                ),
                placeholder: (context, url) => AspectRatio(
                  aspectRatio: 1,
                  child: Container(color: Colors.grey.shade200),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('yyyy년 M월 d일').format(submission.createdAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    missionTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionDetailCard(BuildContext context, MissionDetailState state, MemberInfoDto submitter, SubmissionDetailDto submission) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: submitter.profileImageUrl != null ? CachedNetworkImageProvider(submitter.profileImageUrl!) : null,
                  child: submitter.profileImageUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submitter.nickname, style: textTheme.titleMedium),
                    Text(DateFormat('yy.MM.dd HH:mm').format(submission.createdAt), style: textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(submission.content, style: textTheme.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 20),

            if (state.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (state.error != null)
              Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
            else if (state.evaluation == null)
                const Center(child: Text('파트너의 코멘트가 없어요'))
              else
                _buildEvaluationCard(context, state.evaluation!),
          ],
        ),
      ),
    );
  }

  // ✨ 평가 카드 UI의 배치를 개선합니다.
  Widget _buildEvaluationCard(BuildContext context, dynamic evaluation) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 평가자 정보와 별점을 한 줄에 배치
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, // 세로 정렬을 위쪽으로
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: evaluation.evaluatorProfileImageUrl != null
                      ? CachedNetworkImageProvider(evaluation.evaluatorProfileImageUrl!)
                      : null,
                  child: evaluation.evaluatorProfileImageUrl == null ? const Icon(Icons.person, size: 18) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${evaluation.evaluatorNickname}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormat('yy.MM.dd hh:mm').format(evaluation.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildStarRating(evaluation.score), // 별점을 오른쪽 끝으로
              ],
            ),
            // ✨ Divider 대신 SizedBox와 Container를 사용해 더 부드러운 구분선을 만듭니다.
            if (evaluation.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1))
                ),
                child: Text(evaluation.comment, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index >= score) return Icon(Icons.star_border_rounded, color: Colors.amber, size: 20);
        if (index > score - 1 && index < score) return Icon(Icons.star_half_rounded, color: Colors.amber, size: 20);
        return Icon(Icons.star_rounded, color: Colors.amber, size: 20);
      }),
    );
  }
}

