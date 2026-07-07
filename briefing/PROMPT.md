# Tarefa: Implementar NNAdsorption_App (backend FastAPI + frontend Flutter Web)

Você está implementando o repositório `NNAdsorption_App`. Estrutura existente:

```
NNAdsorption_App/
    backend/      (vazia)
    frontend/     (vazia)
    README.md     (existe)
```

> ## ⚠️ Use a skill `/simplify` em TODO o código
> O usuário é aluno do 3º período de Ciência da Computação. Quer código simples
> e legível, não código "profissional ninja". Priorize sempre: clareza > esperteza.
> Comentários em português, nomes de variáveis explícitos, evite abstrações
> desnecessárias. Se um padrão "elegante" sacrifica legibilidade, use o jeito
> simples.

---

## Arquivos fornecidos (anexados nesta pasta)

- **`design.md`** — design completo do projeto (LEIA PRIMEIRO, é a fonte da verdade)
- **`NNAdsorption_Library.zip`** — biblioteca Python já pronta. Extraia ao lado do
  repo (não dentro) e instale localmente com `pip install -e ../NNAdsorption_Library`
- **`logo_dark.png`** — logo do projeto (versão escura, fundo escuro)
- **`logo_light.png`** — logo do projeto (versão clara, fundo claro)
- **`mockup.html`** — mockup HTML da interface da plataforma (paleta, layout, abas)
- **`hero.png`** — mockup da landing page

---

## Stack confirmada

- **Backend:** FastAPI (Python 3.10+)
- **Banco:** SQLite (arquivo local `app.db`)
- **Auth:** email + senha, hash via `passlib[bcrypt]`, sessão via JWT (`python-jose`)
- **ORM:** SQLAlchemy
- **Lib de inferência:** `nnadsorption` (já pronta, ver acima)
- **Frontend:** Flutter Web
- **Gráficos:** `fl_chart` (renderiza nativo, interativo)
- **Estado/auth:** simples, recomendo `provider` ou `flutter_riverpod` — escolha o
  mais simples e justifique numa linha no README

---

## Estrutura de pastas que você deve criar

```
backend/
    app/
        __init__.py
        main.py              ponto de entrada do FastAPI
        config.py            configurações (JWT_SECRET, DB_URL etc)
        database.py          engine + sessão SQLAlchemy
        models.py            tabelas User, Prediction
        schemas.py           modelos Pydantic (validação de request/response)
        security.py          hash de senha + JWT
        routers/
            __init__.py
            auth.py          /auth/register, /auth/login, /auth/me
            predict.py       /predict
            history.py       /history (GET lista, GET por id, DELETE por id)
            meta.py          /meta (devolve param_cols do model_meta.json)
    requirements.txt
    .env.example
    README.md

frontend/
    (rodar `flutter create .` aqui pra inicializar)
    lib/
        main.dart
        config.dart                 URL do backend, etc
        theme/
            colors.dart             paletas claro + escuro
            app_theme.dart          ThemeData claro e escuro
        models/                     classes Dart pros dados
            user.dart
            prediction.dart
        services/
            api_service.dart        chamadas HTTP ao backend
            auth_service.dart       login/logout, token JWT
            storage_service.dart    salva token no localStorage
        providers/                  (ou riverpod, escolha)
            auth_provider.dart
            theme_provider.dart
        screens/
            landing_screen.dart     /
            login_screen.dart       /login
            register_screen.dart    /register
            platform_screen.dart    /app   (a plataforma principal)
        widgets/
            topbar.dart             logo + status + tema + avatar
            parameters_panel.dart   coluna esquerda (accordions dos inputs)
            results_panel.dart      coluna direita (4 abas)
            charts/
                c_profile_chart.dart
                q_profile_chart.dart
                t_profile_chart.dart
                breakthrough_chart.dart
            history_drawer.dart
    assets/
        images/
            logo_dark.png
            logo_light.png
    pubspec.yaml
```

---

## Backend — especificação

### Models (SQLAlchemy)

```python
class User:
    id: int (pk)
    email: str (único)
    senha_hash: str
    email_verified: bool = True   # placeholder pra ativar verificação no futuro
    criado_em: datetime

class Prediction:
    id: int (pk)
    user_id: int (fk -> User)
    inputs_json: str    # JSON serializado dos 22 inputs
    outputs_json: str   # JSON serializado do resultado completo
    criado_em: datetime
```

### Endpoints

```
POST   /auth/register   body: {email, password}                  -> {token, user}
POST   /auth/login      body: {email, password}                  -> {token, user}
GET    /auth/me                                                  -> {user}            (requer JWT)
POST   /predict         body: {inputs: {...22 chaves}}           -> {prediction_id, result}  (requer JWT)
GET    /history                                                  -> [{id, criado_em, ...}]   (requer JWT)
GET    /history/{id}                                             -> {inputs, outputs}        (requer JWT)
DELETE /history/{id}                                             -> {ok: true}               (requer JWT)
GET    /meta                                                     -> {input_cols, final_cols, block_size}
```

### Predict — fluxo
1. Recebe `{inputs: {...}}`
2. Valida que tem as 22 chaves (use Pydantic, leia os nomes de `predictor.meta`)
3. Chama `predictor.predict(inputs)` (use o singleton `get_predictor()` da lib)
4. Salva a predição no banco (inputs + outputs em JSON string)
5. Devolve `{prediction_id, result}`

### Verificação de email (estrutura pronta, desligada)

- Modelo `User` tem `email_verified` (default `True`)
- Crie um endpoint `POST /auth/verify-email` esqueleto que retorna 501 Not Implemented
- Adicione comentário `# TODO: ativar verificação por email (Resend/SendGrid)` em
  `auth.py` mostrando onde plugar quando ativar

### Segurança

- Senha mínima: 8 caracteres (validação no Pydantic)
- Hash: bcrypt via `passlib`
- JWT: assinado com chave de `JWT_SECRET` do `.env`, expiração 7 dias
- CORS: liberar localhost:* pra dev; lista de origins do `.env` pra prod
- NUNCA logar senha nem retornar `senha_hash` em response

### Configuração

`.env.example`:
```
JWT_SECRET=mude-isso-em-producao
JWT_EXPIRES_DAYS=7
DATABASE_URL=sqlite:///./app.db
ALLOWED_ORIGINS=http://localhost:*
```

---

## Frontend — especificação

### Tema (claro + escuro)

**Inicia em claro.** Botão de alternar no topbar (lado esquerdo do avatar).

**Paleta escura** (do mockup):
- BG `#0E1013`, panel `#15181D`, accent amarelo `#E6D23C`
- texto `#E8EAED`, grid `#2A2E35`

**Paleta clara** (você cria, baseada no Hero.png):
- BG `#FFFFFF`, panel `#F5F5F7`, accent amarelo-verde gradiente (do hero)
- texto `#0E1013`, grid `#E0E0E0`

Use `ThemeData` do Flutter, mantenha **as duas paletas em arquivos separados**
em `theme/colors.dart`. Tema é alternado via Provider.

### Rotas

```
/           -> landing_screen.dart
/login      -> login_screen.dart
/register   -> register_screen.dart
/app        -> platform_screen.dart  (protegida: redireciona pra /login se sem JWT)
```

### Landing (`/`)

Inspire-se em `hero.png`. Conteúdo:

1. **Topbar:** logo NNAdsorption (esquerda) + avatar/login (direita)
2. **Hero:**
   - Título: "Otimize" em uma linha, **"suas operações"** abaixo com gradiente
     amarelo→verde
   - Subtítulo: "Sua plataforma de previsões de comportamento de colunas de
     adsorção em leito fixo a partir de modelos neurais."
   - Botão CTA escuro arredondado: **"Começar agora"** -> vai pra `/register`
3. **Seção "No que vamos te ajudar":** grid de 4 cards
   - 📈 **Predições instantâneas** — "Resultados em segundos a partir dos 22
     parâmetros da sua coluna"
   - 📊 **Visualização clara** — "Perfis de concentração, adsorção e
     temperatura ao longo do leito + curva de breakthrough"
   - 💾 **Exportação pronta** — "Baixe resultados em CSV ou XLSX direto da
     plataforma"
   - 🕓 **Histórico salvo** — "Acompanhe todas as predições feitas com sua conta"
4. **Seção "Nossa Motivação":** placeholder com texto "Em breve."
5. **Seção "Agradecimentos":** placeholder com texto "Em breve."
6. **Seção "Perguntas Frequentes":** 3 placeholders de FAQ (perguntas inventadas
   tipo "Como funciona?" / "O que é adsorção?" / "Preciso pagar?") cada uma com
   resposta curta placeholder
7. **Footer:** logo + links (Termos de Uso / Sobre / Fale Conosco) + logo UTFPR

### Plataforma (`/app`)

Siga `mockup.html` exatamente, com estas mudanças:

**Layout:**
```
┌─────────────────────────────────────────────────┐
│ Topbar: [logo] NNAdsorption  ...  [☀/🌙] [👤▾] │
├──────────────┬──────────────────────────────────┤
│ Parâmetros   │ [Gráficos][Tabela][Comparação]   │
│ (accordions) │ [Resultados Finais]              │
│              │                                   │
│ Ações        │  conteúdo da aba ativa            │
│ Presets      │                                   │
│ Histórico    │                                   │
└──────────────┴──────────────────────────────────┘
```

**Mudanças em relação ao mockup:**
- ❌ Remova a coluna direita (saídas/KPIs) — vira a 4ª aba "Resultados Finais"
- ✅ Adicione 4ª aba "Resultados Finais" mostrando: C_out_final, q_out_final,
  T_out_final, N_ads_final, Qtot_final como cards numéricos grandes
- ✅ Avatar do usuário no topbar à direita, com dropdown:
  Perfil / Logout
- ✅ Botão de alternar tema ao lado esquerdo do avatar (ícone sol/lua)

**Coluna de parâmetros (esquerda):**
- Use `ExpansionTile` (accordions do Flutter)
- Agrupe os 22 inputs do `/meta` em 4 grupos lógicos (decida você os grupos com
  base nos nomes; ex.: Geometria=L,Nz,D_col; Operação=u,T_in,C_in,dt,t_end; etc.)
- Cada campo: label + input numérico + unidade opcional
- Botão "Rodar predição" no final
- Botão "Resetar valores"

**Abas (centro/direita):**
- **Gráficos:** 4 gráficos `fl_chart` (line chart): C(z), q(z), T(z), breakthrough
  - Cada gráfico com tooltip ao passar o mouse
  - Eixos com labels e unidades
  - Cores: C azul `#4FB7FF`, q amarelo `#E6D23C`, T vermelho `#FF6B6B`,
    breakthrough amarelo accent
- **Tabela:** DataTable com colunas z, C, q, T (51 linhas) — scroll vertical
- **Comparação:** seleciona 2 predições do histórico, mostra os 4 KPIs lado a
  lado com delta (Δ = atual - referência)
- **Resultados Finais:** cards grandes com os 5 escalares

**Botão "Exportar":** chama `/predict` e depois um endpoint que devolve CSV/XLSX
(decida: ou o backend devolve direto pelo `/predict?format=csv`, ou tem
endpoint `/predict/{id}/export?format=csv` — escolha a mais simples)

### Login (`/login`) e Register (`/register`)

- Formulário simples centralizado
- Email + senha (registro também com confirmação de senha)
- Validação no front: email válido, senha ≥ 8 caracteres
- Em caso de erro, mostra mensagem clara (ex.: "Email já cadastrado")
- Em caso de sucesso, salva token no `localStorage` e redireciona pra `/app`
- Link entre eles ("não tem conta? cadastre-se" / "já tem conta? entrar")

---

## Como rodar (documente no README)

Backend:
```bash
cd backend
python -m venv .venv
source .venv/bin/activate    # Linux/Mac
# .venv\Scripts\activate     # Windows
pip install -r requirements.txt
pip install -e ../../NNAdsorption_Library    # lib local
cp .env.example .env
uvicorn app.main:app --reload
```
→ Backend roda em `http://localhost:8000`, docs em `/docs`

Frontend:
```bash
cd frontend
flutter pub get
flutter run -d chrome
```
→ Frontend abre no Chrome

---

## Testes obrigatórios

**Backend:** pelo menos 5 testes em `backend/tests/test_basic.py`:
1. Registro funciona, retorna token
2. Login funciona, retorna token
3. Endpoint protegido sem token retorna 401
4. `/predict` com inputs válidos retorna resultado e salva no histórico
5. `/history` retorna predições do usuário logado

**Frontend:** ao menos um teste de widget pra cada tela (smoke test que ela
renderiza sem crashar).

---

## Critérios de aceite

1. ✅ `pip install -r requirements.txt && uvicorn app.main:app` sobe sem erro
2. ✅ `flutter run -d chrome` abre o app sem erro
3. ✅ Consigo cadastrar usuário, fazer login, fazer uma predição, ver os
   gráficos, exportar CSV/XLSX, ver no histórico
4. ✅ Tema claro/escuro alterna corretamente
5. ✅ Landing → Login → Plataforma funciona como fluxo
6. ✅ Todos os testes do backend passam
7. ✅ Código segue `/simplify`: legível, comentado em pt-BR, sem abstração
   desnecessária

---

## Ordem sugerida de implementação

1. **Backend** primeiro, do mais simples ao mais complexo:
   a. Estrutura básica + `/health` que retorna `{ok: true}`
   b. Modelos + database + migrations
   c. `/auth/register` e `/auth/login`
   d. `/meta` (pega de `predictor.meta`)
   e. `/predict` (chama a lib)
   f. `/history` (lista, get, delete)
   g. Testes
2. **Frontend** depois:
   a. `flutter create .` + estrutura de pastas
   b. Tema claro + escuro funcionando
   c. Landing
   d. Login + Register integrados com backend
   e. Plataforma — layout vazio com as abas
   f. Formulário de parâmetros lendo de `/meta`
   g. Chamada ao `/predict` e popular gráficos
   h. Histórico
   i. Exportação

Implemente uma etapa, mostre que funciona, passa pra próxima.

---

## Observações finais

- Comentários em **português brasileiro**
- Nomes de variáveis em inglês simples (padrão da comunidade), mas comentários
  em pt-BR
- Não invente features que não estão aqui
- Se tiver dúvida que afeta o design, pergunte ao usuário antes de chutar
- Use o `design.md` como referência principal
