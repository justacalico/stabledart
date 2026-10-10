import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stabledart/state/installed_packages_store.dart';
import 'package:stabledart/services/package_registry.dart';
import 'package:stabledart/state/outputs_store.dart';
import 'package:stabledart/state/workflows_store.dart';
import 'package:stabledart/state/model_index_service.dart';
import 'package:stabledart/models/local_model.dart';
import 'package:stabledart/models/output_image.dart';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stabledart/models/civit_models.dart';
import 'package:stabledart/models/console_entry.dart';
import 'package:stabledart/state/console_store.dart';
import 'package:stabledart/views/pages/activity_page.dart';
import 'package:stabledart/views/pages/banana_vision_page.dart';
import 'package:stabledart/views/pages/checkpoints_page.dart';
import 'package:stabledart/views/pages/console_page.dart';
import 'package:stabledart/views/pages/documentation_page.dart';
import 'package:stabledart/views/pages/first_launch_page.dart';
import 'package:stabledart/views/pages/inference_page.dart';
import 'package:stabledart/views/pages/model_browser_page.dart';
import 'package:stabledart/views/pages/outputs_page.dart';
import 'package:stabledart/views/pages/packages_page.dart';
import 'package:stabledart/views/pages/civit_detail_page.dart';
import 'package:stabledart/views/pages/workflows_page.dart';
import 'package:stabledart/services/download_service.dart';
import 'package:stabledart/models/download_task.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  testWidgets('PackagesPage empty state', (tester) async {
    await pumpPage(tester, const PackagesPage());
    expect(find.text('No Packages Installed'), findsOneWidget);
    expect(find.text('Add Package'), findsWidgets);
  });

  testWidgets('PackagesPage browser navigation and detail', (tester) async {
    await pumpPage(tester, const PackagesPage());
    await tester.tap(find.text('Add Package').first);
    await tester.pumpAndSettle();
    expect(find.text('Install Packages'), findsOneWidget);
    expect(find.text('ComfyUI'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'comfy');
    await tester.pumpAndSettle();
    expect(find.text('ComfyUI'), findsWidgets);

    await tester.tap(find.text('Inference').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ComfyUI').first);
    await tester.pumpAndSettle();
    expect(find.text('Install'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    final store = tester.element(find.byType(PackagesPage))
        .read<InstalledPackagesStore>();
    await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Packages'), findsOneWidget);
  });

  testWidgets('PackageInstallDetail install flow', (tester) async {
    await pumpPage(tester, const PackagesPage());
    await tester.tap(find.text('Add Package').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ComfyUI').first);
    await tester.pumpAndSettle();
    final store = tester.element(find.byType(PackagesPage))
        .read<InstalledPackagesStore>();
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();
    expect(store.packages, isNotEmpty);
  });

  testWidgets('PackagesPage with installed package', (tester) async {
    await pumpPage(tester, const PackagesPage());
    final store = tester.element(find.byType(PackagesPage))
        .read<InstalledPackagesStore>();
    await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
    await tester.pumpAndSettle();
    expect(find.text('ComfyUI'), findsWidgets);
    expect(find.text('Launch'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.textContaining('Launch Options'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uninstall'));
    await tester.pumpAndSettle();
    expect(store.packages, isEmpty);
  });

  testWidgets('launch options cancel path', (tester) async {
    await pumpPage(tester, const PackagesPage());
    final store = tester.element(find.byType(PackagesPage))
        .read<InstalledPackagesStore>();
    await store.install(PackageRegistry.byName('OneTrainer')!, 'v1');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();
    expect(find.textContaining('no configurable'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('InferencePage renders all tabs', (tester) async {
    await pumpPage(tester, const InferencePage());
    expect(find.text('Generate'), findsOneWidget);
    for (final tab in [
      'Image to Image',
      'Image to Video',
      'Image Upscale',
      'Flux Text to Image',
      'Wan Text to Video',
      'Wan Image to Video',
    ]) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text('Generate'), findsOneWidget);
    }
  });

  testWidgets('InferencePage generate', (tester) async {
    await pumpPage(tester, const InferencePage());
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    expect(find.text('Idle'), findsOneWidget);
  });

  testWidgets('InferencePage card interactions', (tester) async {
    await pumpPage(tester, const InferencePage());
    expect(find.text('Prompt'), findsWidgets);

    await tester.enterText(
        find.byKey(const ValueKey('prompt-field')), 'a castle');
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('negative-prompt-field')), 'blur');
    await tester.pump();

    final scrollables = find.byType(Scrollable);
    await tester.drag(scrollables.first, const Offset(0, -400));
    await tester.pumpAndSettle();

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    for (var i = 0; i < 3 && i < dropdowns.evaluate().length; i++) {
      final dd = dropdowns.at(i);
      await tester.tap(dd);
      await tester.pumpAndSettle();
      final items = find.byType(DropdownMenuItem<String>);
      if (items.evaluate().length > 1) {
        await tester.tap(items.at(1));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('InferencePage seed and toggles', (tester) async {
    await pumpPage(tester, const InferencePage(),
        size: const Size(1400, 2600));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.casino));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();
  });

  testWidgets('InferencePage collapsible card', (tester) async {
    await pumpPage(tester, const InferencePage());
    await tester.tap(find.text('Prompt').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prompt').first);
    await tester.pumpAndSettle();
  });

  testWidgets('ModelBrowserPage renders tabs', (tester) async {
    await pumpPage(tester, const ModelBrowserPage());
    await tester.pumpAndSettle();
    for (final tab in ['CivArchive', 'HuggingFace', 'OpenModelDB', 'CivitAI']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('CheckpointsPage empty and import', (tester) async {
    await pumpPage(tester, const CheckpointsPage());
    expect(find.text('No Models Found'), findsOneWidget);
    await tester.tap(find.text('Import Model').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'model.safetensors');
    await tester.tap(find.byType(DropdownButtonFormField<ModelCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lora').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('model.safetensors'), findsOneWidget);
  });

  testWidgets('CheckpointsPage populated', (tester) async {
    await pumpPage(tester, const CheckpointsPage());
    final index = tester.element(find.byType(CheckpointsPage))
        .read<ModelIndexService>();
    await index.importFile(
        fileName: 'a.safetensors',
        category: ModelCategory.stableDiffusion,
        sizeBytes: 100);
    await index.importFile(
        fileName: 'b.safetensors', category: ModelCategory.lora);
    await tester.pumpAndSettle();
    expect(find.textContaining('Stable Diffusion (1)'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'a.safe');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Lora').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('Model Metadata'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Title'), 'My Model');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
  });

  testWidgets('OutputsPage', (tester) async {
    await pumpPage(tester, const OutputsPage());
    expect(find.text('No Outputs'), findsOneWidget);
    final store =
        tester.element(find.byType(OutputsPage)).read<OutputsStore>();
    await store.add(OutputImage(
        id: 'o1',
        filePath: 'outputs/t/a.png',
        prompt: 'cat',
        createdAt: DateTime(2024)));
    await tester.pumpAndSettle();
    expect(find.text('cat'), findsOneWidget);
    await tester.tap(find.text('cat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('seed'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('outputs/t'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'cat');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();
    expect(find.text('No Outputs'), findsOneWidget);
  });

  testWidgets('WorkflowsPage', (tester) async {
    await pumpPage(tester, const WorkflowsPage());
    expect(find.text('No Workflows Installed'), findsOneWidget);
    await tester.tap(find.text('Install Workflow').first);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Workflow name'), 'my wf');
    await tester.enterText(
        find.widgetWithText(TextField, 'Author'), 'me');
    await tester.tap(find.text('Install'));
    await tester.pumpAndSettle();
    expect(find.text('my wf'), findsOneWidget);
    final store = tester
        .element(find.byType(WorkflowsPage))
        .read<WorkflowsStore>();
    await store.install(
        name: 'wf2', author: 'a2', baseModel: 'SD3',
        requiredNodes: const []);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open').first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('No Workflows Installed'), findsOneWidget);
  });

  testWidgets('ActivityPage', (tester) async {
    final downloads = DownloadService(
        clientFactory: () => MockClient.streaming((r, _) async =>
            http.StreamedResponse(Stream.value([1, 2]), 200,
                contentLength: 2)));
    await pumpPage(tester, const ActivityPage(), downloads: downloads);
    expect(find.text('No Activity'), findsOneWidget);
    downloads.enqueue(
        fileName: 'f.bin', url: 'https://x/f', totalBytes: 2);
    await tester.pumpAndSettle();
    expect(find.text('f.bin'), findsOneWidget);
    await tester.tap(find.text('Clear Finished'));
    await tester.pumpAndSettle();
    expect(find.text('No Activity'), findsOneWidget);
  });

  testWidgets('ActivityPage task states and actions', (tester) async {
    final service = SeededDownloadService([
      DownloadTask(
          id: 'd1',
          fileName: 'downloading.bin',
          url: 'u',
          status: DownloadStatus.downloading,
          totalBytes: 100,
          receivedBytes: 50,
          bytesPerSecond: 10),
      DownloadTask(
          id: 'd2',
          fileName: 'paused.bin',
          url: 'u',
          status: DownloadStatus.paused,
          totalBytes: 100,
          receivedBytes: 40),
      DownloadTask(
          id: 'd3',
          fileName: 'failed.bin',
          url: 'u',
          status: DownloadStatus.failed,
          totalBytes: 100,
          errorMessage: 'HTTP 500'),
      DownloadTask(
          id: 'd4',
          fileName: 'done.bin',
          url: 'u',
          status: DownloadStatus.completed,
          totalBytes: 100,
          receivedBytes: 100),
      DownloadTask(
          id: 'd5',
          fileName: 'queued.bin',
          url: 'u',
          status: DownloadStatus.queued),
      DownloadTask(
          id: 'd6',
          fileName: 'cancelled.bin',
          url: 'u',
          status: DownloadStatus.cancelled),
    ]);
    await pumpPage(tester, const ActivityPage(),
        downloads: service, settle: false);
    await tester.pump();
    expect(find.text('downloading.bin'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.textContaining('HTTP 500'), findsOneWidget);
    expect(find.textContaining('/s'), findsWidgets);

    await tester.tap(find.byIcon(Icons.pause).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow).last);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pump();
    await tester.tap(find.text('Clear Finished'));
    await tester.pump();
  });

  testWidgets('ConsolePage', (tester) async {
    await pumpPage(tester, ConsolePage());
    expect(find.text('No console output'), findsOneWidget);
  });

  testWidgets('ConsoleView with entries', (tester) async {
    await pumpPage(tester, ConsolePage());
    final console = tester
        .element(find.byType(ConsolePage))
        .read<ConsoleStore>();
    console.log('some output');
    console.log('warn', level: ConsoleLevel.warning);
    console.log('err', level: ConsoleLevel.error);
    console.log('dbg', level: ConsoleLevel.debug);
    await tester.pumpAndSettle();
    expect(find.text('some output'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();
    expect(find.text('No console output'), findsOneWidget);
  });

  testWidgets('DocumentationPage', (tester) async {
    await pumpPage(tester, const DocumentationPage());
    expect(find.text('Select a topic'), findsOneWidget);
    await tester.tap(find.text('Installation'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Download the release'), findsOneWidget);
    await tester.tap(find.text('Launching'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Model Browser'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('full wiki'));
    await tester.pump();
  });

  testWidgets('FirstLaunchPage full flow', (tester) async {
    await pumpPage(tester, const FirstLaunchPage());
    expect(find.text('Welcome to Stability Matrix'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a Data Directory'), findsOneWidget);
    await tester.tap(find.text('Standard'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish Setup'));
    await tester.pumpAndSettle();
  });

  testWidgets('BananaVisionPage setup gate then chat', (tester) async {
    await pumpPage(tester, const BananaVisionPage());
    expect(find.text('Gemini API Setup Required'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'key123');
    await tester.tap(find.text('Save Key'));
    await tester.pumpAndSettle();
    expect(find.text('New Chat'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New Chat'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'draw a cat');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.text('draw a cat'), findsWidgets);

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Cats');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
  });

  testWidgets('BananaVisionPage empty conversation view', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['geminiApiKey'] = 'k');
    await pumpPage(tester, const BananaVisionPage(), settings: settings);
    expect(find.textContaining('Start a new chat'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a prompt');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
  });

  testWidgets('CivitDetailPage', (tester) async {
    const model = CivitModel(
      id: 1,
      name: 'Test Model',
      creator: 'alice',
      type: 'Checkpoint',
      tags: ['anime', 'style'],
      nsfw: true,
      downloadCount: 100,
      favoriteCount: 5,
      commentCount: 2,
      rating: 4.5,
      versions: [
        CivitModelVersion(
          id: 10,
          name: 'v1',
          baseModel: 'SD 1.5',
          images: [
            CivitImage(id: 1, url: 'https://x/1.png'),
            CivitImage(id: 2, url: 'https://x/2.png'),
          ],
          files: [
            CivitModelFile(
                id: 1,
                name: 'm.safetensors',
                sizeKb: 2048,
                downloadUrl: 'https://x/dl',
                sha256: 'abcdef123456'),
          ],
        ),
        CivitModelVersion(id: 11, name: 'v2', baseModel: 'SDXL'),
      ],
    );
    await pumpPage(tester, const CivitDetailPage(model: model));
    expect(find.text('Test Model'), findsWidgets);
    expect(find.text('NSFW'), findsOneWidget);
    for (var i = 0; i < find.byType(InkWell).evaluate().length; i++) {
      await tester.tap(find.byType(InkWell).at(i));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('v2 (SDXL)').last);
    await tester.pumpAndSettle();
    expect(find.text('No files available'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('CivitDetailPage download enqueues', (tester) async {
    final downloads = DownloadService();
    const model = CivitModel(
      id: 1,
      name: 'M',
      versions: [
        CivitModelVersion(
          id: 10,
          name: 'v1',
          files: [
            CivitModelFile(
                id: 1,
                name: 'f.safetensors',
                sizeKb: 1,
                downloadUrl: 'https://x/f'),
          ],
        ),
      ],
    );
    await pumpPage(tester, const CivitDetailPage(model: model),
        downloads: downloads);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();
    expect(downloads.tasks.single.fileName, 'f.safetensors');
  });
}
