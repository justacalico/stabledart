import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../state/inference_store.dart';
import '../../../../views/widgets/stack_card.dart';

class ExtraNetworkCard extends StatelessWidget {
  const ExtraNetworkCard({super.key});

  static const networks = [
    'add-detail-xl',
    'Detail Tweaker',
    'EpiNoiseOffset',
    'LowRA',
    'Polyhedron Skin',
    'Style-Hamunaptra',
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    return StackCard(
      title: 'Extra Networks',
      icon: Icons.hub_outlined,
      expanded: store.isCardExpanded('extraNetworks'),
      onToggle: () => store.toggleCard('extraNetworks'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final n in networks)
            ActionChip(
              avatar: const Icon(Icons.add, size: 14),
              label: Text(n, style: const TextStyle(fontSize: 12)),
              onPressed: () {
                store.updateParams(
                  (p) => p.prompt = '${p.prompt}<lora:$n:1> '.trim(),
                );
              },
            ),
        ],
      ),
    );
  }
}
