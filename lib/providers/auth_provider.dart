import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/demo_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final DemoRepository _repository;
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> restoreSession() async {
    _user = _repository.users.first;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _run(() async {
      _user = await _repository.signIn(email, password);
    });
  }

  Future<void> signUp(String name, String email, String password) async {
    await _run(() async {
      _user = await _repository.signUp(name, email, password);
    });
  }

  void signOut() {
    _user = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on Object catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
