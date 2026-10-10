class OutputImage {
  final String id;
  final String filePath;
  final String packageName;
  final String prompt;
  final String negativePrompt;
  final int seed;
  final String sampler;
  final int steps;
  final double cfgScale;
  final int width;
  final int height;
  final DateTime createdAt;

  const OutputImage({
    required this.id,
    required this.filePath,
    this.packageName = '',
    this.prompt = '',
    this.negativePrompt = '',
    this.seed = 0,
    this.sampler = '',
    this.steps = 0,
    this.cfgScale = 0,
    this.width = 0,
    this.height = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'filePath': filePath,
    'packageName': packageName,
    'prompt': prompt,
    'negativePrompt': negativePrompt,
    'seed': seed,
    'sampler': sampler,
    'steps': steps,
    'cfgScale': cfgScale,
    'width': width,
    'height': height,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OutputImage.fromJson(Map<String, dynamic> json) => OutputImage(
    id: json['id'] as String,
    filePath: json['filePath'] as String? ?? '',
    packageName: json['packageName'] as String? ?? '',
    prompt: json['prompt'] as String? ?? '',
    negativePrompt: json['negativePrompt'] as String? ?? '',
    seed: json['seed'] as int? ?? 0,
    sampler: json['sampler'] as String? ?? '',
    steps: json['steps'] as int? ?? 0,
    cfgScale: (json['cfgScale'] as num?)?.toDouble() ?? 0,
    width: json['width'] as int? ?? 0,
    height: json['height'] as int? ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
