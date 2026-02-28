class UserDto {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? bloodGroup;
  final bool available;
  final String? phone;

  const UserDto({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.bloodGroup,
    required this.available,
    this.phone,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      bloodGroup: json['blood_group']?.toString(),
      available: json['available'] == true,
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'blood_group': bloodGroup,
      'available': available,
      'phone': phone,
    };
  }
}
