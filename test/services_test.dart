import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stabledart/models/download_task.dart';
import 'package:stabledart/services/civarchive_api.dart';
import 'package:stabledart/services/civitai_api.dart';
import 'package:stabledart/services/download_service.dart';
import 'package:stabledart/services/github_versions_api.dart';
import 'package:stabledart/services/huggingface_api.dart';
import 'package:stabledart/services/openmodeldb_api.dart';
import 'package:stabledart/services/process_runner.dart';
import 'package:stabledart/services/settings_backend.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/services/version_checker.dart';
import 'package:stabledart/models/civit_models.dart';

import 'test_helpers.dart';

http.Client _jsonClient(Object body, {int status = 200}) =>
    MockClient((r) async => http.Response(jsonEncode(body), status));

void main() {
  group('SettingsBackend', () {
    test('memory backend', () async {
      final b = MemorySettingsBackend();
      expect(b.getString('k'), isNull);
      await b.setString('k', 'v');
      expect(b.getString('k'), 'v');
    });

    test('shared prefs backend', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final b = SharedPreferencesBackend(prefs);
      expect(b.getString('k'), isNull);
      await b.setString('k', 'v');
      expect(b.getString('k'), 'v');
    });
  });

  group('SettingsManager', () {
    test('loads defaults and persists', () async {
      final sm = SettingsManager(MemorySettingsBackend());
      expect(sm.settings.language, 'en_US');
      sm.update((s) => s.language = 'zh_CN');
      await Future.delayed(Duration.zero);
      final sm2 = SettingsManager(MemorySettingsBackend());
      expect(sm2.settings.language, 'en_US');
    });

    test('reloads persisted settings', () async {
      final backend = MemorySettingsBackend();
      final sm = SettingsManager(backend);
      sm.update((s) => s.language = 'ja_JP');
      await Future.delayed(Duration.zero);
      final sm2 = SettingsManager(backend);
      expect(sm2.settings.language, 'ja_JP');
    });

    test('falls back on corrupt json', () {
      final backend = MemorySettingsBackend();
      backend.setString('stabledart.settings', '{not json');
      final sm = SettingsManager(backend);
      expect(sm.settings.language, 'en_US');
    });

    test('readRaw/writeRaw key mapping', () async {
      final sm = SettingsManager(MemorySettingsBackend());
      await sm.writeRaw('packages', '[1]');
      expect(sm.readRaw('packages'), '[1]');
      await sm.writeRaw('models', 'm');
      expect(sm.readRaw('models'), 'm');
      await sm.writeRaw('outputs', 'o');
      expect(sm.readRaw('outputs'), 'o');
      await sm.writeRaw('workflows', 'w');
      expect(sm.readRaw('workflows'), 'w');
      await sm.writeRaw('conversations', 'c');
      expect(sm.readRaw('conversations'), 'c');
      await sm.writeRaw('settings', 's');
      expect(sm.readRaw('settings'), 's');
      await sm.writeRaw('custom', 'x');
      expect(sm.readRaw('custom'), 'x');
    });
  });

  group('SystemProcessRunner', () {
    test('runs and streams', () async {
      final runner = SystemProcessRunner();
      final lines = await runner.start('echo', ['hello']).toList();
      expect(lines, contains('hello'));
    });

    test('run', () async {
      final runner = SystemProcessRunner();
      final result = await runner.run('echo', ['x']);
      expect(result.stdout.toString().trim(), 'x');
    });

    test('stop kills process', () async {
      final runner = SystemProcessRunner();
      final stream = runner.start('cat', []);
      stream.listen((_) {});
      await Future.delayed(const Duration(milliseconds: 50));
      await runner.stop('cat');
    });
  });

  group('CivitAiApi', () {
    test('getModels parses response', () async {
      final api = CivitAiApi(client: _jsonClient({
        'items': [
          {'id': 1, 'name': 'A', 'modelVersions': []}
        ],
        'metadata': {'nextCursor': 'abc'},
      }));
      final page = await api.getModels(
        query: 'q',
        type: CivitModelType.lora,
        sort: CivitSort.newest,
        period: CivitPeriod.week,
        baseModels: const ['SDXL'],
        nsfw: true,
        cursor: 'c0',
      );
      expect(page.items.single.name, 'A');
      expect(page.nextCursor, 'abc');
    });

    test('getModels nextPage fallback cursor', () async {
      final api = CivitAiApi(client: _jsonClient({
        'items': [],
        'metadata': {'nextPage': 'https://civitai.com/api/v1/models?cursor=zz'},
      }));
      final page = await api.getModels();
      expect(page.nextCursor, 'zz');
    });

    test('getModels error', () {
      final api = CivitAiApi(client: MockClient((r) async => http.Response('', 500)));
      expect(api.getModels(), throwsA(isA<CivitApiException>()));
    });

    test('getModels bad shape', () {
      final api = CivitAiApi(client: _jsonClient([1, 2]));
      expect(api.getModels(), throwsA(isA<CivitApiException>()));
    });

    test('getModel', () async {
      final api = CivitAiApi(client: _jsonClient({'id': 5, 'name': 'M'}));
      expect((await api.getModel(5)).id, 5);
      final bad = CivitAiApi(client: _jsonClient('x'));
      expect(bad.getModel(1), throwsA(isA<CivitApiException>()));
      final err = CivitAiApi(client: MockClient((r) async => http.Response('', 404)));
      expect(err.getModel(1), throwsA(isA<CivitApiException>()));
    });

    test('getModelVersion', () async {
      final api = CivitAiApi(client: _jsonClient({'id': 9, 'name': 'v'}));
      expect((await api.getModelVersion(9)).id, 9);
      final bad = CivitAiApi(client: _jsonClient(3));
      expect(bad.getModelVersion(1), throwsA(isA<CivitApiException>()));
      final err = CivitAiApi(client: MockClient((r) async => http.Response('', 404)));
      expect(err.getModelVersion(1), throwsA(isA<CivitApiException>()));
    });

    test('api key header', () async {
      String? auth;
      final api = CivitAiApi(
        apiKey: 'secret',
        client: MockClient((r) async {
          auth = r.headers['Authorization'];
          return http.Response('{"items":[],"metadata":{}}', 200);
        }),
      );
      await api.getModels();
      expect(auth, 'Bearer secret');
    });

    test('sort and period params', () {
      expect(CivitAiApi.apiBase, contains('civitai'));
    });
  });

  group('HuggingFaceApi', () {
    test('searchModels', () async {
      final api = HuggingFaceApi(client: _jsonClient([
        {'id': 'a/b', 'downloads': 1}
      ]));
      final models = await api.searchModels(query: 'x', author: 'a');
      expect(models.single.id, 'a/b');
    });

    test('searchModels errors', () {
      final api = HuggingFaceApi(client: _jsonClient({'a': 1}));
      expect(api.searchModels(), throwsA(isA<HuggingFaceApiException>()));
      final err = HuggingFaceApi(client: MockClient((r) async => http.Response('', 403)));
      expect(err.searchModels(), throwsA(isA<HuggingFaceApiException>()));
    });

    test('listFiles', () async {
      final api = HuggingFaceApi(client: _jsonClient([
        {'path': 'a.safetensors', 'size': 10}
      ]));
      expect((await api.listFiles('a/b')).single.path, 'a.safetensors');
      final bad = HuggingFaceApi(client: _jsonClient({}));
      expect(bad.listFiles('x'), throwsA(isA<HuggingFaceApiException>()));
      final err = HuggingFaceApi(client: MockClient((r) async => http.Response('', 404)));
      expect(err.listFiles('x'), throwsA(isA<HuggingFaceApiException>()));
    });

    test('downloadUrl and api key header', () async {
      String? auth;
      final api = HuggingFaceApi(
        apiKey: 'tok',
        client: MockClient((r) async {
          auth = r.headers['Authorization'];
          return http.Response('[]', 200);
        }),
      );
      await api.searchModels();
      expect(auth, 'Bearer tok');
      expect(HuggingFaceApi.downloadUrl('a/b', 'f.safetensors'),
          'https://huggingface.co/a/b/resolve/main/f.safetensors');
    });
  });

  group('OpenModelDbApi', () {
    test('getModels', () async {
      final api = OpenModelDbApi(client: _jsonClient({
        '4x-x': {'name': 'X', 'scale': 4}
      }));
      expect((await api.getModels()).single.id, '4x-x');
      final bad = OpenModelDbApi(client: _jsonClient([]));
      expect(bad.getModels(), throwsA(isA<OpenModelDbApiException>()));
      final err = OpenModelDbApi(client: MockClient((r) async => http.Response('', 500)));
      expect(err.getModels(), throwsA(isA<OpenModelDbApiException>()));
    });
  });

  group('CivArchiveApi', () {
    test('getModels', () async {
      final api = CivArchiveApi(client: _jsonClient([
        {'id': 1, 'name': 'arch'}
      ]));
      expect((await api.getModels(query: 'q', page: 2)).single.name, 'arch');
      final bad = CivArchiveApi(client: _jsonClient({}));
      expect(bad.getModels(), throwsA(isA<CivArchiveApiException>()));
      final err = CivArchiveApi(client: MockClient((r) async => http.Response('', 500)));
      expect(err.getModels(), throwsA(isA<CivArchiveApiException>()));
    });
  });

  group('GitHubVersionsApi', () {
    test('getTags', () async {
      final api = GitHubVersionsApi(client: _jsonClient([
        {'name': 'v1.0'},
        {'name': ''},
      ]));
      expect(await api.getTags('https://github.com/a/b'), ['v1.0']);
    });

    test('getTags errors', () {
      final api = GitHubVersionsApi();
      expect(api.getTags('https://example.com/x/y'),
          throwsA(isA<GitHubApiException>()));
      expect(api.getTags('https://github.com/only'),
          throwsA(isA<GitHubApiException>()));
      expect(api.getTags('not a url'),
          throwsA(isA<GitHubApiException>()));
      final err = GitHubVersionsApi(client: MockClient((r) async => http.Response('', 500)));
      expect(err.getTags('https://github.com/a/b'),
          throwsA(isA<GitHubApiException>()));
      final bad = GitHubVersionsApi(client: _jsonClient({}));
      expect(bad.getTags('https://github.com/a/b'),
          throwsA(isA<GitHubApiException>()));
    });

    test('getBranches', () async {
      final api = GitHubVersionsApi(client: _jsonClient([
        {'name': 'main'},
        {'name': ''},
      ]));
      expect(await api.getBranches('https://github.com/a/b'), ['main']);
      final err = GitHubVersionsApi(client: MockClient((r) async => http.Response('', 500)));
      expect(err.getBranches('https://github.com/a/b'),
          throwsA(isA<GitHubApiException>()));
      final bad = GitHubVersionsApi(client: _jsonClient({}));
      expect(bad.getBranches('https://github.com/a/b'),
          throwsA(isA<GitHubApiException>()));
      final notGh = GitHubVersionsApi();
      expect(notGh.getBranches('https://gitlab.com/a/b'),
          throwsA(isA<GitHubApiException>()));
    });
  });

  group('VersionChecker', () {
    test('finds highest semver tag', () async {
      final checker = VersionChecker(client: _jsonClient([
        {'tag_name': 'v1.0.0'},
        {'tag_name': 'v2.1.0'},
        {'tag_name': 'notsemver'},
        {'tag_name': 5},
        'junk',
      ]));
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isTrue);
      expect(update.latestVersion, '2.1.0');
      expect(update.releaseUrl, contains('/releases/v2.1.0'));
      checker.close();
    });

    test('up to date', () async {
      final checker = VersionChecker(client: _jsonClient([
        {'tag_name': 'v0.5.0'}
      ]));
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isFalse);
      expect(update.latestVersion, '0.5.0');
    });

    test('no releases', () async {
      final checker = VersionChecker(client: _jsonClient(const <Object>[]));
      final update = await checker.check('1.0.0');
      expect(update.updateAvailable, isFalse);
      expect(update.latestVersion, '');
    });

    test('unparseable current version', () async {
      final checker = VersionChecker(client: _jsonClient([
        {'tag_name': 'v1.0.0'}
      ]));
      final update = await checker.check('dev');
      expect(update.updateAvailable, isTrue);
    });

    test('http error', () {
      final checker = VersionChecker(
          client: MockClient((r) async => http.Response('', 500)));
      expect(checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });

    test('bad shape', () {
      final checker = VersionChecker(client: _jsonClient({'a': 1}));
      expect(checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });

    test('network failure wraps', () {
      final checker = VersionChecker(
          client: MockClient((r) async => throw Exception('net')));
      expect(checker.check('1.0.0'), throwsA(isA<VersionCheckException>()));
    });
  });

  group('DownloadService', () {
    MockClient streamClient(List<int> bytes, {int status = 200}) =>
        MockClient.streaming((request, _) {
          return Future.value(http.StreamedResponse(
            Stream.value(bytes),
            status,
            contentLength: bytes.length,
          ));
        });

    test('enqueue downloads to completion', () async {
      final writer = RecordingFileWriter();
      final dl = DownloadService(
          client: streamClient([1, 2, 3, 4]), fileWriter: writer);
      final task = dl.enqueue(
          fileName: 'f.bin', url: 'https://x/f', destinationPath: '/tmp/f');
      expect(dl.tasks.single.isActive, isTrue);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.status, DownloadStatus.completed);
      expect(writer.written['/tmp/f'], [1, 2, 3, 4]);
      expect(dl.activeCount, 0);
    });

    test('failed download sets error', () async {
      final dl = DownloadService(client: streamClient([], status: 404));
      final task = dl.enqueue(fileName: 'f', url: 'https://x/f');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.status, DownloadStatus.failed);
      expect(task.errorMessage, contains('404'));
    });

    test('stream error marks failed', () async {
      final dl = DownloadService(
          client: MockClient.streaming((r, _) async =>
              http.StreamedResponse(Stream.error(Exception('io')), 200)));
      final task = dl.enqueue(fileName: 'f', url: 'https://x/f');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.status, DownloadStatus.failed);
      expect(task.errorMessage, isNotNull);
    });

    test('queued respects concurrency', () async {
      final gate = Completer<void>();
      final dl = DownloadService(
        maxConcurrent: 1,
        client: MockClient.streaming((r, _) async => http.StreamedResponse(
            Stream.fromFuture(gate.future.then((_) => [0])), 200)),
      );
      final t1 = dl.enqueue(fileName: 'a', url: 'https://x/1');
      final t2 = dl.enqueue(fileName: 'b', url: 'https://x/2');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(t1.status, DownloadStatus.downloading);
      expect(t2.status, DownloadStatus.queued);
      gate.complete();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(t1.status, DownloadStatus.completed);
      expect(t2.status, DownloadStatus.completed);
    });

    test('pause and resume', () async {
      final controller = StreamController<List<int>>();
      final dl = DownloadService(
          client: MockClient.streaming((r, _) async =>
              http.StreamedResponse(controller.stream, 200)));
      final task = dl.enqueue(fileName: 'f', url: 'https://x/f');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.add([1]);
      dl.pause(task);
      controller.add([2]);
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.close();
      expect(task.status, DownloadStatus.paused);
      dl.resume(task);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.isFinished || task.isActive, isTrue);
    });

    test('cancel queued and downloading', () async {
      final controller = StreamController<List<int>>();
      final dl = DownloadService(
          maxConcurrent: 1,
          client: MockClient.streaming((r, _) async =>
              http.StreamedResponse(controller.stream, 200)));
      final t1 = dl.enqueue(fileName: 'a', url: 'https://x/1');
      final t2 = dl.enqueue(fileName: 'b', url: 'https://x/2');
      await Future.delayed(const Duration(milliseconds: 50));
      dl.cancel(t1);
      await Future.delayed(const Duration(milliseconds: 50));
      await controller.close();
      dl.cancel(t2);
      expect(t2.isFinished, isTrue);
    });

    test('remove and clearCompleted', () async {
      final dl = DownloadService(client: streamClient([1]));
      final task = dl.enqueue(fileName: 'f', url: 'https://x/f');
      await Future.delayed(const Duration(milliseconds: 100));
      dl.clearCompleted();
      expect(dl.tasks, isEmpty);
      final t2 = dl.enqueue(fileName: 'g', url: 'https://x/g');
      dl.remove(t2);
      expect(dl.tasks, isEmpty);
    });

    test('resume failed restarts', () async {
      var calls = 0;
      final dl = DownloadService(
          client: MockClient.streaming((r, _) async {
        calls++;
        return http.StreamedResponse(
            Stream.value([1]), calls == 1 ? 500 : 200);
      }));
      final task = dl.enqueue(fileName: 'f', url: 'https://x/f');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.status, DownloadStatus.failed);
      dl.resume(task);
      await Future.delayed(const Duration(milliseconds: 100));
      expect(task.status, DownloadStatus.completed);
    });

    test('pause on queued is no-op, resume on active is no-op', () {
      final dl = DownloadService();
      final task = DownloadTask(
          id: 'x', fileName: 'f', url: 'u',
          status: DownloadStatus.downloading);
      dl.resume(task);
      expect(task.status, DownloadStatus.downloading);
      final queued = DownloadTask(id: 'y', fileName: 'f', url: 'u');
      dl.pause(queued);
      expect(queued.status, DownloadStatus.queued);
    });
  });

  group('exception toString', () {
    test('all exception types stringify', () {
      expect('${const CivitApiException('x')}', contains('x'));
      expect('${const HuggingFaceApiException('x')}', contains('x'));
      expect('${const OpenModelDbApiException('x')}', contains('x'));
      expect('${const CivArchiveApiException('x')}', contains('x'));
      expect('${const GitHubApiException('x')}', contains('x'));
      expect('${const VersionCheckException('x')}', contains('x'));
    });
  });
}
