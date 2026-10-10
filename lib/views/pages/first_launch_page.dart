import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/settings_manager.dart';
import '../../theme/app_theme.dart';

class FirstLaunchPage extends StatefulWidget {
  const FirstLaunchPage({super.key});

  @override
  State<FirstLaunchPage> createState() => _FirstLaunchPageState();
}

class _FirstLaunchPageState extends State<FirstLaunchPage> {
  int _step = 0;
  bool _portableMode = true;
  bool _analytics = false;
  final _dirController = TextEditingController(text: '~/StabilityMatrix');

  @override
  void dispose() {
    _dirController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<SettingsManager>().update((s) {
      s.dataDirectory = _dirController.text.trim();
      s.analyticsEnabled = _analytics;
      s.analyticsOptInSeen = true;
      s.firstLaunchComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: switch (_step) {
                0 => _welcome(),
                1 => _dataDirectory(),
                _ => _analyticsStep(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.dashboard_customize,
          size: 64,
          color: AppColors.accent,
        ),
        const SizedBox(height: 20),
        const Text(
          'Welcome to Stability Matrix',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'A multi-platform package manager and inference UI for '
          'Stable Diffusion. Install, launch, and extend packages like '
          'Automatic1111, ComfyUI, Fooocus, and more.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Get Started'),
        ),
      ],
    );
  }

  Widget _dataDirectory() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a Data Directory',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Packages, models, and outputs live here. A portable '
          'install keeps everything in the app folder; a standard '
          'install uses your user data folder.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            ChoiceChip(
              label: const Text('Portable'),
              selected: _portableMode,
              onSelected: (_) => setState(() {
                _portableMode = true;
                _dirController.text = '~/StabilityMatrix';
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Standard'),
              selected: !_portableMode,
              onSelected: (_) => setState(() {
                _portableMode = false;
                _dirController.text = '~/.local/share/StabilityMatrix';
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _dirController,
          decoration: const InputDecoration(labelText: 'Data directory'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _analyticsStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.analytics_outlined, size: 48, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text(
          'Help improve Stability Matrix?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Anonymous usage analytics help prioritize features and '
          'fix crashes faster. No personal data, prompts, or file '
          'contents are ever collected.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable analytics'),
          value: _analytics,
          onChanged: (v) => setState(() => _analytics = v),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Back'),
            ),
            FilledButton(onPressed: _finish, child: const Text('Finish Setup')),
          ],
        ),
      ],
    );
  }
}
