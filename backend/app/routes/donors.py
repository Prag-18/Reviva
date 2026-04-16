from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from ..database import get_db

router = APIRouter()

ALLOWED_ORGAN_TYPES = {
    "blood",
    "kidney",
    "liver",
    "heart",
    "cornea",
    "bone_marrow"
}


@router.get("/nearby-donors")
def get_nearby_donors(
    latitude: float,
    longitude: float,
    organ_type: str,
    radius_km: float = 5,
    db: Session = Depends(get_db)
):
    organ_type_normalized = organ_type.lower().strip()

    # Validate organ type
    if organ_type_normalized not in ALLOWED_ORGAN_TYPES:
        raise HTTPException(status_code=400, detail="Invalid organ type")

    # Validate radius
    if radius_km <= 0:
        raise HTTPException(status_code=400, detail="Radius must be greater than 0")

    query = text("""
    SELECT
        id,
        name,
        role,
        blood_group,
        donation_type,
        available,
        ST_Y(location::geometry) AS latitude,
        ST_X(location::geometry) AS longitude,
        ROUND(
            ST_Distance(
                location,
                ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
            )::numeric / 1000,
            2
        ) as distance_km
    FROM users
    WHERE role = 'donor'
      AND donation_type = :organ_type
      AND available = TRUE
      AND is_verified_donor = TRUE
      AND verification_status = 'approved'
      AND ST_DWithin(
            location,
            ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
            :radius
        )
    ORDER BY distance_km ASC
    LIMIT 50
    """)

    result = db.execute(query, {
        "lon": longitude,
        "lat": latitude,
        "radius": radius_km * 1000,  # convert km to meters
        "organ_type": organ_type_normalized
    })

    donors = result.fetchall()

    return [dict(row._mapping) for row in donors]
