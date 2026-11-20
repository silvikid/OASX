import 'dart:convert';

/// One pythonw.exe process reported by the Windows process table.
class PythonwProcess {
  /// Creates one process snapshot.
  const PythonwProcess({
    required this.pid,
    required this.parentPid,
    this.executablePath,
    this.commandLine,
  });

  /// Process identifier.
  final int pid;

  /// Identifier of the parent process, 0 when Windows does not report one.
  final int parentPid;

  /// Full path of the interpreter image, null when Windows hides it.
  final String? executablePath;

  /// Full command line, null when Windows hides it.
  final String? commandLine;

  /// Parses the JSON payload printed by the pythonw.exe enumeration script.
  ///
  /// PowerShell emits an array for several matches and a bare object for a
  /// single match, so both shapes are accepted. Entries without a usable
  /// process id are skipped instead of failing the whole deploy.
  static List<PythonwProcess> parseList(String payload) {
    final trimmed = payload.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final dynamic decoded = jsonDecode(trimmed);
    final items = decoded is List ? decoded : [decoded];
    final result = <PythonwProcess>[];
    for (final item in items) {
      if (item is! Map) {
        continue;
      }
      final pid = _readInt(item, 'processid');
      if (pid == null || pid <= 0) {
        continue;
      }
      result.add(
        PythonwProcess(
          pid: pid,
          parentPid: _readInt(item, 'parentprocessid') ?? 0,
          executablePath: _readString(item, 'executablepath'),
          commandLine: _readString(item, 'commandline'),
        ),
      );
    }
    return result;
  }

  static dynamic _read(Map<dynamic, dynamic> item, String key) {
    for (final entry in item.entries) {
      if (entry.key.toString().toLowerCase() == key) {
        return entry.value;
      }
    }
    return null;
  }

  static int? _readInt(Map<dynamic, dynamic> item, String key) {
    final value = _read(item, key);
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static String? _readString(Map<dynamic, dynamic> item, String key) {
    final value = _read(item, key);
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

/// Decides which pythonw.exe processes belong to one OAS install.
class OasPythonwSelection {
  /// Creates one selection for the given OAS root and interpreter.
  const OasPythonwSelection({
    required this.rootPath,
    required this.pythonwPath,
  });

  /// OAS root directory the deploy targets.
  final String rootPath;

  /// Interpreter OASX launches to run the OAS server.
  final String pythonwPath;

  /// Returns the process ids to stop before a new deploy starts.
  ///
  /// Ownership is decided by the interpreter image path, never by the image
  /// name: anything started from this exact pythonw.exe belongs to the install,
  /// while other pythonw.exe programs on the machine keep running. When the
  /// configured interpreter lives outside the OAS root it may host unrelated
  /// scripts, so only the server process and its children are returned.
  List<int> selectTargetPids(List<PythonwProcess> processes) {
    final interpreter = _normalize(pythonwPath);
    if (interpreter == null) {
      return const [];
    }
    final owned = processes
        .where((process) => _normalize(process.executablePath) == interpreter)
        .toList();
    if (owned.isEmpty) {
      return const [];
    }

    final root = _normalize(rootPath);
    final scopedToRoot = root != null && interpreter.startsWith('$root\\');
    if (scopedToRoot) {
      return _sortedPids(owned);
    }

    final selected = <int>{
      for (final process in owned)
        if (_runsOasServer(process)) process.pid,
    };
    if (selected.isEmpty) {
      return const [];
    }
    var expanded = true;
    while (expanded) {
      expanded = false;
      for (final process in owned) {
        if (selected.contains(process.pid)) {
          continue;
        }
        if (selected.contains(process.parentPid)) {
          selected.add(process.pid);
          expanded = true;
        }
      }
    }
    return selected.toList()..sort();
  }

  static List<int> _sortedPids(List<PythonwProcess> processes) {
    return processes.map((process) => process.pid).toList()..sort();
  }

  static bool _runsOasServer(PythonwProcess process) {
    final commandLine = _normalize(process.commandLine);
    return commandLine != null && commandLine.contains('server.py');
  }

  static String? _normalize(String? path) {
    if (path == null) {
      return null;
    }
    final trimmed = path.trim().replaceAll('"', '');
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.replaceAll('/', '\\').toLowerCase();
  }
}
