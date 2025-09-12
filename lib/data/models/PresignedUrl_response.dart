// S3 Pre-signed URL 발급 요청 성공 시 서버로부터 받을 응답을 담는 DTO입니다.
class PresignedUrlResponse {
  final String presignedUrl; // S3에 직접 업로드할 때 사용할 URL
  final String fileKey;      // 업로드 완료 후 우리 서버에 알려줄 파일의 고유 키

  PresignedUrlResponse({
    required this.presignedUrl,
    required this.fileKey,
  });

  factory PresignedUrlResponse.fromJson(Map<String, dynamic> json) {
    return PresignedUrlResponse(
      presignedUrl: json['presignedUrl'] as String,
      fileKey: json['fileKey'] as String,
    );
  }
}
