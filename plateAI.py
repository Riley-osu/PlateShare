import os
from dotenv import load_dotenv
import base64
import json
import requests
import imageHandling

# Directory for input image to be analyzed
imageDir = ["testImages/food1.jpg", "testImages/food2.png", "testImages/food3.jpg"] 

# Loads .env
load_dotenv()

# Defines Ollama's path, key, and model; pulled from environment variables
# Also contains default parameters if OLLAMA_HOST or OLLAMA_MODEL is not found
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "https://api.ollama.com".rstrip("/"))
OLLAMA_API_KEY = os.getenv("OLLAMA_API_KEY", "")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "deepseek-v4.1-flash") 

# Ensures OlLAMA_API_KEY is present
if not OLLAMA_API_KEY:
    raise RuntimeError("OLLAMA_API_KEY's environment variable is NOT found!")


def analyze_food(image:bytes) -> dict:
    """ Sends HTTPs request to Ollama Cloud service under templated parameters to be analyzed and returned as a JSON object, then returned as a converted Python dict. """
    # Converts image from bytes to Base64 for transfer
    base64Img = base64.b64encode(image).decode("utf-8")

    # Template to prompt Ollama to analyze food image with specific JSON fields
    prompt = """
        You are an AI that visually analyzes images of food.
        Inspect the provided image of food and store listing data as parameterized below.

        Return ONLY a JSON object with the following keys:
        {
            "safe": true or false (safe to eat or not)
            "freshness": 1-10 (10 being perfectly fresh and 1 being completely spoiled),
            "expiration":  0 or more days until expiration,
            "allergens": ["list", "of", "possible", "allergens", "contained", "within", "food"],
            "religious_constraints": ["list", "of", "possible", "religious", "restrictions"],
        }
    """

    # Defines Ollama message format
    message = {
        "model": OLLAMA_MODEL,
        "messages": [
            {
                "role": "user",
                "content": prompt,
                "images": [base64Img]
            }
        ],
        "format": "json",
        "stream": False
    }

    # Sets headers to ensure proper output
    headers = {"Content-Type": "application/json"}
    if OLLAMA_API_KEY:
        headers["Authorization"] = f"Bearer {OLLAMA_API_KEY}"

    # Tries call to Ollama Cloud service
    try:
        response = requests.post(
            f"{OLLAMA_HOST}/api/chat",
            headers = headers,
            json = message,
            timeout = 45
        )
        # Checks HTTP status code for API response and throws exception if failed
        response.raise_for_status()
    # Throws exception
    except Exception as e:
        print(e)

    # Safely pulls from response without crashing from missing key
    content = response.json().get("message", {}).get("content", "")

    # Cleans up response if it's unnecessarily wrapped and labeled
    if "```" in content:
        # Splits unwanted string and takes the inner block
        content = content.split("```")[1]
        # Remvoes json tag
        if content.lower.startswith("json"):
            content = content[4:]
        content.strip

    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        print("JSON decoding failed: {e}")

# Function for local testing
def test_all():
    """ Calls all images in imageDir array to be analyzed """
    for i in imageDir:
        with open (i, "rb") as file:
            image = file.read()
            print(analyze_food(image))

# Testing sample images
# test_all()
with open(imageDir[0], "rb") as file:
    print(analyze_food(file.read()))
file.close()
