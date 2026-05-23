import 'comment.dart';

enum TaskStatus { todo, inProgress, done }

extension TaskStatusLabel on TaskStatus {
  String get label {
    return switch (this) {
      TaskStatus.todo => 'To do',
      TaskStatus.inProgress => 'In progress',
      TaskStatus.done => 'Done',
    };
  }
}

enum TaskFlag { urgent, blocked, review, client }

extension TaskFlagLabel on TaskFlag {
  String get label {
    return switch (this) {
      TaskFlag.urgent => 'Urgent',
      TaskFlag.blocked => 'Blocked',
      TaskFlag.review => 'Review',
      TaskFlag.client => 'Client',
    };
  }
}

class TaskAttachment {
  const TaskAttachment({
    required this.id,
    required this.name,
    required this.path,
    required this.addedAt,
  });

  final String id;
  final String name;
  final String path;
  final DateTime addedAt;
}

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assigneeId,
    required this.createdBy,
    required this.createdAt,
    required this.comments,
    required this.attachments,
    this.flags = const [],
    this.dueDate,
  });

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final String assigneeId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? dueDate;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;
  final List<TaskFlag> flags;

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    String? assigneeId,
    DateTime? dueDate,
    bool clearDueDate = false,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
    List<TaskFlag>? flags,
  }) {
    return ProjectTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      createdBy: createdBy,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
      flags: flags ?? this.flags,
    );
  }
}
