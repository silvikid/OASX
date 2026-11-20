import 'dart:convert';
import 'dart:io';

import 'package:oasx/modules/server/models/oas_pythonw_selection.dart';

/// Result of one path-scoped pythonw.exe cleanup.
class PythonwCleanupResult {
  /// Creates one cleanup result.
  const PythonwCleanupResult({
    required this.supported,
    required this.enumerated,
    required this.selected,
    required this.killed,
    this.failure,
  });

  /// Whether the cleanup could run at all on this platform.
  final bool supported;

  /// How many pythonw.exe processes the process table reported.
  final int enumerated;

  /// Process ids that belong to this OAS install.
  final List<int> selected;

  /// Process ids that were stopped.
  final List<int> killed;

  /// Reason the cleanup did not finish, null when it did.
  final String? failure;
}

/// Stops the pythonw.exe processes that belong to one OAS install.
///
/// Windows has no cheap "find process by image path" call available to Dart,
/// so the process table is read through PowerShell once and filtered in Dart.
/// Only processes started from the exact interpreter at [pythonwPath] are
/// stopped, so unrelated pythonw.exe programs keep running.
class OasPythonwCleaner {
  /// Creates one cleaner for the given OAS root and interpreter.
  const OasPythonwCleaner({required this.rootPath, required this.pythonwPath});

  /// OAS root directory the deploy targets.
  final String rootPath;

  /// Interpreter OASX launches to run the OAS server.
  final String pythonwPath;

  /// Lists and stops every pythonw.exe process owned by this OAS install.
  Future<PythonwCleanupResult> cleanup() async {
    if (!Platform.isWindows) {
      return const PythonwCleanupResult(
        supported: false,
        enumerated: 0,
        selected: [],
        killed: [],
        failure: 'pythonw.exe cleanup only applies to Windows',
      );
    }

    final enumerate = await _runScript(_enumerateScript);
    if (enumerate.exitCode != 0) {
      return PythonwCleanupResult(
        supported: true,
        enumerated: 0,
        selected: const [],
        killed: const [],
        failure:
            _firstLine(enumerate.stderr) ?? 'could not read the process table',
      );
    }

    List<PythonwProcess> processes;
    try {
      processes = PythonwProcess.parseList(enumerate.stdout.toString());
    } catch (e) {
      return PythonwCleanupResult(
        supported: true,
        enumerated: 0,
        selected: const [],
        killed: const [],
        failure: 'could not read the process table: $e',
      );
    }

    final selection = OasPythonwSelection(
      rootPath: rootPath,
      pythonwPath: pythonwPath,
    );
    final targets = selection.selectTargetPids(processes);
    if (targets.isEmpty) {
      return PythonwCleanupResult(
        supported: true,
        enumerated: processes.length,
        selected: const [],
        killed: const [],
      );
    }

    final stop = await _runScript(
      _stopScript,
      environment: {'OAS_CLEANER_PIDS': targets.join(',')},
    );
    if (stop.exitCode != 0) {
      return PythonwCleanupResult(
        supported: true,
        enumerated: processes.length,
        selected: targets,
        killed: const [],
        failure:
            _firstLine(stop.stderr) ?? 'could not stop the owned processes',
      );
    }
    return PythonwCleanupResult(
      supported: true,
      enumerated: processes.length,
      selected: targets,
      killed: targets,
    );
  }

  /// Runs one PowerShell script from a temporary file.
  ///
  /// The script goes through a file because the process table query spans
  /// several lines and must not depend on command-line quote escaping.
  Future<ProcessResult> _runScript(
    String script, {
    Map<String, String>? environment,
  }) async {
    final file = File(
      '${Directory.systemTemp.path}\\oasx_pythonw_'
      '${DateTime.now().microsecondsSinceEpoch}.ps1',
    );
    try {
      await file.writeAsString(script, encoding: utf8);
      return await Process.run(
        _resolvePowerShellPath(),
        [
          '-NoLogo',
          '-NoProfile',
          '-NonInteractive',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          file.path,
        ],
        environment: environment,
        runInShell: false,
      );
    } finally {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static String? _firstLine(Object? stderr) {
    final text = stderr?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return text.split(RegExp(r'\r?\n')).first;
  }

  /// Resolves the Windows PowerShell path used for the process table.
  static String _resolvePowerShellPath() {
    final systemRoot = Platform.environment['SystemRoot'];
    if (systemRoot == null || systemRoot.isEmpty) {
      return 'powershell.exe';
    }
    return '$systemRoot\\System32\\WindowsPowerShell\\v1.0\\powershell.exe';
  }

  /// Reads every pythonw.exe process with its image path and command line.
  static const String _enumerateScript = r'''
$ErrorActionPreference = 'Stop'
$items = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='pythonw.exe'" |
  Select-Object ProcessId, ParentProcessId, ExecutablePath, CommandLine)
if ($items.Count -eq 0) { '[]' } else { ConvertTo-Json -InputObject $items -Compress -Depth 3 }
''';

  /// Stops the process ids passed in OAS_CLEANER_PIDS.
  static const String _stopScript = r'''
$ErrorActionPreference = 'Continue'
$raw = $env:OAS_CLEANER_PIDS
if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
foreach ($token in $raw.Split(',')) {
  $processId = 0
  if (-not [int]::TryParse($token.Trim(), [ref]$processId)) { continue }
  if ($processId -le 0) { continue }
  Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
}
''';
}
