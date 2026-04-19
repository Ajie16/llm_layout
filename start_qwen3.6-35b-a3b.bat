@echo off
chcp 65001 >nul
title Qwen3.6-35B-A3B 本地推理服务器 (AMD RX9060 XT)

set "MODEL=.\models\Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf"
set "SERVER=.\llama\llama-server.exe"

echo ==============================================
echo   Qwen3.6-35B-A3B 本地推理服务器
echo   GPU: AMD RX9060 XT (Vulkan后端)
echo   模型: %MODEL%
echo ==============================================
echo.

REM 检查模型文件
if not exist "%MODEL%" (
    echo [错误] 模型文件不存在: %MODEL%
    echo.
    echo 请将 .gguf 模型文件放入 .\models\ 目录，
    echo 然后修改本脚本顶部的 MODEL 变量。
    pause
    exit /b 1
)

REM 检查 llama-server
if not exist "%SERVER%" (
    echo [错误] llama-server.exe 不存在: %SERVER%
    pause
    exit /b 1
)

echo 启动命令:
echo   %SERVER% -m "%MODEL%" -ngl 99 -fa on -c 32768 --port 8080 -t 16 --host 0.0.0.0
echo.
echo 服务启动后访问:
echo   Web UI:    http://localhost:8080
echo   API 端点:  http://localhost:8080/v1/chat/completions
echo.
echo 按 Ctrl+C 停止服务
echo.

REM 启动参数说明:
REM   -m              模型路径
REM   -ngl 99         尽可能多地将层 offload 到 GPU
REM   -fa on          启用 Flash Attention
REM   -c 32768        上下文长度 32K
REM   --port 8080     API 服务端口
REM   -t 16            CPU 线程数
REM   --host 0.0.0.0   允许局域网访问

"%SERVER%" -m "%MODEL%" -ngl 99 -fa on -c 32768 --port 8080 -t 16 --host 0.0.0.0

pause
