# security.py — hash de senha com bcrypt e JWT para autenticação
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from .config import JWT_EXPIRES_DAYS, JWT_SECRET

# Contexto do passlib para hash bcrypt
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

ALGORITHM = "HS256"


def hash_senha(senha: str) -> str:
    """Transforma a senha em hash bcrypt. NUNCA salvar senha pura."""
    return _pwd_context.hash(senha)


def verificar_senha(senha: str, hash_armazenado: str) -> bool:
    """Verifica se a senha bate com o hash salvo no banco."""
    return _pwd_context.verify(senha, hash_armazenado)


def criar_token(user_id: int) -> str:
    """Cria um token JWT com o id do usuário e expiração configurada."""
    expira = datetime.now(timezone.utc) + timedelta(days=JWT_EXPIRES_DAYS)
    payload = {"sub": str(user_id), "exp": expira}
    return jwt.encode(payload, JWT_SECRET, algorithm=ALGORITHM)


def ler_token(token: str) -> Optional[int]:
    """Decodifica o JWT e retorna o user_id, ou None se inválido/expirado."""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            return None
        return int(user_id)
    except JWTError:
        return None
