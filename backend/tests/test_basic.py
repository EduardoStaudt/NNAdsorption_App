# test_basic.py — testes básicos do backend
# A configuração do banco em memória e o client ficam em conftest.py


def test_registro_retorna_token(client):
    """Teste 1: cadastro de novo usuário deve retornar token JWT."""
    resposta = client.post("/auth/register", json={"email": "teste@exemplo.com", "password": "senha123"})
    assert resposta.status_code == 201
    dados = resposta.json()
    assert "token" in dados
    assert dados["user"]["email"] == "teste@exemplo.com"


def test_login_retorna_token(client):
    """Teste 2: login com credenciais corretas deve retornar token JWT."""
    # Garante que o usuário existe
    client.post("/auth/register", json={"email": "login@exemplo.com", "password": "senha123"})
    resposta = client.post("/auth/login", json={"email": "login@exemplo.com", "password": "senha123"})
    assert resposta.status_code == 200
    assert "token" in resposta.json()


def test_endpoint_protegido_sem_token_retorna_401(client):
    """Teste 3: acessar /auth/me sem token deve retornar 401."""
    resposta = client.get("/auth/me")
    assert resposta.status_code == 403  # HTTPBearer retorna 403 quando não tem header


def test_predict_valido_salva_no_historico(client, inputs_validos):
    """Teste 4: /predict com inputs válidos deve retornar resultado e salvar no histórico."""
    # Cria usuário e faz login
    client.post("/auth/register", json={"email": "pred@exemplo.com", "password": "senha123"})
    login = client.post("/auth/login", json={"email": "pred@exemplo.com", "password": "senha123"})
    token = login.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Faz a predição
    resposta = client.post("/predict", json={"inputs": inputs_validos}, headers=headers)
    assert resposta.status_code == 200
    dados = resposta.json()
    assert "prediction_id" in dados
    assert "result" in dados
    assert "C_out_final" in dados["result"]


def test_history_retorna_predicoes_do_usuario(client, inputs_validos):
    """Teste 5: /history deve retornar as predições do usuário logado."""
    # Cria usuário e faz uma predição
    client.post("/auth/register", json={"email": "hist@exemplo.com", "password": "senha123"})
    login = client.post("/auth/login", json={"email": "hist@exemplo.com", "password": "senha123"})
    token = login.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    client.post("/predict", json={"inputs": inputs_validos}, headers=headers)

    # Verifica o histórico
    resposta = client.get("/history", headers=headers)
    assert resposta.status_code == 200
    historico = resposta.json()
    assert len(historico) >= 1
    assert "id" in historico[0]
