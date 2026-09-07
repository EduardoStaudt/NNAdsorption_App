// motor_lote_stub.dart — sem `dart:js_interop` não há Worker.
//
// Vale pra `flutter test`, que roda na VM: o lote lá cairia no caminho da
// thread principal de qualquer jeito.
import 'dart:typed_data';

class MotorLote {
  int msDeCarga = 0;
  bool get ativo => false;

  Future<bool> iniciar() async => false;

  Future<Float32List> rodar(
    String rede,
    Float32List entrada,
    int linhas,
    int colunas,
  ) => Future.error(UnsupportedError('sem worker fora do navegador'));

  void encerrar() {}
}

bool get suportaWorker => false;
