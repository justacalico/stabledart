import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:stabledart/app.dart';
import 'package:stabledart/services/civarchive_api.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/download_service.dart';
import 'package:stabledart/services/github_versions_api.dart';
import 'package:stabledart/services/huggingface_api.dart';
import 'package:stabledart/services/openmodeldb_api.dart';
import 'package:stabledart/services/process_runner.dart';
import 'package:stabledart/services/settings_backend.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/services/version_checker.dart';
import 'package:stabledart/models/download_task.dart';
import 'package:stabledart/state/console_store.dart';
import 'package:stabledart/state/image_lab_store.dart';
import 'package:stabledart/state/inference_store.dart';
import 'package:stabledart/state/installed_packages_store.dart';
import 'package:stabledart/state/model_browser_store.dart';
import 'package:stabledart/state/model_index_service.dart';
import 'package:stabledart/state/navigation_store.dart';
import 'package:stabledart/state/notification_store.dart';
import 'package:stabledart/state/outputs_store.dart';
import 'package:stabledart/state/version_store.dart';
import 'package:stabledart/state/workflows_store.dart';

class FakeProcessRunner implements ProcessRunner {
  final List<String> lines;
  final List<List<String>> calls = [];
  final List<StreamController<String>> _controllers = [];
  bool stopped = false;
  ProcessResult? runResult;

  bool hang = false;

  FakeProcessRunner(
      {this.lines = const ['line1', 'line2'],
      this.hang = false,
      this.error});
  final Object? error;

  @override
  Stream<String> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      String? key}) {
    calls.add([executable, ...arguments]);
    if (error != null) return Stream.error(error!);
    if (hang) {
      final c = StreamController<String>();
      _controllers.add(c);
      return c.stream;
    }
    return Stream.fromIterable(lines);
  }

  @override
  Future<void> stop(String executable) async {
    stopped = true;
    for (final c in _controllers) {
      if (!c.isClosed) await c.close();
    }
  }

  @override
  Future<ProcessResult> run(String executable, List<String> arguments,
          {String? workingDirectory, Map<String, String>? environment}) =>
      Future.value(runResult ?? ProcessResult(0, 0, 'ok', ''));
}

class RecordingFileWriter implements DownloadFileWriter {
  final Map<String, List<int>> written = {};

  @override
  Future<StreamSink<List<int>>> openWrite(String path) async {
    final controller = StreamController<List<int>>();
    written[path] = [];
    controller.stream.listen((c) => written[path]!.addAll(c));
    return controller.sink;
  }
}

class TestProviders {
  static SettingsManager memorySettings({
    Map<String, dynamic> Function(Map<String, dynamic>)? seed,
  }) {
      final backend = MemorySettingsBackend();
      if (seed != null) {
        backend.setString('stabledart.settings', jsonEncode(seed({})));
      }
      return SettingsManager(backend);
  }

  static Widget wrap(
    Widget child, {
    SettingsManager? settings,
    DownloadService? downloads,
    CivitAiApi? civitAi,
    HuggingFaceApi? huggingFace,
    OpenModelDbApi? openModelDb,
    CivArchiveApi? civArchive,
    GitHubVersionsApi? gitHub,
    VersionStore? versionStore,
    InferenceStore? inference,
    ProcessRunner? runner,
    InstalledPackagesStore? packages,
  }) {
    final sm = settings ?? memorySettings();
    final outputs = OutputsStore(sm);
    final procRunner = runner ?? FakeProcessRunner();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sm),
        Provider<ProcessRunner>.value(value: procRunner),
        packages != null
            ? ChangeNotifierProvider.value(value: packages)
            : ChangeNotifierProvider(
                create: (_) => InstalledPackagesStore(sm, procRunner)),
        ChangeNotifierProvider(create: (_) => NavigationStore()),
        ChangeNotifierProvider(create: (_) => NotificationStore()),
        ChangeNotifierProvider(create: (_) => ConsoleStore()),
        ChangeNotifierProvider(create: (_) => ModelIndexService(sm)),
        ChangeNotifierProvider.value(value: outputs),
        ChangeNotifierProvider(create: (_) => WorkflowsStore(sm)),
        ChangeNotifierProvider(create: (_) => ImageLabStore(sm)),
        ChangeNotifierProvider.value(
            value: downloads ?? DownloadService()),
        Provider<CivitAiApi>.value(
            value: civitAi ?? CivitAiApi(client: MockClient(_notFound))),
        Provider<HuggingFaceApi>.value(
            value:
                huggingFace ?? HuggingFaceApi(client: MockClient(_notFound))),
        Provider<OpenModelDbApi>.value(
            value: openModelDb ??
                OpenModelDbApi(client: MockClient(_notFound))),
        Provider<CivArchiveApi>.value(
            value: civArchive ??
                CivArchiveApi(client: MockClient(_notFound))),
        Provider<GitHubVersionsApi>.value(
            value: gitHub ??
                GitHubVersionsApi(client: MockClient(_notFound))),
        ChangeNotifierProvider(
            create: (c) => CivitAiBrowserStore(c.read<CivitAiApi>())),
        ChangeNotifierProvider(
            create: (c) =>
                HuggingFaceBrowserStore(c.read<HuggingFaceApi>())),
        ChangeNotifierProvider(
            create: (c) =>
                OpenModelDbBrowserStore(c.read<OpenModelDbApi>())),
        ChangeNotifierProvider(
            create: (c) =>
                CivArchiveBrowserStore(c.read<CivArchiveApi>())),
        ChangeNotifierProvider.value(
            value: inference ??
                InferenceStore(
                    defaults: sm.settings,
                    onImageGenerated: outputs.add)),
        ChangeNotifierProvider.value(
            value: versionStore ??
                VersionStore(
                    VersionChecker(client: MockClient(_emptyReleases)),
                    () => '0.1.0')),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  static Future<http.Response> _notFound(http.Request r) async =>
      http.Response('{}', 404);

  static Future<http.Response> _emptyReleases(http.Request r) async =>
      http.Response('[]', 200);
}

class SeededDownloadService extends DownloadService {
  final List<DownloadTask> seeded;

  SeededDownloadService(this.seeded);

  @override
  List<DownloadTask> get tasks => seeded;
}

void setupMockChannels() {
  final messenger = TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/url_launcher'),
    (call) async => true,
  );
}

Future<void> loadAppFonts() async {
  final regular = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
  final bold = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
  final loader = FontLoader('Inter')
    ..addFont(Future.value(regular.buffer.asByteData()))
    ..addFont(Future.value(bold.buffer.asByteData()));
  await loader.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      '/home/calico/flutter';
  final icons = File(
          '$flutterRoot/bin/cache/artifacts/material_fonts/'
          'MaterialIcons-Regular.otf')
      .readAsBytesSync();
  await (FontLoader('MaterialIcons')
        ..addFont(Future.value(
            ByteData.view(Uint8List.fromList(icons).buffer))))
      .load();
}

Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  SettingsManager? settings,
  DownloadService? downloads,
  VersionStore? versionStore,
  InferenceStore? inference,
  InstalledPackagesStore? packages,
  GitHubVersionsApi? githubVersions,
  CivitAiApi? civitAi,
  HuggingFaceApi? huggingFace,
  OpenModelDbApi? openModelDb,
  CivArchiveApi? civArchive,
  Size size = const Size(1400, 900),
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TestProviders.wrap(page,
      settings: settings,
      downloads: downloads,
      versionStore: versionStore,
      inference: inference,
      packages: packages,
      gitHub: githubVersions,
      civitAi: civitAi,
      huggingFace: huggingFace,
      openModelDb: openModelDb,
      civArchive: civArchive));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> pumpApp(
  WidgetTester tester, {
  SettingsManager? settings,
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      TestProviders.wrap(const StableDartApp(), settings: settings));
  await tester.pumpAndSettle();
}
