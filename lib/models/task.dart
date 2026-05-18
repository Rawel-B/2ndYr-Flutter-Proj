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

  ProjectTask copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    String? assigneeId,
    DateTime? dueDate,
    List<TaskComment>? comments,
    List<TaskAttachment>? attachments,
  }) {
    return ProjectTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      createdBy: createdBy,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      attachments: attachments ?? this.attachments,
    );
  }
}
