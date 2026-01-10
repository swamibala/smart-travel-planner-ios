# Smart Travel Planner

**AI-powered travel planning assistant with on-device LLM**

This project uses **Llama 3.2 3B Instruct** fine-tuned with LoRA for tool-calling on Apple Silicon, deployed to iOS with MLX Swift.

## ✨ Features

- 🧠 **On-device AI** - Fine-tuned Llama 3.2 3B running locally
- 🔧 **Tool-calling** - Trained to use `search_places`, `get_weather`, `search_web`
- 📱 **iOS Native** - MLX Swift for seamless Apple Silicon integration
- 🔒 **Private** - All inference happens on-device
- ⚡ **Fast** - Optimized 4-bit quantized model (~1.7GB)

---

## 📁 Project Structure

```
smart-travel-planner-ios/
├── Brain_Factory/              # AI Training Pipeline
│   ├── train_llama.py          # Training script
│   ├── fuse_llama.py           # Model fusion script
│   ├── generate_data.py        # Synthetic data generator
│   ├── train.jsonl             # Training data (74 examples)
│   ├── valid.jsonl             # Validation data (19 examples)
│   ├── adapters/               # LoRA weights
│   └── Llama_TravelAgent/      # Fused model (1.7GB)
│
└── TravelAgent_iOS/            # iOS Application
    ├── Package.swift
    └── SmartTravelPlanner/
        ├── SmartTravelPlannerApp.swift
        ├── ContentView.swift
        ├── TravelAgentService.swift
        └── Resources/
            └── Llama_TravelAgent/   # Model weights
```

---

## 🧠 AI Training (Brain_Factory)

### Prerequisites

- macOS with Apple Silicon (M1/M2/M3/M4)
- Python 3.9+
- 8GB+ RAM

### Setup

```bash
cd Brain_Factory

# Install dependencies
python3 -m pip install -r requirements.txt
```

### Training Workflow

**1. Generate Training Data**

```bash
python3 generate_data.py
```

Creates 93 synthetic examples teaching the model to use travel tools.

**2. Train the Model**

```bash
python3 train_llama.py
```

**Training Results:**
- Model: `mlx-community/Llama-3.2-3B-Instruct-4bit`
- Method: LoRA fine-tuning
- Loss: 1.420 → 0.073 (95% improvement)
- Time: ~7 minutes on M4 Pro
- Output: `adapters/` folder with LoRA weights

**3. Fuse Model for iOS**

```bash
python3 fuse_llama.py
```

Creates `Llama_TravelAgent/` folder (1.7GB) ready for iOS.

### Training Parameters

| Parameter | Value |
|-----------|-------|
| Base model | Llama-3.2-3B-Instruct-4bit |
| LoRA rank | 16 layers |
| Learning rate | 1e-4 |
| Batch size | 4 |
| Iterations | 600 |
| Checkpoints | Every 100 iterations |

---

## 📱 iOS Application

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ device (physical device required for Metal)
- macOS 14.0+

### Setup

**1. Open Project**

```bash
# Open the folder in Xcode to use Swift Package Manager
open TravelAgent_iOS
```

**2. Add Model Weights**

1.  Locate your `Llama_TravelAgent` folder.
2.  Copy or Move the **entire folder** to:
    `TravelAgent_iOS/SmartTravelPlanner/Resources/Llama_TravelAgent`

    Structure:
    ```
    .../Resources/Llama_TravelAgent/
        ├── config.json
        ├── model.safetensors
        └── tokenizer.json
    ```

**3. Build and Run**

- Select the `SmartTravelPlanner` scheme.
- Select your target (e.g., iPhone 15 Simulator).
- Run (Cmd+R).

**4. Enjoy!**

- The app handles MLX framework constraints automatically.
- All inference runs locally on your device.

### Testing

Try these queries:
- "Where is Tower Bridge?"
- "What's the weather in London?"
- "Find coffee shops near Hyde Park"
- "How much are tickets to The Shard?"

---

## 🔧 Tools Available

| Tool | Description | Example Input |
|------|-------------|---------------|
| `search_places` | Find locations using MapKit | "Where is Tower Bridge?" |
| `get_weather` | Get weather information | "What's the weather in London?" |
| `search_web` | Search for travel info | "How much are tickets to The Shard?" |

### Tool Output Format

The model outputs JSON tool calls:

```json
call:{"tool": "search_places", "parameters": {"query": "Tower Bridge"}}
```

The iOS app parses this and executes the appropriate tool.

---

## 🎯 Why Llama 3.2 3B?

| Feature | Value |
|---------|-------|
| **Architecture** | Standard Transformer (stable MLX support) |
| **Size** | 3.2B parameters → 1.7GB (4-bit quantized) |
| **Performance** | Excellent at tool-calling & instruction following |
| **Efficiency** | ~3-4GB RAM usage on device |
| **Training** | LoRA works flawlessly with MLX |

**Compared to alternatives:**
- ✅ Better than Gemma 2B at following instructions
- ✅ Smaller than Gemma after quantization (1.7GB vs 4.7GB)
- ✅ No MatFormer architecture issues
- ✅ Meta-trained specifically for agentic tasks

---

## 📊 Performance

### Training Metrics
- Loss improvement: 95.1% (1.420 → 0.073)
- Final validation loss: 0.112
- Training time: ~7 minutes (M4 Pro)
- Peak memory: 3.868 GB

### iOS Inference
- Model load time: 3-5 seconds
- First token latency: ~500ms
- Throughput: ~20-30 tokens/sec (iPhone 15 Pro)
- Memory usage: ~3-4 GB

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| AI Training | MLX-LM, Python 3.9+ |
| Base Model | Llama 3.2 3B Instruct (4-bit) |
| Fine-tuning | LoRA (6.9M trainable params) |
| iOS Framework | MLX Swift |
| UI | SwiftUI |
| Deployment | On-device (no API calls) |

---

## 🚀 Quick Start

**Clone and train in 3 commands:**

```bash
# 1. Generate data
cd Brain_Factory && python3 generate_data.py

# 2. Train model (~7 minutes)
python3 train_llama.py

# 3. Fuse for iOS
python3 fuse_llama.py
```

**Then open Xcode, add packages, and deploy!**

---

## 📝 Development Workflow

### Training New Models

1. Edit `generate_data.py` to add new tools/examples
2. Run `python3 generate_data.py`
3. Train: `python3 train_llama.py`
4. Fuse: `python3 fuse_llama.py`
5. Refresh in Xcode

### Customization

**Add new tools:**
1. Update `generate_data.py` with tool examples
2. Update `TravelAgentService.swift` with tool execution logic
3. Retrain the model

**Adjust training:**
- Edit `LEARNING_RATE`, `ITERATIONS`, or `LORA_LAYERS` in `train_llama.py`
- Higher iterations = better but slower
- Lower learning rate = more stable training

---

## 🐛 Troubleshooting

### Training Issues

**"Model not found"**
```bash
# MLX will auto-download from HuggingFace
# Ensure internet connection and HuggingFace access
```

**NaN loss during training**
```python
# Reduce learning rate in train_llama.py
LEARNING_RATE = "5e-5"  # Lower than default 1e-4
```

### iOS Issues

**"Model not found in bundle"**
```bash
# Verify symlink exists
ls -la TravelAgent_iOS/SmartTravelPlanner/SmartTravelPlanner/TravelAgent_Model

# Should point to: ../../../../Brain_Factory/Llama_TravelAgent
```

**Package errors**
- Add BOTH mlx-swift AND mlx-swift-examples
- MLXLLM is in examples package, not main MLX package

**Out of memory**
- Close other apps
- Llama 3.2 4-bit needs ~3-4GB RAM
- Test on iPhone 15+ recommended

---

## 📚 References

- [MLX Framework](https://github.com/ml-explore/mlx)
- [MLX Swift](https://github.com/ml-explore/mlx-swift)
- [Llama 3.2](https://ai.meta.com/blog/llama-3-2-connect-2024-vision-edge-mobile-devices/)
- [LoRA Paper](https://arxiv.org/abs/2106.09685)

---

## 📄 License

This project is for educational purposes. Please respect the licenses of:
- Meta Llama 3.2 (Meta Community License)
- MLX (Apache 2.0)

---

## 🎉 Success!

You now have a fully functional AI travel assistant running entirely on your iPhone! 

**No internet required • No API costs • 100% private**

🚀 Happy traveling!
