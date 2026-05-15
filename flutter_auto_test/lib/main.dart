import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'ui/pages/home_page.dart';
import 'ui/pages/recorder_page.dart';
import 'ui/pages/player_page.dart';
import 'ui/pages/reports_page.dart';
import 'ui/pages/accounts_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/pages/import_page.dart';
import 'ui/pages/app_selector_page.dart';
import 'ui/pages/app_structure_page.dart';
import 'ui/pages/test_recommend_page.dart';

void main() {
  runApp(const AutoTestApp());
}

class AutoTestApp extends StatelessWidget {
  const AutoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoTest - 自动化测试工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052D9),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052D9),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
      routes: {
        '/recorder': (context) => const RecorderPage(),
        '/player': (context) => const PlayerPage(),
        '/reports': (context) => const ReportsPage(),
        '/accounts': (context) => const AccountsPage(),
        '/settings': (context) => const SettingsPage(),
        '/import': (context) => const ImportPage(),
        '/app_selector': (context) => const AppSelectorPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/app_structure') {
          return MaterialPageRoute(
            builder: (context) => const AppStructurePage(),
          );
        }
        if (settings.name == '/test_recommend') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => TestRecommendPage(
              targetPackage: args['packageName']!,
              targetAppName: args['appName']!,
            ),
          );
        }
        return null;
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
    );
  }
}
