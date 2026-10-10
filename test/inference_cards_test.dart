import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stabledart/state/inference_store.dart';
import 'package:stabledart/views/pages/inference/cards.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  Future<void> pumpCard(WidgetTester tester, Widget card,
      {Size size = const Size(800, 2000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
        TestProviders.wrap(SingleChildScrollView(child: card)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
  }

  testWidgets('PromptCard edits prompts', (tester) async {
    await pumpCard(tester, const PromptCard());
    await tester.enterText(
        find.byKey(const ValueKey('prompt-field')), 'a castle');
    await tester.enterText(
        find.byKey(const ValueKey('negative-prompt-field')), 'blur');
    await tester.pump();
    expect(find.text('a castle'), findsOneWidget);
  });

  testWidgets('ModelCard dropdown and clip skip', (tester) async {
    await pumpCard(tester, const ModelCard());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('sd_xl_base_1.0.safetensors').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('SamplerCard all controls', (tester) async {
    await pumpCard(tester, const SamplerCard());
    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('DPM++ 2M').last);
    await tester.pumpAndSettle();
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karras').last);
    await tester.pumpAndSettle();
    for (final slider in find.byType(Slider).evaluate().toList()) {
      await tester.drag(
          find.byWidget(slider.widget), const Offset(50, 0));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < find.byIcon(Icons.add).evaluate().length; i++) {
      await tester.tap(find.byIcon(Icons.add).at(i));
      await tester.pump();
    }
    for (var i = 0; i < find.byIcon(Icons.remove).evaluate().length; i++) {
      await tester.tap(find.byIcon(Icons.remove).at(i));
      await tester.pump();
    }
    await tester.enterText(find.byType(TextFormField).first, '700');
    await tester.pump();
  });

  testWidgets('SeedCard interactions', (tester) async {
    await pumpCard(tester, const SeedCard());
    await tester.enterText(find.byType(TextFormField), '12345');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.casino));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pump();
  });

  testWidgets('BatchSizeCard +/- and text input', (tester) async {
    await pumpCard(tester, const BatchSizeCard());
    for (var i = 0; i < find.byIcon(Icons.add).evaluate().length; i++) {
      await tester.tap(find.byIcon(Icons.add).at(i));
      await tester.pump();
    }
    for (var i = 0; i < find.byIcon(Icons.remove).evaluate().length; i++) {
      await tester.tap(find.byIcon(Icons.remove).at(i));
      await tester.pump();
    }
    await tester.enterText(find.byType(TextFormField).first, '5');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'x');
    await tester.pump();
  });

  testWidgets('SelectImageCard pick and clear', (tester) async {
    await pumpCard(tester, const SelectImageCard());
    expect(find.textContaining('Drop an image'), findsOneWidget);
    await tester.tap(find.textContaining('Drop an image'));
    await tester.pumpAndSettle();
    expect(find.text('input/selected-image.png'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('ImageFolderCard', (tester) async {
    await pumpCard(tester, const ImageFolderCard());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favorites').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
  });

  testWidgets('ImageGalleryCard empty and populated', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final sm = TestProviders.memorySettings();
    final inf = InferenceStore(
        defaults: sm.settings,
        backend: MockInferenceBackend(stepDelay: Duration.zero));
    await tester.pumpWidget(TestProviders.wrap(
        const SizedBox(height: 800, child: ImageGalleryCard()),
        settings: sm,
        inference: inf));
    await tester.pumpAndSettle();
    expect(find.textContaining('appear here'), findsOneWidget);
    final store = tester
        .element(find.byType(ImageGalleryCard))
        .read<InferenceStore>();
    store.updateParams((p) => p.prompt = 'cat');
    await store.generate();
    await tester.pumpAndSettle();
    expect(find.text('cat'), findsOneWidget);
    await tester.tap(find.text('cat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('seed'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    expect(find.textContaining('appear here'), findsOneWidget);
  });

  testWidgets('ExtraNetworkCard adds lora tag', (tester) async {
    await pumpCard(tester, const ExtraNetworkCard());
    await tester.tap(find.text('add-detail-xl'));
    await tester.pump();
    final element = tester.element(find.byType(ExtraNetworkCard));
    final store = element.read<InferenceStore>();
    expect(store.params.prompt, contains('<lora:add-detail-xl:1>'));
  });

  testWidgets('ControlNetCard', (tester) async {
    await pumpCard(tester, const ControlNetCard());
    final dds = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dds.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('control_v11p_sd15_depth').last);
    await tester.pumpAndSettle();
    await tester.tap(dds.last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('canny').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(30, 0));
    await tester.pumpAndSettle();
  });

  testWidgets('UpscalerCard', (tester) async {
    await pumpCard(tester, const UpscalerCard());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SwinIR 4x').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
  });

  group('toggle cards', () {
    for (final (name, card) in [
      ('FreeU', const FreeUCard()),
      ('FaceDetailer', const FaceDetailerCard()),
      ('TiledVAE', const TiledVAECard()),
      ('RegionalPrompt', const RegionalPromptCard()),
      ('PromptExpansion', const PromptExpansionCard()),
      ('RescaleCfg', const RescaleCfgCard()),
      ('Sharpen', const SharpenCard()),
      ('PlasmaNoise', const PlasmaNoiseCard()),
      ('NRS', const NrsCard()),
      ('DMS', const DiscreteModelSamplingCard()),
      ('CfzCudnn', const CfzCudnnToggleCard()),
      ('LayerDiffuse', const LayerDiffuseCard()),
    ]) {
      testWidgets('$name enable and controls', (tester) async {
        await pumpCard(tester, card);
        await tester.tap(find.byType(Switch).first);
        await tester.pumpAndSettle();
        for (final s in find.byType(Slider).evaluate().toList()) {
          await tester.drag(
              find.byWidget(s.widget), const Offset(30, 0));
          await tester.pump();
        }
        if (find.byType(SegmentedButton<String>).evaluate().isNotEmpty) {
          await tester.tap(find.text('Rows'));
          await tester.pump();
        }
        final ddCount = find
            .byType(DropdownButtonFormField<String>)
            .evaluate()
            .length;
        for (var i = 0; i < ddCount; i++) {
          await tester.tap(
              find.byType(DropdownButtonFormField<String>).at(i));
          await tester.pumpAndSettle();
          final items = find.byType(DropdownMenuItem<String>);
          if (items.evaluate().isNotEmpty) {
            await tester.tap(items.last);
            await tester.pumpAndSettle();
          }
        }
        final extra = find.byType(Switch).evaluate().length - 1;
        for (var i = 0; i < extra; i++) {
          await tester.tap(find.byType(Switch).last);
          await tester.pump();
        }
        await tester.tap(find.byType(Switch).first);
        await tester.pump();
      });
    }
  });

  testWidgets('WanModelCard', (tester) async {
    await pumpCard(tester, const WanModelCard());
    for (final dd in find.byType(DropdownButtonFormField<String>)
        .evaluate()
        .toList()) {
      await tester.tap(find.byWidget(dd.widget));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();
    }
    await tester.drag(find.byType(Slider), const Offset(40, 0));
    await tester.pump();
  });

  testWidgets('WanSamplerCard', (tester) async {
    await pumpCard(tester, const WanSamplerCard());
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('uni_pc').last);
    await tester.pumpAndSettle();
    for (final s in find.byType(Slider).evaluate().toList()) {
      await tester.drag(
          find.byWidget(s.widget), const Offset(40, 0));
      await tester.pump();
    }
  });

  testWidgets('UnetModelCard', (tester) async {
    await pumpCard(tester, const UnetModelCard());
    for (final dd in find.byType(DropdownButtonFormField<String>)
        .evaluate()
        .toList()) {
      await tester.tap(find.byWidget(dd.widget));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('VideoOutputSettingsCard', (tester) async {
    await pumpCard(tester, const VideoOutputSettingsCard());
    for (final s in find.byType(Slider).evaluate().toList()) {
      await tester.drag(
          find.byWidget(s.widget), const Offset(40, 0));
      await tester.pump();
    }
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('webm').last);
    await tester.pumpAndSettle();
  });

  testWidgets('SvdConditioningCard', (tester) async {
    await pumpCard(tester, const SvdConditioningCard());
    for (final s in find.byType(Slider).evaluate().toList()) {
      await tester.drag(
          find.byWidget(s.widget), const Offset(40, 0));
      await tester.pump();
    }
  });

  testWidgets('TextEncoderSlotCard', (tester) async {
    await pumpCard(tester, const TextEncoderSlotCard());
    for (final dd in find.byType(DropdownButtonFormField<String>)
        .evaluate()
        .toList()) {
      await tester.tap(find.byWidget(dd.widget));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownMenuItem<String>).last);
      await tester.pumpAndSettle();
    }
  });
}
