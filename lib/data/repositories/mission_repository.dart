import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/PresignedUrl_response.dart';
import '../models/dailyMission_response.dart';
import '../models/evaluationr_equest.dart';
import '../models/presignedUrl_request.dart';
import '../models/submission_create_request.dart';

class MissionRepository {
  final DioClient _dioClient;

  MissionRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 오늘의 미션 현황을 조회합니다.
  /// 성공 시 DailyMissionResponse 객체를, 미션이 없으면(404) null을 반환합니다.
  Future<DailyMissionResponse?> getTodayMission() async {
    try {
      final response = await _dioClient.dio.get('/timeline/today');
      return DailyMissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      // API 명세에 따라, 할당된 미션이 없으면 404 Not Found 에러가 발생합니다.
      if (e.response?.statusCode == 404) {
        // 미션이 없는 것은 에러가 아닌 정상적인 상황이므로 null을 반환합니다.
        return null;
      }
      // 그 외 다른 에러는 상위 레이어에서 처리하도록 다시 던집니다.
      rethrow;
    }
  }

  /// 1단계: 사진 업로드용 Pre-signed URL 요청
  Future<PresignedUrlResponse> getPresignedUrl(String filename) async {
    final requestDto = PresignedUrlRequest(filename: filename);
    final response = await _dioClient.dio.post(
      '/submissions/presigned-url',
      data: requestDto.toJson(),
    );
    return PresignedUrlResponse.fromJson(response.data);
  }

  /// (외부) S3에 실제 이미지 파일 업로드
  Future<void> uploadImageToS3(String presignedUrl, Uint8List imageData) async {
    // S3 업로드 시에는 우리 서버의 인터셉터가 필요 없으므로, 깨끗한 Dio 인스턴스를 사용합니다.
    final s3Dio = Dio();
    await s3Dio.put(
      presignedUrl,
      data: Stream.fromIterable(imageData.map((e) => [e])), // Uint8List를 Stream으로 변환
      options: Options(
        headers: {
          Headers.contentLengthHeader: imageData.length, // S3 업로드 시 Content-Length는 필수
          'Content-Type': 'image/jpeg', // 이미지 타입에 맞게 설정 (예: image/png)
        },
      ),
    );
  }

  /// 2단계: 미션 제출 최종 보고
  Future<void> createSubmission({
    required int dailyMissionId,
    required String content,
    required String fileKey,
  }) async {
    final requestDto = SubmissionCreateRequest(
      dailyMissionId: dailyMissionId,
      content: content,
      fileKey: fileKey,
    );
    await _dioClient.dio.post(
      '/submissions',
      data: requestDto.toJson(),
    );
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
    } on DioException catch (e) {
      // API 명세에 따른 에러를 사용자 친화적인 메시지로 변환합니다.
      if (e.response?.statusCode == 403) {
        throw '자신의 제출물이거나 평가할 권한이 없어요.';
      }
      if (e.response?.statusCode == 409) {
        throw '이미 평가를 완료한 제출물이에요.';
      }
      if (e.response?.statusCode == 400) {
        throw '점수 범위(0~5) 또는 코멘트 길이를 확인해주세요.';
      }
      throw '평가 제출에 실패했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  ///과거 미션 기록을 페이징하여 조회합니다.
  Future<List<DailyMissionResponse>> getTimeline({
    required int page,
    int size = 10, // 한 번에 10개의 기록을 불러옵니다.
  }) async {
    try {
      final response = await _dioClient.dio.get(
        '/timeline',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      print(response);
      final List<dynamic> content = response.data['content'];
      return content
          .map((item) => DailyMissionResponse.fromJson(item))
          .toList();
    } catch (e) {
      print('타임라인 조회 실패: $e');
      throw '과거 기록을 불러오는 데 실패했어요.';
    }
  }
}

// MissionRepository의 인스턴스를 제공하는 Provider입니다.
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  // get_it을 통해 DioClient를 주입받아 MissionRepository를 생성합니다.
  return MissionRepository(dioClient: serviceLocator<DioClient>());
});
