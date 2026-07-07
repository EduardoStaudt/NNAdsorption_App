# Backend — NNAdsorption API

FastAPI + SQLite + SQLAlchemy. Roda predições da rede neural via `nnadsorption`.

## Como rodar

```bash
# Cria e ativa o ambiente virtual com Python 3.11
python3.11 -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/Mac

# Instala dependências
pip install -r requirements.txt

# Instala a biblioteca de predição (está no repo irmão)
pip install -e ..\..\NNAdsorption_Library   # Windows
# pip install -e ../../NNAdsorption_Library  # Linux/Mac

# Configura variáveis de ambiente
cp .env.example .env

# Sobe o servidor (cria app.db automaticamente na 1ª execução)
uvicorn app.main:app --reload
```

Servidor: `http://localhost:8000`
Documentação: `http://localhost:8000/docs`

## Rodar os testes

```bash
python -m pytest -v
```

Roda o fluxo principal (`test_basic.py`) e os testes de segurança
(`test_security.py` — rate limit, headers, CORS e validações).

## Endpoints

| Método | Rota                          | Auth | Descrição                           |
|--------|-------------------------------|------|-------------------------------------|
| POST   | /auth/register                | Não  | Cadastra usuário, retorna token JWT |
| POST   | /auth/login                   | Não  | Autentica, retorna token JWT        |
| GET    | /auth/me                      | Sim  | Dados do usuário logado             |
| POST   | /predict                      | Sim  | Roda predição e salva no histórico  |
| GET    | /predict/{id}/export?format=  | Sim  | Exporta predição como CSV ou XLSX   |
| GET    | /history                      | Sim  | Lista predições do usuário          |
| GET    | /history/{id}                 | Sim  | Detalhe de uma predição             |
| DELETE | /history/{id}                 | Sim  | Apaga uma predição                  |
| GET    | /meta                         | Não  | Nomes dos campos do modelo atual    |
| GET    | /health                       | Não  | Verifica se o servidor está no ar   |
