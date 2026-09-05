// prediction.dart — resumo de uma predição no histórico
import '../services/armazenamento_local.dart';

/// O que a lista do histórico mostra de cada experimento sem abrir o resultado
/// inteiro: quando rodou e o número que distingue um run do outro.
class PredictionSummary {
  final int id;
  final DateTime criadoEm;
  final double? tBreak;

  PredictionSummary({required this.id, required this.criadoEm, this.tBreak});

  /// Resumo de uma entrada do histórico do navegador. O escalar sai do
  /// resultado binário que a própria entrada carrega — entradas gravadas antes
  /// dele existir ficam sem o número, e a lista mostra só nome e data.
  factory PredictionSummary.doLocal(EntradaHistorico entrada) {
    return PredictionSummary(
      id: entrada.id,
      criadoEm: entrada.criadoEm,
      tBreak: (entrada.binario['t_break'] as num?)?.toDouble(),
    );
  }
}
