import 'package:chemiq/core/di/service_locator.dart';
import 'package:chemiq/core/dio/dio_client.dart';
import 'package:chemiq/data/models/partnership_partner_response.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/partner_receive_response.dart';
import '../models/partnership_request.dart';
import '../models/partnership_sent_response.dart';

class PartnershipRepository {
  final DioClient _dioClient;
  PartnershipRepository({required DioClient dioClient}) : _dioClient = dioClient;

  /// 현재 연결된 파트너 정보를 조회합니다.
  /// 성공 시 PartnershipPartnerResponse 객체를, 파트너가 없으면(404) null을 반환합니다.
  Future<PartnershipPartnerResponse?> getPartnerInfo() async {
    try {
      final response = await _dioClient.dio.get('/partnerships');
      return PartnershipPartnerResponse.fromJson(response.data);
    } on DioException catch (e) {
      // API 명세에 따라, 파트너가 없으면 404 Not Found 에러가 발생합니다.
      if (e.response?.statusCode == 404) {
        // 파트너가 없는 것은 정상적인 상황이므로, 에러 대신 null을 반환합니다.
        return null;
      }
      // 그 외의 다른 에러(서버 오류 등)는 그대로 던져서 상위에서 처리하도록 합니다.
      rethrow;
    }
  }

  /// 특정 사용자에게 파트너 관계를 요청합니다.
  Future<void> requestPartnership({required String partnerId}) async {
    try {
      // 서버에 보낼 요청 데이터를 생성합니다.
      final requestDto = PartnershipRequest(partnerId: partnerId);
      // '/partnerships/requests' 경로로 POST 요청을 보냅니다.
      await _dioClient.dio.post(
        '/partnerships/requests',
        data: requestDto.toJson(),
      );
    } on DioException catch (e) {
      // API 명세에 따른 에러 상황을 더 친절한 메시지로 변환하여 UI에 전달합니다.
      if (e.response?.statusCode == 404) {
        throw '해당 ID를 가진 사용자를 찾을 수 없어요.';
      }
      if (e.response?.statusCode == 409) {
        throw '이미 파트너이거나 처리 대기 중인 요청이 있어요.';
      }
      if (e.response?.statusCode == 400) {
        throw '자기 자신에게는 파트너 요청을 보낼 수 없어요.';
      }
      // 그 외의 서버 에러
      throw '요청에 실패했어요. 잠시 후 다시 시도해주세요.';
    }
  }

  /// 보낸 파트너 요청 목록을 조회합니다.
  Future<List<PartnershipSentResponse>> getSentRequests() async {
    final response = await _dioClient.dio.get('/partnerships/requests/sent');
    return (response.data as List)
        .map((item) => PartnershipSentResponse.fromJson(item))
        .toList();
  }

  /// 받은 파트너 요청 목록을 조회합니다.
  Future<List<PartnershipReceiveResponse>> getReceivedRequests() async {
    final response = await _dioClient.dio.get('/partnerships/requests/received');
    return (response.data as List)
        .map((item) => PartnershipReceiveResponse.fromJson(item))
        .toList();
  }

  /// 받은 파트너 요청을 수락합니다.
  Future<void> acceptRequest(int partnershipId) async {
    await _dioClient.dio.post('/partnerships/requests/$partnershipId/accept');
  }

  /// 받은 파트너 요청을 거절합니다.
  Future<void> rejectRequest(int partnershipId) async {
    await _dioClient.dio.delete('/partnerships/requests/$partnershipId/reject');
  }

  /// 보낸 파트너 요청을 취소합니다.
  Future<void> cancelRequest(int partnershipId) async {
    await _dioClient.dio.delete('/partnerships/requests/$partnershipId/cancel');
  }

  /// 현재 파트너 관계를 해제합니다.
  Future<void> deletePartnership() async {
    try {
      await _dioClient.dio.delete('/partnerships');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw '해제할 파트너 관계가 존재하지 않아요.';
      }
      throw '관계 해제에 실패했어요. 다시 시도해주세요.';
    }
  }
}

// PartnershipRepository의 인스턴스를 제공하는 Provider
final partnershipRepositoryProvider = Provider<PartnershipRepository>((ref) {
  return PartnershipRepository(dioClient: serviceLocator<DioClient>());
});
