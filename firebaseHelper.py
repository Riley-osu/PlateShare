import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone
from pathlib import Path
from dataclasses import dataclass, field
import math
from typing import List, Optional, Any
from fastapi import HTTPException
import uuid

def init_firestore():
    if not firebase_admin._apps:
        for path in ("firebase_admin.json", "/etc/secrets/firebase_admin.json"):
            if Path(path).is_file():
                firebase_admin.initialize_app(credentials.Certificate(path))
                break
        else:
            try:
                firebase_admin.initialize_app()
            except Exception:
                return None
    return firestore.client()

db = init_firestore() 

def _response(status: int, message) -> dict:
    return {"status": status, "message":message}

UNAUTHORIZED = _response(401, "unauthorized")

# Added helper ISO parsing function
def parse_iso_datetime(dtIn: str) -> datetime:
    # dt = datetime.fromisoformat(dtIn.replace("Z", "+00:00"))
    # if dt.tzinfo is None:
    #     dt = dt.replace(tzinfo = timezone.utc)
    # return dt
    try:
        return datetime.fromisoformat(dtIn.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        raise HTTPException(status_code = 400, detail = f"Invalid ISO Datetime string: {dtIn}")

def get_database_field(collection:str, document:str, field:str) -> dict:
    """gets a preexisting field within the database. Returns a empty string if it failed to do so"""
    httpsReturn = {"status": 200, "message": "OK"}
    # if db is None:
    #     return UNAUTHORIZED
    try:
        # docData = db.collection(collection).document(document).get().to_dict()
        docData = db.collection(collection).document(document).get()
        if not docData.exists:
            return _response(404, "Document not found")
        docData = docData.to_dict()
        # return _response(200, docData[field])
        return _response(200, docData.get(field))
    except Exception as e:
        return _response(400, str(e))

def edit_database_field(collection:str, document:str, field:str, data) -> dict:
    """Edit a preexisting field within the database. Returns https code"""
    if db is None:
        return UNAUTHORIZED
    try:
        db.collection(collection).document(document).update({field: data})
        return _response(200,"OK")
    except Exception as e:
            return _response(400, str(e))

def add_database_user(username:str, firstName:str, lastName:str, role:str, email:str) -> dict:
    """Add a new database user."""
    if db is None:
        return UNAUTHORIZED
    try:
        db.collection("users").document(username).set({
            "username": username,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "role": role,
            "status": "active",
            "createdAt": firestore.SERVER_TIMESTAMP
        })
        return _response(201, "Created")
    except Exception as e:
            return _response(400, str(e))

def delete_database_user(userName:str) -> dict:
    """Delete a user from the database."""    
    if db is None:
        return UNAUTHORIZED
    docRef = db.collection("users").document(userName)
    docRef.delete()
    if docRef.get().exists:
        return _response(409, "Conflict")
    return _response(204, "No Content")

def generate_ListingID (organizationID: int, location: str, startTime: str) -> str:
    """Get the ListingID for any listing, given its organization, location and start time."""
    return str(organizationID) + location + startTime


def add_listing(foodType:str, description:str, quantity:int, location:str, organizationID:int, startTime:str, endTime:str, imageURL: Optional[str] = None, isSafe: bool = True, freshnessScore: int = 10, expirationDays: int = 0, allergensList: Optional[List[str]] = None, constraintsList: Optional[List[str]] = None) -> dict:
    """Add a new listing to the database. Pass time as: datetime(...).isoformat()"""
    
    httpsReturn = {"status": 200, "message": "OK"}
    # if db != None:
    #     return UNAUTHORIZED

    if db is None:
        return UNAUTHORIZED
    
    listingID = generate_ListingID(organizationID, location, startTime)

    try:
        db.collection("listings").document(listingID).set({
            "foodName": foodType,
            "description": description,
            "quantity": quantity,
            "maxQuantity": quantity,
            "location": location,
            "pickupStart": parse_iso_datetime(startTime),
            "pickupEnd": parse_iso_datetime(endTime),
            # "pickupStart": {
            #     "Date": startTime,
            #     "_seconds": startTime
            # },
            # "pickupEnd": {
            #     "Date": endTime,
            #     "_seconds": endTime
            # },
            "imageURL": imageURL,
            "status": "available",
            "createdAt": firestore.SERVER_TIMESTAMP,
            # "createdAt": {
            #     "Date": startTime,
            #     "_seconds": startTime
            # },
            "organizationID": organizationID,
            "ai_metadata": {
                "safe": isSafe,
                "freshness": freshnessScore,
                "expiration": expirationDays,
                "allergens": allergensList or [],
                "constraints": constraintsList or []
            }
        })
        return _response(200,listingID)
    except Exception as e:
        return _response(400, str(e))

def delete_listing(listingID:str) -> dict:
    """Delete a listing from the database."""
    if db is None:
        return _response(401, "Unauthorized")
    docRef = db.collection('listings').document(listingID)
    docRef.delete()
    
    if docRef.get().exists:
        return _response(409, "Conflict")
    return _response(204, "No Content")

def edit_listing(listingID:str, field:str, data) -> dict:
    """Edit a field on a listing."""
    return edit_database_field("listings", listingID, field, data)

"""Listing reservations"""

@firestore.transactional

def _adjust_spots(transaction,docRef,delta:int) -> int:
    """Atomically change remaing spots by delta. Raises ValueError if out of range."""
    snap = docRef.get(transaction=transaction)
    if not snap.exists:
        raise KeyError("Listing not foun")
    data = snap.to_dict()
    remaining = data["quantity"] + delta
    maxSpots = data.get("maxQuantity")
    if remaining < 0 or (maxSpots is not None and remaining > maxSpots):
        raise ValueError("Reservation amount out of range")
    transaction.update(docRef, {"quantity": remaining})
    return remaining

def _change_reservations(listingID: str, delta: int) -> dict:
    if db is None: 
        return UNAUTHORIZED
    try:
        docRef = db.collection("listings").document(listingID)
        remaining = _adjust_spots(db.transaction(), docRef,delta)
        return _response(200, remaining)
    except ValueError as e:
        return _response(409, str(e))
    except KeyError as e:
        return _response(404,str(e))
    except Exception as e:
        return _response(400, str(e))
    
def add_reservation(listingID: str, amount: int) -> dict:
    """Reserve amount spots. Fails with 409 if no spots remain"""
    return _change_reservations(listingID, -amount)

def remove_reservation(listingID: str, amount: int) -> dict:
    """remove amount spots. Fails with 409 if exceeds listings max"""
    return _change_reservations(listingID, amount)

def get_remaining_spots(listingID: str) -> dict:
    """Gets the remaining spots available in given listing"""
    return get_database_field("listings",listingID, "quantity")

def _time_until(listingID:str, field:str) -> dict:
    # result = get_database_field("listings",listingID, field)
    # if result["status"] != 200:
    #     return result
    try:
        # target = datetime.fromisoformat(result["message"]["Date"])
        # if target.tzinfo is None:
        #     target = target.replace(tzinfo=timezone.utc)
        # delta = target - datetime.now(timezone.utc)
        # minutes = max(math.cell(delta.total_seconds() / 60),0)
        # return _response(200,minutes)
        docRef = db.collection("listings").document(listingID).get()
        if not docRef.exists:
            return _response(404, "Listing not found")

        targetTime = docRef.to_dict().get(field)
        if isinstance(targetTime, str):
            targetTime = parse_iso_datetime(targetTime)

        timeDelta = targetTime - datetime.now(timezone.utc)
        mins = max(math.ceil(timeDelta.total_seconds() / 60), 0)
        return _response(200, mins)
    except Exception as e:
        return _response(400, str(e))
    
def get_time_until_start(listingID: str) -> dict:
    """minutes until pickup starts (0) if pickup has started"""
    return _time_until(listingID, "pickupStart")

def get_time_until_end(listingID: str) -> dict:
    """minutes until pickup ends"""
    return _time_until(listingID, "pickupEnd")

@dataclass
class Listing:
    foodType: str
    description: str
    maxReservations: int
    location: str
    organizationID: int
    startTime: str
    endTime: str
    imageURL: Optional[str] = None

    # AI Fields
    isSafe: bool = True
    freshnessScore: int = 10
    expirationDays: int = 0
    allergensList: List[str] = field(default_factory = list)
    constraintsList: List[str] = field(default_factory = list)
    
    def __post_init__(self):
        if self.maxReservations < 1:
            raise ValueError("maxReservations must be at least 1")
        if parse_iso_datetime(self.endTime) <= parse_iso_datetime(self.startTime):
            raise ValueError("endTime must be after startTime")
        
    @property
    def listingID(self) -> str:
        return generate_ListingID(self.organizationID, self.location, self.startTime)
    
def create_listing(listing:Listing) -> dict:
    """Writes a validated Liting to the db"""
    # return add_listing(listing.foodType, listing.description, listing.maxReservations,
    #                    listing.location, listing.organizationID, listing.startTime,
    #                    listing.endTime)
    return add_listing(
        foodType = listing.foodType,
        description = listing.description,
        quantity = listing.maxReservations,
        location = listing.location,
        organizationID = listing.organizationID,
        startTime = listing.startTime,
        endTime = listing.endTime,
        imageURL = listing.imageURL,
        isSafe = listing.isSafe,
        freshnessScore = listing.freshnessScore,
        expirationDays = listing.expirationDays,
        allergensList = listing.allergensList,
        constraintsList = listing.constraintsList
    )