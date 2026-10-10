import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/civarchive_api.dart';
import 'services/civitai_api.dart';
import 'services/download_service.dart';
import 'services/github_versions_api.dart';
import 'services/huggingface_api.dart';
import 'services/openmodeldb_api.dart';
import 'services/process_runner.dart';
import 'services/settings_backend.dart';
import 'services/settings_manager.dart';
import 'services/version_checker.dart';
import 'state/console_store.dart';
import 'state/image_lab_store.dart';
import 'state/inference_store.dart';
import 'state/installed_packages_store.dart';
import 'state/model_browser_store.dart';
import 'state/model_index_service.dart';
import 'state/navigation_store.dart';
import 'state/notification_store.dart';
import 'state/outputs_store.dart';
import 'state/version_store.dart';
import 'state/workflows_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  runApp(buildApp(prefs, packageInfo.version));
}

Widget buildApp(dynamic prefs, String appVersion) {
  final settings = SettingsManager(SharedPreferencesBackend(prefs));
  final outputsStore = OutputsStore(settings);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      Provider<ProcessRunner>(create: (_) => SystemProcessRunner()),
      ChangeNotifierProvider(
        create: (c) =>
            InstalledPackagesStore(settings, c.read<ProcessRunner>()),
      ),
      ChangeNotifierProvider(create: (_) => NavigationStore()),
      ChangeNotifierProvider(create: (_) => NotificationStore()),
      ChangeNotifierProvider(
        create: (_) =>
            ConsoleStore(maxHistory: settings.settings.consoleHistorySize),
      ),
      ChangeNotifierProvider(create: (_) => ModelIndexService(settings)),
      ChangeNotifierProvider.value(value: outputsStore),
      ChangeNotifierProvider(create: (_) => WorkflowsStore(settings)),
      ChangeNotifierProvider(create: (_) => ImageLabStore(settings)),
      ChangeNotifierProvider(
        create: (_) => DownloadService(
          maxConcurrent: settings.settings.maxConcurrentDownloads,
        ),
      ),
      Provider<CivitAiApi>(
        create: (_) => CivitAiApi(apiKey: settings.settings.civitAiApiKey),
      ),
      Provider<HuggingFaceApi>(
        create: (_) =>
            HuggingFaceApi(apiKey: settings.settings.huggingFaceApiKey),
      ),
      Provider<OpenModelDbApi>(create: (_) => OpenModelDbApi()),
      Provider<CivArchiveApi>(create: (_) => CivArchiveApi()),
      Provider<GitHubVersionsApi>(create: (_) => GitHubVersionsApi()),
      ChangeNotifierProvider(
        create: (c) => CivitAiBrowserStore(c.read<CivitAiApi>()),
      ),
      ChangeNotifierProvider(
        create: (c) => HuggingFaceBrowserStore(c.read<HuggingFaceApi>()),
      ),
      ChangeNotifierProvider(
        create: (c) => OpenModelDbBrowserStore(c.read<OpenModelDbApi>()),
      ),
      ChangeNotifierProvider(
        create: (c) => CivArchiveBrowserStore(c.read<CivArchiveApi>()),
      ),
      ChangeNotifierProvider(
        create: (_) => InferenceStore(
          defaults: settings.settings,
          onImageGenerated: outputsStore.add,
        ),
      ),
      Provider<VersionChecker>(create: (_) => VersionChecker()),
      ChangeNotifierProvider(
        create: (c) => VersionStore(c.read<VersionChecker>(), () => appVersion),
      ),
    ],
    child: const StableDartApp(),
  );
}
