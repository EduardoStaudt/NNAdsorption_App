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

## Fluxo de predição

```
Usuário          Frontend                Backend                nnadsorption
  │ preenche 22    │                        │                      │
  │ parâmetros e   │                        │                      │
  │ clica "Rodar"  │                        │                      │
  ├───────────────>│ POST /predict          │                      │
  │                ├───────────────────────>│ valida faixas físicas│
  │                │                        ├─────────────────────>│ predict()
  │                │                        │<─────────────────────┤ perfis + KPIs
  │                │                        ├──> INSERT prediction (SQLite)
  │                │  { prediction_id,      │                      │
  │                │    result }            │                      │
  │                │<───────────────────────┤                      │
  │  gráficos, tabela e KPIs renderizados   │                      │
```

Observações:

- A **primeira** predição depois que o servidor sobe é mais lenta (~20-30s)
  porque o TensorFlow carrega o modelo na memória. As seguintes levam
  milissegundos.
- Toda predição bem-sucedida é salva no histórico do usuário.

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
