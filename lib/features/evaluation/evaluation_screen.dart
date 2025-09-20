import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home/home_screen_view_model.dart';
import '../mission_status/mission_status_view_model.dart';
import '../timeline/timeline_view_model.dart';
import 'evaluation_view_model.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  final int submissionId;
  final SubmissionDetailDto partnerSubmission;

  const EvaluationScreen({
    super.key,
    required this.submissionId,
    required this.partnerSubmission,
  });

  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentController.addListener(() {
      ref.read(evaluationViewModelProvider.notifier).onCommentChanged(_commentController.text);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✨ ViewModel의 상태 변화를 감지하여, 관련된 모든 Provider를 새로고침합니다.
    ref.listen(evaluationViewModelProvider, (previous, next) {
      if (next.status == EvaluationStatus.success) {
        showChemiQToast('평가를 완료했어요!', type: ToastType.success);

        // 1. 홈 화면의 통합 데이터를 새로고침합니다.
        ref.invalidate(homeSummaryProvider);
        // 2. 미션 현황 탭의 데이터를 새로고침합니다.
        ref.invalidate(missionStatusViewModelProvider);
        ref.invalidate(missionStatusMyPageProvider);
        // 3. 타임라인 탭의 데이터를 새로고침합니다.
        ref.invalidate(timelineViewModelProvider);

        context.pop(); // 이전 화면으로 돌아갑니다.
      }
      if (next.status == EvaluationStatus.error && next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    final state = ref.watch(evaluationViewModelProvider);
    final viewModel = ref.read(evaluationViewModelProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('코멘트 남기기')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('파트너의 제출물', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildSubmissionPreview(),
              const SizedBox(height: 32),
              Text('코멘트 남기기', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildEvaluationForm(state, viewModel),
              const SizedBox(height: 32),
              PrimaryButton(
                text: '제출하기',
                isLoading: state.status == EvaluationStatus.loading,
                onPressed: state.isFormValid
                    ? () => viewModel.submitEvaluation(submissionId: widget.submissionId)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionPreview() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CachedNetworkImage(
            imageUrl: widget.partnerSubmission.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            placeholder: (context, url) => Container(height: 300, color: Colors.grey.shade200),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          if (widget.partnerSubmission.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.partnerSubmission.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvaluationForm(EvaluationState state, EvaluationViewModel viewModel) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
            child: Column(
              children: [
                Text(
                  '별점을 매겨주세요 (${state.score.toStringAsFixed(1)})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildStarRatingInput(
                  currentScore: state.score,
                  onScoreChanged: (newScore) => viewModel.onScoreChanged(newScore),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            // ✨ ConstrainedBox를 사용하여 최소 높이를 지정합니다.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 100, // 텍스트 필드의 최소 높이
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '파트너에게 따뜻한 코멘트를 남겨주세요',
                  border: InputBorder.none,           // 기본 테두리 제거
                  focusedBorder: InputBorder.none,    // 포커스 시 테두리 제거
                  enabledBorder: InputBorder.none,    // 활성화 시 테두리 제거
                  disabledBorder: InputBorder.none,   // 비활성화 시 테두리 제거
                  fillColor: Colors.transparent,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                maxLength: 150,
              ),
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStarRatingInput({
    required double currentScore,
    required ValueChanged<double> onScoreChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth;
        void updateScore(Offset localPosition) {
          final double starWidth = totalWidth / 5;
          final double rawScore = localPosition.dx / starWidth;
          final double newScore = (rawScore * 2).round() / 2;
          onScoreChanged(newScore.clamp(0.0, 5.0));
        }
        return GestureDetector(
          onHorizontalDragUpdate: (details) => updateScore(details.localPosition),
          onTapDown: (details) => updateScore(details.localPosition),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              IconData icon;
              if (currentScore >= index + 1) {
                icon = Icons.star_rounded;
              } else if (currentScore >= index + 0.5) {
                icon = Icons.star_half_rounded;
              } else {
                icon = Icons.star_border_rounded;
              }
              return Icon(
                icon,
                color: Colors.amber,
                size: 44,
              );
            }),
          ),
        );
      },
    );
  }
}

