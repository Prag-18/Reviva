from fastapi import FastAPI 
from fastapi.middleware.cors import CORSMiddleware
from .database import engine
from . import models
from .routes import users, donors, requests
from fastapi import WebSocket, WebSocketDisconnect


models.Base.metadata.create_all(bind=engine)

app = FastAPI()
app.state.active_connections = []

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router)
app.include_router(donors.router)
app.include_router(requests.router)


@app.get("/")
def home():
    return {"message": "Organ Donor API Running"}


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    app.state.active_connections.append((user_id, websocket))

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        app.state.active_connections.remove((user_id, websocket))
