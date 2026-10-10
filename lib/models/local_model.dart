enum ModelCategory {
  stableDiffusion,
  lora,
  vae,
  controlnet,
  textualInversion,
  hypernetwork,
  upscaler,
  clipVision,
  diffusionModels,
  clip,
  unet,
  unknown;

  String get displayName => switch (this) {
    ModelCategory.stableDiffusion => 'Stable Diffusion',
    ModelCategory.lora => 'Lora',
    ModelCategory.vae => 'VAE',
    ModelCategory.controlnet => 'ControlNet',
    ModelCategory.textualInversion => 'Textual Inversion',
    ModelCategory.hypernetwork => 'Hypernetwork',
    ModelCategory.upscaler => 'Upscaler',
    ModelCategory.clipVision => 'Clip Vision',
    ModelCategory.diffusionModels => 'Diffusion Models',
    ModelCategory.clip => 'CLIP',
    ModelCategory.unet => 'UNET',
    ModelCategory.unknown => 'Unknown',
  };

  String get folderName => switch (this) {
    ModelCategory.stableDiffusion => 'StableDiffusion',
    ModelCategory.lora => 'Lora',
    ModelCategory.vae => 'VAE',
    ModelCategory.controlnet => 'ControlNet',
    ModelCategory.textualInversion => 'TextualInversion',
    ModelCategory.hypernetwork => 'Hypernetwork',
    ModelCategory.upscaler => 'ESRGAN',
    ModelCategory.clipVision => 'CLIPVision',
    ModelCategory.diffusionModels => 'DiffusionModels',
    ModelCategory.clip => 'CLIP',
    ModelCategory.unet => 'UNET',
    ModelCategory.unknown => 'Unknown',
  };

  static ModelCategory fromName(String? name) => values.firstWhere(
    (c) => c.name == name || c.folderName == name,
    orElse: () => ModelCategory.unknown,
  );
}

class LocalModelFile {
  final String id;
  String fileName;
  String relativePath;
  ModelCategory category;
  int sizeBytes;
  String? sha256;
  String? title;
  String? author;
  String? description;
  String? thumbnailUrl;
  int? civitModelId;
  DateTime modifiedAt;
  bool isShared;

  LocalModelFile({
    required this.id,
    required this.fileName,
    this.relativePath = '',
    this.category = ModelCategory.unknown,
    this.sizeBytes = 0,
    this.sha256,
    this.title,
    this.author,
    this.description,
    this.thumbnailUrl,
    this.civitModelId,
    DateTime? modifiedAt,
    this.isShared = true,
  }) : modifiedAt = modifiedAt ?? DateTime.now();

  String get displayTitle =>
      (title != null && title!.isNotEmpty) ? title! : fileName;

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'relativePath': relativePath,
    'category': category.name,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'title': title,
    'author': author,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'civitModelId': civitModelId,
    'modifiedAt': modifiedAt.toIso8601String(),
    'isShared': isShared,
  };

  factory LocalModelFile.fromJson(Map<String, dynamic> json) => LocalModelFile(
    id: json['id'] as String,
    fileName: json['fileName'] as String? ?? '',
    relativePath: json['relativePath'] as String? ?? '',
    category: ModelCategory.fromName(json['category'] as String?),
    sizeBytes: json['sizeBytes'] as int? ?? 0,
    sha256: json['sha256'] as String?,
    title: json['title'] as String?,
    author: json['author'] as String?,
    description: json['description'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    civitModelId: json['civitModelId'] as int?,
    modifiedAt: DateTime.tryParse(json['modifiedAt'] as String? ?? ''),
    isShared: json['isShared'] as bool? ?? true,
  );
}
