# Inferência client-side

A rede v22 roda **inteiramente no navegador**. Não há backend de predição: os
dois modelos ONNX viajam como assets do app, o onnxruntime-web os executa em
WASM, e a "cola" entre eles — o enriquecimento de atributos, o tempo
estequiométrico e a grade de tempo — está portada em Dart.

Consequências práticas: nenhum parâmetro sai da máquina de quem usa, não há
cold start de servidor gratuito pra esperar, e o app funciona offline depois do
primeiro carregamento.

## A cadeia

```
X31 (físico) → X47 (enriquecido, com log) → rede TEMPOS → tb, ts, πmax
                              │                              │
                              └──── + 3 tempos + πmax → rede FORMA
                                                             │
                                          y0(τ), Tout(τ) → eixo em segundos
```

| Arquivo | Porte de |
|---------|----------|
| `lib/inferencia/contrato.dart` | `reference/contrato_io_22.py` |
| `lib/inferencia/features.dart` | `reference/features_22.py` |
| `lib/inferencia/isoterma.dart` | `tst_ancora` do `exemplo_inferencia.py` |
| `lib/inferencia/grade_tau.dart` | `grid_tau` do `exemplo_inferencia.py` |
| `lib/inferencia/preditor_onnx.dart` | a cascata (`inferencia()`) |
| `lib/inferencia/param_defs_ponte.dart` | tela → contrato (nomes e unidades) |
| `lib/inferencia/motor_onnx*.dart` | onnxruntime-web via JS interop |

A biblioteca Python `nnadsorption` continua sendo a **referência canônica**. Se
ela mudar, o porte muda junto — e `test/inferencia_test.dart` é quem avisa.

## Três regras que não podem ser esquecidas

**1. Nada de z-score.** Os `.onnx` embutem a normalização. Entra número físico,
sai número físico. Aplicar `(x−μ)/σ` em qualquer ponto quebra tudo em silêncio.

**2. `Dt` é o último global.** A ordem das 31 colunas é
`… vs, Tin, P, L, hw, lam, dp, Dm, Dt, y0`. A tela mostra `Dt` logo depois de
`L`, o que convida ao erro. Trocar duas colunas não levanta exceção nenhuma —
só devolve número errado.

**3. Enriquece antes, loga depois.** Primeiro monta as 47 colunas, **depois**
aplica log em `kLogXIdx = [2, 11, 6, 15]`. Inverter isso faz `B_ref` e `kL`
entrarem logados nas features derivadas, e o resultado sai errado sem erro.

## Validação contra o Python

`test/inferencia_test.dart` compara o porte com números gerados pela lib
canônica sobre os valores padrão da tela. As 47 colunas do vetor enriquecido, o
`tst` e os 100 pontos da grade τ batem em 1e-9.

A cascata completa (com os `.onnx`) não roda em `flutter test` — precisa de
navegador. Ela foi conferida rodando a mesma entrada nos dois lados:

| Grandeza | Dart (WASM) | Python (x64) | Diferença |
|----------|-------------|--------------|-----------|
| `t_break` | 201.026749 | 201.026749 | 3,7e-7 s |
| `t_sat` | 500.405956 | 500.405975 | 1,9e-5 s |
| `TF` | 679.929189 | 679.929189 | 0 |
| `tst` | 339.964595 | 339.964595 | 0 |
| `pi_max` | 0.998945 | 0.998945 | 0 |

Curvas (100 pontos cada): `y_forte` e `y_carreador` com desvio máximo de 1,2e-7,
`T_out` de 3,1e-5 K. O que sobra é arredondamento de float32 entre o build WASM
e o build nativo do ONNX Runtime.

## O runtime no navegador

O onnxruntime-web é servido do **próprio domínio** (`web/ort/`), não de CDN: o
CSP do Hosting só libera script de `'self'`, e assim o app não depende de um
terceiro estar no ar pra prever.

- `ort.wasm.min.js` (50 KB) — o build só-WASM, sem WebGL/WebGPU
- `ort-wasm-simd-threaded.mjs` + `.wasm` (14 MB) — o runtime

Duas configurações valem explicação:

- **`numThreads = 1`.** Threads exigem cross-origin isolation (COOP **e** COEP);
  o Hosting hoje manda só o COOP. Pedir mais faria o ORT tentar um worker e cair
  de volta sozinho, com um erro no console pra ninguém.
- **`wasmPaths` é URL absoluta**, montada a partir do `<base href>`. O ORT usa
  esse valor num `import()` dinâmico, e um caminho relativo sem `./` o navegador
  lê como *nome de módulo* — `Failed to resolve module specifier`.

Os modelos são assets (`assets/onnx/*.onnx`, 39 MB) carregados por
`rootBundle.load` na primeira predição, não no boot: a landing não paga por eles.

## Logs

O preditor imprime no console do navegador (F12) — é o que se olha durante o
desenvolvimento:

```
[onnx] Modelos ONNX carregados em 584 ms
[onnx] Predição levou 11 ms
[onnx] Lote de 40 predições em 41 ms
```

A carga fica fora dos cronômetros de predição: na primeira vez ela domina tudo,
e o número que interessa medir é o de dentro.

## Peso da página

| Item | Tamanho |
|------|---------|
| `modelo_tempos_v22.onnx` | 21 MB |
| `modelo_forma_v22.onnx` | 17 MB |
| runtime WASM | 14 MB |

~52 MB baixados uma vez por navegador, e só quando alguém roda a primeira
predição. É o preço de não ter servidor. Se um dia incomodar, os caminhos são
quantizar os modelos (int8) ou servi-los com cache longo e `Content-Encoding`.

No repositório esses três arquivos vivem em **Git LFS** (`.gitattributes` rastreia
`*.onnx` e `*.wasm`); o Git guarda só um ponteiro de 133 bytes. Clonar sem o
`git-lfs` instalado traz os ponteiros no lugar dos binários — o app compila e
quebra só na hora de criar a sessão do ORT.
