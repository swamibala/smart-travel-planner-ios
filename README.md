# SmartTravelPlanner (Gemma LLM Sandbox)

## Goal
A minimal "Sanity Check" iOS application to verify on-device inference of the **Gemma 3 1B IT Int4** model using Google's **MediaPipe Tasks GenAI** library. This project serves as a baseline for integrating local LLMs into iOS apps.

## Prerequisites
- **Xcode 15+**
- **iOS 15.0+** (Simulator or Physical Device)
- **CocoaPods** (`brew install cocoapods`)
- **Model File**: `gemma3-1b-it-int4.task` (Download from Kaggle/Google AI Edge)

## Setup Steps

### 1. Installation
1.  Navigate to the project directory:
    ```bash
    cd Code/smart-travel-planner-ios
    ```
2.  Install dependencies:
    ```bash
    pod install
    ```
3.  **Important**: Always open `SmartTravelPlanner.xcworkspace` (not the .xcodeproj).

### 2. Adding the Model
The model file is too large to commit to git. You must add it manually:
1.  Drag `gemma3-1b-it-int4.task` into the Xcode **Project Navigator**.
2.  In the dialog, ensure:
    - **Copy items if needed**: Checked.
    - **Add to targets**: `SmartTravelPlanner` is Checked.

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
