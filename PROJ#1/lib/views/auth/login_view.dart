import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const _rememberedEmailKey = 'remembered_login_email';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _signup = false;
  bool _rememberMe = false;
  String? _rememberedEmail;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Logo(),
                  const SizedBox(height: 36),
                  Text(
                    _signup ? 'Create your workspace account' : 'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage projects, assign tasks, and keep activity visible.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 28),
                  if (_signup) ...[
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.alternate_email),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (!_signup) ...[
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _rememberMe,
                      onChanged: (value) => setState(() {
                        _rememberMe = value ?? false;
                        if (_rememberMe && _rememberedEmail != null) {
                          _emailController.text = _rememberedEmail!;
                        }
                      }),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Remember me'),
                    ),
                  ],
                  if (auth.error != null) ...[
                    if (auth.error != AuthProvider.accountExistsMessage) ...[
                      const SizedBox(height: 12),
                      Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                  if (auth.success != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.success!, style: const TextStyle(color: Color(0xFF45D6B5))),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: auth.loading ? null : _submit,
                      icon: auth.loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_signup ? Icons.person_add_alt : Icons.login),
                      label: Text(_signup ? 'Create account' : 'Sign in'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _toggleMode,
                    child: Text(
                      _signup
                          ? 'Already have an account? Sign in'
                          : 'Need a new account? Sign up',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (_signup) {
      final created = await auth.signUp(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );
      if (!created && mounted && auth.error == AuthProvider.accountExistsMessage) {
        _showToast(AuthProvider.accountExistsMessage);
      }
      if (created && mounted) {
        setState(() {
          _signup = false;
          _passwordController.clear();
          _restoreLoginEmailField();
        });
      }
    } else {
      final email = _emailController.text.trim().toLowerCase();
      final rememberEmail = _rememberMe;
      await auth.signIn(_emailController.text, _passwordController.text);
      if (auth.isAuthenticated && auth.error == null) {
        await _saveRememberedEmail(email, rememberEmail);
      }
    }
  }

  Future<void> _loadRememberedEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(_rememberedEmailKey);
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _rememberedEmail = email;
      _rememberMe = true;
      if (!_signup) {
        _emailController.text = email;
      }
    });
  }

  Future<void> _saveRememberedEmail(String email, bool rememberEmail) async {
    final preferences = await SharedPreferences.getInstance();
    if (rememberEmail && email.isNotEmpty) {
      await preferences.setString(_rememberedEmailKey, email);
      _rememberedEmail = email;
      return;
    }

    await preferences.remove(_rememberedEmailKey);
    _rememberedEmail = null;
  }

  void _toggleMode() {
    setState(() {
      _signup = !_signup;
      _passwordController.clear();
      if (_signup) {
        _nameController.clear();
        _emailController.clear();
      } else {
        _restoreLoginEmailField();
      }
    });
  }

  void _restoreLoginEmailField() {
    if (_rememberMe && _rememberedEmail != null) {
      _emailController.text = _rememberedEmail!;
    } else {
      _emailController.clear();
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.view_kanban_rounded, color: Colors.black),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FlutterTrello',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            Text('Project collaboration', style: TextStyle(color: Colors.white60)),
          ],
        ),
      ],
    );
  }
}
