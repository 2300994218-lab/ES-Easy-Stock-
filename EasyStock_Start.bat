@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title EasyStock OneKey Start

rem One-click start of easy-stock (backend container + frontend Vite + browser).
rem The image easy-stock:latest and frontend\node_modules are ready; startup needs no network.

set "ROOT=D:\Codex-WorkSpace2\ES"
set "BACKEND_PORT=20081"
set "FRONTEND_PORT=20073"
set "LOCAL=http://127.0.0.1:%BACKEND_PORT%"
set "SHOW=http://localhost:%FRONTEND_PORT%"
set "CONTAINER=easy-stock"
set "IMAGE=easy-stock:latest"

cd /d "%ROOT%" || (echo [ERR] Directory not found: %ROOT% & pause & exit /b 1)

where docker >nul 2>&1 || (echo [ERR] docker.exe not in PATH & pause & exit /b 1)
docker info >nul 2>&1 || (echo [ERR] Docker engine not running -- start Docker Desktop first. & pause & exit /b 1)

if not exist "%ROOT%\frontend\node_modules\" (
    echo [ERR] frontend\node_modules not found.
    echo       Install once:  cd frontend  ^&^&  npm install --ignore-scripts
    pause & exit /b 1
)

rem ---------- Step 1: backend container ----------
for /f "usebackq delims=" %%s in (`docker inspect -f "{{.State.Status}}" %CONTAINER% 2^>nul`) do set "STATE=%%s"
if not defined STATE (
    echo [1/3] Creating container %CONTAINER% from image %IMAGE% ...
    set "VOLUME=%ROOT:\=/%/data"
    docker run -d --name %CONTAINER% --restart unless-stopped ^
        -p %BACKEND_PORT%:%BACKEND_PORT% ^
        -v "!VOLUME!:/app/data" ^
        %IMAGE%
    if errorlevel 1 (echo [ERR] docker run failed & docker logs %CONTAINER% & pause & exit /b 1)
) else (
    if "!STATE!"=="running" (
        echo [1/3] Container %CONTAINER% already running.
    ) else (
        echo [1/3] Starting container %CONTAINER% ...
        docker start %CONTAINER%
    )
)

set "READY="
for /l %%s in (1,1,30) do (
    if not defined READY (
        ping -n 3 127.0.0.1 >nul
        for /f "usebackq delims=" %%c in (`curl -s -o nul -m 2 -w %%{http_code} %LOCAL%/api/health`) do if "%%c"=="200" set "READY=1"
    )
)
if defined READY (
    echo [OK] Backend ready: %LOCAL%/api/health
) else (
    echo [WARN] Backend /api/health did not answer in 60s -- check: docker logs -f %CONTAINER%
)

rem ---------- Step 2: frontend Vite dev server ----------
if not exist "%ROOT%\.runtime" mkdir "%ROOT%\.runtime"
cd /d "%ROOT%\frontend"
set "VITE_A_STOCK_BACKEND_URL=%LOCAL%"
echo [2/3] Starting frontend Vite on %SHOW% ...
powershell -NoProfile -Command "Start-Process -FilePath 'npm.cmd' -ArgumentList 'run','dev' -WorkingDirectory '%ROOT%\frontend' -WindowStyle Hidden"

set "FREADY="
for /l %%s in (1,1,30) do (
    if not defined FREADY (
        ping -n 3 127.0.0.1 >nul
        for /f "usebackq delims=" %%c in (`curl -s -o nul -m 2 -w %%{http_code} %SHOW%`) do if "%%c"=="200" set "FREADY=1"
    )
)
if defined FREADY (
    echo [OK] Frontend ready: %SHOW%/
) else (
    echo [WARN] Frontend did not answer on %SHOW% -- check %ROOT%\.runtime\frontend.out.log
)

rem ---------- Step 3: open browser ----------
echo [3/3] Opening browser: %SHOW%/
start "" "%SHOW%/"

echo.
echo ===== EasyStock =====
echo   Backend : %LOCAL%/api/health
echo   Frontend: %SHOW%/
echo   Stop   : EasyStock_Stop.bat
echo.
pause
endlocal
