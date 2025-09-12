// GET /partnerships/requests/sent API의 응답 본문을 나타내는 모델입니다.
class PartnershipSentResponse {
  final int partnershipId;
  final String addresseeId;
  final String addresseeNickname;
  final String status; // PENDING, ACCEPTED, REJECTED, CANCELED

  PartnershipSentResponse({
    required this.partnershipId,
    required this.addresseeId,
    required this.addresseeNickname,
    required this.status,
  });

  factory PartnershipSentResponse.fromJson(Map<String, dynamic> json) {
    return PartnershipSentResponse(
      partnershipId: json['partnershipId'] as int,
      addresseeId: json['addresseeId'] as String,
      addresseeNickname: json['addresseeNickname'] as String,
      status: json['status'] as String,
    );
  }
}
