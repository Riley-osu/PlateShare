# For local testing:
# import ollama
import os
from dotenv import load_dotenv

load_dotenv()

OLLAMA_HOST = os.getenv("OLLAMA_HOST")
OLLAMA_API_KEY = os.getenv("OLLAMA_API_KEY")

if not OLLAMA_API_KEY:
    raise RuntimeError("OLLAMA_API_KEY's environment variable is NOT found!")








# # Directory for input image to be analyzed
# imageDir = "testImages/food1.jpg" 
# imageDir2 = "testImages/food2.png" 
# imageDir3 = "testImages/food3.jpg" 
# # Prompts user on what to ask about designated image
# prompt = input("What do you want to know about the image?:\n")

# # Function that takes an image of food and a user's inquiry to evaluate the image by
# def getImageFlag(food, userPrompt):
#     # Establishes message to qwen3-vl with user's prompt
#     message = {
#         "role": "user",
#         "content": userPrompt,
#     }

#     # Ensures an image file is provided, if so, add image to message to LLM
#     if food is not None:
#         with open(food, "rb") as image:
#             message["images"] = [image.read()]

#     # Tries to send message to Ollama, if an error occurs, throws exception
#     try:
#         print("\nProcessing...\n")

#         response = ollama.chat(
#             model= "qwen3-vl",
#             messages = [message]           
#         )

#         # Prints response message
#         print("[PlateAI]:")
#         print(response["message"]["content"])

#     except Exception as e:
#         print(f"\nAn error occurred: {e}")

# # Calls function
# # getImageFlag(imageDir, prompt)
# # getImageFlag(imageDir2, prompt)
# getImageFlag(imageDir3, prompt)
# # getImageFlag(None, prompt)