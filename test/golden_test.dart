import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stabledart/app.dart';
import 'package:stabledart/models/output_image.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/state/outputs_store.dart';
import 'package:stabledart/views/pages/checkpoints_page.dart';
import 'package:stabledart/views/pages/first_launch_page.dart';
import 'package:stabledart/views/pages/inference_page.dart';
import 'package:stabledart/views/pages/model_browser_page.dart';
import 'package:stabledart/views/pages/outputs_page.dart';
import 'package:stabledart/views/pages/packages_page.dart';
import 'package:stabledart/views/pages/settings_page.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> golden(
      WidgetTester tester, Widget page, String name,
      {SettingsManager? settings,
      Size size = const Size(1400, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(page, settings: settings));
    await tester.pumpAndSettle();
    await expectLater(
        find.byType(page.runtimeType), matchesGoldenFile('goldens/$name.png'));
  }

  testWidgets('golden: packages page', (tester) async {
    await golden(tester, const PackagesPage(), 'packages_page');
  });

  testWidgets('golden: inference page', (tester) async {
    await golden(tester, const InferencePage(), 'inference_page',
        size: const Size(1600, 1200));
  });

  testWidgets('golden: model browser', (tester) async {
    final api = CivitAiApi(client: MockClient((r) async {
      return http.Response(
          '{"items": [], "metadata": {}}', 200);
    }));
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(const ModelBrowserPage(),
        civitAi: api));
    await tester.pumpAndSettle();
    await expectLater(find.byType(ModelBrowserPage),
        matchesGoldenFile('goldens/model_browser.png'));
  });

  testWidgets('golden: checkpoints page', (tester) async {
    await golden(tester, const CheckpointsPage(), 'checkpoints_page');
  });

  testWidgets('golden: outputs page', (tester) async {
    final settings = TestProviders.memorySettings();
    final outputs = OutputsStore(settings);
    await outputs.add(OutputImage(
        id: 'o1',
        filePath: 'outputs/txt2img/sunset.png',
        prompt: 'a sunset over water',
        seed: 42,
        createdAt: DateTime(2024)));
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        TestProviders.wrap(const OutputsPage(), settings: settings));
    await tester.pumpAndSettle();
    await expectLater(find.byType(OutputsPage),
        matchesGoldenFile('goldens/outputs_page.png'));
  });

  testWidgets('golden: settings page', (tester) async {
    await golden(tester, const SettingsPage(), 'settings_page');
  });

  testWidgets('golden: first launch page', (tester) async {
    await golden(tester, const FirstLaunchPage(), 'first_launch');
  });

  testWidgets('golden: main shell', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['firstLaunchComplete'] = true);
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        TestProviders.wrap(const StableDartApp(), settings: settings));
    await tester.pumpAndSettle();
    await expectLater(find.byType(StableDartApp),
        matchesGoldenFile('goldens/main_shell.png'));
  });
}
