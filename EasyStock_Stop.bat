@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title EasyStock OneKey Stop

rem One-click stop of easy-stock (frontend Vite process + backend container).
rem The browser tab stays open; close it yourself (other tabs are untouched).

set "ROOT=D:\Codex-WorkSpace2\ES"
set "BACKEND_PORT=20081"
set "FRONTEND_PORT=20073"
set "CONTAINER=easy-stock"

cd /d "%ROOT%" || (echo [ERR] Directory not found: %ROOT% & pause & exit /b 1)

rem ---------- Step 1: stop frontend Vite dev server ----------
echo [1/2] Stopping frontend on port %FRONTEND_PORT% ...
set "KILLED="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /c:":%FRONTEND_PORT% " ^| findstr /i "LISTENING"') do (
    taskkill /pid %%p /t /f >nul 2>&1
    echo [OK] Killed frontend PID %%p on port %FRONTEND_PORT%
    set "KILLED=1"
)
if not defined KILLED echo [INFO] No frontend listener on port %FRONTEND_PORT%.

rem ---------- Step 2: stop backend container ----------
echo [2/2] Stopping container %CONTAINER% ...
for /f "usebackq delims=" %%s in (`docker inspect -f "{{.State.Status}}" %CONTAINER% 2^>nul`) do set "STATE=%%s"
if not defined STATE (
    echo [INFO] No container named %CONTAINER% found.
) else (
    if "!STATE!"=="running" (
        docker stop %CONTAINER% >nul 2>&1
        echo [OK] Container %CONTAINER% stopped.
    ) else (
        echo [INFO] Container %CONTAINER% already !STATE!.
    )
)

ping -n 3 127.0.0.1 >nul
set "BPORT="
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /c:":%BACKEND_PORT% " ^| findstr /i "LISTENING"') do set "BPORT=%%p"

echo.
echo ===== EasyStock =====
if defined BPORT (
    echo   [WARN] Backend port %BACKEND_PORT% still busy ^(PID !BPORT!^) -- Docker NAT may take a moment.
) else (
    echo   Backend port %BACKEND_PORT%: free.
)
echo   Browser tab: close it manually.
echo   Start again: EasyStock_Start.bat
echo.
pause
endlocal
