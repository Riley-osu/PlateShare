import array
import collections
import os
from google.cloud.firestore_v1 import collection, document
import uvicorn
import json
import firebase_admin
from firebase_admin import credentials, firestore
from fastapi import FastAPI
import firebaseToFlutter

app = FastAPI(title="Test App")

@app.get("/")
def health_check():
    """A simple test for checking if the server is running.
    Will always return active since you could call the server."""
    return {"status":200, "message":"OK"}

@app.get("/test-db")
def test_database_connection():
    """Returns a system message with the status of the database connection."""
    try:
        returnCode = firebaseToFlutter.get_database_field("users", "Firebase001", "username")
        return returnCode
    except Exception as e:
        return {"status":404, "message":str(e)}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)