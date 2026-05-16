import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isArchived;
  final String? lastMessagePreview;

  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isArchived = false,
    this.lastMessagePreview,
  });

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isArchived,
    String? lastMessagePreview,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    createdAt,
    updatedAt,
    isPinned,
    isArchived,
    lastMessagePreview,
  ];
}
