@echo off
REM Starts Nodro in a local web server and prints the address to open.
REM
REM One command, no arguments, no build step. Flutter is not on this machine's
REM PATH, so the path is set here rather than asking anyone to configure it.
REM
REM Stop the server with Ctrl+C.

setlocal
set "PATH=C:\flutter\bin;%PATH%"
cd /d "%~dp0"

echo.
echo   Nodro — starting local server...
echo   When it says "is being served at", open this address:
echo.
echo       http://localhost:8080
echo.

flutter run -d web-server --web-port 8080 --web-hostname localhost
