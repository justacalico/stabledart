import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../views/widgets/number_field.dart';
import '../../../../views/widgets/stack_card.dart';

class BatchSizeCard extends StatelessWidget {
  const BatchSizeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final params = store.params;
    return StackCard(
      title: 'Batch Size',
      icon: Icons.layers,
      expanded: store.isCardExpanded('batch'),
      onToggle: () => store.toggleCard('batch'),
      child: Row(
        children: [
          Expanded(
            child: NumberField(
              label: 'Batch Count',
              value: params.batchCount,
              min: 1,
              max: 100,
              onChanged: (v) => store.updateParams((p) => p.batchCount = v),
            ),
          ),
          Expanded(
            child: NumberField(
              label: 'Batch Size',
              value: params.batchSize,
              min: 1,
              max: 16,
              onChanged: (v) => store.updateParams((p) => p.batchSize = v),
            ),
          ),
        ],
      ),
    );
  }
}
