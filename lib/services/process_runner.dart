import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class ProcessRunner {
  Stream<String> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    String? key,
  });
  Future<void> stop(String key);
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

class SystemProcessRunner implements ProcessRunner {
  final Map<String, Process> _processes = {};

  @override
  Stream<String> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    String? key,
  }) async* {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final id = key ?? executable;
    _processes[id] = process;
    final controller = StreamController<String>();
    final decoder = SystemEncoding().decoder;
    var open = 2;
    for (final output in [process.stdout, process.stderr]) {
      output
          .transform(decoder)
          .transform(const LineSplitter())
          .listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              if (--open == 0) unawaited(controller.close());
            },
          );
    }
    yield* controller.stream;
    _processes.remove(id);
  }

  @override
  Future<void> stop(String key) async {
    _processes.remove(key)?.kill();
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) => Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );
}
