import os
import hmac
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user
from ..database import get_db
from ..services.otp import (
    OTP_MAX_SENDS_PER_HOUR,
    OTP_MAX_VERIFY_ATTEMPTS,
    OTP_MIN_SEND_INTERVAL_SECONDS,
    generate_otp_code,
    hash_otp_code,
    otp_expiry_time,
)
from ..services.sms_provider import SMSProviderFactory

router = APIRouter()


def _bool_env(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


@router.post("/send-otp")
def send_otp(
    payload: schemas.SendOTPRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.phone is not None:
        current_user.phone = payload.phone.strip()
        current_user.phone_verified = False

    if not current_user.phone:
        raise HTTPException(status_code=400, detail="Phone number is required")

    now = datetime.utcnow()
    last_send_boundary = now - timedelta(seconds=OTP_MIN_SEND_INTERVAL_SECONDS)
    hour_boundary = now - timedelta(hours=1)

    recent_send = (
        db.query(models.OTPVerification)
        .filter(
            models.OTPVerification.user_id == current_user.id,
            models.OTPVerification.last_sent_at >= last_send_boundary,
        )
        .order_by(models.OTPVerification.last_sent_at.desc())
        .first()
    )
    if recent_send:
        raise HTTPException(status_code=429, detail="OTP sent too recently. Please wait before retrying")

    hourly_count = (
        db.query(models.OTPVerification)
        .filter(
            models.OTPVerification.user_id == current_user.id,
            models.OTPVerification.created_at >= hour_boundary,
        )
        .count()
    )
    if hourly_count >= OTP_MAX_SENDS_PER_HOUR:
        raise HTTPException(status_code=429, detail="OTP request limit reached. Try again later")

    db.query(models.OTPVerification).filter(
        models.OTPVerification.user_id == current_user.id,
        models.OTPVerification.verified == False,
    ).update({"expires_at": now})

    otp_code = generate_otp_code()
    otp_hash = hash_otp_code(current_user.id, otp_code)
    otp_row = models.OTPVerification(
        user_id=current_user.id,
        otp_code=otp_hash,
        expires_at=otp_expiry_time(),
        verified=False,
        attempts=0,
        created_at=now,
        last_sent_at=now,
    )
    db.add(otp_row)
    db.commit()

    message = f"Your Reviva verification code is {otp_code}. It expires in 5 minutes."
    SMSProviderFactory.create().send_sms(to_phone=current_user.phone, message=message)

    response_data = {
        "phone": current_user.phone,
        "expires_in_seconds": 300,
    }
    if _bool_env("DEBUG_VERIFICATION_TOKENS", default=False):
        response_data["debug_otp"] = otp_code

    return {
        "success": True,
        "message": "OTP sent successfully",
        "data": response_data,
    }


@router.post("/verify-otp")
def verify_otp(
    payload: schemas.VerifyOTPRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    now = datetime.utcnow()

    otp_row = (
        db.query(models.OTPVerification)
        .filter(
            models.OTPVerification.user_id == current_user.id,
            models.OTPVerification.verified == False,
            models.OTPVerification.expires_at >= now,
        )
        .order_by(models.OTPVerification.created_at.desc())
        .first()
    )

    if not otp_row:
        raise HTTPException(status_code=404, detail="No active OTP found or OTP expired")

    if otp_row.attempts >= OTP_MAX_VERIFY_ATTEMPTS:
        raise HTTPException(status_code=429, detail="Maximum OTP verification attempts exceeded")

    otp_row.attempts += 1
    otp_row.last_attempt_at = now

    expected_hash = hash_otp_code(current_user.id, payload.otp_code)
    if not hmac.compare_digest(otp_row.otp_code, expected_hash):
        db.commit()
        remaining = max(0, OTP_MAX_VERIFY_ATTEMPTS - otp_row.attempts)
        raise HTTPException(
            status_code=400,
            detail=f"Invalid OTP code. Remaining attempts: {remaining}",
        )

    otp_row.verified = True
    current_user.phone_verified = True
    db.commit()

    return {
        "success": True,
        "message": "Phone number verified successfully",
        "data": {
            "phone_verified": True,
            "user_id": str(current_user.id),
        },
    }
