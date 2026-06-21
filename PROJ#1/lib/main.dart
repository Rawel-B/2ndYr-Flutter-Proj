import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'services/demo_repository.dart';
import 'services/firebase_bootstrap.dart';
import 'views/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await FirebaseBootstrap.tryInitialize();
  final repository = DemoRepository(firebaseReady: firebaseReady);
  await repository.loadFirebaseData();

  runApp(FlutterTrelloApp(repository: repository));
}

class FlutterTrelloApp extends StatelessWidget {
  const FlutterTrelloApp({super.key, required this.repository});

  final DemoRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository)..restoreSession(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
          create: (_) => ProjectProvider(repository),
          update: (_, auth, provider) =>
              (provider ?? ProjectProvider(repository))..syncUser(auth.user),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FlutterTrello',
        themeMode: ThemeMode.dark,
        darkTheme: _darkTheme(),
        home: const AuthGate(),
      ),
    );
  }

  ThemeData _darkTheme() {
    const background = Color(0xFF080B12);
    const surface = Color(0xFF101520);
    const card = Color(0xFF161D2B);
    const accent = Color(0xFF45D6B5);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: surface,
        primary: accent,
        secondary: const Color(0xFFFFC857),
        tertiary: const Color(0xFF8AB4FF),
      ),
      cardColor: card,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF273244)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF273244)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF06110F),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
