import 'dart:io';
import 'package:chemiq/core/ui/chemiq_toast.dart';
import 'package:chemiq/core/ui/widgets/primary_button.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../home/home_screen_view_model.dart';
import 'mission_submission_view_model.dart';

class MissionSubmissionScreen extends ConsumerStatefulWidget {
  final int dailyMissionId;
  final String missionTitle;

  const MissionSubmissionScreen({
    super.key,
    required this.dailyMissionId,
    required this.missionTitle,
  });

  @override
  ConsumerState<MissionSubmissionScreen> createState() => _MissionSubmissionScreenState();
}

class _MissionSubmissionScreenState extends ConsumerState<MissionSubmissionScreen> {
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _showImageSourcePicker(BuildContext context, MissionSubmissionViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.of(context).pop();
                  viewModel.pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.of(context).pop();
                  viewModel.pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionSubmissionViewModelProvider);
    final viewModel = ref.read(missionSubmissionViewModelProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    ref.listen(missionSubmissionViewModelProvider, (previous, next) {
      if (next.status == SubmissionStatus.success) {
        showChemiQToast('퀘스트 기록 완료!', type: ToastType.success);
        ref.read(homeViewModelProvider.notifier).fetchTodayMission();
        context.pop();
      }
      if (next.status == SubmissionStatus.error && next.errorMessage != null) {
        showChemiQToast(next.errorMessage!, type: ToastType.error);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(widget.missionTitle)),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(context, state, viewModel),
              const SizedBox(height: 32),
              Text('오늘의 기록', style: textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  hintText: '사진에 대한 이야기를 남겨보세요...',
                  counterText: '${state.contentLength}/150',
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLength: 150,
                maxLines: 5,
                onChanged: (text) => viewModel.onContentChanged(text),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: '기록하기',
                isLoading: state.status == SubmissionStatus.loading,
                // ✨ isFormValid 상태에 따라 버튼의 onPressed를 null 또는 함수로 설정합니다.
                onPressed: state.isFormValid
                    ? () {
                  viewModel.submitMission(
                    dailyMissionId: widget.dailyMissionId,
                    content: _contentController.text.trim(),
                  );
                }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, MissionSubmissionState state, MissionSubmissionViewModel viewModel) {
    return GestureDetector(
      onTap: () => _showImageSourcePicker(context, viewModel),
      child: DottedBorder(
        color: Colors.grey.shade300,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        borderType: BorderType.RRect,
        radius: const Radius.circular(16),
        child: AspectRatio(
          aspectRatio: 10 / 11,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('사진을 추가하려면 탭하세요', style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 4),
                  Text('JPG, PNG 파일만 가능', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500)),
                ],
              ),
            )
                : null,
          ),
        ),
      ),
    );
  }
}

