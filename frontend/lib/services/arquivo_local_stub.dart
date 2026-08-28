// arquivo_local_stub.dart — implementação de fora do navegador.
//
// Escolher e baixar arquivo aqui dependem do DOM. Fora da web (desktop, e a VM
// onde `flutter test` roda) não há equivalente, então o stub existe só pra o
// código compilar: quem chamar recebe `null` ou não faz nada.
import 'dart:typed_data';

import 'arquivo_local.dart';

/// Sem seletor de arquivo fora do navegador.
Future<ArquivoEscolhido?> escolherArquivo(List<String> extensoes) async => null;

/// Sem download por âncora fora do navegador.
void baixarBytes(Uint8List bytes, String nomeArquivo, String tipoMime) {}

/// Só o navegador entrega arquivo por arraste.
bool get suportaArrastar => false;

void aoArrastarArquivo(void Function(ArquivoEscolhido) quandoSoltar) {}

void pararDeOuvirArraste() {}
