# Predição em lote

A rede prevê uma curva de ruptura em milissegundos, contra ~3 min do solver
numérico. A vantagem real, porém, não está em uma predição: está em mil. A rede
é **vetorizada** — N entradas empilhadas numa matriz custam quase o mesmo que
uma. É isso que o modo lote explora.

> **Uma chamada, não um laço.** `PreditorOnnx.predizerLoteX31` monta a matriz
> `[N, 47]` e chama a rede **uma vez** (tempos e forma). Rodar linha a linha num
> `for` jogaria fora exatamente a vantagem que justifica a feature. `predizer` é
> o caso N = 1 dessa mesma cascata.

O lote grande é fatiado em rodadas de 500 linhas (`kLinhasPorRodada`). Não é
recuo da regra acima: cada rodada continua sendo uma chamada só por rede. As
fatias existem pra a barra andar, a estimativa se corrigir com o ritmo real e
o cancelar ter onde acontecer.

Desde a migração para inferência client-side, **tudo acontece no navegador**:
o parse da planilha, a rede e a geração do arquivo de volta. Não há servidor no
caminho e nenhum dado sai da máquina de quem usa. Ver
[inferencia.md](inferencia.md).

## Onde fica

| Arquivo | Papel |
|---------|-------|
| `lib/inferencia/lote_local.dart` | lê planilha, roda em rodadas, exporta |
| `lib/inferencia/motor_lote*.dart` | a ponte com o Web Worker |
| `web/lote_worker.js` | o worker: só o `session.run` das duas redes |
| `lib/widgets/dialogo_lote.dart` | o modal (upload, prévia, seletor de saída) |

O modal abre pelo ícone de lote no trilho lateral, abaixo do histórico.

## Formato de I/O

O mesmo esquema de colunas vale na ida e na volta, pra ida-e-volta limpa.

**Entrada** — `nome` (opcional) + as 31 colunas do contrato, nesta ordem:

```
nome, c0_qm_ref, c0_k2, c0_B_ref, c0_k4, c0_n_ref, c0_k6, c0_kL, c0_dH, c0_Cpg,
      c1_qm_ref, c1_k2, c1_B_ref, c1_k4, c1_n_ref, c1_k6, c1_kL, c1_dH, c1_Cpg,
      eb, rho_b, Cps, vs, Tin, P, L, hw, lam, dp, Dm, Dt, y0
```

> **`Dt` é o último global**, depois de `Dm` — não vem junto do `L` como a tela
> sugere. Ele foi acrescentado no fim quando o contrato passou de 28 pra 31
> colunas. A ordem canônica vive em `lib/inferencia/contrato.dart`.

**Saída escalares:**

```
nome, tbreak, tsat, TF, tst, pi_max, severidade, avisos
```

**Saída curvas** (formato longo — uma linha por ponto):

```
nome, t, y_forte, y_carrier, T_out
```

Sem `nome`, cada linha recebe `exp_1`, `exp_2`, … na ordem de entrada.

### Unidades

São as do **contrato** (SI), não as da tela. A tela converte antes de mandar;
quem monta a planilha na mão precisa saber:

| Campo | Unidade | Cuidado |
|-------|---------|---------|
| `c*_dH` | J/mol | a tela mostra kJ/mol |
| `P` | Pa | a tela mostra MPa |
| `dp` | m | a tela mostra mm |
| `c*_Cpg` | J/(mol·K) | |
| `Cps` | J/(kg·K) | |

Os botões **Template XLSX** e **Template CSV** no próprio modal geram a planilha com o cabeçalho na
ordem certa e duas linhas de exemplo válidas — é o caminho curto pra não errar
nada disso.

## O que a saída traz

O seletor "O que exportar" define o arquivo, não a predição: a rede sempre
devolve tudo, e o que se escolhe é o que vai pro CSV/XLSX.

- **Escalares** — `tbreak`, `tsat`, `TF`, `tst`, `pi_max`, `severidade`, com as
  seis chaves ligáveis uma a uma.
- **Curvas completas** — as 4 séries de 100 pontos de cada experimento.
- **Formato** — CSV ou XLSX.

`nome` e `avisos` nunca saem: sem eles não dá pra saber de qual linha é o
resultado nem se ele saiu do domínio de treino.

## Fora da faixa avisa, não bloqueia

Cada linha é conferida contra as faixas de treino (`kFaixas` em
`contrato.dart`). Uma linha fora do domínio sai com `avisos` preenchido e **o
resultado calculado do mesmo jeito**: explorar fora do domínio é um uso
legítimo, e a extrapolação é responsabilidade de quem lê. O rodapé conta quantas
linhas saíram marcadas.

Vale olhar o que a extrapolação produz. Uma linha com `L = 99` (a faixa vai até
1,5 m) devolve `pi_max = -1.87` — um valor sem sentido físico, já que πmax vive
em [0,1]. O aviso está lá justamente pra isso.

O que **bloqueia** é erro de forma, não de valor: coluna ausente no cabeçalho,
célula vazia, texto onde devia haver número. Nesses casos o modal diz a linha e
a coluna, e o botão de rodar nem libera.

A mesma planilha serve a predição única: o modal de exportar (`dialogo_exportar.dart`)
embrulha o resultado em um lote de uma linha (`loteDeUm`) e chama estes mesmos
exportadores. Quem abrir os dois arquivos não precisa aprender dois formatos.

## Exportação

- **CSV** — só os escalares. Achatar 100 pontos × 4 séries em colunas daria 400
  colunas por linha, uma planilha que ninguém lê.
- **XLSX** — aba `Resumo` (uma linha por experimento) e, quando o lote foi
  rodado com curvas, uma aba `Curvas` no formato longo.

## Fora da thread da tela

As duas redes rodam num **Web Worker** (`web/lote_worker.js`). Só o
`session.run` mora lá: o contrato de 31 colunas, o enriquecimento pra 47 e a
montagem das curvas continuam em Dart, porque a cadeia canônica é a da
biblioteca Python e duplicá-la em JS seria pedir pra as duas divergirem.

Detalhes que custaram tempo:

- O worker é **clássico**, carregado com `importScripts`. O `ort.wasm.min.js` é
  UMD: num worker de módulo ele não exporta nada e `self.ort` fica indefinido.
- A variável do runtime no worker **não** pode se chamar `ort`: o próprio UMD
  declara esse nome, e `importScripts` estoura com
  `Identifier 'ort' has already been declared`.
- O worker recebe o `<base href>` da página por mensagem. Sem ela não teria como
  achar nem o runtime nem os `.onnx`, já que a URL dele não diz onde o app foi
  servido.

Com o worker de pé, a thread principal **não carrega os modelos**: quem tem as
sessões é o worker, e o `PreditorOnnx` só entra como reserva.

## Tempo estimado

Rodar não dispara o lote inteiro de cara. Primeiro passam
`kLinhasDeMedicao` = 50 linhas, que dão o ritmo real daquela máquina, e o rodapé
mostra o tempo estimado antes de a pessoa se comprometer. Durante a execução a
estimativa é refeita com a média das últimas três rodadas: o ritmo cai quando o
navegador começa a paginar memória, e uma estimativa do começo mentiria no fim.

Lote de até 50 linhas termina na própria medição, sem perguntar nada.

## Limites

- **30000 linhas por lote** (`kMaxLinhasLote`).
- **10000 linhas** com curvas no XLSX (`kMaxLinhasComCurvas`): são 100 linhas de
  planilha por experimento, e o formato aceita pouco mais de um milhão. Acima
  disso a opção de curvas sai de cena e o arquivo leva só os escalares.

## Desempenho medido

Chromium headless, WASM de uma thread, servindo localmente:

| Lote | Tempo da rede | Pior quadro da UI |
|------|---------------|-------------------|
| 40 | ~41 ms | — |
| 2000 | ~3 s | 17 ms |
| 30000 | ~39 s | 50 ms |

O "pior quadro" é o maior intervalo entre dois `requestAnimationFrame` durante o
lote: é o que diz se a tela travou. Antes do worker, 30 mil linhas numa chamada
só congelavam a aba do começo ao fim.

A carga dos dois `.onnx` (39 MB) acontece uma vez por lote, dentro do worker, em
~500 ms servindo localmente, e **não** entra nesses números.

O pico de heap com 30 mil resultados em memória ficou em ~125 MB: são 400
números por experimento (4 séries de 100 pontos). É o teto prático de hoje.
