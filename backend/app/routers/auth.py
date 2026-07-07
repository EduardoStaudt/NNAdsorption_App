# auth.py — endpoints de autenticação: register, login, me
# TODO: ativar verificação por email (Resend/SendGrid) quando tiver domínio próprio.
#       Plugar aqui no endpoint /auth/verify-email abaixo.
from fastapi import APIRouter, Depends, HTTPException, Request, Response
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import User
from ..rate_limit import LIMITE_AUTH, limiter
from ..schemas import LoginRequest, RegisterRequest, TokenResponse, UserResponse
from ..security import criar_token, hash_senha, verificar_senha

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
@limiter.limit(LIMITE_AUTH)
def register(request: Request, response: Response, body: RegisterRequest, db: Session = Depends(get_db)):
    """Cadastra novo usuário e devolve o token JWT.

    request e response parecem não usados, mas o slowapi precisa
    dos dois na assinatura pra aplicar o rate limit.
    """
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email já cadastrado")

    novo_user = User(email=body.email, senha_hash=hash_senha(body.password))
    db.add(novo_user)
    db.commit()
    db.refresh(novo_user)

    token = criar_token(novo_user.id)
    return TokenResponse(token=token, user=UserResponse.model_validate(novo_user))


@router.post("/login", response_model=TokenResponse)
@limiter.limit(LIMITE_AUTH)
def login(request: Request, response: Response, body: LoginRequest, db: Session = Depends(get_db)):
    """Autentica o usuário e devolve o token JWT.

    request e response parecem não usados, mas o slowapi precisa
    dos dois na assinatura pra aplicar o rate limit.
    """
    user = db.query(User).filter(User.email == body.email).first()
    if user is None or not verificar_senha(body.password, user.senha_hash):
        raise HTTPException(status_code=401, detail="Email ou senha incorretos")

    token = criar_token(user.id)
    return TokenResponse(token=token, user=UserResponse.model_validate(user))


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)):
    """Retorna os dados do usuário autenticado."""
    return UserResponse.model_validate(current_user)


@router.post("/verify-email", status_code=501)
def verify_email():
    """Placeholder — verificação por email ainda não implementada."""
    # TODO: integrar com Resend/SendGrid quando tiver domínio próprio
    raise HTTPException(status_code=501, detail="Verificação de email ainda não implementada")
