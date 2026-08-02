// app_sizes.dart — escala de tamanhos das telas funcionais (plataforma).
//
// Fonte: DESIGN.md (spacing 6/8/14/18, rounded 6/10/14, tipografia 11/14/16).
// Todo padding, gap, raio, borda, tamanho de fonte e dimensão de componente das
// telas de trabalho sai daqui — nada de número solto no widget.
//
// A landing (`screens/landing_screen.dart`) ainda tem escala própria e será
// migrada num passo separado.

/// Espaçamentos: padding, margin e gaps.
/// Passos de 2px na base (a plataforma é densa por natureza) e saltos maiores
/// no topo, onde separam blocos inteiros.
abstract final class Espaco {
  static const xxs = 4.0;
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 14.0;
  static const xxl = 18.0;
  static const xxxl = 24.0;
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
  static const corpoGrande = 14.0; // texto de UI, valor de input, título de card
  static const titulo = 16.0; // cabeçalho de painel
  static const tituloModal = 18.0;
  static const valor = 22.0; // valor de KPI
}

/// Tamanhos de ícone — três degraus, nada entre eles.
abstract final class Icone {
  static const pp = 14.0; // dica inline, mensagem de erro
  static const p = 16.0; // botão compacto
  static const m = 18.0; // ação padrão
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
  static const alturaBotaoIcone = 36.0; // fechar modal
  static const alturaItemMenu = 40.0;
  static const alturaItemHistorico = 52.0; // também a altura do skeleton

  static const larguraPainelParametros = 352.0;
  static const larguraDrawerParametros = 372.0;
  static const larguraDrawerHistorico = 340.0;

  static const larguraInput = 96.0;
  static const larguraUnidade = 72.0; // cabe 'mol/(kg·K)' em mono 11
  static const larguraCartaoKpi = 200.0;
  static const larguraBarraKpi = 26.0; // marca âmbar no topo do card
  static const alturaBarraKpi = 3.0;

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
