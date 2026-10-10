enum CivitSort {
  highestRated,
  mostDownloaded,
  mostLiked,
  mostDiscussed,
  newest,
  oldest,
}

enum CivitPeriod { allTime, year, month, week, day }

enum CivitModelType {
  all,
  checkpoint,
  textualInversion,
  hypernetwork,
  aestheticGradient,
  lora,
  locon,
  controlnet,
  upscaler,
  motionModule,
  vae,
  poses,
  wildcards,
  workflows,
  other;

  String get apiValue => switch (this) {
    CivitModelType.all => '',
    CivitModelType.checkpoint => 'Checkpoint',
    CivitModelType.textualInversion => 'TextualInversion',
    CivitModelType.hypernetwork => 'Hypernetwork',
    CivitModelType.aestheticGradient => 'AestheticGradient',
    CivitModelType.lora => 'LORA',
    CivitModelType.locon => 'LoCon',
    CivitModelType.controlnet => 'Controlnet',
    CivitModelType.upscaler => 'Upscaler',
    CivitModelType.motionModule => 'MotionModule',
    CivitModelType.vae => 'VAE',
    CivitModelType.poses => 'Poses',
    CivitModelType.wildcards => 'Wildcards',
    CivitModelType.workflows => 'Workflows',
    CivitModelType.other => 'Other',
  };

  String get displayName => switch (this) {
    CivitModelType.all => 'All',
    CivitModelType.textualInversion => 'Textual Inversion',
    CivitModelType.aestheticGradient => 'Aesthetic Gradient',
    CivitModelType.lora => 'LORA',
    CivitModelType.locon => 'LoCon',
    CivitModelType.controlnet => 'ControlNet',
    CivitModelType.motionModule => 'Motion Module',
    CivitModelType.vae => 'VAE',
    _ => name[0].toUpperCase() + name.substring(1),
  };
}

class CivitImage {
  final int id;
  final String url;
  final bool nsfw;
  final int width;
  final int height;

  const CivitImage({
    required this.id,
    required this.url,
    this.nsfw = false,
    this.width = 0,
    this.height = 0,
  });

  factory CivitImage.fromJson(Map<String, dynamic> json) => CivitImage(
    id: json['id'] as int? ?? 0,
    url: json['url'] as String? ?? '',
    nsfw: json['nsfw'] as bool? ?? false,
    width: json['width'] as int? ?? 0,
    height: json['height'] as int? ?? 0,
  );
}

class CivitModelFile {
  final int id;
  final String name;
  final int sizeKb;
  final String downloadUrl;
  final String sha256;
  final bool primary;

  const CivitModelFile({
    required this.id,
    required this.name,
    required this.sizeKb,
    required this.downloadUrl,
    this.sha256 = '',
    this.primary = false,
  });

  int get sizeBytes => sizeKb * 1024;

  factory CivitModelFile.fromJson(Map<String, dynamic> json) {
    final hashes = json['hashes'];
    var sha = '';
    if (hashes is Map<String, dynamic>) {
      sha = hashes['SHA256'] as String? ?? '';
    }
    return CivitModelFile(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sizeKb: ((json['sizeKB'] as num?) ?? 0).round(),
      downloadUrl: json['downloadUrl'] as String? ?? '',
      sha256: sha,
      primary: json['primary'] as bool? ?? false,
    );
  }
}

class CivitModelVersion {
  final int id;
  final String name;
  final String baseModel;
  final String? description;
  final List<CivitModelFile> files;
  final List<CivitImage> images;
  final int downloadCount;
  final double rating;

  const CivitModelVersion({
    required this.id,
    required this.name,
    this.baseModel = '',
    this.description,
    this.files = const [],
    this.images = const [],
    this.downloadCount = 0,
    this.rating = 0,
  });

  factory CivitModelVersion.fromJson(Map<String, dynamic> json) =>
      CivitModelVersion(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        baseModel: json['baseModel'] as String? ?? '',
        description: json['description'] as String?,
        files: (json['files'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CivitModelFile.fromJson)
            .toList(),
        images: (json['images'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CivitImage.fromJson)
            .toList(),
        downloadCount: json['downloadCount'] as int? ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
      );
}

class CivitModel {
  final int id;
  final String name;
  final String type;
  final String creator;
  final String? description;
  final List<String> tags;
  final List<CivitModelVersion> versions;
  final int downloadCount;
  final int favoriteCount;
  final int commentCount;
  final double rating;
  final bool nsfw;

  const CivitModel({
    required this.id,
    required this.name,
    this.type = '',
    this.creator = '',
    this.description,
    this.tags = const [],
    this.versions = const [],
    this.downloadCount = 0,
    this.favoriteCount = 0,
    this.commentCount = 0,
    this.rating = 0,
    this.nsfw = false,
  });

  String? get thumbnailUrl =>
      versions.isNotEmpty && versions.first.images.isNotEmpty
      ? versions.first.images.first.url
      : null;

  factory CivitModel.fromJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return CivitModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      creator: creator is Map<String, dynamic>
          ? creator['username'] as String? ?? ''
          : '',
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      versions: (json['modelVersions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CivitModelVersion.fromJson)
          .toList(),
      downloadCount:
          (json['stats'] is Map<String, dynamic>
                  ? (json['stats'] as Map<String, dynamic>)['downloadCount']
                  : null)
              as int? ??
          0,
      favoriteCount:
          (json['stats'] is Map<String, dynamic>
                  ? (json['stats'] as Map<String, dynamic>)['favoriteCount']
                  : null)
              as int? ??
          0,
      commentCount:
          (json['stats'] is Map<String, dynamic>
                  ? (json['stats'] as Map<String, dynamic>)['commentCount']
                  : null)
              as int? ??
          0,
      rating:
          (json['stats'] is Map<String, dynamic>
              ? ((json['stats'] as Map<String, dynamic>)['rating'] as num?)
                    ?.toDouble()
              : null) ??
          0,
      nsfw: json['nsfw'] as bool? ?? false,
    );
  }
}
