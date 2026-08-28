# lote.py — rotas de predição em lote: JSON, upload de planilha, exportação e template.
#
# Todas passam pelo mesmo `lote.rodar_lote`, que roda a rede UMA vez pro lote
# inteiro. O formato de colunas (ida e volta) está documentado em app/lote.py.
from typing import List, Optional

from fastapi import APIRouter, File, Form, HTTPException, Query, UploadFile
from fastapi.responses import Response

from .. import lote
from ..schemas import ExportBatchRequest, PredictBatchRequest, PredictBatchResponse

router = APIRouter(tags=["lote"])


def _arquivo(corpo: bytes, formato: str, nome: str) -> Response:
    """Devolve bytes como download, no media type do formato."""
    if formato == "xlsx":
        media, extensao = lote.MEDIA_XLSX, "xlsx"
    else:
        media, extensao = lote.MEDIA_CSV, "csv"
    return Response(
        content=corpo,
        media_type=media,
        headers={"Content-Disposition": "attachment; filename=%s.%s" % (nome, extensao)},
    )


def _checar_formato(formato: str) -> str:
    if formato not in ("csv", "xlsx"):
        raise HTTPException(status_code=422, detail="formato deve ser 'csv' ou 'xlsx'")
    return formato


@router.post("/predict_batch", response_model=PredictBatchResponse)
def predict_batch(body: PredictBatchRequest):
    """Prediz N experimentos de uma vez.

    Linha fora das faixas de treino não derruba o lote: sai com `avisos_faixa`
    preenchido e o resultado calculado do mesmo jeito, porque explorar fora do
    domínio é um uso legítimo.
    """
    return lote.rodar_lote(
        body.experimentos,
        escalares=body.saida.escalares,
        curvas=body.saida.curvas,
        colunas=body.saida.colunas,
    )


@router.post("/predict_batch_file", response_model=PredictBatchResponse)
async def predict_batch_file(
    arquivo: UploadFile = File(..., description="CSV ou XLSX com as 31 colunas do contrato"),
    escalares: bool = Form(True),
    curvas: bool = Form(False),
    colunas: Optional[str] = Form(None, description="escalares separados por vírgula"),
):
    """Mesma predição em lote, com a planilha do pesquisador como entrada."""
    conteudo = await arquivo.read()
    experimentos = lote.ler_tabela(conteudo, arquivo.filename or "")
    escolhidas: Optional[List[str]] = (
        [c.strip() for c in colunas.split(",") if c.strip()] if colunas else None
    )
    return lote.rodar_lote(experimentos, escalares=escalares, curvas=curvas, colunas=escolhidas)


@router.post("/export_batch")
def export_batch(body: ExportBatchRequest, formato: str = Query("csv")):
    """Converte um resultado de lote já calculado em planilha.

    CSV sai só com os escalares; XLSX ganha a aba 'Curvas' quando o lote foi
    rodado com `curvas: true`.
    """
    _checar_formato(formato)
    resultado = body.model_dump()
    corpo = lote.lote_para_xlsx(resultado) if formato == "xlsx" else lote.lote_para_csv(resultado)
    return _arquivo(corpo, formato, body.nome)


@router.get("/template_batch")
def template_batch(formato: str = Query("csv")):
    """Planilha modelo pra baixar, preencher e subir de volta."""
    _checar_formato(formato)
    corpo = lote.df_para_bytes(lote.template_df(), formato)
    return _arquivo(corpo, formato, "template_lote")
