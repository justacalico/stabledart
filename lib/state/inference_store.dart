import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/output_image.dart';

enum InferenceTab {
  textToImage,
  imageToImage,
  imageToVideo,
  imageUpscale,
  fluxTextToImage,
  wanTextToVideo,
  wanImageToVideo;

  String get displayName => switch (this) {
    InferenceTab.textToImage => 'Text to Image',
    InferenceTab.imageToImage => 'Image to Image',
    InferenceTab.imageToVideo => 'Image to Video',
    InferenceTab.imageUpscale => 'Image Upscale',
    InferenceTab.fluxTextToImage => 'Flux Text to Image',
    InferenceTab.wanTextToVideo => 'Wan Text to Video',
    InferenceTab.wanImageToVideo => 'Wan Image to Video',
  };
}

class GenerationParams {
  String prompt;
  String negativePrompt;
  String model;
  String sampler;
  String scheduler;
  int steps;
  double cfgScale;
  int seed;
  int width;
  int height;
  int batchSize;
  int batchCount;
  double denoiseStrength;
  String? inputImagePath;
  double clipSkip;
  String upscaler;
  double upscaleFactor;
  int frameCount;
  int fps;
  bool highResFix;
  bool tiling;

  GenerationParams({
    this.prompt = '',
    this.negativePrompt = '',
    this.model = '',
    this.sampler = 'Euler a',
    this.scheduler = 'Normal',
    this.steps = 20,
    this.cfgScale = 7.0,
    this.seed = -1,
    this.width = 512,
    this.height = 512,
    this.batchSize = 1,
    this.batchCount = 1,
    this.denoiseStrength = 0.6,
    this.inputImagePath,
    this.clipSkip = 1,
    this.upscaler = 'ESRGAN 4x',
    this.upscaleFactor = 2.0,
    this.frameCount = 16,
    this.fps = 8,
    this.highResFix = false,
    this.tiling = false,
  });

  GenerationParams copy() => GenerationParams(
    prompt: prompt,
    negativePrompt: negativePrompt,
    model: model,
    sampler: sampler,
    scheduler: scheduler,
    steps: steps,
    cfgScale: cfgScale,
    seed: seed,
    width: width,
    height: height,
    batchSize: batchSize,
    batchCount: batchCount,
    denoiseStrength: denoiseStrength,
    inputImagePath: inputImagePath,
    clipSkip: clipSkip,
    upscaler: upscaler,
    upscaleFactor: upscaleFactor,
    frameCount: frameCount,
    fps: fps,
    highResFix: highResFix,
    tiling: tiling,
  );
}

abstract class InferenceBackend {
  Stream<double> generate(GenerationParams params);
}

class MockInferenceBackend implements InferenceBackend {
  final Duration stepDelay;
  final int ticks;

  MockInferenceBackend({
    this.stepDelay = const Duration(milliseconds: 1),
    this.ticks = 10,
  });

  @override
  Stream<double> generate(GenerationParams params) async* {
    for (var i = 1; i <= ticks; i++) {
      if (stepDelay > Duration.zero) await Future.delayed(stepDelay);
      yield i / ticks;
    }
  }
}

class InferenceStore extends ChangeNotifier {
  final InferenceBackend backend;
  final AppSettings defaults;
  final void Function(OutputImage) onImageGenerated;

  InferenceTab _tab = InferenceTab.textToImage;
  bool _isGenerating = false;
  double _progress = 0;
  String _statusText = 'Idle';
  final List<OutputImage> _gallery = [];
  final Map<String, bool> _cardExpanded = {};
  final Map<InferenceTab, GenerationParams> _params = {};
  StreamSubscription<double>? _generationSub;
  Completer<void>? _generationCompleter;
  int _imageCounter = 0;

  static const samplers = [
    'Euler a',
    'Euler',
    'LMS',
    'Heun',
    'DPM2',
    'DPM2 a',
    'DPM++ 2S a',
    'DPM++ 2M',
    'DPM++ SDE',
    'DPM fast',
    'DPM adaptive',
    'DDIM',
    'PLMS',
    'UniPC',
    'DPM++ 2M SDE',
    'DPM++ 3M SDE',
    'Restart',
  ];

  static const schedulers = [
    'Normal',
    'Karras',
    'Exponential',
    'SGM Uniform',
    'Simple',
    'DDIM Uniform',
    'Beta',
  ];

  static const upscalers = [
    'ESRGAN 4x',
    'R-ESRGAN 4x+',
    'R-ESRGAN 4x+ Anime6B',
    'SwinIR 4x',
    'LDSR',
    'Nearest',
    'Lanczos',
  ];

  static const models = [
    'v1-5-pruned-emaonly.safetensors',
    'sd_xl_base_1.0.safetensors',
    'sd_xl_refiner_1.0.safetensors',
    'flux1-dev.safetensors',
    'flux1-schnell.safetensors',
    'sd3_medium.safetensors',
    'wan2.1_t2v_1.3B.safetensors',
    'ponyDiffusionV6XL.safetensors',
    'dreamshaper_8.safetensors',
    'realisticVisionV51.safetensors',
  ];

  InferenceStore({
    InferenceBackend? backend,
    required this.defaults,
    void Function(OutputImage)? onImageGenerated,
  }) : backend = backend ?? MockInferenceBackend(),
       onImageGenerated = onImageGenerated ?? ((_) {});

  InferenceTab get tab => _tab;
  bool get isGenerating => _isGenerating;
  double get progress => _progress;
  String get statusText => _statusText;
  List<OutputImage> get gallery => List.unmodifiable(_gallery);
  GenerationParams get params => _params.putIfAbsent(_tab, () {
    final p = GenerationParams(
      steps: defaults.defaultSteps,
      cfgScale: defaults.defaultCfgScale,
      width: defaults.defaultWidth,
      height: defaults.defaultHeight,
      model: models.first,
    );
    return p;
  });

  bool isCardExpanded(String key) => _cardExpanded[key] ?? true;

  void toggleCard(String key) {
    _cardExpanded[key] = !isCardExpanded(key);
    notifyListeners();
  }

  void selectTab(InferenceTab tab) {
    _tab = tab;
    notifyListeners();
  }

  void updateParams(void Function(GenerationParams) mutate) {
    mutate(params);
    notifyListeners();
  }

  void randomizeSeed() {
    params.seed = DateTime.now().microsecondsSinceEpoch % 4294967295;
    notifyListeners();
  }

  Future<void> generate() async {
    if (_isGenerating) return;
    _isGenerating = true;
    _progress = 0;
    _statusText = 'Generating...';
    notifyListeners();
    final current = params.copy();
    final completer = Completer<void>();
    _generationCompleter = completer;
    _generationSub = backend
        .generate(current)
        .listen(
          (value) {
            _progress = value;
            _statusText = 'Generating ${(value * 100).round()}%';
            notifyListeners();
          },
          onDone: () {
            _isGenerating = false;
            _progress = 0;
            _statusText = 'Idle';
            final seed = current.seed < 0
                ? (++_imageCounter * 7919)
                : current.seed;
            final image = OutputImage(
              id: 'out-${DateTime.now().microsecondsSinceEpoch}',
              filePath: 'outputs/${_tab.name}/$seed.png',
              packageName: 'Inference',
              prompt: current.prompt,
              negativePrompt: current.negativePrompt,
              seed: seed,
              sampler: current.sampler,
              steps: current.steps,
              cfgScale: current.cfgScale,
              width: current.width,
              height: current.height,
              createdAt: DateTime.now(),
            );
            _gallery.insert(0, image);
            onImageGenerated(image);
            notifyListeners();
            completer.complete();
          },
          onError: (Object e) {
            _isGenerating = false;
            _statusText = 'Error: $e';
            notifyListeners();
            completer.complete();
          },
          cancelOnError: true,
        );
    await completer.future;
  }

  void cancelGeneration() {
    _generationSub?.cancel();
    _generationSub = null;
    _isGenerating = false;
    _statusText = 'Cancelled';
    final completer = _generationCompleter;
    _generationCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    notifyListeners();
  }

  void clearGallery() {
    _gallery.clear();
    notifyListeners();
  }
}
