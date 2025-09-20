import 'package:chemiq/data/models/partnership_info_dto.dart';

import 'AchievementDto.dart';
import 'member_info_dto.dart';

// 마이페이지에 필요한 모든 정보를 담는 DTO입니다.
class MyPageResponse {
  final MemberInfoDto myInfo;
  final MemberInfoDto? partnerInfo;
  final PartnershipInfoDto? partnershipInfo;
  final List<AchievementDto> myAchievements; // ✨ 도전과제 목록 필드 추가

  MyPageResponse({
    required this.myInfo,
    this.partnerInfo,
    this.partnershipInfo,
    required this.myAchievements, // ✨ 생성자에 추가
  });

  factory MyPageResponse.fromJson(Map<String, dynamic> json) {
    // ✨ 서버에서 받은 List<Map>을 List<AchievementDto>로 변환하는 로직
    final achievementsList = json['myAchievements'] as List? ?? [];
    final myAchievements = achievementsList
        .map((item) => AchievementDto.fromJson(item))
        .toList();

    return MyPageResponse(
      myInfo: MemberInfoDto.fromJson(json['myInfo']),
      partnerInfo: json['partnerInfo'] != null
          ? MemberInfoDto.fromJson(json['partnerInfo'])
          : null,
      partnershipInfo: json['partnershipInfo'] != null
          ? PartnershipInfoDto.fromJson(json['partnershipInfo'])
          : null,
      myAchievements: myAchievements, // ✨ 변환된 목록을 할당
    );
  }
}

