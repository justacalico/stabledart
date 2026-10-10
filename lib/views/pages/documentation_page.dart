import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class _DocEntry {
  final String title;
  final String body;
  const _DocEntry(this.title, this.body);
}

class DocumentationPage extends StatefulWidget {
  const DocumentationPage({super.key});

  static const sections = <String, List<_DocEntry>>{
    'Getting Started': [
      _DocEntry(
        'Installation',
        'Download the release for your platform, extract it, and run Stability Matrix. On first launch pick a data directory where packages and models will be stored.',
      ),
      _DocEntry(
        'Installing Packages',
        'Open the Packages page and click Add Package to browse supported packages. Pick a version and press Install. Stability Matrix handles Python environments, dependencies, and model linking automatically.',
      ),
      _DocEntry(
        'Launching',
        'Press Launch on an installed package to start it with your saved launch options. The console streams its output and the Open Web UI button opens the interface once it is up.',
      ),
    ],
    'Inference': [
      _DocEntry(
        'Text to Image',
        'Write a prompt, choose a checkpoint, sampler, seed, and dimensions, then press Generate. Negative prompts exclude concepts from the image.',
      ),
      _DocEntry(
        'Image to Image',
        'Supply an input image and a denoise strength. Lower values preserve the original image; higher values reimagine it.',
      ),
      _DocEntry(
        'Video Generation',
        'Wan and SVD pipelines turn prompts or still images into short videos. Frame count, fps, and format live in the Video Output card.',
      ),
    ],
    'Models': [
      _DocEntry(
        'Model Browser',
        'Search CivitAI, CivArchive, HuggingFace, and OpenModelDB without leaving the app. Downloads land in the shared Models folder and are available to every package.',
      ),
      _DocEntry(
        'Model Manager',
        'The Model Manager indexes everything in your Models folder by category. Edit metadata, assign categories, or remove files.',
      ),
      _DocEntry(
        'Importing',
        'Use Import Model to register existing safetensors, checkpoints, and LoRAs. Choose whether files are copied or moved in Settings.',
      ),
    ],
    'Reference': [
      _DocEntry(
        'Launch Options',
        'Each package exposes command-line flags like --xformers, --medvram, and --port. Configure them per install from the launch options dialog.',
      ),
      _DocEntry(
        'Shared Models',
        'Models are stored once and linked into every package, so you never download the same checkpoint twice.',
      ),
    ],
  };

  @override
  State<DocumentationPage> createState() => _DocumentationPageState();
}

class _DocumentationPageState extends State<DocumentationPage> {
  _DocEntry? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return PageScaffold(
      title: 'Documentation',
      child: Row(
        children: [
          Container(
            width: 260,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final section in DocumentationPage.sections.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                    child: Text(
                      section.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  for (final entry in section.value)
                    Material(
                      color: _selected == entry
                          ? AppColors.surfaceAlt
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => setState(() => _selected = entry),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            entry.title,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            child: selected == null
                ? const Center(
                    child: Text(
                      'Select a topic',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(28),
                    children: [
                      Text(
                        selected.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(selected.body, style: const TextStyle(height: 1.6)),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://github.com/LykosAI/StabilityMatrix/wiki',
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Open the full wiki on GitHub'),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
