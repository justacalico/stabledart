import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class PromptCard extends StatelessWidget {
  const PromptCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Prompt',
      icon: Icons.chat_bubble_outline,
      expanded: store.isCardExpanded('prompt'),
      onToggle: () => store.toggleCard('prompt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prompt',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const ValueKey('prompt-field'),
            initialValue: params.prompt,
            maxLines: 4,
            minLines: 3,
            decoration: const InputDecoration(
              hintText: 'What do you want to generate?',
            ),
            onChanged: (v) => store.updateParams((p) => p.prompt = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Negative Prompt',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          TextFormField(
            key: const ValueKey('negative-prompt-field'),
            initialValue: params.negativePrompt,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'What to exclude from the image',
            ),
            onChanged: (v) => store.updateParams((p) => p.negativePrompt = v),
          ),
        ],
      ),
    );
  }
}
