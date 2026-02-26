from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from geoalchemy2.shape import from_shape
from shapely.geometry import Point

from ..database import get_db
from .. import models
from ..auth import create_access_token, get_current_user

router = APIRouter()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

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

    user = db.query(models.User).filter(
        models.User.email == email
    ).first()

    if not user:
        raise HTTPException(status_code=400, detail="Invalid email")

    if not pwd_context.verify(password, user.password):
        raise HTTPException(status_code=400, detail="Invalid password")

    access_token = create_access_token(
        data={"sub": str(user.id)}
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


# ================= REGISTER =================
 
ALLOWED_DONATION_TYPES = {
    "blood", "kidney", "liver", "heart",
    "cornea", "bone_marrow"
}

@router.post("/register")
def register_user(
    name: str,
    email: str,
    password: str,
    role: str,
    donation_type: str,
    blood_group: str = None,
    phone: str = None,   # ✅ ADD THIS
    latitude: float = None,
    longitude: float = None,
    db: Session = Depends(get_db)
):


    if donation_type.lower() not in ALLOWED_DONATION_TYPES:
        raise HTTPException(status_code=400, detail="Invalid donation type")

    if role == "donor" and not donation_type:
        raise HTTPException(status_code=400, detail="Donation type required")

    # Prevent duplicate email
    existing_user = db.query(models.User).filter(
        models.User.email == email
    ).first()

    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    hashed_pw = pwd_context.hash(password)

    location_point = None
    if latitude and longitude:
        location_point = from_shape(Point(longitude, latitude), srid=4326)

    user = models.User(
        name=name,
        email=email,
        password=hashed_pw,
        role=role,
        blood_group=blood_group,
        donation_type=donation_type.lower(),
        phone=phone,   # ✅ ADD THIS
        location=location_point,
        available=True
    )  


    db.add(user)
    db.commit()
    db.refresh(user)

    return {"message": "User registered successfully"}


     

# ================= TOGGLE AVAILABILITY =================
@router.put("/toggle-availability")
def toggle_availability(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    current_user.available = not current_user.available
    db.commit()

    return {
        "message": "Availability updated",
        "available": current_user.available
    }
@router.get("/me")
def get_me(current_user = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "name": current_user.name,
        "email": current_user.email,
        "role": current_user.role,
        "blood_group": current_user.blood_group,
        "available": current_user.available,
        "phone": current_user.phone   # 👈 ADD THIS
    }

from pydantic import BaseModel

class UpdateProfile(BaseModel):
    phone: str | None = None
    donation_type: str | None = None
    available: bool | None = None
    role: str | None = None


@router.put("/users/me")
def update_profile(
    data: UpdateProfile,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    if data.phone is not None:
        current_user.phone = data.phone

    if data.donation_type is not None:
        current_user.donation_type = data.donation_type.lower()

    if data.available is not None:
        current_user.available = data.available

    if data.role is not None:
        if data.role not in ["donor", "seeker"]:
            raise HTTPException(status_code=400, detail="Invalid role")
        current_user.role = data.role

    db.commit()
    db.refresh(current_user)

    return {"message": "Profile updated successfully"}
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


