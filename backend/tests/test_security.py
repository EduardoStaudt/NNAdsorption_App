# test_security.py — testes das medidas de segurança do backend
#
# Não há mais login pra proteger: o que sobrou aqui são as defesas que valem
# pra uma API aberta — headers, CORS, rate limit e validação de faixa física.


def test_rate_limit_bloqueia_rajada(client):
    """Passado o limite por minuto, o IP leva 429 no lugar da resposta.

    Medido no /health porque o limite é global: não precisa carregar a rede
    pra provar que o contador funciona.
    """
    for _ in range(60):
        client.get("/health")

    resposta = client.get("/health")
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


def test_predict_com_eps_fora_da_faixa_retorna_422(client, inputs_validos):
    """eps (porosidade) maior que 1 é fisicamente impossível — deve dar 422."""
    inputs_validos["eps"] = 1.5
    resposta = client.post("/predict", json={"inputs": inputs_validos})
    assert resposta.status_code == 422


def test_predict_com_comprimento_negativo_retorna_422(client, inputs_validos):
    """L (comprimento da coluna) negativo é fisicamente impossível — deve dar 422."""
    inputs_validos["L"] = -1.0
    resposta = client.post("/predict", json={"inputs": inputs_validos})
    assert resposta.status_code == 422
