from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload
import uuid

from .. import models
from ..auth import get_current_user
from ..database import get_db
from ..services.audit import log_audit_event
from .chat import chat_manager

router = APIRouter()

ALLOWED_URGENCY_LEVELS = {"low", "medium", "high", "critical"}

PENDING_STATUS = "pending"
ACCEPTED_STATUS = "accepted"
REJECTED_STATUS = "rejected"


# ================= NOTIFY DONOR =================
async def _notify_user(user_id: uuid.UUID, message: str) -> None:
    await chat_manager.send_to_user(
        str(user_id),
        {"type": message},
    )


# ================= CREATE REQUEST =================
@router.post("/create-request")
async def create_request(
    donor_id: uuid.UUID,
    urgency: str,
    organ_type: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    urgency_normalized = urgency.lower().strip()
    organ_type_normalized = organ_type.lower().strip()

    if urgency_normalized not in ALLOWED_URGENCY_LEVELS:
        raise HTTPException(status_code=400, detail="Invalid urgency level")

    if current_user.role != "seeker":
        raise HTTPException(status_code=403, detail="Only seekers can create requests")

    if current_user.id == donor_id:
        raise HTTPException(status_code=400, detail="Cannot create a request to yourself")

    donor = (
        db.query(models.User)
        .filter(models.User.id == donor_id, models.User.role == "donor")
        .first()
    )

    if not donor:
        raise HTTPException(status_code=404, detail="Donor not found")

    if donor.verification_status != "approved" or not donor.is_verified_donor:
        raise HTTPException(status_code=400, detail="Donor is not verified yet")

    if not donor.available:
        raise HTTPException(status_code=400, detail="Donor is currently unavailable")

    if donor.donation_type != organ_type_normalized:
        raise HTTPException(
            status_code=400,
            detail="Donor does not support this organ type"
        )

    existing_pending_request = (
        db.query(models.DonationRequest)
        .filter(
            models.DonationRequest.donor_id == donor_id,
            models.DonationRequest.seeker_id == current_user.id,
            models.DonationRequest.status == PENDING_STATUS,
        )
        .first()
    )

    if existing_pending_request:
        raise HTTPException(
            status_code=409,
            detail="A pending request already exists for this donor",
        )

    new_request = models.DonationRequest(
        donor_id=donor_id,
        seeker_id=current_user.id,
        urgency=urgency_normalized,
        organ_type=organ_type_normalized,
        status=PENDING_STATUS,
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    log_audit_event(
        db,
        user_id=current_user.id,
        action_type="request_creation",
        metadata={
            "request_id": str(new_request.id),
            "donor_id": str(donor_id),
            "organ_type": organ_type_normalized,
            "urgency": urgency_normalized,
        },
    )

    await _notify_user(donor_id, "new_request")

    return {
        "message": "Request sent successfully",
        "urgency": urgency_normalized,
        "organ_type": organ_type_normalized,
        "request_id": new_request.id,
    }


# ================= ACCEPT REQUEST =================
@router.put("/accept-request/{request_id}")
async def accept_request(
    request_id: uuid.UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    if current_user.role != "donor":
        raise HTTPException(status_code=403, detail="Only donors can accept requests")

    donation_request = (
        db.query(models.DonationRequest)
        .filter(models.DonationRequest.id == request_id)
        .first()
    )

    if not donation_request:
        raise HTTPException(status_code=404, detail="Request not found")

    if donation_request.donor_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed to accept this request")

    if donation_request.status != PENDING_STATUS:
        raise HTTPException(status_code=409, detail="Only pending requests can be accepted")

    donation_request.status = ACCEPTED_STATUS
    db.commit()
    await _notify_user(donation_request.seeker_id, "request_accepted")
    await _notify_user(current_user.id, "request_updated")

    return {"message": "Request accepted"}


# ================= REJECT REQUEST =================
@router.put("/reject-request/{request_id}")
async def reject_request(
    request_id: uuid.UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):

    if current_user.role != "donor":
        raise HTTPException(status_code=403, detail="Only donors can reject requests")

    donation_request = (
        db.query(models.DonationRequest)
        .filter(models.DonationRequest.id == request_id)
        .first()
    )

    if not donation_request:
        raise HTTPException(status_code=404, detail="Request not found")

    if donation_request.donor_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed to reject this request")

    if donation_request.status != PENDING_STATUS:
        raise HTTPException(status_code=409, detail="Only pending requests can be rejected")

    donation_request.status = REJECTED_STATUS
    db.commit()
    await _notify_user(donation_request.seeker_id, "request_rejected")
    await _notify_user(current_user.id, "request_updated")

    return {"message": "Request rejected"}


# ================= GET MY REQUESTS =================
@router.get("/my-requests/{user_id}")
def get_my_requests(
    user_id: uuid.UUID,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Not allowed to view other users' requests",
        )

    requests = (
        db.query(models.DonationRequest)
        .options(
            joinedload(models.DonationRequest.seeker),
            joinedload(models.DonationRequest.donor),
        )
        .filter(
            (models.DonationRequest.donor_id == user_id)
            | (models.DonationRequest.seeker_id == user_id)
        )
        .order_by(models.DonationRequest.id.desc())
        .all()
    )

    return [
        {
            "id": request_item.id,
            "urgency": request_item.urgency,
            "status": request_item.status,
            "organ_type": request_item.organ_type,
            "donor_id": request_item.donor_id,
            "seeker_id": request_item.seeker_id,
            "seeker_name": request_item.seeker.name if request_item.seeker else None,
            "seeker_blood_group": request_item.seeker.blood_group if request_item.seeker else None,
            "seeker_email": request_item.seeker.email if request_item.seeker else None,
            "donor_name": request_item.donor.name if request_item.donor else None,
            "donor_blood_group": request_item.donor.blood_group if request_item.donor else None,
            "created_at": request_item.created_at,
        }
        for request_item in requests
    ]
