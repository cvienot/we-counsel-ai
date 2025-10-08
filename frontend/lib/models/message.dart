enum MessageSenderType { user, ai }

enum MessageRecipientType { both, partner, counsellor }

class Message {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String senderName;
  final MessageSenderType senderType;
  final String content;
  final MessageRecipientType recipientType;
  final int timestamp;
  final DateTime createdAt;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime? deletedAt;

  Message({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.recipientType,
    required this.timestamp,
    required this.createdAt,
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderType: _senderTypeFromString(json['senderType']),
      content: json['content'] ?? '',
      recipientType: _recipientTypeFromString(json['recipientType']),
      timestamp: json['timestamp'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isEdited: json['isEdited'] ?? false,
      editedAt: json['editedAt'] != null ? DateTime.parse(json['editedAt']) : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
    );
  }

  static MessageSenderType _senderTypeFromString(String? senderType) {
    switch (senderType) {
      case 'ai':
        return MessageSenderType.ai;
      case 'user':
      default:
        return MessageSenderType.user;
    }
  }

  static MessageRecipientType _recipientTypeFromString(String? recipientType) {
    switch (recipientType) {
      case 'partner':
        return MessageRecipientType.partner;
      case 'counsellor':
        return MessageRecipientType.counsellor;
      case 'both':
      default:
        return MessageRecipientType.both;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType.name,
      'content': content,
      'recipientType': recipientType.name,
      'timestamp': timestamp,
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  bool get isFromAI => senderType == MessageSenderType.ai;
  
  bool get isFromUser => senderType == MessageSenderType.user;

  bool get canEdit => 
      isFromUser && 
      !isDeleted && 
      DateTime.now().difference(createdAt).inMinutes < 15;

  bool get canDelete => isFromUser && !isDeleted;

  Message copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? senderName,
    MessageSenderType? senderType,
    String? content,
    MessageRecipientType? recipientType,
    int? timestamp,
    DateTime? createdAt,
    bool? isEdited,
    DateTime? editedAt,
    bool? isDeleted,
    DateTime? deletedAt,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      recipientType: recipientType ?? this.recipientType,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
