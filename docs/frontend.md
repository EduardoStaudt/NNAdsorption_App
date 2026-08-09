# Frontend

App Flutter Web que consome a API e apresenta os resultados.

## Estrutura

```
frontend/lib/
    main.dart               providers, tema, rotas e transições de página
    config.dart             URL do backend (kBackendUrl)
    theme/
        colors.dart         AppColors: paleta clara/escura como ThemeExtension
        app_sizes.dart      tokens de tamanho (espaço, raio, tipo, ícone, ...)
        app_theme.dart      ThemeData montado a partir da paleta e dos tokens
    providers/
        auth_provider.dart  sessão do usuário (token, login, logout)
        theme_provider.dart alterna claro/escuro e persiste a escolha
    screens/
        landing_screen.dart página pública inicial — REFERÊNCIA DE ESTILO, não editar
        login_screen.dart   formulário de login
        register_screen.dart formulário de cadastro
        platform_screen.dart tela principal (trilho + painel + resultados)
    widgets/
        topbar.dart         barra superior (alternar, logo, status, tema, avatar)
        rail_lateral.dart   trilho de ícones e a prévia do hover
        parameters_panel.dart accordions dos 28 inputs + validação
        results_panel.dart  abas Gráficos / Tabela / Comparação / Resultados
        history_drawer.dart lista de predições (conteúdo + moldura de drawer)
        export_button.dart  dropdown de exportação CSV/XLSX
        auth_comum.dart     moldura e campos de login/cadastro
        ui_comum.dart       widgets visuais compartilhados
        charts/line_profile_chart.dart  gráfico de linha genérico (fl_chart)
    services/
        api_service.dart    todas as chamadas HTTP à API
        storage_service.dart persiste token e tema no shared_preferences
    models/
        param_defs.dart     FONTE DA VERDADE dos 28 parâmetros
        prediction.dart     PredictionSummary e PredictionResult
        user.dart           dados do usuário
```

## Os 28 parâmetros

`models/param_defs.dart` é a fonte da verdade — campos, símbolos, unidades e
intervalos vêm da tabela do artigo (*Computers & Chemical Engineering*).

| Bloco | Campos |
|-------|--------|
| Isoterma e cinética, **por componente** | 8 (`qm_ref`, `k2`, `b_ref`, `k4`, `n_ref`, `k6`, `kL`, `dH`) |
| Adsorvente (fixo) | 3 (`eps`, `rho_b`, `cp_s`) |
| Operação e geometria (fixo) | 9 (`vs`, `T_in`, `P`, `L`, `h_w`, `lam`, `dp`, `Dm`, `y0`) |

Com `kNumComponentes = 2` → 8×2 + 12 = **28**. A UI e as chaves de payload se
geram a partir dessa constante.

> **Atenção antes de subir `kNumComponentes`:** `y0` é um campo só porque com 2
> gases a outra fração sai de `y1 = 1 − y0`. Com N > 2 são precisas N−1 frações
> independentes, e `kOperationFields` é uma lista fixa que não indexa por
> componente. Sem resolver isso primeiro, o payload sai incompleto em silêncio.

Validação: cada campo compara com o `min`/`max` do seu `ParamDef` a cada tecla.
Fora do intervalo → borda e texto em `cores.erro`, com ícone e a faixa válida na
mensagem. Grupo fechado mostra "N com erro" no cabeçalho, e o erro sobe do nível
aninhado pro card que o contém.

## Rotas (go_router)

| Rota | Tela | Proteção |
|------|------|----------|
| `/` | Landing | pública |
| `/login` | Login | redireciona pra `/app` se já logado |
| `/register` | Cadastro | idem |
| `/app` | Plataforma | exige login (senão vai pra `/login`) |

## Providers

- **ThemeProvider** — guarda o `ThemeMode`. **Nasce no escuro** (dark-first) e a
  escolha do usuário persiste no `shared_preferences`. As gravações são
  enfileiradas: dois toques rápidos disparariam dois `setBool` concorrentes sem
  ordem garantida.
- **AuthProvider** — guarda token e usuário. `inicializar()` restaura a sessão
  salva ao abrir o app.

## Sistema de cores e tamanhos

Cores em `theme/colors.dart` como `ThemeExtension`, acessadas por
`context.cores.<token>` — evita `isDark ? x : y` espalhado. Tamanhos em
`theme/app_sizes.dart`: `Espaco`, `Raio`, `Borda`, `Tipo`, `Icone`, `Duracao`,
`Dim`, `Breakpoint`, `Elevacao`. **Nada de número solto nas telas funcionais.**

A landing ainda tem escala própria e será migrada num passo separado.

## Tipografia

- **Archivo** (700–900): títulos, valores de KPI, marca
- **IBM Plex Sans** (400–600): textos de UI e botões
- **IBM Plex Mono**: números, unidades, labels técnicos e eixos

Fontes locais (`frontend/assets/fonts/`, declaradas no `pubspec.yaml`) —
embutidas no bundle, sem download em runtime.

## Layout da plataforma

| Largura | Layout |
|---------|--------|
| ≥ 1200px | trilho lateral + painel + resultados |
| 800–1199px | só resultados; parâmetros no Drawer, histórico no endDrawer |
| < 800px | só resultados; parâmetros num bottom sheet |

### Desktop: trilho + painel

- **Trilho** de 52px colado na borda esquerda, altura inteira. Um ícone por
  painel (Parâmetros, Histórico). Clicar no ícone ativo fecha o painel.
- **Alternar** fica fora do trilho, no cabeçalho antes da marca, alinhado ao mesmo
  eixo X. Abre/fecha sem trocar de painel.
- **Prévia (peek):** passar o mouse num ícone cujo painel está fechado mostra uma
  caixa fixa de 280×340 com o painel de verdade, só-leitura. Some ao tirar o
  mouse. Não aparece no ícone do painel já aberto.
- Os painéis ficam **montados** mesmo fechados (`IndexedStack`), então trocar ou
  fechar não perde accordion aberto nem rolagem.

Tablet e mobile mantêm os três botões no cabeçalho dos resultados — lá o toque é
caro e a tela é estreita demais pra ceder uma faixa fixa. O peek depende de hover,
que não existe em touch; portar o trilho pra lá exige decidir o que o substitui.

## Splash de boot

`web/index.html` tem um splash em HTML/CSS puro que aparece antes de o Flutter
existir e some no evento `flutter-first-frame` (mecanismo do próprio engine, sem
timer). Repete o fundo da bancada — grade de pontos a 26px e brilho âmbar no topo
— pra a troca passar despercebida. **Sem `@font-face` de propósito:** esperar uma
TTF só pra desenhar texto anularia o ponto de um splash; a marca é o
`logo_dark.png`.

## Testes

```bash
cd frontend
flutter test      # 60 testes
flutter analyze   # deve dar 0 issues
flutter build web
```

| Arquivo | Cobre |
|---------|-------|
| `param_defs_test.dart` | as 28 chaves, faixas, formatação e validação |
| `parameters_panel_test.dart` | estrutura dos cards, seleção única, erros, nome |
| `platform_sidebar_test.dart` | trilho, alternar, prévia do hover |
| `theme_provider_test.dart` | padrão escuro e persistência |
| `theme_hover_test.dart` | hover dos botões do Material nos dois temas |
| `widget_test.dart` | landing, login, cadastro |
