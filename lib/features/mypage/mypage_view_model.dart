import 'dart:typed_data';
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:chemiq/data/repositories/partnership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/myPage_response.dart';
import '../auth/provider/home_screen_data_provider.dart';
import '../auth/provider/partner_state_provider.dart';
import '../home/home_screen_view_model.dart';
import '../mission_status/mission_status_view_model.dart';
import '../timeline/timeline_view_model.dart';

class MyPageState {
  final bool isLoading;
  final MyPageResponse? myPageInfo;
  final String? error;
  final bool isImageUploading;
  final String? profileImageError;

  MyPageState({
    this.isLoading = true,
    this.myPageInfo,
    this.error,
    this.isImageUploading = false,
    this.profileImageError,
  });

  MyPageState copyWith({
    bool? isLoading,
    MyPageResponse? myPageInfo,
    String? error,
    bool? isImageUploading,
    String? profileImageError,
  }) {
    return MyPageState(
      isLoading: isLoading ?? this.isLoading,
      myPageInfo: myPageInfo ?? this.myPageInfo,
      error: error,
      isImageUploading: isImageUploading ?? this.isImageUploading,
      profileImageError: profileImageError,
    );
  }
}

// ViewModel
class MyPageViewModel extends StateNotifier<MyPageState> {
  final MemberRepository _memberRepository;
  final PartnershipRepository _partnershipRepository;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  MyPageViewModel(this._memberRepository, this._partnershipRepository, this._ref)
      : super(MyPageState());

  Future<void> fetchMyPageInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _memberRepository.getMyPageInfo();
      state = state.copyWith(isLoading: false, myPageInfo: info);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfileImage() async {
    state = state.copyWith(isImageUploading: true, profileImageError: null);
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        state = state.copyWith(isImageUploading: false);
        return;
      }
      final imageData = await image.readAsBytes();

      final presignedUrlResponse = await _memberRepository.getProfileImageUploadUrl(image.name);
      await _memberRepository.uploadImageToS3(presignedUrlResponse.presignedUrl, imageData);
      await _memberRepository.updateProfileImage(fileKey: presignedUrlResponse.fileKey);

      await fetchMyPageInfo();
    } catch (e) {
      state = state.copyWith(profileImageError: '프로필 사진 변경에 실패했어요.');
    } finally {
      state = state.copyWith(isImageUploading: false);
    }
  }

  /// 파트너 관계를 해제하고 관련된 데이터 소스를 갱신합니다.
  Future<void> breakUp() async {
    await _partnershipRepository.deletePartnership();

    // 성공 시, 관련된 Provider들을 모두 무효화하여 앱 전체에 상태 변경을 알립니다.
    _ref.invalidate(partnerStateProvider); // 1. 라우터가 반응하도록
    _ref.invalidate(homeSummaryProvider);   // 2. 홈 화면 데이터 갱신
    _ref.invalidate(missionStatusViewModelProvider); // 3. 미션 현황 데이터 갱신
    _ref.invalidate(timelineViewModelProvider);    // 4. 타임라인 데이터 갱신

    // 5. 현재 보고 있는 마이페이지 화면의 데이터를 다시 불러와 즉시 갱신
    await fetchMyPageInfo();
  }
}

// Provider는 수정사항이 없습니다.
final myPageViewModelProvider =
StateNotifierProvider.autoDispose<MyPageViewModel, MyPageState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final partnershipRepository = ref.watch(partnershipRepositoryProvider);
  return MyPageViewModel(memberRepository, partnershipRepository, ref);
});