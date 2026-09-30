import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
from pathlib import Path

cred = ""

if Path("firebase_admin.json").is_file():
    cred = credentials.Certificate("firebase_admin.json")
else:
    cred = credentials.Certificate("/etc/secrets/firebase_admin.json")


if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def edit_database_field(collection:str, document:str, field:str, data) -> bool:
    """Edit a preexisting field within the database. Returns false if it failed to do so."""
    doc_ref = db.collection(collection).document(document)
    try:
        doc_ref.update({
            field: data
        })
        return True
    except Exception as e:
        print(e)
        return False

def add_database_user(username:str, firstName:str, lastName:str, role:str, email:str) -> bool:
    """Add a new database user. Returns false if it failed to do so."""
    doc_ref = db.collection('users').document(username)

    try:
        doc_ref.set({
            "username": username,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "role": role,
            "status": "active",
            "createdAt": {
                "Date": datetime,
                "_seconds": datetime.now
            }
        })
        return True
    except Exception as e:
        print(e)

def delete_database_user(userName:str) -> bool:
    """Delete a user from the database. Returns false if it failed to do so."""
    doc_ref = db.collection('users').document(userName)
    doc_ref.delete()

    if doc_ref.get():
        return False
    return True

def add_listing(foodType:str, description:str, quanity:int, location:str, organizationID:int, startTime:str, endTime:str, image:str) -> bool:
    """Add a new listing to the database with the given information. Returns false if it failed to do so."""
    doc_ref = db.collection('listings').document('listing002')

    try:
        doc_ref.set({
            "foodName": foodType,
            "description": description,
            "quantity": quanity,
            "location": location,
            "pickupStart": {
                "Date": startTime,
                "_seconds": startTime
            },
            "pickupEnd": {
                "Date": endTime,
                 "_seconds": endTime
            },
            "imageURL": image,
            "status": "available",
            "createdAt": {
                "Date": startTime,
                "_seconds": startTime
            },
            "organizationID": organizationID
        })
        return True
    except Exception as e:
        print(e)
        return False

def delete_listing(listingID:str) -> bool:
    """Delete a listing from the database. Returns false if it failed to do so."""
    doc_ref = db.collection('listings').document(listingID)
    doc_ref.delete()

    if doc_ref.get():
        return False
    return True
