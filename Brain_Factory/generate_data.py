import json
import random

# CONFIG: The 3 Tools for your Smart Travel Planner
TOOLS_LIST = [
    {
        "name": "search_places",
        "description": "Finds places, attractions, restaurants, or businesses by name or category. Returns coordinates and basic info.",
        "arguments": ["query", "location_hint"]
    },
    {
        "name": "get_weather",
        "description": "Gets current weather and forecast for a specific location.",
        "arguments": ["location_name"]
    },
    {
        "name": "search_web",
        "description": "Searches the internet for specific information like ticket prices, opening hours, or facts.",
        "arguments": ["query"]
    }
]

LOCATIONS = ["Tower Bridge", "London Eye", "The Shard", "British Museum", "Hyde Park", "Covent Garden", "Buckingham Palace", "Tate Modern", "Sky Garden", "Borough Market"]

INTENTS = [
    ("I want to go to {loc}", "search_places", "{loc}"),
    ("Where is {loc}?", "search_places", "{loc}"),
    ("Find {loc} on the map", "search_places", "{loc}"),
    ("How much are tickets for {loc}?", "search_web", "ticket price {loc}"),
    ("What are the opening hours for {loc}?", "search_web", "opening hours {loc}"),
    ("Is it raining at {loc}?", "get_weather", "{loc}"),
    ("What is the weather like at {loc}?", "get_weather", "{loc}"),
    ("Find me a restaurant near {loc}", "search_places", "restaurant near {loc}"),
    ("I need a coffee shop near {loc}", "search_places", "coffee near {loc}"),
]

dataset = []
print(f"Generating synthetic training data...")

# Generate Tool Use Examples
for loc in LOCATIONS:
    for intent_template, tool_name, arg_template in INTENTS:
        user_query = intent_template.format(loc=loc)
        arg_value = arg_template.format(loc=loc)
        
        if tool_name == "search_places":
            args = {"query": arg_value}
        elif tool_name == "get_weather":
            args = {"location_name": arg_value}
        else:
            args = {"query": arg_value}
            
        tool_call_json = {"tool": tool_name, "parameters": args}
        
        # Format for MLX-LM / Gemma (ChatML style)
        entry = {
            "messages": [
                {"role": "user", "content": user_query},
                {"role": "assistant", "content": f"call:{json.dumps(tool_call_json)}"} 
            ]
        }
        dataset.append(entry)

# Add Chit-Chat (Safety Buffer)
chit_chat = [
    ("Hi", "Hello! I am your Smart Travel Planner. Where would you like to go?"),
    ("Who are you?", "I am an AI agent designed to help you plan trips using Maps and Weather tools."),
    ("Thanks", "You're welcome! Let me know if you need anything else."),
]
for q, a in chit_chat:
    dataset.append({"messages": [{"role": "user", "content": q}, {"role": "assistant", "content": a}]})

# Split into train (80%) and validation (20%)
random.shuffle(dataset)
split_idx = int(len(dataset) * 0.8)
train_data = dataset[:split_idx]
valid_data = dataset[split_idx:]

# Save train set
train_file = "train.jsonl"
with open(train_file, "w") as f:
    for entry in train_data:
        f.write(json.dumps(entry) + "\n")

# Save validation set
valid_file = "valid.jsonl"
with open(valid_file, "w") as f:
    for entry in valid_data:
        f.write(json.dumps(entry) + "\n")

print(f"✅ Success! Generated {len(train_data)} training examples in '{train_file}'.")
print(f"✅ Generated {len(valid_data)} validation examples in '{valid_file}'.")
