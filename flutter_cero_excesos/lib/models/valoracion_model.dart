class ValoracionModel {
  final double promedio;
  final int total;
  final int? miPuntuacion;

  ValoracionModel({
    required this.promedio,
    required this.total,
    this.miPuntuacion,
  });

  factory ValoracionModel.fromJson(Map<String, dynamic> json) {
    return ValoracionModel(
      promedio: (json['promedio'] as num?)?.toDouble() ?? 0.0,
      total: int.tryParse('${json['total']}') ?? 0,
      miPuntuacion: json['mi_puntuacion'] == null
          ? null
          : int.tryParse('${json['mi_puntuacion']}'),
    );
  }
}
