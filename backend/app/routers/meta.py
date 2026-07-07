# meta.py — expõe os metadados do modelo (nomes dos inputs/outputs)
from fastapi import APIRouter
from nnadsorption.predictor import get_predictor

from ..schemas import MetaResponse

router = APIRouter(tags=["meta"])


@router.get("/meta", response_model=MetaResponse)
def get_meta():
    """Retorna os nomes dos campos do modelo atual (lidos da lib)."""
    pred = get_predictor()

    return MetaResponse(
        input_cols=pred.input_cols,
        final_cols=pred.final_cols,
        block_size=pred.block_size,
    )
