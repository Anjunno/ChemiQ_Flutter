import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 정보 수정 화면의 상태 (로딩, 성공/실패 메시지)
class EditProfileState {
  final bool isNicknameLoading;
  final bool isPasswordLoading;
  final String? successMessage;
  final String? errorMessage;

  EditProfileState({
    this.isNicknameLoading = false,
    this.isPasswordLoading = false,
    this.successMessage,
    this.errorMessage,
  });

  EditProfileState copyWith({
    bool? isNicknameLoading,
    bool? isPasswordLoading,
    String? successMessage,
    String? errorMessage,
  }) {
    return EditProfileState(
      isNicknameLoading: isNicknameLoading ?? this.isNicknameLoading,
      isPasswordLoading: isPasswordLoading ?? this.isPasswordLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
    );
  }
}

// 상태(EditProfileState)와 로직을 관리하는 ViewModel
class EditProfileViewModel extends StateNotifier<EditProfileState> {
  final MemberRepository _memberRepository;

  EditProfileViewModel(this._memberRepository) : super(EditProfileState());

  /// 닉네임 변경 로직
  Future<void> changeNickname(String newNickname) async {
    state = state.copyWith(isNicknameLoading: true, successMessage: null, errorMessage: null);
    try {
      await _memberRepository.changeNickname(nickname: newNickname);
      state = state.copyWith(isNicknameLoading: false, successMessage: '닉네임이 성공적으로 변경되었어요.');
    } catch (e) {
      state = state.copyWith(isNicknameLoading: false, errorMessage: e.toString());
    }
  }

  /// 비밀번호 변경 로직
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      state = state.copyWith(errorMessage: '새 비밀번호가 일치하지 않아요.');
      return;
    }
    state = state.copyWith(isPasswordLoading: true, successMessage: null, errorMessage: null);
    try {
      await _memberRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isPasswordLoading: false, successMessage: '비밀번호가 성공적으로 변경되었어요.');
    } catch (e) {
      state = state.copyWith(isPasswordLoading: false, errorMessage: e.toString());
    }
  }
}

// ViewModel의 인스턴스를 UI에 제공하는 Provider
final editProfileViewModelProvider =
StateNotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return EditProfileViewModel(memberRepository);
});
