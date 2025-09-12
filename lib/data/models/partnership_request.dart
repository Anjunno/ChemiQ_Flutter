// 파트너 요청 시 서버에 보낼 파트너의 ID를 담는 DTO입니다.
class PartnershipRequest {
  final String partnerId;

  PartnershipRequest({required this.partnerId});

  // 이 객체를 서버가 이해할 수 있는 JSON 형태로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'partnerId': partnerId,
    };
  }
}
