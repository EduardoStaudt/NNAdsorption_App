# lote.py — predição em lote: monta a matriz, roda a rede uma vez e formata a saída.
#
# A vantagem do surrogate sobre o solver aparece aqui: a rede é vetorizada, então
# mil curvas custam quase o mesmo que uma. Toda rota de lote passa por
# `rodar_lote` — o laço que rodaria linha a linha é justamente o que não pode
# existir.
#
# FORMATO DE I/O — o mesmo esquema de colunas vale na ida e na volta:
#
#   Entrada (nome + as 31 colunas do contrato, nesta ordem):
#     nome, c0_qm_ref, c0_k2, c0_B_ref, c0_k4, c0_n_ref, c0_k6, c0_kL, c0_dH,
#     c0_Cpg, c1_... (idem), eb, rho_b, Cps, vs, Tin, P, L, Dt, hw, lam, dp, Dm, y0
#
#   Saída escalares:
#     nome, tbreak, tsat, TF, tst, pi_max, severidade, avisos
#
#   Saída curvas (formato longo, uma linha por ponto):
#     nome, t, y_forte, y_carrier, T_out
#
# As unidades são as do contrato da lib (SI): dH em J/mol, P em Pa, dp em m.
# Não são as da tela — o frontend converte antes de mandar.
import io
import time
from typing import Any, Dict, List, Optional, Sequence

import pandas as pd
from fastapi import HTTPException
from nnadsorption import contract
from nnadsorption.predictor import get_predictor

# Colunas dos 31 parâmetros, na ordem exata que a rede espera.
COLUNAS_PARAMETROS: List[str] = contract.x_column_names()
COLUNAS_ENTRADA: List[str] = ["nome"] + COLUNAS_PARAMETROS

# Escalares que a rede devolve por experimento.
COLUNAS_ESCALARES: List[str] = ["tbreak", "tsat", "TF", "tst", "pi_max", "severidade"]

# Séries de 100 pontos por experimento.
COLUNAS_CURVAS: List[str] = ["t_points", "y_forte_points", "y_carrier_points", "T_out_points"]

# Teto de linhas por requisição. A API é aberta e sem conta; sem um teto, uma
# requisição só derruba o processo.
MAX_LINHAS = 5000

# Linhas de exemplo do template. Valores dentro das faixas de treino, nas
# unidades do contrato — servem de referência de grandeza pra quem preenche.
LINHAS_EXEMPLO: List[Dict[str, Any]] = [
    {
        "nome": "exemplo_1",
        "c0_qm_ref": 8.0, "c0_k2": -0.02, "c0_B_ref": 0.1, "c0_k4": 1500.0,
        "c0_n_ref": 1.0, "c0_k6": 0.0, "c0_kL": 0.1, "c0_dH": 25000.0, "c0_Cpg": 29.0,
        "c1_qm_ref": 8.0, "c1_k2": -0.02, "c1_B_ref": 0.1, "c1_k4": 1500.0,
        "c1_n_ref": 1.0, "c1_k6": 0.0, "c1_kL": 0.1, "c1_dH": 25000.0, "c1_Cpg": 37.0,
        "eb": 0.4, "rho_b": 650.0, "Cps": 1000.0,
        "vs": 0.01, "Tin": 298.0, "P": 1.0e6, "L": 0.5, "Dt": 0.035,
        "hw": 50.0, "lam": 0.4, "dp": 2.0e-3, "Dm": 1.0e-5, "y0": 0.5,
    },
    {
        "nome": "exemplo_2",
        "c0_qm_ref": 5.0, "c0_k2": -0.01, "c0_B_ref": 0.02, "c0_k4": 900.0,
        "c0_n_ref": 0.9, "c0_k6": -500.0, "c0_kL": 0.05, "c0_dH": 15000.0, "c0_Cpg": 29.0,
        "c1_qm_ref": 12.0, "c1_k2": -0.03, "c1_B_ref": 0.5, "c1_k4": 2200.0,
        "c1_n_ref": 1.1, "c1_k6": 800.0, "c1_kL": 0.3, "c1_dH": 40000.0, "c1_Cpg": 40.0,
        "eb": 0.38, "rho_b": 750.0, "Cps": 950.0,
        "vs": 0.02, "Tin": 310.0, "P": 2.0e6, "L": 1.0, "Dt": 0.05,
        "hw": 70.0, "lam": 0.5, "dp": 1.0e-3, "Dm": 2.0e-5, "y0": 0.6,
    },
]

MEDIA_CSV = "text/csv"
MEDIA_XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"


# --- predição ---

def rodar_lote(experimentos: Sequence[Dict[str, Any]],
               escalares: bool = True,
               curvas: bool = False,
               colunas: Optional[Sequence[str]] = None) -> Dict[str, Any]:
    """Roda N experimentos numa única passada da rede e formata a resposta.

    `colunas` filtra quais escalares aparecem (None = todos). `nome` e
    `avisos_faixa` ficam sempre: sem eles não dá pra saber de qual linha é o
    resultado nem se ele saiu do domínio de treino.
    """
    if not experimentos:
        raise HTTPException(status_code=422, detail="lote vazio: mande ao menos um experimento")
    if len(experimentos) > MAX_LINHAS:
        raise HTTPException(
            status_code=422,
            detail="lote de %d linhas passa do teto de %d" % (len(experimentos), MAX_LINHAS),
        )

    nomes = [str(e.get("nome") or "exp_%d" % (i + 1)) for i, e in enumerate(experimentos)]
    escolhidas = _escalares_pedidos(escalares, colunas)

    pred = get_predictor()
    inicio = time.perf_counter()
    try:
        brutos = pred.predict_batch(list(experimentos))
    except FileNotFoundError as e:
        # Pesos da rede ausentes na máquina: é erro de instalação, não do pedido.
        raise HTTPException(status_code=503, detail=str(e))
    except (KeyError, TypeError, ValueError) as e:
        raise HTTPException(status_code=422, detail=str(e))
    tempo_ms = int(round((time.perf_counter() - inicio) * 1000))

    resultados = []
    for nome, bruto in zip(nomes, brutos):
        linha: Dict[str, Any] = {"nome": nome, "avisos_faixa": bruto["avisos_faixa"]}
        for chave in escolhidas:
            linha[chave] = bruto[chave]
        linha["curvas"] = {c: bruto[c] for c in COLUNAS_CURVAS} if curvas else None
        resultados.append(linha)

    return {
        "n_total": len(resultados),
        "n_avisos": sum(1 for r in resultados if r["avisos_faixa"]),
        "tempo_ms": tempo_ms,
        "resultados": resultados,
    }


def _escalares_pedidos(escalares: bool, colunas: Optional[Sequence[str]]) -> List[str]:
    """Quais escalares entram na saída, sempre na ordem canônica."""
    if not escalares:
        return []
    if colunas is None:
        return list(COLUNAS_ESCALARES)
    desconhecidas = [c for c in colunas if c not in COLUNAS_ESCALARES]
    if desconhecidas:
        raise HTTPException(
            status_code=422,
            detail="coluna(s) desconhecida(s): %s. Disponíveis: %s"
                   % (", ".join(desconhecidas), ", ".join(COLUNAS_ESCALARES)),
        )
    return [c for c in COLUNAS_ESCALARES if c in colunas]


# --- leitura de arquivo ---

def ler_tabela(conteudo: bytes, nome_arquivo: str) -> List[Dict[str, Any]]:
    """Lê CSV ou XLSX e devolve a lista de experimentos no formato do contrato.

    Cabeçalho obrigatório: as 31 colunas do contrato. `nome` é opcional.
    """
    extensao = nome_arquivo.lower().rsplit(".", 1)[-1] if "." in nome_arquivo else ""
    if extensao == "csv":
        leitor = pd.read_csv
    elif extensao in ("xlsx", "xlsm", "xls"):
        leitor = pd.read_excel
    else:
        raise HTTPException(
            status_code=422,
            detail="extensão %s não suportada: use .csv ou .xlsx" % (extensao or "(nenhuma)"),
        )

    try:
        df = leitor(io.BytesIO(conteudo))
    except Exception as e:
        raise HTTPException(status_code=422, detail="não consegui ler o arquivo: %s" % e)

    df.columns = [str(c).strip() for c in df.columns]

    faltando = [c for c in COLUNAS_PARAMETROS if c not in df.columns]
    if faltando:
        raise HTTPException(
            status_code=422,
            detail="faltam %d coluna(s) no cabeçalho: %s" % (len(faltando), ", ".join(faltando)),
        )
    if df.empty:
        raise HTTPException(status_code=422, detail="arquivo sem nenhuma linha de dados")

    vazias = df[COLUNAS_PARAMETROS].isna().any(axis=1)
    if bool(vazias.any()):
        # +2 porque a linha 1 da planilha é o cabeçalho e a contagem do usuário começa em 1
        linhas = [int(i) + 2 for i in df.index[vazias][:5]]
        raise HTTPException(
            status_code=422,
            detail="célula vazia nas linhas: %s" % ", ".join(str(n) for n in linhas),
        )

    tem_nome = "nome" in df.columns
    experimentos = []
    for i, (_, linha) in enumerate(df.iterrows()):
        exp: Dict[str, Any] = {c: linha[c] for c in COLUNAS_PARAMETROS}
        if tem_nome and pd.notna(linha["nome"]):
            exp["nome"] = str(linha["nome"])
        else:
            exp["nome"] = "exp_%d" % (i + 1)
        experimentos.append(exp)
    return experimentos


# --- template de entrada ---

def template_df() -> pd.DataFrame:
    """Planilha modelo: cabeçalho na ordem certa + 2 linhas de exemplo válidas."""
    return pd.DataFrame(LINHAS_EXEMPLO, columns=COLUNAS_ENTRADA)


# --- exportação do resultado ---

def resumo_df(resultado: Dict[str, Any]) -> pd.DataFrame:
    """Uma linha por experimento: nome + escalares + avisos concatenados."""
    linhas = []
    for r in resultado.get("resultados", []):
        linha: Dict[str, Any] = {"nome": r.get("nome", "")}
        for c in COLUNAS_ESCALARES:
            if r.get(c) is not None:
                linha[c] = r[c]
        linha["avisos"] = "; ".join(r.get("avisos_faixa") or [])
        linhas.append(linha)
    return pd.DataFrame(linhas)


def curvas_df(resultado: Dict[str, Any]) -> pd.DataFrame:
    """Formato longo: uma linha por ponto de cada experimento.

    Longo em vez de largo porque 100 pontos x 4 séries viram 400 colunas — uma
    planilha que ninguém lê e nenhum gráfico aceita direto.
    """
    linhas = []
    for r in resultado.get("resultados", []):
        curvas = r.get("curvas")
        if not curvas:
            continue
        nome = r.get("nome", "")
        for i, t in enumerate(curvas["t_points"]):
            linhas.append({
                "nome": nome,
                "t": t,
                "y_forte": curvas["y_forte_points"][i],
                "y_carrier": curvas["y_carrier_points"][i],
                "T_out": curvas["T_out_points"][i],
            })
    return pd.DataFrame(linhas, columns=["nome", "t", "y_forte", "y_carrier", "T_out"])


def lote_para_csv(resultado: Dict[str, Any]) -> bytes:
    """CSV só com os escalares — achatar 100 pontos em colunas fica ilegível."""
    return resumo_df(resultado).to_csv(index=False).encode("utf-8")


def lote_para_xlsx(resultado: Dict[str, Any]) -> bytes:
    """XLSX com aba 'Resumo' e, quando houver curvas, uma aba 'Curvas' longa."""
    buffer = io.BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        resumo_df(resultado).to_excel(writer, sheet_name="Resumo", index=False)
        curvas = curvas_df(resultado)
        if not curvas.empty:
            curvas.to_excel(writer, sheet_name="Curvas", index=False)
    return buffer.getvalue()


def df_para_bytes(df: pd.DataFrame, formato: str, aba: str = "Modelo") -> bytes:
    """Serializa um DataFrame no formato pedido (usado pelo template)."""
    if formato == "csv":
        return df.to_csv(index=False).encode("utf-8")
    buffer = io.BytesIO()
    with pd.ExcelWriter(buffer, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name=aba, index=False)
    return buffer.getvalue()
