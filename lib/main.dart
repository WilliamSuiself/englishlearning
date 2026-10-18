import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/router.dart';
import 'services/database_service.dart';
import 'services/tts_service.dart';
import 'services/data_seeder.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await DatabaseService.database;
  await DataSeeder.seedIfNeeded();

  // Initialize TTS - don't await, let it bind in background
  // The speak() method will await init if not ready
  TtsService().init();

  final themeMode = await SettingsService.getThemeMode();

  runApp(ProviderScope(child: EnglishLearningApp(themeMode: themeMode)));
}

class EnglishLearningApp extends StatelessWidget {
  final String themeMode;

  const EnglishLearningApp({super.key, required this.themeMode});

  ThemeMode get _themeMode {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EchoEnglish',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
      ),
      themeMode: _themeMode,
      routerConfig: goRouter,
    );
  }
}
