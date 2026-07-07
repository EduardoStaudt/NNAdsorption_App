# Brief de Correções — NNAdsorption_App

Após primeira rodada de testes manuais, encontramos um bug crítico no histórico
e várias melhorias de UX/visual. Este documento lista tudo, em ordem de
prioridade.

> ⚠️ **Continua usando a skill `/simplify` em todo o código.**

> 📎 **Arquivos de referência (na pasta `briefing/`):**
> - `mockup.html` — referência visual da plataforma (USE AGORA, não foi
>   seguido o suficiente na primeira rodada)
> - `Hero.png` — referência da landing (já está bem implementada, manter)
> - `design.md` — fonte da verdade do design

---

## 🔴 1. BUG CRÍTICO — Histórico não persiste entre sessões

### Diagnóstico já feito (não refaça)
Backend está correto. Confirmamos via Swagger que `GET /history` retorna
corretamente as predições do usuário logado:

```json
[
  {
    "id": 6,
    "criado_em": "2026-06-16T02:55:31.719961",
    "C_out_final": 5.5222,
    ...
  }
]
```

**O bug está no FRONTEND Flutter.** Sintoma: quando o usuário faz logout e
relogin, o drawer de histórico aparece vazio, mesmo havendo predições salvas
no banco.

### Causas prováveis (investigar e corrigir)
1. Token JWT não está sendo persistido no `localStorage` do browser
2. `AuthProvider` ou `HistoryProvider` mantém histórico só em memória
3. Falha silenciosa no fetch de `/history` — tratado como "lista vazia"

### Correções obrigatórias
- ✅ Token JWT deve ser salvo em `localStorage` após login/register
- ✅ Ao iniciar o app, verificar localStorage; se token válido, ir direto
  para `/app` e chamar `/history` imediatamente
- ✅ Sempre que `/app` for montada (initState), chamar `/history`
- ✅ Após cada `/predict` bem-sucedido, atualizar o histórico
- ✅ Logout deve limpar localStorage (`storage.remove('token')`)
- ✅ Se `/history` falhar, mostrar mensagem de erro (não mostrar lista vazia
  silenciosa)

### Como validar
1. Login → 2-3 predições → drawer mostra todas
2. Logout → login mesma conta → drawer mostra as predições anteriores
3. Login → fecha aba → reabre URL direto → vai pra `/app` automaticamente E
   mostra histórico

---

## 🔴 2. BUG VISUAL — Logo cortado no topbar

Nas telas da plataforma (modo claro E modo escuro), o logo "NNAdsorption" no
topbar aparece **cortado/sobreposto** — vê-se metade dele. Na landing o logo
aparece corretamente.

### Possíveis causas
- Container do topbar com largura/altura insuficiente
- Logo dark sendo usado em fundo claro (ou vice-versa) → contraste péssimo
- Padding/clipping cortando a imagem

### Correção
- Garantir que `logo_dark.png` é usado no tema escuro
- Garantir que `logo_light.png` é usado no tema claro
- Dimensionar corretamente o container do logo no topbar (altura ~40-48px,
  largura proporcional, sem overflow/clip)

---

## 🟠 3. Layout da aba "Gráficos" — gráficos grandes demais

### Problema
Ao abrir a aba Gráficos, vê-se só 2 dos 4 gráficos (Temperatura T(z) e
Breakthrough). Os outros (C(z) e q(z)) estão **fora da tela**, exigindo scroll
vertical.

Gráficos têm altura excessiva, ocupam quase toda a viewport vertical.

### Correção
- Layout em **grid 2×2** (2 colunas × 2 linhas), todos os 4 gráficos visíveis
  sem scroll em telas comuns (1366×768 ou superior)
- Cada gráfico ocupa ~50% da largura disponível e ~45% da altura
- Aspecto ratio dos gráficos: aprox. 4:3 (mais largos que altos)
- Em telas pequenas (<900px), cai pra 1 coluna com scroll (responsivo)

---

## 🟠 4. Aba "Resultados Finais" — cards flutuando no vazio

### Problema (ver screenshot)
Os 5 cards de KPI (C_out_final, q_out_final, ...) aparecem flutuando no meio
da tela, com espaço vazio absurdo acima e abaixo. Visual "horrível" (palavras
do usuário).

### Correção
- Cards devem ficar **próximos ao topo da área de conteúdo** (logo abaixo das
  abas), não no centro vertical
- Layout em grid responsivo:
  - Em telas grandes: 5 colunas (lado a lado, como está agora, mas no topo)
  - Em telas médias: 3 + 2 colunas
  - Em pequenas: 2 + 2 + 1
- Cards com altura uniforme e padding interno generoso
- Adicionar abaixo dos cards um **bloco de informações contextuais** explicando
  o que cada métrica significa, com exemplo de unidade e faixa típica.
  Pode ser um placeholder por enquanto: "Em breve: interpretação e
  contextualização dos resultados."

---

## 🟠 5. Aba "Tabela" — sem envolvimento visual

### Problema
A DataTable está solta no fundo da página, sem contraste visual com o resto.

### Correção
- Envolver a tabela em um **Card/Container** com:
  - Background do panel (`#15181D` no escuro, `#F5F5F7` no claro)
  - Border radius arredondado (~8px)
  - Padding interno
  - Sombra sutil (`elevation: 1`)
- Header da tabela em destaque (background ligeiramente diferente das rows)
- Linhas alternadas com cor sutil (zebra striping)
- Scroll vertical interno (não da página inteira)

---

## 🟠 6. Visual da plataforma geral — muito distante do `mockup.html`

### Problema
A primeira rodada não seguiu o mockup HTML com a fidelidade necessária. Pontos:
- Tipografia parece padrão do Flutter, não Archivo/IBM Plex
- Topbar não tem a estética "técnica/densa" do mockup
- Painel de parâmetros à esquerda está com accordions soltos, sem
  divisórias/hierarquia visual rica como no mockup
- Falta o "respiro" e proporções do design original

### Correção
Abra o `briefing/mockup.html` e use-o como referência **estrita** para:

1. **Fontes:** importar e usar Archivo (display, títulos), IBM Plex Sans
   (texto UI), IBM Plex Mono (números/dados). Use Google Fonts via
   `google_fonts` package no Flutter
2. **Topbar:** logo à esquerda, mantém o status indicator (bolinha verde
   "Conectado") que tinha no mockup, à direita ficam tema + avatar
3. **Painel esquerdo (parâmetros):**
   - Header de cada accordion com tipografia caps + cor accent sutil
   - Divisórias entre accordions
   - Inputs alinhados, com labels acima e unidades em cor secundária
4. **Botão "Rodar predição":** manter como FAB amarelo destacado (já está bom)
5. **Abas:** sublinhado amarelo na ativa, espaçamento generoso, fonte caps

---

## 🟡 7. Landing — pequenos ajustes

### Problema
A landing está bem (Hero perfeito) mas a seção "No que vamos te ajudar" tem
problema:
- Cards alinhados à esquerda em vez de centralizados
- O container cinza atrás dos cards forma uma "ilha" estranha
- Espaçamento entre seções inconsistente

### Correção
- Seção "No que vamos te ajudar" deve ter `max-width` (ex.: 1100px) e estar
  **centralizada horizontalmente** na página
- Cards distribuídos uniformemente dentro desse container
- Remover o fundo cinza estranho ou ajustar pra ser um fundo de seção que
  cobre 100% da largura, não só uma "ilha" no meio
- Padding/margin consistente entre todas as seções (ex.: 80px vertical entre
  cada uma)

---

## ✅ O que NÃO mexer (está bom)

- Landing — hero (título, gradiente, CTA) ✅
- Modo claro/escuro funcionando ✅
- Aba Comparação ✅
- Aba Tabela (conteúdo, só falta envolver em card) ✅
- Backend (sem alterações necessárias) ✅
- Acordeões de parâmetros (estrutura ok, só polir visual) ✅
- Botão "Rodar predição" amarelo destacado ✅

---

## Ordem sugerida de implementação

1. **Bug do histórico (#1)** — funcional, prioritário
2. **Bug do logo (#2)** — rápido de consertar
3. **Aba Gráficos (#3)** — alta visibilidade
4. **Aba Resultados Finais (#4)** — está feia
5. **Aba Tabela (#5)** — polish rápido
6. **Visual geral inspirado no mockup (#6)** — maior, leva tempo
7. **Ajustes da landing (#7)** — polish final

---

## Validação final

Antes de declarar pronto, fazer este teste completo:

1. Cadastra usuário novo
2. Faz 3 predições com inputs diferentes
3. Verifica os 4 gráficos visíveis SEM scroll
4. Aba Resultados Finais não tem espaço vazio absurdo
5. Aba Tabela está envolvida em card
6. Logout
7. Login mesma conta → histórico mostra as 3 predições
8. Fecha aba → reabre URL → vai direto pra `/app` E mostra histórico
9. Alterna tema claro/escuro — logo permanece visível em ambos
10. Visual da plataforma está próximo do `mockup.html` (compare lado a lado)

Se TODOS passarem, o brief está concluído.
