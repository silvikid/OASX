import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/server/models/oas_pythonw_selection.dart';

void main() {
  const oasRoot = r'E:\Games\yys\OAS\OnmyojiAutoScript-easy-install';
  const oasPythonw = '$oasRoot\\toolkit\\pythonw.exe';
  const userPythonw =
      r'C:\Users\Admin\AppData\Local\Programs\Python\Python312\pythonw.exe';

  OasPythonwSelection selection({String pythonwPath = oasPythonw}) {
    return OasPythonwSelection(rootPath: oasRoot, pythonwPath: pythonwPath);
  }

  group('parseList', () {
    test('reads a PowerShell array payload', () {
      const payload =
          '[{"ProcessId":10,"ParentProcessId":1,'
          '"ExecutablePath":"C:\\\\a\\\\pythonw.exe",'
          '"CommandLine":"pythonw.exe  server.py"}]';

      final processes = PythonwProcess.parseList(payload);

      expect(processes.single.pid, 10);
      expect(processes.single.parentPid, 1);
      expect(processes.single.executablePath, r'C:\a\pythonw.exe');
      expect(processes.single.commandLine, 'pythonw.exe  server.py');
    });

    test('reads a single object payload', () {
      final processes = PythonwProcess.parseList(
        '{"ProcessId":7,"ParentProcessId":2,"ExecutablePath":null}',
      );

      expect(processes.single.pid, 7);
      expect(processes.single.parentPid, 2);
      expect(processes.single.executablePath, isNull);
    });

    test('treats an empty payload as no process', () {
      expect(PythonwProcess.parseList('  '), isEmpty);
      expect(PythonwProcess.parseList('[]'), isEmpty);
    });

    test('skips entries without a usable pid', () {
      final processes = PythonwProcess.parseList(
        '[{"ProcessId":0},{"ParentProcessId":3},{"ProcessId":5}]',
      );

      expect(processes.single.pid, 5);
    });
  });

  group('selectTargetPids', () {
    test('keeps pythonw.exe started from another interpreter', () {
      final processes = [
        const PythonwProcess(
          pid: 100,
          parentPid: 1,
          executablePath: oasPythonw,
          commandLine: '$oasPythonw  server.py',
        ),
        const PythonwProcess(
          pid: 200,
          parentPid: 1,
          executablePath: userPythonw,
          commandLine: '$userPythonw power_plan_tray.pyw',
        ),
      ];

      expect(selection().selectTargetPids(processes), [100]);
    });

    test('selects the OAS server and its multiprocessing children', () {
      final processes = [
        const PythonwProcess(
          pid: 100,
          parentPid: 1,
          executablePath: oasPythonw,
          commandLine: '$oasPythonw  server.py',
        ),
        const PythonwProcess(
          pid: 101,
          parentPid: 100,
          executablePath: oasPythonw,
          commandLine: '"$oasPythonw" "-c" "spawn_main(parent_pid=100)"',
        ),
        const PythonwProcess(
          pid: 102,
          parentPid: 101,
          executablePath: oasPythonw,
        ),
      ];

      expect(selection().selectTargetPids(processes), [100, 101, 102]);
    });

    test('matches the interpreter path ignoring case and separators', () {
      final processes = [
        const PythonwProcess(
          pid: 100,
          parentPid: 1,
          executablePath:
              r'e:/games/yys/oas/onmyojiautoscript-easy-install/toolkit/Pythonw.exe',
          commandLine: 'server.py',
        ),
      ];

      expect(selection().selectTargetPids(processes), [100]);
    });

    test('returns nothing when it cannot tell which processes are OAS', () {
      final processes = [
        const PythonwProcess(
          pid: 200,
          parentPid: 1,
          executablePath: userPythonw,
          commandLine: 'tray.pyw',
        ),
        const PythonwProcess(pid: 201, parentPid: 1),
      ];

      expect(selection().selectTargetPids(processes), isEmpty);
    });

    test('returns nothing when the configured interpreter is unknown', () {
      expect(
        selection(pythonwPath: '   ').selectTargetPids(const [
          PythonwProcess(pid: 100, parentPid: 1, executablePath: oasPythonw),
        ]),
        isEmpty,
      );
    });

    test('limits itself to the server tree for a shared interpreter', () {
      const sharedPythonw =
          r'C:\Users\Admin\AppData\Local\Programs\Python\Python312\pythonw.exe';
      final processes = [
        const PythonwProcess(
          pid: 300,
          parentPid: 1,
          executablePath: sharedPythonw,
          commandLine: '"$sharedPythonw" server.py',
        ),
        const PythonwProcess(
          pid: 301,
          parentPid: 300,
          executablePath: sharedPythonw,
          commandLine: 'spawn_main(parent_pid=300)',
        ),
        const PythonwProcess(
          pid: 302,
          parentPid: 1,
          executablePath: sharedPythonw,
          commandLine: '"$sharedPythonw" power_plan_tray.pyw',
        ),
      ];

      expect(
        selection(pythonwPath: sharedPythonw).selectTargetPids(processes),
        [300, 301],
      );
    });
  });
}
