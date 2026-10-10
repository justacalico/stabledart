import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../views/widgets/stack_card.dart';

class CfzCudnnToggleCard extends StatefulWidget {
  const CfzCudnnToggleCard({super.key});

  @override
  State<CfzCudnnToggleCard> createState() => _CfzCudnnToggleCardState();
}

class _CfzCudnnToggleCardState extends State<CfzCudnnToggleCard> {
  bool enabled = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'CFZ cuDNN Toggle',
      icon: Icons.memory,
      expanded: store.isCardExpanded('cfzCudnn'),
      onToggle: () => store.toggleCard('cfzCudnn'),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Disable cuDNN for CFZ-conditioned sampling. Can help on '
              'some GPU/driver combinations that crash during inference.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Switch(value: enabled, onChanged: (v) => setState(() => enabled = v)),
        ],
      ),
    );
  }
}
