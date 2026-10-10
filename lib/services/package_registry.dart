import '../models/launch_option.dart';
import '../models/package_definition.dart';
import '../theme/app_theme.dart';

List<LaunchOption> _webuiOptions() => [
  LaunchOption.toggle(
    'xformers',
    '--xformers',
    description: 'Enable xformers memory-efficient attention',
  ),
  LaunchOption.toggle(
    'medvram',
    '--medvram',
    description: 'Enable optimizations for low VRAM',
  ),
  LaunchOption.toggle(
    'lowvram',
    '--lowvram',
    description: 'Enable optimizations for very low VRAM',
  ),
  LaunchOption.toggle(
    'api',
    '--api',
    description: 'Launch the WebUI API server',
  ),
  LaunchOption.toggle(
    'no-half',
    '--no-half',
    description: 'Do not switch to half precision',
  ),
  LaunchOption.toggle(
    'autolaunch',
    '--autolaunch',
    description: 'Open the WebUI in a browser on startup',
  ),
  LaunchOption(
    name: 'port',
    flag: '--port',
    description: 'Override the default port (7860)',
  ),
  LaunchOption(
    name: 'listen',
    flag: '--listen',
    description: 'Allow network connections',
    isToggle: true,
  ),
];

List<LaunchOption> _comfyOptions() => [
  LaunchOption.toggle('cpu', '--cpu', description: 'Run on CPU instead of GPU'),
  LaunchOption.toggle(
    'directml',
    '--directml',
    description: 'Use DirectML backend',
  ),
  LaunchOption.toggle('lowvram', '--lowvram', description: 'Low VRAM mode'),
  LaunchOption.toggle('novram', '--novram', description: 'No VRAM mode'),
  LaunchOption(
    name: 'port',
    flag: '--port',
    description: 'Override the default port (8188)',
  ),
  LaunchOption.toggle(
    'listen',
    '--listen',
    description: 'Allow network connections',
  ),
  LaunchOption.toggle(
    'auto-launch',
    '--auto-launch',
    description: 'Open the UI in a browser on startup',
  ),
];

List<LaunchOption> _fooocusOptions() => [
  LaunchOption.toggle(
    'listen',
    '--listen',
    description: 'Allow network connections',
  ),
  LaunchOption(name: 'port', flag: '--port', description: 'Override the port'),
  LaunchOption.toggle(
    'always-cpu',
    '--always-cpu',
    description: 'Force CPU inference',
  ),
  LaunchOption.toggle(
    'always-gpu',
    '--always-gpu',
    description: 'Force GPU inference',
  ),
];

class PackageRegistry {

  static final List<PackageDefinition> all = [
    PackageDefinition(
      name: 'stable-diffusion-webui',
      displayName: 'Stable Diffusion WebUI',
      author: 'AUTOMATIC1111',
      description:
          'The original Stable Diffusion web interface. Feature-rich with txt2img, img2img, extras, and a massive extension ecosystem.',
      repositoryUrl: 'https://github.com/AUTOMATIC1111/stable-diffusion-webui',
      accentColor: AppColors.blue.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'ComfyUI',
      displayName: 'ComfyUI',
      author: 'comfyanonymous',
      description:
          'Powerful node-based interface for Stable Diffusion. Build complex workflows visually with full control over the pipeline.',
      repositoryUrl: 'https://github.com/comfyanonymous/ComfyUI',
      accentColor: AppColors.teal.toARGB32(),
      launchOptions: _comfyOptions,
      tags: ['Inference', 'Nodes'],
    ),
    PackageDefinition(
      name: 'Fooocus',
      displayName: 'Fooocus',
      author: 'lllyasviel',
      description:
          'Simplified Stable Diffusion UI focused on great results with minimal configuration. Prompt-in and image-out.',
      repositoryUrl: 'https://github.com/lllyasviel/Fooocus',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'InvokeAI',
      displayName: 'InvokeAI',
      author: 'invoke-ai',
      description:
          'Professional-grade creative engine for Stable Diffusion with a unified canvas, workflow builder, and model manager.',
      repositoryUrl: 'https://github.com/invoke-ai/InvokeAI',
      accentColor: AppColors.deepPurple.toARGB32(),
      launchOptions: () => [
        LaunchOption.toggle('web', '--web', description: 'Start the web UI'),
      ],
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'StableSwarmUI',
      displayName: 'SwarmUI',
      author: 'mcmonkeyprojects',
      description:
          'Modular Stable Diffusion web UI emphasizing speed, power tools, and easy ComfyUI backend integration.',
      repositoryUrl: 'https://github.com/mcmonkeyprojects/SwarmUI',
      accentColor: AppColors.mediumSeaGreen.toARGB32(),
      launchOptions: () => [
        LaunchOption(
          name: 'port',
          flag: '--port',
          description: 'Override the port',
        ),
        LaunchOption.toggle(
          'launch-mode-none',
          '--launch_mode none',
          description: 'Do not open a browser on launch',
        ),
      ],
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'automatic',
      displayName: 'SD.Next',
      author: 'vladmandic',
      description:
          'Vladmandic\'s fork of the WebUI with a refreshed interface, faster pipelines, and broad backend support.',
      repositoryUrl: 'https://github.com/vladmandic/sdnext',
      accentColor: AppColors.lightBlue.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'stable-diffusion-webui-forge',
      displayName: 'Stable Diffusion WebUI Forge',
      author: 'lllyasviel',
      description:
          'Re-architected WebUI fork with improved memory management and speed, fully compatible with A1111 extensions.',
      repositoryUrl:
          'https://github.com/lllyasviel/stable-diffusion-webui-forge',
      accentColor: AppColors.eldenOrange.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'forge-classic',
      displayName: 'Stable Diffusion WebUI Forge - Classic',
      author: 'Haoming02',
      description:
          'Community continuation of the original Forge feature set with ongoing maintenance and fixes.',
      repositoryUrl: 'https://github.com/Haoming02/sd-webui-forge-classic',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'forge-neo',
      displayName: 'Stable Diffusion WebUI Forge - Neo',
      author: 'Haoming02',
      description:
          'Next-generation Forge branch with expanded model support and performance work.',
      repositoryUrl: 'https://github.com/Haoming02/sd-webui-forge-neo',
      accentColor: AppColors.amber.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'reforge',
      displayName: 'Stable Diffusion WebUI reForge',
      author: 'Panchovix',
      description:
          'reForge combines WebUI features with Forge performance improvements and continued community updates.',
      repositoryUrl:
          'https://github.com/Panchovix/stable-diffusion-webui-reForge',
      accentColor: AppColors.darkRed.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'stable-diffusion-webui-amdgpu-forge',
      displayName: 'Stable Diffusion WebUI AMDGPU Forge',
      author: 'lshqqytiger',
      description:
          'Forge variant tuned for AMD GPUs through ZLUDA and DirectML backends.',
      repositoryUrl:
          'https://github.com/lshqqytiger/stable-diffusion-webui-amdgpu-forge',
      accentColor: AppColors.red.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'AMD'],
    ),
    PackageDefinition(
      name: 'stable-diffusion-webui-directml',
      displayName: 'Stable Diffusion Web UI (DirectML)',
      author: 'lshqqytiger',
      description:
          'WebUI fork targeting DirectML so AMD and integrated GPUs can run inference on Windows.',
      repositoryUrl:
          'https://github.com/lshqqytiger/stable-diffusion-webui-directml',
      accentColor: AppColors.darkRed.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'AMD'],
    ),
    PackageDefinition(
      name: 'stable-diffusion-webui-ux',
      displayName: 'Stable Diffusion Web UI-UX',
      author: 'anapnoe',
      description:
          'Modernized WebUI experience with a rebuilt front end and refined UX.',
      repositoryUrl: 'https://github.com/anapnoe/stable-diffusion-webui-ux',
      accentColor: AppColors.pink.toARGB32(),
      launchOptions: _webuiOptions,
      tags: ['Inference', 'Extensions'],
    ),
    PackageDefinition(
      name: 'ComfyUI-Zluda',
      displayName: 'ComfyUI-Zluda',
      author: 'patientx',
      description:
          'ComfyUI packaged with ZLUDA so AMD GPUs on Windows can run CUDA workloads.',
      repositoryUrl: 'https://github.com/patientx/ComfyUI-Zluda',
      accentColor: AppColors.red.toARGB32(),
      launchOptions: _comfyOptions,
      tags: ['Inference', 'AMD', 'Nodes'],
    ),
    PackageDefinition(
      name: 'Fooocus-MRE',
      displayName: 'Fooocus - MRE',
      author: 'MoonRide303',
      description:
          'MoonRide Edition of Fooocus with extra sampling controls and advanced options.',
      repositoryUrl: 'https://github.com/MoonRide303/Fooocus-MRE',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'mashb1t-fooocus',
      displayName: "Fooocus - mashb1t's 1-Up Edition",
      author: 'mashb1t',
      description:
          'Fooocus fork with quality-of-life features, extra models support, and UI improvements.',
      repositoryUrl: 'https://github.com/mashb1t/Fooocus',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'Fooocus-ControlNet-SDXL',
      displayName: 'Fooocus-ControlNet',
      author: 'fenneishi',
      description:
          'Fooocus build centered on ControlNet SDXL workflows for guided generation.',
      repositoryUrl: 'https://github.com/fenneishi/Fooocus-ControlNet-SDXL',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'RuinedFooocus',
      displayName: 'RuinedFooocus',
      author: 'runew0lf',
      description:
          'Fooocus derivative with experimental features and interface tweaks.',
      repositoryUrl: 'https://github.com/runew0lf/RuinedFooocus',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'SimpleSDXL',
      displayName: 'SimpleSDXL',
      author: 'metercai',
      description:
          'Fooocus-based distribution tuned for SDXL with a simplified experience.',
      repositoryUrl: 'https://github.com/metercai/SimpleSDXL',
      accentColor: AppColors.orange.toARGB32(),
      launchOptions: _fooocusOptions,
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'kohya_ss',
      displayName: 'kohya_ss GUI',
      author: 'bmaltais',
      description:
          'Gradio GUI for kohya\'s sd-scripts: train LoRAs, DreamBooth, and fine-tune diffusion models.',
      repositoryUrl: 'https://github.com/bmaltais/kohya_ss',
      accentColor: AppColors.purple.toARGB32(),
      launchOptions: () => [
        LaunchOption.toggle(
          'headless',
          '--headless',
          description: 'Run without the GUI',
        ),
        LaunchOption(
          name: 'listen',
          flag: '--listen',
          description: 'Listen address',
        ),
      ],
      tags: ['Training'],
    ),
    PackageDefinition(
      name: 'OneTrainer',
      displayName: 'OneTrainer',
      author: 'Nerogar',
      description:
          'All-in-one training solution for Stable Diffusion fine-tunes, LoRAs, embeddings, and more.',
      repositoryUrl: 'https://github.com/Nerogar/OneTrainer',
      accentColor: AppColors.purple.toARGB32(),
      launchOptions: () => [],
      tags: ['Training'],
    ),
    PackageDefinition(
      name: 'ai-toolkit',
      displayName: 'AI-Toolkit',
      author: 'ostris',
      description:
          'Ostris AI Toolkit for training FLUX and SDXL LoRAs with a guided web UI.',
      repositoryUrl: 'https://github.com/ostris/ai-toolkit',
      accentColor: AppColors.purple.toARGB32(),
      launchOptions: () => [],
      tags: ['Training'],
    ),
    PackageDefinition(
      name: 'FluxGym',
      displayName: 'FluxGym',
      author: 'cocktailpeanut',
      description:
          'Dead-simple FLUX LoRA training UI that works on modest GPUs.',
      repositoryUrl: 'https://github.com/cocktailpeanut/fluxgym',
      accentColor: AppColors.purple.toARGB32(),
      launchOptions: () => [],
      tags: ['Training'],
    ),
    PackageDefinition(
      name: 'framepack',
      displayName: 'FramePack',
      author: 'lllyasviel',
      description:
          'Video diffusion generation that packs frame context for long, coherent video on consumer GPUs.',
      repositoryUrl: 'https://github.com/lllyasviel/FramePack',
      accentColor: AppColors.blue.toARGB32(),
      launchOptions: () => [
        LaunchOption.toggle(
          'share',
          '--share',
          description: 'Create a public share link',
        ),
        LaunchOption.toggle(
          'server',
          '--server',
          description: 'Run in server mode',
        ),
      ],
      tags: ['Video'],
    ),
    PackageDefinition(
      name: 'framepack-studio',
      displayName: 'FramePack Studio',
      author: 'colinurbs',
      description:
          'Extended FramePack workspace with batch tools and studio workflow features.',
      repositoryUrl: 'https://github.com/colinurbs/FramePack-Studio',
      accentColor: AppColors.blue.toARGB32(),
      launchOptions: () => [
        LaunchOption.toggle(
          'share',
          '--share',
          description: 'Create a public share link',
        ),
      ],
      tags: ['Video'],
    ),
    PackageDefinition(
      name: 'Wan2GP',
      displayName: 'Wan2GP',
      author: 'deepbeepmeep',
      description:
          'GPU-poor friendly front end for Wan 2.x video models plus other video diffusion models.',
      repositoryUrl: 'https://github.com/deepbeepmeep/Wan2GP',
      accentColor: AppColors.blue.toARGB32(),
      launchOptions: () => [
        LaunchOption.toggle(
          'share',
          '--share',
          description: 'Create a public share link',
        ),
      ],
      tags: ['Video'],
    ),
    PackageDefinition(
      name: 'Cogstudio',
      displayName: 'Cogstudio',
      author: 'pinokiofactory',
      description:
          'CogVideo-based video generation studio packaged for one-click installs.',
      repositoryUrl: 'https://github.com/pinokiofactory/cogstudio',
      accentColor: AppColors.blue.toARGB32(),
      launchOptions: () => [],
      tags: ['Video'],
    ),
    PackageDefinition(
      name: 'sdfx',
      displayName: 'SDFX',
      author: 'sdfxai',
      description:
          'Node-based diffusion playground for prototyping and experimental pipelines.',
      repositoryUrl: 'https://github.com/sdfxai/sdfx',
      accentColor: AppColors.teal.toARGB32(),
      launchOptions: () => [],
      tags: ['Inference', 'Nodes'],
    ),
    PackageDefinition(
      name: 'dank-diffusion',
      displayName: 'Dank Diffusion',
      author: 'mohnjiles',
      description:
          'Standalone diffusion playground with a compact dependency footprint.',
      repositoryUrl: 'https://github.com/LykosAI/StabilityMatrix',
      accentColor: AppColors.mediumSeaGreen.toARGB32(),
      launchOptions: () => [],
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'Fizgig',
      displayName: 'Fizgig',
      author: 'shootthesound',
      description:
          'Experimental generative workspace with an emphasis on rapid iteration.',
      repositoryUrl: 'https://github.com/shootthesound/Fizgig',
      accentColor: AppColors.lightBlue.toARGB32(),
      launchOptions: () => [],
      tags: ['Inference'],
    ),
    PackageDefinition(
      name: 'voltaML-fast-stable-diffusion',
      displayName: 'VoltaML',
      author: 'VoltaML',
      description:
          'Lightweight acceleration library and UI for Stable Diffusion focused on speed.',
      repositoryUrl: 'https://github.com/VoltaML/voltaML-fast-stable-diffusion',
      accentColor: AppColors.mediumSeaGreen.toARGB32(),
      launchOptions: () => [],
      tags: ['Inference'],
    ),
  ];

  static PackageDefinition? byName(String name) {
    for (final def in all) {
      if (def.name == name) return def;
    }
    return null;
  }

  static List<String> get allTags =>
      all.expand((p) => p.tags).toSet().toList()..sort();
}
