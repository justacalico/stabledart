import '../utils/number_format.dart';

enum AppThemeMode { dark, light, system }

enum NotificationLevel { none, important, all }

enum HolidayMode { off, auto, on }

class AppSettings {
  String dataDirectory;
  String modelsDirectory;
  AppThemeMode themeMode;
  String language;
  NumberFormatMode numberFormat;
  HolidayMode holidayMode;
  bool alwaysShowScrollbars;
  bool discordRichPresence;
  bool autoSearchModelBrowser;
  Set<String> baseModelFilters;
  bool infiniteScrollingWorkflows;
  int consoleHistorySize;
  int maxConcurrentDownloads;
  bool importMoveNotCopy;
  bool removeSymlinksOnShutdown;
  bool showUnsupportedPythonVersions;
  Map<String, String> environmentVariables;
  bool analyticsEnabled;
  bool analyticsOptInSeen;
  bool firstLaunchComplete;
  Map<NotificationLevel, Set<String>> notificationOptions;
  NotificationLevel notificationLevel;
  String? civitAiApiKey;
  String? huggingFaceApiKey;
  String? geminiApiKey;
  String? lykosAccountName;
  bool updateCheckOnLaunch;
  bool updatePrerelease;
  String inferenceModelDirectory;
  bool inferenceSharedOutput;
  int defaultSteps;
  double defaultCfgScale;
  int defaultWidth;
  int defaultHeight;

  AppSettings({
    this.dataDirectory = '',
    this.modelsDirectory = '',
    this.themeMode = AppThemeMode.dark,
    this.language = 'en_US',
    this.numberFormat = NumberFormatMode.comma,
    this.holidayMode = HolidayMode.auto,
    this.alwaysShowScrollbars = false,
    this.discordRichPresence = true,
    this.autoSearchModelBrowser = false,
    Set<String>? baseModelFilters,
    this.infiniteScrollingWorkflows = true,
    this.consoleHistorySize = 300,
    this.maxConcurrentDownloads = 3,
    this.importMoveNotCopy = false,
    this.removeSymlinksOnShutdown = false,
    this.showUnsupportedPythonVersions = false,
    Map<String, String>? environmentVariables,
    this.analyticsEnabled = false,
    this.analyticsOptInSeen = false,
    this.firstLaunchComplete = false,
    Map<NotificationLevel, Set<String>>? notificationOptions,
    this.notificationLevel = NotificationLevel.all,
    this.civitAiApiKey,
    this.huggingFaceApiKey,
    this.geminiApiKey,
    this.lykosAccountName,
    this.updateCheckOnLaunch = true,
    this.updatePrerelease = false,
    this.inferenceModelDirectory = '',
    this.inferenceSharedOutput = true,
    this.defaultSteps = 20,
    this.defaultCfgScale = 7.0,
    this.defaultWidth = 512,
    this.defaultHeight = 512,
  }) : baseModelFilters = baseModelFilters ?? {},
       environmentVariables = environmentVariables ?? {},
       notificationOptions = notificationOptions ?? {};

  Map<String, dynamic> toJson() => {
    'dataDirectory': dataDirectory,
    'modelsDirectory': modelsDirectory,
    'themeMode': themeMode.name,
    'language': language,
    'numberFormat': numberFormat.name,
    'holidayMode': holidayMode.name,
    'alwaysShowScrollbars': alwaysShowScrollbars,
    'discordRichPresence': discordRichPresence,
    'autoSearchModelBrowser': autoSearchModelBrowser,
    'baseModelFilters': baseModelFilters.toList(),
    'infiniteScrollingWorkflows': infiniteScrollingWorkflows,
    'consoleHistorySize': consoleHistorySize,
    'maxConcurrentDownloads': maxConcurrentDownloads,
    'importMoveNotCopy': importMoveNotCopy,
    'removeSymlinksOnShutdown': removeSymlinksOnShutdown,
    'showUnsupportedPythonVersions': showUnsupportedPythonVersions,
    'environmentVariables': environmentVariables,
    'analyticsEnabled': analyticsEnabled,
    'analyticsOptInSeen': analyticsOptInSeen,
    'firstLaunchComplete': firstLaunchComplete,
    'notificationLevel': notificationLevel.name,
    'civitAiApiKey': civitAiApiKey,
    'huggingFaceApiKey': huggingFaceApiKey,
    'geminiApiKey': geminiApiKey,
    'lykosAccountName': lykosAccountName,
    'updateCheckOnLaunch': updateCheckOnLaunch,
    'updatePrerelease': updatePrerelease,
    'inferenceModelDirectory': inferenceModelDirectory,
    'inferenceSharedOutput': inferenceSharedOutput,
    'defaultSteps': defaultSteps,
    'defaultCfgScale': defaultCfgScale,
    'defaultWidth': defaultWidth,
    'defaultHeight': defaultHeight,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    dataDirectory: json['dataDirectory'] as String? ?? '',
    modelsDirectory: json['modelsDirectory'] as String? ?? '',
    themeMode: AppThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => AppThemeMode.dark,
    ),
    language: json['language'] as String? ?? 'en_US',
    numberFormat: NumberFormatMode.fromName(json['numberFormat'] as String?),
    holidayMode: HolidayMode.values.firstWhere(
      (m) => m.name == json['holidayMode'],
      orElse: () => HolidayMode.auto,
    ),
    alwaysShowScrollbars: json['alwaysShowScrollbars'] as bool? ?? false,
    discordRichPresence: json['discordRichPresence'] as bool? ?? true,
    autoSearchModelBrowser: json['autoSearchModelBrowser'] as bool? ?? false,
    baseModelFilters: (json['baseModelFilters'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toSet(),
    infiniteScrollingWorkflows:
        json['infiniteScrollingWorkflows'] as bool? ?? true,
    consoleHistorySize: json['consoleHistorySize'] as int? ?? 300,
    maxConcurrentDownloads: json['maxConcurrentDownloads'] as int? ?? 3,
    importMoveNotCopy: json['importMoveNotCopy'] as bool? ?? false,
    removeSymlinksOnShutdown:
        json['removeSymlinksOnShutdown'] as bool? ?? false,
    showUnsupportedPythonVersions:
        json['showUnsupportedPythonVersions'] as bool? ?? false,
    environmentVariables:
        (json['environmentVariables'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, v.toString()),
        ),
    analyticsEnabled: json['analyticsEnabled'] as bool? ?? false,
    analyticsOptInSeen: json['analyticsOptInSeen'] as bool? ?? false,
    firstLaunchComplete: json['firstLaunchComplete'] as bool? ?? false,
    notificationLevel: NotificationLevel.values.firstWhere(
      (m) => m.name == json['notificationLevel'],
      orElse: () => NotificationLevel.all,
    ),
    civitAiApiKey: json['civitAiApiKey'] as String?,
    huggingFaceApiKey: json['huggingFaceApiKey'] as String?,
    geminiApiKey: json['geminiApiKey'] as String?,
    lykosAccountName: json['lykosAccountName'] as String?,
    updateCheckOnLaunch: json['updateCheckOnLaunch'] as bool? ?? true,
    updatePrerelease: json['updatePrerelease'] as bool? ?? false,
    inferenceModelDirectory: json['inferenceModelDirectory'] as String? ?? '',
    inferenceSharedOutput: json['inferenceSharedOutput'] as bool? ?? true,
    defaultSteps: json['defaultSteps'] as int? ?? 20,
    defaultCfgScale: (json['defaultCfgScale'] as num?)?.toDouble() ?? 7.0,
    defaultWidth: json['defaultWidth'] as int? ?? 512,
    defaultHeight: json['defaultHeight'] as int? ?? 512,
  );
}
