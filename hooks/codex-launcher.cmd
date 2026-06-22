: << 'CMDBLOCK'
@echo off
REM Codex SessionStart launcher (Windows path).
REM cmd.exe runs this batch portion and dispatches to PowerShell.
REM bash on Unix consumes the lines between : << 'CMDBLOCK' and CMDBLOCK
REM as a no-op heredoc, then runs the bash section after.
REM
REM Pinned to LF in .gitattributes so the heredoc terminator parses on Unix.
REM cmd.exe accepts LF for this simple linear batch on Windows 10/11.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0session-end-nudge.ps1"
exit /b %ERRORLEVEL%
CMDBLOCK

# Unix: run the bash session-end-nudge directly. PowerShell isn't standard
# on Linux/macOS, and the bash script already emits the correct nested
# hookSpecificOutput.additionalContext shape when PLUGIN_ROOT is set
# (which Codex does).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "${SCRIPT_DIR}/session-end-nudge"
