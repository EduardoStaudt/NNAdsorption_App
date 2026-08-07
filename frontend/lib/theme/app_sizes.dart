// app_sizes.dart — escala de tamanhos das telas funcionais (plataforma).
//
// Fonte: DESIGN.md (spacing 6/8/14/18, rounded 6/10/14, tipografia 11/14/16).
// Todo padding, gap, raio, borda, tamanho de fonte e dimensão de componente das
// telas de trabalho sai daqui — nada de número solto no widget.
//
// A landing (`screens/landing_screen.dart`) ainda tem escala própria e será
// migrada num passo separado.

/// Espaçamentos: padding, margin e gaps.
/// `xs`/`sm`/`md`/`lg` são exatamente os quatro passos do DESIGN.md — mesmo
/// nome, mesmo valor. `campo` e `cartao` são os dois degraus intermediários que
/// a plataforma densa usa e o DESIGN.md não nomeia; ficam fora da escala t-shirt
/// de propósito, pra não competir com ela.
abstract final class Espaco {
  static const xxs = 4.0;
  static const xs = 6.0; // DESIGN.md xs
  static const sm = 8.0; // DESIGN.md sm
  static const md = 14.0; // DESIGN.md md
  static const lg = 18.0; // DESIGN.md lg
  static const xl = 24.0;

  static const campo = 10.0; // padding interno de input e linha de tabela
  static const cartao = 12.0; // respiro entre cards e blocos irmãos
}

/// Raios de canto, nomeados pelo papel (DESIGN.md §5).
abstract final class Raio {
  static const chip = 6.0; // chip de número, badge
  static const campo = 8.0; // input numérico
  static const controle = 10.0; // botão, aba, menu
  static const cartao = 11.0; // superfície aninhada (accordion, KPI, histórico)
  static const painel = 14.0; // painel principal e modal
}

/// Espessura de borda. `foco` é o único realce de foco do sistema.
abstract final class Borda {
  static const fina = 1.0;
  static const foco = 1.5;
}

/// Escala tipográfica da plataforma. O teto é 22 (valor de KPI): tamanho de
/// display só existe no hero da landing (Regra do Grito Único).
abstract final class Tipo {
  static const eixo = 10.0; // ticks de gráfico (única exceção abaixo de 11)
  static const label = 11.0; // eyebrow, unidade, símbolo, cabeçalho de tabela
  static const dado = 12.0; // número em tabela
  static const corpo = 13.0; // texto de UI compacto
  static const corpoGrande =
      14.0; // texto de UI, valor de input, título de card
  static const titulo = 16.0; // cabeçalho de painel
  static const tituloModal = 18.0;
  static const valor = 22.0; // valor de KPI
}

/// Tamanhos de ícone — quatro degraus, nada entre eles.
abstract final class Icone {
  static const pp = 14.0; // dica inline, mensagem de erro
  static const p = 16.0; // botão compacto
  static const m = 18.0; // ação padrão
  static const g = 28.0; // ilustra estado vazio
}

/// Elevação. O sistema é plano **em repouso** (DESIGN.md); estes valores só
/// existem no hover, e reproduzem o gesto que a landing já faz nos cards:
/// a superfície sobe um pouco e a borda ganha um fio de âmbar.
abstract final class Elevacao {
  static const escalaHover = 1.02;
  static const bordaHover = 0.7; // alpha do âmbar na borda
  static const sombraHover = 0.18; // alpha do preto
  static const desfoqueHover = 22.0;
  static const deslocaHover = 10.0;
  static const espalhaHover = -8.0;
}

/// Durações de transição. Hover/estado em `rapida`; nada passa de `lenta`.
abstract final class Duracao {
  static const toque = Duration(milliseconds: 120); // clique afunda
  static const rapida = Duration(milliseconds: 150); // hover, cor, borda
  static const media = Duration(milliseconds: 200); // chip, modal, rotação
  static const lenta = Duration(milliseconds: 300); // expansão de accordion
}

/// Dimensões fixas de componente.
abstract final class Dim {
  static const alturaBotaoPrimario = 46.0;
  static const alturaBotaoSecundario = 42.0;
  static const alturaBotaoCompacto = 38.0; // exportar
  static const alturaTopbar = 56.0;
  static const alturaBotaoIcone = 36.0; // fechar modal
  static const alturaItemMenu = 40.0;
  static const alturaItemHistorico = 52.0; // também a altura do skeleton

  static const larguraPainelParametros = 352.0;
  static const larguraDrawerParametros = 372.0;
  static const larguraDrawerHistorico = 340.0;

  static const larguraRail = 52.0; // trilho de ícones colado na borda
  static const itemRail = 44.0; // alvo de toque de cada ícone do trilho
  static const larguraPeek = 260.0; // prévia que aparece no hover do trilho

  static const larguraInput = 96.0;
  static const larguraUnidade = 72.0; // cabe 'mol/(kg·K)' em mono 11
  static const larguraCartaoKpi = 200.0;
  static const larguraTextoVazio = 320.0; // dica do estado vazio
  static const larguraAuth = 400.0; // painel de login/cadastro
  static const larguraBarraKpi = 26.0; // marca âmbar no topo do card
  static const alturaBarraKpi = 3.0;

  // Calhas dos eixos do gráfico: espaço reservado pros ticks. Andam junto com
  // Tipo.eixo — subir a fonte sem subir a calha corta os rótulos.
  static const calhaEixoY = 56.0;
  static const calhaEixoX = 26.0;

  static const maxLarguraModal = 1100.0;
  static const maxAlturaModal = 820.0;
  static const margemModal = 40.0; // respiro em volta do gráfico ampliado
}

/// Larguras de viewport onde o layout muda de forma.
abstract final class Breakpoint {
  static const desktop = 1200.0; // painel de parâmetros fixo ao lado
  static const tablet = 800.0; // parâmetros vão pro drawer
  static const graficoUmaColuna = 700.0; // grade 2x2 vira 1 coluna
  static const abasEmLinha = 680.0; // abas e ações na mesma linha
  static const modalEstreito = 600.0; // margem menor no gráfico ampliado
}
