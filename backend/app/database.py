from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://pragati:123456@localhost/organ_donor"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


# ✅ THE ONLY get_db FUNCTION IN PROJECT
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
