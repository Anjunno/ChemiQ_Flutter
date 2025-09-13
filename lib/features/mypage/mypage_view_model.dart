
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:chemiq/data/repositories/partnership_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/myPage_response.dart';
import '../auth/provider/partner_state_provider.dart';

// 마이페이지의 상태를 정의하는 클래스
class MyPageState {
  final bool isLoading;
  final MyPageResponse? myPageInfo;
  final String? error;
  final bool isImageUploading;
  final String? profileImageError; // ✨ 프로필 이미지 업로드 실패 시 에러 메시지

  MyPageState({
    this.isLoading = true,
    this.myPageInfo,
    this.error,
    this.isImageUploading = false,
    this.profileImageError, // ✨ 생성자에 추가
  });

  MyPageState copyWith({
    bool? isLoading,
    MyPageResponse? myPageInfo,
    String? error,
    bool? isImageUploading,
    String? profileImageError, // ✨ copyWith에 추가
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

// 상태(MyPageState)와 로직을 관리하는 ViewModel
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

  /// 프로필 사진 업데이트 로직
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

      // fileKey: 라는 이름표를 추가합니다.
      await _memberRepository.updateProfileImage(
        fileKey: presignedUrlResponse.fileKey,
      );

      await fetchMyPageInfo();
    } catch (e) {
      state = state.copyWith(profileImageError: '프로필 사진 변경에 실패했어요.');
    } finally {
      state = state.copyWith(isImageUploading: false);
    }
  }

  Future<void> breakUp() async {
    try {
      await _partnershipRepository.deletePartnership();
      _ref.invalidate(partnerStateProvider);
    } catch (e) {
      rethrow;
    }
  }
}

// Provider는 수정사항이 없습니다.
final myPageViewModelProvider =
StateNotifierProvider.autoDispose<MyPageViewModel, MyPageState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final partnershipRepository = ref.watch(partnershipRepositoryProvider);
  return MyPageViewModel(memberRepository, partnershipRepository, ref);
});

