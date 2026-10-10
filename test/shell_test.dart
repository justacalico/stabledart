import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stabledart/app.dart';
import 'package:stabledart/main.dart' as app_main;
import 'package:stabledart/services/version_checker.dart';
import 'package:stabledart/state/navigation_store.dart';
import 'package:stabledart/state/version_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  testWidgets('app shows first launch when incomplete', (tester) async {
    await pumpApp(tester);
    expect(find.text('Welcome to Stability Matrix'), findsOneWidget);
  });

  testWidgets('shell navigates all destinations', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s
          ..['firstLaunchComplete'] = true
          ..['geminiApiKey'] = 'k');
    await pumpApp(tester, settings: settings);
    expect(find.text('Packages'), findsWidgets);

    for (final dest in [
      'Inference',
      'Model Manager',
      'Model Browser',
      'Outputs',
      'Workflows',
      'Documentation',
      'Activity',
      'Support Us',
      'Join Discord',
      'Settings',
    ]) {
      await tester.tap(find.text(dest).first);
      await tester.pumpAndSettle();
    }
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.text('Packages').first);
    await tester.pumpAndSettle();
  });

  testWidgets('shell shows update tile when update exists',
      (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['firstLaunchComplete'] = true);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final vs = VersionStore(
        VersionChecker(
            client: MockClient((r) async =>
                http.Response('[{"tag_name":"v9.9.9"}]', 200))),
        () => '0.1.0');
    await tester.pumpWidget(TestProviders.wrap(const StableDartApp(),
        settings: settings, versionStore: vs));
    await vs.checkForUpdates();
    await tester.pumpAndSettle();
    expect(find.text('Update Available'), findsOneWidget);
    await tester.tap(find.text('Update Available'));
    await tester.pumpAndSettle();
  });

  testWidgets('main() boots with mocked plugins', (tester) async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'stabledart',
      packageName: 'gitlab.httpanimations.stabledart',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: 'test',
    );
    app_main.main();
    await tester.pumpAndSettle();
    expect(find.byType(StableDartApp), findsOneWidget);
  });
}
