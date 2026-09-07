// lote_worker.js — as duas redes ONNX fora da thread da UI.
//
// O worker só roda `session.run`. O contrato de 31 colunas, o enriquecimento
// pra 47 e a montagem das curvas continuam em Dart: a cadeia canônica é a da
// biblioteca Python, e duplicá-la aqui em JS seria pedir pra as duas versões
// divergirem em silêncio.
//
// Worker clássico, carregado com `importScripts`: o `ort.wasm.min.js` é UMD e
// se pendura no global do worker. Em worker de módulo ele não exporta nada e
// `self.ort` fica indefinido.
// `ort` é o nome que o UMD declara no global do worker: usar a mesma palavra
// aqui dava "Identifier 'ort' has already been declared" no importScripts.
let motor = null;
const sessoes = {};

const ARQUIVOS = {
  tempos: 'assets/assets/onnx/modelo_tempos_v22.onnx',
  forma: 'assets/assets/onnx/modelo_forma_v22.onnx',
};

async function carregar(base) {
  // Worker clássico: o UMD do ORT se pendura no global do worker.
  importScripts(new URL('ort/ort.wasm.min.js', base).href);
  motor = self.ort;

  // Mesma configuração da thread principal: uma thread só (threads pedem
  // COOP *e* COEP, e o Hosting manda só COOP) e caminho absoluto pro .wasm.
  motor.env.wasm.numThreads = 1;
  motor.env.wasm.proxy = false;
  motor.env.wasm.wasmPaths = new URL('ort/', base).href;

  const opcoes = {
    executionProviders: ['wasm'],
    graphOptimizationLevel: 'all',
  };
  for (const [nome, caminho] of Object.entries(ARQUIVOS)) {
    const resposta = await fetch(new URL(caminho, base).href);
    if (!resposta.ok) {
      throw new Error(`${caminho} respondeu ${resposta.status}`);
    }
    const bytes = new Uint8Array(await resposta.arrayBuffer());
    sessoes[nome] = await motor.InferenceSession.create(bytes, opcoes);
  }
}

async function rodar(rede, dados, linhas, colunas) {
  const sessao = sessoes[rede];
  if (!sessao) throw new Error(`rede desconhecida: ${rede}`);

  const tensor = new motor.Tensor('float32', dados, [linhas, colunas]);
  const entrada = {};
  entrada[sessao.inputNames[0]] = tensor;
  const saida = await sessao.run(entrada);
  return saida[sessao.outputNames[0]].data;
}

self.onmessage = async (evento) => {
  const msg = evento.data;
  try {
    if (msg.tipo === 'carregar') {
      const relogio = performance.now();
      await carregar(msg.base);
      self.postMessage({
        tipo: 'carregado',
        id: msg.id,
        ms: Math.round(performance.now() - relogio),
      });
      return;
    }
    if (msg.tipo === 'rodar') {
      const dados = await rodar(msg.rede, msg.dados, msg.linhas, msg.colunas);
      // Transfere o buffer em vez de copiar: são 200 floats por linha.
      self.postMessage({ tipo: 'saida', id: msg.id, dados }, [dados.buffer]);
      return;
    }
    throw new Error(`mensagem desconhecida: ${msg.tipo}`);
  } catch (e) {
    self.postMessage({ tipo: 'erro', id: msg.id, mensagem: String(e) });
  }
};
