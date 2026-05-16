import 'package:manus/domain/entities/conversation.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    super.isPinned,
    super.isArchived,
    super.lastMessagePreview,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      isPinned: json['isPinned'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      lastMessagePreview: json['lastMessagePreview'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'lastMessagePreview': lastMessagePreview,
  };

  factory ConversationModel.fromEntity(Conversation c) => ConversationModel(
    id: c.id,
    title: c.title,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    isPinned: c.isPinned,
    isArchived: c.isArchived,
    lastMessagePreview: c.lastMessagePreview,
  );
}
