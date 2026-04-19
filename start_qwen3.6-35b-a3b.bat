@echo off
chcp 65001 >nul

REM Qwen3.6-35B-A3B Inference Server
REM Config: .\config\qwen3.6-35b-a3b.json
REM Close window to stop

start "Qwen3.6-35B-A3B Server (port 8080)" powershell -NoExit -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwen3.6-35b-a3b.json"