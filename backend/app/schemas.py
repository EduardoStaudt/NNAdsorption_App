# schemas.py — modelos Pydantic para validação de request e response
import math
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field, field_validator


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


# --- Predict em lote ---

class SaidaLote(BaseModel):
    """O que o cliente quer de volta de cada experimento do lote."""

    escalares: bool = True
    curvas: bool = False
    # None = todos os escalares; lista = só esses (ver lote.COLUNAS_ESCALARES)
    colunas: Optional[List[str]] = None


class PredictBatchRequest(BaseModel):
    # Cada item traz as 31 chaves do contrato + 'nome' opcional
    experimentos: List[Dict[str, Any]]
    saida: SaidaLote = Field(default_factory=SaidaLote)


class CurvasLote(BaseModel):
    """As 4 séries de M pontos de um experimento."""

    t_points: List[float]
    y_forte_points: List[float]
    y_carrier_points: List[float]
    T_out_points: List[float]


class ResultadoLote(BaseModel):
    """Um experimento do lote. Os escalares são opcionais porque `saida.colunas`
    pode pedir só alguns — `nome` e `avisos_faixa` nunca somem."""

    nome: str
    tbreak: Optional[float] = None
    tsat: Optional[float] = None
    TF: Optional[float] = None
    tst: Optional[float] = None
    pi_max: Optional[float] = None
    severidade: Optional[float] = None
    avisos_faixa: List[str] = Field(default_factory=list)
    curvas: Optional[CurvasLote] = None


class PredictBatchResponse(BaseModel):
    n_total: int
    n_avisos: int
    # Tempo da rede no lote inteiro — é o número que mostra o ganho sobre o solver
    tempo_ms: int
    resultados: List[ResultadoLote]


class ExportBatchRequest(BaseModel):
    """Resultado do lote devolvido pelo cliente pra virar planilha.

    Mesmo desenho do /export: a API não guarda nada, quem tem o resultado é quem
    o pediu.
    """

    n_total: int = 0
    n_avisos: int = 0
    tempo_ms: int = 0
    resultados: List[ResultadoLote]
    nome: str = "lote"
