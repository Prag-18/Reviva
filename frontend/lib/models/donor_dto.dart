class DonorDto {
  final String id;
  final String name;
  final String? bloodGroup;
  final String? donationType;
  final bool available;
  final double distanceKm;

  const DonorDto({
    required this.id,
    required this.name,
    this.bloodGroup,
    this.donationType,
    required this.available,
    required this.distanceKm,
  });

  factory DonorDto.fromJson(Map<String, dynamic> json) {
    return DonorDto(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Unknown donor',
      bloodGroup: json['blood_group']?.toString(),
      donationType: json['donation_type']?.toString(),
      available: json['available'] == true,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'blood_group': bloodGroup,
      'donation_type': donationType,
      'available': available,
      'distance_km': distanceKm,
    };
  }
}
