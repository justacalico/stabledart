import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/console_store.dart';
import '../../state/installed_packages_store.dart';
import 'console_page.dart';
import 'packages_page.dart';

class LaunchPage extends StatefulWidget {
  final String packageId;

  const LaunchPage({super.key, required this.packageId});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  int _webUiPort(dynamic package) {
    for (final arg in package.launchArgs as List) {
      if (arg is Map &&
          (arg['name'] == 'port' || arg['name'] == 'Port') &&
          arg['enabled'] == true) {
        return int.tryParse('${arg['value']}') ?? 7860;
      }
    }
    return 7860;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InstalledPackagesStore>();
    final package = store.byId(widget.packageId);
    if (package == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Package not found')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(package.displayName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: package.isRunning
                      ? () => store.stop(package)
                      : () {
                          final console = context.read<ConsoleStore>();
                          store.launch(package, onOutput: console.log);
                        },
                  icon: Icon(package.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(package.isRunning ? 'Stop' : 'Launch'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => showLaunchOptionsDialog(context, package),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Launch Options'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: package.isRunning
                      ? () => launchUrl(
                          Uri.parse('http://localhost:${_webUiPort(package)}'))
                      : null,
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Open Web UI'),
                ),
              ],
            ),
          ),
          const Expanded(child: ConsoleView()),
        ],
      ),
    );
  }
}
