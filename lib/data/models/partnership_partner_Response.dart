// GET /partnerships API의 성공 응답(200 OK)을 담을 모델 클래스입니다.

class PartnershipPartnerResponse {
  final String partnerId;
  final String partnerNickname;

  PartnershipPartnerResponse({
    required this.partnerId,
    required this.partnerNickname,
  });

  factory PartnershipPartnerResponse.fromJson(Map<String, dynamic> json) {
    return PartnershipPartnerResponse(
      partnerId: json['partnerId'] as String,
      partnerNickname: json['partnerNickname'] as String,
    );
  }
}
