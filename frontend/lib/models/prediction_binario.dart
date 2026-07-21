// prediction_binario.dart — modelo de dados do futuro modelo binário (2 componentes).
// Só a estrutura de dados; a tela de resultados ainda não existe.
class BinaryPredictionResult {
  // Escalares
  final double tBreakthrough;
  final double tSaturacao;
  final double tFinalJanela;
  final double grauSaturacao;

  // Eixo de tempo
  final List<double> tPoints;

  // Curvas de saída: fração molar de cada componente e temperatura
  final List<double> y0Points;
  final List<double> y1Points;
  final List<double> tOutPoints;

  BinaryPredictionResult({
    required this.tBreakthrough,
    required this.tSaturacao,
    required this.tFinalJanela,
    required this.grauSaturacao,
    required this.tPoints,
    required this.y0Points,
    required this.y1Points,
    required this.tOutPoints,
  });

  factory BinaryPredictionResult.fromJson(Map<String, dynamic> json) =>
      BinaryPredictionResult(
        tBreakthrough: (json['t_breakthrough'] as num).toDouble(),
        tSaturacao: (json['t_saturacao'] as num).toDouble(),
        tFinalJanela: (json['t_final_janela'] as num).toDouble(),
        grauSaturacao: (json['grau_saturacao'] as num).toDouble(),
        tPoints: _toDoubleList(json['t_points']),
        y0Points: _toDoubleList(json['y0_points']),
        y1Points: _toDoubleList(json['y1_points']),
        tOutPoints: _toDoubleList(json['T_out_points']),
      );

  static List<double> _toDoubleList(dynamic lista) =>
      (lista as List).map((e) => (e as num).toDouble()).toList();
}
