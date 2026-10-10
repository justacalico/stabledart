import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:stabledart/services/civarchive_api.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/download_service.dart';
import 'package:stabledart/services/huggingface_api.dart';
import 'package:stabledart/services/openmodeldb_api.dart';
import 'package:stabledart/state/model_browser_store.dart';
import 'package:stabledart/views/pages/model_browser/civarchive_browser.dart';
import 'package:stabledart/views/pages/model_browser/civitai_browser.dart';
import 'package:stabledart/views/pages/model_browser/huggingface_browser.dart';
import 'package:stabledart/views/pages/model_browser/openmodeldb_browser.dart';
import 'package:stabledart/views/widgets/app_network_image.dart';
import 'package:stabledart/views/widgets/number_field.dart';

import 'test_helpers.dart';

void main() {
  setUp(setupMockChannels);

  testWidgets('CivitAiBrowser populated and interactions', (tester) async {
    var page = 0;
    final api = CivitAiApi(client: MockClient((r) async {
      page++;
      return http.Response(
          jsonEncode({
            'items': [
              {
                'id': page,
                'name': 'Model $page',
                'type': 'Checkpoint',
                'nsfw': true,
                'stats': {'downloadCount': 42},
                'modelVersions': [
                  {
                    'id': 1,
                    'name': 'v1',
                    'images': [
                      {'id': 1, 'url': 'https://x/i.png'}
                    ]
                  }
                ]
              }
            ],
            'metadata': {
              'nextCursor': page == 1 ? 'c' : null,
            },
          }),
          200);
    }));
    await pumpPage(tester, const CivitAiBrowserView(), civitAi: api);
    expect(find.text('Model 1'), findsOneWidget);
    await tester.tap(find.text('Model 1'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Load More'));
    await tester.pumpAndSettle();
    expect(find.text('Model 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'query');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final ddFinder = find.byWidgetPredicate((w) => w is DropdownButton);
    expect(ddFinder.evaluate().length, 3);
    for (final (i, label) in [
      (0, 'LORA'),
      (1, 'Newest'),
      (2, 'Week'),
    ]) {
      await tester.tap(ddFinder.at(i), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('NSFW'));
    await tester.pumpAndSettle();
  });

  testWidgets('CivitAiBrowser error retry', (tester) async {
    final api = CivitAiApi(
        client: MockClient((r) async => http.Response('x', 500)));
    await pumpPage(tester, const CivitAiBrowserView(), civitAi: api);
    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
  });

  testWidgets('CivArchiveBrowser rows and pagination', (tester) async {
    final api = CivArchiveApi(client: MockClient((r) async {
      return http.Response(
          jsonEncode([
            {
              'id': 1,
              'name': 'Archived',
              'type': 'Checkpoint',
              'modelVersions': [
                {
                  'id': 1,
                  'images': [
                    {'id': 1, 'url': 'https://x/i.png'}
                  ]
                }
              ]
            },
            {'id': 2, 'name': 'Second'}
          ]),
          200);
    }));
    await pumpPage(tester, const CivArchiveBrowserView(),
        civArchive: api);
    expect(find.text('Archived'), findsOneWidget);
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'q');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  });

  testWidgets('HuggingFaceBrowser files and download', (tester) async {
    final api = HuggingFaceApi(client: MockClient((r) async {
      if (r.url.path.contains('/tree/')) {
        return http.Response(
            jsonEncode([
              {'path': 'model.safetensors', 'size': 2048},
              {'path': 'readme.md', 'size': 10},
            ]),
            200);
      }
      return http.Response(
          jsonEncode([
            {'id': 'a/b', 'downloads': 5, 'likes': 1},
            {'id': 'c/d'},
          ]),
          200);
    }));
    final downloads = DownloadService(
        clientFactory: () => MockClient.streaming((r, _) async =>
            http.StreamedResponse(Stream.value([0]), 200)));
    await pumpPage(tester, const HuggingFaceBrowserView(),
        huggingFace: api, downloads: downloads);
    expect(find.text('a/b'), findsOneWidget);
    await tester.tap(find.text('a/b'));
    await tester.pumpAndSettle();
    expect(find.text('model.safetensors'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.download));
    await tester.pumpAndSettle();
    expect(downloads.tasks.single.fileName, 'model.safetensors');
  });

  testWidgets('OpenModelDbBrowser cards and details', (tester) async {
    final api = OpenModelDbApi(client: MockClient((r) async {
      return http.Response(
          jsonEncode({
            'm1': {
              'name': 'UltraSharp',
              'author': 'a',
              'scale': 4,
              'architecture': 'ESRGAN',
              'tags': ['general'],
              'images': [
                {'SRGB': {'url': 'https://x/i.png'}}
              ],
              'resources': [
                {'urls': ['https://x/dl']}
              ],
            },
            'm2': {
              'name': 'PhotoFix',
              'author': 'b',
              'scale': 2,
              'tags': ['photo'],
            },
          }),
          200);
    }));
    await pumpPage(tester, const OpenModelDbBrowserView(),
        openModelDb: api);
    expect(find.text('UltraSharp'), findsOneWidget);
    await tester.tap(find.text('general'));
    await tester.pumpAndSettle();
    expect(find.text('UltraSharp'), findsOneWidget);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UltraSharp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('4x upscale'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No models found'), findsOneWidget);
  });

  testWidgets('AppNetworkImage placeholder', (tester) async {
    await pumpPage(tester, const Column(children: [
      AppNetworkImage(url: null),
      AppNetworkImage(url: ''),
    ]));
    expect(find.byIcon(Icons.image_outlined), findsWidgets);
  });

  testWidgets('NumberField bounds', (tester) async {
    var value = 5;
    await pumpPage(tester, StatefulBuilder(
      builder: (context, setState) => NumberField(
        label: 'n',
        value: value,
        min: 0,
        max: 10,
        onChanged: (v) => setState(() => value = v),
      ),
    ));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(value, 6);
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pumpAndSettle();
    expect(value, 5);
    value = 0;
    await pumpPage(tester, StatefulBuilder(
      builder: (context, setState) => NumberField(
        label: 'n',
        value: value,
        min: 0,
        max: 10,
        onChanged: (v) => setState(() => value = v),
      ),
    ));
    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(value, 0);
  });

  testWidgets('HuggingFaceBrowser query and failure', (tester) async {
    final api = HuggingFaceApi(
        client: MockClient((r) async => http.Response('x', 500)));
    await pumpPage(tester, const HuggingFaceBrowserView(),
        huggingFace: api);
    await tester.enterText(find.byType(TextField), 'q');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP'), findsOneWidget);
  });
}
