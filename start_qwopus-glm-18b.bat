@echo off
chcp 65001 >nul

REM Qwopus-GLM-18B 推理服务器
REM 配置: .\config\qwopus-glm-18b.json
REM 操作: 关闭窗口即停止服务

start "Qwopus-GLM-18B Server (port 8080)" powershell -NoExit -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwopus-glm-18b.json"
