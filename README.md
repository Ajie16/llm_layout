# Qwen3.6-35B-A3B 本地部署环境 (AMD RX9060 XT)

## 硬件配置
- GPU: AMD Radeon RX 9060 XT 16GB
- CPU: AMD Ryzen 9 5950X (32核)
- RAM: 32GB
- OS: Windows

## 目录结构

```
LLAMA_LAYOUT/
├── llama/                          # llama.cpp 推理引擎
│   ├── llama-server.exe            # API 服务器主程序
│   ├── llama-cli.exe               # 命令行对话工具
│   ├── llama-bench.exe             # 性能测试工具
│   ├── ggml-vulkan.dll             # Vulkan 后端 (AMD GPU 加速)
│   └── ... (其他 dll/exe)
├── models/                         # 所有 GGUF 模型存放目录
│   └── Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf
├── scripts/                        # 辅助脚本
│   └── download_model.ps1          # 模型下载工具
├── start_qwen3.6-35b-a3b.bat       # Qwen3.6-35B-A3B 启动脚本
├── stop_server.bat                 # 停止服务脚本
└── README.md                       # 本文件
```

> **以后加载其他模型**：只需把 `.gguf` 文件放入 `models/` 目录，然后修改 `start_qwen3.6-35b-a3b.bat` 顶部的 `MODEL` 变量即可。

## 快速开始

### 1. 启动服务
```cmd
cd F:\WorkSpace\LLAMA_LAYOUT
start_qwen3.6-35b-a3b.bat
```

### 2. 停止服务
```cmd
cd F:\WorkSpace\LLAMA_LAYOUT
stop_server.bat
```

服务启动后访问:
- Web UI: http://localhost:8080
- OpenAI API: http://localhost:8080/v1/chat/completions

### 2. API 调用示例
```powershell
$body = @{
    model = "qwen3.6"
    messages = @(
        @{ role = "system"; content = "You are a helpful assistant." },
        @{ role = "user"; content = "你好" }
    )
    max_tokens = 2048
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:8080/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
```

### 3. 下载其他量化版本
```powershell
cd F:\WorkSpace\LLAMA_LAYOUT\scripts
.\download_model.ps1 -Quant UD-Q4_K_M
```

## 量化选择建议

| 量化等级 | 大小 | 显存需求 | 适用场景 |
|----------|------|----------|----------|
| UD-Q2_K_XL | ~11.5GB | ~12GB | ⭐ 推荐，可完全放入16G显存 |
| UD-Q4_K_M | ~20.6GB | ~20GB | 质量更好，需部分放系统内存 |
| UD-Q4_K_XL | ~21GB | ~21GB | 质量更好，需混合调度 |

## 实测性能 (RX9060 XT + Vulkan)

| 测试项 | 速度 |
|---|---|
| 输入处理 (pp256) | **233 tokens/s** |
| 输出生成 (tg128) | **27.7 tokens/s** |

## 参数调优

上下文长度 (`-c`) 建议:
- 16GB 显存 + Q2_K_XL: 可设 32K~64K
- 如果爆显存，降为 16K 或 8K

线程数 (`-t`) 建议:
- 5950X 32线程，建议设 16~24

## 注意事项

1. **驱动更新**: 确保 AMD 显卡驱动为 **Adrenalin 26.2.2+**
2. **I-quants 不兼容 Vulkan**: 避免使用 `UD-IQ2_XXS` 等 I-quants，选择 K-quants
3. **多模型管理**: 所有 `.gguf` 文件统一放在 `models/` 目录，修改 `$ModelFile` 即可切换
