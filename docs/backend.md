# Backend

API FastAPI que autentica usuários, roda as predições e guarda o histórico.

> 💡 Com o servidor rodando, acesse **http://localhost:8000/docs** — o
> Swagger gerado automaticamente pelo FastAPI é a referência interativa da
> API: dá pra testar cada endpoint direto do navegador.

## Estrutura

```
backend/
    app/
        main.py         cria o app, registra middlewares e rotas
        config.py       lê o .env (JWT_SECRET, ALLOWED_ORIGINS...)
        database.py     engine SQLAlchemy + sessão do SQLite
        models.py       tabelas User e Prediction
        schemas.py      modelos Pydantic (validação de entrada/saída)
        security.py     hash bcrypt + criação/verificação de JWT
        rate_limit.py   limitador de requisições por IP (slowapi)
        deps.py         dependências (usuário logado a partir do token)
        routers/
            auth.py     /auth/register, /auth/login, /auth/me
            predict.py  /predict e /predict/{id}/export
            history.py  /history (listar, detalhar, apagar)
            meta.py     /meta (nomes dos campos do modelo)
    tests/
        conftest.py     banco em memória + fixtures compartilhadas
        test_basic.py   fluxo principal (auth, predict, history)
        test_security.py  rate limit, headers, CORS, validações
```

## Endpoints

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/auth/register` | Não | Cadastra usuário e devolve JWT |
| POST | `/auth/login` | Não | Autentica e devolve JWT |
| GET | `/auth/me` | Sim | Dados do usuário do token |
| POST | `/predict` | Sim | Roda a rede neural e salva no histórico |
| GET | `/predict/{id}/export?format=csv\|xlsx` | Sim | Baixa resultados salvos |
| GET | `/history` | Sim | Lista predições do usuário (resumo) |
| GET | `/history/{id}` | Sim | Inputs + outputs completos de uma predição |
| DELETE | `/history/{id}` | Sim | Apaga uma predição |
| GET | `/meta` | Não | Nomes dos inputs/outputs do modelo |
| GET | `/health` | Não | Health check (`{"ok": true}`) |

## Autenticação

- Cadastro exige **email válido** (Pydantic `EmailStr`) e **senha com no
  mínimo 8 caracteres contendo pelo menos 1 letra e 1 número**.
- A senha é armazenada como hash **bcrypt** (`security.py`).
- O login devolve um **JWT** assinado com `JWT_SECRET` (do `.env`), com
  validade de `JWT_EXPIRES_DAYS` dias (padrão 7).
- Endpoints protegidos usam `Depends(get_current_user)`: o token vem no
  header `Authorization: Bearer <token>`.
- O endpoint de export também aceita o token via query string (`?token=`),
  porque o navegador não envia headers em downloads de link.

## Validação da predição

`POST /predict` recebe `{"inputs": {...}}` com os 22 parâmetros. Antes de
chegar na rede neural, o `schemas.py` valida faixas físicas plausíveis:

- Campos como `L`, `T_in`, `rho_B` devem ser **maiores que zero**;
- Coeficientes como `D_ax`, `kL`, `C_in` **não podem ser negativos**;
- `eps` (porosidade) deve estar **entre 0 e 1**;
- Nenhum valor pode ser NaN ou infinito.

Valores fora da faixa retornam **422** com mensagem clara. A biblioteca
`nnadsorption` ainda valida se todos os campos esperados estão presentes.

## Banco de dados

SQLite em `backend/app.db`, criado automaticamente na primeira execução.

| Tabela | Colunas principais |
|--------|--------------------|
| `users` | id, email (único), senha_hash, criado_em |
| `predictions` | id, user_id, inputs_json, outputs_json, criado_em |

Inputs e outputs são guardados como JSON — simples e suficiente, já que o
backend nunca consulta campos individuais deles.

## Segurança

Rate limit, headers de segurança e CORS estrito — detalhes em
[seguranca.md](seguranca.md).

## Testes

```bash
cd backend
python -m pytest -v
```

O `conftest.py` troca o banco por um SQLite **em memória** e zera o contador
do rate limit entre os testes, então a suíte não toca no `app.db` real.
