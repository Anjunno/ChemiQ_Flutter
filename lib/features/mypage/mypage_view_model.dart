
import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/myPage_response.dart';
import '../../data/repositories/partnership_repository.dart';
import '../auth/provider/partner_state_provider.dart';

// 마이페이지의 상태
class MyPageState {
  final bool isLoading;
  final bool isUploadingImage; // 프로필 사진 업로드 중인지 여부
  final MyPageResponse? myPageInfo;
  final String? error;

  MyPageState({
    this.isLoading = true,
    this.isUploadingImage = false,
    this.myPageInfo,
    this.error,
  });

  MyPageState copyWith({
    bool? isLoading,
    bool? isUploadingImage,
    MyPageResponse? myPageInfo,
    String? error,
  }) {
    return MyPageState(
      isLoading: isLoading ?? this.isLoading,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      myPageInfo: myPageInfo ?? this.myPageInfo,
      error: error,
    );
  }
}

// ViewModel
class MyPageViewModel extends StateNotifier<MyPageState> {
  final MemberRepository _memberRepository;
  final ImagePicker _picker = ImagePicker();
  final PartnershipRepository _partnershipRepository; // PartnershipRepository 추가
  final Ref _ref; // 다른 Provider를 제어하기 위한 Ref 추가


  // 생성자에서 PartnershipRepository와 Ref를 주입받도록 수정
  MyPageViewModel(this._memberRepository, this._partnershipRepository, this._ref)
      : super(MyPageState());

  /// 마이페이지 정보 불러오기 (기존 코드)
  Future<void> fetchMyPageInfo() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _memberRepository.getMyPageInfo();
      state = state.copyWith(isLoading: false, myPageInfo: info);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 프로필 사진 변경 프로세스
  Future<void> changeProfileImage() async {
    try {
      // 1. 갤러리에서 이미지 선택
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return; // 사용자가 선택을 취소한 경우

      state = state.copyWith(isUploadingImage: true, error: null);
      final imageData = await image.readAsBytes();

      // 2. Pre-signed URL 요청
      final presignedUrlResponse = await _memberRepository.getProfileImageUploadUrl(image.name);

      print(presignedUrlResponse.presignedUrl);
      print(presignedUrlResponse.fileKey);

      // 3. S3에 이미지 업로드
      await _memberRepository.uploadImageToS3(presignedUrlResponse.presignedUrl, imageData);

      // 4. 서버에 업로드 완료 보고
      await _memberRepository.updateProfileImage(fileKey: presignedUrlResponse.fileKey);

      // 5. 성공 시, 마이페이지 정보를 새로고침하여 변경된 사진을 반영
      await fetchMyPageInfo();
    } catch (e) {
      state = state.copyWith(error: '프로필 사진 변경에 실패했어요.');
    } finally {
      // 성공/실패와 관계없이 업로드 상태는 항상 false로 마무리
      state = state.copyWith(isUploadingImage: false);
    }
  }
  /// 파트너 관계를 해제합니다.
  Future<void> breakUp() async {
    try {
      await _partnershipRepository.deletePartnership();
      // ★★★ 중요: 전역 파트너 상태를 무효화하여 갱신합니다.
      // 이 코드로 인해 GoRouter가 변경을 감지하고 파트너 연결 화면으로 리다이렉트합니다.
      _ref.invalidate(partnerStateProvider);
    } catch (e) {
      // 에러가 발생하면 UI에서 스낵바 등으로 표시할 수 있도록 다시 던집니다.
      rethrow;
    }
  }

}

// Provider
final myPageViewModelProvider =
StateNotifierProvider.autoDispose<MyPageViewModel, MyPageState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final partnershipRepository = ref.watch(partnershipRepositoryProvider);
  return MyPageViewModel(memberRepository, partnershipRepository, ref);
});
