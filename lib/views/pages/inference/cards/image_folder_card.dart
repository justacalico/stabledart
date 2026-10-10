import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../views/widgets/stack_card.dart';

class ImageFolderCard extends StatelessWidget {
  const ImageFolderCard({super.key});

  static const folders = ['Unsorted', 'txt2img', 'img2img', 'Favorites'];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Output Folder',
      icon: Icons.folder_outlined,
      expanded: store.isCardExpanded('imageFolder'),
      onToggle: () => store.toggleCard('imageFolder'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: folders.first,
            items: [
              for (final f in folders)
                DropdownMenuItem(value: f, child: Text(f)),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Save to shared outputs',
                style: TextStyle(fontSize: 13),
              ),
              const Spacer(),
              Switch(
                value: store.defaults.inferenceSharedOutput,
                onChanged: (_) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
