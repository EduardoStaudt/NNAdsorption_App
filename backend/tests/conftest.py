# conftest.py — configuração compartilhada entre todos os testes
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database import Base, get_db
from app.main import app

# StaticPool força todos os acessos a usar a mesma conexão em memória
# (sem isso, cada sessão abriria um banco em memória diferente e vazio)
engine_test = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
SessionTest = sessionmaker(bind=engine_test, autocommit=False, autoflush=False)


def override_get_db():
    """Substituição da dependência do banco — usa banco em memória."""
    db = SessionTest()
    try:
        yield db
    finally:
        db.close()


# Cria as tabelas no banco de teste e substitui a dependência
Base.metadata.create_all(bind=engine_test)
app.dependency_overrides[get_db] = override_get_db

_client = TestClient(app)

# Inputs válidos do modelo (22 campos)
INPUTS_VALIDOS = {
    "L": 0.5,
    "Nz": 50.0,
    "eps": 0.4,
    "rho_B": 500.0,
    "u": 0.01,
    "D_ax": 1e-5,
    "kL": 0.05,
    "qmax": 10.0,
    "b": 0.1,
    "n": 1.0,
    "lam_z": 0.1,
    "rho_g": 1.2,
    "cp_g": 1000.0,
    "cp_s": 800.0,
    "D_col": 0.05,
    "h_w": 10.0,
    "T_wall": 298.0,
    "dH": -20000.0,
    "dt": 1.0,
    "t_end": 100.0,
    "C_in": 0.01,
    "T_in": 298.0,
}


@pytest.fixture
def client():
    """Cliente HTTP de teste apontando pro app com banco em memória."""
    return _client


@pytest.fixture
def inputs_validos():
    """Cópia dos inputs válidos (cada teste pode alterar sem afetar os outros)."""
    return dict(INPUTS_VALIDOS)


@pytest.fixture(autouse=True)
def zerar_rate_limit():
    """Zera o contador do rate limit antes de cada teste.

    Sem isso, os vários register/login dos testes estourariam
    o limite de 5 requisições por minuto e retornariam 429.
    """
    app.state.limiter.reset()
