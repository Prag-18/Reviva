import uuid
from sqlalchemy import Column, String, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from geoalchemy2 import Geography
from .database import Base


# ==========================
# USER MODEL
# ==========================

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password = Column(String, nullable=False)

    role = Column(String, nullable=False)  # donor / seeker
    blood_group = Column(String, nullable=True)  # nullable for organ-only donors

    donation_type = Column(String, nullable=False)  
    # blood / kidney / liver / heart / cornea / bone_marrow

    verified = Column(Boolean, default=False)
    available = Column(Boolean, default=True)

    location = Column(Geography(geometry_type="POINT", srid=4326))

    # Relationships
    sent_requests = relationship(
        "DonationRequest",
        foreign_keys="DonationRequest.seeker_id",
        back_populates="seeker",
        cascade="all, delete"
    )

    received_requests = relationship(
        "DonationRequest",
        foreign_keys="DonationRequest.donor_id",
        back_populates="donor",
        cascade="all, delete"
    )


# ==========================
# DONATION REQUEST MODEL
# ==========================

class DonationRequest(Base):
    __tablename__ = "donation_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    donor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    seeker_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False
    )

    organ_type = Column(String, nullable=False)
    # blood / kidney / liver / etc.

    urgency = Column(String, default="medium")
    status = Column(String, default="pending")

    # Relationships
    donor = relationship(
        "User",
        foreign_keys=[donor_id],
        back_populates="received_requests"
    )

    seeker = relationship(
        "User",
        foreign_keys=[seeker_id],
        back_populates="sent_requests"
    )
