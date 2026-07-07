# predict.py — endpoint de predição e exportação de resultados
import io
import json
import os
import tempfile

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from nnadsorption.exporters import to_csv, to_xlsx
from nnadsorption.predictor import get_predictor
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user, get_current_user_query_or_header
from ..models import Prediction, User
from ..schemas import PredictRequest, PredictResponse

router = APIRouter(tags=["predict"])


@router.post("/predict", response_model=PredictResponse)
def predict(body: PredictRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Roda a predição da rede neural e salva no histórico."""
    pred = get_predictor()

    # Deixa a própria lib validar os inputs — ela levanta KeyError com mensagem clara
    try:
        result = pred.predict(body.inputs)
    except KeyError as e:
        raise HTTPException(status_code=422, detail=str(e))

    nova_predicao = Prediction(
        user_id=current_user.id,
        inputs_json=json.dumps(body.inputs),
        outputs_json=json.dumps(result),
    )
    db.add(nova_predicao)
    db.commit()
    db.refresh(nova_predicao)

    return PredictResponse(prediction_id=nova_predicao.id, result=result)


def _exportar_para_arquivo(result: dict, prediction_id: int, format: str) -> StreamingResponse:
    """Gera o arquivo de exportação em disco e devolve como StreamingResponse.

    Usa arquivo temporário porque os exporters da lib escrevem em path (não BytesIO).
    """
    if format == "xlsx":
        suffix, mode, media_type = ".xlsx", "wb", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else:
        suffix, mode, media_type = ".csv", "w", "text/csv"

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp_path = tmp.name

    try:
        if format == "xlsx":
            to_xlsx(result, tmp_path)
            with open(tmp_path, "rb") as f:
                conteudo = f.read()
            corpo = io.BytesIO(conteudo)
        else:
            to_csv(result, tmp_path)
            with open(tmp_path, "r", encoding="utf-8") as f:
                conteudo = f.read()
            corpo = io.StringIO(conteudo)
    finally:
        os.unlink(tmp_path)

    nome_arquivo = f"predicao_{prediction_id}{suffix}"
    return StreamingResponse(
        corpo,
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={nome_arquivo}"},
    )


@router.get("/predict/{prediction_id}/export")
def export_prediction(
    prediction_id: int,
    format: str = "csv",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user_query_or_header),
):
    """Exporta uma predição salva como CSV ou XLSX (sem re-executar a inferência)."""
    predicao = db.query(Prediction).filter(
        Prediction.id == prediction_id,
        Prediction.user_id == current_user.id,
    ).first()

    if predicao is None:
        raise HTTPException(status_code=404, detail="Predição não encontrada")

    # Usa os outputs já salvos no banco — não precisa rodar a rede neural de novo
    outputs = json.loads(predicao.outputs_json)
    return _exportar_para_arquivo(outputs, prediction_id, format)
