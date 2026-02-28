# Alembic Migration Plan

1. Install and configure Alembic in `backend/`.
2. Set `sqlalchemy.url` in `alembic.ini` to the same `DATABASE_URL` used by app runtime.
3. Set `target_metadata = app.models.Base.metadata` in `alembic/env.py`.
4. Apply migration script:
   - `alembic upgrade 20260228_01_trust_layer`
5. For future changes:
   - `alembic revision --autogenerate -m "..."`
   - review generated script
   - `alembic upgrade head`

## Included Example

- `alembic/versions/20260228_01_trust_layer.py`
  - Adds user verification columns
  - Adds message status column
  - Creates `otp_verifications`, `reports`, `user_blocks`, `audit_logs`
  - Adds indexes and constraints
