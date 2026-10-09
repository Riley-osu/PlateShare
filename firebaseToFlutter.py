import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
from pathlib import Path
from imageHandling import imageHandler
import base64
import io

cred = ""

if Path("firebase_admin.json").is_file():
    cred = credentials.Certificate("firebase_admin.json")
else:
    if Path("/etc/secrets/firebase_admin.json").is_file():
        cred = credentials.Certificate("/etc/secrets/firebase_admin.json")
    else:
        raise ImportWarning() #rework later so the app will run without admin database permissions

if not firebase_admin._apps and cred != "":
    firebase_admin.initialize_app(cred)
else:
    firebase_admin.initialize_app()

db = firestore.client()


def get_database_field(collection:str, document:str, field:str):
    """gets a preexisting field within the database. Returns a empty string if it failed to do so"""
    doc_ref = db.collection(collection).document(document)
    try:
        return doc_ref.get()
    except Exception as e:
        print(e)
        return False

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

def add_listing(foodType:str, description:str, quanity:int, location:str, organizationID:int, startTime:str, endTime:str, image) -> bool:
    """Add a new listing to the database with the given information. Returns false if it failed to do so.
    Pass time using the following:
    from datatime import datetime
    startTime = datetime(time).isoformat()"""

    ListingID = generate_ListingID(organizationID, location, startTime)
    doc_ref = db.collection('listings').document(ListingID)

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
            "imageURL": "",
            "status": "available",
            "createdAt": {
                "Date": startTime,
                "_seconds": startTime
            },
            "organizationID": organizationID
        })
        return store_image(ListingID, image)
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

def edit_listing(listingID:str, field:str, data) -> bool:
    doc_ref = db.collection('listings').document(listingID)
    try:
        doc_ref.update({
            field: data
        })
        return True
    except Exception as e:
        print(e)
        return False

def store_image(listingID:str, img) -> bool:
    """Stores an image to the given listing. Created for interal use only"""
    rawBytes = imageHandler.get_image_bytes(img, format="JPEG")

    base64Encoded = base64.b64encode(rawBytes).decode('utf-8')

    return edit_database_field("listings", listingID, "imageURL", base64Encoded)

def get_image(listingID:str):
    """Returns an image from the database."""
    
    base64String = get_database_field("listings", listingID, "imageURL").to_dict()["imageURL"]
    rawBytes = base64.b64decode(base64String)
    byteStream = io.BytesIO(rawBytes)
    image = imageHandler.load_image(byteStream)
    #image.show() #how to show the image quickly for testing

    return image

def generate_ListingID(organizationID:int, location:str, startTime:str) -> str:
    """Use to get the ListingID from for any listing given that you know the orgnaization that posted it, location and start time"""
    return str(organizationID) + location + startTime
