import 'package:chemiq/data/models/member_info_dto.dart';
import 'package:chemiq/data/models/partnership_info_dto.dart';

// GET /members/me/info API의 전체 응답을 담는 최종 모델입니다.
class MyPageResponse {
  final MemberInfoDto myInfo;
  final MemberInfoDto? partnerInfo; // 파트너가 없으면 null일 수 있습니다.
  final PartnershipInfoDto? partnershipInfo; // 파트너가 없으면 null일 수 있습니다.

  MyPageResponse({
    required this.myInfo,
    this.partnerInfo,
    this.partnershipInfo,
  });

  factory MyPageResponse.fromJson(Map<String, dynamic> json) {
    return MyPageResponse(
      myInfo: MemberInfoDto.fromJson(json['myInfo']),
      partnerInfo: json['partnerInfo'] != null
          ? MemberInfoDto.fromJson(json['partnerInfo'])
          : null,
      partnershipInfo: json['partnershipInfo'] != null
          ? PartnershipInfoDto.fromJson(json['partnershipInfo'])
          : null,
    );
  }
}
