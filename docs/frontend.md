# Frontend

App Flutter Web que consome a API e apresenta os resultados.

## Estrutura

```
frontend/lib/
    main.dart               providers, tema, rotas e transições de página
    config.dart             URL do backend (kBackendUrl)
    theme/
        colors.dart         AppColors: paleta clara/escura como ThemeExtension
        app_theme.dart      ThemeData montado a partir da paleta
    providers/
        auth_provider.dart  sessão do usuário (token, login, logout)
        theme_provider.dart alterna claro/escuro
    screens/
        landing_screen.dart página pública inicial
        login_screen.dart   formulário de login
        register_screen.dart formulário de cadastro
        platform_screen.dart tela principal (parâmetros + resultados)
    widgets/
        topbar.dart         barra superior (logo, status, tema, avatar)
        parameters_panel.dart accordions com os 22 inputs
        results_panel.dart  abas Gráficos / Tabela / Comparação / Resultados
        history_drawer.dart drawer lateral com o histórico
        export_button.dart  dropdown de exportação CSV/XLSX
        ui_comum.dart       widgets visuais compartilhados
        charts/line_profile_chart.dart  gráfico de linha genérico (fl_chart)
    services/
        api_service.dart    todas as chamadas HTTP à API
        storage_service.dart persiste o token no shared_preferences
    models/
        prediction.dart     PredictionSummary e PredictionResult
        user.dart           dados do usuário
```

## Rotas (go_router)

| Rota | Tela | Proteção |
|------|------|----------|
| `/` | Landing | pública |
| `/login` | Login | redireciona pra `/app` se já logado |
| `/register` | Cadastro | idem |
| `/app` | Plataforma | exige login (senão vai pra `/login`) |

O `redirect` do go_router usa o `AuthProvider` como `refreshListenable`:
quando o login/logout muda, as rotas reavaliam automaticamente. As
transições entre telas usam fade + deslize sutil (`_paginaSuave` em
`main.dart`).

## Providers

- **ThemeProvider** — guarda o `ThemeMode`. O app inicia no claro; o botão
  sol/lua na topbar chama `alternar()`.
- **AuthProvider** — guarda token e usuário. `inicializar()` restaura a
  sessão salva no navegador ao abrir o app.

## Sistema de cores

Todas as cores vivem em `theme/colors.dart` como um `ThemeExtension`
chamado `AppColors`, com uma instância `escuro` (valores do mockup) e uma
`claro`. Qualquer widget acessa a paleta do tema atual com:

```dart
final cores = context.cores;   // ex.: cores.accent, cores.panel2
```

Isso evita o padrão repetitivo `isDark ? corEscura : corClara` em cada widget.

## Tipografia

- **Archivo** (700–900): títulos, valores de KPI, marca
- **IBM Plex Sans** (400–600): textos de UI e botões
- **IBM Plex Mono**: números, unidades, labels técnicos e eixos

As fontes vêm do pacote `google_fonts` (baixadas em runtime).

## Responsividade

`platform_screen.dart` define os breakpoints:

| Largura | Layout |
|---------|--------|
| ≥ 1200px | painel de parâmetros fixo (352px) + resultados ao lado |
| 800–1199px | só resultados; parâmetros abrem num Drawer lateral |
| < 800px | só resultados; parâmetros abrem num bottom sheet |

A grade de gráficos vira 1 coluna abaixo de 700px, e a barra de
abas/ações quebra em duas linhas abaixo de 680px.

## Componentes visuais compartilhados (`ui_comum.dart`)

| Widget | O que faz |
|--------|-----------|
| `Painel` | container padrão (fundo panel, borda, cantos 14px) |
| `CabecalhoSecao` | eyebrow + título de seção do mockup |
| `Eyebrow` | tracinho accent + texto mono maiúsculo |
| `FundoPontilhado` | grade de pontinhos + brilho no topo (fundo do app) |
| `Hover` | detecta hover do mouse pra efeitos visuais |
| `EscalaAoClicar` | afunda o botão levemente ao clicar |
| `Skeleton` | bloco pulsante mostrado enquanto algo carrega |
| `EntradaSuave` | fade + subida de 10px na entrada (efeito "rise") |

## Gráficos

Um único widget `LineProfileChart` (fl_chart) desenha as 4 curvas —
concentração, adsorção, temperatura e breakthrough — mudando só os dados,
eixos e cor. A transição entre predições é animada (300ms).

## Testes

```bash
cd frontend
flutter test      # 3 testes de widget (landing, login, register)
flutter analyze   # análise estática, deve dar 0 issues
```
