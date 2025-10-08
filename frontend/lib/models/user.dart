class User {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String? partnerId;
  final String? coupleId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final User? partner;

  User({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.partnerId,
    this.coupleId,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.partner,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      partnerId: json['partnerId'],
      coupleId: json['coupleId'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      partner: json['partner'] != null ? User.fromJson(json['partner']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'partnerId': partnerId,
      'coupleId': coupleId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'partner': partner?.toJson(),
    };
  }

  String get fullName => '$firstName $lastName';

  bool get hasPartner => partnerId != null && partnerId!.isNotEmpty;
  
  User copyWith({
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? partnerId,
    String? coupleId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? partner,
  }) {
    return User(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      partnerId: partnerId ?? this.partnerId,
      coupleId: coupleId ?? this.coupleId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partner: partner ?? this.partner,
    );
  }
}
