# history.py — lista, detalha e apaga predições do histórico do usuário
import json
from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Prediction, User
from ..schemas import PredictionDetail, PredictionSummary

router = APIRouter(prefix="/history", tags=["history"])


@router.get("", response_model=List[PredictionSummary])
def list_history(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Lista todas as predições do usuário logado, mais recentes primeiro."""
    predicoes = (
        db.query(Prediction)
        .filter(Prediction.user_id == current_user.id)
        .order_by(Prediction.criado_em.desc())
        .all()
    )

    resultado = []
    for p in predicoes:
        outputs = json.loads(p.outputs_json)
        resultado.append(PredictionSummary(
            id=p.id,
            criado_em=p.criado_em,
            C_out_final=outputs.get("C_out_final"),
            q_out_final=outputs.get("q_out_final"),
            T_out_final=outputs.get("T_out_final"),
            N_ads_final=outputs.get("N_ads_final"),
            Qtot_final=outputs.get("Qtot_final"),
        ))
    return resultado


@router.get("/{prediction_id}", response_model=PredictionDetail)
def get_prediction(prediction_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Retorna os detalhes completos de uma predição (inputs + outputs)."""
    predicao = db.query(Prediction).filter(
        Prediction.id == prediction_id,
        Prediction.user_id == current_user.id,
    ).first()

    if predicao is None:
        raise HTTPException(status_code=404, detail="Predição não encontrada")

    return PredictionDetail(
        id=predicao.id,
        criado_em=predicao.criado_em,
        inputs=json.loads(predicao.inputs_json),
        outputs=json.loads(predicao.outputs_json),
    )


@router.delete("/{prediction_id}")
def delete_prediction(prediction_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Apaga uma predição do histórico do usuário."""
    predicao = db.query(Prediction).filter(
        Prediction.id == prediction_id,
        Prediction.user_id == current_user.id,
    ).first()

    if predicao is None:
        raise HTTPException(status_code=404, detail="Predição não encontrada")

    db.delete(predicao)
    db.commit()
    return {"ok": True}
