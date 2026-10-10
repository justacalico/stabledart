import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stabledart/utils/paths.dart';
import 'package:stabledart/utils/file_size.dart';
import 'package:stabledart/utils/number_format.dart';
import 'package:stabledart/utils/time_ago.dart';
import 'package:stabledart/utils/version_utils.dart';

void main() {
  group('Version', () {
    test('parses valid versions', () {
      expect(Version.parse('1.2.3')!.core, [1, 2, 3]);
      expect(Version.parse('v2.0.0')!.core, [2, 0, 0]);
      expect(Version.parse('1.2.3-rc.1')!.pre, ['rc', '1']);
      expect(Version.parse('1.2.3+build')!.core, [1, 2, 3]);
      expect(Version.parse('  4.5.6  ')!.core, [4, 5, 6]);
    });

    test('rejects invalid versions', () {
      expect(Version.parse(null), isNull);
      expect(Version.parse(''), isNull);
      expect(Version.parse('1.2'), isNull);
      expect(Version.parse('1.2.3.4'), isNull);
      expect(Version.parse('a.b.c'), isNull);
      expect(Version.parse('01.2.3'), isNull);
      expect(Version.parse('1.2.3-'), isNull);
      expect(Version.parse('1.2.3-rc_1'), isNull);
      expect(Version.parse('1.2.3-01'), isNull);
      expect(Version.parse('-1.2.3'), isNull);
    });

    test('compares versions', () {
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('2.0.0')!), lessThan(0));
      expect(Version.parse('1.1.0')!.compareTo(Version.parse('1.0.9')!), greaterThan(0));
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0')!), 0);
      expect(Version.parse('1.0.0-rc.1')!.compareTo(Version.parse('1.0.0')!), lessThan(0));
      expect(Version.parse('1.0.0')!.compareTo(Version.parse('1.0.0-rc.1')!), greaterThan(0));
      expect(Version.parse('1.0.0-2')!.compareTo(Version.parse('1.0.0-10')!), lessThan(0));
      expect(Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-1')!), greaterThan(0));
      expect(Version.parse('1.0.0-a.1')!.compareTo(Version.parse('1.0.0-a')!), greaterThan(0));
      expect(Version.parse('1.0.0-a')!.compareTo(Version.parse('1.0.0-a')!), 0);
    });

    test('equality and hashCode', () {
      expect(Version.parse('1.2.3'), equals(Version.parse('1.2.3')));
      expect(Version.parse('1.2.3-rc.1'), equals(Version.parse('1.2.3-rc.1')));
      expect(Version.parse('1.2.3') == Version.parse('1.2.4'), isFalse);
      expect(Version.parse('1.2.3')!.hashCode, isA<int>());
      expect('${Version.parse('v1.2.3')}', '1.2.3');
      expect('${Version.parse('1.2.3-rc.1')}', '1.2.3-rc.1');
    });
  });

  group('file size', () {
    test('formats bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(-5), '0 B');
      expect(formatBytes(512), '512 B');
      expect(formatBytes(2048), '2.0 KiB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MiB');
      expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GiB');
      expect(formatBytes(2 * 1024 * 1024 * 1024 * 1024), '2.0 TiB');
      expect(formatBytes(1024 * 1024 * 1024 * 1024 * 1024), '1024.0 TiB');
    });

    test('formats speed', () {
      expect(formatSpeed(1536), '1.5 KiB/s');
      expect(formatSpeed(0), '0 B/s');
    });
  });

  group('time ago', () {
    test('formats durations', () {
      final now = DateTime(2024, 6, 1, 12);
      expect(timeAgo(now.subtract(const Duration(seconds: 3)), now: now), 'just now');
      expect(timeAgo(now.subtract(const Duration(seconds: 30)), now: now), '30s ago');
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
      expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
      expect(timeAgo(now.subtract(const Duration(days: 10)), now: now), '10d ago');
      expect(timeAgo(now.subtract(const Duration(days: 90)), now: now), '3mo ago');
      expect(timeAgo(now.subtract(const Duration(days: 800)), now: now), '2y ago');
      expect(timeAgo(now.add(const Duration(days: 1)), now: now), 'just now');
    });
  });

  group('number format', () {
    test('formats numbers', () {
      expect(formatNumber(1234567, NumberFormatMode.comma), '1,234,567');
      expect(formatNumber(1234567, NumberFormatMode.period), '1.234.567');
      expect(formatNumber(1234567, NumberFormatMode.space), '1 234 567');
      expect(formatNumber(1234567, NumberFormatMode.none), '1234567');
      expect(formatNumber(42, NumberFormatMode.comma), '42');
    });

    test('display names and samples', () {
      expect(NumberFormatMode.comma.displayName, 'Comma');
      expect(NumberFormatMode.period.displayName, 'Period');
      expect(NumberFormatMode.space.displayName, 'Space');
      expect(NumberFormatMode.none.displayName, 'None');
      expect(NumberFormatMode.comma.sample, '1,234,567');
      expect(NumberFormatMode.period.sample, '1.234.567');
      expect(NumberFormatMode.space.sample, '1 234 567');
      expect(NumberFormatMode.none.sample, '1234567');
    });

    test('fromName', () {
      expect(NumberFormatMode.fromName('comma'), NumberFormatMode.comma);
      expect(NumberFormatMode.fromName('period'), NumberFormatMode.period);
      expect(NumberFormatMode.fromName('space'), NumberFormatMode.space);
      expect(NumberFormatMode.fromName('none'), NumberFormatMode.none);
      expect(NumberFormatMode.fromName('bogus'), NumberFormatMode.comma);
    });
  });

  group('paths', () {
    test('expandHome expands tilde', () {
      expect(expandHome('~/foo/bar'),
          contains(Platform.environment['HOME'] ?? ''));
      expect(expandHome('/abs/path'), '/abs/path');
    });

    test('downloadDestination joins models dir', () {
      expect(downloadDestination('~/data', 'm.safetensors'),
          contains('/Models/m.safetensors'));
    });
  });
}
