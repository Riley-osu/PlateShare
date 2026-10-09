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

firebase_creds_env = os.getenv("FIREBASE_CREDENTIALS")

if not firebase_admin._apps:
    if firebase_creds_env:
        credDict = json.loads(firebase_creds_env)
        cred = credentials.Certificate(credDict)
        firebase_admin.initialize_app(cred)
    else:
        cred = credentials.Certificate("firebase_admin.json")
        firebase_admin.initialize_app(cred)

db = firestore.client()

app = FastAPI(title="Test App")


#from imageHandling import imageHandler
#from listing import listing
#picture = imageHandler.load_image(r"C:\Users\rcros\source\repos\Software Engineering\Screenshot 2025-08-13 211504.png")

#post = listing(5, "testD", "testT", "here", 52, "timeStart", "timeEnd", picture)

#imageHandler.load_image(firebaseToFlutter.get_database_field("listings", "52heretimeStart", "img")).show()
#firebaseToFlutter.get_image(firebaseToFlutter.generate_ListingID(52, "here", "timeStart"))

@app.get("/")
def health_check():
    """A simple test for checking if the server is running.
    Will always return active since you could call the server."""
    return {"status":"Active"}

@app.get("/test-db")
def test_database_connection():
    """Returns a system message with the status of the database connection."""
    try:
        collectionRef = db.collection("users")
        #plateshate-6fcd3

        docs = collectionRef.stream()

        fetchedData = []
        for doc in docs:
            documentDict = doc.to_dict()
            documentDict["users"] = doc.id
            fetchedData.append(documentDict)
        return {"status": "Success", "data": fetchedData}
    except Exception as e:
        return {"status": "Error", "message": str(e)}

@app.get("/debug/collections")
def list_all_collections():
    """Returns a system message will all the collections."""
    try:
        collections = db.collections()
        collectionNames = [coll.id for coll in collections]
        fetchedData = []

        doc = collection.stream()

        for col in collections:
            CollectionDict= doc.to_dict()
            CollectionDict["_id"] = doc.id
            fetchedData.append(CollectionDict)

        return {"status": "Sucess", "collections": collectionNames}
    except Exception as e:
        return {"status": "Error", "message": str(e)}

@app.get("/debug/documents/{collectionName}")
def get_all_documents_in_collection(collectionName:str):
    """Returns system message of all documents within the given collection."""
    try:
        docs = db.collection(collectionName).stream()
        fetchedData = []

        for doc in docs:
            CollectionDict = doc.to_dict()
            CollectionDict["_id"] = doc.id
            fetchedData.append(CollectionDict)

        if not fetchedData:
            return {"status": "Empty or Not Found", "message": f"No documents found in '{collectionName}'"} 

        return {"status": "Sucess", "total_documents": len(fetchedData), "data": fetchedData}
    except Exception as e:
        return {"status": "Error", "message": str(e)}

@app.get("/debug/documents-ids/{collectionName}")
def get_document_ids(collectionName:str):
    """Return a system message containing only the list of id's for any documents within the given collection."""
    try:
        docs = db.collection(collectionName).stream()
        docIds = [doc.id for doc in docs]

        for doc in docs:
            CollectionDict = doc.to_dict()
            CollectionDict["_id"] = doc.id
            docIds.append(CollectionDict)

        if not docIds:
            return {"status": "Empty or Not Found", "message": f"No documents found in '{collectionName}'"}
        return {"status": "Sucess", "total_documents": len(docIds), "data": docIds}
    except Exception as e:
        return {"status": "Error", "message": str(e)}

@app.get("/get-data/{collectionName}/{docId}")
def get_specific_document(docId:str):
    """Will return a system message with the given document from the given collection."""
    docId = "Firebase001"
    try:
        collection = db.collection("users")
        docRef = collection.document(docId)

        doc = docRef.get()
        if doc.exists:
            CollectionDict = doc.to_dict()
            if CollectionDict is None:
                return {"status": "Empty", "message": "Document exists but contains no data", "id":doc.id}
            CollectionDict["id"] = doc.id
            return {"status": "Success", "data": CollectionDict}
        else:
            return {"status": "Not Found", "message": f"document ID '{docId}' does not exist in this collection."}
    except Exception as e:
        return {"status": "Error", "message": str(e)}


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)