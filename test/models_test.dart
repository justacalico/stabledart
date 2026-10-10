import 'package:flutter_test/flutter_test.dart';
import 'package:stabledart/models/app_settings.dart';
import 'package:stabledart/models/app_update.dart';
import 'package:stabledart/models/chat_message.dart';
import 'package:stabledart/models/civit_models.dart';
import 'package:stabledart/models/console_entry.dart';
import 'package:stabledart/models/download_task.dart';
import 'package:stabledart/models/hf_models.dart';
import 'package:stabledart/models/installed_package.dart';
import 'package:stabledart/models/launch_option.dart';
import 'package:stabledart/models/local_model.dart';
import 'package:stabledart/models/omdb_models.dart';
import 'package:stabledart/models/output_image.dart';
import 'package:stabledart/models/package_definition.dart';
import 'package:stabledart/models/workflow.dart';
import 'package:stabledart/utils/number_format.dart';

void main() {
  group('AppUpdate', () {
    test('copyWith and equality', () {
      const a = AppUpdate(currentVersion: '1.0.0');
      final b = a.copyWith(latestVersion: '2.0.0', updateAvailable: true);
      expect(b.latestVersion, '2.0.0');
      expect(b.updateAvailable, isTrue);
      expect(b == a.copyWith(latestVersion: '2.0.0', updateAvailable: true), isTrue);
      expect(a == b, isFalse);
      expect(a.hashCode, isA<int>());
    });
  });

  group('LaunchOption', () {
    test('toArgString', () {
      final toggle = LaunchOption.toggle('xformers', '--xformers');
      expect(toggle.toArgString(), isNull);
      toggle.enabled = true;
      expect(toggle.toArgString(), '--xformers');

      final value = LaunchOption(name: 'port', flag: '--port', enabled: true);
      expect(value.toArgString(), isNull);
      value.value = '8080';
      expect(value.toArgString(), '--port 8080');

      final bare = LaunchOption(name: 'extra', enabled: true, value: '--foo');
      expect(bare.toArgString(), '--foo');
    });

    test('json round trip', () {
      final option = LaunchOption(name: 'x', flag: '--x', isToggle: true);
      option.applyJson({'enabled': true, 'value': '5'});
      expect(option.enabled, isTrue);
      expect(option.value, '5');
      final json = option.toJson();
      expect(json['name'], 'x');
      expect(json['enabled'], isTrue);
    });
  });

  group('PackageDefinition', () {
    test('fields', () {
      final def = PackageDefinition(
        name: 'test',
        displayName: 'Test',
        author: 'me',
        description: 'desc',
        repositoryUrl: 'https://github.com/a/b',
        accentColor: 0xFF0000,
        launchOptions: () => [],
      );
      expect(def.tags, isEmpty);
      expect(def.baseImageModel, 'SD 1.5');
      expect(def.launchOptions(), isEmpty);
    });
  });

  group('InstalledPackage', () {
    test('json round trip', () {
      final pkg = InstalledPackage(
        id: 'p1',
        packageName: 'ComfyUI',
        displayName: 'ComfyUI',
        version: '1.0',
        installPath: '/data/Packages/ComfyUI',
        installedAt: DateTime(2024, 1, 1),
        launchArgs: const [
          {'name': 'cpu', 'enabled': true, 'value': null}
        ],
      );
      final decoded = InstalledPackage.fromJson(pkg.toJson());
      expect(decoded.id, 'p1');
      expect(decoded.packageName, 'ComfyUI');
      expect(decoded.launchArgs.length, 1);
      expect(decoded.isRunning, isFalse);
    });

    test('fromJson handles missing fields', () {
      final pkg = InstalledPackage.fromJson({'id': 'x', 'packageName': 'n', 'displayName': 'd'});
      expect(pkg.version, '');
      expect(pkg.installedAt.millisecondsSinceEpoch, 0);
    });
  });

  group('DownloadTask', () {
    test('progress and status flags', () {
      final t = DownloadTask(id: 'd1', fileName: 'f', url: 'u');
      expect(t.progress, 0);
      expect(t.isActive, isTrue);
      expect(t.isFinished, isFalse);
      t.status = DownloadStatus.downloading;
      t.totalBytes = 100;
      t.receivedBytes = 25;
      expect(t.progress, 0.25);
      t.status = DownloadStatus.completed;
      expect(t.isActive, isFalse);
      expect(t.isFinished, isTrue);
      t.status = DownloadStatus.failed;
      expect(t.isFinished, isTrue);
      t.status = DownloadStatus.cancelled;
      expect(t.isFinished, isTrue);
      t.status = DownloadStatus.paused;
      expect(t.isActive, isFalse);
    });
  });

  group('Civit models', () {
    test('fromJson full', () {
      final json = {
        'id': 1,
        'name': 'Model',
        'type': 'Checkpoint',
        'creator': {'username': 'alice'},
        'description': 'd',
        'tags': ['a', 'b'],
        'nsfw': true,
        'stats': {
          'downloadCount': 100,
          'favoriteCount': 10,
          'commentCount': 5,
          'rating': 4.5,
        },
        'modelVersions': [
          {
            'id': 2,
            'name': 'v1',
            'baseModel': 'SD 1.5',
            'description': 'vd',
            'downloadCount': 50,
            'rating': 4.0,
            'files': [
              {
                'id': 3,
                'name': 'm.safetensors',
                'sizeKB': 2048,
                'downloadUrl': 'https://x/f',
                'primary': true,
                'hashes': {'SHA256': 'abc'},
              }
            ],
            'images': [
              {'id': 4, 'url': 'https://x/i', 'nsfw': false, 'width': 512, 'height': 512}
            ],
          }
        ],
      };
      final m = CivitModel.fromJson(json);
      expect(m.name, 'Model');
      expect(m.creator, 'alice');
      expect(m.downloadCount, 100);
      expect(m.favoriteCount, 10);
      expect(m.commentCount, 5);
      expect(m.rating, 4.5);
      expect(m.nsfw, isTrue);
      expect(m.thumbnailUrl, 'https://x/i');
      final v = m.versions.first;
      expect(v.baseModel, 'SD 1.5');
      expect(v.files.first.sha256, 'abc');
      expect(v.files.first.sizeBytes, 2048 * 1024);
      expect(v.images.first.width, 512);
    });

    test('fromJson handles missing creator and stats', () {
      final m = CivitModel.fromJson({'id': 1, 'name': 'x'});
      expect(m.creator, '');
      expect(m.downloadCount, 0);
      expect(m.rating, 0);
      expect(m.thumbnailUrl, isNull);
    });

    test('model type enums', () {
      expect(CivitModelType.checkpoint.apiValue, 'Checkpoint');
      expect(CivitModelType.all.apiValue, '');
      expect(CivitModelType.textualInversion.displayName, 'Textual Inversion');
      expect(CivitModelType.lora.apiValue, 'LORA');
      expect(CivitModelType.locon.apiValue, 'LoCon');
      expect(CivitModelType.controlnet.apiValue, 'Controlnet');
      expect(CivitModelType.aestheticGradient.apiValue, 'AestheticGradient');
      expect(CivitModelType.hypernetwork.apiValue, 'Hypernetwork');
      expect(CivitModelType.upscaler.displayName, 'Upscaler');
      expect(CivitModelType.motionModule.apiValue, 'MotionModule');
      expect(CivitModelType.vae.displayName, 'VAE');
      expect(CivitModelType.poses.apiValue, 'Poses');
      expect(CivitModelType.wildcards.apiValue, 'Wildcards');
      expect(CivitModelType.workflows.apiValue, 'Workflows');
      expect(CivitModelType.other.apiValue, 'Other');
      expect(CivitModelType.checkpoint.displayName, 'Checkpoint');
    });

    test('file without hashes', () {
      final f = CivitModelFile.fromJson({'id': 1, 'name': 'x'});
      expect(f.sha256, '');
      expect(f.primary, isFalse);
    });
  });

  group('HuggingFace models', () {
    test('fromJson', () {
      final m = HuggingFaceModel.fromJson({
        'id': 'org/name',
        'pipeline_tag': 'text-to-image',
        'tags': ['a'],
        'downloads': 5,
        'likes': 2,
        'lastModified': '2024-01-01T00:00:00.000Z',
      });
      expect(m.author, 'org');
      expect(m.name, 'name');
      expect(m.pipelineTag, 'text-to-image');
      expect(m.lastModified, isNotNull);

      final m2 = HuggingFaceModel.fromJson({'modelId': 'plain'});
      expect(m2.author, '');
      expect(m2.name, 'plain');
    });

    test('files fromJson', () {
      final f = HuggingFaceFile.fromJson({
        'path': 'a/b.safetensors',
        'lfs': {'size': 100, 'oid': 'x'},
      });
      expect(f.size, 100);
      expect(f.lfsOid, 'x');
      final f2 = HuggingFaceFile.fromJson({'rfilename': 'r'});
      expect(f2.path, 'r');
      expect(f2.size, 0);
      expect(f2.lfsOid, isNull);
    });
  });

  group('OpenModelDB models', () {
    test('fromJson', () {
      final m = OpenModelDbModel.fromJson('4x-UltraSharp', {
        'name': 'UltraSharp',
        'author': ['a', 'b'],
        'description': 'd',
        'tags': ['t'],
        'images': [
          {'SRGB': {'url': 'https://x/1'}},
          'https://x/2',
        ],
        'resources': [
          {'urls': ['https://x/dl']}
        ],
        'scale': 4,
        'architecture': 'ESRGAN',
      });
      expect(m.name, 'UltraSharp');
      expect(m.author, 'a, b');
      expect(m.images.length, 2);
      expect(m.resources, ['https://x/dl']);
      expect(m.scale, 4);
      expect(m.thumbnailUrl, 'https://x/1');
    });

    test('fromJson minimal', () {
      final m = OpenModelDbModel.fromJson('id', {'author': 'x'});
      expect(m.author, 'x');
      expect(m.scale, 1);
      expect(m.thumbnailUrl, isNull);
    });
  });

  group('LocalModelFile', () {
    test('json round trip', () {
      final m = LocalModelFile(
        id: 'm1',
        fileName: 'a.safetensors',
        category: ModelCategory.lora,
        sizeBytes: 100,
        title: 'T',
        author: 'A',
        description: 'D',
        thumbnailUrl: 'u',
        civitModelId: 7,
        isShared: false,
      );
      final d = LocalModelFile.fromJson(m.toJson());
      expect(d.category, ModelCategory.lora);
      expect(d.displayTitle, 'T');
      expect(d.isShared, isFalse);
      final m2 = LocalModelFile(id: 'x', fileName: 'f.ckpt');
      expect(m2.displayTitle, 'f.ckpt');
    });

    test('categories', () {
      for (final c in ModelCategory.values) {
        expect(c.displayName.isNotEmpty, isTrue);
        expect(c.folderName.isNotEmpty, isTrue);
      }
      expect(ModelCategory.fromName('lora'), ModelCategory.lora);
      expect(ModelCategory.fromName('VAE'), ModelCategory.vae);
      expect(ModelCategory.fromName('bogus'), ModelCategory.unknown);
    });
  });

  group('OutputImage', () {
    test('json round trip', () {
      final o = OutputImage(
        id: 'o1',
        filePath: 'a/b.png',
        packageName: 'p',
        prompt: 'cat',
        negativePrompt: 'dog',
        seed: 42,
        sampler: 'Euler a',
        steps: 20,
        cfgScale: 7.5,
        width: 512,
        height: 768,
        createdAt: DateTime(2024),
      );
      final d = OutputImage.fromJson(o.toJson());
      expect(d.prompt, 'cat');
      expect(d.cfgScale, 7.5);
      expect(d.seed, 42);
    });
  });

  group('InstalledWorkflow', () {
    test('json round trip', () {
      final w = InstalledWorkflow(
        id: 'w1',
        name: 'wf',
        description: 'd',
        author: 'a',
        baseModel: 'SDXL',
        requiredNodes: const ['n1'],
        installedAt: DateTime(2024),
      );
      final d = InstalledWorkflow.fromJson(w.toJson());
      expect(d.name, 'wf');
      expect(d.requiredNodes, ['n1']);
    });
  });

  group('ConsoleEntry', () {
    test('creates with defaults', () {
      final e = ConsoleEntry('hello');
      expect(e.level, ConsoleLevel.info);
      expect(e.timestamp, isA<DateTime>());
    });
  });

  group('chat messages', () {
    test('json round trip', () {
      final m = ImageLabMessage(
        id: 'm1',
        role: 'user',
        text: 'hi',
        imageUrls: const ['u'],
        timestamp: DateTime(2024),
      );
      final d = ImageLabMessage.fromJson(m.toJson());
      expect(d.text, 'hi');
      expect(d.imageUrls, ['u']);

      final c = ImageLabConversation(
        id: 'c1',
        title: 'chat',
        providerId: 'gemini',
        messages: [m],
      );
      final dc = ImageLabConversation.fromJson(c.toJson());
      expect(dc.title, 'chat');
      expect(dc.messages.length, 1);
      expect(dc.providerId, 'gemini');
    });
  });

  group('AppSettings', () {
    test('json round trip', () {
      final s = AppSettings(
        dataDirectory: '/data',
        themeMode: AppThemeMode.light,
        language: 'ja_JP',
        numberFormat: NumberFormatMode.space,
        holidayMode: HolidayMode.on,
        alwaysShowScrollbars: true,
        discordRichPresence: false,
        autoSearchModelBrowser: true,
        baseModelFilters: {'SDXL'},
        infiniteScrollingWorkflows: false,
        consoleHistorySize: 500,
        maxConcurrentDownloads: 7,
        importMoveNotCopy: true,
        removeSymlinksOnShutdown: true,
        showUnsupportedPythonVersions: true,
        environmentVariables: {'A': 'B'},
        analyticsEnabled: true,
        analyticsOptInSeen: true,
        firstLaunchComplete: true,
        notificationLevel: NotificationLevel.important,
        civitAiApiKey: 'k1',
        huggingFaceApiKey: 'k2',
        geminiApiKey: 'k3',
        lykosAccountName: 'user',
        updateCheckOnLaunch: false,
        updatePrerelease: true,
        inferenceModelDirectory: '/models',
        inferenceSharedOutput: false,
        defaultSteps: 30,
        defaultCfgScale: 5.5,
        defaultWidth: 768,
        defaultHeight: 1024,
      );
      final d = AppSettings.fromJson(s.toJson());
      expect(d.dataDirectory, '/data');
      expect(d.themeMode, AppThemeMode.light);
      expect(d.numberFormat, NumberFormatMode.space);
      expect(d.baseModelFilters, {'SDXL'});
      expect(d.environmentVariables, {'A': 'B'});
      expect(d.notificationLevel, NotificationLevel.important);
      expect(d.defaultCfgScale, 5.5);
    });

    test('fromJson defaults', () {
      final s = AppSettings.fromJson({});
      expect(s.themeMode, AppThemeMode.dark);
      expect(s.notificationLevel, NotificationLevel.all);
      expect(s.holidayMode, HolidayMode.auto);
      expect(s.defaultSteps, 20);
      expect(s.numberFormat, NumberFormatMode.comma);
      expect(s.themeMode, AppThemeMode.dark);
    });
  });
  test('omdb model with string images', () {
    final model = OpenModelDbModel.fromJson('m', {
      'name': 'x',
      'images': [
        'https://x/a.png',
        {'url': 'https://x/b.png'},
        {'LR': 'skip'},
      ],
    });
    expect(model.images.length, 2);
  });
}
