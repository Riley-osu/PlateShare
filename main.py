import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Test App")

@app.get("/")
def health_check():
    return {"status":"Active"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)