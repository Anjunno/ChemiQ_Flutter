import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/mission_repository.dart';

// 미션 제출 과정의 상태를 나타내는 Enum
enum SubmissionStatus {
  idle,       // 초기 상태
  loading,    // 로딩 중 (전체 과정)
  success,    // 성공
  error,      // 실패
}

// 미션 제출 화면의 전체 상태를 관리하는 클래스
class MissionSubmissionState {
  final SubmissionStatus status;
  final XFile? selectedImage; // 사용자가 선택한 이미지 파일
  final String? errorMessage;
  final int contentLength; // ✨ 현재 글자 수를 관리하기 위한 상태 추가

  MissionSubmissionState({
    this.status = SubmissionStatus.idle,
    this.selectedImage,
    this.errorMessage,
    this.contentLength = 0, // ✨ 초기값 0
  });

  MissionSubmissionState copyWith({
    SubmissionStatus? status,
    XFile? selectedImage,
    String? errorMessage,
    int? contentLength, // ✨ copyWith에 추가
  }) {
    return MissionSubmissionState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      errorMessage: errorMessage,
      contentLength: contentLength ?? this.contentLength,
    );
  }
}

// 상태(MissionSubmissionState)와 로직을 관리하는 ViewModel
class MissionSubmissionViewModel extends StateNotifier<MissionSubmissionState> {
  final MissionRepository _missionRepository;
  final ImagePicker _picker = ImagePicker();

  MissionSubmissionViewModel(this._missionRepository) : super(MissionSubmissionState());

  /// 갤러리에서 이미지 선택하기
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85); // 이미지 품질 조절
      if (image != null) {
        state = state.copyWith(selectedImage: image, status: SubmissionStatus.idle);
      }
    } catch (e) {
      state = state.copyWith(status: SubmissionStatus.error, errorMessage: '이미지를 가져오는 데 실패했어요.');
    }
  }

  /// 전체 미션 제출 프로세스 실행
  Future<void> submitMission({
    required int dailyMissionId,
    required String content,
  }) async {
    if (state.selectedImage == null) {
      state = state.copyWith(status: SubmissionStatus.error, errorMessage: '사진을 선택해주세요.');
      return;
    }
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

  // ✨ 글 내용이 변경될 때마다 글자 수를 업데이트하는 메서드
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

