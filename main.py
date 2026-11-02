import array
import collections
import os
from google.cloud.firestore_v1 import collection, document
import uvicorn
import json
import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import *
import firebaseHelper
from plateAI import analyze_food
from fastapi.middleware.cors import CORSMiddleware
import base64
from geoCoding import *
from typing import Optional

app = FastAPI(title="PlateShare")

# CORS Flutter Communiaction
app.add_middleware(
    CORSMiddleware,
    allow_origins = ["*"],
    allow_credentials = True,
    allow_methods = ["*"],
    allow_headers = ["*"],
)

@app.get("/")
def health_check():
    """A simple test for checking if the server is running.
    Will always return active since you could call the server."""
    return {"status":200, "message":"OK"}

@app.get("/test-db")
def test_database_connection():
    """Returns a system message with the status of the database connection."""
    try:
        returnCode = firebaseHelper.get_database_field("users", "Firebase001", "username")
        return returnCode
    except Exception as e:
        return {"status":404, "message":str(e)}

@app.get("/test-message-send")
def test_messages():
    try:
        returnCode = firebaseHelper.add_message("TestID67Student Union2026-10-23T15:25:00.000Z", True, "firebase005", "testing messages")
        return returnCode
    except Exception as e:
        return {"status":404, "message":str(e)}


@app.get("/test-message-get")
def test_messages():
    try:
        returnCode = firebaseHelper.get_listing_message_for_user("TestID67Student Union2026-10-23T15:25:00.000Z", "firebase005")
        return returnCode
    except Exception as e:
        return {"status":404, "message":str(e)}

    
if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

@app.post("/api/listings")
async def create_listing(
    
    # User Fields 
    foodName: str = Form(...),
    description: str = Form(...),
    createdAt: str = Form(...),
    image: UploadFile = File(...),
    location: str = Form(...),
    organizationID: str = Form(...),
    pickupStart: str = Form(...),
    pickupEnd: str = Form(...),
    quantity: int = Form(1),
    reservationCount: int = Form(1),
    status: str = Form("available")

):

    # createdAt = datetime.now(timezone.utc).isoformat()
    # Ensures image was properly loaded
    imageBytes = await image.read()
    # Otherwise, throw exception
    if not imageBytes:
        raise HTTPException(status_code = 400, detail = "Uploaded image is empty")

    """Geocodes the provided address"""
    try:
        lat,lng = await geocodeAddress(location)
    except geocodeError as e:
        raise HTTPException(status_code = 400, detail = str(e))
    
    # AI Metadata
    aiSafe = True
    aiFreshness = 10
    aiExpiration = 0
    aiAllergens = []
    aiConstraints = []

    # Runs image through PlateAI (Ollama Cloud) for analysis 
    try:
        aiResponse = analyze_food(imageBytes)
        aiSafe = aiResponse.get("safe", True)
        aiFreshness = aiResponse.get("freshness", 10)
        aiExpiration = aiResponse.get("expiration", 0)
        aiAllergens = aiResponse.get("allergens", [])
        aiConstraints = aiResponse.get("constraints", [])
    except Exception as e:
        # print(e)
        pass

    # Saves image as B64 URL that Firestore can store
    base64Str = base64.b64encode(imageBytes).decode("utf-8")
    imageURL = f"data:image/jpeg;base64,{base64Str}"

    # Attempts to create listing using helper function dataclass
    try:
        newListing = firebaseHelper.Listing(
            foodType = foodName,
            description = description,
            maxReservations = 1,
            location = location,
            organizationID = organizationID,
            startTime = pickupStart,
            endTime = pickupEnd,
            imageURL = imageURL,
            lat = lat, 
            lng = lng,
            isSafe = aiSafe,
            freshnessScore = aiFreshness,
            expirationDays = aiExpiration,
            allergensList = aiAllergens,
            constraintsList = aiConstraints  
        )
    except Exception as e:
        raise e

    # Commit to Firestore
    apiResponse = firebaseHelper.create_listing(newListing)
    if apiResponse.get("status") != 200:
        raise HTTPException(
            status_code = apiResponse.get("status", 400),
            detail = apiResponse.get("message")      
        )

    return{
        "status": "success",
        "listingID": apiResponse.get("message"),
        "aiResponse": {
            "safe": aiSafe,
            "freshness": aiFreshness,
            "expiration": aiExpiration,
            "allergens": aiAllergens,
            "constraints": aiConstraints
        }
    }


@app.delete("/api/listings/{listingID}")
async def delete_listing(listingID: str):
    
    apiResponse = firebaseHelper.delete_listing((listingID))

    status = apiResponse.get("status", 400)
    if status not in (200, 204):
        raise HTTPException(
            status_code = apiResponse.get("status", 400),
            detail = apiResponse.get("message", "Delete failed")
        )
    return {"status": "success", "message": f"Listing {listingID} deleted"}

@app.patch("/api/listings/{listingID}")
async def update_listing(
    listingID: str,
    foodName: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    quantity: Optional[int] = Form(None),
    location: Optional[str] = Form(None),
    pickupStart: Optional[str] = Form(None),
    pickupEnd: Optional[str] = Form(None),
    status: Optional[str] = Form(None),
    image: Optional[UploadFile] = File(None),
):
    updateFields = {}

    if foodName is not None:
        updateFields["foodType"] = foodName
    if description is not None:
        updateFields["description"] = description
    if quantity is not None:
        updateFields["maxReservations"] = quantity
    if location is not None:
        updateFields["location"] = location
        try:
            lat, lng = await geocodeAddress(location)
            updateFields["lat"] = lat
            updateFields["lng"] = lng
        except Exception as e:
            raise HTTPException(status_code = 400, detail = str(e))
    if pickupStart is not None:
        updateFields["startTime"] = pickupStart
    if pickupEnd is not None:
        updateFields["endTime"] = pickupEnd
    if status is not None:
        updateFields["status"] = status

    if image is not None:
        imageBytes = await image.read()
        if imageBytes:
            base64Str = base64.b64encode(imageBytes).decode("utf-8")
            updateFields["imageURL"] = f"data:image/jpeg;base64,{base64Str}"

    if not updateFields:
        raise HTTPException(status_code = 400, detail = "No fields were provided.")

    apiResponse = firebaseHelper.update_listing(listingID, updateFields)
    if apiResponse.get("status", 400) not in (200, 204):
        raise HTTPException(status_code = apiResponse.get("status", 400), detail = apiResponse.get("message", "Update failed!"))
    return {"status": "success", "message": f"Listing {listingID} updated successfully."}
