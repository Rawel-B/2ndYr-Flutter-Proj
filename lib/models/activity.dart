class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.projectId,
    required this.actorId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String actorId;
  final String message;
  final DateTime createdAt;
}
