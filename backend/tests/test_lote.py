# test_lote.py — testes da predição em lote (JSON, upload, exportação, template)
#
# Os pesos V3 não estão nesta máquina, então quase tudo roda com o `rede_fake`
# do conftest: a cascata de verdade (contrato → física → enriquecimento → grade
# de tempo) é exercitada, só os dois modelos Keras é que devolvem zeros.
import io

import pandas as pd
import pytest

from app import lote

from .conftest import MODELO_DISPONIVEL, entrada_lote


# --- POST /predict_batch ---

def test_lote_devolve_um_resultado_por_experimento(client, rede_fake):
    corpo = {"experimentos": [entrada_lote(), entrada_lote(L=1.0), entrada_lote(vs=0.02)]}
    resposta = client.post("/predict_batch", json=corpo)

    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["n_total"] == 3
    assert dados["n_avisos"] == 0
    assert len(dados["resultados"]) == 3
    assert dados["tempo_ms"] >= 0


def test_a_rede_roda_uma_vez_so_para_o_lote_inteiro(client, rede_fake):
    corpo = {"experimentos": [entrada_lote() for _ in range(25)]}
    assert client.post("/predict_batch", json=corpo).status_code == 200

    # O ponto central da feature: 25 linhas, 1 chamada de cada rede
    assert rede_fake.m_tempos.chamadas == 1
    assert rede_fake.m_tempos.ultimo_n == 25
    assert rede_fake.m_forma.chamadas == 1
    assert rede_fake.m_forma.ultimo_n == 25


def test_escalares_saem_por_padrao_e_curvas_nao(client, rede_fake):
    resposta = client.post("/predict_batch", json={"experimentos": [entrada_lote()]})
    r = resposta.json()["resultados"][0]

    for chave in ("tbreak", "tsat", "TF", "tst", "pi_max", "severidade"):
        assert isinstance(r[chave], float)
    assert r["curvas"] is None


def test_curvas_vem_com_as_quatro_series(client, rede_fake):
    corpo = {"experimentos": [entrada_lote()], "saida": {"curvas": True}}
    curvas = client.post("/predict_batch", json=corpo).json()["resultados"][0]["curvas"]

    for serie in ("t_points", "y_forte_points", "y_carrier_points", "T_out_points"):
        assert len(curvas[serie]) == 100


def test_colunas_filtra_os_escalares(client, rede_fake):
    corpo = {
        "experimentos": [entrada_lote()],
        "saida": {"escalares": True, "colunas": ["tbreak", "severidade"]},
    }
    r = client.post("/predict_batch", json=corpo).json()["resultados"][0]

    assert r["tbreak"] is not None and r["severidade"] is not None
    assert r["tsat"] is None and r["TF"] is None
    # nome e avisos nunca somem: sem eles não dá pra saber de qual linha é isso
    assert r["nome"] and r["avisos_faixa"] == []


def test_coluna_desconhecida_e_erro_com_a_lista_do_que_existe(client, rede_fake):
    corpo = {"experimentos": [entrada_lote()], "saida": {"colunas": ["tbreak", "chutei"]}}
    resposta = client.post("/predict_batch", json=corpo)

    assert resposta.status_code == 422
    assert "chutei" in resposta.json()["detail"]
    assert "tsat" in resposta.json()["detail"]


def test_fora_da_faixa_avisa_mas_nao_bloqueia_o_lote(client, rede_fake):
    corpo = {"experimentos": [entrada_lote(), entrada_lote(L=99.0)]}
    dados = client.post("/predict_batch", json=corpo).json()

    assert dados["n_total"] == 2 and dados["n_avisos"] == 1
    assert dados["resultados"][0]["avisos_faixa"] == []
    assert "L = 99" in dados["resultados"][1]["avisos_faixa"][0]
    # o resultado da linha avisada foi calculado do mesmo jeito
    assert dados["resultados"][1]["tbreak"] is not None


def test_experimento_sem_nome_ganha_um_indice(client, rede_fake):
    corpo = {"experimentos": [entrada_lote(), dict(entrada_lote(), nome="meu_exp")]}
    resultados = client.post("/predict_batch", json=corpo).json()["resultados"]

    assert resultados[0]["nome"] == "exp_1"
    assert resultados[1]["nome"] == "meu_exp"


def test_lote_vazio_e_erro(client, rede_fake):
    assert client.post("/predict_batch", json={"experimentos": []}).status_code == 422


def test_lote_grande_demais_e_recusado(client, rede_fake, monkeypatch):
    monkeypatch.setattr(lote, "MAX_LINHAS", 2)
    corpo = {"experimentos": [entrada_lote() for _ in range(3)]}
    resposta = client.post("/predict_batch", json=corpo)

    assert resposta.status_code == 422
    assert "teto" in resposta.json()["detail"]


def test_parametro_faltando_diz_qual_linha(client, rede_fake):
    incompleto = entrada_lote()
    del incompleto["vs"]
    resposta = client.post("/predict_batch", json={"experimentos": [entrada_lote(), incompleto]})

    assert resposta.status_code == 422
    assert "linha 1" in resposta.json()["detail"]
    assert "vs" in resposta.json()["detail"]


def test_predict_e_predict_batch_concordam(client, rede_fake, monkeypatch):
    """A cascata é a mesma: um lote de 1 tem que dar o mesmo que /predict."""
    from app.routers import predict as rota_predict

    monkeypatch.setattr(rota_predict, "get_predictor", lambda: rede_fake)
    entrada = entrada_lote()

    um = client.post("/predict", json={"inputs": entrada}).json()["result"]
    lote_um = client.post("/predict_batch", json={"experimentos": [entrada]}).json()

    assert um["tbreak"] == pytest.approx(lote_um["resultados"][0]["tbreak"])
    assert um["TF"] == pytest.approx(lote_um["resultados"][0]["TF"])


@pytest.mark.skipif(MODELO_DISPONIVEL, reason="os pesos existem nesta máquina")
def test_sem_os_pesos_a_resposta_explica_o_que_falta(client):
    """Sem `rede_fake`: o predictor real não acha os artefatos."""
    resposta = client.post("/predict_batch", json={"experimentos": [entrada_lote()]})

    assert resposta.status_code == 503
    assert "Artefato ausente" in resposta.json()["detail"]


# --- POST /predict_batch_file ---

def _csv_de(linhas):
    return pd.DataFrame(linhas).to_csv(index=False).encode("utf-8")


def test_upload_de_csv_roda_o_lote(client, rede_fake):
    conteudo = _csv_de([
        dict(entrada_lote(), nome="planilha_a"),
        dict(entrada_lote(L=1.2), nome="planilha_b"),
    ])
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.csv", conteudo, "text/csv")},
    )

    assert resposta.status_code == 200
    dados = resposta.json()
    assert dados["n_total"] == 2
    assert [r["nome"] for r in dados["resultados"]] == ["planilha_a", "planilha_b"]


def test_upload_de_xlsx_roda_o_lote(client, rede_fake):
    df = pd.DataFrame([entrada_lote(), entrada_lote(vs=0.03)])
    conteudo = lote.df_para_bytes(df, "xlsx")
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.xlsx", conteudo, lote.MEDIA_XLSX)},
    )

    assert resposta.status_code == 200
    assert resposta.json()["n_total"] == 2


def test_upload_sem_coluna_nome_gera_nomes(client, rede_fake):
    linhas = [entrada_lote(), entrada_lote()]
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.csv", _csv_de(linhas), "text/csv")},
    )

    assert [r["nome"] for r in resposta.json()["resultados"]] == ["exp_1", "exp_2"]


def test_upload_com_coluna_faltando_diz_qual(client, rede_fake):
    linha = entrada_lote()
    del linha["c1_Cpg"]
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.csv", _csv_de([linha]), "text/csv")},
    )

    assert resposta.status_code == 422
    assert "c1_Cpg" in resposta.json()["detail"]


def test_upload_com_celula_vazia_aponta_a_linha(client, rede_fake):
    linhas = [entrada_lote(), entrada_lote(vs=None)]
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.csv", _csv_de(linhas), "text/csv")},
    )

    assert resposta.status_code == 422
    # linha 3 da planilha = cabeçalho + 2ª linha de dados
    assert "3" in resposta.json()["detail"]


def test_upload_de_extensao_desconhecida_e_recusado(client, rede_fake):
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.txt", b"qualquer coisa", "text/plain")},
    )

    assert resposta.status_code == 422
    assert "csv" in resposta.json()["detail"]


def test_upload_aceita_os_mesmos_campos_de_saida(client, rede_fake):
    conteudo = _csv_de([entrada_lote()])
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("lote.csv", conteudo, "text/csv")},
        data={"curvas": "true", "colunas": "tbreak"},
    )

    r = resposta.json()["resultados"][0]
    assert r["tbreak"] is not None and r["tsat"] is None
    assert len(r["curvas"]["t_points"]) == 100


# --- GET /template_batch ---

def test_template_csv_tem_o_cabecalho_do_contrato(client):
    resposta = client.get("/template_batch", params={"formato": "csv"})

    assert resposta.status_code == 200
    assert "attachment" in resposta.headers["content-disposition"]
    cabecalho = resposta.text.splitlines()[0].split(",")
    assert cabecalho == lote.COLUNAS_ENTRADA
    assert cabecalho[0] == "nome" and len(cabecalho) == 32


def test_template_xlsx_abre_como_planilha(client):
    resposta = client.get("/template_batch", params={"formato": "xlsx"})

    assert resposta.status_code == 200
    df = pd.read_excel(io.BytesIO(resposta.content))
    assert list(df.columns) == lote.COLUNAS_ENTRADA
    assert len(df) == 2


def test_template_volta_pro_lote_sem_nenhum_aviso(client, rede_fake):
    """Ida e volta: o modelo baixado sobe de volta e roda limpo."""
    modelo = client.get("/template_batch", params={"formato": "csv"}).content
    resposta = client.post(
        "/predict_batch_file",
        files={"arquivo": ("template_lote.csv", modelo, "text/csv")},
    )

    dados = resposta.json()
    assert dados["n_total"] == 2
    assert dados["n_avisos"] == 0
    assert [r["nome"] for r in dados["resultados"]] == ["exemplo_1", "exemplo_2"]


def test_template_recusa_formato_desconhecido(client):
    assert client.get("/template_batch", params={"formato": "pdf"}).status_code == 422


# --- POST /export_batch ---

def _resultado_de(client, **saida):
    corpo = {"experimentos": [entrada_lote(), entrada_lote(L=99.0)], "saida": saida}
    return client.post("/predict_batch", json=corpo).json()


def test_export_csv_tem_uma_linha_por_experimento(client, rede_fake):
    resultado = _resultado_de(client)
    resposta = client.post("/export_batch", json=resultado, params={"formato": "csv"})

    assert resposta.status_code == 200
    assert resposta.headers["content-type"].startswith("text/csv")
    df = pd.read_csv(io.StringIO(resposta.text))
    assert len(df) == 2
    assert list(df.columns) == ["nome", *lote.COLUNAS_ESCALARES, "avisos"]
    assert "fora da faixa" in df["avisos"].iloc[1]


def test_export_xlsx_separa_resumo_e_curvas(client, rede_fake):
    resultado = _resultado_de(client, curvas=True)
    resposta = client.post("/export_batch", json=resultado, params={"formato": "xlsx"})

    assert resposta.status_code == 200
    abas = pd.read_excel(io.BytesIO(resposta.content), sheet_name=None)
    assert list(abas) == ["Resumo", "Curvas"]
    assert len(abas["Resumo"]) == 2
    # formato longo: 2 experimentos x 100 pontos
    assert len(abas["Curvas"]) == 200
    assert list(abas["Curvas"].columns) == ["nome", "t", "y_forte", "y_carrier", "T_out"]


def test_export_xlsx_sem_curvas_so_tem_o_resumo(client, rede_fake):
    resultado = _resultado_de(client)
    resposta = client.post("/export_batch", json=resultado, params={"formato": "xlsx"})

    abas = pd.read_excel(io.BytesIO(resposta.content), sheet_name=None)
    assert list(abas) == ["Resumo"]


def test_export_recusa_formato_desconhecido(client, rede_fake):
    resultado = _resultado_de(client)
    resposta = client.post("/export_batch", json=resultado, params={"formato": "pdf"})

    assert resposta.status_code == 422
