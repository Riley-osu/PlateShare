import ollama

# Takes user input
testInput = input("What do you want to ask?:\n")

# Tries input, if Ollama isn't active, an exception is thrown
try:
    print("\nProcessing...\n")

    
    response = ollama.chat(
        # Qwen3 Vision Model
        model="qwen3-vl", 

        messages=[
            {
                "role": "user",
                "content": testInput,
            },
        ]
    )
    
    # Prints output
    print("[PlateAI]:")
    print(response["message"]["content"])

# Exception
except Exception as e:
    print(f"\nAn error occurred: {e}")
    print("Ensure Ollama is actively running in the background!")
