# llama.cpp 通用推理启动器
# 用法: .\start_server.ps1 [config.json]
# 示例: .\start_server.ps1 .\config\qwen3.6-35b-a3b.json

param(
    [string]$ConfigFile = ".\config\qwen3.6-35b-a3b.json"
)

$ErrorActionPreference = "Stop"

# 检查配置文件
if (-not (Test-Path $ConfigFile)) {
    Write-Host "[ERROR] 配置文件不存在: $ConfigFile" -ForegroundColor Red
    Write-Host "用法: .\start_server.ps1 <config.json>" -ForegroundColor Yellow
    Write-Host "可用配置:" -ForegroundColor Yellow
    Get-ChildItem ".\config\*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Gray
    }
    exit 1
}

# 读取 JSON 配置
$cfg = Get-Content $ConfigFile -Raw | ConvertFrom-Json

# 检查模型文件
$modelPath = $cfg.model.path
if (-not (Test-Path $modelPath)) {
    Write-Host "[ERROR] 模型文件不存在: $modelPath" -ForegroundColor Red
    Write-Host "请从 HuggingFace 下载模型后放入 models/ 目录" -ForegroundColor Yellow
    exit 1
}

# 检查 llama-server
$serverExe = ".\llama\llama-server.exe"
if (-not (Test-Path $serverExe)) {
    Write-Host "[ERROR] llama-server.exe 不存在: $serverExe" -ForegroundColor Red
    Write-Host "请从 GitHub Release 下载 llama.cpp Vulkan 后端:" -ForegroundColor Yellow
    Write-Host "  https://github.com/ggml-org/llama.cpp/releases" -ForegroundColor Gray
    exit 1
}

# 构建启动参数
$argsList = [System.Collections.ArrayList]::new()

# 模型路径
[void]$argsList.Add("-m")
[void]$argsList.Add($modelPath)

# GPU 层数
[void]$argsList.Add("--n-gpu-layers")
[void]$argsList.Add([string]$cfg.gpu.n_gpu_layers)

# Flash Attention
if ($cfg.gpu.flash_attn) {
    [void]$argsList.Add("--flash-attn")
}

# KV Cache 类型
if ($cfg.gpu.cache_type_k) {
    [void]$argsList.Add("--cache-type-k")
    [void]$argsList.Add($cfg.gpu.cache_type_k)
}
if ($cfg.gpu.cache_type_v) {
    [void]$argsList.Add("--cache-type-v")
    [void]$argsList.Add($cfg.gpu.cache_type_v)
}

# 上下文长度
[void]$argsList.Add("-c")
[void]$argsList.Add([string]$cfg.context.ctx_size)

# 并发槽数
[void]$argsList.Add("--parallel")
[void]$argsList.Add([string]$cfg.context.parallel)

# 连续批处理
if ($cfg.context.cont_batching) {
    [void]$argsList.Add("--cont-batching")
}

# CPU 线程
[void]$argsList.Add("-t")
[void]$argsList.Add([string]$cfg.cpu.threads)

# 批处理线程
if ($cfg.cpu.threads_batch) {
    [void]$argsList.Add("-tb")
    [void]$argsList.Add([string]$cfg.cpu.threads_batch)
}

# 端口和地址
[void]$argsList.Add("--port")
[void]$argsList.Add([string]$cfg.server.port)
[void]$argsList.Add("--host")
[void]$argsList.Add($cfg.server.host)

# 超时
if ($cfg.server.timeout -gt 0) {
    [void]$argsList.Add("--timeout")
    [void]$argsList.Add([string]$cfg.server.timeout)
}

# 采样参数
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

# 存在惩罚
if ($cfg.sampling.presence_penalty -ne 0) {
    [void]$argsList.Add("--presence-penalty")
    [void]$argsList.Add([string]$cfg.sampling.presence_penalty)
}

# 频率惩罚
if ($cfg.sampling.frequency_penalty -ne 0) {
    [void]$argsList.Add("--frequency-penalty")
    [void]$argsList.Add([string]$cfg.sampling.frequency_penalty)
}

# 最大生成长度
if ($cfg.generation.n_predict -ge 0) {
    [void]$argsList.Add("-n")
    [void]$argsList.Add([string]$cfg.generation.n_predict)
}

# 随机种子
if ($cfg.generation.seed -ge 0) {
    [void]$argsList.Add("--seed")
    [void]$argsList.Add([string]$cfg.generation.seed)
}

# 内存锁定
if ($cfg.memory.mlock) {
    [void]$argsList.Add("--mlock")
}

# 禁用内存映射
if ($cfg.memory.no_mmap) {
    [void]$argsList.Add("--no-mmap")
}

# 详细日志
if ($cfg.logging.verbose) {
    [void]$argsList.Add("--verbose")
}

# 额外参数
if ($cfg.advanced.extra_args) {
    $extra = $cfg.advanced.extra_args -split '\s+'
    foreach ($arg in $extra) {
        if ($arg) {
            [void]$argsList.Add($arg)
        }
    }
}

# 输出启动信息
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  llama.cpp 推理服务器" -ForegroundColor Cyan
Write-Host "  配置: $ConfigFile" -ForegroundColor Cyan
Write-Host "  模型: $($cfg.model.path)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "可调参数摘要:" -ForegroundColor Yellow
Write-Host "  GPU Offload: $($cfg.gpu.n_gpu_layers) 层 | Flash Attention: $($cfg.gpu.flash_attn)" -ForegroundColor Gray
Write-Host "  上下文: $($cfg.context.ctx_size) tokens | 并发槽: $($cfg.context.parallel)" -ForegroundColor Gray
Write-Host "  温度: $($cfg.sampling.temp) | Top-K: $($cfg.sampling.top_k) | Top-P: $($cfg.sampling.top_p)" -ForegroundColor Gray
Write-Host ""
Write-Host "启动命令:" -ForegroundColor Yellow
Write-Host "  $serverExe $($argsList -join ' ')" -ForegroundColor Gray
Write-Host ""
Write-Host "服务启动后访问:" -ForegroundColor Green
Write-Host "  Web UI:    http://localhost:$($cfg.server.port)" -ForegroundColor Green
Write-Host "  API 端点:  http://localhost:$($cfg.server.port)/v1/chat/completions" -ForegroundColor Green
Write-Host ""
Write-Host "按 Ctrl+C 停止服务" -ForegroundColor Gray
Write-Host ""

# 启动服务 (前台运行，关闭窗口即退出)
& $serverExe @argsList

Write-Host ""
Write-Host "[服务已停止] 窗口可随时关闭" -ForegroundColor Gray
