import 'dart:typed_data';
import 'package:chemiq/data/repositories/mission_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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

  MissionSubmissionState({
    this.status = SubmissionStatus.idle,
    this.selectedImage,
    this.errorMessage,
  });

  MissionSubmissionState copyWith({
    SubmissionStatus? status,
    XFile? selectedImage,
    String? errorMessage,
  }) {
    return MissionSubmissionState(
      status: status ?? this.status,
      selectedImage: selectedImage ?? this.selectedImage,
      errorMessage: errorMessage,
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
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
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

      // 1단계: Pre-signed URL 요청
      print('1단계: Pre-signed URL 요청 중...');
      final presignedUrlResponse = await _missionRepository.getPresignedUrl(imageFile.name);

      // (외부) S3에 이미지 업로드
      print('S3에 이미지 업로드 중...');
      await _missionRepository.uploadImageToS3(presignedUrlResponse.presignedUrl, imageData);

      // 2단계: 최종 제출 보고
      print('2단계: 최종 제출 보고 중...');
      await _missionRepository.createSubmission(
        dailyMissionId: dailyMissionId,
        content: content,
        fileKey: presignedUrlResponse.fileKey,
      );

      print('미션 제출 성공!');
      state = state.copyWith(status: SubmissionStatus.success);
    } catch (e) {
      print('미션 제출 실패: $e');
      state = state.copyWith(status: SubmissionStatus.error, errorMessage: '제출에 실패했습니다. 잠시 후 다시 시도해주세요.');
    }
  }
}

// ViewModel의 인스턴스를 UI에 제공하는 Provider
final missionSubmissionViewModelProvider = StateNotifierProvider.autoDispose<
    MissionSubmissionViewModel, MissionSubmissionState>((ref) {
  final missionRepository = ref.watch(missionRepositoryProvider);
  return MissionSubmissionViewModel(missionRepository);
});
