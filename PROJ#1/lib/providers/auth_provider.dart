import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/demo_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  static const accountExistsMessage = 'This account already exists.';

  final DemoRepository _repository;
  AppUser? _user;
  bool _loading = false;
  String? _error;
  String? _success;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  String? get success => _success;

  Future<void> restoreSession() async {
    _user = await _repository.restoreSession();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final validation = _validateCredentials(email, password);
    if (validation != null) {
      _error = validation;
      _success = null;
      notifyListeners();
      return;
    }

    await _run(() async {
      _user = await _repository.signIn(email, password);
    });
  }

  Future<bool> signUp(String name, String email, String password) async {
    final validation = _validateCredentials(email, password);
    if (validation != null) {
      _error = validation;
      _success = null;
      notifyListeners();
      return false;
    }

    final created = await _run(() async {
      await _repository.signUp(name, email, password);
      await _repository.signOut();
      _user = null;
      _success = 'Account created. Please sign in to continue.';
    });
    return created;
  }

  void signOut() {
    _user = null;
    unawaited(_repository.signOut());
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on firebase_auth.FirebaseAuthException catch (error) {
      _error = _messageForAuthError(error);
    } on Object catch (error) {
      _error = _messageForError(error);
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }

  String? _validateCredentials(String email, String password) {
    if (email.trim().isEmpty) return 'Enter your email address.';
    if (!email.contains('@')) return 'Enter a valid email address.';
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 6) return 'Use at least 6 characters for your password.';
    return null;
  }

  String _messageForAuthError(firebase_auth.FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'missing-email' => 'Enter your email address.',
      'missing-password' => 'Enter your password.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'user-not-found' => 'No account exists for that email yet.',
      'wrong-password' || 'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' => accountExistsMessage,
      'operation-not-allowed' =>
        'Enable Email/Password sign-in in Firebase Authentication, then try again.',
      'admin-restricted-operation' =>
        'Firebase is blocking this auth method. Enable Email/Password sign-in first.',
      'configuration-not-found' =>
        'Firebase Authentication is not fully configured for this project.',
      'app-not-authorized' =>
        'This app is not authorized for the configured Firebase project.',
      'invalid-api-key' => 'The Firebase API key is invalid for this app.',
      'network-request-failed' => 'Check your internet connection and try again.',
      'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
      _ => 'Authentication failed (${error.code}). ${error.message ?? 'Please try again.'}',
    };
  }

  String _messageForError(Object error) {
    final message = error.toString().replaceFirst('Bad state: ', '');
    if (message.trim().isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }
}
