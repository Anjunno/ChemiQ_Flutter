import 'package:chemiq/data/models/submission_detail_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../home/home_screen_view_model.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('평가를 완료했어요!')));
        ref.read(homeViewModelProvider.notifier).fetchTodayMission(); // 홈 화면 새로고침
        context.pop();
      }
      if (next.status == EvaluationStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(evaluationViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('파트너 평가하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 파트너가 제출한 내용 미리보기
            Text('파트너의 제출물', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(widget.partnerSubmission.imageUrl, fit: BoxFit.cover, width: double.infinity, height: 180),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.partnerSubmission.content),
                  ],
                ),
              ),
            ),
            const Divider(height: 48),

            // 평가 입력 UI
            Text('평가 남기기', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Text('점수: ${_currentScore.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            Slider(
              value: _currentScore,
              min: 0,
              max: 5,
              divisions: 10, // 0.5 단위로 조절
              label: _currentScore.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _currentScore = value;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '파트너에게 코멘트를 남겨주세요.'),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: state.status == EvaluationStatus.loading
                  ? null
                  : () {
                ref.read(evaluationViewModelProvider.notifier).submitEvaluation(
                  submissionId: widget.submissionId,
                  score: _currentScore,
                  comment: _commentController.text.trim(),
                );
              },
              child: state.status == EvaluationStatus.loading ? const CircularProgressIndicator() : const Text('평가 제출하기'),
            ),
          ],
        ),
      ),
    );
  }
}
