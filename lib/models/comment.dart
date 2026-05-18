class TaskComment {
  const TaskComment({
    required this.id,
    required this.authorId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String message;
  final DateTime createdAt;
}
