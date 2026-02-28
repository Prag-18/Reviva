from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from .database import engine
from . import models
from .routes import users, donors, requests, chat, verification, admin, moderation


# ==============================
# CREATE TABLES
# ==============================
models.Base.metadata.create_all(bind=engine)


def _run_startup_migrations() -> None:
    # Keep existing databases compatible after adding trust-layer columns.
    with engine.begin() as conn:
        conn.execute(
            text("ALTER TABLE messages ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'sent'")
        )
        conn.execute(
            text("UPDATE messages SET status = 'sent' WHERE status IS NULL")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified_donor BOOLEAN DEFAULT FALSE")
        )
        conn.execute(
            text("ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status VARCHAR DEFAULT 'pending'")
        )
        conn.execute(
            text("UPDATE users SET phone_verified = FALSE WHERE phone_verified IS NULL")
        )
        conn.execute(
            text("UPDATE users SET email_verified = FALSE WHERE email_verified IS NULL")
        )
        conn.execute(
            text("UPDATE users SET is_verified_donor = FALSE WHERE is_verified_donor IS NULL")
        )
        conn.execute(
            text("UPDATE users SET verification_status = 'pending' WHERE verification_status IS NULL")
        )


_run_startup_migrations()


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
app.include_router(verification.router)
app.include_router(moderation.router)
app.include_router(admin.router)
app.include_router(donors.router)
app.include_router(requests.router)
app.include_router(chat.router)


# ==============================
# ROOT
# ==============================
@app.get("/")
def home():
    return {"message": "Organ Donor API Running"}
