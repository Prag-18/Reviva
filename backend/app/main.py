from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from .database import engine
from . import models
from .routes import users, donors, requests, chat


# ==============================
# CREATE TABLES
# ==============================
models.Base.metadata.create_all(bind=engine)


# ==============================
# APP INIT
# ==============================
app = FastAPI(title="Organ Donor API", version="1.0.0")


# ==============================
# CORS (FIXED FOR FLUTTER WEB)
# ==============================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ✅ Allow all for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==============================
# ROUTERS
# ==============================
app.include_router(users.router)
app.include_router(donors.router)
app.include_router(requests.router)
app.include_router(chat.router)


# ==============================
# NOTIFICATION WEBSOCKET
# ws://host/ws/{user_id}
# ==============================
app.state.active_connections = []


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    await websocket.accept()
    app.state.active_connections.append((user_id, websocket))

    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        app.state.active_connections.remove((user_id, websocket))


# ==============================
# ROOT
# ==============================
@app.get("/")
def home():
    return {"message": "Organ Donor API Running"}