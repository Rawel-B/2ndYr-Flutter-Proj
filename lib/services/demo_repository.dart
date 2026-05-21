import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/activity.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/comment.dart';
import '../models/project.dart';
import '../models/task.dart';

class DemoRepository {
  static const adminEmail = 'admin@fluttertrello.dev';
  static const adminName = 'Admin';

  DemoRepository({required this.firebaseReady}) {
    _seed();
  }

  final bool firebaseReady;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;
  final _uuid = const Uuid();
  final List<AppUser> _users = [];
  final List<Project> _projects = [];
  final List<ActivityItem> _activity = [];
  final List<AppNotification> _notifications = [];

  List<AppUser> get users => List.unmodifiable(_users);
  List<Project> get projects => List.unmodifiable(_projects);
  List<Project> projectsFor(AppUser? user) {
    if (user == null) return const [];
    if (user.isAdmin) return projects;
    return _projects
        .where(
          (project) => project.members.any((member) => member.userId == user.id),
        )
        .toList(growable: false);
  }

  List<ActivityItem> activityFor(String projectId) =>
      _activity.where((item) => item.projectId == projectId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  Future<void> loadFirebaseData() async {
    if (!firebaseReady) return;

    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final projectsSnapshot = await _firestore.collection('projects').get();
      final notificationsSnapshot = await _firestore.collection('notifications').get();
      final activitySnapshot = await _firestore.collectionGroup('activity').get();

      if (usersSnapshot.docs.isEmpty && projectsSnapshot.docs.isEmpty) {
        _users.clear();
        _projects.clear();
        _activity.clear();
        _notifications.clear();
        return;
      }

      _users
        ..clear()
        ..addAll(usersSnapshot.docs.map((doc) => _userFromMap(doc.id, doc.data())));
      _projects
        ..clear()
        ..addAll(projectsSnapshot.docs.map((doc) => _projectFromMap(doc.id, doc.data())));
      _notifications
        ..clear()
        ..addAll(
          notificationsSnapshot.docs.map((doc) => _notificationFromMap(doc.id, doc.data())),
        );
      _activity
        ..clear()
        ..addAll(activitySnapshot.docs.map((doc) => _activityFromMap(doc.id, doc.data())));
    } on Object catch (error) {
      debugPrint('Could not load Firestore data. Using local data: $error');
    }
  }

  Future<AppUser> signIn(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (firebaseReady) {
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        final authUser = credential.user;
        if (authUser == null) {
          throw StateError('Firebase sign in did not return a user.');
        }
        final user = await _ensureUserProfile(
          id: authUser.uid,
          email: normalized,
          name: authUser.displayName,
        );
        _notify('Welcome back', '${user.name} signed in successfully.');
        return user;
      } on firebase_auth.FirebaseAuthException catch (error) {
        if (!_isFirebaseAuthSetupError(error)) rethrow;
        debugPrint('Firebase Auth setup issue. Falling back to local sign in: ${error.code}');
      }
    }

    return _signInLocal(normalized);
  }

  Future<AppUser> signUp(String name, String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (firebaseReady) {
      final displayName = _displayNameFor(normalized, name);
      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: normalized,
          password: password,
        );
        final authUser = credential.user;
        if (authUser == null) {
          throw StateError('Firebase sign up did not return a user.');
        }
        await authUser.updateDisplayName(displayName);
        final user = AppUser(
          id: authUser.uid,
          name: displayName,
          email: normalized,
          role: _roleForEmail(normalized),
        );
        _upsertUser(user);
        _saveUser(user);
        _notify('Account created', '${user.name} joined the workspace.');
        return user;
      } on firebase_auth.FirebaseAuthException catch (error) {
        if (!_isFirebaseAuthSetupError(error)) rethrow;
        debugPrint('Firebase Auth setup issue. Falling back to local sign up: ${error.code}');
      }
    }

    return _signUpLocal(name, normalized);
  }

  AppUser _signInLocal(String normalizedEmail) {
    final user = _users.firstWhere(
      (user) => user.email == normalizedEmail,
      orElse: () => _createUser(normalizedEmail),
    );
    _notify('Welcome back', '${user.name} signed in successfully.');
    return user;
  }

  AppUser _signUpLocal(String name, String normalizedEmail) {
    if (_userByEmail(normalizedEmail) != null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'This account already exists.',
      );
    }

    final user = AppUser(
      id: _uuid.v4(),
      name: _displayNameFor(normalizedEmail, name),
      email: normalizedEmail,
      role: _roleForEmail(normalizedEmail),
    );
    _users.add(user);
    _saveUser(user);
    _notify('Account created', '${user.name} joined the workspace.');
    return user;
  }

  bool _isFirebaseAuthSetupError(firebase_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'operation-not-allowed' ||
      'admin-restricted-operation' ||
      'configuration-not-found' =>
        true,
      _ => false,
    };
  }

  Future<AppUser?> restoreSession() async {
    if (!firebaseReady) {
      return _users.isEmpty ? null : _users.first;
    }

    final authUser = _auth.currentUser;
    if (authUser == null || authUser.email == null) return null;
    return _ensureUserProfile(
      id: authUser.uid,
      email: authUser.email!,
      name: authUser.displayName,
    );
  }

  Future<void> signOut() async {
    if (firebaseReady) {
      await _auth.signOut();
    }
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
    _saveProject(project);
    _log(project.id, owner.id, 'created project "${project.name}"');
    _notify('Project created', project.name);
    return project;
  }

  void inviteMember(Project project, String email, AppUser actor) {
    _requireProjectManager(project, actor);
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
    _requireProjectOwner(project, actor);
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
    _requireProjectMember(project, actor);
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
    _requireProjectMember(project, actor);
    updateTask(project, task.copyWith(status: status));
    _log(project.id, actor.id, 'moved "${task.title}" to ${status.label}');
  }

  void addComment(Project project, ProjectTask task, AppUser actor, String message) {
    _requireProjectMember(project, actor);
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
    _requireProjectMember(project, actor);
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
      _saveNotification(_notifications[index]);
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
      name: _displayNameFor(email, ''),
      email: email,
      role: _roleForEmail(email),
    );
    _users.add(user);
    _saveUser(user);
    return user;
  }

  Future<AppUser> _ensureUserProfile({
    required String id,
    required String email,
    String? name,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = userById(id) ?? _userByEmail(normalized);
    if (existing != null) {
      if (existing.id == id) return existing;
      final updated = AppUser(
        id: id,
        name: existing.name,
        email: existing.email,
        role: existing.role,
      );
      _upsertUser(updated);
      _saveUser(updated);
      return updated;
    }

    final user = AppUser(
      id: id,
      name: _displayNameFor(normalized, name ?? ''),
      email: normalized,
      role: _roleForEmail(normalized),
    );
    _upsertUser(user);
    _saveUser(user);
    return user;
  }

  AppUser? _userByEmail(String email) {
    for (final user in _users) {
      if (user.email == email) return user;
    }
    return null;
  }

  void _upsertUser(AppUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      _users.add(user);
    } else {
      _users[index] = user;
    }
  }

  String _displayNameFor(String email, String name) {
    if (email == adminEmail) return adminName;
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return email.split('@').first.replaceAll('.', ' ');
  }

  UserRole _roleForEmail(String email) {
    return email == adminEmail ? UserRole.admin : UserRole.user;
  }

  void _requireProjectOwner(Project project, AppUser actor) {
    if (actor.isAdmin || project.ownerId == actor.id) return;
    throw StateError('Only admins and project owners can change project leadership.');
  }

  void _requireProjectManager(Project project, AppUser actor) {
    if (actor.isAdmin || project.ownerId == actor.id || project.managerId == actor.id) {
      return;
    }
    throw StateError('Only admins, owners, and managers can invite project members.');
  }

  void _requireProjectMember(Project project, AppUser actor) {
    if (actor.isAdmin || project.members.any((member) => member.userId == actor.id)) {
      return;
    }
    throw StateError('You are not a member of this project.');
  }

  void _replaceProject(Project project) {
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      _saveProject(project);
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
    _saveActivity(_activity.last);
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
    _saveNotification(_notifications.first);
  }

  void _saveUser(AppUser user) {
    if (!firebaseReady) return;
    unawaited(_runFirestoreWrite(() {
      return _firestore.collection('users').doc(user.id).set(_userToMap(user));
    }));
  }

  void _saveProject(Project project) {
    if (!firebaseReady) return;
    unawaited(_runFirestoreWrite(() {
      return _firestore.collection('projects').doc(project.id).set(_projectToMap(project));
    }));
  }

  void _saveActivity(ActivityItem item) {
    if (!firebaseReady) return;
    unawaited(_runFirestoreWrite(() {
      return _firestore
          .collection('projects')
          .doc(item.projectId)
          .collection('activity')
          .doc(item.id)
          .set(_activityToMap(item));
    }));
  }

  void _saveNotification(AppNotification notification) {
    if (!firebaseReady) return;
    unawaited(_runFirestoreWrite(() {
      return _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(_notificationToMap(notification));
    }));
  }

  Future<void> _runFirestoreWrite(Future<void> Function() write) async {
    try {
      await write();
    } on Object catch (error) {
      debugPrint('Firestore write failed: $error');
    }
  }

  Map<String, Object?> _userToMap(AppUser user) {
    return {
      'name': user.name,
      'email': user.email,
      'role': user.role.name,
    };
  }

  AppUser _userFromMap(String id, Map<String, Object?> data) {
    final email = (data['email'] as String? ?? '').trim().toLowerCase();
    return AppUser(
      id: id,
      name: _displayNameFor(email, data['name'] as String? ?? ''),
      email: email,
      role: _roleForEmail(email) == UserRole.admin
          ? UserRole.admin
          : UserRole.values.byName(data['role'] as String? ?? UserRole.user.name),
    );
  }

  Map<String, Object?> _projectToMap(Project project) {
    return {
      'name': project.name,
      'description': project.description,
      'ownerId': project.ownerId,
      'managerId': project.managerId,
      'members': project.members.map(_memberToMap).toList(),
      'tasks': project.tasks.map(_taskToMap).toList(),
      'createdAt': Timestamp.fromDate(project.createdAt),
      'color': project.color,
    };
  }

  Project _projectFromMap(String id, Map<String, Object?> data) {
    final members = data['members'] as List<dynamic>? ?? const [];
    final tasks = data['tasks'] as List<dynamic>? ?? const [];
    return Project(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      managerId: data['managerId'] as String? ?? '',
      members: members
          .whereType<Map<String, dynamic>>()
          .map(_memberFromMap)
          .toList(growable: false),
      tasks: tasks.whereType<Map<String, dynamic>>().map(_taskFromMap).toList(growable: false),
      createdAt: _dateFromValue(data['createdAt']),
      color: data['color'] as int? ?? 0xFF45D6B5,
    );
  }

  Map<String, Object?> _memberToMap(ProjectMember member) {
    return {
      'userId': member.userId,
      'email': member.email,
      'permission': member.permission.name,
    };
  }

  ProjectMember _memberFromMap(Map<String, Object?> data) {
    return ProjectMember(
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      permission: ProjectPermission.values.byName(
        data['permission'] as String? ?? ProjectPermission.member.name,
      ),
    );
  }

  Map<String, Object?> _taskToMap(ProjectTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'status': task.status.name,
      'assigneeId': task.assigneeId,
      'createdBy': task.createdBy,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'dueDate': task.dueDate == null ? null : Timestamp.fromDate(task.dueDate!),
      'comments': task.comments.map(_commentToMap).toList(),
      'attachments': task.attachments.map(_attachmentToMap).toList(),
    };
  }

  ProjectTask _taskFromMap(Map<String, Object?> data) {
    final comments = data['comments'] as List<dynamic>? ?? const [];
    final attachments = data['attachments'] as List<dynamic>? ?? const [];
    return ProjectTask(
      id: data['id'] as String? ?? _uuid.v4(),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: TaskStatus.values.byName(data['status'] as String? ?? TaskStatus.todo.name),
      assigneeId: data['assigneeId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      dueDate: data['dueDate'] == null ? null : _dateFromValue(data['dueDate']),
      comments: comments
          .whereType<Map<String, dynamic>>()
          .map(_commentFromMap)
          .toList(growable: false),
      attachments: attachments
          .whereType<Map<String, dynamic>>()
          .map(_attachmentFromMap)
          .toList(growable: false),
    );
  }

  Map<String, Object?> _commentToMap(TaskComment comment) {
    return {
      'id': comment.id,
      'authorId': comment.authorId,
      'message': comment.message,
      'createdAt': Timestamp.fromDate(comment.createdAt),
    };
  }

  TaskComment _commentFromMap(Map<String, Object?> data) {
    return TaskComment(
      id: data['id'] as String? ?? _uuid.v4(),
      authorId: data['authorId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
    );
  }

  Map<String, Object?> _attachmentToMap(TaskAttachment attachment) {
    return {
      'id': attachment.id,
      'name': attachment.name,
      'path': attachment.path,
      'addedAt': Timestamp.fromDate(attachment.addedAt),
    };
  }

  TaskAttachment _attachmentFromMap(Map<String, Object?> data) {
    return TaskAttachment(
      id: data['id'] as String? ?? _uuid.v4(),
      name: data['name'] as String? ?? '',
      path: data['path'] as String? ?? '',
      addedAt: _dateFromValue(data['addedAt']),
    );
  }

  Map<String, Object?> _activityToMap(ActivityItem item) {
    return {
      'projectId': item.projectId,
      'actorId': item.actorId,
      'message': item.message,
      'createdAt': Timestamp.fromDate(item.createdAt),
    };
  }

  ActivityItem _activityFromMap(String id, Map<String, Object?> data) {
    return ActivityItem(
      id: id,
      projectId: data['projectId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
    );
  }

  Map<String, Object?> _notificationToMap(AppNotification notification) {
    return {
      'title': notification.title,
      'body': notification.body,
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'read': notification.read,
    };
  }

  AppNotification _notificationFromMap(String id, Map<String, Object?> data) {
    return AppNotification(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: _dateFromValue(data['createdAt']),
      read: data['read'] as bool? ?? false,
    );
  }

  DateTime _dateFromValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  int _colorForIndex(int index) {
    const colors = [0xFF45D6B5, 0xFFFFC857, 0xFF8AB4FF, 0xFFFF6B8B];
    return colors[index % colors.length];
  }

  void _seed() {
    final admin = AppUser(
      id: _uuid.v4(),
      name: adminName,
      email: adminEmail,
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
