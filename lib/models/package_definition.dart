import 'launch_option.dart';

class PackageDefinition {
  final String name;
  final String displayName;
  final String author;
  final String description;
  final String repositoryUrl;
  final String previewAsset;
  final int accentColor;
  final List<LaunchOption> Function() launchOptions;
  final List<String> tags;
  final String baseImageModel;

  const PackageDefinition({
    required this.name,
    required this.displayName,
    required this.author,
    required this.description,
    required this.repositoryUrl,
    required this.accentColor,
    required this.launchOptions,
    this.previewAsset = '',
    this.tags = const [],
    this.baseImageModel = 'SD 1.5',
  });
}
