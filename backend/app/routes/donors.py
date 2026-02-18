from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from ..database import get_db

router = APIRouter()


@router.get("/nearby-donors")
def get_nearby_donors(
    latitude: float,
    longitude: float,
    radius_km: float,
    db: Session = Depends(get_db)
):

    query = text("""
    SELECT 
        id,
        name,
        role,
        blood_group,available,
        ST_AsText(location) as location,
        ROUND(
            ST_Distance(
                location,
                ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography
            )::numeric / 1000,
            2
        ) as distance_km
    FROM users
    WHERE role = 'donor'
    AND ST_DWithin(
        location,
        ST_SetSRID(ST_MakePoint(:lon, :lat), 4326)::geography,
        :radius
    )
    AND available = TRUE

""")


    result = db.execute(query, {
        "lon": longitude,
        "lat": latitude,
        "radius": radius_km * 1000
    })

    donors = result.fetchall()

    return [dict(row._mapping) for row in donors]
