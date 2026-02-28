import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_admin
from ..database import get_db
from ..services.audit import log_audit_event

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/pending-donors")
def get_pending_donors(
    current_admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    donors = (
        db.query(models.User)
        .filter(
            models.User.role == "donor",
            models.User.verification_status == "pending",
        )
        .order_by(models.User.id.asc())
        .all()
    )

    items = [
        {
            "id": str(user.id),
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "blood_group": user.blood_group,
            "donation_type": user.donation_type,
            "verification_status": user.verification_status,
        }
        for user in donors
    ]

    return {
        "success": True,
        "message": "Pending donors fetched",
        "data": items,
    }


@router.put("/approve-donor/{user_id}")
def approve_donor(
    user_id: uuid.UUID,
    payload: schemas.AdminDonorDecisionRequest,
    current_admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    donor = (
        db.query(models.User)
        .filter(models.User.id == user_id, models.User.role == "donor")
        .first()
    )
    if not donor:
        raise HTTPException(status_code=404, detail="Donor not found")

    donor.is_verified_donor = True
    donor.verification_status = "approved"
    db.commit()

    log_audit_event(
        db,
        user_id=current_admin.id,
        action_type="donor_approval",
        metadata={
            "donor_id": str(donor.id),
            "decision": "approved",
            "reason": payload.reason,
        },
    )

    return {
        "success": True,
        "message": "Donor approved successfully",
        "data": {
            "donor_id": str(donor.id),
            "verification_status": donor.verification_status,
            "is_verified_donor": donor.is_verified_donor,
        },
    }


@router.put("/reject-donor/{user_id}")
def reject_donor(
    user_id: uuid.UUID,
    payload: schemas.AdminDonorDecisionRequest,
    current_admin: models.User = Depends(get_current_admin),
    db: Session = Depends(get_db),
):
    donor = (
        db.query(models.User)
        .filter(models.User.id == user_id, models.User.role == "donor")
        .first()
    )
    if not donor:
        raise HTTPException(status_code=404, detail="Donor not found")

    donor.is_verified_donor = False
    donor.verification_status = "rejected"
    db.commit()

    log_audit_event(
        db,
        user_id=current_admin.id,
        action_type="donor_approval",
        metadata={
            "donor_id": str(donor.id),
            "decision": "rejected",
            "reason": payload.reason,
        },
    )

    return {
        "success": True,
        "message": "Donor rejected successfully",
        "data": {
            "donor_id": str(donor.id),
            "verification_status": donor.verification_status,
            "is_verified_donor": donor.is_verified_donor,
        },
    }
