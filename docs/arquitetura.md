# Arquitetura

Visão geral de como as partes do NNAdsorption App se conectam.

## Diagrama geral

```
┌─────────────────────┐        HTTP/JSON         ┌──────────────────────┐
│   Frontend           │ ───────────────────────> │   Backend            │
│   Flutter Web        │ <─────────────────────── │   FastAPI            │
│   (navegador)        │                          │   localhost:8000     │
└─────────────────────┘                          └──────────┬───────────┘
                                                            │
                                            ┌───────────────┼───────────────┐
                                            │               │               │
                                     ┌──────▼─────┐  ┌──────▼──────┐ ┌──────▼──────┐
                                     │  SQLite    │  │ nnadsorption│ │  Exporters  │
                                     │  app.db    │  │ (rede MLP)  │ │  CSV/XLSX   │
                                     └────────────┘  └─────────────┘ └─────────────┘
```

- O **frontend** roda inteiro no navegador. Ele nunca acessa o banco ou o
  modelo diretamente — tudo passa pela API.
- O **backend** valida cada requisição, roda a rede neural pela biblioteca
  `nnadsorption` e guarda os resultados no SQLite.
- A **biblioteca `nnadsorption`** é um repositório separado, já finalizado.
  O backend só a consome (`get_predictor()`, `to_csv()`, `to_xlsx()`).

## Fluxo de autenticação

```
Usuário          Frontend                Backend                 SQLite
  │  cadastro      │                        │                      │
  ├───────────────>│ POST /auth/register    │                      │
  │                ├───────────────────────>│  hash bcrypt         │
  │                │                        ├─────────────────────>│ INSERT user
  │                │   { token, user }      │                      │
  │                │<───────────────────────┤  assina JWT          │
  │  token salvo no shared_preferences      │                      │
```

1. A senha nunca é guardada em texto puro — só o hash bcrypt.
2. O backend devolve um **JWT** válido por 7 dias (configurável no `.env`).
3. O frontend guarda o token no `shared_preferences` do navegador e o envia
   em todas as chamadas seguintes no header `Authorization: Bearer <token>`.
4. Ao recarregar a página, o `AuthProvider` restaura a sessão chamando
   `/auth/me` com o token salvo.

## Fluxo de predição — DESLIGADO no momento

```
Usuário          Frontend                Backend                nnadsorption
  │ preenche os    │                        │                      │
  │ parâmetros e   │   ✗ o botão "Rodar"    │                      │
  │ clica "Rodar"  │     está desligado     │                      │
  ├───────────────>│ ····X                  │                      │
  │                │                        │                      │
  │                │ POST /predict continua existindo no backend,   │
  │                │ mas o frontend não chama mais.                 │
```

O modelo mono-gás (22 parâmetros) está congelado, e o frontend já migrou pra
estrutura de 28 do modelo N-componentes — os dois não conversam. Enquanto a rede
binária não existir, `/predict` fica desconectado e o botão aparece inerte, com
nota explicando.

**Consequência prática:** resultados só entram em tela carregando uma predição
antiga do histórico. Os estados vazios das abas dizem exatamente isso.

Quando religar:

- A **primeira** predição depois que o servidor sobe é mais lenta (~20-30s)
  porque o TensorFlow carrega o modelo na memória. As seguintes levam
  milissegundos.
- Toda predição bem-sucedida é salva no histórico do usuário.
- O nome do experimento (campo no topo do painel) hoje é estado local da sessão;
  ele precisa passar a acompanhar a predição no banco.

## Fluxo de histórico

```
Usuário          Frontend                Backend                SQLite
  │ abre o        │                        │                      │
  │ Histórico     │ GET /history           │                      │
  ├──────────────>├───────────────────────>│ filtra por user_id   │
  │               │                        ├─────────────────────>│ SELECT
  │  lista de predições salvas             │                      │
  │               │                        │                      │
  │ clica numa    │ GET /history/{id}      │                      │
  ├──────────────>├───────────────────────>│  { inputs, outputs } │
  │  gráficos, tabela e KPIs renderizados  │                      │
```

## Fluxo de exportação

O botão "Exportar" abre `GET /predict/{id}/export?format=csv|xlsx` numa nova
aba. O backend lê os resultados **já salvos** no banco (não roda a rede de
novo), gera o arquivo com os exporters da biblioteca e devolve como download.

## Decisões de projeto

| Decisão | Por quê |
|---------|---------|
| SQLite | zero configuração, suficiente para o volume esperado |
| JWT sem refresh token | simplicidade; expiração de 7 dias é aceitável aqui |
| provider (não Riverpod) | mais didático para quem está aprendendo Flutter |
| Monorepo backend+frontend | facilita manter as duas partes sincronizadas |
