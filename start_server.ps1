# llama.cpp Generic Launcher
# Usage: .\start_server.ps1 [config.json]
# Example: .\start_server.ps1 .\config\qwen3.6-35b-a3b.json

param(
    [string]$ConfigFile = ".\config\qwen3.6-35b-a3b.json"
)

$ErrorActionPreference = "Stop"

# Check config file
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERROR] Config file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Usage: .\start_server.ps1 <config.json>" -ForegroundColor Yellow
    Get-ChildItem ".\config\*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    exit 1
}

# Read JSON config
$cfg = Get-Content $ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json

# Check model file
$modelPath = $cfg.model.path
if (-not (Test-Path $modelPath)) {
    Write-Host "[ERROR] Model file not found: $modelPath" -ForegroundColor Red
    Write-Host "Please download the .gguf model and place it in the models/ folder" -ForegroundColor Yellow
    exit 1
}

# Check llama-server
$serverExe = ".\llama\llama-server.exe"
if (-not (Test-Path $serverExe)) {
    Write-Host "[ERROR] llama-server.exe not found: $serverExe" -ForegroundColor Red
    Write-Host "Please download llama.cpp Vulkan backend from GitHub Release:" -ForegroundColor Yellow
    Write-Host "  https://github.com/ggml-org/llama.cpp/releases" -ForegroundColor Gray
    exit 1
}

# Build argument list
$argsList = [System.Collections.ArrayList]::new()

# Model path
[void]$argsList.Add("-m")
[void]$argsList.Add($modelPath)

# GPU layers
[void]$argsList.Add("--n-gpu-layers")
[void]$argsList.Add([string]$cfg.gpu.n_gpu_layers)

# Flash Attention
if ($cfg.gpu.flash_attn) {
    [void]$argsList.Add("--flash-attn"); [void]$argsList.Add("on")
}

# KV Cache type
if ($cfg.gpu.cache_type_k) {
    [void]$argsList.Add("--cache-type-k")
    [void]$argsList.Add($cfg.gpu.cache_type_k)
}
if ($cfg.gpu.cache_type_v) {
    [void]$argsList.Add("--cache-type-v")
    [void]$argsList.Add($cfg.gpu.cache_type_v)
}

# Context size
[void]$argsList.Add("-c")
[void]$argsList.Add([string]$cfg.context.ctx_size)

# Parallel slots
[void]$argsList.Add("--parallel")
[void]$argsList.Add([string]$cfg.context.parallel)

# Continuous batching
if ($cfg.context.cont_batching) {
    [void]$argsList.Add("--cont-batching")
}

# CPU threads
[void]$argsList.Add("-t")
[void]$argsList.Add([string]$cfg.cpu.threads)

# Batch threads
if ($cfg.cpu.threads_batch) {
    [void]$argsList.Add("-tb")
    [void]$argsList.Add([string]$cfg.cpu.threads_batch)
}

# Port and host
[void]$argsList.Add("--port")
[void]$argsList.Add([string]$cfg.server.port)
[void]$argsList.Add("--host")
[void]$argsList.Add($cfg.server.host)

# Timeout
if ($cfg.server.timeout -gt 0) {
    [void]$argsList.Add("--timeout")
    [void]$argsList.Add([string]$cfg.server.timeout)
}

# Sampling parameters
[void]$argsList.Add("--temp")
[void]$argsList.Add([string]$cfg.sampling.temp)
[void]$argsList.Add("--top-k")
[void]$argsList.Add([string]$cfg.sampling.top_k)
[void]$argsList.Add("--top-p")
[void]$argsList.Add([string]$cfg.sampling.top_p)
[void]$argsList.Add("--min-p")
[void]$argsList.Add([string]$cfg.sampling.min_p)
[void]$argsList.Add("--repeat-penalty")
[void]$argsList.Add([string]$cfg.sampling.repeat_penalty)

# Presence penalty
if ($cfg.sampling.presence_penalty -ne 0) {
    [void]$argsList.Add("--presence-penalty")
    [void]$argsList.Add([string]$cfg.sampling.presence_penalty)
}

# Frequency penalty
if ($cfg.sampling.frequency_penalty -ne 0) {
    [void]$argsList.Add("--frequency-penalty")
    [void]$argsList.Add([string]$cfg.sampling.frequency_penalty)
}

# Max generation length
if ($cfg.generation.n_predict -ge 0) {
    [void]$argsList.Add("-n")
    [void]$argsList.Add([string]$cfg.generation.n_predict)
}

# Random seed
if ($cfg.generation.seed -ge 0) {
    [void]$argsList.Add("--seed")
    [void]$argsList.Add([string]$cfg.generation.seed)
}

# Memory lock
if ($cfg.memory.mlock) {
    [void]$argsList.Add("--mlock")
}

# Disable mmap
if ($cfg.memory.no_mmap) {
    [void]$argsList.Add("--no-mmap")
}

# Verbose logging
if ($cfg.logging.verbose) {
    [void]$argsList.Add("--verbose")
}

# Extra arguments
if ($cfg.advanced.extra_args) {
    $extra = $cfg.advanced.extra_args -split '\s+'
    foreach ($arg in $extra) {
        if ($arg) {
            [void]$argsList.Add($arg)
        }
    }
}

# Print startup info
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  llama.cpp Inference Server" -ForegroundColor Cyan
Write-Host "  Config: $ConfigFile" -ForegroundColor Cyan
Write-Host "  Model: $($cfg.model.path)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Parameters:" -ForegroundColor Yellow
Write-Host "  GPU Offload: $($cfg.gpu.n_gpu_layers) layers | Flash Attention: $($cfg.gpu.flash_attn)" -ForegroundColor Gray
Write-Host "  Context: $($cfg.context.ctx_size) tokens | Parallel slots: $($cfg.context.parallel)" -ForegroundColor Gray
Write-Host "  Temperature: $($cfg.sampling.temp) | Top-K: $($cfg.sampling.top_k) | Top-P: $($cfg.sampling.top_p)" -ForegroundColor Gray
Write-Host ""
Write-Host "Command:" -ForegroundColor Yellow
Write-Host "  $serverExe $($argsList -join ' ')" -ForegroundColor Gray
Write-Host ""
Write-Host "Endpoints:" -ForegroundColor Green
Write-Host "  Web UI:    http://localhost:$($cfg.server.port)" -ForegroundColor Green
Write-Host "  API:       http://localhost:$($cfg.server.port)/v1/chat/completions" -ForegroundColor Green
Write-Host ""
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

# Start server (foreground, closes when window closes)
& $serverExe @argsList

Write-Host ""
Write-Host "[Server stopped]" -ForegroundColor Gray

