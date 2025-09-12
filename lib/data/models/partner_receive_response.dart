// GET /partnerships/requests/received API의 응답 본문을 나타내는 모델입니다.
class PartnershipReceiveResponse {
  final int partnershipId;
  final String requesterId;
  final String requesterNickname;

  PartnershipReceiveResponse({
    required this.partnershipId,
    required this.requesterId,
    required this.requesterNickname,
  });

  factory PartnershipReceiveResponse.fromJson(Map<String, dynamic> json) {
    return PartnershipReceiveResponse(
      partnershipId: json['partnershipId'] as int,
      requesterId: json['requesterId'] as String,
      requesterNickname: json['requesterNickname'] as String,
    );
  }
}
