import 'dart:typed_data';

import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/logger.dart';
import '../models/PresignedUrl_response.dart';
import '../models/home_summary_dto.dart';
import '../models/myPage_response.dart';
import '../models/nickname_change_request.dart';
import '../models/password_change_request.dart';
import '../models/presignedUrl_request.dart';
import '../models/profileImage_update_request.dart';

class MemberRepository {
  final DioClient _dioClient;

  MemberRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 마이페이지에 필요한 모든 정보를 서버에서 조회합니다.
  Future<MyPageResponse> getMyPageInfo() async {
    try {
      final response = await _dioClient.dio.get('/members/me/info');
      logInfo('마이페이지 정보 조회 성공');
      return MyPageResponse.fromJson(response.data);
    } catch (e) {
      logError('마이페이지 정보 조회 실패: $e');
      throw '정보를 불러오는 데 실패했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 홈페이지에 필요한 모든 정보를 서버에서 조회합니다.
  Future<HomeSummaryDto> getHomeSummary() async {
    try {
      final response = await _dioClient.dio.get('/home-summary');
      logInfo('홈 요약 정보 조회 성공');
      return HomeSummaryDto.fromJson(response.data);
    } catch (e) {
      logError('홈 요약 정보 조회 실패: $e');
      throw '홈 화면 정보를 불러오는 데 실패했어요.';
    }
  }

  /// 1단계: 프로필 사진 업로드용 Pre-signed URL 요청
  Future<PresignedUrlResponse> getProfileImageUploadUrl(String filename) async {
    final requestDto = PresignedUrlRequest(filename: filename);
    final response = await _dioClient.dio.post(
      '/members/me/profile-image/presigned-url',
      data: requestDto.toJson(),
    );
    logInfo('프리사인드 URL 요청 성공: $filename');
    return PresignedUrlResponse.fromJson(response.data);
  }

  /// (외부) S3에 실제 이미지 파일 업로드
  Future<void> uploadImageToS3(String presignedUrl, Uint8List imageData) async {
    try {
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
      logInfo('S3 이미지 업로드 성공');
    } catch (e) {
      logError('S3 이미지 업로드 실패: $e');
      rethrow;
    }
  }

  /// 2단계: 프로필 사진 업로드 완료 보고
  Future<void> updateProfileImage({required String fileKey}) async {
    try {
      final requestDto = ProfileImageUpdateRequest(fileKey: fileKey);
      await _dioClient.dio.post(
        '/members/me/profile-image',
        data: requestDto.toJson(),
      );
      logInfo('프로필 사진 업데이트 성공: $fileKey');
    } catch (e) {
      logError('프로필 사진 업데이트 실패: $e');
      throw '프로필 사진 업데이트에 실패했어요.';
    }
  }

  /// 닉네임 변경을 요청합니다.
  Future<void> changeNickname({required String nickname}) async {
    try {
      final requestDto = NicknameChangeRequest(nickname: nickname);
      await _dioClient.dio.patch(
        '/members/me/nickname',
        data: requestDto.toJson(),
      );
      logInfo('닉네임 변경 성공: $nickname');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw '닉네임 규칙(2~6자)을 확인해주세요.';
      }
      logError('닉네임 변경 실패: $e');
      throw '닉네임 변경에 실패했어요.';
    } catch (e) {
      logError('닉네임 변경 중 알 수 없는 에러: $e');
      rethrow;
    }
  }

  /// 비밀번호 변경을 요청합니다.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final requestDto = PasswordChangeRequest(
        password: currentPassword,
        newPassword: newPassword,
      );
      await _dioClient.dio.patch(
        '/members/me/password',
        data: requestDto.toJson(),
      );
      logInfo('비밀번호 변경 성공');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final message = e.response?.data['message'] ?? '요청이 잘못되었습니다.';
        if (message.contains('현재 비밀번호')) {
          throw '현재 비밀번호가 일치하지 않아요.';
        }
        throw '새 비밀번호 규칙을 확인해주세요.';
      }
      logError('비밀번호 변경 실패: $e');
      throw '비밀번호 변경에 실패했어요.';
    } catch (e) {
      logError('비밀번호 변경 중 알 수 없는 에러: $e');
      rethrow;
    }
  }
}

// MemberRepository의 인스턴스를 제공하는 Provider입니다.
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(dioClient: serviceLocator<DioClient>());
});
