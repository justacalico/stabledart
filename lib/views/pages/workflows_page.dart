import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/workflows_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class WorkflowsPage extends StatelessWidget {
  const WorkflowsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkflowsStore>();
    return PageScaffold(
      title: 'Workflows',
      actions: [
        FilledButton.icon(
          onPressed: () => _installDialog(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Install Workflow'),
        ),
      ],
      child: store.workflows.isEmpty
          ? EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No Workflows Installed',
              message:
                  'Install ComfyUI workflows to run them in compatible packages.',
              action: FilledButton.icon(
                onPressed: () => _installDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Install Workflow'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: store.workflows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final wf = store.workflows[i];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.surfaceAlt,
                      child: Icon(
                        Icons.account_tree_outlined,
                        color: AppColors.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(wf.name),
                    subtitle: Text(
                      '${wf.baseModel}${wf.author.isNotEmpty ? ' · ${wf.author}' : ''}${wf.requiredNodes.isNotEmpty ? ' · ${wf.requiredNodes.length} nodes' : ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.tonal(
                          onPressed: () {},
                          child: const Text('Open'),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'Remove',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.red,
                          ),
                          onPressed: () => store.remove(wf),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _installDialog(BuildContext context) {
    final store = context.read<WorkflowsStore>();
    final name = TextEditingController();
    final author = TextEditingController();
    var baseModel = 'SD 1.5';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Install Workflow'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Workflow name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: author,
                  decoration: const InputDecoration(labelText: 'Author'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: baseModel,
                  decoration: const InputDecoration(labelText: 'Base model'),
                  items: const [
                    DropdownMenuItem(value: 'SD 1.5', child: Text('SD 1.5')),
                    DropdownMenuItem(value: 'SDXL', child: Text('SDXL')),
                    DropdownMenuItem(value: 'Flux', child: Text('Flux')),
                    DropdownMenuItem(value: 'SD3', child: Text('SD3')),
                  ],
                  onChanged: (v) => setState(() => baseModel = v ?? baseModel),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty) {
                  store.install(
                    name: name.text.trim(),
                    author: author.text.trim(),
                    baseModel: baseModel,
                  );
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Install'),
            ),
          ],
        ),
      ),
    );
  }
}
