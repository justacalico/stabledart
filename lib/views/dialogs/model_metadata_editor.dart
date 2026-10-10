import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/local_model.dart';
import '../../state/model_index_service.dart';

void showModelMetadataEditor(BuildContext context, LocalModelFile model) {
  final index = context.read<ModelIndexService>();
  final title = TextEditingController(text: model.title ?? '');
  final author = TextEditingController(text: model.author ?? '');
  final description = TextEditingController(text: model.description ?? '');
  var category = model.category;
  var shared = model.isShared;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Model Metadata'),
        content: SizedBox(
          width: 440,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: author,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ModelCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in ModelCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.displayName)),
                ],
                onChanged: (v) => setState(() => category = v ?? category),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Shared with all packages')),
                  Switch(
                    value: shared,
                    onChanged: (v) => setState(() => shared = v),
                  ),
                ],
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
              index.updateMetadata(
                model,
                title: title.text.trim(),
                author: author.text.trim(),
                description: description.text.trim(),
                category: category,
                isShared: shared,
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
