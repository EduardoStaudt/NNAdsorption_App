# conftest.py — configuração compartilhada entre todos os testes
import pytest
from fastapi.testclient import TestClient

from app.main import app

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


def _modelo_disponivel() -> bool:
    """Os pesos da rede não estão no repositório (ver artifacts/README.md da lib).

    Numa máquina sem eles a inferência nem carrega, então os testes que passam
    pela rede se marcam como pulados em vez de falharem por um motivo que não é
    do backend.
    """
    # Olha o diretório de artefatos direto: `get_predictor()` constrói sem
    # reclamar e só quebra na primeira inferência, tarde demais pra pular.
    try:
        from pathlib import Path

        import nnadsorption

        artefatos = Path(nnadsorption.__file__).parent / "artifacts"
        return any(artefatos.glob("*.keras"))
    except Exception:
        return False


MODELO_DISPONIVEL = _modelo_disponivel()


@pytest.fixture
def client():
    """Cliente HTTP de teste apontando pro app."""
    return _client


@pytest.fixture
def modelo():
    """Declara que o teste precisa dos pesos da rede pra rodar."""
    if not MODELO_DISPONIVEL:
        pytest.skip("artefatos da lib nnadsorption ausentes nesta máquina")


@pytest.fixture
def inputs_validos():
    """Cópia dos inputs válidos (cada teste pode alterar sem afetar os outros)."""
    return dict(INPUTS_VALIDOS)


@pytest.fixture(autouse=True)
def zerar_rate_limit():
    """Zera o contador do rate limit antes de cada teste.

    Sem isso, uma bateria de requisições estouraria o limite por minuto e
    passaria a devolver 429 no meio da suíte.
    """
    app.state.limiter.reset()
