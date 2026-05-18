import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/comment.dart';
import '../models/project.dart';
import '../models/task.dart';

class DemoRepository {
  DemoRepository({required this.firebaseReady}) {
    _seed();
  }

  final bool firebaseReady;
  final _uuid = const Uuid();
  final List<AppUser> _users = [];
  final List<Project> _projects = [];
  final List<ActivityItem> _activity = [];
  final List<AppNotification> _notifications = [];

  List<AppUser> get users => List.unmodifiable(_users);
  List<Project> get projects => List.unmodifiable(_projects);
  List<ActivityItem> activityFor(String projectId) =>
      _activity.where((item) => item.projectId == projectId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<AppUser> signIn(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = _users.firstWhere(
      (user) => user.email == normalized,
      orElse: () => _createUser(normalized),
    );
    _notify('Welcome back', '${user.name} signed in successfully.');
    return user;
  }

  Future<AppUser> signUp(String name, String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final user = AppUser(
      id: _uuid.v4(),
      name: name.trim().isEmpty ? normalized.split('@').first : name.trim(),
      email: normalized,
      role: _users.isEmpty ? UserRole.admin : UserRole.user,
    );
    _users.add(user);
    _notify('Account created', '${user.name} joined the workspace.');
    return user;
  }

  Project createProject({
    required AppUser owner,
    required String name,
    required String description,
  }) {
    final project = Project(
      id: _uuid.v4(),
      name: name.trim(),
      description: description.trim(),
      ownerId: owner.id,
      managerId: owner.id,
      members: [
        ProjectMember(
          userId: owner.id,
          email: owner.email,
          permission: ProjectPermission.owner,
        ),
      ],
      tasks: const [],
      createdAt: DateTime.now(),
      color: _colorForIndex(_projects.length),
    );
    _projects.add(project);
    _log(project.id, owner.id, 'created project "${project.name}"');
    _notify('Project created', project.name);
    return project;
  }

  void inviteMember(Project project, String email, AppUser actor) {
    final user = _users.firstWhere(
      (user) => user.email == email.trim().toLowerCase(),
      orElse: () => _createUser(email.trim().toLowerCase()),
    );
    final members = [...project.members];
    if (!members.any((member) => member.userId == user.id)) {
      members.add(
        ProjectMember(
          userId: user.id,
          email: user.email,
          permission: ProjectPermission.member,
        ),
      );
      _replaceProject(project.copyWith(members: members));
      _log(project.id, actor.id, 'invited ${user.email}');
      _notify('Member invited', '${user.email} was added to ${project.name}.');
    }
  }

  void setManager(Project project, String userId, AppUser actor) {
    _replaceProject(project.copyWith(managerId: userId));
    final manager = _users.firstWhere((user) => user.id == userId);
    _log(project.id, actor.id, 'made ${manager.name} project manager');
  }

  ProjectTask createTask({
    required Project project,
    required AppUser actor,
    required String title,
    required String description,
    required TaskStatus status,
    required String assigneeId,
  }) {
    final task = ProjectTask(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      status: status,
      assigneeId: assigneeId,
      createdBy: actor.id,
      createdAt: DateTime.now(),
      comments: const [],
      attachments: const [],
    );
    _replaceProject(project.copyWith(tasks: [...project.tasks, task]));
    _log(project.id, actor.id, 'created task "${task.title}"');
    return task;
  }

  void updateTask(Project project, ProjectTask task) {
    final tasks = project.tasks
        .map((item) => item.id == task.id ? task : item)
        .toList(growable: false);
    _replaceProject(project.copyWith(tasks: tasks));
  }

  void moveTask(Project project, ProjectTask task, TaskStatus status, AppUser actor) {
    updateTask(project, task.copyWith(status: status));
    _log(project.id, actor.id, 'moved "${task.title}" to ${status.label}');
  }

  void addComment(Project project, ProjectTask task, AppUser actor, String message) {
    final comment = TaskComment(
      id: _uuid.v4(),
      authorId: actor.id,
      message: message.trim(),
      createdAt: DateTime.now(),
    );
    updateTask(project, task.copyWith(comments: [...task.comments, comment]));
    _log(project.id, actor.id, 'commented on "${task.title}"');
  }

  void addAttachment(Project project, ProjectTask task, AppUser actor, String name, String path) {
    final attachment = TaskAttachment(
      id: _uuid.v4(),
      name: name,
      path: path,
      addedAt: DateTime.now(),
    );
    updateTask(project, task.copyWith(attachments: [...task.attachments, attachment]));
    _log(project.id, actor.id, 'attached $name to "${task.title}"');
  }

  void markNotificationsRead() {
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(read: true);
    }
  }

  Project? projectById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  AppUser? userById(String id) {
    for (final user in _users) {
      if (user.id == id) return user;
    }
    return null;
  }

  AppUser _createUser(String email) {
    final user = AppUser(
      id: _uuid.v4(),
      name: email.split('@').first.replaceAll('.', ' '),
      email: email,
      role: UserRole.user,
    );
    _users.add(user);
    return user;
  }

  void _replaceProject(Project project) {
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
  }

  void _log(String projectId, String actorId, String message) {
    _activity.add(
      ActivityItem(
        id: _uuid.v4(),
        projectId: projectId,
        actorId: actorId,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _notify(String title, String body) {
    _notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }

  int _colorForIndex(int index) {
    const colors = [0xFF45D6B5, 0xFFFFC857, 0xFF8AB4FF, 0xFFFF6B8B];
    return colors[index % colors.length];
  }

  void _seed() {
    final admin = AppUser(
      id: _uuid.v4(),
      name: 'Rayan Admin',
      email: 'admin@fluttertrello.dev',
      role: UserRole.admin,
    );
    final dev = AppUser(
      id: _uuid.v4(),
      name: 'Maya Chen',
      email: 'maya@fluttertrello.dev',
      role: UserRole.user,
    );
    _users.addAll([admin, dev]);

    final project = Project(
      id: _uuid.v4(),
      name: 'Mobile Launch Board',
      description: 'Plan, build, and ship the FlutterTrello MVP.',
      ownerId: admin.id,
      managerId: admin.id,
      members: [
        ProjectMember(userId: admin.id, email: admin.email, permission: ProjectPermission.owner),
        ProjectMember(userId: dev.id, email: dev.email, permission: ProjectPermission.member),
      ],
      tasks: [
        ProjectTask(
          id: _uuid.v4(),
          title: 'Design Kanban dashboard',
          description: 'Create a dark, compact board interface inspired by Trello and Notion.',
          status: TaskStatus.todo,
          assigneeId: admin.id,
          createdBy: admin.id,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          comments: const [],
          attachments: const [],
        ),
        ProjectTask(
          id: _uuid.v4(),
          title: 'Connect Firebase services',
          description: 'Prepare auth and Firestore boundaries for real-time collaboration.',
          status: TaskStatus.inProgress,
          assigneeId: dev.id,
          createdBy: admin.id,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          comments: const [],
          attachments: const [],
        ),
        ProjectTask(
          id: _uuid.v4(),
          title: 'Write project brief',
          description: 'Document roles, permissions, tasks, activity, and deployment options.',
          status: TaskStatus.done,
          assigneeId: admin.id,
          createdBy: admin.id,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          comments: const [],
          attachments: const [],
        ),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );
    _projects.add(project);
    _log(project.id, admin.id, 'created the launch board');
  }
}
