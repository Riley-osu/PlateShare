import ollama

# Directory for input image to be analyzed
imageDir = 'testImages/food1.jpg' 
# Prompts user on what to ask about designated image
prompt = input("What do you want to know about the image?:\n")

# Function that takes an image of food and a user's inquiry to evaluate the image by
def getImageFlag(food, userPrompt):
    # Establishes message to qwen3-vl with user's prompt
    message = {
        "role": "user",
        "content": userPrompt,
    }

    # Ensures an image file is provided, if so, add image to message to LLM
    if food is not None:
        with open(food, "rb") as image:
            message["images"] = [image.read()]

    # Tries to send message to Ollama, if an error occurs, throws exception
    try:
        print("\nProcessing...\n")

        response = ollama.chat(
            model= "qwen3-vl",
            messages = [message]           
        )

        # Prints response message
        print("[PlateAI]:")
        print(response["message"]["content"])

    except Exception as e:
        print(f"\nAn error occurred: {e}")

# Calls function
getImageFlag(imageDir, prompt)