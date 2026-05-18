import 'task.dart';

enum ProjectPermission { owner, manager, member, guest }

class ProjectMember {
  const ProjectMember({
    required this.userId,
    required this.email,
    required this.permission,
  });

  final String userId;
  final String email;
  final ProjectPermission permission;
}

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.managerId,
    required this.members,
    required this.tasks,
    required this.createdAt,
    this.color = 0xFF45D6B5,
  });

  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String managerId;
  final List<ProjectMember> members;
  final List<ProjectTask> tasks;
  final DateTime createdAt;
  final int color;

  Project copyWith({
    String? name,
    String? description,
    String? managerId,
    List<ProjectMember>? members,
    List<ProjectTask>? tasks,
    int? color,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      managerId: managerId ?? this.managerId,
      members: members ?? this.members,
      tasks: tasks ?? this.tasks,
      createdAt: createdAt,
      color: color ?? this.color,
    );
  }
}
