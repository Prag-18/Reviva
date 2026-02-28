import uuid
import json
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from .. import models
from ..auth import get_current_user
from ..database import get_db

router = APIRouter()


# ======================================
# IN-MEMORY CHAT CONNECTION MANAGER
# ======================================
class ChatConnectionManager:
    def __init__(self):
        # { user_id: [websocket, ...] }
        self.active: dict[str, list[WebSocket]] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        if user_id not in self.active:
            self.active[user_id] = []
        self.active[user_id].append(websocket)

        await self.broadcast_status(user_id, "online")

    async def disconnect(self, user_id: str, websocket: WebSocket):
        if user_id in self.active:
            self.active[user_id].remove(websocket)
            if not self.active[user_id]:
                del self.active[user_id]

        await self.broadcast_status(user_id, "offline")

    async def send_to_user(self, user_id: str, message: dict):
        connections = self.active.get(str(user_id), [])
        for ws in connections:
            try:
                await ws.send_text(json.dumps(message))
            except Exception:
                pass

    async def broadcast_status(self, user_id: str, status: str):
        for uid in self.active:
            if uid != user_id:
                await self.send_to_user(uid, {
                    "type": "status",
                    "user_id": user_id,
                    "status": status
                })


chat_manager = ChatConnectionManager()


# ======================================
# WEBSOCKET CHAT ENDPOINT
# ws://host/chat/ws/{user_id}?token=JWT
# ======================================
@router.websocket("/chat/ws/{user_id}")
async def chat_websocket(
    websocket: WebSocket,
    user_id: str,
    token: str,
    db: Session = Depends(get_db),
):
    # Validate token manually (WebSocket can't use Depends for auth header)
    from jose import jwt, JWTError
    import os
    from dotenv import load_dotenv
    load_dotenv()

    SECRET_KEY = os.getenv("SECRET_KEY")
    ALGORITHM = os.getenv("ALGORITHM", "HS256")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_user_id = uuid.UUID(payload.get("sub"))
    except Exception:
        await websocket.close(code=4001)
        return

    # Make sure the user_id in the path matches the token
    if str(token_user_id) != user_id:
        await websocket.close(code=4003)
        return

    user = db.query(models.User).filter(models.User.id == token_user_id).first()
    if not user:
        await websocket.close(code=4004)
        return

    await chat_manager.connect(user_id, websocket)

    try:
        while True:
            raw = await websocket.receive_text()

            try:
                data = json.loads(raw)
                msg_type = data.get("type", "message")
                receiver_id = uuid.UUID(data["receiver_id"])

                if msg_type == "typing":
                    await chat_manager.send_to_user(
                        str(receiver_id),
                        {
                            "type": "typing",
                            "sender_id": user_id
                        }
                    )
                    continue

                if msg_type == "stop_typing":
                    await chat_manager.send_to_user(
                        str(receiver_id),
                        {
                            "type": "stop_typing",
                            "sender_id": user_id
                        }
                    )
                    continue

                if msg_type != "message":
                    await websocket.send_text(json.dumps({"error": "Unsupported message type"}))
                    continue

                content = data.get("content", "").strip()
            except Exception:
                await websocket.send_text(json.dumps({"error": "Invalid message format"}))
                continue

            if not content:
                continue

            # Validate receiver exists
            receiver = db.query(models.User).filter(models.User.id == receiver_id).first()
            if not receiver:
                await websocket.send_text(json.dumps({"error": "Receiver not found"}))
                continue

            receiver_online = str(receiver_id) in chat_manager.active and bool(
                chat_manager.active.get(str(receiver_id))
            )

            # Save message to DB
            message = models.Message(
                sender_id=token_user_id,
                receiver_id=receiver_id,
                content=content,
                status="delivered" if receiver_online else "sent",
            )
            db.add(message)
            db.commit()
            db.refresh(message)

            payload_out = {
                "type": "chat_message",
                "id": str(message.id),
                "sender_id": str(message.sender_id),
                "receiver_id": str(message.receiver_id),
                "content": message.content,
                "created_at": message.created_at.isoformat(),
                "is_read": message.is_read,
                "status": message.status,
            }

            # Deliver to receiver if online
            await chat_manager.send_to_user(str(receiver_id), payload_out)

            # Echo back to sender
            await chat_manager.send_to_user(user_id, payload_out)

    except WebSocketDisconnect:
        await chat_manager.disconnect(user_id, websocket)


# ======================================
# GET CHAT HISTORY BETWEEN TWO USERS
# GET /chat/history/{other_user_id}
# ======================================
@router.get("/chat/history/{other_user_id}")
async def get_chat_history(
    other_user_id: uuid.UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
    limit: int = 50,
    offset: int = 0,
):
    other_user = db.query(models.User).filter(models.User.id == other_user_id).first()
    if not other_user:
        raise HTTPException(status_code=404, detail="User not found")

    messages = (
        db.query(models.Message)
        .filter(
            or_(
                and_(
                    models.Message.sender_id == current_user.id,
                    models.Message.receiver_id == other_user_id,
                ),
                and_(
                    models.Message.sender_id == other_user_id,
                    models.Message.receiver_id == current_user.id,
                ),
            )
        )
        .order_by(models.Message.created_at.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    # Mark messages sent to current_user as read
    updated = db.query(models.Message).filter(
        models.Message.sender_id == other_user_id,
        models.Message.receiver_id == current_user.id,
        models.Message.is_read == False,
    ).all()

    for msg in updated:
        msg.is_read = True
        msg.status = "read"

    db.commit()

    for msg in updated:
        await chat_manager.send_to_user(
            str(other_user_id),
            {
                "type": "read_receipt",
                "message_id": str(msg.id)
            }
        )

    return [
        {
            "id": str(m.id),
            "sender_id": str(m.sender_id),
            "receiver_id": str(m.receiver_id),
            "content": m.content,
            "created_at": m.created_at.isoformat(),
            "is_read": m.is_read,
            "status": m.status,
        }
        for m in messages
    ]


# ======================================
# GET ALL CONVERSATIONS (INBOX)
# GET /chat/conversations
# ======================================
@router.get("/chat/conversations")
def get_conversations(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    from sqlalchemy import text

    result = db.execute(text("""
        SELECT DISTINCT ON (other_user_id)
            other_user_id,
            users.name AS other_user_name,
            users.role AS other_user_role,
            messages.content AS last_message,
            messages.created_at AS last_message_at,
            messages.is_read,
            messages.sender_id
        FROM (
            SELECT
                CASE
                    WHEN sender_id = :uid THEN receiver_id
                    ELSE sender_id
                END AS other_user_id,
                id, content, created_at, is_read, sender_id
            FROM messages
            WHERE sender_id = :uid OR receiver_id = :uid
        ) AS messages
        JOIN users ON users.id = messages.other_user_id
        ORDER BY other_user_id, messages.created_at DESC
    """), {"uid": current_user.id})

    rows = result.fetchall()

    return [
        {
            "other_user_id": str(row.other_user_id),
            "other_user_name": row.other_user_name,
            "other_user_role": row.other_user_role,
            "last_message": row.last_message,
            "last_message_at": row.last_message_at.isoformat() if row.last_message_at else None,
            "unread": not row.is_read and str(row.sender_id) != str(current_user.id),
        }
        for row in rows
    ]
