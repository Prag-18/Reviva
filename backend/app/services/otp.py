from __future__ import annotations

import hashlib
import os
import secrets
import uuid
from datetime import datetime, timedelta

OTP_LENGTH = 6
OTP_TTL_MINUTES = 5
OTP_MAX_VERIFY_ATTEMPTS = 5
OTP_MIN_SEND_INTERVAL_SECONDS = 60
OTP_MAX_SENDS_PER_HOUR = 5


def generate_otp_code() -> str:
    return f"{secrets.randbelow(10**OTP_LENGTH):0{OTP_LENGTH}d}"


def hash_otp_code(user_id: uuid.UUID, otp_code: str) -> str:
    salt = os.getenv("OTP_HASH_SALT", "dev-otp-salt")
    payload = f"{user_id}:{otp_code}:{salt}".encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def otp_expiry_time() -> datetime:
    return datetime.utcnow() + timedelta(minutes=OTP_TTL_MINUTES)
