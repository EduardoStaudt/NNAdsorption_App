# test_basic.py — testes básicos do backend
# O client e os inputs válidos ficam em conftest.py


def test_health_responde(client):
    """Teste 1: o health check responde sem autenticação nenhuma."""
    resposta = client.get("/health")
    assert resposta.status_code == 200
    assert resposta.json() == {"ok": True}


def test_predict_sem_token_funciona(client, inputs_validos, modelo):
    """Teste 2: /predict é aberto — não existe mais login pra passar por ele."""
    resposta = client.post("/predict", json={"inputs": inputs_validos})
    assert resposta.status_code == 200
    dados = resposta.json()
    assert "result" in dados
    assert "C_out_final" in dados["result"]
    # A API não guarda nada: não devolve id de nada
    assert "prediction_id" not in dados


def test_rotas_de_auth_nao_existem_mais(client):
    """Teste 3: o que era autenticação sumiu do app, não só ficou protegido."""
    for rota in ("/auth/login", "/auth/register", "/auth/me", "/history"):
        assert client.get(rota).status_code == 404, rota


def test_export_recebe_o_resultado_no_corpo(client, inputs_validos, modelo):
    """Teste 4: exportar não busca em banco — o cliente devolve o resultado."""
    result = client.post("/predict", json={"inputs": inputs_validos}).json()["result"]

    resposta = client.post("/export", json={"result": result, "format": "csv"})
    assert resposta.status_code == 200
    assert resposta.headers["content-type"].startswith("text/csv")


def test_export_recusa_formato_desconhecido(client, inputs_validos, modelo):
    """Teste 5: formato fora de csv/xlsx é erro de validação, não arquivo vazio."""
    result = client.post("/predict", json={"inputs": inputs_validos}).json()["result"]
    resposta = client.post("/export", json={"result": result, "format": "pdf"})
    assert resposta.status_code == 422
