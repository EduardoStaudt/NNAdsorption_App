// prediction.dart — modelo de dados de uma predição
class PredictionSummary {
  final int id;
  final DateTime criadoEm;
  final double? cOutFinal;
  final double? qOutFinal;
  final double? tOutFinal;
  final double? nAdsFinal;
  final double? qtotFinal;

  PredictionSummary({
    required this.id,
    required this.criadoEm,
    this.cOutFinal,
    this.qOutFinal,
    this.tOutFinal,
    this.nAdsFinal,
    this.qtotFinal,
  });

  factory PredictionSummary.fromJson(Map<String, dynamic> json) =>
      PredictionSummary(
        id: json['id'] as int,
        criadoEm: DateTime.parse(json['criado_em'] as String),
        cOutFinal: (json['C_out_final'] as num?)?.toDouble(),
        qOutFinal: (json['q_out_final'] as num?)?.toDouble(),
        tOutFinal: (json['T_out_final'] as num?)?.toDouble(),
        nAdsFinal: (json['N_ads_final'] as num?)?.toDouble(),
        qtotFinal: (json['Qtot_final'] as num?)?.toDouble(),
      );
}

class PredictionResult {
  // Escalares finais
  final double cOutFinal;
  final double qOutFinal;
  final double tOutFinal;
  final double nAdsFinal;
  final double qtotFinal;

  // Eixos
  final List<double> zPoints;
  final List<double> tPoints;

  // Perfis espaciais
  final List<double> cZPoints;
  final List<double> qZPoints;
  final List<double> tZPoints;

  // Curva de saída (breakthrough)
  final List<double> cOutPoints;

  PredictionResult({
    required this.cOutFinal,
    required this.qOutFinal,
    required this.tOutFinal,
    required this.nAdsFinal,
    required this.qtotFinal,
    required this.zPoints,
    required this.tPoints,
    required this.cZPoints,
    required this.qZPoints,
    required this.tZPoints,
    required this.cOutPoints,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) =>
      PredictionResult(
        cOutFinal: (json['C_out_final'] as num).toDouble(),
        qOutFinal: (json['q_out_final'] as num).toDouble(),
        tOutFinal: (json['T_out_final'] as num).toDouble(),
        nAdsFinal: (json['N_ads_final'] as num).toDouble(),
        qtotFinal: (json['Qtot_final'] as num).toDouble(),
        zPoints: _toDoubleList(json['z_points']),
        tPoints: _toDoubleList(json['t_points']),
        cZPoints: _toDoubleList(json['C_z_points']),
        qZPoints: _toDoubleList(json['q_z_points']),
        tZPoints: _toDoubleList(json['T_z_points']),
        cOutPoints: _toDoubleList(json['C_out_points']),
      );

  static List<double> _toDoubleList(dynamic lista) =>
      (lista as List).map((e) => (e as num).toDouble()).toList();
}
