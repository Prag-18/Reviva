from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session, joinedload
import uuid

from .. import models
from ..auth import get_current_user
from ..database import get_db

router = APIRouter()

ALLOWED_URGENCY_LEVELS = {"low", "medium", "high", "critical"}
PENDING_STATUS = "pending"
ACCEPTED_STATUS = "accepted"
REJECTED_STATUS = "rejected"


async def _notify_donor_new_request(app_request: Request, donor_id: uuid.UUID) -> None:
    active_connections = getattr(app_request.app.state, "active_connections", [])
    for uid, connection in active_connections:
        if uid == str(donor_id):
            await connection.send_text("new_request")


@router.post("/create-request")
async def create_request(
    donor_id: uuid.UUID,
    urgency: str,
    request: Request,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    urgency_normalized = urgency.lower().strip()
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

    if not donor.available:
        raise HTTPException(status_code=400, detail="Donor is currently unavailable")

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
        status=PENDING_STATUS,
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    await _notify_donor_new_request(request, donor_id)

    return {
        "message": "Request sent successfully",
        "urgency": urgency_normalized,
        "request_id": new_request.id,
    }


@router.put("/accept-request/{request_id}")
def accept_request(
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

    return {"message": "Request accepted"}


@router.put("/reject-request/{request_id}")
def reject_request(
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

    return {"message": "Request rejected"}


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
        .all()
    )

    return [
        {
            "id": request_item.id,
            "urgency": request_item.urgency,
            "status": request_item.status,
            "donor_id": request_item.donor_id,
            "seeker_id": request_item.seeker_id,
            "seeker_name": request_item.seeker.name,
            "seeker_blood_group": request_item.seeker.blood_group,
            "seeker_email": request_item.seeker.email,
            "donor_name": request_item.donor.name,
            "donor_blood_group": request_item.donor.blood_group,
        }
        for request_item in requests
    ]
