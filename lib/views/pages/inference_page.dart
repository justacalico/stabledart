import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/inference_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'inference/cards.dart';

class InferencePage extends StatelessWidget {
  const InferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: InferenceTab.values.length,
      child: Builder(
        builder: (context) {
          final controller = DefaultTabController.of(context);
          controller.addListener(() {
            if (!controller.indexIsChanging) {
              context.read<InferenceStore>().selectTab(
                InferenceTab.values[controller.index],
              );
            }
          });
          return PageScaffold(
            title: 'Inference',
            headerExtra: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (final t in InferenceTab.values) Tab(text: t.displayName),
              ],
            ),
            child: const _InferenceBody(),
          );
        },
      ),
    );
  }
}

class _InferenceBody extends StatelessWidget {
  const _InferenceBody();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<InferenceStore>();
    final tab = store.tab;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              for (final card in _cardsFor(tab))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: card,
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: store.isGenerating
                              ? AppColors.darkRed
                              : AppColors.accent,
                        ),
                        onPressed: store.isGenerating
                            ? store.cancelGeneration
                            : store.generate,
                        icon: Icon(
                          store.isGenerating ? Icons.stop : Icons.auto_awesome,
                        ),
                        label: Text(store.isGenerating ? 'Cancel' : 'Generate'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (store.isGenerating)
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              value: store.progress,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Expanded(child: ImageGalleryCard()),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _cardsFor(InferenceTab tab) {
    switch (tab) {
      case InferenceTab.textToImage:
        return [
          const PromptCard(),
          const ModelCard(),
          const SamplerCard(),
          const SeedCard(),
          const BatchSizeCard(),
          const ImageFolderCard(),
          const ExtraNetworkCard(),
          const FreeUCard(),
          const RegionalPromptCard(),
          const PromptExpansionCard(),
          const FaceDetailerCard(),
          const TiledVAECard(),
          const RescaleCfgCard(),
          const SharpenCard(),
          const PlasmaNoiseCard(),
          const NrsCard(),
          const DiscreteModelSamplingCard(),
          const CfzCudnnToggleCard(),
          const LayerDiffuseCard(),
        ];
      case InferenceTab.imageToImage:
        return [
          const PromptCard(),
          const SelectImageCard(),
          const ModelCard(),
          const SamplerCard(),
          const SeedCard(),
          const BatchSizeCard(),
          const ImageFolderCard(),
          const ControlNetCard(),
          const ExtraNetworkCard(),
          const FaceDetailerCard(),
          const TiledVAECard(),
        ];
      case InferenceTab.imageToVideo:
        return [
          const PromptCard(),
          const SelectImageCard(),
          const UnetModelCard(),
          const SvdConditioningCard(),
          const WanSamplerCard(),
          const SeedCard(),
          const VideoOutputSettingsCard(),
          const TextEncoderSlotCard(),
        ];
      case InferenceTab.imageUpscale:
        return [
          const SelectImageCard(),
          const UpscalerCard(),
          const ModelCard(),
          const PromptCard(),
          const SamplerCard(),
          const SeedCard(),
        ];
      case InferenceTab.fluxTextToImage:
        return [
          const PromptCard(),
          const UnetModelCard(),
          const TextEncoderSlotCard(),
          const WanSamplerCard(),
          const SeedCard(),
          const BatchSizeCard(),
        ];
      case InferenceTab.wanTextToVideo:
        return [
          const PromptCard(),
          const WanModelCard(),
          const WanSamplerCard(),
          const SeedCard(),
          const VideoOutputSettingsCard(),
        ];
      case InferenceTab.wanImageToVideo:
        return [
          const PromptCard(),
          const SelectImageCard(),
          const WanModelCard(),
          const WanSamplerCard(),
          const SeedCard(),
          const VideoOutputSettingsCard(),
        ];
    }
  }
}
