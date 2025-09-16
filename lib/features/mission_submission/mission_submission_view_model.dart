import 'dart:typed_data';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// 미션 제출 과정의 상태를 나타내는 Enum
enum SubmissionStatus {
  idle,
  loading,
  success,
  error,
}

// 미션 제출 화면의 전체 상태를 관리하는 클래스
class MissionSubmissionState {
  final SubmissionStatus status;
  final XFile? selectedImage;
  final String? errorMessage;
  final int contentLength;

  // ✨ 사진과 기록이 모두 입력되었는지 확인하는 getter를 추가합니다.
  bool get isFormValid => selectedImage != null && contentLength > 0;

  MissionSubmissionState({
    this.status = SubmissionStatus.idle,
    this.selectedImage,
    this.errorMessage,
    this.contentLength = 0,
  });

  MissionSubmissionState copyWith({
    SubmissionStatus? status,
    XFile? selectedImage,
    String? errorMessage,
    int? contentLength,
  }) {
    return MissionSubmissionState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      errorMessage: errorMessage,
      contentLength: contentLength ?? this.contentLength,
    );
  }
}

// ViewModel
class MissionSubmissionViewModel extends StateNotifier<MissionSubmissionState> {
  final MissionRepository _missionRepository;
  final ImagePicker _picker = ImagePicker();

  MissionSubmissionViewModel(this._missionRepository) : super(MissionSubmissionState());

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        state = state.copyWith(selectedImage: image, status: SubmissionStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(status: SubmissionStatus.error, errorMessage: '이미지를 가져오는 데 실패했어요. 권한을 확인해주세요.');
    }
  }

  Future<void> submitMission({
    required int dailyMissionId,
    required String content,
  }) async {
    // ✨ isFormValid를 사용하여 버튼이 비활성화되므로, 이중 체크는 선택사항입니다.
    if (!state.isFormValid || state.status == SubmissionStatus.loading) return;

    state = state.copyWith(status: SubmissionStatus.loading, errorMessage: null);
    try {
      final imageFile = state.selectedImage!;
      final imageData = await imageFile.readAsBytes();
      final presignedUrlResponse = await _missionRepository.getPresignedUrl(imageFile.name);
      await _missionRepository.uploadImageToS3(presignedUrlResponse.presignedUrl, imageData);
      await _missionRepository.createSubmission(
        dailyMissionId: dailyMissionId,
        content: content,
        fileKey: presignedUrlResponse.fileKey,
      );
      state = state.copyWith(status: SubmissionStatus.success);
    } catch (e) {
      state = state.copyWith(status: SubmissionStatus.error, errorMessage: '제출에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  void onContentChanged(String content) {
    state = state.copyWith(contentLength: content.length);
  }
}

// Provider
final missionSubmissionViewModelProvider = StateNotifierProvider.autoDispose<
    MissionSubmissionViewModel, MissionSubmissionState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return MissionSubmissionViewModel(missionRepository);
});

