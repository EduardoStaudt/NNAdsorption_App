# schemas.py — modelos Pydantic para validação de request e response
import math
from typing import Any, Dict, List

from pydantic import BaseModel, field_validator


# --- Predict ---

# Faixas físicas plausíveis dos inputs do modelo:
# campos que devem ser maiores que zero (comprimento, densidade, temperatura...)
CAMPOS_POSITIVOS = {
    "L", "Nz", "rho_B", "u", "qmax", "rho_g", "cp_g",
    "cp_s", "D_col", "T_wall", "dt", "t_end", "T_in",
}
# campos que podem ser zero, mas não negativos (coeficientes, concentração...)
CAMPOS_NAO_NEGATIVOS = {"D_ax", "kL", "b", "n", "lam_z", "h_w", "C_in"}


class PredictRequest(BaseModel):
    # Dicionário com os 22 inputs do modelo
    inputs: Dict[str, float]

    @field_validator("inputs")
    @classmethod
    def faixas_fisicas(cls, inputs):
        """Garante que os valores estão dentro de faixas fisicamente plausíveis."""
        for nome, valor in inputs.items():
            if not math.isfinite(valor):
                raise ValueError(f"{nome} deve ser um número finito")
            if nome in CAMPOS_POSITIVOS and valor <= 0:
                raise ValueError(f"{nome} deve ser maior que zero")
            if nome in CAMPOS_NAO_NEGATIVOS and valor < 0:
                raise ValueError(f"{nome} não pode ser negativo")

        # Porosidade do leito: precisa estar entre 0 e 1 (exclusivo)
        eps = inputs.get("eps")
        if eps is not None and not (0 < eps < 1):
            raise ValueError("eps deve estar entre 0 e 1 (exclusivo)")

        return inputs


class PredictResponse(BaseModel):
    result: Dict[str, Any]


# --- Export ---

class ExportRequest(BaseModel):
    """Resultado que o cliente guardou e quer de volta como planilha."""

    result: Dict[str, Any]
    format: str = "csv"
    nome: str = "predicao"


# --- Meta ---

class MetaResponse(BaseModel):
    input_cols: List[str]
    final_cols: List[str]
    block_size: int
