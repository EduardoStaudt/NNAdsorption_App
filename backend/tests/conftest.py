# conftest.py — configuração compartilhada entre todos os testes
import numpy as np
import pytest
from fastapi.testclient import TestClient
from nnadsorption import contract
from nnadsorption.predictor import AdsorptionPredictor

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


# --- Modo lote ---

def entrada_lote(**troca):
    """Uma linha válida no formato do contrato (31 params, nomes e unidades SI)."""
    p = {}
    for c in range(2):
        p.update({
            "c%d_qm_ref" % c: 8.0, "c%d_k2" % c: -0.02, "c%d_B_ref" % c: 0.1,
            "c%d_k4" % c: 1500.0, "c%d_n_ref" % c: 1.0, "c%d_k6" % c: 0.0,
            "c%d_kL" % c: 0.1, "c%d_dH" % c: 25000.0, "c%d_Cpg" % c: 29.0,
        })
    p.update({
        "eb": 0.4, "rho_b": 650.0, "Cps": 1000.0, "vs": 0.01, "Tin": 298.0,
        "P": 1.0e6, "L": 0.5, "Dt": 0.035, "hw": 50.0, "lam": 0.4,
        "dp": 2.0e-3, "Dm": 1.0e-5, "y0": 0.5,
    })
    p.update(troca)
    return p


class _RedeFake:
    """Rede de mentira: devolve zeros do tamanho certo e conta as chamadas.

    Serve pra testar a cascata inteira (contrato, física, enriquecimento, grade
    de tempo) numa máquina sem os pesos V3 — só os dois `.keras` são falsos.
    """

    def __init__(self, n_saidas):
        self.n_saidas = n_saidas
        self.chamadas = 0
        self.ultimo_n = 0

    def predict(self, z, verbose=0, batch_size=None):
        self.chamadas += 1
        self.ultimo_n = z.shape[0]
        return np.zeros((z.shape[0], self.n_saidas), dtype=np.float64)


@pytest.fixture
def rede_fake(monkeypatch):
    """Troca o predictor real por um com redes falsas e devolve o predictor."""
    n_enriq = 47   # 31 crus + 16 derivados (features.FEATURE_NAMES)
    M = 100
    pred = AdsorptionPredictor()
    pred.m_tempos = _RedeFake(3)
    pred.m_forma = _RedeFake(2 * M)
    pred.meta_tempos = {
        "xmu": np.zeros(n_enriq), "xsd": np.ones(n_enriq),
        "ymu": np.zeros(3), "ysd": np.ones(3),
    }
    pred.meta_forma = {
        "xmu": np.zeros(n_enriq + 4), "xsd": np.ones(n_enriq + 4),
        "ymu": np.zeros(2 * M), "ysd": np.ones(2 * M), "M": M,
    }
    pred._loaded = True

    from app import lote

    monkeypatch.setattr(lote, "get_predictor", lambda: pred)
    return pred
