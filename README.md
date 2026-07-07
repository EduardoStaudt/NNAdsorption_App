# NNAdsorption App

Plataforma web para **predição do comportamento de colunas de adsorção em
leito fixo** usando uma rede neural MLP. O usuário informa os 22 parâmetros
físicos da coluna (geometria, condições de operação, propriedades do sólido e
do fluido) e recebe em segundos os perfis de concentração, adsorção e
temperatura ao longo do leito, além da curva de breakthrough — resultados que
tradicionalmente exigiriam a resolução numérica de um sistema de equações
diferenciais parciais.

O projeto nasceu como Iniciação Científica na **UTFPR — Campus Santa Helena**.
A rede neural foi treinada com dados gerados por um simulador numérico
validado, e fica encapsulada na biblioteca Python `nnadsorption` (repositório
separado). Este repositório contém a aplicação web que expõe o modelo: um
backend FastAPI com autenticação e histórico, e um frontend Flutter Web com
visualização interativa dos resultados.

O app é gratuito e voltado a fins acadêmicos e científicos: estudantes e
pesquisadores podem explorar cenários de adsorção sem precisar instalar
nada além de um navegador.

## Screenshots

> TODO: screenshot da landing page aqui
>
> TODO: screenshot da plataforma (aba Gráficos, tema escuro) aqui
>
> TODO: screenshot da plataforma em tela de celular aqui

## Stack tecnológica

| Camada | Tecnologia |
|--------|------------|
| Backend | FastAPI + SQLite + SQLAlchemy |
| Autenticação | JWT (python-jose) + bcrypt (passlib) |
| Rate limit | slowapi |
| Inferência | biblioteca `nnadsorption` (TensorFlow/Keras) |
| Frontend | Flutter Web |
| Estado | provider |
| Rotas | go_router |
| Gráficos | fl_chart |

**Gerenciamento de estado:** `provider` — escolhido por ser o mais simples e
didático. Riverpod é mais poderoso, mas provider basta para este projeto e é
mais fácil de entender.

## Estrutura de pastas

```
NNAdsorption_App/
    backend/            API FastAPI
        app/
            main.py         ponto de entrada + middlewares
            config.py       variáveis de ambiente (.env)
            database.py     conexão SQLite
            models.py       tabelas (User, Prediction)
            schemas.py      validação Pydantic
            security.py     hash de senha + JWT
            rate_limit.py   limite de requisições por IP
            routers/        endpoints (auth, predict, history, meta)
        tests/          testes (pytest)
    frontend/           app Flutter Web
        lib/
            main.dart       providers, tema e rotas
            theme/          paleta de cores e ThemeData
            screens/        landing, login, register, plataforma
            widgets/        painéis, gráficos, componentes visuais
            providers/      estado (auth, tema)
            services/       chamadas HTTP à API
            models/         classes de dados
        test/           testes de widget
    briefing/           material de design (mockup, logos)
    docs/               documentação detalhada
```

## Como rodar

### Pré-requisito

A biblioteca `nnadsorption` precisa estar extraída ao lado deste repositório:

```
ProjetoNakajima/
    NNAdsorption_App/     ← este repo
    NNAdsorption_Library/ ← biblioteca (já existente)
```

### Backend

```bash
cd backend

# Cria ambiente virtual com Python 3.11+
python -m venv .venv
.venv\Scripts\activate        # Windows
# source .venv/bin/activate   # Linux/Mac

pip install -r requirements.txt
pip install -e ..\..\NNAdsorption_Library   # ajuste o caminho se necessário

cp .env.example .env
uvicorn app.main:app --reload
```

- Servidor: `http://localhost:8000`
- Documentação interativa (Swagger): `http://localhost:8000/docs`

Testes:

```bash
python -m pytest -v
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Testes e análise estática:

```bash
flutter test
flutter analyze
```

## Endpoints principais

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | /auth/register | Não | Cadastra usuário |
| POST | /auth/login | Não | Login |
| GET | /auth/me | Sim | Dados do usuário logado |
| POST | /predict | Sim | Roda predição |
| GET | /predict/{id}/export?format= | Sim | Exporta CSV/XLSX |
| GET | /history | Sim | Lista predições |
| GET | /history/{id} | Sim | Detalhe de uma predição |
| DELETE | /history/{id} | Sim | Apaga uma predição |
| GET | /meta | Não | Campos do modelo |
| GET | /health | Não | Health check |

## Documentação detalhada

- [Arquitetura](docs/arquitetura.md) — visão geral e fluxos
- [Backend](docs/backend.md) — endpoints, autenticação e banco
- [Frontend](docs/frontend.md) — telas, providers e componentes
- [Segurança](docs/seguranca.md) — medidas implementadas
- [Deploy](docs/deploy.md) — como implantar em produção

## Créditos

- **Autor:** Eduardo Andrei Staudt
- **Orientador:** Prof. Evandro Alves Nakajima
- **Instituição:** Universidade Tecnológica Federal do Paraná (UTFPR) — Campus Santa Helena
