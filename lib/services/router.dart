import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/vocabulary_page.dart';
import '../pages/listening_page.dart';
import '../pages/speaking_page.dart';
import '../pages/reading_page.dart';
import '../pages/writing_page.dart';
import '../pages/review_page.dart';
import '../pages/stats_page.dart';
import '../pages/quiz_page.dart';
import '../pages/settings_page.dart';
import '../pages/tts_test_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final goRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const HomePage()),
        ),
        GoRoute(
          path: '/vocabulary',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const VocabularyPage()),
        ),
        GoRoute(
          path: '/listening',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ListeningPage()),
        ),
        GoRoute(
          path: '/speaking',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const SpeakingPage()),
        ),
        GoRoute(
          path: '/reading',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ReadingPage()),
        ),
        GoRoute(
          path: '/writing',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const WritingPage()),
        ),
        GoRoute(
          path: '/review',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ReviewPage()),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const StatsPage()),
        ),
      ],
    ),
    GoRoute(
      path: '/quiz',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const QuizPage()),
    ),
    GoRoute(
      path: '/quiz/exam',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const QuizPage(examMode: true)),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const SettingsPage()),
    ),
    GoRoute(
      path: '/tts-test',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const TtsTestPage()),
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首页', path: '/'),
    (icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: '背单词', path: '/vocabulary'),
    (icon: Icons.headphones_outlined, selectedIcon: Icons.headphones, label: '听力', path: '/listening'),
    (icon: Icons.mic_outlined, selectedIcon: Icons.mic, label: '口语', path: '/speaking'),
    (icon: Icons.book_outlined, selectedIcon: Icons.book, label: '阅读', path: '/reading'),
    (icon: Icons.edit_outlined, selectedIcon: Icons.edit, label: '写作', path: '/writing'),
    (icon: Icons.refresh_outlined, selectedIcon: Icons.refresh, label: '复习', path: '/review'),
    (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: '统计', path: '/stats'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) {
          context.go(_destinations[index].path);
        },
        backgroundColor: theme.colorScheme.surfaceContainer,
        destinations: _destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    for (int i = 0; i < _destinations.length; i++) {
      if (location.startsWith(_destinations[i].path)) {
        return i;
      }
    }
    return 0;
  }
}
