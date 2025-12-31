class UserModel {
  final int id;
  final String role;
  final String phone;
  final String firstName;
  final String lastName;
  final String? level;
  final String? refCode;
  final int? refCount;
  final String? profilePhoto;
  final String? rating;
  final int? ratingCount;

  UserModel({
    required this.id,
    required this.role,
    required this.phone,
    required this.firstName,
    required this.lastName,
    this.level,
    this.refCode,
    this.refCount,
    this.profilePhoto,
    this.rating,
    this.ratingCount,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      role: json['role'] as String,
      phone: json['phone'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      level: json['level'] as String?,
      refCode: json['ref_code'] as String?,
      refCount: json['ref_count'] as int?,
      profilePhoto: json['profile_photo'] as String?,
      rating: json['rating'] as String?,
      ratingCount: json['rating_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'level': level,
      'ref_code': refCode,
      'ref_count': refCount,
      'profile_photo': profilePhoto,
      'rating': rating,
      'rating_count': ratingCount,
    };
  }
}
