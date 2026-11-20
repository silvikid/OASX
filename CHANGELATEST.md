# v0.3.28

## 改进 | Improved
- 启动 OAS 前的 pythonw.exe 清理不再按进程名全杀：改为读取进程表后按**解释器路径**筛选，只结束本 OAS 目录下 `toolkit\pythonw.exe` 启动的进程（含其 multiprocessing 子进程），机器上其它 pythonw.exe 程序不再被误杀
- 当 `deploy.yaml` 里的 Python 指向 OAS 目录之外（与其它脚本共用一个解释器）时，只结束带 `server.py` 的进程及其子进程
- 清理过程写日志：无进程在跑、跳过原因、实际结束的 PID 都会记录在部署日志里
- 清理前先读取一次进程表，失败或无法判定归属时宁可不杀也不误杀

## 修复 | Fixed
- 修复 `taskkill /f /t /im pythonw.exe` 会连带杀掉用户自己写的 pythonw.exe 托盘程序的问题
- 去掉为全量 taskkill 特判的一整套「进程不存在就静默跳过」容错代码（`ignorePythonwNotRunning` 等），启动日志不再出现误导性的 taskkill 提示

