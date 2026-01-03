# Smart Travel Planner

> **Monorepo**: AI-Powered Travel Assistant with On-Device LLM + Tool Use

## 🎯 Project Overview
This project combines AI fine-tuning and iOS development to create an intelligent travel planning assistant powered by the **Gemma 3 1B IT** model with tool-calling capabilities. The monorepo is split into two main components:

- **`Brain_Factory/`**: AI training pipeline for teaching Gemma to use travel-related tools
- **`TravelAgent_iOS/`**: iOS application with on-device inference

## 📁 Repository Structure

```
smart-travel-planner-ios/
├── Brain_Factory/                  # 🧠 AI Training Hub
│   ├── adapters/                   # LoRA adapters (generated during training)
│   ├── generate_data.py           # Synthetic dataset generator
│   ├── requirements.txt            # Python dependencies (mlx-lm)
│   └── train.jsonl                 # 93 training examples (auto-generated)
│
├── TravelAgent_iOS/                # 📱 iOS Application
│   ├── Models/                     # Trained model files (.task)
│   ├── SmartTravelPlanner/         # Swift source code
│   ├── SmartTravelPlanner.xcodeproj
│   ├── SmartTravelPlanner.xcworkspace
│   └── Podfile                     # CocoaPods dependencies
│
├── .gitignore                      # Excludes ML artifacts & large models
└── README.md                       # This file
```

---

## 🧠 Brain_Factory: AI Training

### Tool-Calling Capabilities
The AI agent is trained to use three tools for travel planning:

| Tool | Description | Example Query |
|------|-------------|---------------|
| `search_places` | Find locations, restaurants, attractions | "Where is Tower Bridge?" |
| `get_weather` | Get weather forecasts | "Is it raining at Hyde Park?" |
| `search_web` | Look up ticket prices, opening hours | "How much are tickets for The Shard?" |

### Setup & Training

1. **Install Dependencies**:
   ```bash
   cd Brain_Factory
   pip install -r requirements.txt
   ```

2. **Generate Training Data** (Already done!):
   ```bash
   python generate_data.py
   # ✅ Outputs: train.jsonl (93 examples)
   ```

3. **Fine-Tune with MLX** (Apple Silicon):
   ```bash
   # Example using mlx-lm
   mlx_lm.lora \
     --model google/gemma-1b-it \
     --data train.jsonl \
     --iters 500 \
     --adapter-path ./adapters
   ```

4. **Export for iOS**:
   - Convert the fine-tuned model to `.task` format
   - Place in `TravelAgent_iOS/Models/`

---

## 📱 TravelAgent_iOS: iOS Setup

### Prerequisites
- **Xcode 15+**
- **iOS 15.0+** (Physical device recommended)
- **CocoaPods** (`brew install cocoapods`)
- **Model File**: `gemma3-1b-it-int4.task` (from Brain_Factory or Kaggle)

### Installation

1. **Navigate to iOS Directory**:
   ```bash
   cd TravelAgent_iOS
   ```

2. **Install CocoaPods**:
   ```bash
   pod install
   ```

3. **Open Workspace** (Important!):
   ```bash
   open SmartTravelPlanner.xcworkspace
   ```
   ⚠️ Always use `.xcworkspace`, not `.xcodeproj`

### Adding the Model
The model file is excluded from git due to size (1GB+):

1. Drag `gemma3-1b-it-int4.task` into Xcode's **Project Navigator**
2. In the dialog:
   - ✅ **Copy items if needed**
   - ✅ **Add to targets**: `SmartTravelPlanner`

### 3. Critical Xcode Configuration
This project uses C++ libraries which require specific linking flags to work with CocoaPods.
If you see **"Undefined symbol"** errors, verify these settings:
1.  Open **Build Settings** for the `SmartTravelPlanner` target.
2.  Search for **Other Linker Flags** (`OTHER_LDFLAGS`).
3.  Ensure the following flags are present:
    - `$(inherited)`  *(Crucial for CocoaPods)*
    - `-all_load`     *(Forces loading of MediaPipe C++ libraries)*

### 4. Running
- Select a Simulator or Device.
- Press **Cmd+R** to run.
- Wait for the "Model Ready" indicator (green text).
- Enter a prompt and tap **Send**.

## Technical Implementation Details

### Model Service (`GemmaService.swift`)
- **Initialization**: Loads the model from the bundle with `LlmInference`.
- **Generation**: Uses synchronous `generateResponse(inputText:)` wrapped in a background queue.
    - *Why Synchronous?* The async streaming API can have signature compatibility issues with some Swift Pod versions.
- **Prompt Templating**: explicitly formats prompts for the Instruction Tuned (IT) model:
    ```swift
    "<start_of_turn>user\n" + prompt + "<end_of_turn>\n<start_of_turn>model\n"
    ```
    *Without this format, the model may return empty strings.*

## Known Limitations
- **Simulator Performance**: The 1B parameter model runs on the CPU in the Simulator. It acts slowly and may trigger internal timeouts. **Physical devices** (iPhone 12 or newer) are highly recommended.
- **App Size**: The app bundle will be large (model file is ~1GB+).

## Future Recommendations
- **Streaming**: Investigate `generateResponseAsync` with exact closure signatures for token-by-token output.
- **RAG Integration**: The project structure contains placeholders for "Tools" and "RAGService". These can be re-enabled by setting **Strict Concurrency Checking** to "Complete" and fixing the Swift 6 isolation errors.
- **Production Tools**: Implement actual API integrations for `search_places` (Google Maps), `get_weather` (OpenWeather), and `search_web` (Bing/Google).

---

## 🔄 Complete Workflow

### End-to-End Pipeline

1. **Train the AI** (`Brain_Factory/`)
   ```bash
   cd Brain_Factory
   python generate_data.py          # Generate synthetic data
   # Fine-tune model with MLX
   # Export to .task format
   ```

2. **Deploy to iOS** (`TravelAgent_iOS/`)
   ```bash
   cd ../TravelAgent_iOS
   # Copy trained model to Models/
   pod install
   open SmartTravelPlanner.xcworkspace
   # Build & Run
   ```

3. **Test Tool Usage**
   - Test queries: "Where is Tower Bridge?", "What's the weather at Hyde Park?"
   - Verify the model outputs tool calls in format: `call:{"tool": "search_places", "parameters": {...}}`

### Development Tips
- **Keep models out of git**: All `.task`, `.tflite`, `.pth` files are gitignored
- **Update README**: Always reflect structural changes here
- **Adapters are portable**: LoRA adapters in `Brain_Factory/adapters/` can be shared separately

---

## 📊 Training Data Format

The generated `train.jsonl` uses ChatML format:
```json
{
  "messages": [
    {"role": "user", "content": "Where is Tower Bridge?"},
    {"role": "assistant", "content": "call:{\"tool\": \"search_places\", \"parameters\": {\"query\": \"Tower Bridge\"}}"}
  ]
}
```

This teaches the model to:
1. Parse natural language queries
2. Select the appropriate tool
3. Extract and structure parameters
4. Return JSON-formatted tool calls

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| AI Training | MLX-LM, Python 3.10+ |
| Base Model | Gemma 3 1B IT (Int4 Quantized) |
| Fine-Tuning | LoRA (Low-Rank Adaptation) |
| iOS Runtime | MediaPipe Tasks GenAI |
| Dependency Management | CocoaPods |
| Language | Swift 5.9+ |

---

## 📄 License
MIT License - Feel free to use this as a template for your own projects!
