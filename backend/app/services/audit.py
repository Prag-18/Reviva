import uuid
from datetime import datetime

from sqlalchemy.orm import Session

from .. import models


def log_audit_event(
    db: Session,
    *,
    user_id: uuid.UUID,
    action_type: str,
    metadata: dict | None = None,
) -> models.AuditLog:
    entry = models.AuditLog(
        user_id=user_id,
        action_type=action_type,
        metadata_json=metadata or {},
        timestamp=datetime.utcnow(),
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry
