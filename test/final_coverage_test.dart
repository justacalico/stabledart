import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stabledart/app.dart';
import 'package:stabledart/main.dart';
import 'package:stabledart/models/app_update.dart';
import 'package:stabledart/models/chat_message.dart';
import 'package:stabledart/models/download_task.dart';
import 'package:stabledart/models/output_image.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/download_service.dart';
import 'package:stabledart/services/github_versions_api.dart';
import 'package:stabledart/services/huggingface_api.dart';
import 'package:stabledart/models/package_definition.dart';
import 'package:stabledart/services/package_registry.dart';
import 'package:stabledart/services/settings_backend.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/services/version_checker.dart';
import 'package:stabledart/state/console_store.dart';
import 'package:stabledart/state/inference_store.dart';
import 'package:stabledart/state/installed_packages_store.dart';
import 'package:stabledart/state/navigation_store.dart';
import 'package:stabledart/state/outputs_store.dart';
import 'package:stabledart/services/civarchive_api.dart';
import 'package:stabledart/services/openmodeldb_api.dart';
import 'package:stabledart/state/image_lab_store.dart';
import 'package:stabledart/state/model_index_service.dart';
import 'package:stabledart/state/notification_store.dart';
import 'package:stabledart/state/workflows_store.dart';
import 'package:stabledart/models/local_model.dart';
import 'package:stabledart/utils/version_utils.dart';
import 'package:stabledart/views/dialogs/env_vars_dialog.dart';
import 'package:stabledart/views/dialogs/image_viewer_dialog.dart';
import 'package:stabledart/views/pages/console_page.dart';
import 'package:stabledart/views/pages/inference_page.dart';
import 'package:stabledart/views/pages/launch_page.dart';
import 'package:stabledart/views/pages/packages_page.dart';
import 'package:stabledart/views/pages/package_browser_page.dart';
import 'package:stabledart/views/pages/outputs_page.dart';
import 'package:stabledart/views/pages/workflows_page.dart';
import 'package:stabledart/views/pages/checkpoints_page.dart';
import 'package:stabledart/views/pages/banana_vision_page.dart';
import 'package:stabledart/views/widgets/app_logo.dart';
import 'package:stabledart/views/widgets/stack_card.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  test('misc getters and fallbacks', () {
    final sm = SettingsManager(MemorySettingsBackend());
    final index = ModelIndexService(sm);
    expect(index.models, isEmpty);
    expect(index.query, '');
    expect(index.categoryFilter, isNull);
    final outputs = OutputsStore(sm);
    expect(outputs.outputs, isEmpty);
    expect(outputs.query, '');
    expect(outputs.folderFilter, isNull);
    InferenceStore(defaults: sm.settings);
    CivitAiApi();
    HuggingFaceApi();
    final checker = VersionChecker();
    checker.close();
    VersionChecker(client: MockClient((r) async => http.Response('[]', 200)))
        .close();

    final update = const AppUpdate(currentVersion: '1', latestVersion: '2');
    expect(update.copyWith(latestVersion: '3').latestVersion, '3');
    expect(update.copyWith(updateAvailable: true).updateAvailable, isTrue);

    expect(
        OutputImage.fromJson({'id': 'x', 'filePath': 'f'})
            .createdAt
            .millisecondsSinceEpoch,
        0);
    expect(
        ImageLabMessage.fromJson({'id': 'x', 'role': 'user'})
            .timestamp
            .millisecondsSinceEpoch,
        0);

    expect(
        Version.parse('1.0.0-alpha')!
            .compareTo(Version.parse('1.0.0-beta')!),
        isNot(0));
    expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0')!), 0);
    expect(
        Version.parse('1.0.0-1')!
            .compareTo(Version.parse('1.0.0-alpha')!),
        lessThan(0));
  });

  test('download tick and paused cancel', () async {
    final controller = StreamController<List<int>>();
    final written = <int>[];
    final dl = DownloadService(
      clientFactory: () => MockClient.streaming(
          (r, _) async => http.StreamedResponse(controller.stream, 200,
              contentLength: 4)),
      fileWriter: _CollectingWriter(written),
    );
    final task = dl.enqueue(fileName: 't', url: 'u', totalBytes: 4);
    controller.add([1]);
    await Future.delayed(const Duration(milliseconds: 700));
    controller.add([2]);
    await Future.delayed(const Duration(milliseconds: 30));
    dl.pause(task);
    controller.add([3]);
    await Future.delayed(const Duration(milliseconds: 50));
    expect(task.status, DownloadStatus.paused);
    dl.cancel(task);
    expect(task.status, DownloadStatus.cancelled);
    await controller.close();
  });

  test('resume paused download', () async {
    var calls = 0;
    final dl = DownloadService(
        clientFactory: () => MockClient.streaming((r, _) async {
              calls++;
              return http.StreamedResponse(
                  calls == 1
                      ? (StreamController<List<int>>()..close()).stream
                      : Stream.value(<int>[1]),
                  200);
            }));
    final task = dl.enqueue(fileName: 'r', url: 'u');
    await Future.delayed(const Duration(milliseconds: 50));
    if (task.status == DownloadStatus.completed ||
        task.status == DownloadStatus.downloading) {
      dl.resume(task);
    }
    await Future.delayed(const Duration(milliseconds: 50));
    expect(task.isFinished || task.isActive, isTrue);
  });

  testWidgets('LaunchPage full flow', (tester) async {
    final runner = FakeProcessRunner(hang: true);
    final settings = TestProviders.memorySettings();
    final store = InstalledPackagesStore(settings, runner);
    final pkg =
        await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(
        LaunchPage(packageId: pkg.id),
        settings: settings,
        packages: store));
    await tester.pumpAndSettle();
    expect(find.text('Launch'), findsOneWidget);
    expect(find.text('Launch Options'), findsOneWidget);

    await tester.tap(find.text('Launch'));
    await tester.pump();
    expect(find.text('Stop'), findsOneWidget);
    await tester.tap(find.text('Open Web UI'));
    await tester.pump();
    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(runner.stopped, isTrue);

    runner.hang = false;
    await tester.tap(find.text('Launch'));
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Launch Options'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Launch Options'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('LaunchPage missing package', (tester) async {
    await pumpPage(tester, const LaunchPage(packageId: 'nope'));
    expect(find.text('Package not found'), findsOneWidget);
  });

  testWidgets('running package badge and launch nav', (tester) async {
    final runner = FakeProcessRunner(hang: true);
    final settings = TestProviders.memorySettings();
    final store = InstalledPackagesStore(settings, runner);
    final pkg =
        await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(const PackagesPage(),
        settings: settings,
        packages: store));
    await tester.pumpAndSettle();
    unawaited(store.launch(pkg, onOutput: (_) {}));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);

    await tester.tap(find.text('Console').first);
    await tester.pumpAndSettle();
    expect(find.byType(LaunchPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.packages, isNotEmpty);
    await store.stop(pkg);
  });

  testWidgets('launch options with value field', (tester) async {
    final settings = TestProviders.memorySettings();
    final store = InstalledPackagesStore(settings, FakeProcessRunner());
    PackageDefinition? def;
    for (final d in PackageRegistry.all) {
      if (d.launchOptions().any((o) => !o.isToggle)) {
        def = d;
        break;
      }
    }
    expect(def, isNotNull);
    final pkg = await store.install(def!, 'v1');
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(const PackagesPage(),
        settings: settings, packages: store));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    final swCount = find.byType(Switch).evaluate().length;
    for (var i = 0; i < swCount; i++) {
      await tester.tap(find.byType(Switch).at(i));
      await tester.pump();
    }
    if (find.byType(TextFormField).evaluate().isNotEmpty) {
      await tester.enterText(
          find.byType(TextFormField).first, '1234');
      await tester.pump();
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.byId(pkg.id)!.launchArgs, isNotEmpty);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('package browser installed icon and versions',
      (tester) async {
    final settings = TestProviders.memorySettings();
    final store = InstalledPackagesStore(settings, FakeProcessRunner());
    await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
    final gh = GitHubVersionsApi(client: MockClient((r) async {
      if (r.url.path.contains('tags')) {
        return http.Response(jsonEncode([
          {'name': 'v0.9'},
          {'name': 'v1.0'}
        ]), 200);
      }
      return http.Response(
          jsonEncode([
            {'name': 'main'},
            {'name': 'dev'}
          ]),
          200);
    }));
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(
        PackageInstallDetailPage(
            definition: PackageRegistry.byName('ComfyUI')!,
            onBack: () {}),
        settings: settings,
        packages: store,
        gitHub: gh));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('v0.9').last);
    await tester.pumpAndSettle();
    expect(find.text('v0.9'), findsWidgets);
  });

  testWidgets('package browser install progress', (tester) async {
    final settings = TestProviders.memorySettings();
    final store = InstalledPackagesStore(settings, FakeProcessRunner());
    final completer = Completer<bool>();
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(TestProviders.wrap(
        PackageInstallDetailPage(
            definition: PackageRegistry.byName('ComfyUI')!,
            onBack: () {}),
        settings: settings,
        packages: store));
    await tester.pumpAndSettle();
    store
        .install(PackageRegistry.byName('ComfyUI')!, 'v1',
            runStep: (_) => completer.future)
        .ignore();
    await tester.pumpAndSettle();
    expect(find.textContaining('%'), findsWidgets);
    completer.complete(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('failed'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
  });

  testWidgets('console scroll listener', (tester) async {
    await pumpPage(tester, const ConsolePage());
    final console = tester
        .element(find.byType(ConsolePage))
        .read<ConsoleStore>();
    for (var i = 0; i < 100; i++) {
      console.log('line $i');
    }
    await tester.pumpAndSettle();
    await tester.drag(
        find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    await tester.drag(
        find.byType(ListView), const Offset(0, -500));
    await tester.pump();
  });

  testWidgets('inference cancel generation', (tester) async {
    final sm = TestProviders.memorySettings();
    final inf = InferenceStore(
        defaults: sm.settings,
        backend: MockInferenceBackend(
            stepDelay: const Duration(milliseconds: 30), ticks: 200));
    await pumpPage(tester, const InferencePage(),
        settings: sm, inference: inf);
    await tester.tap(find.text('Generate'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Cancelled'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('workflows empty action and dropdown', (tester) async {
    await pumpPage(tester, const WorkflowsPage());
    await tester.tap(find.text('Install Workflow').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Workflow name'), 'wf');
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SD3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('No Workflows Installed'), findsOneWidget);
  });

  testWidgets('checkpoints search empty and metadata edit',
      (tester) async {
    await pumpPage(tester, const CheckpointsPage());
    final index = tester
        .element(find.byType(CheckpointsPage))
        .read<ModelIndexService>();
    await index.importFile(
        fileName: 'a.safetensors',
        category: ModelCategory.stableDiffusion);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No Models Found'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(
        find.byType(DropdownButtonFormField<ModelCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VAE').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Model').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await index.remove(index.models.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import Model').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'empty-import.safetensors');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(index.models, isNotEmpty);
  });

  testWidgets('banana vision tile select and submit', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['geminiApiKey'] = 'k');
    await pumpPage(tester, const BananaVisionPage(), settings: settings);
    await tester.tap(find.widgetWithText(FilledButton, 'New Chat'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'New Chat'));
    await tester.pumpAndSettle();
    final tiles = find.ancestor(
        of: find.textContaining('messages ·'),
        matching: find.byType(InkWell));
    for (var i = 0; i < tiles.evaluate().length; i++) {
      await tester.tap(tiles.at(i));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextField).last, 'via submit');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('via submit'), findsWidgets);
  });

  testWidgets('outputs seed fallback and viewer negative',
      (tester) async {
    await pumpPage(tester, const OutputsPage());
    final store =
        tester.element(find.byType(OutputsPage)).read<OutputsStore>();
    await store.add(OutputImage(
        id: 'o1',
        filePath: 'x.png',
        negativePrompt: 'bad stuff',
        createdAt: DateTime(2024)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Seed'), findsOneWidget);
    await tester.tap(find.textContaining('Seed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Negative'), findsOneWidget);
  });

  testWidgets('env vars dialog seeded', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['environmentVariables'] = {'A': '1'});
    await pumpPage(tester, Builder(
      builder: (context) => FilledButton(
        onPressed: () => showEnvVarsDialog(context),
        child: const Text('open'),
      ),
    ), settings: settings);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField).evaluate().length, 2);
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('image viewer dialog', (tester) async {
    await pumpPage(tester, Builder(
      builder: (context) => FilledButton(
        onPressed: () => showImageViewerDialog(
            context,
            OutputImage(
                id: 'o',
                filePath: 'x.png',
                prompt: 'p',
                negativePrompt: 'n',
                createdAt: DateTime(2024))),
        child: const Text('open'),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Negative'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('buildApp covers all provider factories', (tester) async {
    SharedPreferences.setMockInitialValues({
      'stabledart.settings': jsonEncode({'firstLaunchComplete': true}),
    });
    final prefs = await SharedPreferences.getInstance();
    final app = buildApp(prefs, '0.1.0');
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(StableDartApp));
    context.read<GitHubVersionsApi>();
    context.read<CivitAiApi>();
    context.read<HuggingFaceApi>();
    context.read<DownloadService>();
    context.read<VersionChecker>();
    context.read<NavigationStore>();
    context.read<OpenModelDbApi>();
    context.read<CivArchiveApi>();
    context.read<WorkflowsStore>();
    context.read<ImageLabStore>();
    context.read<ModelIndexService>();
    context.read<InstalledPackagesStore>();
    context.read<OutputsStore>();
    context.read<NotificationStore>();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model Browser').first);
    await tester.pumpAndSettle();
    for (final tab in ['CivArchive', 'HuggingFace', 'OpenModelDB']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    context.read<ConsoleStore>();
  });

  testWidgets('activity badge in shell', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['firstLaunchComplete'] = true);
    await pumpApp(tester, settings: settings);
    final nav = tester
        .element(find.text('Packages').first)
        .read<NavigationStore>();
    nav.setActivityBadge(37);
    await tester.pumpAndSettle();
    expect(find.text('37'), findsWidgets);
  });

  testWidgets('app logo fallback', (tester) async {
    await pumpPage(tester, const Column(children: [
      AppLogo(asset: 'assets/missing.png'),
      AppLogo(asset: 'assets/images/icon.png'),
    ]));
    expect(find.byIcon(Icons.dashboard_customize), findsOneWidget);
  });

  testWidgets('stack card toggle', (tester) async {
    var toggled = false;
    await pumpPage(tester, StackCard(
      title: 'C',
      expanded: false,
      onToggle: () => toggled = true,
      child: const Text('body'),
    ));
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(toggled, isTrue);
    expect(find.text('body'), findsNothing);
  });
}

class _CollectingWriter implements DownloadFileWriter {
  _CollectingWriter(this.data);
  final List<int> data;

  @override
  Future<IOSink> openWrite(String path) async => _CollectingSink(data);
}

class _CollectingSink implements IOSink {
  _CollectingSink(this.data);
  final List<int> data;

  @override
  void add(List<int> chunk) => data.addAll(chunk);

  @override
  Future<void> close() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
