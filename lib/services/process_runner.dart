import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class ProcessRunner {
  Stream<String> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
  Future<void> stop(String executable);
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  });
}

class SystemProcessRunner implements ProcessRunner {
  Process? _process;

  @override
  Stream<String> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async* {
    _process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    yield* _process!.stdout
        .transform(SystemEncoding().decoder)
        .transform(const LineSplitter());
  }

  @override
  Future<void> stop(String executable) async {
    _process?.kill();
    _process = null;
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
