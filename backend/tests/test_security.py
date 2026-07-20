# test_security.py — testes das medidas de segurança do backend


def _login_headers(client, email: str) -> dict:
    """Cadastra um usuário e devolve o header Authorization pronto."""
    client.post("/auth/register", json={"email": email, "password": "senha123"})
    login = client.post("/auth/login", json={"email": email, "password": "senha123"})
    return {"Authorization": f"Bearer {login.json()['token']}"}


def test_sexta_tentativa_de_login_retorna_429(client):
    """Rate limit: a 6ª tentativa de login dentro de 1 minuto deve ser bloqueada."""
    credenciais = {"email": "bruto@exemplo.com", "password": "senhaerrada1"}
    for _ in range(5):
        client.post("/auth/login", json=credenciais)

    resposta = client.post("/auth/login", json=credenciais)
    assert resposta.status_code == 429
    assert "retry-after" in resposta.headers


def test_headers_de_seguranca_presentes(client):
    """Toda resposta deve trazer os headers de segurança do middleware."""
    resposta = client.get("/health")
    assert resposta.headers["x-content-type-options"] == "nosniff"
    assert resposta.headers["x-frame-options"] == "DENY"
    assert resposta.headers["referrer-policy"] == "strict-origin-when-cross-origin"
    assert resposta.headers["strict-transport-security"] == "max-age=31536000; includeSubDomains"
    assert resposta.headers["content-security-policy"] == "default-src 'self'"


def test_docs_tem_csp_permissiva_para_o_swagger(client):
    """/docs precisa liberar o CDN do Swagger, mas sem afetar o resto da API."""
    resposta = client.get("/docs")
    csp = resposta.headers["content-security-policy"]
    assert "cdn.jsdelivr.net" in csp
    assert "fonts.googleapis.com" in csp

    # Uma rota qualquer fora de /docs continua com a CSP restrita
    resposta_normal = client.get("/health")
    assert resposta_normal.headers["content-security-policy"] == "default-src 'self'"


def test_cors_rejeita_origem_nao_permitida(client):
    """Preflight CORS de uma origem fora da lista do .env deve ser rejeitado."""
    resposta = client.options("/health", headers={
        "Origin": "http://site-malicioso.com",
        "Access-Control-Request-Method": "GET",
    })
    assert resposta.status_code == 400
    assert "access-control-allow-origin" not in resposta.headers


def test_senha_curta_rejeitada_no_register(client):
    """Senha "1234" (menos de 8 caracteres) deve ser rejeitada com 422."""
    resposta = client.post("/auth/register", json={"email": "fraco@exemplo.com", "password": "1234"})
    assert resposta.status_code == 422


def test_senha_sem_numero_rejeitada_no_register(client):
    """Senha só com letras (sem número) deve ser rejeitada com 422."""
    resposta = client.post("/auth/register", json={"email": "fraco2@exemplo.com", "password": "somenteletras"})
    assert resposta.status_code == 422


def test_predict_com_eps_fora_da_faixa_retorna_422(client, inputs_validos):
    """eps (porosidade) maior que 1 é fisicamente impossível — deve dar 422."""
    headers = _login_headers(client, "faixas@exemplo.com")
    inputs_validos["eps"] = 1.5

    resposta = client.post("/predict", json={"inputs": inputs_validos}, headers=headers)
    assert resposta.status_code == 422


def test_predict_com_comprimento_negativo_retorna_422(client, inputs_validos):
    """L (comprimento da coluna) negativo é fisicamente impossível — deve dar 422."""
    headers = _login_headers(client, "faixas2@exemplo.com")
    inputs_validos["L"] = -1.0

    resposta = client.post("/predict", json={"inputs": inputs_validos}, headers=headers)
    assert resposta.status_code == 422
