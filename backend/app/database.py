# database.py — cria a engine do SQLAlchemy e uma fábrica de sessões
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker

from .config import DATABASE_URL

# connect_args é necessário pra SQLite não ter problemas com threads
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})

# Fábrica de sessões: cada requisição abre uma sessão e fecha ao terminar
SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)

# Base das classes de modelo ORM
Base = declarative_base()


def get_db():
    """Dependência do FastAPI: abre a sessão e garante que ela fecha."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
