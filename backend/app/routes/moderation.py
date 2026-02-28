from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from .. import models, schemas
from ..auth import get_current_user
from ..database import get_db
from ..services.audit import log_audit_event

router = APIRouter(tags=["moderation"])


@router.post("/report-user")
def report_user(
    payload: schemas.ReportUserRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.reported_user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot report yourself")

    target = db.query(models.User).filter(models.User.id == payload.reported_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Reported user not found")

    report = models.Report(
        reporter_id=current_user.id,
        reported_user_id=payload.reported_user_id,
        reason=payload.reason.strip(),
    )
    db.add(report)

    block_created = False
    if payload.block_user:
        existing_block = (
            db.query(models.UserBlock)
            .filter(
                models.UserBlock.blocker_id == current_user.id,
                models.UserBlock.blocked_user_id == payload.reported_user_id,
            )
            .first()
        )
        if not existing_block:
            db.add(
                models.UserBlock(
                    blocker_id=current_user.id,
                    blocked_user_id=payload.reported_user_id,
                )
            )
            block_created = True

    db.commit()
    db.refresh(report)

    log_audit_event(
        db,
        user_id=current_user.id,
        action_type="report_submission",
        metadata={
            "report_id": str(report.id),
            "reported_user_id": str(payload.reported_user_id),
            "reason": payload.reason,
            "block_user": payload.block_user,
        },
    )

    return {
        "success": True,
        "message": "User reported successfully",
        "data": {
            "report_id": str(report.id),
            "blocked": payload.block_user and block_created,
        },
    }


@router.post("/block-user")
def block_user(
    payload: schemas.BlockUserRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if payload.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot block yourself")

    target = db.query(models.User).filter(models.User.id == payload.user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    existing_block = (
        db.query(models.UserBlock)
        .filter(
            models.UserBlock.blocker_id == current_user.id,
            models.UserBlock.blocked_user_id == payload.user_id,
        )
        .first()
    )

    if existing_block:
        return {
            "success": True,
            "message": "User already blocked",
            "data": {
                "blocked_user_id": str(payload.user_id),
            },
        }

    block = models.UserBlock(
        blocker_id=current_user.id,
        blocked_user_id=payload.user_id,
    )
    db.add(block)
    db.commit()

    return {
        "success": True,
        "message": "User blocked successfully",
        "data": {
            "blocked_user_id": str(payload.user_id),
        },
    }
