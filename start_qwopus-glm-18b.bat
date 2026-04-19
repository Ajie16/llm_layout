@echo off
chcp 65001 >nul
title Qwopus-GLM-18B 本地推理服务器 (AMD RX9060 XT)

REM 启动 Qwopus-GLM-18B 模型服务
REM 配置位置: .\config\qwopus-glm-18b.json

echo ==============================================
echo   Qwopus-GLM-18B 本地推理服务器
echo   GPU: AMD RX9060 XT (Vulkan后端)
echo ==============================================
echo.

powershell -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwopus-glm-18b.json"

pause
