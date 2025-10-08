enum InvitationStatus { pending, accepted, declined, expired }

class Invitation {
  final String invitationId;
  final String inviterId;
  final String inviterName;
  final String email;
  final String message;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? acceptedAt;

  Invitation({
    required this.invitationId,
    required this.inviterId,
    required this.inviterName,
    required this.email,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      invitationId: json['invitationId'] ?? '',
      inviterId: json['inviterId'] ?? '',
      inviterName: json['inviterName'] ?? '',
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      expiresAt: DateTime.parse(json['expiresAt'] ?? DateTime.now().add(Duration(days: 7)).toIso8601String()),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
    );
  }

  static InvitationStatus _statusFromString(String? status) {
    switch (status) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'declined':
        return InvitationStatus.declined;
      case 'expired':
        return InvitationStatus.expired;
      case 'pending':
      default:
        return InvitationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'invitationId': invitationId,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'email': email,
      'message': message,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isPending => status == InvitationStatus.pending && !isExpired;
  
  bool get isAccepted => status == InvitationStatus.accepted;

  Invitation copyWith({
    String? invitationId,
    String? inviterId,
    String? inviterName,
    String? email,
    String? message,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? acceptedAt,
  }) {
    return Invitation(
      invitationId: invitationId ?? this.invitationId,
      inviterId: inviterId ?? this.inviterId,
      inviterName: inviterName ?? this.inviterName,
      email: email ?? this.email,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
