# schemas_binario.py — contrato de validação do futuro modelo binário (2 componentes)
# Esqueleto pronto para quando o modelo existir: não há endpoint nem rota registrada.
import math
from typing import Dict, List

from pydantic import BaseModel, field_validator


# --- Predict binário ---

# Faixas físicas plausíveis de cada input (min, max), ambos inclusivos.
# Campos de isoterma/cinética existem por componente, com sufixo _1 e _2.
FAIXAS_POR_COMPONENTE = {
    "qm_ref": (1.0, 15.0),
    "k2": (-0.1, 0.0),
    "Bref": (1e-4, 1.0),
    "k4": (0.0, 3200.0),
    "nref": (0.5, 1.5),
    "k6": (-2200.0, 2200.0),
    "kL": (0.01, 1.0),
    "dH": (5.0, 50.0),
}

# Monta as faixas dos 16 campos por componente (_1 e _2) a partir do padrão acima.
FAIXAS = {
    f"{nome}{sufixo}": faixa
    for nome, faixa in FAIXAS_POR_COMPONENTE.items()
    for sufixo in ("_1", "_2")
}

# Campos únicos (leito, operação/geometria e composição).
FAIXAS.update({
    # Leito
    "eps_b": (0.30, 0.50),
    "rho_b": (400.0, 900.0),
    "cp_s": (800.0, 1200.0),
    # Operação / geometria
    "vs": (0.001, 0.05),
    "T_in": (288.0, 323.0),
    "P": (0.1, 3.0),
    "L": (0.3, 1.5),
    "hw": (20.0, 100.0),
    "lambda_ax": (0.1, 0.8),
    "dp": (0.5, 5.0),
    "Dm": (5e-6, 3e-5),
    # Composição
    "y0": (0.20, 0.75),
})


class PredictBinarioRequest(BaseModel):
    # Dicionário com os 28 inputs do modelo binário.
    inputs: Dict[str, float]

    @field_validator("inputs")
    @classmethod
    def faixas_fisicas(cls, inputs):
        """Garante que cada valor é finito e está dentro da faixa física do campo."""
        for nome, valor in inputs.items():
            if not math.isfinite(valor):
                raise ValueError(f"{nome} deve ser um número finito")
            faixa = FAIXAS.get(nome)
            if faixa is not None:
                minimo, maximo = faixa
                if not (minimo <= valor <= maximo):
                    raise ValueError(f"{nome} deve estar entre {minimo} e {maximo}")

        return inputs


class PredictBinarioResponse(BaseModel):
    t_breakthrough: float
    t_saturacao: float
    t_final_janela: float
    grau_saturacao: float
    t_points: List[float]
    y0_points: List[float]
    y1_points: List[float]
    T_out_points: List[float]
