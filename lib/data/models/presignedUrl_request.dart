// S3 Pre-signed URL 발급을 요청할 때 서버에 보낼 파일 이름을 담는 DTO입니다.
class PresignedUrlRequest {
  final String filename;

  PresignedUrlRequest({required this.filename});

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
    };
  }
}
