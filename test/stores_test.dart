import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stabledart/models/civit_models.dart';
import 'package:stabledart/models/output_image.dart';
import 'package:stabledart/services/civarchive_api.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/huggingface_api.dart';
import 'package:stabledart/services/openmodeldb_api.dart';
import 'package:stabledart/services/package_registry.dart';
import 'package:stabledart/services/settings_backend.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/services/version_checker.dart';
import 'package:stabledart/state/console_store.dart';
import 'package:stabledart/state/image_lab_store.dart';
import 'package:stabledart/state/inference_store.dart';
import 'package:stabledart/state/installed_packages_store.dart';
import 'package:stabledart/state/model_browser_store.dart';
import 'package:stabledart/state/model_index_service.dart';
import 'package:stabledart/models/hf_models.dart';
import 'package:stabledart/models/installed_package.dart';
import 'package:stabledart/models/local_model.dart';
import 'package:stabledart/state/navigation_store.dart';
import 'package:stabledart/state/notification_store.dart';
import 'package:stabledart/state/outputs_store.dart';
import 'package:stabledart/state/version_store.dart';
import 'package:stabledart/state/workflows_store.dart';

import 'test_helpers.dart';

SettingsManager _sm() => SettingsManager(MemorySettingsBackend());

void main() {
  group('PackageRegistry', () {
    test('catalog is complete and lookup works', () {
      expect(PackageRegistry.all.length, greaterThanOrEqualTo(30));
      expect(PackageRegistry.byName('ComfyUI')!.displayName, 'ComfyUI');
      expect(PackageRegistry.byName('nonexistent'), isNull);
      expect(PackageRegistry.allTags, isNotEmpty);
      for (final def in PackageRegistry.all) {
        def.launchOptions();
      }
    });
  });

  group('InstalledPackagesStore', () {
    test('install persists and uninstall removes', () async {
      final store = InstalledPackagesStore(_sm(), FakeProcessRunner());
      final def = PackageRegistry.byName('ComfyUI')!;
      final pkg = await store.install(def, 'v1.0');
      expect(store.packages.single.displayName, 'ComfyUI');
      expect(store.installs['ComfyUI']!.done, isTrue);
      expect(store.byId(pkg.id), pkg);
      expect(store.byId('nope'), isNull);
      await store.uninstall(pkg);
      expect(store.packages, isEmpty);
    });

    test('install failure records error', () async {
      final store = InstalledPackagesStore(_sm(), FakeProcessRunner());
      final def = PackageRegistry.byName('ComfyUI')!;
      await expectLater(
        store.install(def, 'v1', runStep: (s) async => false),
        throwsStateError,
      );
      expect(store.installs['ComfyUI']!.error, isNotNull);
      expect(store.packages, isEmpty);
    });

    test('loads persisted packages', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.packages', jsonEncode([
        {
          'id': 'p1',
          'packageName': 'Fooocus',
          'displayName': 'Fooocus',
          'version': '1',
          'installPath': '/x',
          'installedAt': '2024-01-01T00:00:00.000Z',
          'launchArgs': [],
        },
        'junk',
      ]));
      final store = InstalledPackagesStore(
          SettingsManager(backend), FakeProcessRunner());
      expect(store.packages.single.id, 'p1');
    });

    test('corrupt packages json starts empty', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.packages', '{bad');
      final store = InstalledPackagesStore(
          SettingsManager(backend), FakeProcessRunner());
      expect(store.packages, isEmpty);
    });

    test('launch streams output and stops', () async {
      final runner = FakeProcessRunner(lines: ['a', 'b']);
      final store = InstalledPackagesStore(_sm(), runner);
      final pkg = await store.install(
          PackageRegistry.byName('Fooocus')!, 'v1');
      final out = <String>[];
      final done = store.launch(pkg, onOutput: out.add);
      expect(pkg.isRunning, isTrue);
      await done;
      expect(out, ['a', 'b']);
      expect(pkg.isRunning, isFalse);
      await store.stop(pkg);
      runner.hang = true;
      final second = store.launch(pkg, onOutput: (_) {});
      expect(pkg.isRunning, isTrue);
      await store.stop(pkg);
      expect(runner.stopped, isTrue);
      expect(pkg.isRunning, isFalse);
      await second;
    });

    test('launch converts launch args to flags', () async {
      final runner = FakeProcessRunner();
      final store = InstalledPackagesStore(_sm(), runner);
      final def = PackageRegistry.byName('ComfyUI')!;
      final pkg = await store.install(def, 'v1');
      final option = def.launchOptions().first;
      await store.saveLaunchArgs(pkg, [
        {'name': option.name, 'enabled': true, 'value': option.initialValue},
        {'name': 'does-not-exist', 'enabled': true},
      ]);
      await store.launch(pkg, onOutput: (_) {});
      expect(runner.calls.single.any((a) => a.startsWith('-')), isTrue);
      expect(pkg.isRunning, isFalse);
    });

    test('launch process failure surfaces to output', () async {
      final runner = FakeProcessRunner(error: StateError('boom'));
      final store = InstalledPackagesStore(_sm(), runner);
      final pkg =
          await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
      final out = <String>[];
      await store.launch(pkg, onOutput: out.add);
      expect(out.single, contains('Process failed'));
      expect(pkg.isRunning, isFalse);
    });

    test('uninstall stops running package', () async {
      final runner = FakeProcessRunner(hang: true);
      final store = InstalledPackagesStore(_sm(), runner);
      final pkg =
          await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
      final done = store.launch(pkg, onOutput: (_) {});
      expect(pkg.isRunning, isTrue);
      await store.uninstall(pkg);
      await done;
      expect(runner.stopped, isTrue);
      expect(store.packages, isEmpty);
      expect(store.installs, isEmpty);
    });

    test('saveLaunchArgs persists', () async {
      final store = InstalledPackagesStore(_sm(), FakeProcessRunner());
      final pkg =
          await store.install(PackageRegistry.byName('ComfyUI')!, 'v1');
      await store.saveLaunchArgs(pkg, [
        {'name': 'cpu', 'enabled': true}
      ]);
      expect(store.byId(pkg.id)!.launchArgs.single['name'], 'cpu');
      await store.saveLaunchArgs(
          InstalledPackage(
              id: 'missing',
              packageName: 'x',
              displayName: 'x',
              version: '1',
              installPath: '/x',
              installedAt: DateTime(2024)),
          const []);
    });
  });

  group('ModelIndexService', () {
    test('import, filter, remove', () async {
      final index = ModelIndexService(_sm());
      await index.importFile(
          fileName: 'a.safetensors',
          category: ModelCategory.stableDiffusion,
          sizeBytes: 10);
      await index.importFile(
          fileName: 'b.safetensors', category: ModelCategory.lora);
      expect(index.models.length, 2);
      expect(index.countFor(ModelCategory.lora), 1);
      expect(index.byCategory.keys, contains(ModelCategory.lora));
      index.setCategoryFilter(ModelCategory.lora);
      expect(index.filtered.single.fileName, 'b.safetensors');
      index.setCategoryFilter(null);
      index.setQuery('a.safe');
      expect(index.filtered.single.fileName, 'a.safetensors');
      index.setQuery('zzz');
      expect(index.filtered, isEmpty);
      index.setQuery('');
      await index.remove(index.models.first);
      expect(index.models.length, 1);
      await index.resetCache();
      expect(index.models, isEmpty);
    });

    test('updateMetadata and whereType', () async {
      final index = ModelIndexService(_sm());
      final m = await index.importFile(fileName: 'x.safetensors');
      await index.updateMetadata(m,
          title: 'T', author: 'A', description: 'D',
          thumbnailUrl: 'u', category: ModelCategory.vae,
          isShared: false);
      expect(m.title, 'T');
      expect(m.category, ModelCategory.vae);
      expect(m.isShared, isFalse);
      expect(index.whereType(ModelCategory.vae).single, m);
    });

    test('load persisted and corrupt', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.models', jsonEncode([
        {'id': 'm1', 'fileName': 'a.ckpt', 'category': 'vae'},
      ]));
      var index = ModelIndexService(SettingsManager(backend));
      expect(index.models.single.id, 'm1');
      backend.setString('stabledart.models', '{bad');
      index = ModelIndexService(SettingsManager(backend));
      expect(index.models, isEmpty);
    });
  });

  group('ConsoleStore', () {
    test('log trims history and clear', () {
      final console = ConsoleStore(maxHistory: 3);
      for (var i = 0; i < 5; i++) {
        console.log('l$i');
      }
      expect(console.entries.length, 3);
      expect(console.entries.first.text, 'l2');
      console.clear();
      expect(console.isEmpty, isTrue);
    });
  });

  group('NavigationStore', () {
    test('navigation and badges', () {
      final nav = NavigationStore();
      nav.goTo(2);
      expect(nav.index, 2);
      nav.goTo(2);
      expect(nav.index, 2);
      nav.dismissUpdateBanner();
      expect(nav.updateBannerVisible, isFalse);
      nav.setActivityBadge(4);
      expect(nav.activityBadgeCount, 4);
    });
  });

  group('NotificationStore', () {
    test('push, read, clear', () {
      final store = NotificationStore();
      store.push('t', 'm');
      store.push('t2', 'm2');
      expect(store.unreadCount, 2);
      store.markAllRead();
      expect(store.unreadCount, 0);
      store.clear();
      expect(store.notifications, isEmpty);
    });
  });

  group('OutputsStore', () {
    test('add, folders, filter, remove, clear', () async {
      final store = OutputsStore(_sm());
      await store.add(OutputImage(
          id: 'o1',
          filePath: 'outputs/txt2img/a.png',
          prompt: 'cat',
          createdAt: DateTime(2024)));
      await store.add(OutputImage(
          id: 'o2',
          filePath: 'outputs/img2img/b.png',
          prompt: 'dog',
          createdAt: DateTime(2024)));
      await store.add(OutputImage(
          id: 'o3', filePath: 'root.png', createdAt: DateTime(2024)));
      expect(store.folders, contains('outputs/txt2img'));
      expect(store.folders, contains('root.png'));
      store.setFolderFilter('outputs/txt2img');
      expect(store.filtered.single.id, 'o1');
      store.setFolderFilter(null);
      store.setQuery('dog');
      expect(store.filtered.single.id, 'o2');
      store.setQuery('');
      await store.remove(store.outputs.first);
      expect(store.outputs.length, 2);
      await store.clear();
      expect(store.outputs, isEmpty);
    });

    test('load persisted and corrupt', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.outputs', jsonEncode([
        {'id': 'o1', 'filePath': 'x.png', 'createdAt': '2024-01-01'},
      ]));
      var store = OutputsStore(SettingsManager(backend));
      expect(store.outputs.single.id, 'o1');
      backend.setString('stabledart.outputs', '{bad');
      store = OutputsStore(SettingsManager(backend));
      expect(store.outputs, isEmpty);
    });
  });

  group('WorkflowsStore', () {
    test('install, remove, persistence', () async {
      final store = WorkflowsStore(_sm());
      final wf = await store.install(
          name: 'wf1', author: 'a', baseModel: 'SDXL',
          requiredNodes: const ['n']);
      expect(store.workflows.single.name, 'wf1');
      await store.remove(wf);
      expect(store.workflows, isEmpty);
    });

    test('load persisted and corrupt', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.workflows', jsonEncode([
        {'id': 'w1', 'name': 'wf'},
      ]));
      var store = WorkflowsStore(SettingsManager(backend));
      expect(store.workflows.single.id, 'w1');
      backend.setString('stabledart.workflows', '{bad');
      store = WorkflowsStore(SettingsManager(backend));
      expect(store.workflows, isEmpty);
    });
  });

  group('ImageLabStore', () {
    test('conversations lifecycle', () async {
      final store = ImageLabStore(_sm());
      final c = await store.newConversation();
      expect(store.current, c);
      await store.send('make a cat');
      expect(c.messages.length, 2);
      expect(c.title, 'make a cat');
      await store.renameConversation(c, 'Cats');
      expect(c.title, 'Cats');
      final c2 = await store.newConversation();
      store.selectConversation(c.id);
      expect(store.current, c);
      await store.deleteConversation(c);
      expect(store.current, c2);
      await store.deleteConversation(c2);
      expect(store.current, isNull);
      await store.send('hello again');
      expect(store.conversations.single.messages.length, 2);
    });

    test('load persisted and corrupt', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.conversations', jsonEncode([
        {'id': 'c1', 'title': 't', 'messages': []},
      ]));
      var store = ImageLabStore(SettingsManager(backend));
      expect(store.conversations.single.id, 'c1');
      expect(store.currentId, 'c1');
      backend.setString('stabledart.conversations', '{bad');
      store = ImageLabStore(SettingsManager(backend));
      expect(store.conversations, isEmpty);
      expect(store.current, isNull);
    });
  });

  group('InferenceStore', () {
    test('tabs, params, cards, seed', () {
      final store = InferenceStore(defaults: _sm().settings);
      expect(store.tab, InferenceTab.textToImage);
      expect(store.params.steps, 20);
      store.selectTab(InferenceTab.imageToImage);
      expect(store.tab, InferenceTab.imageToImage);
      expect(store.params.denoiseStrength, 0.6);
      store.updateParams((p) => p.prompt = 'cat');
      expect(store.params.prompt, 'cat');
      store.randomizeSeed();
      expect(store.params.seed, greaterThanOrEqualTo(0));
      expect(store.isCardExpanded('x'), isTrue);
      store.toggleCard('x');
      expect(store.isCardExpanded('x'), isFalse);
      store.toggleCard('x');
      expect(store.isCardExpanded('x'), isTrue);
    });

    test('tab names', () {
      for (final t in InferenceTab.values) {
        expect(t.displayName.isNotEmpty, isTrue);
      }
    });

    test('generation lifecycle', () async {
      OutputImage? generated;
      final store = InferenceStore(
        defaults: _sm().settings,
        backend: MockInferenceBackend(
            stepDelay: const Duration(milliseconds: 5), ticks: 4),
        onImageGenerated: (i) => generated = i,
      );
      store.updateParams((p) {
        p.prompt = 'a cat';
        p.seed = 42;
      });
      final done = store.generate();
      expect(store.isGenerating, isTrue);
      await done;
      expect(store.isGenerating, isFalse);
      expect(store.statusText, 'Idle');
      expect(generated, isNotNull);
      expect(generated!.seed, 42);
      expect(store.gallery.single.prompt, 'a cat');
      store.clearGallery();
      expect(store.gallery, isEmpty);
    });

    test('generate while running is no-op and cancel works', () async {
      final store = InferenceStore(
        defaults: _sm().settings,
        backend: MockInferenceBackend(
            stepDelay: const Duration(milliseconds: 40), ticks: 100),
      );
      final done = store.generate();
      await Future.delayed(const Duration(milliseconds: 20));
      await store.generate();
      expect(store.isGenerating, isTrue);
      store.cancelGeneration();
      expect(store.isGenerating, isFalse);
      expect(store.statusText, 'Cancelled');
      await done;
    });

    test('backend error surfaces', () async {
      final store = InferenceStore(
        defaults: _sm().settings,
        backend: _FailingBackend(),
      );
      await store.generate();
      expect(store.statusText, contains('Error'));
    });

    test('params copy', () {
      final p = GenerationParams(prompt: 'x', seed: 9);
      final c = p.copy();
      expect(c.prompt, 'x');
      expect(c.seed, 9);
      c.prompt = 'y';
      expect(p.prompt, 'x');
    });
  });

  group('VersionStore', () {
    VersionStore storeFor(Object body, {int status = 200}) => VersionStore(
        VersionChecker(
            client: MockClient(
                (r) async => http.Response(jsonEncode(body), status))),
        () => '0.1.0');

    test('check success with update', () async {
      final store = storeFor([
        {'tag_name': 'v9.9.9'}
      ]);
      await store.checkForUpdates();
      expect(store.status, VersionCheckStatus.success);
      expect(store.lastResult.updateAvailable, isTrue);
    });

    test('check failure', () async {
      final store = storeFor({}, status: 500);
      await store.checkForUpdates();
      expect(store.status, VersionCheckStatus.failed);
      expect(store.errorMessage, isNotNull);
    });

    test('concurrent checks dedupe', () async {
      final store = storeFor(const []);
      await Future.wait(
          [store.checkForUpdates(), store.checkForUpdates()]);
      expect(store.status, VersionCheckStatus.success);
    });
  });

  group('browser stores', () {
    test('CivitAiBrowserStore search and loadMore', () async {
      var calls = 0;
      final api = CivitAiApi(client: MockClient((r) async {
        calls++;
        return http.Response(
            jsonEncode({
              'items': [
                {'id': calls, 'name': 'm$calls'}
              ],
              'metadata': {'nextCursor': calls == 1 ? 'c' : null},
            }),
            200);
      }));
      final store = CivitAiBrowserStore(api);
      store.setQuery('q');
      await store.search();
      expect(store.status, LoadStatus.success);
      expect(store.models.single.id, 1);
      expect(store.canLoadMore, isTrue);
      await store.loadMore();
      expect(store.models.length, 2);
      expect(store.canLoadMore, isFalse);
      store.setType(CivitModelType.lora);
      await pumpUntil(() => store.status == LoadStatus.success);
      for (final s in CivitSort.values) {
        store.setSort(s);
        await pumpUntil(() => store.status == LoadStatus.success);
      }
      for (final p in CivitPeriod.values) {
        store.setPeriod(p);
        await pumpUntil(() => store.status == LoadStatus.success);
      }
      store.setNsfw(true);
      await pumpUntil(() => store.status == LoadStatus.success);
    });

    test('CivitAiBrowserStore failure', () async {
      final store = CivitAiBrowserStore(
          CivitAiApi(
              client: MockClient((r) async => http.Response('', 500))));
      await store.search();
      expect(store.status, LoadStatus.failed);
      expect(store.errorMessage, isNotNull);
    });

    test('HuggingFaceBrowserStore', () async {
      final api = HuggingFaceApi(client: MockClient((r) async {
        if (r.url.path.contains('/tree/')) {
          return http.Response(
              jsonEncode([
                {'path': 'm.safetensors', 'size': 5}
              ]),
              200);
        }
        return http.Response(
            jsonEncode([
              {'id': 'a/b'}
            ]),
            200);
      }));
      final store = HuggingFaceBrowserStore(api);
      store.setQuery('x');
      await store.search();
      expect(store.status, LoadStatus.success);
      await store.selectModel(store.models.single);
      expect(store.files.single.path, 'm.safetensors');
    });

    test('HuggingFaceBrowserStore failures', () async {
      final store = HuggingFaceBrowserStore(
          HuggingFaceApi(
              client: MockClient((r) async => http.Response('', 500))));
      await store.search();
      expect(store.status, LoadStatus.failed);
      await store.selectModel(const HuggingFaceModel(id: 'a/b'));
      expect(store.status, LoadStatus.failed);
    });

    test('OpenModelDbBrowserStore', () async {
      final api = OpenModelDbApi(client: MockClient((r) async {
        return http.Response(
            jsonEncode({
              'm1': {'name': 'A', 'tags': ['upscale']},
              'm2': {'name': 'B', 'tags': ['photo']},
            }),
            200);
      }));
      final store = OpenModelDbBrowserStore(api);
      await store.load();
      expect(store.status, LoadStatus.success);
      expect(store.allTags, contains('upscale'));
      store.setTagFilter('upscale');
      expect(store.filtered.single.name, 'A');
      store.setTagFilter(null);
      store.setQuery('b');
      expect(store.filtered.single.name, 'B');
      store.setQuery('zzz');
      expect(store.filtered, isEmpty);
      store.setQuery('');
    });

    test('OpenModelDbBrowserStore failure', () async {
      final store = OpenModelDbBrowserStore(
          OpenModelDbApi(
              client: MockClient((r) async => http.Response('', 500))));
      await store.load();
      expect(store.status, LoadStatus.failed);
    });

    test('CivArchiveBrowserStore', () async {
      final api = CivArchiveApi(client: MockClient((r) async {
        return http.Response(
            jsonEncode([
              {'id': 1, 'name': 'arch'}
            ]),
            200);
      }));
      final store = CivArchiveBrowserStore(api);
      store.setQuery('q');
      await store.search();
      expect(store.status, LoadStatus.success);
      store.setPage(2);
      await pumpUntil(() => store.status == LoadStatus.success);
      expect(store.page, 2);
    });

    test('CivArchiveBrowserStore failure', () async {
      final store = CivArchiveBrowserStore(
          CivArchiveApi(
              client: MockClient((r) async => http.Response('', 500))));
      await store.search();
      expect(store.status, LoadStatus.failed);
    });
  });
}

class _FailingBackend implements InferenceBackend {
  @override
  Stream<double> generate(GenerationParams params) =>
      Stream.error(Exception('backend down'));
}

Future<void> pumpUntil(bool Function() cond,
    {int tries = 50}) async {
  for (var i = 0; i < tries && !cond(); i++) {
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

