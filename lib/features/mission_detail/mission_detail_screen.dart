import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'mission_detail_view_model.dart';

class MissionDetailScreen extends ConsumerWidget {
  final SubmissionDetailDto submission;

  const MissionDetailScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .family Provider를 사용하여, 어떤 submission에 대한 ViewModel인지 명시합니다.
    final state = ref.watch(missionDetailViewModelProvider(submission));
    final viewModel = ref.read(missionDetailViewModelProvider(submission).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy.MM.dd 미션').format(submission.createdAt)),
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.fetchEvaluation(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  submission.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 350,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                submission.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Divider(height: 32),
              Text(
                '파트너의 평가',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // ✨ ViewModel의 상태에 따라 평가 UI를 다르게 그립니다.
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.error != null)
                Center(child: Text(state.error!, style: const TextStyle(color: Colors.red)))
              else if (state.evaluation == null)
                  const Center(child: Text('아직 파트너의 평가가 등록되지 않았어요.'))
                else
                // 불러온 평가 정보를 카드에 표시합니다.
                  _buildEvaluationCard(
                    context,
                    state.evaluation!.score,
                    state.evaluation!.comment,
                    state.evaluation!.evaluatorNickname,
                    state.evaluation!.createdAt, // createdAt 추가
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationCard(BuildContext context, double score, String comment, String evaluator, DateTime createdAt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$evaluator님의 평가',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildStarRating(score),
              ],
            ),
            const SizedBox(height: 8),
            if (comment.isNotEmpty) // 코멘트가 있을 때만 표시
              Text(comment),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('yyyy.MM.dd HH:mm').format(createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
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

