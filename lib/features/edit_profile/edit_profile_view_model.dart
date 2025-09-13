import 'package:chemiq/data/repositories/member_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 정보 수정 화면의 상태 (닉네임 변경에 집중)
class EditProfileState {
  final bool isNicknameLoading;
  final String? successMessage;
  final String? errorMessage;
  // ✨ 닉네임 유효성 검사 결과 등을 추가할 수 있습니다.
  final bool isNicknameValid;

  EditProfileState({
    this.isNicknameLoading = false,
    this.successMessage,
    this.errorMessage,
    this.isNicknameValid = false,
  });

  EditProfileState copyWith({
    bool? isNicknameLoading,
    String? successMessage,
    String? errorMessage,
    bool? isNicknameValid,
  }) {
    return EditProfileState(
      isNicknameLoading: isNicknameLoading ?? this.isNicknameLoading,
      successMessage: successMessage,
      errorMessage: errorMessage,
      isNicknameValid: isNicknameValid ?? this.isNicknameValid,
    );
  }
}

// ViewModel
class EditProfileViewModel extends StateNotifier<EditProfileState> {
  final MemberRepository _memberRepository;

  EditProfileViewModel(this._memberRepository) : super(EditProfileState());

  /// 닉네임 변경 로직
  Future<bool> changeNickname(String newNickname) async {
    state = state.copyWith(isNicknameLoading: true, successMessage: null, errorMessage: null);
    try {
      await _memberRepository.changeNickname(nickname: newNickname);
      state = state.copyWith(isNicknameLoading: false, successMessage: '닉네임이 성공적으로 변경되었어요.');
      return true; // 성공 여부 반환
    } catch (e) {
      state = state.copyWith(isNicknameLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ✨ 닉네임 유효성을 검사하는 로직 (예시)
  void validateNickname(String nickname) {
    final isValid = nickname.length >= 2 && nickname.length <= 10;
    state = state.copyWith(isNicknameValid: isValid, errorMessage: null);
  }
}

// Provider
final editProfileViewModelProvider =
StateNotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return EditProfileViewModel(memberRepository);
});

