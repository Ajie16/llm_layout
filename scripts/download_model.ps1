# 下载 Qwen3.6-35B-A3B-GGUF 模型脚本
# 模型会自动保存到 ../models/ 目录

param(
    [ValidateSet("UD-Q2_K_XL", "UD-Q4_K_M", "UD-Q4_K_XL", "Q8_0", "BF16")]
    [string]$Quant = "UD-Q2_K_XL"
)

$RepoId = "unsloth/Qwen3.6-35B-A3B-GGUF"
$Filename = "Qwen3.6-35B-A3B-$Quant.gguf"
$SaveDir = "..\models"
$SavePath = Join-Path $SaveDir $Filename

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  模型下载工具" -ForegroundColor Cyan
Write-Host "  仓库: $RepoId" -ForegroundColor Cyan
Write-Host "  文件: $Filename" -ForegroundColor Cyan
Write-Host "  保存到: $SaveDir" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 确保 models 目录存在
if (-not (Test-Path $SaveDir)) {
    New-Item -ItemType Directory -Force -Path $SaveDir | Out-Null
}

# 检查是否已有文件
if (Test-Path $SavePath) {
    $size = (Get-Item $SavePath).Length / 1GB
    Write-Host "[INFO] 文件已存在: $Filename ($([math]::Round($size,2)) GB)" -ForegroundColor Green
    $confirm = Read-Host "是否重新下载? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "取消下载" -ForegroundColor Gray
        exit 0
    }
    Remove-Item $SavePath -Force
}

# 启用加速下载
$env:HF_HUB_ENABLE_HF_TRANSFER = "1"

Write-Host "开始下载，请耐心等待..." -ForegroundColor Yellow
Write-Host "(11GB 文件根据网络情况可能需要 10-30 分钟)" -ForegroundColor Gray
Write-Host ""

try {
    python -c "from huggingface_hub import hf_hub_download; hf_hub_download(repo_id='$RepoId', filename='$Filename', local_dir='$SaveDir', local_dir_use_symlinks=False)"
    Write-Host ""
    Write-Host "[SUCCESS] 下载完成: $SavePath" -ForegroundColor Green
    Write-Host "提示: 修改 start_server.ps1 中的 `$ModelFile 变量即可切换模型" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] 下载失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "备选方案 - 使用浏览器手动下载:" -ForegroundColor Yellow
    Write-Host "  https://huggingface.co/$RepoId/resolve/main/$Filename" -ForegroundColor Gray
    Write-Host ""
    Write-Host "或使用镜像站:" -ForegroundColor Yellow
    Write-Host "  https://hf-mirror.com/$RepoId/resolve/main/$Filename" -ForegroundColor Gray
    Write-Host "  https://modelscope.cn/models/$RepoId/resolve/master/$Filename" -ForegroundColor Gray
}
