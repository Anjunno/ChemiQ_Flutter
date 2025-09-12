import 'dart:typed_data';

import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/PresignedUrl_response.dart';
import '../models/myPage_response.dart';
import '../models/presignedUrl_request.dart';
import '../models/profileImage_update_request.dart';

class MemberRepository {
  final DioClient _dioClient;

  MemberRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 마이페이지에 필요한 모든 정보를 서버에서 조회합니다.
  Future<MyPageResponse> getMyPageInfo() async {
    try {
      final response = await _dioClient.dio.get('/members/me/info');
      return MyPageResponse.fromJson(response.data);
    } catch (e) {
      print('마이페이지 정보 조회 실패: $e');
      throw '정보를 불러오는 데 실패했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 1단계: 프로필 사진 업로드용 Pre-signed URL 요청
  Future<PresignedUrlResponse> getProfileImageUploadUrl(String filename) async {
    final requestDto = PresignedUrlRequest(filename: filename);
    final response = await _dioClient.dio.post(
      '/members/me/profile-image/presigned-url',
      data: requestDto.toJson(),
    );
    return PresignedUrlResponse.fromJson(response.data);
  }

  /// (외부) S3에 실제 이미지 파일 업로드
  Future<void> uploadImageToS3(String presignedUrl, Uint8List imageData) async {
    final s3Dio = Dio();
    await s3Dio.put(
      presignedUrl,
      data: Stream.fromIterable(imageData.map((e) => [e])),
      options: Options(
        headers: {
          Headers.contentLengthHeader: imageData.length,
          'Content-Type': 'image/jpeg',
        },
      ),
    );
  }

  /// 2단계: 프로필 사진 업로드 완료 보고
  Future<void> updateProfileImage({required String fileKey}) async {
    final requestDto = ProfileImageUpdateRequest(fileKey: fileKey);
    await _dioClient.dio.post(
      '/members/me/profile-image',
      data: requestDto.toJson(),
    );
  }

// TODO: 여기에 닉네임 변경, 비밀번호 변경, 프로필 사진 업로드 등의 메서드를 추가합니다.

}

// MemberRepository의 인스턴스를 제공하는 Provider입니다.
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(dioClient: serviceLocator<DioClient>());
});
