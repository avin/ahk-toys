# Repository instructions

## AutoHotkey validation

- The scripts in this repository use AutoHotkey v2 when they declare `#Requires AutoHotkey v2.0`.
- Do not invoke `C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe` without an explicitly configured AutoHotkey v2-compatible base. On this machine its default interpreter is AutoHotkey v1.1.37.02, which opens a modal `Ahk2Exe Error` dialog for v2 scripts.
- Do not treat the compiler process exit code alone as a successful validation: `Ahk2Exe` can leave an error dialog running while the calling command reports exit code 0.
- Prefer a known headless, v2-compatible syntax check. Do not execute persistent scripts merely to validate syntax because they can launch applications or replace the user's running script.
- If any validation unexpectedly opens a GUI error dialog, close the spawned validator process and report the validation as failed.
