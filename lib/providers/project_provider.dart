import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/demo_repository.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectProvider(this._repository);

  final DemoRepository _repository;
  AppUser? _user;
  String? _selectedProjectId;
  bool _listView = false;

  List<Project> get projects => _repository.projectsFor(_user);
  List<AppUser> get users => _repository.users;
  List<AppNotification> get notifications => _repository.notificationsFor(_user);
  bool get listView => _listView;

  Project? get selectedProject {
    if (_selectedProjectId == null) {
      return _firstProject;
    }
    return _repository.projectById(_selectedProjectId!) ?? _firstProject;
  }

  int get unreadNotifications =>
      notifications.where((notification) => !notification.read).length;

  void syncUser(AppUser? user) {
    if (_user?.id == user?.id) return;
    _user = user;
    _selectedProjectId ??= _firstProject?.id;
  }

  Project? get _firstProject => projects.isEmpty ? null : projects.first;

  void selectProject(String id) {
    _selectedProjectId = id;
    notifyListeners();
  }

  void toggleView() {
    _listView = !_listView;
    notifyListeners();
  }

  void createProject(String name, String description) {
    final user = _requireUser();
    final project = _repository.createProject(
      owner: user,
      name: name,
      description: description,
    );
    _selectedProjectId = project.id;
    notifyListeners();
  }

  void inviteMember(Project project, String email) {
    _repository.inviteMember(project, email, _requireUser());
    notifyListeners();
  }

  void setManager(Project project, String userId) {
    _repository.setManager(project, userId, _requireUser());
    notifyListeners();
  }

  void createTask({
    required Project project,
    required String title,
    required String description,
    required TaskStatus status,
    required String assigneeId,
  }) {
    _repository.createTask(
      project: project,
      actor: _requireUser(),
      title: title,
      description: description,
      status: status,
      assigneeId: assigneeId,
    );
    notifyListeners();
  }

  void moveTask(Project project, ProjectTask task, TaskStatus status) {
    _repository.moveTask(project, task, status, _requireUser());
    notifyListeners();
  }

  void updateTask(Project project, ProjectTask task) {
    _repository.updateTask(project, task, _requireUser());
    notifyListeners();
  }

  void deleteTask(Project project, ProjectTask task) {
    _repository.deleteTask(project, task, _requireUser());
    notifyListeners();
  }

  void addComment(Project project, ProjectTask task, String message) {
    if (message.trim().isEmpty) return;
    _repository.addComment(project, task, _requireUser(), message);
    notifyListeners();
  }

  void addAttachment(Project project, ProjectTask task, String name, String path) {
    _repository.addAttachment(project, task, _requireUser(), name, path);
    notifyListeners();
  }

  List<ActivityItem> activityFor(String projectId) {
    return _repository.activityFor(projectId);
  }

  AppUser? userById(String id) => _repository.userById(id);

  void markNotificationsRead() {
    _repository.markNotificationsRead(_user);
    notifyListeners();
  }

  AppUser _requireUser() {
    final user = _user;
    if (user == null) {
      throw StateError('You must be signed in to manage projects.');
    }
    return user;
  }
}
