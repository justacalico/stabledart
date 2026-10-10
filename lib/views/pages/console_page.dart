import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/console_entry.dart';
import '../../state/console_store.dart';
import '../../theme/app_theme.dart';

class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Console')),
      body: const ConsoleView(),
    );
  }
}

class ConsoleView extends StatefulWidget {
  const ConsoleView({super.key});

  @override
  State<ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<ConsoleView> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final atBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 40;
      if (atBottom != _autoScroll) {
        setState(() => _autoScroll = atBottom);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final console = context.watch<ConsoleStore>();
    if (_autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surface,
          child: Row(
            children: [
              Text(
                '${console.entries.length} lines',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Copy all',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: console.entries.map((e) => e.text).join('\n'),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied console output')),
                  );
                },
              ),
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.delete_sweep, size: 18),
                onPressed: console.clear,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: console.isEmpty
              ? const Center(
                  child: Text(
                    'No console output',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: console.entries.length,
                  itemBuilder: (context, i) {
                    final entry = console.entries[i];
                    return Text(
                      entry.text,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: switch (entry.level) {
                          ConsoleLevel.error => AppColors.red,
                          ConsoleLevel.warning => AppColors.orange,
                          ConsoleLevel.debug => AppColors.textSecondary,
                          ConsoleLevel.info => AppColors.text,
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
