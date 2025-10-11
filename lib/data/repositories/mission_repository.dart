import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import '../../core/utils/logger.dart';
import '../models/PresignedUrl_response.dart';
import '../models/dailyMission_response.dart';
import '../models/evaluation_detail_dto.dart';
import '../models/evaluation_request.dart';
import '../models/presignedUrl_request.dart';
import '../models/submission_create_request.dart';
import '../models/timeline_item_dto.dart';
import '../models/weekly_status_dto.dart';

class MissionRepository {
  final DioClient _dioClient;

  MissionRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 오늘의 미션 현황을 조회합니다.
  Future<DailyMissionResponse?> getTodayMission() async {
    try {
      final response = await _dioClient.dio.get('/timeline/today');
      logInfo('오늘의 미션 조회 성공');
      return DailyMissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        logDebug('오늘의 미션 없음 (404)');
        return null;
      }
      logError('오늘의 미션 조회 실패: $e');
      rethrow;
    } catch (e) {
      logError('오늘의 미션 조회 중 알 수 없는 에러: $e');
      rethrow;
    }
  }

  /// 1단계: 사진 업로드용 Pre-signed URL 요청
  Future<PresignedUrlResponse> getPresignedUrl(String filename) async {
    try {
      final requestDto = PresignedUrlRequest(filename: filename);
      final response = await _dioClient.dio.post(
        '/submissions/presigned-url',
        data: requestDto.toJson(),
      );
      logInfo('프리사인드 URL 요청 성공: $filename');
      return PresignedUrlResponse.fromJson(response.data);
    } catch (e) {
      logError('프리사인드 URL 요청 실패: $e');
      rethrow;
    }
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

  /// 2단계: 미션 제출 최종 보고
  Future<void> createSubmission({
    required int dailyMissionId,
    required String content,
    required String fileKey,
  }) async {
    try {
      final requestDto = SubmissionCreateRequest(
        dailyMissionId: dailyMissionId,
        content: content,
        fileKey: fileKey,
      );
      await _dioClient.dio.post(
        '/submissions',
        data: requestDto.toJson(),
      );
      logInfo('미션 제출 성공 (dailyMissionId: $dailyMissionId)');
    } catch (e) {
      logError('미션 제출 실패: $e');
      throw '미션 제출에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 파트너의 미션 제출물을 평가합니다.
  Future<void> evaluateSubmission({
    required int submissionId,
    required double score,
    required String comment,
  }) async {
    try {
      final requestDto = EvaluationRequest(score: score, comment: comment);
      await _dioClient.dio.post(
        '/submissions/$submissionId/evaluations',
        data: requestDto.toJson(),
      );
      logInfo('제출물 평가 성공 (submissionId: $submissionId)');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw '자신의 제출물이거나 평가할 권한이 없어요.';
      }
      if (e.response?.statusCode == 409) {
        throw '이미 평가를 완료한 제출물이에요.';
      }
      if (e.response?.statusCode == 400) {
        throw '점수 범위(0~5) 또는 코멘트 길이를 확인해주세요.';
      }
      logError('제출물 평가 실패: $e');
      throw '평가 제출에 실패했어요. 잠시 후 다시 시도해주세요.';
    } catch (e) {
      logError('제출물 평가 중 알 수 없는 에러: $e');
      rethrow;
    }
  }

  /// 과거 미션 기록을 페이징하여 조회합니다.
  Future<List<DailyMissionResponse>> getTimeline({
    required int page,
    int size = 10,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/timeline',
        queryParameters: {'page': page, 'size': size},
      );
      final List<dynamic> content = response.data['content'];
      logInfo('타임라인 조회 성공 (page: $page)');
      return content.map((item) => DailyMissionResponse.fromJson(item)).toList();
    } catch (e) {
      logError('타임라인 조회 실패: $e');
      throw '과거 기록을 불러오는 데 실패했어요.';
    }
  }

  /// 특정 제출물에 대한 파트너의 평가 정보를 조회합니다.
  Future<EvaluationDetailDto?> getEvaluationForSubmission(int submissionId) async {
    try {
      final response = await _dioClient.dio.get('/submissions/$submissionId/evaluation');
      logInfo('평가 정보 조회 성공 (submissionId: $submissionId)');
      return EvaluationDetailDto.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        logDebug('평가 정보 없음 (submissionId: $submissionId)');
        return null;
      }
      logError('평가 정보 조회 실패: $e');
      throw '평가 정보를 불러오는 데 실패했어요.';
    } catch (e) {
      logError('평가 정보 조회 중 알 수 없는 에러: $e');
      rethrow;
    }
  }

  /// 주간 미션 현황 조회
  Future<WeeklyMissionStatusResponse> getWeeklyStatus() async {
    try {
      final response = await _dioClient.dio.get('/missions/weekly-status');
      logInfo('주간 미션 현황 조회 성공');
      return WeeklyMissionStatusResponse.fromJson(response.data);
    } catch (e) {
      logError('주간 미션 현황 조회 실패: $e');
      throw '주간 현황을 불러오는 데 실패했어요.';
    }
  }
}

// MissionRepository의 인스턴스를 제공하는 Provider
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return MissionRepository(dioClient: serviceLocator<DioClient>());
});
