class Conversation {
  final String conversationId;
  final String coupleId;
  final String title;
  final String topic;
  final String createdBy;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final int messageCount;
  final DateTime? updatedAt;
  final DateTime? archivedAt;

  Conversation({
    required this.conversationId,
    required this.coupleId,
    required this.title,
    required this.topic,
    required this.createdBy,
    required this.createdAt,
    required this.lastMessageAt,
    required this.isActive,
    required this.messageCount,
    this.updatedAt,
    this.archivedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] ?? '',
      coupleId: json['coupleId'] ?? '',
      title: json['title'] ?? '',
      topic: json['topic'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] ?? DateTime.now().toIso8601String()),
      isActive: json['isActive'] ?? true,
      messageCount: json['messageCount'] ?? 0,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      archivedAt: json['archivedAt'] != null ? DateTime.parse(json['archivedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'coupleId': coupleId,
      'title': title,
      'topic': topic,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'isActive': isActive,
      'messageCount': messageCount,
      'updatedAt': updatedAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? conversationId,
    String? coupleId,
    String? title,
    String? topic,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isActive,
    int? messageCount,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return Conversation(
      conversationId: conversationId ?? this.conversationId,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
