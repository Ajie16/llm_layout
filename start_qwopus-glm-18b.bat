@echo off
chcp 65001 >nul

REM Qwopus-GLM-18B Inference Server
REM Config: .\config\qwopus-glm-18b.json
REM Close window to stop

start "Qwopus-GLM-18B Server (port 8080)" powershell -NoExit -ExecutionPolicy Bypass -File ".\start_server.ps1" ".\config\qwopus-glm-18b.json"