# models.py — tabelas do banco de dados (SQLAlchemy ORM)
from datetime import datetime, timezone

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text

from .database import Base


class User(Base):
    """Tabela de usuários."""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    senha_hash = Column(String, nullable=False)
    # Placeholder pra verificação de email — ativo por padrão até integrar Resend/SendGrid
    email_verified = Column(Boolean, default=True)
    criado_em = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))


class Prediction(Base):
    """Tabela de predições feitas pelos usuários."""
    __tablename__ = "predictions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    # Os 22 inputs e todos os outputs ficam serializados em JSON
    inputs_json = Column(Text, nullable=False)
    outputs_json = Column(Text, nullable=False)
    criado_em = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
