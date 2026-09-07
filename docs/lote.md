# Predição em lote

A rede prevê uma curva de ruptura em milissegundos, contra ~3 min do solver
numérico. A vantagem real, porém, não está em uma predição: está em mil. A rede
é **vetorizada** — N entradas empilhadas numa matriz custam quase o mesmo que
uma. É isso que o modo lote explora.

> **Uma chamada, não um laço.** `PreditorOnnx.predizerLoteX31` monta a matriz
> `[N, 47]` e chama a rede **uma vez** (tempos e forma). Rodar linha a linha num
> `for` jogaria fora exatamente a vantagem que justifica a feature. `predizer` é
> o caso N = 1 dessa mesma cascata.

Desde a migração para inferência client-side, **tudo acontece no navegador**:
o parse da planilha, a rede e a geração do arquivo de volta. Não há servidor no
caminho e nenhum dado sai da máquina de quem usa. Ver
[inferencia.md](inferencia.md).

## Onde fica

| Arquivo | Papel |
|---------|-------|
| `lib/inferencia/lote_local.dart` | lê planilha, roda, exporta, gera o modelo |
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

## Exportação

- **CSV** — só os escalares. Achatar 100 pontos × 4 séries em colunas daria 400
  colunas por linha, uma planilha que ninguém lê.
- **XLSX** — aba `Resumo` (uma linha por experimento) e, quando o lote foi
  rodado com curvas, uma aba `Curvas` no formato longo.

## Limites

- **5000 linhas por lote** (`kMaxLinhasLote`). A rede dá conta, mas 100 mil
  curvas de 200 pontos não cabem na memória de uma aba de navegador.
- Acima de 2000 linhas o modal avisa que pode demorar — e deixa rodar.

## Desempenho medido

Com os modelos já carregados, num Chromium headless (WASM, uma thread):

| Lote | Tempo da rede |
|------|---------------|
| 1 | ~10 ms |
| 40 | ~41 ms |

A carga dos dois `.onnx` (39 MB) acontece uma vez por aba, em ~600 ms servindo
localmente, e **não** entra nesses números — o cronômetro começa depois dela.
