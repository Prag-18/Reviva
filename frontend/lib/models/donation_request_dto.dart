class DonationRequestDto {
  final String id;
  final String urgency;
  final String status;
  final String organType;
  final String donorId;
  final String seekerId;
  final String? seekerName;
  final String? donorName;
  final DateTime? createdAt;

  const DonationRequestDto({
    required this.id,
    required this.urgency,
    required this.status,
    required this.organType,
    required this.donorId,
    required this.seekerId,
    this.seekerName,
    this.donorName,
    this.createdAt,
  });

  factory DonationRequestDto.fromJson(Map<String, dynamic> json) {
    return DonationRequestDto(
      id: json['id'].toString(),
      urgency: json['urgency']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      organType: json['organ_type']?.toString() ?? '',
      donorId: json['donor_id'].toString(),
      seekerId: json['seeker_id'].toString(),
      seekerName: json['seeker_name']?.toString(),
      donorName: json['donor_name']?.toString(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'urgency': urgency,
      'status': status,
      'organ_type': organType,
      'donor_id': donorId,
      'seeker_id': seekerId,
      'seeker_name': seekerName,
      'donor_name': donorName,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
