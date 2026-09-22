import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

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