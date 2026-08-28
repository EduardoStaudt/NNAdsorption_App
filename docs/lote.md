# Predição em lote

A rede prevê uma curva de ruptura em ~20 ms, contra ~3 min do solver numérico.
A vantagem real, porém, não está em uma predição: está em mil. A rede é
**vetorizada** — N entradas empilhadas numa matriz custam quase o mesmo que
uma. É isso que o modo lote explora.

> **Uma chamada, não um laço.** `AdsorptionPredictor.predict_batch` monta a
> matriz `[N, 31]` e chama `.predict()` **uma vez** por rede (tempos e forma).
> Rodar linha a linha num `for` jogaria fora exatamente a vantagem que
> justifica a feature. `predict` é o caso N = 1 dessa mesma cascata.

## Rotas

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/predict_batch` | N experimentos em JSON |
| POST | `/predict_batch_file` | N experimentos numa planilha (multipart) |
| POST | `/export_batch?formato=csv\|xlsx` | Resultado do lote → planilha |
| GET | `/template_batch?formato=csv\|xlsx` | Planilha modelo pra preencher |

Nenhuma exige autenticação — a API é aberta e sem estado, como o resto.

## Formato de I/O

O mesmo esquema de colunas vale na ida e na volta, pra ida-e-volta limpa.

**Entrada** — `nome` (opcional) + as 31 colunas do contrato, nesta ordem:

```
nome, c0_qm_ref, c0_k2, c0_B_ref, c0_k4, c0_n_ref, c0_k6, c0_kL, c0_dH, c0_Cpg,
      c1_qm_ref, c1_k2, c1_B_ref, c1_k4, c1_n_ref, c1_k6, c1_kL, c1_dH, c1_Cpg,
      eb, rho_b, Cps, vs, Tin, P, L, Dt, hw, lam, dp, Dm, y0
```

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

São as do **contrato da lib** (SI), não as da tela. O frontend converte antes
de mandar; quem monta a planilha na mão precisa saber:

| Campo | Unidade | Cuidado |
|-------|---------|---------|
| `c*_dH` | J/mol | a tela mostra kJ/mol |
| `P` | Pa | a tela mostra MPa |
| `dp` | m | a tela mostra mm |
| `c*_Cpg` | J/(mol·K) | |
| `Cps` | J/(kg·K) | |

## Requisição

```json
{
  "experimentos": [
    { "nome": "exp1", "c0_qm_ref": 8.0, "...": 0, "y0": 0.5 },
    { "nome": "exp2", "c0_qm_ref": 5.0, "...": 0, "y0": 0.6 }
  ],
  "saida": { "escalares": true, "curvas": false, "colunas": null }
}
```

- `saida.escalares` — inclui `tbreak`, `tsat`, `TF`, `tst`, `pi_max`, `severidade`.
- `saida.curvas` — inclui as 4 séries de 100 pontos de cada experimento.
- `saida.colunas` — filtra quais escalares saem (`null` = todos). `nome` e
  `avisos_faixa` nunca somem: sem eles não dá pra saber de qual linha é o
  resultado nem se ele saiu do domínio de treino.

No `/predict_batch_file` os mesmos três vêm como campos do form
(`escalares`, `curvas`, `colunas` separadas por vírgula).

## Resposta

```json
{
  "n_total": 1000,
  "n_avisos": 3,
  "tempo_ms": 1240,
  "resultados": [
    {
      "nome": "exp1",
      "tbreak": 127.3, "tsat": 289.1, "TF": 412.6, "tst": 206.3,
      "pi_max": 0.987, "severidade": 0.42,
      "avisos_faixa": [],
      "curvas": null
    }
  ]
}
```

`tempo_ms` é o tempo da cascata no lote inteiro — é o número que mostra o
ganho sobre o solver.

## Fora da faixa avisa, não bloqueia

Cada linha é conferida contra as faixas de treino (`contract.X_RANGES`). Uma
linha fora do domínio sai com `avisos_faixa` preenchido e **o resultado
calculado do mesmo jeito**: explorar fora do domínio é um uso legítimo, e a
extrapolação é responsabilidade de quem lê. `n_avisos` conta quantas linhas
saíram marcadas.

O que **bloqueia** o lote inteiro é erro de forma, não de valor: parâmetro
faltando, célula vazia, coluna ausente no cabeçalho. Nesses casos vem 422 com
o índice da linha ou o nome da coluna.

## Exportação

- **CSV** — só os escalares. Achatar 100 pontos × 4 séries em colunas daria
  400 colunas por linha, uma planilha que ninguém lê.
- **XLSX** — aba `Resumo` (uma linha por experimento) e, quando o lote foi
  rodado com `curvas: true`, uma aba `Curvas` no formato longo.

## Limites

- **5000 linhas por requisição** (`lote.MAX_LINHAS`). A API é aberta e sem
  conta; sem teto, uma requisição só derruba o processo.
- XLSX com curvas de um lote grande é caro: 1000 experimentos viram 100 mil
  linhas na aba `Curvas` (~5 s, ~2,8 MB). Pra lotes grandes, CSV de escalares.

## Sem os pesos da rede

Os artefatos V3 (`modelo_tempos.keras`, `modelo_forma.keras`) não estão no
repositório. Numa máquina sem eles as rotas de lote respondem **503** com a
mensagem da lib dizendo qual artefato falta — o resto (parsing, validação,
template, exportação) funciona normalmente.
