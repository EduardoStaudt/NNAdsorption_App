# deps.py — dependências compartilhadas do FastAPI (injeção de dependência)
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .database import get_db
from .models import User
from .security import ler_token

bearer = HTTPBearer()


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    """Valida o JWT e retorna o usuário logado. Usado por qualquer rota protegida."""
    return _buscar_user(credentials.credentials, db)


def get_current_user_query_or_header(
    request: Request,
    db: Session = Depends(get_db),
) -> User:
    """Aceita JWT tanto do header Authorization quanto do query param ?token=.

    Necessário para endpoints de download direto no browser (que não enviam headers).
    """
    token: Optional[str] = None

    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        token = auth_header[7:]
    else:
        token = request.query_params.get("token")

    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token ausente")

    return _buscar_user(token, db)


def _buscar_user(token: str, db: Session) -> User:
    """Lógica comum: valida o token e retorna o usuário."""
    user_id = ler_token(token)
    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido ou expirado")

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuário não encontrado")
    return user
