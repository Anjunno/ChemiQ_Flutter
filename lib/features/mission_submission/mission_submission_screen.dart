import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../home/home_screen_view_model.dart';
import 'mission_submission_view_model.dart';

class MissionSubmissionScreen extends ConsumerWidget {
  final int dailyMissionId;
  final String missionTitle;

  const MissionSubmissionScreen({
    super.key,
    required this.dailyMissionId,
    required this.missionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(missionSubmissionViewModelProvider);
    final viewModel = ref.read(missionSubmissionViewModelProvider.notifier);
    final contentController = TextEditingController();

    // 제출 성공/실패 시 부가 효과 처리
    ref.listen(missionSubmissionViewModelProvider, (previous, next) {
      if (next.status == SubmissionStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('미션 제출 성공!')));
        // 홈 화면의 미션 목록을 새로고침하도록 신호를 보냄
        ref.read(homeViewModelProvider.notifier).fetchTodayMission();
        context.pop(); // 홈 화면으로 돌아가기
      }
      if (next.status == SubmissionStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(missionTitle)),
      body: Stack( // 로딩 인디케이터를 화면 위에 띄우기 위해 Stack 사용
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 이미지 선택 UI ---
                GestureDetector(
                  onTap: () => viewModel.pickImage(),
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      image: state.selectedImage != null
                          ? DecorationImage(
                        image: FileImage(File(state.selectedImage!.path)),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: state.selectedImage == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey.shade600),
                          const SizedBox(height: 8),
                          Text('사진을 추가해주세요', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
                // --- 글 내용 입력 UI ---
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '미션에 대한 글을 남겨보세요...',
                    counterText: '',
                  ),
                  maxLength: 200,
                  maxLines: 4,
                ),
                const Spacer(),
                // --- 제출 버튼 UI ---
                ElevatedButton(
                  onPressed: state.status == SubmissionStatus.loading
                      ? null // 로딩 중일 때 비활성화
                      : () {
                    viewModel.submitMission(
                      dailyMissionId: dailyMissionId,
                      content: contentController.text.trim(),
                    );
                  },
                  child: const Text('제출하기'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // --- 전체 화면 로딩 인디케이터 ---
          if (state.status == SubmissionStatus.loading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

