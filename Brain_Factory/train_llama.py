import subprocess
import sys
import os

# --- CONFIGURATION ---
# The King of Edge AI: Llama 3.2 3B (4-bit Quantized)
# This model is rock-solid stable on MLX.
MODEL_ID = "mlx-community/Llama-3.2-3B-Instruct-4bit"

# Hyperparameters
# We can use a slightly higher learning rate for Llama
BATCH_SIZE = 4
LORA_LAYERS = 16 
ITERATIONS = 600
LEARNING_RATE = "1e-4"  # Reduced from 2e-4 to prevent NaN loss
DATA_DIR = "./" 
ADAPTER_PATH = "adapters"

def run_training():
    print(f"🚀 Initializing Llama 3.2 Training for {MODEL_ID}...")
    
    command = [
        sys.executable, "-m", "mlx_lm.lora",
        "--model", MODEL_ID,
        "--train",
        "--data", DATA_DIR,
        "--batch-size", str(BATCH_SIZE),
        "--num-layers", str(LORA_LAYERS),
        "--iters", str(ITERATIONS),
        "--learning-rate", LEARNING_RATE,
        "--adapter-path", ADAPTER_PATH,
        "--save-every", "100"
    ]

    try:
        # Clean start
        subprocess.run(["rm", "-rf", ADAPTER_PATH], stderr=subprocess.DEVNULL)
        
        print("🔥 Starting Fine-Tuning...")
        subprocess.run(command, check=True)
        print("\n✅ Training Complete! Llama has learned your tools.")
        
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Training Failed. Error code: {e.returncode}")

if __name__ == "__main__":
    run_training()
