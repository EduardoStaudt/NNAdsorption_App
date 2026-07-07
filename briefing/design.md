# Design — NNAdsorption: Biblioteca + App Web

**Data:** 2026-06-15 (atualizado)
**Autor:** Brainstorming com Claude
**Projeto:** IC — UTFPR Santa Helena
**Status:** Aprovado para implementação

---

## Contexto

Rede neural (MLP, TensorFlow) que prediz desempenho de colunas de adsorção em leito fixo.
- **22 inputs** físicos (L, eps, u, T_in, C_in, ...)
- **157 outputs:** 4 escalares finais + perfis C_z, q_z, T_z (51 pontos cada)
- R² = 0.984 — modelo excelente, pronto pra usar
- Treino roda na máquina do orientador (RTX mais forte)
- Artefatos gerados: `best_model.keras`, `scaler_input.save`, `scaler_output.save`, `model_meta.json`

---

## Estrutura de Repositórios

```
repo 1: NNAdsorption          ← treino/Optuna (já existe, NÃO mexer)
repo 2: NNAdsorption_Library  ← biblioteca Python (instalável com pip/uv)
repo 3: NNAdsorption_App      ← monorepo: backend/ + frontend/
```

**Por quê 3 repos:**
- `NNAdsorption` = laboratório de treino, não é produto
- `NNAdsorption_Library` = produto reutilizável, versionado, vai sobreviver ao projeto futuro (multi-gás, multi-solvente)
- `NNAdsorption_App` = backend e frontend mudam juntos → monorepo

---

## Repo 2 — `NNAdsorption_Library`

**Status:** ✅ Implementada, testada e funcionando.

### Princípio central
> Orientador treina → gera artefatos → você dropa em `artifacts/` → funciona. Zero código alterado.

### Estrutura
```
NNAdsorption_Library/
    nnadsorption/
        __init__.py        ← expõe AdsorptionPredictor
        predictor.py       ← carrega modelo + scalers, faz predict
        exporters.py       ← to_csv(), to_xlsx()
        plots.py           ← 4 gráficos modulares
                              C_z, q_z, T_z, breakthrough (+1 a definir)
        artifacts/         ← TUDO que o orientador gera vai aqui
            best_model.keras
            scaler_input.save
            scaler_output.save
            model_meta.json  ← fonte da verdade: define inputs/outputs
    examples/
        basic_usage.py
    tests/
        test_predictor.py
    pyproject.toml
    .gitignore
    README.md
```

### API pública
```python
from nnadsorption import AdsorptionPredictor, plots

pred = AdsorptionPredictor()                       # carrega artifacts/ automaticamente
result = pred.predict({"L": 0.3, "u": 0.1, ...})   # 22 inputs → dict resultado
pred.predict_to_csv(inputs, "saida.csv")
pred.predict_to_xlsx(inputs, "saida.xlsx")
fig = plots.plot_breakthrough(result)              # 4 funções em plots.py
plots.save_all_plots(result, out_dir="figs")
```

### Modularidade-chave
`predictor.py` lê `model_meta.json` para saber quais inputs exigir.
Quando o modelo mudar (ex: 18 inputs no projeto futuro), só os artefatos mudam — zero alteração de código.

### Instalação local (durante desenvolvimento)
```bash
uv pip install -e ".[dev]"
```

### Dependências
`tensorflow`, `joblib`, `numpy`, `pandas`, `openpyxl`, `matplotlib`, `scikit-learn==1.8.0` (versão fixada — mesma do treino, evita warnings de unpickle).

---

## Repo 3 — `NNAdsorption_App`

### Estrutura do monorepo
```
NNAdsorption_App/
    backend/     ← FastAPI (Python)
    frontend/    ← Flutter Web
    README.md
```

---

### Backend (FastAPI)

#### Responsabilidades
1. Autenticação de usuários (email + senha)
2. Executar predições usando `nnadsorption`
3. Salvar histórico de predições por usuário
4. Servir o frontend Flutter compilado (HTML/JS estático)

#### Banco de dados: SQLite
Simples, arquivo único, zero configuração no servidor da UTFPR.

**Tabelas:**
```sql
users
  id, email, senha_hash, email_verified (default true), criado_em

predictions
  id, user_id, inputs_json, outputs_json, criado_em
```

#### Segurança
- Senhas: hash com `bcrypt` via `passlib` (NUNCA salvar senha pura)
- Autenticação: JWT token (expiração configurável)
- LGPD: coleta mínima (só email + senha + predições do próprio usuário)

#### Verificação de email (estrutura pronta, desligada por agora)
- Coluna `email_verified` no modelo `User` (default `True` por enquanto)
- Endpoint `POST /auth/verify-email` esqueleto (retorna 501 Not Implemented)
- Comentário no código `# TODO: ativar verificação por email` indicando onde plugar
- Ativação futura: integrar com Resend/SendGrid quando houver domínio próprio

#### Endpoints
```
POST   /auth/register           cadastro                          → {token, user}
POST   /auth/login              login                             → {token, user}
GET    /auth/me                                                   → {user}            (requer JWT)
POST   /auth/verify-email       (placeholder, retorna 501)
POST   /predict                 roda predição                     → {prediction_id, result}  (requer JWT)
GET    /history                 lista predições do usuário        → [{...}]                 (requer JWT)
GET    /history/{id}            detalhe da predição               → {inputs, outputs}       (requer JWT)
DELETE /history/{id}            apaga predição                    → {ok: true}              (requer JWT)
GET    /meta                    nomes dos campos do modelo atual  → {input_cols, ...}
```

#### Dependências
`fastapi`, `uvicorn`, `sqlalchemy`, `passlib[bcrypt]`, `python-jose`, `nnadsorption`

---

### Frontend (Flutter Web)

#### Tema (claro + escuro)

**Inicia em modo claro.** Botão de alternar no topbar, à esquerda do avatar do usuário.

**Paleta escura** (do mockup HTML):
- BG `#0E1013`, panel `#15181D`, accent amarelo-limão `#E6D23C`
- texto `#E8EAED`, grid `#2A2E35`

**Paleta clara** (baseada no Hero.png):
- BG `#FFFFFF`, panel `#F5F5F7`, accent gradiente amarelo→verde
- texto `#0E1013`, grid `#E0E0E0`

Tema alternado via Provider; paletas em arquivos separados em `theme/colors.dart`.

#### Tipografia
Archivo (display) + IBM Plex Sans (UI) + IBM Plex Mono (dados numéricos).

#### Páginas (rotas)
1. **Landing** (`/`) — porta de entrada pública
2. **Login** (`/login`) — email + senha
3. **Cadastro** (`/register`) — email + senha + confirmação
4. **Plataforma** (`/app`) — tela principal, protegida (redireciona pra `/login` se sem JWT)

**Fluxo:** Landing → login/cadastro → Plataforma

---

#### Landing (`/`)

Inspirada em `hero.png`. Conteúdo:

1. **Topbar:** logo NNAdsorption (esquerda) + avatar/login (direita)
2. **Hero:**
   - Título "Otimize" em uma linha
   - **"suas operações"** abaixo com gradiente amarelo→verde
   - Subtítulo: "Sua plataforma de previsões de comportamento de colunas de adsorção em leito fixo a partir de modelos neurais."
   - Botão CTA escuro arredondado: **"Começar agora"** → vai pra `/register`
3. **Seção "No que vamos te ajudar":** grid de 4 cards
   - 📈 **Predições instantâneas** — "Resultados em segundos a partir dos 22 parâmetros da sua coluna"
   - 📊 **Visualização clara** — "Perfis de concentração, adsorção e temperatura ao longo do leito + curva de breakthrough"
   - 💾 **Exportação pronta** — "Baixe resultados em CSV ou XLSX direto da plataforma"
   - 🕓 **Histórico salvo** — "Acompanhe todas as predições feitas com sua conta"
4. **Seção "Nossa Motivação":** placeholder com texto "Em breve."
5. **Seção "Agradecimentos":** placeholder com texto "Em breve."
6. **Seção "Perguntas Frequentes":** 3 placeholders (perguntas-exemplo: "Como funciona?" / "O que é adsorção?" / "Preciso pagar?")
7. **Footer:** logo NNAdsorption + links (Termos / Sobre / Fale Conosco) + logo UTFPR

---

#### Plataforma (`/app`)

Segue `mockup.html` com as alterações abaixo.

#### Layout
```
┌────────────────────────────────────────────────────────────┐
│ Topbar: [logo] NNAdsorption  ...  [☀/🌙] [👤▾]            │
├──────────────┬─────────────────────────────────────────────┤
│ Parâmetros   │ [Gráficos][Tabela][Comparação]              │
│ (accordions) │ [Resultados Finais]                         │
│              │                                             │
│ Ações        │  conteúdo da aba ativa                      │
│ Presets      │                                             │
│ Histórico    │                                             │
└──────────────┴─────────────────────────────────────────────┘
```

**Mudanças em relação ao mockup:**
- ❌ Coluna direita (Saídas Finais/KPIs) removida → vira a 4ª aba "Resultados Finais"
- ✅ **Avatar do usuário no topbar à direita** (dropdown: Perfil / Logout)
- ✅ **Botão de tema (sol/lua) à esquerda do avatar** no topbar

#### Abas
- **Gráficos:** 4 gráficos renderizados **nativamente no Flutter via `fl_chart`** (não PNG do backend) — interativos com zoom/hover. Perfis C(z), q(z), T(z) ao longo do leito + curva de breakthrough C/C₀(t). Espaço pra +1 a definir. Cada gráfico independente.
- **Tabela:** DataTable com colunas z, C, q, T (51 linhas) — scroll vertical
- **Comparação:** seleciona 2 predições do histórico, mostra KPIs lado a lado com delta (Δ = atual − referência)
- **Resultados Finais:** cards grandes com C_out_final, q_out_final, T_out_final, N_ads_final, Qtot_final

#### Formulário de inputs
- Campos gerados **dinamicamente** a partir do endpoint `/meta` do backend (que lê `model_meta.json`)
- Organizados em accordions por grupo (decisão dos grupos a cargo do Claude Code, com base nos nomes — ex.: Geometria, Operação, Sólido, Fluido, Tempo)
- Quando o modelo mudar (ex: 18 inputs no projeto futuro), o frontend se adapta automaticamente sem mudança de código

#### Fluxo do usuário
1. Chega na **landing** (apresentação do projeto)
2. Faz cadastro ou login → redireciona pra plataforma
3. Preenche os 22 campos (ou carrega preset)
4. Clica "Rodar" → POST /predict → recebe resultado
5. Vê gráficos/tabela/resultados nas abas
6. Exporta CSV/XLSX ou salva no histórico
7. Alterna tema claro/escuro pelo botão no topbar
8. Acessa conta pelo avatar no topbar (Perfil / Logout)

---

## Identidade Visual

**Logo:** "NNAdsorption" — "NN" estilizado com pontos arredondados nas extremidades, evocando **nós de uma rede neural**. Duas versões: `logo_dark.png` (fundo escuro) e `logo_light.png` (fundo claro).

---

## Deploy — Servidor UTFPR

```
servidor UTFPR
├── backend FastAPI (processo Python)  porta 8000
├── SQLite  (arquivo local)
└── Nginx   (serve Flutter HTML/JS + proxy pro FastAPI)
```

**Custo:** sem custo de hospedagem externa — hardware da UTFPR via solicitação ao setor de TI
**Requisitos do servidor:** Python 3.11+, pip, nginx — tudo disponível em qualquer Linux

---

## Ordem de implementação

1. ✅ **`NNAdsorption_Library`** (concluída)
   - `predictor.py`, `exporters.py`, `plots.py`
   - Empacotada com `pyproject.toml`
   - Testes passando, exemplo rodando

2. **Backend FastAPI** (próximo)
   - Auth (register + login + JWT)
   - Endpoint `/meta` (expõe contrato do modelo)
   - Endpoint `/predict` usando a lib
   - Histórico (list + get + delete)
   - Esqueleto de verificação de email (desligado)

3. **Frontend Flutter Web**
   - Tema claro + escuro com Provider
   - Landing
   - Login + Cadastro integrados com backend
   - Plataforma — layout com as 4 abas
   - Formulário lendo de `/meta`
   - Chamada ao `/predict` e gráficos em `fl_chart`
   - Histórico

---

## Decisões registradas

| Decisão | Escolha | Motivo |
|---|---|---|
| Backend | FastAPI | Python nativo, usa a lib diretamente, simples |
| Banco | SQLite | Zero config, suficiente pra IC |
| Senhas | bcrypt via passlib | Padrão seguro, 3 linhas de código |
| Auth | JWT | Sem sessão no servidor, stateless |
| Verificação de email | Estrutura pronta, desligada | Ativa quando tiver domínio próprio |
| Monorepo backend+front | Sim | Mudam juntos, projeto de uma pessoa |
| Lib separada | Sim | Reutilizável no projeto futuro |
| Inputs do formulário | Lidos do `/meta` dinamicamente | Modular, sobrevive mudança de modelo |
| Tema inicial | Claro, com botão pra alternar | Combina com a landing (Hero.png) |
| Posição do menu de usuário | Topbar direita | Padrão da web, familiar |
| Gráficos no frontend | fl_chart (nativo Flutter) | Interativos com zoom/hover, melhor UX que PNG |
