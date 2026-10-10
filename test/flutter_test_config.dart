import 'dart:async';

import "dart:io";

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final bool passed =
        result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }
    final String error =
        await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  goldenFileComparator = TolerantGoldenComparator(
    Uri.file('${Directory.current.path}/test/flutter_test_config.dart'),
    precisionTolerance: 0.05,
  );
  await testMain();
}
