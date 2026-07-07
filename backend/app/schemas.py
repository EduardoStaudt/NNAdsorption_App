# schemas.py — modelos Pydantic para validação de request e response
import math
import re
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, EmailStr, field_validator


# --- Auth ---

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str

    @field_validator("password")
    @classmethod
    def senha_forte(cls, v):
        if len(v) < 8:
            raise ValueError("Senha deve ter pelo menos 8 caracteres")
        if not re.search(r"[A-Za-z]", v) or not re.search(r"\d", v):
            raise ValueError("Senha deve ter pelo menos 1 letra e 1 número")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    email_verified: bool
    criado_em: datetime

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    token: str
    user: UserResponse


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
    prediction_id: int
    result: Dict[str, Any]


# --- History ---

class PredictionSummary(BaseModel):
    id: int
    criado_em: datetime
    # Mostra só os escalares finais no resumo da lista
    C_out_final: Optional[float] = None
    q_out_final: Optional[float] = None
    T_out_final: Optional[float] = None
    N_ads_final: Optional[float] = None
    Qtot_final: Optional[float] = None


class PredictionDetail(BaseModel):
    id: int
    criado_em: datetime
    inputs: Dict[str, Any]
    outputs: Dict[str, Any]


# --- Meta ---

class MetaResponse(BaseModel):
    input_cols: List[str]
    final_cols: List[str]
    block_size: int
