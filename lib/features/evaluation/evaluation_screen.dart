import 'package:cached_network_image/cached_network_image.dart';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/custom_text_field.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../home/home_screen_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  double _currentScore = 3.0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(evaluationViewModelProvider, (previous, next) {
      if (next.status == EvaluationStatus.success) {
        showChemiQToast('평가를 완료했어요!', type: ToastType.success);
        ref.read(homeViewModelProvider.notifier).fetchTodayMission();
        context.pop();
      }
      if (next.status == EvaluationStatus.error && next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    final state = ref.watch(evaluationViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('파트너 평가하기')),
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

              Text('평가 남기기', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildEvaluationForm(state),
              const SizedBox(height: 32),

              // ✨ ElevatedButton 대신 새로 만든 PrimaryButton 사용
              PrimaryButton(
                text: '평가 제출하기',
                isLoading: state.status == EvaluationStatus.loading,
                onPressed: () {
                  ref.read(evaluationViewModelProvider.notifier).submitEvaluation(
                    submissionId: widget.submissionId,
                    score: _currentScore,
                    comment: _commentController.text.trim(),
                  );
                },
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
            height: 220,
            placeholder: (context, url) => Container(color: Colors.grey.shade200),
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

  Widget _buildEvaluationForm(EvaluationState state) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '점수: ${_currentScore.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentScore,
              min: 0,
              max: 5,
              divisions: 10,
              label: _currentScore.toStringAsFixed(1),
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              onChanged: (double value) {
                setState(() {
                  _currentScore = value;
                });
              },
            ),
            const SizedBox(height: 24),
            // ✨ TextField 대신 새로 만든 CustomTextField 사용
            CustomTextField(
              controller: _commentController,
              hintText: '파트너에게 따뜻한 코멘트를 남겨주세요',
              maxLines: 4,
              maxLength: 150,
            ),
            // TextField(
            //   controller: _commentController,
            //   decoration: const InputDecoration(
            //     hintText: '파트너에게 따뜻한 코멘트를 남겨주세요',
            //
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

