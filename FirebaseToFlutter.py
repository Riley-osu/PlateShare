import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import datetime
import time

cred = credentials.Certificate("firebase_admin.json")

if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

doc_ref = db.collection('users').document('Firebase001')

try:
    doc_ref.update({
  "username": "testuser123",
  "firstName": "first",
  "lastName": "last",
  "role": "student",
  "status": "active",
  "createdAt": {
    "_seconds": 1789084139,
    "_nanoseconds": 0
  },
  "email": "test@example.com"
})
except Exception as e:
    print(e)


def edit_Database_Field(collection:str, document:str, field:str, data) -> bool:
    doc_ref = db.collection(collection).document(document)
    try:
        doc_ref.update({
            field: data
        })
        return True
    except Exception as e:
        print(e)
        return False

def add_database_User(username:str, firstName:str, lastName:str, role:str, email:str) -> bool:
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

def add_listing(foodType:str, description:str, quanity:int, location:str, organizationID:int, startTime:str, endTime:str, image:str) -> bool:
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

def delete_listing(listingID:str):
    doc_ref = db.collection('listings').document('listeningID')
    doc_ref.delete()