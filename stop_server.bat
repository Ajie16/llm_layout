@echo off
chcp 65001 >nul
title 停止 Qwen3.6 推理服务器

echo ==============================================
echo   停止 Qwen3.6-35B-A3B 推理服务器
echo ==============================================
echo.

REM 查找 llama-server.exe 进程
for /f "tokens=2 delims=," %%a in ('tasklist /FI "IMAGENAME eq llama-server.exe" /FO CSV /NH 2^>nul') do (
    set "PID=%%~a"
    goto :found
)

echo [提示] 没有找到正在运行的 llama-server.exe 进程。
echo.
pause
exit /b 0

:found
echo 发现运行中的 llama-server.exe (PID: %PID%)
echo.
set /p confirm="确认停止服务? (Y/n): "
if /I "%confirm%"=="n" (
    echo 已取消。
    pause
    exit /b 0
)

echo 正在停止服务...
taskkill /F /PID %PID% >nul 2>&1
if %errorlevel%==0 (
    echo.
    echo [成功] 服务已停止 (PID: %PID%)
) else (
    echo.
    echo [失败] 无法停止进程，尝试强制结束所有 llama-server...
    taskkill /F /IM llama-server.exe >nul 2>&1
    if %errorlevel%==0 (
        echo [成功] 所有 llama-server 已强制停止。
    ) else (
        echo [错误] 停止失败，请手动在任务管理器中结束进程。
    )
)

echo.
pause
