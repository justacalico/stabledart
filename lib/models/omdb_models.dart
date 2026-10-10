class OpenModelDbModel {
  final String id;
  final String name;
  final String author;
  final String description;
  final List<String> tags;
  final List<String> images;
  final List<String> resources;
  final int scale;
  final String architecture;

  const OpenModelDbModel({
    required this.id,
    required this.name,
    this.author = '',
    this.description = '',
    this.tags = const [],
    this.images = const [],
    this.resources = const [],
    this.scale = 1,
    this.architecture = '',
  });

  String? get thumbnailUrl => images.isNotEmpty ? images.first : null;

  factory OpenModelDbModel.fromJson(String id, Map<String, dynamic> json) {
    final imageList = <String>[];
    final rawImages = json['images'];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img is Map<String, dynamic>) {
          final url = img['SRGB'] is Map<String, dynamic>
              ? ((img['SRGB'] as Map<String, dynamic>)['url'] as String?)
              : img['url'] as String?;
          if (url != null) imageList.add(url);
        } else if (img is String) {
          imageList.add(img);
        }
      }
    }
    final resources = <String>[];
    final rawResources = json['resources'];
    if (rawResources is List) {
      for (final r in rawResources) {
        if (r is Map<String, dynamic>) {
          final urls = r['urls'];
          if (urls is List && urls.isNotEmpty && urls.first is String) {
            resources.add(urls.first as String);
          }
        }
      }
    }
    return OpenModelDbModel(
      id: id,
      name: json['name'] as String? ?? id,
      author: json['author'] is List
          ? (json['author'] as List).whereType<String>().join(', ')
          : json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      images: imageList,
      resources: resources,
      scale: (json['scale'] as num?)?.toInt() ?? 1,
      architecture: json['architecture'] as String? ?? '',
    );
  }
}
