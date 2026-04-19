# LLM 推理配置指南

## 目录结构

```
config/
├── config_template.json        # 完整参数模板 (参考用)
├── qwen3.6-35b-a3b.json       # Qwen3.6-35B-A3B 专用配置
└── qwopus-glm-18b.json        # Qwopus-GLM-18B 专用配置
```

---

## 快速开始

### 启动指定模型

```cmd
:: 方式1: 双击 BAT 快捷方式
start_qwen3.6-35b-a3b.bat
start_qwopus-glm-18b.bat

:: 方式2: 使用通用启动器 + 指定配置
powershell -File .\start_server.ps1 .\config\qwopus-glm-18b.json
```

### 添加新模型

1. 将 `.gguf` 模型放入 `models/` 目录
2. 复制 `config\config_template.json` 为新配置文件
3. 修改 `model.path` 指向你的模型
4. 根据需要调整其他参数
5. 创建新的 BAT 快捷方式 (可选)

---

## 参数详解与微调指南

### 1. GPU 加速 (`gpu`)

| 参数 | 范围 | 说明 |
|------|------|------|
| `n_gpu_layers` | 0~99 | **最关键参数**。99=全部放显存，0=纯CPU。显存不足时逐步减小 |
| `flash_attn` | true/false | **强烈推荐开启**。可降低 30~50% KV Cache 显存占用 |
| `cache_type_k` | f16 / q8_0 / q4_0 | KV Cache K 量化。长上下文推荐 `q8_0`，可省约 50% KV 显存 |
| `cache_type_v` | f16 / q8_0 / q4_0 | KV Cache V 量化。建议与 K 保持一致 |

**显存计算公式 (近似):**
```
模型显存 ≈ 模型文件大小 × 1.1
KV Cache 显存 ≈ ctx_size × n_layers × head_dim × n_kv_heads × 2(bytes) × parallel / 1024³
总显存 ≈ 模型显存 + KV Cache 显存
```

**RX9060 XT 16GB 调优建议:**

| 场景 | n_gpu_layers | cache_type | ctx_size | parallel |
|------|-------------|-----------|---------|---------|
| 高质量 + 短对话 | 99 | f16 | 8192 | 4 |
| 平衡模式 | 99 | q8_0 | 32768 | 4 |
| 超长上下文 | 99 | q4_0 | 65536 | 2 |
| 多用户并发 | 99 | q8_0 | 16384 | 8 |

### 2. 上下文长度 (`context`)

| 参数 | 范围 | 说明 |
|------|------|------|
| `ctx_size` | 512~262144 | 单次对话最大 token 数。每增加一倍，KV Cache 显存翻倍 |
| `parallel` | 1~16 | 并发槽数。每增加一个槽，KV Cache 显存翻倍 |
| `cont_batching` | true/false | 连续批处理。开启后吞吐量提升 2~5 倍，**强烈推荐** |

**上下文长度选择:**
- **日常对话**: 4096~8192 (足够)
- **文档分析**: 16384~32768 (可处理长文)
- **代码审查**: 32768~65536 (大文件)
- **全书翻译**: 131072+ (需要大量显存)

### 3. 采样参数 (`sampling`) —— 控制输出风格

| 参数 | 范围 | 效果 |
|------|------|------|
| **temp** | 0.0~2.0 | 温度。低=保守准确，高=创意随机 |
| **top_k** | 1~100 | Top-K。限制候选词数量 |
| **top_p** | 0.0~1.0 | Top-P (Nucleus)。动态裁剪概率分布 |
| **min_p** | 0.0~1.0 | Min-P。过滤低概率词，减少胡言乱语 |
| **repeat_penalty** | 1.0~2.0 | 重复惩罚。>1 减少重复用词 |
| **presence_penalty** | -2.0~2.0 | 存在惩罚。正数鼓励话题多样性 |
| **frequency_penalty** | -2.0~2.0 | 频率惩罚。正数抑制高频词 |

**常用预设组合:**

```json
// 精确/代码模式
{ "temp": 0.1, "top_k": 10, "top_p": 0.9, "repeat_penalty": 1.0 }

// 平衡/聊天模式 (默认)
{ "temp": 0.7, "top_k": 40, "top_p": 0.95, "repeat_penalty": 1.1 }

// 创意/写作模式
{ "temp": 1.0, "top_k": 80, "top_p": 0.98, "repeat_penalty": 1.2 }

// 头脑风暴模式
{ "temp": 1.2, "top_k": 100, "top_p": 0.99, "presence_penalty": 0.5 }
```

### 4. CPU 线程 (`cpu`)

| 参数 | 建议值 | 说明 |
|------|--------|------|
| `threads` | 物理核心数 × 0.5~0.75 | 5950X (32线程) 推荐 16~24 |
| `threads_batch` | 与 threads 相同 | prompt 处理阶段的线程数 |

**注意:** GPU offload 层数越高，CPU 负担越小。`n_gpu_layers=99` 时 CPU 线程影响很小。

### 5. 服务参数 (`server`)

| 参数 | 说明 |
|------|------|
| `port` | 服务端口。多模型同时运行时修改此值避免冲突 |
| `host` | `0.0.0.0` = 局域网可访问; `127.0.0.1` = 仅本机 |
| `timeout` | 单请求最大等待秒数 |

**多模型同时运行:**
```json
// 模型A: port 8080
{ "port": 8080, "host": "0.0.0.0" }

// 模型B: port 8081
{ "port": 8081, "host": "0.0.0.0" }
```

### 6. 高级参数 (`advanced`)

| 参数 | 示例 | 说明 |
|------|------|------|
| `extra_args` | `"--defrag-thold 0.1"` | llama-server 原生参数 |

**常用 extra_args:**
- `--defrag-thold 0.1` — KV Cache 碎片整理阈值，长对话时保持性能
- `--slot-save-path slots` — 保存对话槽状态，支持会话恢复
- `--metrics` — 暴露 Prometheus 格式指标
- `--no-warmup` — 跳过启动预热，加快启动速度

---

## 性能调优流程

### Step 1: 确认模型能加载
1. 设置 `verbose: true`
2. 启动服务，观察日志中的 `offloaded X/Y layers to GPU`
3. 确保模型成功加载，无 OOM 错误

### Step 2: 找到最大上下文
1. 逐步增大 `ctx_size` (8192 → 16384 → 32768 → 65536)
2. 每次启动后观察显存占用 (`nvidia-smi` 或任务管理器)
3. 当显存接近 14~15GB 时停止，留 1~2GB 余量

### Step 3: 优化 KV Cache
1. 如果显存吃紧，将 `cache_type_k/v` 从 `f16` 改为 `q8_0`
2. 可节省约 50% KV Cache 显存，对输出质量影响极小
3. 如需更大上下文，可进一步改为 `q4_0`

### Step 4: 调整采样获得理想输出
1. 先用默认参数 (`temp=0.7`) 测试
2. 如果输出太保守/重复，增大 `temp` 或减小 `repeat_penalty`
3. 如果输出太发散/跑题，减小 `temp` 或增大 `repeat_penalty`
4. 出现无意义内容时，增大 `min_p`

---

## 故障排查

| 现象 | 可能原因 | 解决方案 |
|------|---------|---------|
| OOM / 显存不足 | ctx_size 或 parallel 太大 | 减小 ctx_size，或降低 cache_type 精度 |
| 加载慢 | no_mmap=false + HDD | 设置 `no_mmap: true` 或换 SSD |
| 输出乱码 | cache_type 精度太低 | 恢复为 `f16` |
| 生成速度慢 | CPU 瓶颈 | 增大 n_gpu_layers，确保模型主要在 GPU |
| 高并发卡顿 | parallel 太小 | 增大 parallel，或降低 ctx_size |
| 重复输出 | repeat_penalty 太小 | 增大到 1.15~1.25 |
| 离题/发散 | temp 太高 | 降低到 0.5~0.7 |

---

## 配置示例: 生产环境

```json
{
  "gpu": {
    "n_gpu_layers": 99,
    "flash_attn": true,
    "cache_type_k": "q8_0",
    "cache_type_v": "q8_0"
  },
  "context": {
    "ctx_size": 16384,
    "parallel": 8,
    "cont_batching": true
  },
  "sampling": {
    "temp": 0.6,
    "top_k": 30,
    "top_p": 0.92,
    "repeat_penalty": 1.15
  }
}
```

## 配置示例: 个人开发

```json
{
  "gpu": {
    "n_gpu_layers": 99,
    "flash_attn": true,
    "cache_type_k": "f16",
    "cache_type_v": "f16"
  },
  "context": {
    "ctx_size": 32768,
    "parallel": 4,
    "cont_batching": true
  },
  "sampling": {
    "temp": 0.8,
    "top_k": 50,
    "top_p": 0.95,
    "repeat_penalty": 1.05
  }
}
```
