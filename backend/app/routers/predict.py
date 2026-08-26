# predict.py — endpoint de predição e exportação de resultados
#
# Sem estado: a API recebe os parâmetros, roda a rede e devolve a curva. Quem
# guarda o que foi rodado é o navegador (localStorage) — por isso a exportação
# recebe o resultado de volta no corpo em vez de buscá-lo num banco.
import io
import os
import tempfile

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from nnadsorption.exporters import to_csv, to_xlsx
from nnadsorption.predictor import get_predictor

from ..schemas import ExportRequest, PredictRequest, PredictResponse

router = APIRouter(tags=["predict"])


@router.post("/predict", response_model=PredictResponse)
def predict(body: PredictRequest):
    """Roda a predição da rede neural e devolve o resultado."""
    pred = get_predictor()

    # Deixa a própria lib validar os inputs — ela levanta KeyError com mensagem clara
    try:
        result = pred.predict(body.inputs)
    except KeyError as e:
        raise HTTPException(status_code=422, detail=str(e))

    return PredictResponse(result=result)


def _exportar_para_arquivo(result: dict, nome: str, format: str) -> StreamingResponse:
    """Gera o arquivo de exportação em disco e devolve como StreamingResponse.

    Usa arquivo temporário porque os exporters da lib escrevem em path (não BytesIO).
    """
    if format == "xlsx":
        suffix, media_type = ".xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else:
        suffix, media_type = ".csv", "text/csv"

    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp_path = tmp.name

    try:
        if format == "xlsx":
            to_xlsx(result, tmp_path)
            with open(tmp_path, "rb") as f:
                corpo = io.BytesIO(f.read())
        else:
            to_csv(result, tmp_path)
            with open(tmp_path, "r", encoding="utf-8") as f:
                corpo = io.StringIO(f.read())
    finally:
        os.unlink(tmp_path)

    return StreamingResponse(
        corpo,
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={nome}{suffix}"},
    )


@router.post("/export")
def export_prediction(body: ExportRequest):
    """Converte um resultado já calculado em CSV ou XLSX.

    O resultado vem do cliente (que o guardou no localStorage) — a API não tem
    onde procurá-lo.
    """
    if body.format not in ("csv", "xlsx"):
        raise HTTPException(status_code=422, detail="format deve ser 'csv' ou 'xlsx'")
    return _exportar_para_arquivo(body.result, body.nome, body.format)
