// 프로필 사진 업로드 완료 후 서버에 보고할 때 보낼 파일 키를 담는 DTO입니다.
class ProfileImageUpdateRequest {
  final String fileKey;

  ProfileImageUpdateRequest({required this.fileKey});

  Map<String, dynamic> toJson() {
    return {
      'fileKey': fileKey,
    };
  }
}
