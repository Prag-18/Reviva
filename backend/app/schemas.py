from __future__ import annotations

import uuid
from typing import Any, Literal

from pydantic import BaseModel, Field


class APIResponse(BaseModel):
    success: bool = True
    message: str
    data: Any | None = None


class SendOTPRequest(BaseModel):
    phone: str | None = Field(default=None, min_length=6, max_length=32)


class VerifyOTPRequest(BaseModel):
    otp_code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class ReportUserRequest(BaseModel):
    reported_user_id: uuid.UUID
    reason: str = Field(min_length=5, max_length=1000)
    block_user: bool = False


class BlockUserRequest(BaseModel):
    user_id: uuid.UUID


class AdminDonorDecisionRequest(BaseModel):
    reason: str | None = Field(default=None, max_length=1000)


class PendingDonorItem(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    phone: str | None = None
    blood_group: str | None = None
    donation_type: str | None = None
    verification_status: Literal["pending", "approved", "rejected"]


class PendingDonorsResponse(APIResponse):
    data: list[PendingDonorItem]


class VerifyEmailResponse(APIResponse):
    data: dict[str, Any] | None = None
