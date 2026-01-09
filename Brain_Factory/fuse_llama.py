from mlx_lm import fuse

MODEL_ID = "mlx-community/Llama-3.2-3B-Instruct-4bit"
ADAPTER_PATH = "adapters"
OUTPUT_DIR = "Llama_TravelAgent" 

print(f"🔥 Fusing Adapters into '{MODEL_ID}'...")
fuse.fuse(
    model=MODEL_ID,
    adapter_path=ADAPTER_PATH,
    save_path=OUTPUT_DIR
)
print(f"✅ DONE! Drag the '{OUTPUT_DIR}' folder into Xcode.")
