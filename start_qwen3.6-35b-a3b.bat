@echo off
chcp 65001 >nul

REM Qwen3.6-35B-A3B 推理服务器
REM 配置: .\config\qwen3.6-35b-a3b.json
REM 操作: 关闭窗口即停止服务

start "Qwen3.6-35B-A3B Server (port 8080)" powershell -NoExit -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwen3.6-35b-a3b.json"
