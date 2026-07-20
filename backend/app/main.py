# main.py — ponto de entrada do FastAPI
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from .config import ALLOWED_ORIGINS
from .database import Base, engine
from .rate_limit import limiter
from .routers import auth, history, meta, predict

# Cria as tabelas no banco se ainda não existirem
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="NNAdsorption API",
    description="Backend para predição de comportamento de colunas de adsorção em leito fixo.",
    version="1.0.0",
)

# Rate limit: 60 req/min por IP (login/register têm limite próprio de 5/min)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)


# CSP padrão da API: só carrega recursos do próprio domínio.
_CSP_PADRAO = "default-src 'self'"

# CSP só pra /docs e /redoc: essas páginas do Swagger/Redoc carregam
# CSS/JS de CDN externo, então precisam de uma política mais aberta.
# O resto da API (as rotas que realmente importam proteger) continua
# com o default-src 'self' restrito acima.
_CSP_DOCS = (
    "default-src 'self'; "
    # 'unsafe-inline' no script-src é necessário porque o HTML do Swagger
    # inicializa a UI com um <script> inline (window.ui = SwaggerUIBundle(...))
    "script-src 'self' 'unsafe-inline' cdn.jsdelivr.net; "
    "style-src 'self' cdn.jsdelivr.net fonts.googleapis.com 'unsafe-inline'; "
    "img-src 'self' fastapi.tiangolo.com data:; "
    "font-src 'self' fonts.gstatic.com; "
    "worker-src 'self' blob:"
)


@app.middleware("http")
async def adicionar_headers_de_seguranca(request: Request, call_next):
    """Adiciona headers de segurança em toda resposta da API."""
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"

    eh_pagina_de_docs = request.url.path.startswith(("/docs", "/redoc"))
    response.headers["Content-Security-Policy"] = _CSP_DOCS if eh_pagina_de_docs else _CSP_PADRAO
    return response


# CORS: origens do .env + qualquer porta de localhost (nunca "*").
# O regex é necessário porque o `flutter run` sorteia uma porta nova
# a cada execução; em produção só valem as origens do .env.
# Adicionado por último pra ficar por fora dos outros middlewares
# (assim as respostas de erro também recebem os headers de CORS).
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_origin_regex=r"http://localhost:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registra os roteadores
app.include_router(auth.router)
app.include_router(predict.router)
app.include_router(history.router)
app.include_router(meta.router)


@app.get("/health")
def health():
    """Verifica se o servidor está rodando."""
    return {"ok": True}
