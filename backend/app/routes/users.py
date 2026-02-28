import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
from pydantic import BaseModel

from ..database import get_db
from .. import models
from ..auth import (
    create_access_token,
    create_email_verification_token,
    decode_email_verification_token,
)
from ..auth import ENFORCE_EMAIL_VERIFICATION, get_current_user
from ..services.audit import log_audit_event
from ..services.email_provider import EmailProviderFactory

router = APIRouter()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALLOWED_DONATION_TYPES = {
    "blood", "kidney", "liver", "heart", "cornea", "bone_marrow"
}
ALLOWED_ROLES = {"donor", "seeker"}


def _bool_env(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "y", "on"}


# ================= LOGIN (OAuth2 compatible) =================
@router.post("/login")
async def login(
    request: Request,
    db: Session = Depends(get_db)
):
    form_data = await request.form()
    email = form_data.get("username") or form_data.get("email")
    password = form_data.get("password")

    if not email or not password:
        email = request.query_params.get("email") or request.query_params.get("username")
        password = request.query_params.get("password")

    if not email or not password:
        raise HTTPException(status_code=422, detail="Missing login credentials")

    user = db.query(models.User).filter(models.User.email == email).first()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email")

    if not pwd_context.verify(password, user.password):
        raise HTTPException(status_code=400, detail="Invalid password")

    if ENFORCE_EMAIL_VERIFICATION and not user.email_verified:
        raise HTTPException(status_code=403, detail="Email is not verified")

    access_token = create_access_token(data={"sub": str(user.id)})

    log_audit_event(
        db,
        user_id=user.id,
        action_type="login",
        metadata={
            "email": user.email,
            "ip": request.client.host if request.client else None,
            "user_agent": request.headers.get("user-agent"),
        },
    )

    # Keep top-level token fields for backward compatibility.
    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "access_token": access_token,
            "token_type": "bearer",
        },
        "access_token": access_token,
        "token_type": "bearer",
    }


# ================= REGISTER =================
@router.post("/register")
def register_user(
    name: str,
    email: str,
    password: str,
    role: str,
    donation_type: str,
    blood_group: str = None,
    phone: str = None,
    latitude: float = None,
    longitude: float = None,
    db: Session = Depends(get_db)
):
    role_normalized = role.lower().strip()
    donation_type_normalized = donation_type.lower().strip()

    if role_normalized not in ALLOWED_ROLES:
        raise HTTPException(status_code=400, detail="Invalid role")

    if donation_type_normalized not in ALLOWED_DONATION_TYPES:
        raise HTTPException(status_code=400, detail="Invalid donation type")

    if role_normalized == "donor" and not donation_type_normalized:
        raise HTTPException(status_code=400, detail="Donation type required")

    if role_normalized == "donor" and (latitude is None or longitude is None):
        raise HTTPException(status_code=400, detail="Location is required for donor registration")

    existing_user = db.query(models.User).filter(models.User.email == email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pw = pwd_context.hash(password)

    location_point = None
    if latitude is not None and longitude is not None:
        location_point = from_shape(Point(longitude, latitude), srid=4326)

    verification_status = "pending" if role_normalized == "donor" else "approved"

    user = models.User(
        name=name,
        email=email,
        password=hashed_pw,
        role=role_normalized,
        blood_group=blood_group,
        donation_type=donation_type_normalized,
        phone=phone,
        location=location_point,
        available=True,
        email_verified=False,
        phone_verified=False,
        is_verified_donor=False,
        verification_status=verification_status,
    )

    db.add(user)
    db.commit()
    db.refresh(user)

    verification_token = create_email_verification_token(user_id=user.id, email=user.email)
    verification_base_url = os.getenv("PUBLIC_API_BASE_URL", "http://localhost:8000")
    verification_url = f"{verification_base_url}/verify-email?token={verification_token}"
    EmailProviderFactory.create().send_verification_email(
        to_email=user.email,
        verification_url=verification_url,
    )

    response_data = {
        "user_id": str(user.id),
        "email": user.email,
        "verification_email_sent": True,
        "verification_status": user.verification_status,
    }
    if _bool_env("DEBUG_VERIFICATION_TOKENS", default=False):
        response_data["debug_verification_token"] = verification_token

    return {
        "success": True,
        "message": "User registered successfully",
        "data": response_data,
    }


@router.get("/verify-email")
def verify_email(
    token: str,
    db: Session = Depends(get_db),
):
    payload = decode_email_verification_token(token)
    try:
        user_id = uuid.UUID(payload.get("sub"))
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid verification token payload")

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    if user.email != payload.get("email"):
        raise HTTPException(status_code=400, detail="Verification token mismatch")

    user.email_verified = True
    db.commit()

    return {
        "success": True,
        "message": "Email verified successfully",
        "data": {
            "user_id": str(user.id),
            "email_verified": True,
        },
    }


# ================= TOGGLE AVAILABILITY =================
@router.put("/toggle-availability")
def toggle_availability(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.available = not current_user.available
    db.commit()

    return {
        "success": True,
        "message": "Availability updated",
        "data": {
            "available": current_user.available,
        },
    }


@router.get("/me")
def get_me(current_user=Depends(get_current_user)):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role,
        "blood_group": current_user.blood_group,
        "available": current_user.available,
        "phone": current_user.phone,
        "phone_verified": current_user.phone_verified,
        "email_verified": current_user.email_verified,
        "is_verified_donor": current_user.is_verified_donor,
        "verification_status": current_user.verification_status,
    }


class UpdateProfile(BaseModel):
    phone: str | None = None
    donation_type: str | None = None
    available: bool | None = None
    role: str | None = None
    latitude: float | None = None
    longitude: float | None = None


@router.put("/users/me")
def update_profile(
    data: UpdateProfile,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if data.phone is not None:
        current_user.phone = data.phone
        current_user.phone_verified = False

    if data.donation_type is not None:
        normalized = data.donation_type.lower()
        if normalized not in ALLOWED_DONATION_TYPES:
            raise HTTPException(status_code=400, detail="Invalid donation type")
        current_user.donation_type = normalized

    if data.available is not None:
        current_user.available = data.available

    if data.role is not None:
        role_normalized = data.role.lower()
        if role_normalized not in ALLOWED_ROLES:
            raise HTTPException(status_code=400, detail="Invalid role")
        if current_user.role != role_normalized:
            current_user.role = role_normalized
            if role_normalized == "donor":
                current_user.verification_status = "pending"
                current_user.is_verified_donor = False

    if data.latitude is not None and data.longitude is not None:
        current_user.location = from_shape(Point(data.longitude, data.latitude), srid=4326)

    db.commit()
    db.refresh(current_user)

    return {
        "success": True,
        "message": "Profile updated successfully",
        "data": {
            "id": str(current_user.id),
        },
    }


@router.get("/donation-history")
def get_donation_history(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if current_user.role == "seeker":
        history = db.query(models.DonationRequest).filter(
            models.DonationRequest.seeker_id == current_user.id
        ).all()
    else:
        history = db.query(models.DonationRequest).filter(
            models.DonationRequest.donor_id == current_user.id
        ).all()

    return [
        {
            "id": req.id,
            "organ_type": req.organ_type,
            "status": req.status,
            "created_at": req.created_at,
        }
        for req in history
    ]
