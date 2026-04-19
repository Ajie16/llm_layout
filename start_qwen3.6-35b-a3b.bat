@echo off
chcp 65001 >nul
title Qwen3.6-35B-A3B 本地推理服务器 (AMD RX9060 XT)

REM 启动 Qwen3.6-35B-A3B 模型服务
REM 配置位置: .\config\qwen3.6-35b-a3b.json

echo ==============================================
echo   Qwen3.6-35B-A3B 本地推理服务器
echo   GPU: AMD RX9060 XT (Vulkan后端)
echo ==============================================
echo.

powershell -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwen3.6-35b-a3b.json"

pause
