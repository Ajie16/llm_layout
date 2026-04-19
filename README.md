# LLM 本地推理环境 (AMD RX9060 XT)

AMD Radeon RX 9060 XT + llama.cpp Vulkan 后端的本地大模型推理部署方案。

## 目录结构

```
LLAMA_LAYOUT/
├── llama/                          # llama.cpp 推理引擎 (需单独下载)
│   ├── llama-server.exe
│   ├── llama-cli.exe
│   └── ...
├── models/                         # 所有 GGUF 模型存放目录
│   ├── Qwen3.6-35B-A3B-UD-Q2_K_XL.gguf
│   └── Qwopus-GLM-18B-Healed-Q4_K_M.gguf
├── config/                         # 模型配置文件 (JSON)
│   ├── config_template.json        # 完整参数模板
│   ├── qwen3.6-35b-a3b.json       # Qwen3.6 配置
│   └── qwopus-glm-18b.json        # Qwopus-GLM 配置
├── scripts/                        # 辅助脚本
│   └── download_model.ps1
├── start_server.ps1                # 通用启动器 (读取 JSON 配置)
├── start_qwen3.6-35b-a3b.bat      # Qwen3.6 快捷启动
├── start_qwopus-glm-18b.bat       # Qwopus-GLM 快捷启动
├── stop_server.bat                 # 停止服务
├── README.md                       # 本文件
└── CONFIG_GUIDE.md                 # 参数配置与调优指南 ⭐
```

## 环境准备

### 1. 下载 llama.cpp 推理引擎

```powershell
# 下载 Vulkan 后端 (支持 AMD GPU)
# 地址: https://github.com/ggml-org/llama.cpp/releases
# 文件: llama-*-bin-win-vulkan-x64.zip

# 解压到 llama/ 目录
Expand-Archive llama-b8840-bin-win-vulkan-x64.zip -DestinationPath .\llama
```

### 2. 下载模型

| 模型 | 大小 | 来源 | 放置位置 |
|------|------|------|----------|
| Qwen3.6-35B-A3B-UD-Q2_K_XL | ~11.5GB | [HuggingFace](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) / [ModelScope](https://modelscope.cn/models/unsloth/Qwen3.6-35B-A3B-GGUF) | `models/` |
| Qwopus-GLM-18B-Healed-Q4_K_M | ~9.2GB | [HuggingFace](https://huggingface.co/KyleHessling1/Qwopus-GLM-18B-Merged-GGUF) | `models/` |

```powershell
# 或使用脚本下载
cd scripts
.\download_model.ps1
```

## 快速开始

### 启动服务

双击 BAT 文件即可启动，**每个模型会打开一个独立的 PowerShell 窗口**：

```cmd
:: 启动 Qwen3.6-35B-A3B (窗口标题: Qwen3.6-35B-A3B Server)
start_qwen3.6-35b-a3b.bat

:: 启动 Qwopus-GLM-18B (窗口标题: Qwopus-GLM-18B Server)
start_qwopus-glm-18b.bat
```

### 停止服务

**关闭对应的 PowerShell 窗口即可** —— llama-server 会随窗口一起终止。

### API 调用

```powershell
$body = @{
    model = "local"
    messages = @(@{ role = "user"; content = "你好" })
    max_tokens = 2048
    stream = $true    # 启用流式输出
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Uri "http://localhost:8080/v1/chat/completions" -Method Post -ContentType "application/json" -Body $body
```

## 配置化设计

**所有推理参数统一在 `config/*.json` 中管理**，无需修改脚本代码即可调优：

```json
// config/qwopus-glm-18b.json
{
  "model": { "path": ".\\models\\Qwopus-GLM-18B-Healed-Q4_K_M.gguf" },
  "gpu": { "n_gpu_layers": 99, "flash_attn": true, "cache_type_k": "f16" },
  "context": { "ctx_size": 32768, "parallel": 4 },
  "sampling": { "temp": 0.7, "top_k": 40, "top_p": 0.95 }
}
```

### 添加新模型

1. 将 `.gguf` 放入 `models/`
2. 复制 `config/config_template.json` → `config/你的模型.json`
3. 修改 `model.path` 和调优参数
4. 创建 BAT 快捷方式 (可选)

📖 **详细调优指南**: [CONFIG_GUIDE.md](CONFIG_GUIDE.md)

## 实测性能

| 模型 | GPU Offload | 输入处理 | 输出生成 |
|------|------------|---------|---------|
| Qwen3.6-35B-A3B (UD-Q2_K_XL) | 41/41 层 | 233 tok/s | 27.7 tok/s |
| Qwopus-GLM-18B (Q4_K_M) | 待测 | 待测 | 待测 |

## 注意事项

1. **驱动更新**: AMD 显卡驱动需 **Adrenalin 26.2.2+**
2. **I-quants 不兼容 Vulkan**: 避免使用 `IQ2_XXS` 等 I-quants
3. **llama.cpp 版本**: 推荐使用 b8840+，Vulkan 后端对 RX9060 XT 支持更好

## 多模型同时运行

修改不同配置的 `port` 为不同值，分别启动即可：

```json
// config/qwen3.6-35b-a3b.json
{ "server": { "port": 8080 } }

// config/qwopus-glm-18b.json
{ "server": { "port": 8081 } }
```
