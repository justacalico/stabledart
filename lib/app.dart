import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/settings_manager.dart';
import 'theme/app_theme.dart';
import 'views/pages/first_launch_page.dart';
import 'views/shell/main_shell.dart';

class StableDartApp extends StatelessWidget {
  const StableDartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsManager>();
    return MaterialApp(
      title: 'Stability Matrix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: settings.settings.firstLaunchComplete
          ? const MainShell()
          : const FirstLaunchPage(),
    );
  }
}
